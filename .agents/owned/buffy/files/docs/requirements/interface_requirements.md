# Interface Requirements Specification — Home-Automation-SoC

**Document ID:** HAS-SoC-IRS-001  
**Version:** 1.0  
**Date:** 2026-11-11  
**Status:** DRAFT — For Review  
**Parent:** HAS-SoC-SRS-001 (System Requirements)

---

## 1. Pin Interface (QFN-64)

### 1.1 Package Mechanical

| Parameter | Value | Source |
|-----------|-------|--------|
| Package Type | QFN-64 (Quad Flat No-leads) | ARC-022 |
| Body Size | 9.0 mm × 9.0 mm | Standard |
| Pitch | 0.5 mm | Standard |
| Exposed Pad | Yes (GND, thermal) | ARC-023 |
| Lead Count | 64 (including EP as 2 pins) | Standard |
| Moisture Sensitivity | MSL-3 | Standard |

### 1.2 Pin Assignment Summary

| Category | Pin Count | Voltage Domain | Details |
|----------|-----------|----------------|---------|
| Power/Ground | 16 | 1.0V/1.8V/3.3V | VDD_CORE×2, GND_CORE×2, VDD_IO, GND_IO, VDD_PERIPH, GND_PERIPH, VDD_AON, GND_AON, VDD_RTC, GND_RTC, EP×2 |
| System | 4 | 3.3V (AON) | XTAL_IN, XTAL_OUT, RESET_N, BOOT_MODE[1:0] |
| Debug | 6 | 3.3V (AON) | TCK, TMS, TDI, TDO, TRST_N, UART0_TX/RX |
| UART | 4 | 1.8V (IO) | UART0_TX/RX (debug), UART1_TX/RX (radio) |
| I²C | 2 | 1.8V (IO) | SCL, SDA (PMIC + sensors) |
| SPI/QSPI | 6 | 1.8V (IO) | SCK, MOSI, MISO, CS0/1/2 (Flash + Radio + Aux) |
| PWM | 4 | 3.3V (PERIPH) | PWM0-3_OUT |
| GPIO | 16 | 3.3V (PERIPH) | GPIO0-15 (shared/alternate) |
| I²S | 4 | 1.8V (IO) | BCLK, LRCLK, DIN, DOUT |
| PMIC | 2 | 3.3V (AON) | ALERT, IRQ |
| RF Control | 2 | 1.8V (IO) | RF_CTRL0, RF_CTRL1 |
| **Total** | **64** | — | **56 usable I/O** |

### 1.3 Detailed Pin Table

See `constraints/pin_assignment_qfn64.csv` for complete pin-by-pin assignment including:
- Pin number
- Signal name
- Direction (INPUT/OUTPUT/INOUT/POWER/GROUND)
- Power domain
- Voltage level
- Function description
- Notes (alternate functions, pull requirements)

### 1.4 Pin Multiplexing (GPIO Alternate Functions)

| GPIO | Primary | Alternate 1 | Alternate 2 | Alternate 3 |
|------|---------|-------------|-------------|-------------|
| GPIO0 | GPIO | UART1_CTS | PWM4 | — |
| GPIO1 | GPIO | UART1_RTS | PWM5 | — |
| GPIO2 | GPIO | I2C1_SCL | SPI1_CS0 | — |
| GPIO3 | GPIO | I2C1_SDA | SPI1_CS1 | — |
| GPIO4 | GPIO | SPI1_SCK | I2S_MCLK | — |
| GPIO5 | GPIO | SPI1_MOSI | — | — |
| GPIO6 | GPIO | SPI1_MISO | — | — |
| GPIO7 | GPIO | PWM6 | — | — |
| GPIO8 | GPIO | PWM7 | — | — |
| GPIO9 | GPIO | UART2_TX | — | — |
| GPIO10 | GPIO | UART2_RX | — | — |
| GPIO11 | GPIO | I2C2_SCL | — | — |
| GPIO12 | GPIO | I2C2_SDA | — | — |
| GPIO13 | GPIO | CLK_OUT | — | — |
| GPIO14 | GPIO | TRACE_CLK | — | — |
| GPIO15 | GPIO | TRACE_DATA | — | — |

