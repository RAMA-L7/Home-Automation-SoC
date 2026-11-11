/*------------------------------------------------------------------------------
 * Home-Automation-SoC — Secure Boot
 * Stage 3 Firmware
 *
 * Boot policy in this build:
 *   - validate the candidate images (header, bounds, entry, signature block);
 *   - verify the signature — which FAILS, because no cryptographic verifier is
 *     linked in.  Secure boot therefore rejects every image and falls back to
 *     recovery.  That is intentional: an unverified image must never run.
 *   - copy to SRAM and jump ONLY after a successful verification.
 *
 * The CRC32 here is transport integrity, NOT authentication.  It is checked so
 * that corrupted metadata is rejected before any unsafe read or copy, but a
 * matching CRC proves nothing about the author of the image.
 *----------------------------------------------------------------------------*/

#include "boot.h"
#include "drivers.h"
#include <stddef.h>

#define FW_HEADER_SIZE   ((uint32_t)sizeof(boot_header_t))
#define SIG_MAGIC        0x53454355u   /* "SECU" */

/* Simple CRC32 (transport integrity only) */
static uint32_t crc32_compute(const uint8_t *data, uint32_t len)
{
    uint32_t crc = 0xFFFFFFFF;
    uint32_t i, j;
    for (i = 0; i < len; i++) {
        crc ^= data[i];
        for (j = 0; j < 8; j++) {
            if (crc & 1)
                crc = (crc >> 1) ^ 0xEDB88320;
            else
                crc >>= 1;
        }
    }
    return crc ^ 0xFFFFFFFF;
}

/* Destination range must be word-aligned, word-sized, entirely inside SRAM and
 * entirely below the region reserved for the boot stack/metadata.  The last
 * check is written as a subtraction so it cannot overflow. */
static int boot_range_ok(uint32_t load_addr, uint32_t size)
{
    if (load_addr < SRAM_BASE || load_addr >= SRAM_APP_LIMIT)
        return -1;
    if (size == 0 || size > FW_MAX_IMAGE_SIZE)
        return -1;
    if ((load_addr & 3u) != 0 || (size & 3u) != 0)
        return -1;                      /* copy loop is word-wise */
    if (load_addr > SRAM_APP_LIMIT - size)
        return -1;
    return 0;
}

int boot_validate_image(const boot_header_t *hdr, uint32_t partition_base)
{
    uint32_t payload, sig_off, remaining;

    if (hdr->magic != 0x4841534Fu)                 /* "HASO" */
        return -1;

    if (boot_range_ok(hdr->load_addr, hdr->image_size) != 0)
        return -1;

    /* Entry must be an aligned address inside the image that will be loaded. */
    if (hdr->entry_addr < hdr->load_addr ||
        hdr->entry_addr >= hdr->load_addr + hdr->image_size ||
        (hdr->entry_addr & 3u) != 0)
        return -1;

    /* The whole image must fit in the partition after its header. */
    if (hdr->image_size > FW_PARTITION_SIZE - FW_HEADER_SIZE)
        return -1;

    payload = partition_base + FW_HEADER_SIZE;

    /* Reject corrupt payloads before we ever copy them. */
    if (hdr->crc32 != crc32_compute((const uint8_t *)payload, hdr->image_size))
        return -1;

    /* Signature block must exist inside the same partition, with a bounded
     * length.  Bounds are computed by subtraction to avoid overflow. */
    sig_off = FW_HEADER_SIZE + hdr->image_size;
    if (sig_off > FW_PARTITION_SIZE - 12u)
        return -1;

    {
        const uint32_t *sigb = (const uint32_t *)(partition_base + sig_off);
        uint32_t sig_len = sigb[2];
        remaining = FW_PARTITION_SIZE - sig_off - 12u;
        if (sigb[0] != SIG_MAGIC || sigb[1] == 0)
            return -1;
        if (sig_len == 0 || sig_len > SIG_MAX_LEN || sig_len > remaining)
            return -1;
    }

    return 0;
}

