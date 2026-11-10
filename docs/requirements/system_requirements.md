# System Requirements Specification (SRS) — Home-Automation-SoC

**Document ID:** HAS-SoC-SRS-001  
**Version:** 1.0  
**Date:** 2026-11-11  
**Status:** DRAFT — For Review  
**Classification:** CONFIDENTIAL (Project Internal)

---

## 1. Introduction

### 1.1 Purpose
This document specifies the measurable, verifiable system requirements for the Home-Automation-SoC (HAS-SoC), a low-power RISC-V based System-on-Chip targeting residential home automation applications. The SoC collects sensor data, controls actuators, and communicates with an external host running Home Assistant and a Claude-based voice assistant.

### 1.2 Scope
The HAS-SoC integrates:
- RV32IMC processor (Ibex core)
- Secure boot and cryptographic acceleration
- Multi-protocol peripheral interfaces (UART, SPI, I²C, GPIO, PWM, I²S)
- External connectivity for Wi-Fi, Bluetooth LE, and Zigbee/Thread modules
- Ultra-low-power operation with deep sleep (< 1 mW)
- Over-the-air (OTA) firmware update with cryptographic verification

### 1.3 Definitions and Acronyms

| Acronym | Definition |
|---------|------------|
| **HAS-SoC** | Home-Automation System-on-Chip |
| **AON** | Always-On power domain |
| **CLINT** | Core-Local Interruptor (timer/software interrupts) |
| **DUT** | Device Under Test |
| **DUTY** | PWM duty cycle |
| **ECC** | Error Correction Code |
| **GPIO** | General Purpose Input/Output |
| **LPO** | Low-Power Oscillator (32 kHz RC) |
| **LPTIM** | Low-Power Timer |
| **Matter** | CSA Matter smart home protocol (formerly CHIP) |
| **OTA** | Over-The-Air firmware update |
| **PLC** | Power Line Communication (not used) |
| **PLIC** | Platform-Level Interrupt Controller |
| **PMIC** | Power Management IC (TPS65217) |
| **PMP** | Physical Memory Protection (RISC-V) |
| **PSA** | Platform Security Architecture (Arm/Mbed TLS) |
| **QSPI** | Quad Serial Peripheral Interface |
| **RTC** | Real-Time Clock |
| **SRS** | System Requirements Specification |
| **TCM** | Tightly-Coupled Memory |
| **TRNG** | True Random Number Generator |
| **XIP** | Execute-In-Place (from flash) |

### 1.4 References
- [R1] HOME_AUTOMATION_SOC_ARCHITECTURE.md
- [R2] SYSTEM_BLOCK_DIAGRAM.md
- [R3] PROCESSOR_SELECTION.md (ARC-001)
- [R4] BUS_AND_MEMORY_ARCHITECTURE.md (ARC-002, ARC-003, ARC-019)
- [R5] PERIPHERAL_ARCHITECTURE.md (ARC-005)
- [R6] CLOCK_RESET_AND_POWER_ARCHITECTURE.md (ARC-006, ARC-007, ARC-008)
- [R7] SECURITY_ARCHITECTURE.md (ARC-004, ARC-025, ARC-026)
- [R8] BOOT_AND_FIRMWARE_ARCHITECTURE.md (ARC-018)
- [R9] EXTERNAL_INTERFACE_AND_PINOUT.md (ARC-022, ARC-023)
- [R10] ARCHITECTURE_DECISION_RECORDS.md
- [R11] Phase 0/1A Reports (reports/phase_0/, reports/phase_1a/)
- [R12] Independent Review (agents/deepseek/ARCHITECTURE_INDEPENDENT_REVIEW.md)
- [R13] Specialist Research Reports (agents/deepseek/ds01–ds06/)

---

## 2. Functional Requirements

### 2.1 Processing Subsystem

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-PROC-001** | SoC shall integrate Ibex RV32IMC core (4-stage pipeline, M & C extensions) | Mandatory | RTL sim, FPGA | ARC-001 |
| **FR-PROC-002** | Core shall operate at 50 MHz nominal (1.0V domain) | Mandatory | STA, FPGA | ARC-006 |
| **FR-PROC-003** | Core shall support RISC-V privileged spec v1.12 (M/U modes) | Mandatory | riscv-dv, formal | ARC-001 |
| **FR-PROC-004** | Core shall implement PMP with 16 regions (TOR/NAPOT) | Mandatory | Unit test, formal | ARC-033 |
| **FR-PROC-005** | Core shall support WFI (Wait For Interrupt) for low-power entry | Mandatory | FW test, sim | ARC-008 |