*Multiplexing controlled via APB Pinmux registers (base 0x5000_C000)*

---

## 2. Electrical Interfaces

### 2.1 Power Supply Pins

| Pin Group | Voltage | Tolerance | Max Current | Source | Sequencing |
|-----------|---------|-----------|-------------|--------|------------|
| VDD_CORE | 1.0 V | ±5% (0.95–1.05V) | 1.2 A | TPS65217 Buck1 | 3rd (after AON) |
| VDD_IO | 1.8 V | ±5% (1.71–1.89V) | 1.2 A | TPS65217 Buck2 | 4th (after Core) |
| VDD_PERIPH | 3.3 V | ±5% (3.135–3.465V) | 200 mA | TPS65217 LDO2 | 5th (after IO) |
| VDD_AON | 3.3 V | ±5% (3.135–3.465V) | 100 mA | TPS65217 LDO1 | 1st (always on) |
| VDD_RTC | 3.0 V | ±10% (2.7–3.3V) | 10 µA | Coincell / LDO1 | 2nd (with AON) |

### 2.2 Digital I/O Electrical Characteristics

#### 2.2.1 3.3V Domain (Peripheral GPIO, PWM, RF_CTRL)

| Parameter | Symbol | Min | Typ | Max | Unit | Condition |
|-----------|--------|-----|-----|-----|------|-----------|
| Input High Voltage | VIH | 2.0 | — | 3.6 | V | 5V tolerant inputs |
| Input Low Voltage | VIL | -0.3 | — | 0.8 | V | |
| Output High Voltage | VOH | 2.4 | — | — | V | IOH = -4 mA |
| Output Low Voltage | VOL | — | — | 0.4 | V | IOL = 4 mA |
| Input Leakage | IIL | -1 | — | 1 | µA | 0 < VIN < VDD |
| Pull-up Resistance | RPU | 40 | 60 | 80 | kΩ | When enabled |
| Pull-down Resistance | RPD | 40 | 60 | 80 | kΩ | When enabled |
| Pin Capacitance | CIO | — | 5 | 8 | pF | |

#### 2.2.2 1.8V Domain (SPI, I²C, UART1, I²S, XTAL)

| Parameter | Symbol | Min | Typ | Max | Unit | Condition |
|-----------|--------|-----|-----|-----|------|-----------|
| Input High Voltage | VIH | 0.65×VDD | — | VDD+0.3 | V | Not 5V tolerant |
| Input Low Voltage | VIL | -0.3 | — | 0.35×VDD | V | |
| Output High Voltage | VOH | VDD-0.45 | — | — | V | IOH = -2 mA |
| Output Low Voltage | VOL | — | — | 0.45 | V | IOL = 2 mA |
| Input Leakage | IIL | -1 | — | 1 | µA | 0 < VIN < VDD |
| Pin Capacitance | CIO | — | 3 | 5 | pF | |

### 2.3 Analog Pins

| Pin | Type | Specification |
|-----|------|---------------|
| XTAL_IN | Analog Input | 12 MHz sine/clipped sine, 0.5–1.2 Vpp, AC-coupled |
| XTAL_OUT | Analog Output | 12 MHz drive, ~1 mA, DC bias ~0.9V |

---

## 3. Communication Protocol Interfaces

### 3.1 UART0 (Debug Console)

| Parameter | Value |
|-----------|-------|
| Standard | 16550-compatible |
| Baud Rates | 115200 (default), up to 3 Mbps |
| Data Format | 8 data, 1 stop, no parity (8N1) |
| Flow Control | None |
| FIFO Depth | 16 bytes TX, 16 bytes RX |
| Interrupts | TX empty, RX full, RX timeout, Error |
| Pins | UART0_TX (OUT), UART0_RX (IN) — 1.8V domain |
| Register Map | Base 0x5000_0000 (4 KB) |

