# Home Automation SoC – Phase 0 Architecture Report

## Executive Summary
The Phase 0 architecture defines the first‑iteration architecture for a low‑power residential Home‑Automation‑SoC.  The design is based firmly on the six research reports (DS‑01‑DS‑06).  It proposes an Ibex (lowRISC) core, AXI4‑Lite + APB bus, 128 KB SRAM, 32 KB TCM, and 64 MB QSPI flash.  Security is achieved via an OpenTitan‑derived secure boot ROM and cryptographic accelerators.  Power management relies on TPS65217 PMIC and a 32 kHz recharge oscillator for deep sleep.  The device will be fabricated in the SkyWater 130 nm process with an initial QFN‑64 package.

## Architecture Highlights
- **Processor**: Ibex RV32IMC (open‑source, verified).* 
- **Bus**: AXI4‑Lite master to memory, APB to peripherals.*
- **Memory**: 128 KB SRAM macro, 32 KB TCM, 64 MB QSPI.
- **Security**: OpenTitan secure boot ROM, AES‑256 & SHA‑256 engines, TRNG.*
- **Power**: TPS65217 PMIC (1.0 V, 1.8 V, 3.3 V rails), 32 kHz LPO.*
- **External Interface**: UART, SPI, I²C, PWM, GPIO, I²S, and external RF modules via dedicated headers.*
- **Package**: QFN‑64.
- **Verification**: Formal checks via Yosys + SymbiOS; simulation with Verilator + cocotb; test plan via riscv-dv and Renode.*

## Risks & Unresolved Items
1. **DFT/ATPG** – No open‑source solution; requires commercial tool (CRITICAL).* 
2. **IR‑Drop Sign‑off** – Requires commercial sign‑off (CRITICAL).* 
3. **RF Isolation** – Layout for EMI compliance pending.*
4. **Clock Source & PLL Specs** – Confirmed bandwidth and jitter unknown.*
5. **Power‑Domain Sequencing** – Detailed PMIC sequencing tables not yet finalised.*

The architecture is **not approved**.  All decisions are marked PROPOSED in the ADRs and require human approval before proceeding to RTL.  The documents will provide a complete traceability matrix, evidence tags, and mapping of requirements to implementation.

* All statements reference DS‑01, DS‑02, DS‑03, DS‑04, DS‑05, DS‑06.
