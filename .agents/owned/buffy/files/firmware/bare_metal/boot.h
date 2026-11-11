/*------------------------------------------------------------------------------
 * Home-Automation-SoC — Secure Boot Header
 * Stage 3 Firmware
 *----------------------------------------------------------------------------*/

#ifndef BOOT_H
#define BOOT_H

#include <stdint.h>

/* Boot ROM is at 0x0000_0000, 16 KB */
/* QSPI flash at 0x4000_0000, 64 MB */
/* Firmware A partition: 0x4000_1000 */
/* Firmware B partition: 0x4020_1000 */

/* Partition addresses */
#define FW_PARTITION_A_ADDR  0x40001000
#define FW_PARTITION_B_ADDR  0x40201000
#define FW_PARTITION_SIZE    0x00020000   /* 128 KB each */

/* Boot status flags in flash */
#define BOOT_FLAG_ADDR       0x40400000
#define BOOT_FLAG_VALID      0xA5A55A5A
#define BOOT_FLAG_INVALID    0x00000000

/* Signature structure (appended to firmware image) */
typedef struct {
    uint32_t magic;        /* 0x53454355 "SECU" */
    uint32_t algo;         /* 1 = RSA-2048, 2 = ECDSA-P256 */
    uint32_t sig_len;      /* signature length in bytes */
    uint8_t  signature[];  /* variable-length signature */
} __attribute__((packed)) boot_signature_t;

/* Firmware header */
typedef struct {
    uint32_t magic;        /* 0x4841534F "HASO" */
    uint32_t version;      /* firmware version */
    uint32_t load_addr;    /* SRAM load address */
    uint32_t entry_addr;   /* entry point */
    uint32_t image_size;   /* image size in bytes */
    uint32_t crc32;        /* CRC32 of image */
    uint32_t reserved[2];
} __attribute__((packed)) boot_header_t;

/* Memory bounds used by image validation */
#define SRAM_BASE            0x20000000u
#define SRAM_SIZE            0x00020000u   /* 128 KB */
#define SRAM_END             (SRAM_BASE + SRAM_SIZE)
#define BOOT_RESERVED_TOP    0x00001000u   /* stack + boot metadata kept clear */
#define SRAM_APP_LIMIT       (SRAM_END - BOOT_RESERVED_TOP)
#define FW_MAX_IMAGE_SIZE    0x00020000u
#define SIG_MAX_LEN          512u

/* Boot ROM functions (called from ROM, implemented here) */
/* Returns 0 only if the image signature was cryptographically verified.
 * Returns nonzero otherwise.  There is no verifier in this build, so every
 * call fails: callers must treat nonzero as "do not execute". */
int boot_verify_signature(const uint8_t *image, uint32_t size,
                          const uint8_t *sig, uint32_t sig_len);
/* Header, range, entry and signature-block validation against a partition. */
int boot_validate_image(const boot_header_t *hdr, uint32_t partition_base);
void boot_copy_to_sram(const uint8_t *src, uint32_t dst, uint32_t size);
void boot_jump_to_app(uint32_t entry);

/* Recovery mode */
void boot_enter_recovery(void);

#endif /* BOOT_H */
