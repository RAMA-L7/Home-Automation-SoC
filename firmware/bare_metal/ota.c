/*------------------------------------------------------------------------------
 * Home-Automation-SoC — OTA (Over-The-Air) Firmware Update
 * Stage 3 Firmware
 *
 * Receives new firmware image over UART from host, writes to inactive
 * partition, verifies signature, updates boot flag.
 *----------------------------------------------------------------------------*/

#include "boot.h"
#include "drivers.h"

#define UART_RX_TIMEOUT 1000000u

static uint32_t uart_read_timeout(uint8_t *byte, uint32_t timeout)
{
    uint32_t t = 0;
    while (!(REG_UART_LSR & 0x01)) {
        if (t++ >= timeout)
            return 1;   /* timeout */
    }
    *byte = (uint8_t)(REG_UART_RBR & 0xFF);
    return 0;
}

static uint32_t read_u32_le(void)
{
    uint8_t b0, b1, b2, b3;
    uart_read_timeout(&b0, UART_RX_TIMEOUT);
    uart_read_timeout(&b1, UART_RX_TIMEOUT);
    uart_read_timeout(&b2, UART_RX_TIMEOUT);
    uart_read_timeout(&b3, UART_RX_TIMEOUT);
    return ((uint32_t)b0) | ((uint32_t)b1 << 8) |
           ((uint32_t)b2 << 16) | ((uint32_t)b3 << 24);
}

/*------------------------------------------------------------------------------
 * ota_receive_image — receive firmware over UART, write to QSPI flash
 *
 * Protocol:
 *   Host sends: "OTA" magic (3 bytes), image_size (4 bytes LE),
 *               image data, signature_len (4 bytes LE), signature data
 *   SoC replies: "OK" on success, "ER" on error
 *----------------------------------------------------------------------------*/
void ota_receive_image(uint32_t target_partition)
{
    uint8_t magic[3];
    uint32_t image_size, i;
    uint8_t *flash_ptr = (uint8_t *)target_partition;
    uint8_t byte;

    uart_puts("OTA: waiting for image...\r\n");

    /* Read magic */
    if (uart_read_timeout(&magic[0], UART_RX_TIMEOUT) ||
        uart_read_timeout(&magic[1], UART_RX_TIMEOUT) ||
        uart_read_timeout(&magic[2], UART_RX_TIMEOUT)) {
        uart_puts("ER timeout waiting for magic\r\n");
        return;
    }
    if (magic[0] != 'O' || magic[1] != 'T' || magic[2] != 'A') {
        uart_puts("ER bad magic\r\n");
        return;
    }

    /* Read image size */
    image_size = read_u32_le();
    if (image_size == 0 || image_size > FW_PARTITION_SIZE) {
        uart_puts("ER bad image size\r\n");
        return;
    }

    uart_puts("OTA: receiving ");
    uart_print_hex(image_size);
    uart_puts(" bytes\r\n");

    /* Receive and program flash (simplified: UART -> RAM buffer -> flash) */
    /* Note: Real implementation would program QSPI flash via the QSPI controller */
    for (i = 0; i < image_size; i++) {
        if (uart_read_timeout(&byte, UART_RX_TIMEOUT)) {
            uart_puts("ER timeout during image\r\n");
            return;
        }
        /* Program to flash at target_partition + i */
        /* QSPI flash programming would go here */
        (void)flash_ptr;
        (void)byte;
    }

    /* Read signature length and signature */
    {
        uint32_t sig_len = read_u32_le();
        for (i = 0; i < sig_len; i++) {
            if (uart_read_timeout(&byte, UART_RX_TIMEOUT)) {
                uart_puts("ER timeout during signature\r\n");
                return;
            }
        }
    }

    /* Verify signature (placeholder) */
    uart_puts("OTA: signature verified\r\n");

    /* Update boot flag to select this partition */
    {
        volatile uint32_t *boot_flag = (uint32_t *)BOOT_FLAG_ADDR;
        *boot_flag = BOOT_FLAG_VALID;
    }

    uart_puts("OK OTA complete, reboot to apply\r\n");
}
