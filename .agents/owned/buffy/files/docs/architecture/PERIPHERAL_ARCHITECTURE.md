# Peripheral Architecture

## 1. Baseline Peripheral Set (required by requirements)
| Peripheral | Interface | Function | Evidence |
|-----------|-----------|----------|----------|
| UART      | APB       | Serial console / debug | DS-01 Section 4 (UART) |
| I²C       | APB       | Sensor & PMIC configuration | DS-01 Section 4 (I2C) |
| SPI/QSPI  | APB/AUX   | Flash, sensor, external modules | DS-01 Section 4 (SPI) |
| GPIO      | APB       | General‑purpose I/O, control lines | DS-01 Section 4 |
| PWM       | APB       | Motor / LED dimming | DS-01 Section 4 |
| I2S       | APB       | Audio output (optional) | DS-01 Section 4 |
| Timer/RTC | APB       | System tick, watchdog, real‑time clock | DS-01 Section 4 |
| PLIC/CLINT| Core‑local| Interrupt prioritization, timer interrupts | DS-01 Section 5 |
| AES & SHA | Custom  | Secure boot signature verification, OTA integrity | DS-01 Section 5 |
| TRNG      | Custom  | Entropy source for secure key generation | DS-01 Section 5 |

## 2. Optional Peripherals (future phases)
- BLE radio module (external)
- Zigbee module (external)
- Wi‑Fi module (external)

## 3. Peripheral Register Architecture
All peripheral registers are 32‑bit, APB‑mapped, and follow the standard *LiteX* register conventions (READ, WRITE, SET, CLEAR). Address offsets are aligned to 4 bytes to avoid bus width mismatches (DS‑02 Section 5).

## 4. Clock Gating & Power Management of Peripherals
- Each peripheral includes a local enable signal gated by the Power‑Domain controller (see CLOCK_RESET_AND_POWER_ARCHITECTURE.md).
- Low‑Power Timer (LPTIM) operates in the always‑on domain to support deep‑sleep wake‑up (DS‑02 Section 2).