### 2.2 Memory Subsystem

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-MEM-001** | SoC shall provide 128 KB on-chip SRAM (OpenRAM macro, sky130) | Mandatory | RTL sim, STA | ARC-003 |
| **FR-MEM-002** | SoC shall provide 32 KB TCM (zero-wait, direct core connect) | Mandatory | RTL sim, FW | ARC-003 |
| **FR-MEM-003** | SoC shall provide 16 KB Boot ROM (OpenTitan-derived, immutable) | Mandatory | FW boot test | ARC-004 |
| **FR-MEM-004** | SoC shall support 64 MB external QSPI flash (memory-mapped, XIP) | Mandatory | FW boot, sim | ARC-018 |
| **FR-MEM-005** | Memory map shall conform to ARC-019 (32-bit, non-overlapping) | Mandatory | Linker script, sim | ARC-019 |
| **FR-MEM-006** | SRAM shall support optional SECDED ECC (configurable at build) | Optional | Fault injection | ARC-003 |

### 2.3 Bus and Interconnect

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-BUS-001** | CPU-to-memory interconnect shall be AXI4-Lite (32-bit data, no burst) | Mandatory | RTL sim, formal | ARC-002 |
| **FR-BUS-002** | Peripheral interconnect shall be APB (via AXI4-Lite→APB bridge) | Mandatory | RTL sim, formal | ARC-002 |
| **FR-BUS-003** | Ibex req/gnt interfaces shall connect via req/gnt→AXI4-Lite bridge | Mandatory | RTL sim | ARC-011 |
| **FR-BUS-004** | Bridge shall add ≤ 2 cycles latency per transaction | Mandatory | STA, sim | ARC-011 |
| **FR-BUS-005** | All peripheral registers shall be 32-bit, 4-byte aligned (LiteX convention) | Mandatory | Register map review | ARC-020 |

### 2.4 Peripheral Interfaces

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-PER-001** | 2× UART (16550-compatible): 115200–3M baud, FIFO, interrupt | Mandatory | FW driver test | ARC-005 |
| **FR-PER-002** | 1× I²C Master (Standard 100k, Fast 400k, Fast+ 1M): PMIC + sensors | Mandatory | FW driver test | ARC-005 |
| **FR-PER-003** | 1× SPI/QSPI Master: Mode 0/3, up to 50 MHz, 4-bit DDR, CS[3] | Mandatory | FW driver test | ARC-005 |
| **FR-PER-004** | 16× GPIO: configurable I/O, interrupt, pull-up/down, 3.3V tolerant | Mandatory | FW driver test | ARC-005 |
| **FR-PER-005** | 4× PWM: 16-bit resolution, 1 Hz–1 MHz, independent duty/period | Mandatory | FW driver test | ARC-005 |
| **FR-PER-006** | 1× I²S: Master/Slave, 8–48 kHz LRCLK, 16/24/32-bit, DMA optional | Optional | FW driver test | ARC-005 |
| **FR-PER-007** | 2× Timer (32-bit): free-running, compare, interrupt (CLINT) | Mandatory | FW driver test | ARC-005 |
| **FR-PER-008** | 1× LPTIM (32-bit, AON domain): wake from deep sleep, 32 kHz | Mandatory | FW power test | ARC-005 |
| **FR-PER-009** | PLIC: ≥32 external sources, 7-bit priority, preemptive | Mandatory | FW interrupt test | ARC-014 |
| **FR-PER-010** | CLINT: MTIME, MTIMECMP, MSIP (core-local) | Mandatory | FW timer test | ARC-014 |

