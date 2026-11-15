# ASIC Stage 1 — Architecture Baseline Audit

Date: 2026-11-15
Baseline: `3fb1f0492b0dd460bd70d1a06a36b536b3d4280e` (branch `main`)
Scope: read-only investigation. No RTL, SDC, flow script, PDK or experiment was modified.
Status: **READY FOR APPROVAL — Stage 1 is not complete.**

---

## 1. Executive conclusion

The architecture documents describe a **four-domain, crypto-capable, 64 MB-XIP, 56-pin IoT SoC**. The RTL implements a **single-clock, machine-mode RV32IM SoC** with inferred memories, one UART, one SPI, one I2C, 16 GPIO, four PWM channels, an 8-source PLIC and a single-line QSPI read engine.

The distance is not a missing feature here and there. It is a **different product baseline**. Stage 2 cannot start until the owner chooses either (a) implement the documented architecture, or (b) re-baseline the requirements to the implementable product. This report records every discrepancy with evidence and a recommended resolution; it does not choose silently.

**17 discrepancies** are recorded (D-01…D-17). Four are correctness-critical: clocking (D-01), core ISA/privilege (D-02), memory sizes (D-03/D-04), and pin budget (D-08).

---

## 2. Method

1. Read `AGENTS.md`, the Stage 0 audit, tracker, registers and roadmap.
2. Read all requirements (`system_requirements.md`, `interface_requirements.md`) and all architecture documents.
3. Inspected the 23 RTL modules, with emphasis on `has_soc.sv`, `has_addr_map.sv`, `riscv_core.sv`, `boot_rom.sv`, `sram.sv`, `qspi_flash_ctrl.sv`, `axi_lite_to_apb.sv`, `intc_axi.sv`, `plic.sv`, `clint.sv`, `power_mgr.sv`, `reset_ctrl.sv`, `debug_jtag.sv`.
4. Inspected firmware (`linker.ld`, `boot.S`, `drivers.h`) for memory and address assumptions.
5. Cross-checked verification evidence (`build/sim/regression.log`, `build/formal/formal.log`, `reports/verification/*`).
6. Recorded every contradiction without editing historical documents.

Commands used (read-only): `grep`, `sed`, `sha256sum`, `node scripts/eda/run_regression.js` (Stage 0), Python parsers for the SRS and RTL.

---

## 3. Discrepancy register

### D-01 — Clock architecture not implemented

| Field | Value |
|---|---|
| Requirement | FR-CLK-001..005; ARC-006 |
| Documentation | 50 MHz core, 25 MHz peripheral (core/2), 32 kHz AON LPO, per-peripheral gating |
| RTL behavior | `core_clk = clk & core_clk_en_q`; `periph_clk = clk & periph_clk_en_q` — both 50 MHz; no divider, no 32 kHz, no PLL |
| Evidence | `rtl/rtl_top/has_soc.sv:92-109`; `architecture/clock_architecture.json` |
| Technical impact | Peripherals run 2× specified; UART/timer/PWM scales wrong; deep sleep impossible; CDC plan describes domains that do not exist |
| Affected modules | `has_soc`, all APB peripherals, `power_mgr`, `plic`, `reset_ctrl` |
| Downstream | SDC (TD-010), CTS, STA, power, CDC, firmware timing |
| Recommended resolution | Adopt C-prime: 50 MHz core, internal /2 25 MHz peripheral, external 32.768 kHz AON; see clock report |
| Required approval | User/design owner — ARC-006, FR-CLK-002, FR-CLK-004 |

### D-02 — Core is not the specified Ibex RV32IMC with M/U and PMP

| Field | Value |
|---|---|
| Requirement | FR-PROC-001 (Ibex RV32IMC), FR-PROC-003 (priv 1.12 M/U), FR-PROC-004 (PMP 16 regions) |
| Documentation | Ibex, M & C extensions, M/U modes, PMP |
| RTL behavior | Custom multi-cycle core; header states "RV32IM … Not supported: C extension, F/D, atomics, user mode, PMP" |
| Evidence | `rtl/rtl_top/riscv_core.sv:2,20-21`; ISA regression is RV32IM + traps |
| Technical impact | No compressed code (size), no privilege separation, no memory protection; security architecture cannot be implemented on this core |
| Affected modules | `riscv_core`, boot firmware, MPU/secure boot |
| Downstream | Stage 2, Stage 5 formal, Stage 7 synthesis/area, Stage 16 DFT |
| Recommended resolution | Either replace with Ibex (matching docs) or re-baseline ISA to RV32IM machine-mode and descope PMP/security partitioning |
| Required approval | ARC-001, TD-017 |

