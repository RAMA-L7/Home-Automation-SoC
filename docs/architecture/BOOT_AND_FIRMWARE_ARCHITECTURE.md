# Boot and Firmware Architecture

## 1. Boot Flow Overview

The Home-Automation-SoC implements a **secure, multi-stage boot** sequence designed for residential IoT with OTA capability:

```
POR
  │
  ▼
┌─────────────────────┐
│  Boot ROM (16 KB)   │  ← Immutable, in mask ROM / OTP
│  - Self-test        │
│  - TRNG init        │
│  - Key derivation   │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Firmware Header    │  ← QSPI 0x4000_0000 (A/B partition)
│  - Version          │
│  - Hash (SHA-256)   │
│  - ECDSA-P256 Sig   │
└─────────┬───────────┘
          │  Verify
          ▼
┌─────────────────────┐
│  Firmware Image     │  ← Load to SRAM (0x2000_0000) or execute XIP
│  - Zephyr RTOS      │
│  - Drivers          │
│  - App (Matter/Thread)    │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Runtime Services   │
│  - Secure Boot Meas │
│  - OTA Verifier     │
│  - Key Manager      │
└─────────────────────┘
```

---

## 2. Boot Stages Detail

### 2.1 Stage 0: Power-On Reset (Hardware)
- **Trigger:** PMIC POR_B release + crystal stable
- **Clocks:** 32 kHz LPO → PLL lock → 50 MHz core clock
- **Resets:** Global `reset_n` → core reset → peripheral resets (staggered)
- **Duration:** ~10 ms (PLL lock dominant)

### 2.2 Stage 1: Boot ROM (Immutable)
| Step | Action | Cycles (est.) | Notes |
|------|--------|---------------|-------|
| 1 | Stack pointer init (TCM top) | 10 | 0x0001_8000 |
| 2 | SRAM/regs self-test (march C-) | ~50k | Optional fast path |
| 3 | TRNG instantiate + health test | ~10k | AON domain |
| 4 | Read DUK from OTP | 50 | Derive keys |
| 5 | Initialize AES/SHA engines | 100 | APB config |
| 6 | Locate valid firmware partition | 200 | A/B + rollback counter |
| 7 | Verify ECDSA-P256 signature | ~500k | ~50 ms @ 50 MHz |
| 8 | Measure firmware hash (SHA-256) | ~200k | For attestation |
| 9 | Jump to firmware entry | 10 | PC = 0x2000_0100 |

**Total Boot ROM Time:** ~70 ms (target < 100 ms)

### 2.3 Stage 2: Firmware Early Init (Zephyr)
| Component | Action |
|-----------|--------|
| **Kernel** | Zero BSS, init scheduler, heap |
| **Drivers** | UART console, I²C (PMIC), SPI (QSPI), GPIO |
| **Security** | Mbed TLS init, PSA key slots, PMP config |
| **Network** | Thread/OpenThread stack, Matter commissioning |
| **Power** | PMIC config, clock gating, deep-sleep policy |

### 2.4 Stage 3: Application Start
- Home Assistant connection (MQTT over TLS)
- Sensor polling, actuator control
- OTA listener (background)

---

## 3. Firmware Architecture (Zephyr RTOS)

### 3.1 Repository Structure
```
firmware/
├── boards/
│   └── has_soc/              # Board definition (DTS, Kconfig)
├── modules/
│   ├── lib/                  # Custom libraries
│   │   ├── crypto/           # Mbed TLS PSA wrappers
│   │   ├── ota/              # OTA verifier, A/B manager
│   │   └── pm/               # Power management policies
│   └── drivers/              # SoC-specific drivers
│       ├── uart/             # NS16550-compatible
│       ├── i2c/              # DW APB I2C
│       ├── spi/              # DW APB SPI + QSPI
│       ├── gpio/             # 32-bit APB GPIO
│       ├── pwm/              # 4-channel APB PWM
│       ├── aes/              # AES-256 APB driver
│       ├── sha/              # SHA-256 APB driver
│       └── trng/             # TRNG APB driver
├── apps/
│   ├── bootloader/           # Minimal 2nd-stage (optional)
│   └── ha_controller/        # Main Home Assistant app
└── tests/
    ├── unit/                 # Driver unit tests
    └── integration/          # Renode/Verilator co-sim
```