### 3.2 UART1 (External Radio Module)

| Parameter | Value |
|-----------|-------|
| Standard | 16550-compatible |
| Baud Rates | Up to 3 Mbps (configurable) |
| Data Format | 8N1, 8E1, 8O1 configurable |
| Flow Control | Optional RTS/CTS (via GPIO mux) |
| FIFO Depth | 32 bytes TX, 32 bytes RX |
| Interrupts | TX empty, RX full, RX timeout, Error, CTS change |
| Pins | UART1_TX (OUT), UART1_RX (IN) — 1.8V domain |
| Register Map | Base 0x5000_0400 (4 KB) |

### 3.3 I²C0 (PMIC + Sensors)

| Parameter | Value |
|-----------|-------|
| Role | Master only |
| Speeds | Standard (100 kbps), Fast (400 kbps), Fast+ (1 Mbps) |
| Addressing | 7-bit (10-bit not supported) |
| Clock Stretching | Supported (slave-initiated) |
| Multi-master | Not supported |
| FIFO | 8 bytes TX, 8 bytes RX |
| Interrupts | TX done, RX done, NACK, Arbitration lost, Timeout |
| Pins | I2C0_SCL (OD), I2C0_SDA (OD) — 1.8V domain, ext. pull-ups 2.2k |
| Register Map | Base 0x5000_1000 (4 KB) |
| PMIC Address | 0x24 (TPS65217 default) |
| Sensor Addresses | 0x48–0x4B (typical temp/humidity), 0x68 (IMU) |

### 3.4 SPI0 / QSPI (Flash + Radio + Aux)

| Parameter | Value |
|-----------|-------|
| Role | Master only |
| Modes | 0, 1, 2, 3 (CPOL/CPHA) |
| Max Frequency | 50 MHz (SDR), 50 MHz DDR (QSPI) |
| Data Width | 1-bit (SPI), 2-bit (Dual), 4-bit (Quad) |
| Chip Selects | 3 (CS0: Flash, CS1: Radio, CS2: Aux) |
| CS Polarity | Active low |
| FIFO | 32 bytes TX, 32 bytes RX |
| Interrupts | TX done, RX done, RX overflow, Mode fault |
| Pins | SCK, MOSI, MISO, CS0_N, CS1_N, CS2_N — 1.8V domain |
| Register Map | Base 0x5000_2000 (4 KB) |

#### 3.4.1 QSPI Flash Profile (CS0)

| Parameter | Value |
|-----------|-------|
| Device | Winbond W25Q512JV (64 MB) or equivalent |
| Mode | Quad DDR (4-bit, double data rate) |
| Read Command | 0xED (Fast Read Quad I/O DDR) |
| Dummy Cycles | 6 (configurable) |
| Address Bytes | 3 (24-bit) or 4 (32-bit) |
| XIP Support | Yes (memory-mapped 0x4000_0000) |
| Max Freq | 50 MHz DDR (effective 100 MB/s) |

#### 3.4.2 Radio SPI Profile (CS1)

| Parameter | Value |
|-----------|-------|
| Device | ESP32-C6 / nRF52840 / EFR32MG21 (module dependent) |
| Mode | SPI Mode 0, Single-bit |
| Max Freq | 25 MHz |
| Protocol | Module-specific (HCI, NCP, etc.) |

### 3.5 PWM (4 Channels)

| Parameter | Value |
|-----------|-------|
| Channels | 4 independent (PWM0–3) |
| Resolution | 16-bit counter + 16-bit duty |
| Frequency Range | 1 Hz – 1 MHz (derived from 25 MHz peripheral clock) |
| Polarity | Active high / low configurable |
| Alignment | Edge / center aligned |
| Dead Time | Optional (for motor control) |
| Synchronization | All channels can sync to PWM0 |
| Interrupts | Period match, Duty match, Overflow |
| Pins | PWM0-3_OUT — 3.3V domain (PERIPH) |
| Register Map | Base 0x5000_4000 (4 KB) |

