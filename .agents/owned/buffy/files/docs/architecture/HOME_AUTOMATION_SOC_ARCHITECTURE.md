# Home Automation SoC Architecture

## Purpose
The Home‑Automation‑SoC (HAS‑SoC) is a low‑power, RISC‑V based System‑on‑Chip targeting residential automation. It integrates a configurable core, boot ROM, SRAM, QSPI flash, interrupt controller, timers, debug, UART, SPI, I²C, PWM, GPIO, I2S, and external Wi‑Fi/BLE/Zigbee connectivity. The architecture is grounded in the six discipline research reports (IP, RTL, Verification, Firmware, ASIC, PCB) and follows open‑source ASIC flow (OpenLane 2/OpenROAD) using the SkyWater 130 nm PDK.

## High‑Level Block Diagram
`
+-------------------+      +-------------------+
|   Boot ROM       |      |   QSPI Flash      |
|   (Secure ROM)   |----->|   (Firmware Img)  |
+-------------------+      +-------------------+
        |                         |
        v                         v
+-------------------+   +-------------------+
|   Core (Ibex)     |   |   Peripherals     |
|   (RV32IMC)       |<->|   AXI4‑Lite Bus   |
+-------------------+   +-------------------+
        |                         |
        v                         v
+-------------------+
|   Interrupt Ctrl  |
+-------------------+
``n
The architecture decisions are detailed in the subsequent documents.

---

**References**
- IP Research Report – ds01_ip_research/report.md
- RTL Research Report – ds02_rtl_research/report.md
- Verification Research Report – ds03_verification_research/report.md
- Firmware Research Report – ds04_firmware_research/report.md
- ASIC Research Report – ds05_asic_research/report.md
- PCB Research Report – ds06_pcb_research/report.md