### 2.5 Security Subsystem

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-SEC-001** | Secure Boot: Verify ECDSA-P256 signature on firmware at POR | Mandatory | FW boot test | ARC-004 |
| **FR-SEC-002** | Boot ROM shall measure firmware hash (SHA-256) for attestation | Mandatory | FW boot test | ARC-033 |
| **FR-SEC-003** | Device Unique Key (DUK): 256-bit from TRNG → OTP at provisioning | Mandatory | Mfg test | ARC-025 |
| **FR-SEC-004** | AES-256 Engine: ECB, CBC, CTR, GCM modes, APB interface | Mandatory | NIST CAVP vectors | ARC-005 |
| **FR-SEC-005** | SHA-256 Engine: Streaming, context save/restore, APB interface | Mandatory | NIST CAVP vectors | ARC-005 |
| **FR-SEC-006** | TRNG: FIPS 140-2 compliant, health tests, 256-bit entropy/req | Mandatory | NIST SP800-90B test | ARC-005 |
| **FR-SEC-006** | OTA Verification: AES-256-GCM decrypt + ECDSA-P256 verify | Mandatory | FW OTA test | ARC-026 |
| **FR-SEC-007** | Rollback Protection: Monotonic counter in OTP/PMIC NVRAM | Mandatory | FW OTA test | ARC-026 |
| **FR-SEC-008** | JTAG/SWD Disable: Fuse bit locks debug after provisioning | Mandatory | Mfg test | ARC-024 |

### 2.6 Clock and Reset

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-CLK-001** | Core clock: 50 MHz from external Si5351 (12 MHz XTAL ref) | Mandatory | FPGA, scope | ARC-006 |
| **FR-CLK-002** | Peripheral clock: 25 MHz (core/2), synchronous | Mandatory | STA, sim | ARC-006 |
| **FR-CLK-003** | QSPI clock: 12.5 MHz (core/4) or 50 MHz DDR, configurable | Mandatory | FW test | ARC-006 |
| **FR-CLK-004** | AON clock: 32 kHz internal RC (LPO), ±10% accuracy | Mandatory | FW wake test | ARC-006 |
| **FR-CLK-005** | Clock gating: Per-peripheral enable via power-domain controller | Mandatory | Power sim | ARC-006 |
| **FR-RST-001** | Global POR: Active-low, multi-stage, PMIC sequenced | Mandatory | HW test | ARC-007 |
| **FR-RST-002** | Core reset: CLINT watchdog + software control | Mandatory | FW test | ARC-007 |
| **FR-RST-003** | Peripheral reset: APB register per peripheral | Mandatory | FW test | ARC-007 |

### 2.7 Power Management

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-PWR-001** | Three power domains: Core (1.0V), IO (1.8V), Peripheral (3.3V), AON (3.3V) | Mandatory | HW bring-up | ARC-008 |
| **FR-PWR-002** | PMIC: TPS65217 (3 buck + 2 LDO), I²C configurable sequencing | Mandatory | HW bring-up | ARC-009 |
| **FR-PWR-003** | Deep sleep: Core/IO/Periph OFF, AON active, < 1 mW total | Mandatory | HW power meas | ARC-008 |
| **FR-PWR-004** | Wake sources: LPTIM, GPIO interrupt, PMIC_ALERT, PMIC_IRQ | Mandatory | FW power test | ARC-008 |
| **FR-PWR-005** | Wake latency: < 10 ms (PLL re-lock + context restore) | Mandatory | HW meas | ARC-008 |
| **FR-PWR-006** | Power-loss detect: PMIC ALERT → backup regulator (10 mA AON) | Mandatory | HW test | ARC-027 |

### 2.8 External Connectivity

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-EXT-001** | Wi-Fi/BLE module: UART1 + SPI0_CS1 + RF_CTRL[1:0] + GPIOs | Mandatory | FW integration | ARC-021 |
| **FR-EXT-002** | Zigbee/Thread module: UART1 (alt) or SPI0_CS1 + RF_CTRL | Mandatory | FW integration | ARC-021 |
| **FR-EXT-003** | Module reset/control via RF_CTRL GPIOs (1.8V domain) | Mandatory | FW test | ARC-021 |

### 2.9 Debug and Test

| ID | Requirement | Priority | Verification | Trace |
|----|-------------|----------|--------------|-------|
| **FR-DBG-001** | JTAG (IEEE 1149.1): TCK, TMS, TDI, TDO, TRST | Mandatory | OpenOCD | ARC-024 |
| **FR-DBG-002** | SWD (optional): SWCLK, SWDIO (shared with JTAG) | Optional | OpenOCD | ARC-024 |
| **FR-DBG-003** | Debug UART: UART0_TX/RX for console (115200 8N1) | Mandatory | Terminal | ARC-024 |

---

## 3. Non-Functional Requirements

### 3.1 Performance

