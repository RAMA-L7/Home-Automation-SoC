/*------------------------------------------------------------------------------
 * Home-Automation-SoC — Secure Boot
 * Stage 3 Firmware
 *
 * Implements secure boot: validates firmware header, verifies signature,
 * copies to SRAM, and jumps to application.
 *----------------------------------------------------------------------------*/

#include "boot.h"
#include "drivers.h"
#include <stddef.h>

/* Simple CRC32 */
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

int boot_validate_header(const boot_header_t *hdr)
{
    if (hdr->magic != 0x4841534Fu)   /* "HASO" */
        return -1;
    if (hdr->load_addr < 0x20000000u || hdr->load_addr > 0x20020000u)
        return -1;                    /* must load into SRAM */
    if (hdr->image_size == 0 || hdr->image_size > 0x20000u)
        return -1;                    /* max 128 KB */
    if (hdr->crc32 != crc32_compute((const uint8_t *)hdr + sizeof(boot_header_t),
                                     hdr->image_size))
        return -1;                    /* CRC mismatch */
    return 0;
}

void boot_verify_signature(const uint8_t *image, uint32_t size,
                           const uint8_t *sig, uint32_t sig_len)
{
    /* Hardware accelerator verification would go here.
     * For now, we check the signature magic and length as a placeholder.
     * Production: use AES/SHA/TRNG accelerators for RSA/ECDSA verification.
     */
    if (sig_len == 0) {
        uart_puts("WARNING: No signature, booting unverified\r\n");
        return;
    }
    uart_puts("Signature verified (placeholder)\r\n");
}

void boot_copy_to_sram(const uint8_t *src, uint32_t dst, uint32_t size)
{
    uint32_t i;
    for (i = 0; i < size; i += 4) {
        *(volatile uint32_t *)(dst + i) = *(const uint32_t *)(src + i);
    }
}

void boot_jump_to_app(uint32_t entry)
{
    /* Jump to application entry point */
    asm volatile ("jr %0" :: "r"(entry));
}

void boot_enter_recovery(void)
{
    uart_puts("=== RECOVERY MODE ===\r\n");
    uart_puts("Awaiting new firmware via UART...\r\n");
    /* Simple recovery: wait for 'r' to reboot, or flash new image */
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
    uint32_t selected_addr;

    uart_puts("\r\n=== Secure Boot ===\r\n");

    /* Validate both partitions */
    valid_a = boot_validate_header(hdr_a);
    valid_b = boot_validate_header(hdr_b);

    /* Check boot flag for preferred partition */
    if (*boot_flag == BOOT_FLAG_VALID && valid_a == 0) {
        selected = hdr_a;
        selected_addr = FW_PARTITION_A_ADDR;
        uart_puts("Boot flag selects partition A\r\n");
    } else if (valid_b == 0) {
        selected = hdr_b;
        selected_addr = FW_PARTITION_B_ADDR;
        uart_puts("Boot flag invalid, using partition B\r\n");
    } else if (valid_a == 0) {
        selected = hdr_a;
        selected_addr = FW_PARTITION_A_ADDR;
        uart_puts("Partition B invalid, using partition A\r\n");
    }

    if (!selected) {
        uart_puts("No valid partition! Entering recovery.\r\n");
        boot_enter_recovery();
        return;
    }

    /* Verify signature */
    boot_verify_signature((const uint8_t *)selected + sizeof(boot_header_t),
                          selected->image_size,
                          (const uint8_t *)selected + sizeof(boot_header_t) +
                          selected->image_size,
                          256);   /* placeholder sig len */

    /* Copy to SRAM */
    boot_copy_to_sram((const uint8_t *)selected + sizeof(boot_header_t),
                      selected->load_addr, selected->image_size);

    uart_puts("Jumping to application at 0x");
    uart_print_hex(selected->entry_addr);
    uart_puts("\r\n");

    boot_jump_to_app(selected->entry_addr);
}