### 3.6 GPIO (16 Pins)

| Parameter | Value |
|-----------|-------|
| Pins | GPIO0–GPIO15 |
| Direction | Per-pin configurable (IN/OUT/ALT) |
| Input Types | Schmitt trigger, CMOS |
| Output Drive | 4 mA / 8 mA / 12 mA selectable |
| Pull Resistors | Pull-up / Pull-down / None (per pin) |
| Interrupt | Edge (rising/falling/both) + Level (high/low) |
| Debounce | Optional 16-cycle digital filter |
| Alternate Functions | See Section 1.4 |
| Register Map | Base 0x5000_3000 (4 KB) |

### 3.7 I²S (Audio)

| Parameter | Value |
|-----------|-------|
| Role | Master / Slave |
| Sample Rates | 8, 16, 22.05, 24, 32, 44.1, 48 kHz |
| Data Width | 16, 24, 32 bits |
| Format | I²S Philips, Left-Justified, Right-Justified, TDM |
| Channels | 2 (stereo) |
| FIFO | 16 samples TX, 16 samples RX |
| DMA | Optional (future) |
| Interrupts | TX empty, RX full, Underrun, Overrun |
| Pins | BCLK, LRCLK, DIN, DOUT — 1.8V domain |
| Register Map | Base 0x5000_5000 (4 KB) |

### 3.8 Timers

#### 3.8.1 CLINT (Core-Local)
- **MTIME**: 64-bit free-running @ 25 MHz (peripheral clock)
- **MTIMECMP**: 64-bit compare per hart
- **MSIP**: Software interrupt per hart
- **Base**: 0x8000_8000 (32 KB)

#### 3.8.2 Timer0/1 (APB, General Purpose)
- **Width**: 32-bit
- **Modes**: Free-running, Periodic, One-shot
- **Prescaler**: 16-bit (divide 25 MHz)
- **Interrupts**: Match, Overflow
- **Base**: 0x5000_6000, 0x5000_6400 (4 KB each)

#### 3.8.3 LPTIM (AON Domain)
- **Width**: 32-bit
- **Clock**: 32 kHz LPO
- **Modes**: Periodic, One-shot, Wake-on-match
- **Retention**: Counter retained in deep sleep
- **Wake Sources**: Compare match, Overflow, External GPIO
- **Base**: 0x5000_7000 (4 KB)

---

## 4. Debug Interfaces

### 4.1 JTAG (IEEE 1149.1)

| Signal | Direction | Domain | Description |
|--------|-----------|--------|-------------|
| TCK | Input | AON (3.3V) | Test Clock (max 10 MHz) |
| TMS | Input | AON (3.3V) | Test Mode Select |
| TDI | Input | AON (3.3V) | Test Data In |
| TDO | Output | AON (3.3V) | Test Data Out |
| TRST_N | Input | AON (3.3V) | Test Reset (active low, optional) |

- **TAP Controller**: Standard 16-state
- **IDCODE**: 0x1234_567F (example — to be assigned)
- **Debug Module**: RISC-V Debug Spec v0.13+ (DM + DTM)
- **OpenOCD Support**: `target/riscv.cfg` + custom board config

### 4.2 SWD (Optional, Shared Pins)

| Signal | JTAG Pin | Description |
|--------|----------|-------------|
| SWCLK | TCK | Serial Wire Clock |
| SWDIO | TMS | Serial Wire Data I/O |

- **Protocol**: ARM SWD (CMSIS-DAP compatible)
- **Enable**: Via JTAG IR instruction or strap

### 4.3 Trace (Optional, via GPIO Mux)

| Signal | GPIO | Description |
|--------|------|-------------|
| TRACE_CLK | GPIO13 | Trace Clock (50 MHz max) |
| TRACE_DATA[3:0] | GPIO14-15 + 2 more | Trace Data (4-bit) |

- **Protocol**: RISC-V Trace Encoder (Nexus/ETM style)
- **Not in baseline** — future phase

---

## 5. Boot Mode Selection