| ID | Requirement | Target | Verification | Trace |
|----|-------------|--------|--------------|-------|
| **NFR-PERF-001** | Core frequency | 50 MHz | STA, FPGA | ARC-006 |
| **NFR-PERF-002** | Boot time (POR to app main) | < 200 ms | HW meas | ARC-018 |
| **NFR-PERF-003** | Secure boot verification | < 100 ms | HW meas | ARC-004 |
| **NFR-PERF-004** | Interrupt latency (PLIC → handler) | < 50 cycles | Sim, FW meas | ARC-014 |
| **NFR-PERF-005** | Context switch (Zephyr) | < 5 µs | FW bench | — |
| **NFR-PERF-006** | QSPI throughput (XIP, DDR) | ≥ 20 MB/s | FW bench | ARC-018 |
| **NFR-PERF-007** | AES-256 throughput | ≥ 10 MB/s | HW bench | ARC-005 |
| **NFR-PERF-008** | SHA-256 throughput | ≥ 15 MB/s | HW bench | ARC-005 |

### 3.2 Power Consumption

| ID | Requirement | Target | Verification | Trace |
|----|-------------|--------|--------------|-------|
| **NFR-PWR-001** | Active (all domains, 50 MHz) | < 500 mW | HW meas | Power Budget |
| **NFR-PWR-002** | Core domain (1.0V) | < 555 mA (worst 125°C) | HW meas, sim | Power Budget |
| **NFR-PWR-003** | IO domain (1.8V) | < 100 mA | HW meas | Power Budget |
| **NFR-PWR-004** | Peripheral domain (3.3V, SoC only) | < 200 mA | HW meas | Power Budget |
| **NFR-PWR-005** | AON domain (3.3V) | < 1 mA | HW meas | Power Budget |
| **NFR-PWR-006** | Deep sleep (AON only) | < 1 mW (≈300 µA @ 3.3V) | HW meas | Power Budget |
| **NFR-PWR-007** | Wake energy (deep sleep → active) | < 10 mJ | HW meas | Power Budget |

### 3.3 Area (ASIC Target: SkyWater 130nm)

| ID | Requirement | Target | Verification | Trace |
|----|-------------|--------|--------------|-------|
| **NFR-AREA-001** | Total die area | < 10 mm² | PNR report | ARC-003 |
| **NFR-AREA-002** | Core (Ibex + caches) | ~1.5 mm² | PNR report | ARC-001 |
| **NFR-AREA-003** | SRAM (128 KB) | ~3.5 mm² | OpenRAM | ARC-003 |
| **NFR-AREA-004** | TCM (32 KB) | ~0.8 mm² | PNR report | ARC-003 |
| **NFR-AREA-005** | Peripherals + Bus | ~2.0 mm² | PNR report | ARC-005 |
| **NFR-AREA-006** | Security (AES/SHA/TRNG/ROM) | ~1.5 mm² | PNR report | ARC-005 |
| **NFR-AREA-007** | Analog/PLL/PMIC I/F | ~0.5 mm² | PNR report | ARC-006 |

### 3.4 Environmental and Reliability

| ID | Requirement | Target | Verification | Trace |
|----|-------------|--------|--------------|-------|
| **NFR-ENV-001** | Operating temperature | -40°C to +85°C | Qual | — |
| **NFR-ENV-002** | Junction temperature (max) | +125°C | Thermal sim | — |
| **NFR-ENV-003** | ESD (HBM) | ±2 kV | Qual | — |
| **NFR-ENV-004** | ESD (CDM) | ±500 V | Qual | — |
| **NFR-ENV-005** | Latch-up immunity | ±100 mA | Qual | — |
| **NFR-ENV-006** | EMI/EMC (residential) | FCC Part 15B, EN 55032 | System test | ARC-023 |
| **NFR-ENV-007** | Safety (mains isolation) | IEC 62368-1, UL 62368 | System design | ARC-023 |

### 3.5 Quality and Manufacturing

| ID | Requirement | Target | Verification | Trace |
|----|-------------|--------|--------------|-------|
| **NFR-QUA-001** | DFT Scan Coverage | > 95% | ATPG report | ARC-037 |
| **NFR-QUA-002** | MBIST Coverage (SRAM/TCM/ROM) | 100% | MBIST run | ARC-037 |
| **NFR-QUA-003** | DRC/LVS Clean | 0 errors | Sign-off | ARC-037 |
| **NFR-QUA-004** | STA Sign-off (all corners) | 0 violations | STA report | ARC-037 |
| **NFR-QUA-005** | IR-Drop (max) | < 10% VDD | IR analysis | ARC-037 |
| **NFR-QUA-006** | Electromigration | < 0.1 mA/µm | EM analysis | ARC-037 |