int boot_verify_signature(const uint8_t *image, uint32_t size,
                          const uint8_t *sig, uint32_t sig_len)
{
    (void)image; (void)size; (void)sig; (void)sig_len;

    /* No RSA/ECDSA verifier, no trust anchor, and no hardware accelerator is
     * implemented in this ROM.  Returning success here would make secure boot
     * decorative, so this build fails closed and boots into recovery. */
    return -1;
}

void boot_copy_to_sram(const uint8_t *src, uint32_t dst, uint32_t size)
{
    uint32_t i;
    /* Caller has validated alignment and range. */
    for (i = 0; i < size; i += 4) {
        *(volatile uint32_t *)(dst + i) = *(const uint32_t *)(src + i);
    }
}

void boot_jump_to_app(uint32_t entry)
{
    asm volatile ("jr %0" :: "r"(entry));
}

void boot_enter_recovery(void)
{
    uart_puts("=== RECOVERY MODE ===\r\n");
    uart_puts("No authenticated image. Awaiting firmware via UART...\r\n");
    /* Recovery: 'r' reboots through the boot ROM. */
    for (;;) {
        if (REG_UART_LSR & 0x01) {
            char c = (char)(REG_UART_RBR & 0xFF);
            if (c == 'r' || c == 'R') {
                uart_puts("Rebooting...\r\n");
                asm volatile ("j 0x00000000");
            }
        }
    }
}

/*------------------------------------------------------------------------------
 * Secure boot entry — called from boot ROM after reset
 *----------------------------------------------------------------------------*/
void secure_boot(void)
{
    const boot_header_t *hdr_a = (const boot_header_t *)FW_PARTITION_A_ADDR;
    const boot_header_t *hdr_b = (const boot_header_t *)FW_PARTITION_B_ADDR;
    uint32_t *boot_flag = (uint32_t *)BOOT_FLAG_ADDR;
    int valid_a, valid_b;
    const boot_header_t *selected = NULL;
    uint32_t selected_base = 0;

    uart_puts("\r\n=== Secure Boot ===\r\n");

    valid_a = boot_validate_image(hdr_a, FW_PARTITION_A_ADDR);
    valid_b = boot_validate_image(hdr_b, FW_PARTITION_B_ADDR);

    /* Boot flag is a preference, never an authorization: the selected image
     * still has to validate and verify. */
    if (*boot_flag == BOOT_FLAG_VALID && valid_a == 0) {
        selected = hdr_a;
        selected_base = FW_PARTITION_A_ADDR;
        uart_puts("Boot flag selects partition A\r\n");
    } else if (valid_b == 0) {
        selected = hdr_b;
        selected_base = FW_PARTITION_B_ADDR;
        uart_puts("Using partition B\r\n");
    } else if (valid_a == 0) {
        selected = hdr_a;
        selected_base = FW_PARTITION_A_ADDR;
        uart_puts("Partition B invalid, using partition A\r\n");
    }

    if (!selected) {
        uart_puts("No valid partition. Entering recovery.\r\n");
        boot_enter_recovery();
        return;
    }

    /* Authenticate before copying or executing anything. */
    {
        const uint8_t *payload = (const uint8_t *)(selected_base + FW_HEADER_SIZE);
        uint32_t sig_off = FW_HEADER_SIZE + selected->image_size;
        const uint8_t *sig = (const uint8_t *)(selected_base + sig_off + 12u);
        uint32_t sig_len = *(const uint32_t *)(selected_base + sig_off + 8u);

        if (boot_verify_signature(payload, selected->image_size,
                                  sig, sig_len) != 0) {
            uart_puts("ER image not authenticated. Entering recovery.\r\n");
            boot_enter_recovery();
            return;
        }
    }

    /* Verified. Only now is it safe to copy and transfer control. */
    boot_copy_to_sram((const uint8_t *)(selected_base + FW_HEADER_SIZE),
                      selected->load_addr, selected->image_size);

    uart_puts("Jumping to application at 0x");
    uart_print_hex(selected->entry_addr);
    uart_puts("\r\n");

    boot_jump_to_app(selected->entry_addr);
}