| BOOT_MODE[1:0] | Mode | Description |
|----------------|------|-------------|
| 00 | Secure Boot | Normal: Boot ROM → signed firmware (default) |
| 01 | JTAG Debug | Halt at reset vector, JTAG enabled, Boot ROM waits |
| 10 | QSPI Direct | Skip Boot ROM, execute XIP from QSPI 0x4000_0000 |
| 11 | Serial Boot | UART0 bootloader (YMODEM) for recovery |

- **Sampling**: At POR release, latched until next POR
- **Pins**: BOOT_MODE0 (pin 10), BOOT_MODE1 (pin 11) — AON domain, 3.3V
- **Pull-downs**: Internal weak pull-down (default = 00)

---

## 6. Clock Interface

### 6.1 Crystal Oscillator (12 MHz)

| Parameter | Specification |
|-----------|---------------|
| Frequency | 12.000 MHz |
| Tolerance | ±20 ppm (initial), ±50 ppm (aging + temp) |
| Load Capacitance | 20 pF |
| Drive Level | 100 µW max |
| ESR | < 80 Ω |
| Package | 3.2×2.5 mm or 2.5×2.0 mm SMD |

### 6.2 External Clock Generator (Si5351)

| Parameter | Specification |
|-----------|---------------|
| Device | Si5351A-B-GT (10-MSOP) or Si5351C |
| Supply | 3.3V (AON domain) |
| I²C Address | 0x60 (default), 0x61 (alt) |
| Reference | Internal 25 MHz XO (integrated) |
| Outputs Used | CLK0: 50.000 MHz → SoC XTAL_IN (AC-coupled) |
| | CLK1: 25.000 MHz → QSPI/Peripheral ref (optional) |
| | CLK2: 32.768 kHz → RTC calibrate (optional) |
| Jitter | < 50 ps RMS (12 kHz–20 MHz) |
| Spread Spectrum | Configurable (EMI reduction) |
| OTP | Pre-programmed at factory for default clocks |

### 6.3 Internal LPO (32 kHz)

| Parameter | Specification |
|-----------|---------------|
| Frequency | 32.768 kHz (nominal) |
| Accuracy | ±10% (uncalibrated), ±1% (calibrated vs Si5351/XTAL) |
| Startup Time | < 100 µs |
| Current | < 1 µA |
| Calibration | Periodic via Timer0 @ 25 MHz reference |

---

## 7. Reset Interface

### 7.1 Global Reset (RESET_N)

| Parameter | Specification |
|-----------|---------------|
| Pin | RESET_N (pin 9) |
| Polarity | Active Low |
| Domain | AON (3.3V) |
| Input Type | Schmitt trigger, weak pull-up (50 kΩ) |
| Minimum Pulse | 1 µs |
| Deglitch | 2-cycle (AON clock) |

### 7.2 Reset Sources and Scope

| Source | Scope | Control |
|--------|-------|---------|
| POR (PMIC) | Full chip | Hardware |
| RESET_N pin | Full chip | Hardware |
| Watchdog (CLINT) | Core only | Register (MTIMECMP) |
| Software (APB) | Peripheral | PERIPH_RST register (0x5000_F000) |
| Debug (JTAG) | Core | DM Control register |
| Brown-out (PMIC) | Core + IO | PMIC ALERT pin |

### 7.3 Reset Sequencing

| Stage | Action | Timing |
|-------|--------|--------|
| 1 | VDD_AON stable | T0 |
| 2 | LPO running | T0 + 100 µs |
| 3 | PMIC I²C ready | T0 + 1 ms |
| 4 | Buck1 (1.0V) enabled | T0 + 2 ms |
| 5 | Buck2 (1.8V) enabled | T0 + 3 ms |
| 6 | LDO2 (3.3V) enabled | T0 + 4 ms |
| 7 | PLL enabled (via Si5351 config) | T0 + 5 ms |
| 8 | Si5351 CLK0 stable | T0 + 10 ms |
| 9 | Global RESET_N released | T0 + 12 ms |
| 10 | Core fetches @ 0x0000_0000 | T0 + 12 ms |