### 3.2 Build System
- **Toolchain:** riscv-gnu-toolchain (RV32IMC, ILP32 ABI)
- **Build Tool:** Zephyr `west` + CMake + Kconfig
- **Output:** `zephyr.bin` (raw binary) + `zephyr.elf` (debug)
- **Signing:** `imgtool` (Mbed TLS) → signed `zephyr.signed.bin`
- **Flashing:** OpenOCD + JTAG or QSPI programmer

### 3.3 Memory Layout (Linker Script)
```
MEMORY
{
  ROM     (rx)  : ORIGIN = 0x0000_0000, LENGTH = 16K    /* Boot ROM */
  TCM     (rwx) : ORIGIN = 0x0001_0000, LENGTH = 32K    /* TCM: vectors, critical */
  SRAM    (rwx) : ORIGIN = 0x2000_0000, LENGTH = 128K   /* SRAM: .text, .data, .bss, heap, stack */
  QSPI    (rx)  : ORIGIN = 0x4000_0000, LENGTH = 64M    /* QSPI: XIP + OTA staging */
  PERIPH  (rw)  : ORIGIN = 0x5000_0000, LENGTH = 1M     /* APB peripherals */
  IRQ     (rw)  : ORIGIN = 0x8000_0000, LENGTH = 64K    /* PLIC/CLINT */
}

SECTIONS
{
  .text   : { *(.text*) } > SRAM
  .rodata : { *(.rodata*) } > SRAM
  .data   : { *(.data*) } > SRAM AT > QSPI  /* Stored in flash, copied to SRAM */
  .bss    : { *(.bss*) } > SRAM
  .vectors: { *(.vectors*) } > TCM          /* Interrupt vectors in TCM */
  .critical: { *(.critical*) } > TCM        /* Time-critical functions */
}
```

---

## 4. OTA Update Architecture (ARC-018, ARC-026)

### 4.1 A/B Partition Scheme (QSPI Flash)
```
QSPI Flash (64 MB)
├── 0x4000_0000 – 0x41FF_FFFF : Partition A (32 MB) — Active Firmware
├── 0x4200_0000 – 0x43FF_FFFF : Partition B (32 MB) — Staging / Rollback
└── 0x4400_0000 – 0x4400_0FFF : Metadata (4 KB) — Rollback counter, active flag
```

### 4.2 Update Flow
1. **Download:** App receives OTA image via MQTT → writes to inactive partition
2. **Verify (Runtime):** 
   - Check header magic, version > current
   - AES-256-GCM decrypt (key from key manager)
   - SHA-256 hash matches header
   - ECDSA-P256 signature valid (manufacturer key)
3. **Commit:** 
   - Write metadata: active_partition = new, rollback_counter++
   - Request reboot
4. **Boot ROM Verification:** On next POR, Stage 1 verifies new active partition
5. **Rollback:** If boot fails 3×, boot ROM reverts active_partition flag

### 4.3 Image Format
```c
struct ota_header_t {
  uint32_t magic;           // 0x4841534F ("HASO")
  uint32_t version;         // Monotonic, matches rollback counter
  uint32_t size;            // Payload size (bytes)
  uint32_t load_addr;       // 0x2000_0100 (SRAM entry)
  uint32_t entry_point;     // Reset vector
  uint8_t  hash[32];        // SHA-256 of payload
  uint8_t  sig[64];         // ECDSA-P256 (r||s)
  uint8_t  nonce[12];       // AES-GCM nonce
  uint8_t  tag[16];         // AES-GCM auth tag
  uint32_t flags;           // Encrypted=1, Compressed=2, etc.
  uint32_t reserved[4];
};  // Total: 128 bytes, 4-byte aligned
```

---

## 5. Secure Boot Key Provisioning (ARC-025)

### 5.1 Manufacturing Flow
```
+------------------+     +------------------+     +------------------+
|  HSM (Factory)   |────▶|  Provisioning    |────▶|  SoC (QFN-64)    |
|  - Root CA       |     |  Station         |     |  - TRNG          |
|  - Signing Key   |     |  - JTAG/SWD      |     |  - OTP           |
+------------------+     |  - DUK gen       |     |  - QSPI          |
                         |  - Cert sign     |     +------------------+
                         +------------------+
```

1. **Device Unique Key (DUK):** 256-bit from TRNG → OTP (one-time)
2. **Key Derivation:** KDF(DUK, "firmware-signing") → ECDSA-P256 keypair
3. **Certificate:** Manufacturer CA signs device public key → X.509 cert
4. **Storage:** Cert + public key → QSPI (0x4400_1000)
5. **Lock:** OTP debug-disable + boot ROM lock registers