### D-03 — Boot ROM: RTL 64 KB vs mapped 16 KB

| Field | Value |
|---|---|
| Requirement | FR-MEM-003: 16 KB immutable boot ROM |
| Documentation | 16 KB at 0x0000_0000–0x0000_3FFF |
| RTL behavior | `boot_rom ADDR_WIDTH=16` → 16384 words = 64 KB array; decode only 16 KB; 48 KB unreachable |
| Evidence | `rtl/rtl_top/boot_rom.sv:14,49`; `rtl/rtl_top/has_addr_map.sv:10-11`; linker `bootrom 16K` |
| Technical impact | Area 4× too large; synthesis/floorplan estimate wrong; firmware fits 16 KB |
| Affected modules | `boot_rom`, decode, linker |
| Downstream | Stage 3, 7, 9 |
| Recommended resolution | 16 KB mask ROM; set `ADDR_WIDTH=14` or explicit DEPTH=4096 words |
| Required approval | TD-001 |

### D-04 — SRAM: RTL 256 KB vs mapped 128 KB

| Field | Value |
|---|---|
| Requirement | FR-MEM-001: 128 KB on-chip SRAM |
| Documentation | 128 KB at 0x2000_0000–0x2001_FFFF |
| RTL behavior | `sram ADDR_WIDTH=18` → 65536 words = 256 KB; decode 128 KB; upper half unreachable |
| Evidence | `rtl/rtl_top/sram.sv:13,50`; `has_addr_map.sv:14-15`; firmware stack `0x2001_0000` |
| Technical impact | Doubles memory area; macro count/area plan wrong; firmware already assumes 128 KB |
| Affected modules | `sram`, decode, linker |
| Downstream | Stage 3, 7, 9, 10 |
| Recommended resolution | 128 KB; `ADDR_WIDTH=17` or DEPTH=32768 words |
| Required approval | TD-003 |

### D-05 — QSPI: 64 MB window, 16 MB addressable, no XIP/DDR/program/erase

| Field | Value |
|---|---|
| Requirement | FR-MEM-004: 64 MB memory-mapped XIP; FR-PER-003 quad; ARC-039 4-bit DDR |
| Documentation | Winbond W25Q512, quad DDR, XIP at 0x4000_0000 |
| RTL behavior | AXI slave read engine issues single-line 0x03 with 24-bit address; writes return SLVERR; no quad/DDR/cache/program/erase; 64 MB window aliases 16 MB four times |
| Evidence | `rtl/rtl_peripherals/qspi_flash_ctrl.sv:7-10,110-111`; `has_addr_map.sv:17-18` |
| Technical impact | Cannot boot XIP at required throughput; cannot OTA; NFR-PERF-006 fails (~6.25 MB/s vs ≥20 MB/s) |
| Affected modules | `qspi_flash_ctrl`, boot, OTA |
| Downstream | Stage 2, 3, 4, 13 |
| Recommended resolution | Either reduce window to 16 MB, or implement 4-byte addressing + quad read; OTA/program/erase explicitly deferred or implemented |
| Required approval | TD-017, security/OTA decision |

### D-06 — APB peripheral base addresses differ between docs and RTL

| Field | Value |
|---|---|
| Requirement | ARC-020; interface requirements §3 |
| Documentation | UART0 0x5000_0000, I2C 0x1000, SPI 0x2000, GPIO 0x3000, PWM 0x4000, I2S 0x5000, Timer 0x6000, LPTIM 0x7000, AES 0x8000 |
| RTL behavior | GPIO 0x0000, UART 0x1000, I2C 0x2000, SPI 0x3000, PWM 0x4000, Timer 0x5000, WDOG 0x6000, I2S 0x7000, PWR 0x8000 |
| Evidence | `rtl/rtl_top/has_soc.sv:512-523`; `has_addr_map.sv:23-40`; firmware `drivers.h:12-20` |
| Technical impact | Documentation-driven firmware would write the wrong peripheral; register maps in SRS are wrong |
| Affected modules | `has_soc`, all firmware, docs |
| Downstream | Stage 2, 4 |
| Recommended resolution | Adopt the RTL map (firmware already matches) and correct SRS/ADR/interface docs; no RTL change |
| Required approval | TD-016 (interface baseline) |