---

## 8. Power Management Interface (PMIC I²C)

| Register | Address | Description |
|----------|---------|-------------|
| DCDC1_CTRL | 0x10 | Buck1 (Core 1.0V) voltage/enable |
| DCDC2_CTRL | 0x12 | Buck2 (IO 1.8V) voltage/enable |
| DCDC3_CTRL | 0x14 | Buck3 (Radio 3.3V) voltage/enable |
| LDO1_CTRL | 0x16 | LDO1 (AON 3.3V) voltage/enable |
| LDO2_CTRL | 0x18 | LDO2 (PERIPH 3.3V) voltage/enable |
| SEQ1 | 0x20 | Power-up sequence slots |
| SEQ2 | 0x21 | Power-down sequence slots |
| GPIO1_CTRL | 0x24 | PMIC_ALERT pin config |
| GPIO2_CTRL | 0x25 | PMIC_IRQ pin config |
| INT_MASK | 0x30 | Interrupt mask (UV/OV/OT/SC) |
| INT_STATUS | 0x31 | Interrupt status |
| VENDOR_ID | 0xFE | 0x0A (TI) |
| PRODUCT_ID | 0xFF | 0x21 (TPS65217) |

- **I²C Bus**: I2C0 (shared with sensors)
- **Address**: 0x24 (7-bit)
- **Speed**: 400 kHz Fast Mode
- **Boot ROM**: Configures PMIC before enabling Core/IO domains

---

## 9. Compliance Interfaces

### 9.1 EMC/EMI (Residential)

| Standard | Requirement | Interface |
|----------|-------------|-----------|
| FCC Part 15B | Unintentional radiator < 30 MHz: 100 µV/m @ 3m | PCB layout, spread spectrum |
| FCC Part 15B | Unintentional radiator > 30 MHz: 150 µV/m @ 3m | PCB layout, spread spectrum |
| EN 55032 Class B | Conducted emissions 150 kHz–30 MHz | PCB filter, PMIC spread spectrum |
| EN 55032 Class B | Radiated emissions 30 MHz–1 GHz | PCB layout, shielding |
| IEC 61000-4-2 | ESD ±4 kV contact, ±8 kV air | Pin protection, PCB design |
| IEC 61000-4-4 | EFT ±1 kV power/signal | PCB filter, TVS diodes |
| IEC 61000-4-5 | Surge ±1 kV (DM), ±2 kV (CM) | PCB protection |

### 9.2 Safety (Mains-Connected Circuits)

| Standard | Requirement | Interface |
|----------|-------------|-----------|
| IEC 62368-1 | Reinforced insulation 2500 Vrms | Creepage ≥ 8.0 mm (Pollution Deg 2, Mat IIIa) |
| UL 62368-1 | Same as IEC | PCB slot, isolation barriers |
| IEC 60664-1 | Creepage/clearance per voltage | Calculated per working voltage |

*SoC itself is low-voltage (3.3V max). Carrier board must implement isolation for any mains-connected relays/triacs.*

---

## 10. Verification of Interfaces

| Interface | Verification Method | Tools |
|-----------|---------------------|-------|
| Pin Assignment | Schematic review, BOM check | KiCad, CSV |
| Electrical DC | Datasheet compliance, bench | SMU, DMM |
| Electrical AC | Timing analysis, scope | Oscilloscope, LA |
| Protocol Compliance | Conformance test suites | UART/I²C/SPI analyzers |
| Timing (STA) | Sign-off corners | OpenSTA (when available) |
| Power Sequencing | HW measurement | Scope, PMIC I²C log |
| EMC Pre-scan | Near-field probe | Spectrum analyzer |
| Safety | Creepage measurement | Calipers, PCB viewer |

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-11 | Lead | Initial release from architecture docs |

---

*This IRS is derived from and traceable to the System Requirements Specification (HAS-SoC-SRS-001) and Architecture Decisions (ARCs).*