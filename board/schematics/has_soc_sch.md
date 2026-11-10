# Home-Automation-SoC — Reference Carrier Board Schematic (Documentation)
# Stage 8 PCB

## Overview
Reference carrier board for the Home-Automation-SoC QFN-64 device.
4-layer KiCad design: Signal-GND-PWR-Signal.

## Power Architecture
| Rail | Voltage | Current | Source |
|------|---------|---------|--------|
| VDD_CORE | 1.0 V | 500 mA | TPS65217 DCDC1 |
| VDD_IO | 1.8 V | 200 mA | TPS65217 DCDC2 |
| VDD_PERIPH | 3.3 V | 300 mA | TPS65217 DCDC3 |
| VDD_RTC | 3.0 V | 10 mA | TPS65217 LDO1 + coin cell |

PMIC: TI TPS65217 (I2C-controlled, 3 buck + 2 LDO)

## Clock
- 12 MHz crystal (reference for PLL)
- External Si5351 clock generator optional for 50 MHz system clock
- 32.768 kHz RTC crystal for AON domain

## Peripherals
- QSPI flash: 64 MB (W25Q512JV or equivalent)
- UART: USB-UART bridge (CP2102 or CP210x) to host
- I2C: BME280 (temp/humidity), SHT3x, EEPROM, PMIC
- SPI: External radio module (Wi-Fi/BLE/Zigbee)
- GPIO: Relays, LEDs, buttons
- PWM: LED dimming, motor control
- I2S: Audio output (optional, external amp)

## Debug
- JTAG header (6-pin: TCK, TMS, TDI, TDO, TRST, GND)
- UART console header

## Mains Safety (if mains-connected)
- Reinforced isolation per IEC 60664-1 / UL 840
- Creepage/clearance calculated per interface (not blanket 6.4 mm)
- Optocoupler for zero-cross detection
- Slot cuts in PCB for isolation

## Status: NOT STARTED
- KiCad not confirmed installed in this environment
- No schematic (.kicad_sch) or PCB (.kicad_pcb) files created
- BOM not generated

## Next Steps (when KiCad available)
1. Create KiCad project with 4-layer stack-up
2. Draw schematic: SoC, QSPI flash, PMIC, crystal, JTAG, UART, headers
3. PCB layout with controlled impedance for QSPI/SPI
4. Generate Gerbers, BOM, assembly drawings
5. Bring-up guide: power-on sequence, JTAG verification, UART console
