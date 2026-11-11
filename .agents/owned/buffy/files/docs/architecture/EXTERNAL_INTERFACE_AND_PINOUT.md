# External Interface and Pinout Architecture

## 1. Package Selection (DS‑01 Section 7)
- **Primary Package**: QFN‑64 (0.5 mm pitch, 9 mm x 9 mm).
- **Secondary Package (Optional)**: QFN‑100 for high‑feature variants.
- **Justification**: QFN‑64 provides 40+ usable I/O pins, which is sufficient for one AXI master, multiple APB peripherals, and debug. Keeps PCB cost low.

## 2. Pin Assignments (Provisional)

| Pin Category | Count | Signal List | Voltage |
|--------------|-------|-------------|---------|
| **Power/GND** | 12    | VDD_CORE (1.0), VDD_IO (1.8), VDD_PERIPH (3.3), VDD_RTC (3.0), GND | - |
| **System**    | 4     | XTAL_IN, XTAL_OUT, RESET_N, BOOT_MODE | 3.3 V |
| **Debug**     | 6     | TCK, TMS, TDI, TDO, TRST, UART_RX (Debug) | 3.3 V |
| **UART**      | 2     | UART_TX, UART_RX (External Mod) | 1.8 V |
| **I2C Bus**   | 2     | SCL, SDA (Internal PMIC & Sensors) | 3.3 V |
| **SPI Bus**   | 6     | SCK, MOSI, MISO, CS_FLASH, CS_RADIO, CS_AUX | 1.8 V |
| **PWM**       | 4     | PWM_OUT[0:3] | 3.3 V |
| **GPIO**      | 16    | GPIO[0:15] (Shared) | 3.3 V |
| **I2S**       | 4     | BCLK, LRCLK, DIN, DOUT | 1.8 V |
| **Total**     | 56    | - | - |

## 3. PCB Integration (DS‑06 Section 1, 4, 5)
- **Carrier Board**: KiCad v10.0.8 based 4‑layer design (GND/PWR planes).
- **External RF Modules**: Connections via 1.25 mm or 0.1" pitch headers.
- **Regulatory Compliance**: Reinforced isolation slots for mains circuits (>6.4 mm creepage per DS‑06 Section 6 – DOCUMENTED).

## 4. Evidence and Reference
- Package recommendation: DS‑01 Section 7 (QFN‑64).
- PCB design guidelines: DS‑06 Section 5 (KiCad 4‑layer).
- Compliance clearances: DS‑06 Section 6 (UL/CE creepage requirements).