### D-07 — Interrupt controller map and capacity differ

| Field | Value |
|---|---|
| Requirement | FR-PER-009: PLIC ≥32 sources, 7-bit priority; FR-PER-010 CLINT standard |
| Documentation | PLIC 0x8000_0000 (32 KB), CLINT 0x8000_8000 (32 KB) |
| RTL behavior | CLINT 0x8000_0000 (4 KB), PLIC 0x8000_1000 (4 KB), 8 sources, 8-bit priority; MTIME at 0x7F8 not 0xBFF8 |
| Evidence | `intc_axi.sv:5-7`; `plic.sv:2-12`; `clint.sv:8-17` |
| Technical impact | Non-standard CLINT offsets break RISC-V software expectations; only 8 interrupts; 32 external IRQ pins are dead |
| Affected modules | `plic`, `clint`, `intc_axi`, `has_soc` |
| Downstream | Stage 2, 4, 5 |
| Recommended resolution | Document 8 sources and custom offsets for first silicon, or expand PLIC and restore architectural CLINT offsets; remove dead ext_irq pins |
| Required approval | TD-016, TD-017 |

### D-08 — Pin budget: RTL 81 pad signals vs QFN-64 56 usable I/O

| Field | Value |
|---|---|
| Requirement | IF-PIN-002: 56 usable I/O; ARC-022/023; ARC-042 |
| Documentation | QFN-64 with 56 I/O, pinmux, UART1, PMIC, RF_CTRL, BOOT_MODE |
| RTL behavior | 81 pad signals: 32-bit `ext_irq` (dead), 5 JTAG, 16 GPIO, 6 QSPI, 4 I2S, 4 PWM, 4 SPI, 2 I2C, 2 UART, plus status/handshake pins. No pinmux, UART1, PMIC, RF_CTRL, BOOT_MODE |
| Evidence | `has_soc.sv:25-62`; `constraints/pin_assignment_qfn64.csv`; Stage 1 interface report |
| Technical impact | RTL cannot be packaged in the specified package without muxing; 32 IRQ pins are wasted |
| Affected modules | `has_soc`, pad ring, package, board |
| Downstream | Stage 2, 9, 17, 18 |
| Recommended resolution | Remove `ext_irq[31:0]` and three internal handshake pins; mux 8 PLIC sources onto GPIO; add BOOT_MODE, PMIC, RF_CTRL, UART1 → 54 I/O |
| Required approval | TD-016 |

### D-09 — Power architecture: four domains documented, one 1.8 V domain implemented

| Field | Value |
|---|---|
| Requirement | FR-PWR-001..006; ARC-008 |
| Documentation | AON 3.3 V, core 1.0 V, IO 1.8 V, periph 3.3 V, PMIC TPS65217, retention/isolation/level shifters |
| RTL behavior | Single `clk`/`reset_n`; only clock gating in `power_mgr`; no UPF/CPF, no isolation, no retention, no level shifters, no PMIC interface |
| Evidence | `rtl/rtl_peripherals/power_mgr.sv`; repository-wide no `.upf`/`.cpf`; sky130hd is 1.8 V |
| Technical impact | Deep sleep <1 mW unachievable; power intent undefined; 3.3 V/1.0 V pads not available in the open PDK |
| Affected modules | `power_mgr`, `has_soc`, pad ring |
| Downstream | Stage 10, 15, 17 |
| Recommended resolution | Two SoC domains at 1.8 V (AON + switchable); board/PMIC supplies 1.0 V/3.3 V rails; UPF for two domains; explicit single-domain fallback if UPF not feasible |
| Required approval | TD-005, TD-017 |

### D-10 — Security architecture is aspirational; implementation fails closed

| Field | Value |
|---|---|
| Requirement | FR-SEC-001..008: ECDSA secure boot, SHA-256, TRNG, AES, OTP, rollback, debug lock |
| Documentation | OpenTitan ROM, crypto accelerators, OTP, A/B OTA |
| RTL/firmware | No crypto/TRNG/OTP; `boot_verify_signature()` returns failure by design; OTA is a fail-closed stub |
| Evidence | `firmware/bare_metal/boot.c:102-109`; `firmware/bare_metal/ota.c:5`; RTL inventory |
| Technical impact | No secure boot, no measured boot, no OTA; the product cannot claim security compliance |
| Affected modules | boot ROM, crypto (absent), OTP (absent), QSPI |
| Downstream | Stage 2, 4, 5, 17 |
| Recommended resolution | Choose S1 (hardware SHA/ECDSA + key store) or S0 (explicit descope, remove claims); do not ship fail-closed-only labelled secure boot |
| Required approval | TD-007 |