---

## 4. Interface Requirements

### 4.1 Pin Interface (QFN-64)

| ID | Requirement | Specification | Verification | Trace |
|----|-------------|---------------|--------------|-------|
| **IF-PIN-001** | Package | QFN-64, 0.5mm pitch, 9×9mm, exposed pad | Mech dwg | ARC-022 |
| **IF-PIN-002** | Usable I/O | 56 pins (excl. power/GND/EP) | Pin assignment | ARC-023 |
| **IF-PIN-003** | Voltage domains on pins | 1.0V, 1.8V, 3.3V per assignment | Pin assignment | ARC-023 |
| **IF-PIN-004** | Pin assignment | Per `constraints/pin_assignment_qfn64.csv` | Schematic | ARC-023 |

### 4.2 Electrical Interface

| ID | Requirement | Specification | Verification | Trace |
|----|-------------|---------------|--------------|-------|
| **IF-ELE-001** | Core supply (VDD_CORE) | 1.0V ±5%, max 1.2A (Buck1) | HW meas | Power Budget |
| **IF-ELE-002** | IO supply (VDD_IO) | 1.8V ±5%, max 1.2A (Buck2) | HW meas | Power Budget |
| **IF-ELE-003** | Peripheral supply (VDD_PERIPH) | 3.3V ±5%, max 200mA (LDO2) | HW meas | Power Budget |
| **IF-ELE-004** | AON supply (VDD_AON) | 3.3V ±5%, max 100mA (LDO1) | HW meas | Power Budget |
| **IF-ELE-005** | RTC backup (VDD_RTC) | 3.0V ±10%, 10µA (coincell) | HW meas | Power Budget |
| **IF-ELE-006** | Digital I/O (3.3V domain) | 3.3V CMOS, 5V tolerant (inputs) | HW meas | Pin assignment |
| **IF-ELE-007** | Digital I/O (1.8V domain) | 1.8V CMOS, not 5V tolerant | HW meas | Pin assignment |
| **IF-ELE-008** | Crystal oscillator | 12 MHz, 20pF load, ±20 ppm | HW meas | ARC-006 |
| **IF-ELE-009** | External clock (Si5351 CLK0) | 50 MHz, LVCMOS, AC-coupled | HW meas | PLL Decision |

### 4.3 Communication Protocols

| ID | Requirement | Specification | Verification | Trace |
|----|-------------|---------------|--------------|-------|
| **IF-COM-001** | UART0 (Debug) | 115200 8N1, no flow control | Terminal | ARC-005 |
| **IF-COM-002** | UART1 (Radio) | Up to 3M baud, 8N1, RTS/CTS opt | Radio FW | ARC-021 |
| **IF-COM-003** | I²C0 (PMIC/Sensors) | 400 kHz Fast Mode, 7-bit addr | Scope/LA | ARC-005 |
| **IF-COM-004** | SPI0 (QSPI Flash) | Mode 0, 50 MHz DDR, 4-bit | Scope/LA | ARC-005 |
| **IF-COM-005** | SPI0 (Radio) | Mode 0, 25 MHz, CS1 | Scope/LA | ARC-021 |
| **IF-COM-006** | I²S (Audio) | Master, 48 kHz, 24-bit, I²S Philips | Scope/LA | ARC-005 |

### 4.4 Software/Firmware Interface

| ID | Requirement | Specification | Verification | Trace |
|----|-------------|---------------|--------------|-------|
| **IF-SW-001** | ISA | RV32IMC (base + M + C) | riscv-dv | ARC-001 |
| **IF-SW-002** | ABI | ILP32 (riscv32-unknown-elf-) | Toolchain | ARC-001 |
| **IF-SW-003** | RTOS | Zephyr v3.6+ (LTS) | FW build | ds04 |
| **IF-SW-004** | Crypto API | Mbed TLS PSA (v3.5+) | FW test | ARC-025 |
| **IF-SW-005** | Boot Protocol | Secure Boot → Zephyr → App | FW test | ARC-018 |
| **IF-SW-006** | OTA Protocol | Matter OTA / Custom signed | FW test | ARC-026 |
| **IF-SW-007** | Debug Protocol | OpenOCD + GDB (JTAG/SWD) | Debug test | ARC-024 |

