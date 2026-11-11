# System Block Diagram

## Overview
This document specifies the top-level system block diagram and subsystem interfaces for the Home-Automation-SoC (HAS-SoC).

## Block Diagram

`
+-------------------------------------------------------------+
|                      Carrier Board / PCB                    |
|                                                             |
|  +-----------------------+     +-------------------------+  |
|  | QSPI Flash (64 MB)    |     | External Wi-Fi / BT /   |  |
|  | (Firmware & OTA)      |     | Zigbee Modules (Ext)    |  |
|  +-----------+-----------+     +------------+------------+  |
|              | (QSPI)                       | (UART/SPI)  |
|  +-----------v------------------------------v------------+  |
|  |                Home-Automation-SoC (QFN-64)           |  |
|  |                                                       |  |
|  |  +---------------------+   +-----------------------+  |  |
|  |  | Core: Ibex (RV32IMC)|   | Peripheral Bus        |  |  |
|  |  | 4-Stage Pipeline    |   | AXI4-Lite to APB      |  |  |
|  |  +----------+----------+   +-----------+-----------+  |  |
|  |             |                          |              |  |
|  |             +------------+-------------+              |  |
|  |                          |                            |  |
|  |  +-----------------------v-------------------------+  |  |
|  |  | Memory Subsystem                                |  |  |
|  |  | - 128 KB On-Chip SRAM Macro                      |  |  |
|  |  | - 32 KB Tightly-Coupled Memory (TCM)            |  |  |
|  |  | - Secure Boot ROM (OpenTitan derived)           |  |  |
|  |  +-------------------------------------------------+  |  |
|  |                                                       |  |
|  |  +-------------------------------------------------+  |  |
|  |  | Peripherals & Interfaces                         |  |  |
|  |  | - PLIC / CLINT (Interrupts & Timers)             |  |  |
|  |  | - UART, SPI, I2C, PWM, GPIO, I2S                 |  |  |
|  |  | - AES-128/256 & SHA-256 Accelerators + TRNG      |  |  |
|  |  | - Low-Power Timer (LPTIM) & Always-On (AON) DOM  |  |  |
|  |  +-------------------------------------------------+  |  |
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
`

## Subsystem Boundary Notes
- **External RF:** Wi-Fi, Bluetooth, and Zigbee modules are external to the SoC.
- **Power & Reset:** PMIC (e.g., TPS65217) and crystal oscillator / PLL provide power domains and clock distribution.
- **Debug:** JTAG/SWD interface accessible for development and test.
