# ASIC Stage 2 — Implementation Work Packages

**Date:** 2026-11-15
**Status:** PLANS ONLY — No production changes made.
**Stage 2 status:** NOT STARTED

These work packages define the implementation scope for Stage 2 (RTL implementation closure) based on approved Stage 1 decisions. No RTL, firmware, SDC, or physical-design changes were made in this task.

## WP-01: Clock Divider and Clock-Domain Implementation

- **Dependencies:** ARC-006 (APPROVED), TD-010 (APPROVED)
- **Affected RTL:** `has_soc.sv` (core_clk, periph_clk, clock gating), new divider module
- **Affected firmware:** `firmware/boot/boot.S` (UART divisor 434→217), APB peripheral constants
- **Tools:** Icarus Verilog, Yosys (synthesis)
- **Verification:** Generated clock STA; frequency test; APB handshake assertions
- **Timing:** New 25 MHz generated clock; CTS with two clocks
- **Acceptance:** /2 divider produces 25 MHz; firmware compiles with 25 MHz constants; simulation passes
- **Rollback:** Revert to single 50 MHz clock (Option A) with explicit descope of FR-CLK-002/004
- **Evidence:** Simulation log, synthesis report, STA report

## WP-02: Reset-Domain Architecture

- **Dependencies:** ARC-006 (APPROVED)
- **Affected RTL:** `reset_ctrl.sv`, new reset synchronizers per domain
- **Affected firmware:** None
- **Tools:** Icarus Verilog, SBY (formal)
- **Verification:** Formal BMC/PDR for reset release; gate-level simulation
- **Timing:** Reset deassert synchronized per domain
- **Acceptance:** Three reset domains (AON, Core, Peripheral); 2-FF synchronizers; formal proofs pass
- **Rollback:** Revert to single reset domain
- **Evidence:** Formal proof logs, simulation log

## WP-03: APB CDC Handshake

- **Dependencies:** ARC-006 (APPROVED), ARC-036 (APPROVED), ARC-065 (APPROVED)
- **Affected RTL:** `axi_lite_to_apb.sv` (rework for 2:1 ratio), new handshake logic
- **Affected firmware:** None
- **Tools:** Icarus Verilog, SBY
- **Verification:** SVA assertions on APB handshake; formal BMC/PDR; CDC structural lint
- **Timing:** Request held until acknowledge; no data overwrite
- **Acceptance:** APB bridge handles 2:1 ratio; no data loss/duplication; formal properties pass
- **Rollback:** Revert to single-clock APB bridge
- **Evidence:** Formal proof logs, CDC lint report

## WP-04: AON Subsystem

- **Dependencies:** ARC-006 (APPROVED), TD-005 (APPROVED)
- **Affected RTL:** New AON domain logic, LPTIM, wake controller, PMU, power switches, isolation, retention
- **Affected firmware:** AON timer/wake driver
- **Tools:** Icarus Verilog, Yosys, OpenROAD (PDN)
- **Verification:** AON wake formal; power-up sequence verification; retention test
- **Timing:** 32.768 kHz AON clock; async crossings to core
- **Acceptance:** AON domain functional; deep sleep achievable; wake timer operational
- **Rollback:** Remove AON domain; descope FR-CLK-004
- **Evidence:** Simulation log, formal proof, power report

## WP-05: Memory Configuration Alignment

- **Dependencies:** TD-001 (APPROVED), TD-003 (APPROVED)
- **Affected RTL:** `has_addr_map.sv` (ROM ADDR_WIDTH 16→14, SRAM ADDR_WIDTH 18→17)
- **Affected firmware:** Firmware recompile with new ADDR_WIDTH; linker script update
- **Tools:** Icarus Verilog, Yosys
- **Verification:** ROM/SRAM contents consistent with maps; read/write patterns verified
- **Timing:** Reduced address decode; minor improvement
- **Acceptance:** ADDR_WIDTH changes applied; firmware compiles; simulation passes
- **Rollback:** Revert ADDR_WIDTH to original values
- **Evidence:** Simulation log, synthesis report

## WP-06: SRAM Macro Integration

- **Dependencies:** TD-003 (APPROVED), TD-006 (RECOMMENDED, pending evidence)
- **Affected RTL:** `sram.sv` wrapper (macro width, port compatibility)
- **Affected firmware:** None
- **Tools:** Yosys, OpenROAD, Liberty characterization
- **Verification:** Macro interface verified; port/mask compatibility; area ≤ 10 mm²
- **Timing:** Liberty .lib multi-corner characterization
- **Acceptance:** 32-bit wide macros integrated; area target met; timing verified
- **Rollback:** Use 4 KB macro tiling (exceeds area target — requires area renegotiation)
- **Evidence:** Macro audit, area report, timing report