### D-11 — Peripheral feature set is narrower than the SRS

| Field | Value |
|---|---|
| Requirement | FR-PER-001..010 |
| Documentation | 2× UART with FIFO, I2C with stretch, SPI 3 CS/modes 0–3, GPIO pulls/alt functions, I2S RX/24/32-bit, 2 timers, LPTIM, PLIC 32 |
| RTL behavior | 1 UART no FIFO; I2C single-byte no stretch; SPI mode 0 one CS; GPIO no pulls/mux; I2S TX 16-bit only; 1 APB timer; no LPTIM; PLIC 8 |
| Evidence | Peripheral headers and `interface_inventory.csv` |
| Technical impact | Firmware and board assumptions break; pinmux absent |
| Affected modules | all peripherals |
| Downstream | Stage 2, 4 |
| Recommended resolution | Re-baseline feature list per TD-017, or implement the missing features in Stage 2 |
| Required approval | TD-017 |

### D-12 — Boot/ROM and OTA do not match the documented flow

| Field | Value |
|---|---|
| Requirement | ARC-018, ARC-026 |
| Documentation | ROM verifies QSPI image, A/B partitions, rollback |
| RTL/firmware | ROM executes a hand-written test image from 0x0000_0000; no QSPI load/verify; no A/B; no rollback counter |
| Evidence | `firmware/boot/boot.S`; linker; boot.c |
| Technical impact | Production boot flow does not exist |
| Affected modules | boot_rom, qspi, firmware |
| Downstream | Stage 2, 4, 17 |
| Recommended resolution | Define first-silicon boot: ROM → TCM/SRAM image from QSPI read → optional hash; defer verified/OTA |
| Required approval | TD-007 |

### D-13 — LPTIM, per-peripheral reset and pinmux are absent

| Field | Value |
|---|---|
| Requirement | FR-PER-008, FR-RST-003, ARC-058 |
| Documentation | LPTIM at 0x5000_7000, PERIPH_RST at 0x5000_F000, APB pinmux at 0x5000_C000 |
| RTL behavior | None of these blocks exists; 0x7000 is I2S, 0x8000 is power manager; no reset or pinmux registers |
| Evidence | `has_addr_map.sv`; `has_soc.sv:512-523` |
| Technical impact | Deep-sleep wake and pin multiplexing impossible; reset granularity missing |
| Affected modules | has_soc, power_mgr, pad ring |
| Downstream | Stage 2, 6, 10 |
| Recommended resolution | Implement in Stage 2 or descope with owner approval |
| Required approval | TD-017, ARC-006 |

### D-14 — Verification evidence claims are inconsistent

| Field | Value |
|---|---|
| Requirement | Stage 0 governance |
| Documentation | `TEST_RESULTS.md` says 8 PASS / 4 BLOCKED and 13 blocks; `build/verify/summary.txt` says 25/25 |
| Actual | Current runner executes 22 tests and passes 22/22; formal 5/5; full-SoC synthesis fails |
| Evidence | Stage 0 audit; `build/sim/regression.log` |
| Technical impact | Green claims cannot be trusted without re-running |
| Affected modules | verification gate |
| Downstream | Stage 4 |
| Recommended resolution | Reconcile counts and regenerate logs; one source of truth |
| Required approval | Verification owner |

### D-15 — Memory macro strategy cannot meet the area target

| Field | Value |
|---|---|
| Requirement | NFR-AREA-001 <10 mm²; FR-MEM-001/002/003 |
| Documentation | OpenRAM 128 KB macro ~3.5 mm² |
| Reality | Available macro is 4 KB, 128-bit, 0.722 mm²; 44 macros for 176 KB = 31.8 mm² |
| Evidence | `reports/SKY130_SRAM_MACRO_INTERFACE_AUDIT.md`; `architecture/memory_architecture.json` |
| Technical impact | Area target fails by >3× if the 4 KB macro is tiled |
| Affected modules | memories, floorplan, PDN |
| Downstream | Stage 3, 9, 10 |
| Recommended resolution | Obtain/generate 32-bit wide 128 KB and 32 KB macros; otherwise re-approve area or memory sizes |
| Required approval | TD-006 |