### 5.2 Field Recovery
- **Lost Keys:** Not recoverable (by design)
- **RMA:** Challenge-response with manufacturer → temporary debug unlock
- **Re-provisioning:** Not supported (OTP is one-time)

---

## 6. Power-On Reset Sequence (ARC-007, ARC-031)

### 6.1 Hardware Sequence
```
Time 0:      VDD_AON (3.3V) rises → LPO starts (32 kHz)
Time +1ms:   PMIC I²C ready → Buck1 (1.0V) enable → Core domain
Time +2ms:   Buck2 (1.8V) enable → IO domain
Time +3ms:   PLL enable (12 MHz XTAL → 50 MHz)
Time +5ms:   PLL lock → Clock mux to core
Time +6ms:   Global reset_n deasserted (active-low)
Time +7ms:   Ibex fetches first instruction @ 0x0000_0000
```

### 6.2 Reset Sources
| Source | Scope | Register |
|--------|-------|----------|
| POR (PMIC) | Full chip | — |
| Watchdog (CLINT) | Core only | `mtimecmp` |
| Software (APB) | Peripheral | `PERIPH_RST` reg |
| Debug (JTAG) | Core | `dmcontrol` |
| Brown-out (PMIC) | Core + IO | `PMIC_ALERT` pin |

---

## 7. Clock Configuration at Boot

| Domain | Source | Frequency | Boot State |
|--------|--------|-----------|------------|
| Core | PLL (12 MHz XTAL) | 50 MHz | Enabled after PLL lock |
| Peripheral | Core clock / 2 | 25 MHz | Enabled by boot ROM |
| AON | LPO (RC) | 32 kHz | Always on |
| QSPI | Core clock / 4 | 12.5 MHz | Enabled for boot |

---

## 8. Firmware Security Services

### 8.1 PSA Crypto API (Mbed TLS)
- **Key Slots:** Persistent (OTP-derived) + Volatile (session)
- **Operations:** Sign/verify, encrypt/decrypt, hash, HKDF, random
- **Isolation:** PMP regions for key storage

### 8.2 Attestation
- **Platform:** Boot ROM measures firmware hash → TPM-style PCR
- **Report:** Signed by device attestation key (derived from DUK)
- **Verifier:** Home Assistant / cloud service

### 8.3 Key Manager
- **Lifecycle:** Provisioned → Operational → Locked → RMA
- **Derivation:** Per-context keys (TLS, Matter, OTA) from DUK
- **Export Policy:** Never export DUK or root keys

---

## 9. Debug & Development Boot Modes

| Mode | BOOT_MODE Pin | Behavior |
|------|---------------|----------|
| **Secure Boot** | 0 | Normal: Boot ROM → signed firmware |
| **JTAG Debug** | 1 | Halt at reset vector; JTAG enabled |
| **QSPI Direct** | 2 | Boot ROM skipped; execute from QSPI 0x4000_0000 |
| **Serial Boot** | 3 | UART bootloader (YMODEM) for recovery |

*BOOT_MODE sampled at POR; latched until next POR*

---

## 10. Open Decisions (Traceable to ARCs)

| Decision | ARC Ref | Status |
|----------|---------|--------|
| Boot ROM exact size (16 vs 32 KB) | ARC-004, ARC-011 | PROPOSED |
| TCM vs SRAM for .text (XIP vs copy) | ARC-003, ARC-019 | PROPOSED |
| OTA partition size (32 MB vs 16 MB) | ARC-018 | PROPOSED |
| Rollback counter storage (OTP vs PMIC NVRAM) | ARC-026 | PROPOSED |
| Second-stage bootloader needed? | ARC-018 | PENDING |
| Fast boot path (skip self-test) | ARC-007 | PROPOSED |

---

## 11. Integration Checklist

- [ ] Boot ROM SystemVerilog RTL (from OpenTitan)
- [ ] Ibex reset vector configuration
- [ ] OTP macro integration (sky130 eFuse)
- [ ] QSPI controller XIP mode at reset
- [ ] PLL lock detection → reset release
- [ ] PMIC I²C driver early init
- [ ] Zephyr board port (`has_soc`)
- [ ] Mbed TLS PSA config for AES/SHA/TRNG
- [ ] OTA verifier library (`lib/ota/`)
- [ ] imgtool signing script integration
- [ ] OpenOCD board config for JTAG debug

---

*All decisions traceable to ARC IDs in Phase 0 Closure Matrix. Evidence tags: VERIFIED, DOCUMENTED, PROPOSED, UNKNOWN.*