## WP-07: Power-Domain Implementation

- **Dependencies:** TD-005 (APPROVED)
- **Affected RTL:** Power switches, isolation cells, retention cells in AON boundary
- **Affected firmware:** None (UPF at Stage 10)
- **Tools:** OpenROAD, UPF/CPF (Stage 10)
- **Verification:** Power-up sequence verification; domain retention test
- **Timing:** Level shifter sizing
- **Acceptance:** Two 1.8 V domains implemented; isolation/retention functional
- **Rollback:** Single power domain (no low-power mode)
- **Evidence:** Power report, UPF file (Stage 10)

## WP-08: Secure Boot Architecture

- **Dependencies:** TD-007 (APPROVED, S0 default)
- **Affected RTL:** None (S0 = no crypto; S3 = external secure element; S1 = blocked)
- **Affected firmware:** `boot.c` (fail-closed, documented as descope for S0)
- **Tools:** None (S0); external secure element (S3); crypto engine (S1, blocked)
- **Verification:** S0: descope documented, no security claims. S3: secure element communication. S1: blocked by BLK-023.
- **Acceptance:** S0 default implemented; no false security claims in marketing
- **Rollback:** N/A (S0 is the fallback)
- **Evidence:** Descope document, security architecture

## WP-09: DFT Architecture

- **Dependencies:** TD-009 (APPROVED, scope)
- **Affected RTL:** Scan flops, test modes, JTAG test access retention
- **Affected firmware:** None
- **Tools:** Scan insertion tool (pending procurement), ATPG (pending)
- **Verification:** Scan insertion before synthesis freeze; test access via JTAG
- **Timing:** Scan chain timing
- **Acceptance:** Scan architecture defined; tool/partner selected; scan inserted before synthesis freeze
- **Rollback:** No DFT (functional test only)
- **Evidence:** DFT plan, tool selection record

## WP-10: Pin and Interface Reconciliation

- **Dependencies:** TD-016 (APPROVED)
- **Affected RTL:** `has_soc.sv` (pad signal reduction 81→54 usable; mux PLIC onto GPIO; add BOOT_MODE, PMIC_ALERT, RF_CTRL, UART1)
- **Affected firmware:** ISR mapping update for GPIO-based interrupts
- **Tools:** Icarus Verilog
- **Verification:** All 54 I/O mapped; firmware ISR mapping updated; PLIC config updated
- **Timing:** None
- **Acceptance:** Pin table matches RTL; board layout updated
- **Rollback:** Revert to 81 pad signals (impossible in QFN-64)
- **Evidence:** Pin table, board layout, simulation log

## WP-11: SDC Architecture

- **Dependencies:** TD-010 (APPROVED), ARC-006 (APPROVED)
- **Affected RTL:** Clock generator (/2 divider)
- **Affected SDC:** `has_soc.sdc` (50 MHz primary + generated 25 MHz); retire 20/40 ns files
- **Tools:** STA tool, CTS
- **Verification:** Generated clock defined; conflicting files retired; CTS signoff with two clocks; glitch logic analyzed
- **Timing:** 50 MHz core, 25 MHz peripheral, 32 kHz AON
- **Acceptance:** SDC clock plan signed; generated clock matches RTL divider
- **Rollback:** Revert to single 20 ns SDC (non-compliant)
- **Evidence:** SDC file, STA report, CTS report

## WP-12: Firmware Clock Updates

- **Dependencies:** ARC-006 (APPROVED), TD-010 (APPROVED)
- **Affected firmware:** `firmware/boot/boot.S` (UART divisor), all APB peripheral drivers (timer, PWM, I2C, SPI, I2S constants halve), AON driver
- **Tools:** GCC (RISC-V), simulation
- **Verification:** Firmware compiles with 25 MHz constants; boot simulation passes
- **Timing:** Peripheral rates at 25 MHz
- **Acceptance:** All APB constants updated; firmware boots on RTL
- **Rollback:** Revert to 50 MHz constants
- **Evidence:** Build log, simulation log

## Summary

12 work packages defined. All are plans only — no production changes made. Stage 2 remains NOT STARTED. Implementation requires Stage 1 completion (ownership assignment + independent audit) and Stage 2 entry approval.