---

## 5. Verification Requirements

| ID | Requirement | Method | Trace |
|----|-------------|--------|-------|
| **VR-001** | RTL Simulation (Verilator + Icarus) | Unit + Integration | All FR |
| **VR-002** | Formal Verification (SymbiYosys) | CDC, RST, Bus properties | ARC-036 |
| **VR-003** | FPGA Prototype (Nexys A7-100T) | Functional + Performance | All FR |
| **VR-004** | Firmware Unit Tests (Zephyr Ztest) | CI/CD | All FR-PER, FR-SEC |
| **VR-005** | Firmware Integration Tests | Renode + HW | All FR |
| **VR-006** | Power Measurement (Active/Sleep) | HW bench | NFR-PWR |
| **VR-007** | EMI/EMC Pre-compliance | Near-field scan | NFR-ENV-006 |
| **VR-008** | ASIC Sign-off (if tapeout) | DRC/LVS/STA/IR/EM | NFR-QUA |

---

## 6. Traceability Matrix (Requirements → Architecture Decisions)

| Req ID | Architecture Decision (ARC) | Status |
|--------|----------------------------|--------|
| FR-PROC-001..005 | ARC-001, ARC-006, ARC-008, ARC-010, ARC-033 | PROPOSED |
| FR-MEM-001..006 | ARC-003, ARC-004, ARC-010, ARC-013, ARC-019 | PROPOSED |
| FR-BUS-001..005 | ARC-002, ARC-011, ARC-012, ARC-019, ARC-020 | PROPOSED |
| FR-PER-001..010 | ARC-005, ARC-006, ARC-014, ARC-020 | PROPOSED |
| FR-SEC-001..008 | ARC-004, ARC-025, ARC-026, ARC-033, ARC-024 | PROPOSED |
| FR-CLK-001..005 | ARC-006, ARC-041 (Si5351 decision) | PROPOSED |
| FR-RST-001..003 | ARC-007, ARC-031 | PROPOSED |
| FR-PWR-001..006 | ARC-008, ARC-009, ARC-027, ARC-028, ARC-029 | PROPOSED |
| FR-EXT-001..003 | ARC-021, ARC-023 | PROPOSED |
| FR-DBG-001..003 | ARC-024, ARC-032 | PROPOSED |
| NFR-PERF-001..008 | ARC-001, ARC-006, ARC-018, ARC-014 | ESTIMATED |
| NFR-PWR-001..007 | ARC-008, ARC-009, ARC-027, ARC-028, ARC-029 | MEASURED (analysis) |
| NFR-AREA-001..007 | ARC-001, ARC-003, ARC-005, ARC-006 | ESTIMATED |
| NFR-ENV-001..007 | ARC-022, ARC-023 | STANDARD |
| NFR-QUA-001..006 | ARC-037 (BLOCKED) | BLOCKED |

---

## 7. Acceptance Criteria

The HAS-SoC design shall be considered **Stage 0 Complete** when:

1. [ ] All functional requirements (FR-*) have measurable verification criteria defined
2. [ ] All non-functional requirements (NFR-*) have quantitative targets with verification methods
3. [ ] All interface requirements (IF-*) are specified with electrical/timing parameters
4. [ ] Traceability matrix covers 100% of requirements to ARC decisions
5. [ ] System Requirements Review (SRR) conducted with stakeholders
6. [ ] Architecture Decision Records (ADRs) updated to APPROVED for all mandatory items
7. [ ] Architecture freeze blocker ARC-035 cleared (ARC-001 approved)
8. [ ] PLL strategy documented and approved (ARC-006, ARC-041)
9. [ ] Pin assignment verified against package (ARC-023)
10. [ ] Power budget validated against PMIC capability (ARC-028, ARC-029)

The design shall be considered **Architecture Approved (Gate 1)** when:
- All 72 ARC decisions are at APPROVED status
- Human sign-off obtained on ARC-001 (Ibex), ARC-002 (Bus), ARC-006 (Clock), ARC-009 (PMIC)
- RTL Readiness Specification (Phase 1A) 100% satisfied

---

## 8. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-11-11 | Lead | Initial draft from architecture docs and research reports |
| 1.0 | 2026-11-11 | Lead | Complete SRS for SRR |

---

*This SRS is a living document. Updates require traceability to ARC decisions and change control board approval.*