### D-16 — SDC files disagree on the primary period

| Field | Value |
|---|---|
| Requirement | Stage 8 |
| Documentation | `has_soc.sdc` 20 ns (50 MHz); `timer_pclk_provisional.sdc` 40 ns (25 MHz) |
| Actual | No full-SoC SDC; block SDC is provisional with 35 unconstrained endpoints |
| Evidence | Both files |
| Technical impact | No consistent timing signoff basis |
| Downstream | Stage 8, 12, 15 |
| Recommended resolution | One SDC plan per approved clock architecture (50 core + 25 generated) |
| Required approval | TD-010 |

### D-17 — DFT and signoff claims are blocked, not planned

| Field | Value |
|---|---|
| Requirement | NFR-QUA-001..006 |
| Documentation | Scan >95%, MBIST 100%, DRC/LVS/STA/IR/EM clean |
| Reality | No scan/ATPG/MBIST/IR/EM; only a timer-block DRC run |
| Evidence | ARC-037/066/067 BLOCKED |
| Technical impact | No manufacturing test or electrical signoff |
| Downstream | Stage 16, 17, 18 |
| Recommended resolution | Decide DFT scope/tooling in Stage 1; budget or descope |
| Required approval | TD-009/TD-017 |

---

## 4. Contradiction summary by category

| Category | Count | Highest severity |
|---|---:|---|
| Clock/reset | 2 (D-01, D-16) | P0 |
| Core/ISA | 1 (D-02) | P0 |
| Memory | 3 (D-03, D-04, D-15) | P0 |
| Bus/interrupt/map | 3 (D-05, D-06, D-07) | P1 |
| Power | 1 (D-09) | P0 |
| Security/boot | 2 (D-10, D-12) | P1 |
| Interfaces/pins | 2 (D-08, D-13) | P0 |
| Peripheral features | 1 (D-11) | P1 |
| Verification/docs | 1 (D-14) | P1 |
| DFT | 1 (D-17) | P1 |
| **Total** | **17** | |

---

## 5. What is actually consistent

- RTL address decode and `has_addr_map_pkg` agree with each other for ROM/TCM/SRAM/QSPI/APB/INTC.
- Firmware and the linker script already use the intended 16/32/128 KB sizes and the RTL APB order.
- AXI4-Lite fabric, APB bridge, GPIO, UART, PWM, timer, watchdog, I2S, SRAM, boot and firmware paths are simulation-verified (22/22).
- Reset controller behavior is formally proven unbounded.
- PLIC/GPIO/UART input synchronizers exist where implemented; the remaining unsafe inputs are identified in the CDC report.

---

## 6. Stage 1 status

| Acceptance item | Result |
|---|---|
| Clock architecture approved | **NO** — package prepared |
| CDC/RDC scope approved | **NO** — package prepared |
| PLL/external clock recorded | ARC-041 approved historically; board confirmation pending |
| One memory architecture | **NO** — recommendation prepared |
| Peripheral clock strategy approved | **NO** |
| AON/power strategy approved or descoped | **NO** |
| Traceability complete | **YES (analysis)** — 124 requirements mapped; approvals pending |
| No unresolved decision blocking Stage 2 | **NO** — 12 decisions require owner approval |
| Role owners assigned | **NO** — user is authority; roles proposed only |
| Independent architecture audit | This document; independent human audit pending |

**Stage 1 remains READY FOR APPROVAL. Stage 2 must not start.**

---

## 7. Documents produced

- `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md`
- `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md`
- `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md`
- `reports/ASIC_STAGE1_POWER_ARCHITECTURE.md`
- `reports/ASIC_STAGE1_SECURITY_BOOT_ARCHITECTURE.md`
- `reports/ASIC_STAGE1_REQUIREMENTS_TRACEABILITY.md`
- `reports/ASIC_STAGE1_INTERFACE_AND_ADDRESS_MAP.md`
- `reports/ASIC_STAGE1_DECISION_PACKAGE.md`
- Machine-readable: `architecture/{clock_architecture.json,memory_architecture.json,cdc_rdc_matrix.csv,requirements_traceability.csv,interface_inventory.csv,decision_status.json}`
