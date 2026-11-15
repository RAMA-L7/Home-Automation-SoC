# Home-Automation-SoC — Tapeout Decision Register

Preserves historical identifiers (`ARC-*`, `M1–M10`) and adds tapeout-level decisions (`TD-*`). No historical decision is overwritten; status is updated only with evidence.

Status: **OPEN** (no answer), **PROPOSED** (answer documented, not approved), **BLOCKED** (cannot be answered yet), **READY FOR APPROVAL** (decision package complete; owner sign-off outstanding), **APPROVED** (owner sign-off recorded), **DEFERRED** (out of scope with rationale).

| ID | Question | Technical impact | Existing evidence | Required owner | Blocking stages | Status | Resolution evidence |
|---|---|---|---|---|---|---|---|
| ARC-006 | Clocking: 50 MHz core, 25 MHz peripheral, 32 kHz AON? | Defines divider, CDC scope, SDC clocks, CTS corners, power domains | `ARCHITECTURE_DECISION_RECORDS.md`; RTL has one gated 50 MHz clock | SoC architect | 1, 2, 6, 8, 12 | READY FOR APPROVAL | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md`; `architecture/clock_architecture.json` |
| ARC-036 | Formal CDC verification for 3 clock domains required? | Scope of formal plan; currently blocked because domains do not exist | CDC plan; RTL single clock | Verification lead | 5, 6 | READY FOR APPROVAL (scope redefined) | `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` |
| ARC-041 | PLL strategy: external Si5351 | Board clock source; SoC has no PLL | PLL decision report; board docs | SoC architect + board | 1, 9 | APPROVED | `reports/` PLL decision report |
| ARC-065 | Formal CDC properties for async FIFO/synchronizers/handshakes | Determines whether CDC IP is built at all | CDC plan; no async FIFO in RTL | Verification lead | 5, 6 | READY FOR APPROVAL (property set) | `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` §3.2 |
| FR-CLK-002 | Peripheral clock = core/2 (25 MHz), synchronous | Requires divide-by-two RTL and generated clock; changes SDC and CTS | `system_requirements.md:136`; RTL gates 50 MHz instead | SoC architect | 1, 2, 6, 8 | OPEN | — |
| TD-001 | Boot ROM size: 16 KB (map) or 64 KB (RTL `ADDR_WIDTH=16`)? | Area, decode, firmware layout, macro count | `has_addr_map.sv` 16 KB; `boot_rom` 64 KB array | SoC architect | 1, 3, 7 | READY FOR APPROVAL (16 KB) | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` |
| TD-002 | TCM size: 32 KB (map) or 32 KB (`ADDR_WIDTH=15`)? | Consistent (32 KB) but must be confirmed as intentional | `has_addr_map.sv`; `sram` param | SoC architect | 1, 3 | PROPOSED (consistent) | — |
| TD-003 | SRAM size: 128 KB (map) or 256 KB (RTL `ADDR_WIDTH=18`)? | Half the array is unreachable; area/PDN impact | `has_addr_map.sv`; `sram` param | SoC architect | 1, 3, 7 | READY FOR APPROVAL (128 KB) | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` |
| TD-004 | Always-on 32 kHz domain: implement or remove from requirements? | Watchdog/low-power wake behavior; UPF scope | No AON RTL; watchdog runs on `clk` | SoC architect | 1, 2, 6, 10 | READY FOR APPROVAL (implement) | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md`; `ASIC_STAGE1_POWER_ARCHITECTURE.md` |
| TD-005 | Power intent: UPF/CPF in scope? | PDN, level shifters, isolation, signoff | No UPF/CPF anywhere; only board-level PMIC prose | SoC architect + PD lead | 1, 10, 15 | READY FOR APPROVAL (two 1.8 V domains; UPF Stage 10) | `reports/ASIC_STAGE1_POWER_ARCHITECTURE.md` |
| TD-006 | Memory macro: `sky130_sram_1rw1r_128x256_8` (4 KB) × 32 for 128 KB, or 32-bit wide macro? | Area, wrapper RTL, timing, port conflicts | Macro audit; 44-macro tiling = 31.8 mm² | SoC architect + PD lead | 3, 9, 10 | READY FOR APPROVAL (32-bit wide macros) | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md`; `architecture/memory_architecture.json` |
| TD-007 | Secure boot: implement verifier or ship fail-closed recovery only? | Security architecture, ROM size, boot time | `boot.c` fails closed; no verifier | Security owner | 1, 2, 17 | READY FOR APPROVAL (S1, S3 fallback, S0 only descope) | `reports/ASIC_STAGE1_SECURITY_BOOT_ARCHITECTURE.md` |
| TD-008 | QSPI flash program/erase in scope for tapeout? | Firmware OTA, pad count, test | `qspi_flash_ctrl.sv` read-only; OTA stub | SoC architect | 1, 2, 4 | READY FOR APPROVAL (defer OTA, read-only boot) | `reports/ASIC_STAGE1_SECURITY_BOOT_ARCHITECTURE.md` §8 |
| TD-009 | DFT: scan + ATPG in scope? Which tool? | Adds scan flops, test modes, schedule | No scan/ATPG; no commercial tool | Program owner | 1, 16, 17 | READY FOR APPROVAL | `reports/ASIC_STAGE1_DECISION_PACKAGE.md` §12 |
| TD-010 | SDC primary period: 20 ns (50 MHz) or 40 ns (25 MHz)? | All timing signoff and CTS | Two conflicting SDCs | Design owner | 8, 12, 15 | READY FOR APPROVAL (50 + generated 25) | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md`; `ASIC_STAGE1_DECISION_PACKAGE.md` §9 |
| TD-011 | I/O timing budgets for 105 ports | Removes 35 unconstrained endpoints; enables signoff | Phase 4.21 M1–M10 | Design owner + system | 8, 15 | OPEN | — |
| TD-012 | Timing regression thresholds / WNS floor (M10) | Enables timing gate in production | Phase 4.22 conditional integration | Design owner | 8, 12, 15 | OPEN | — |
| TD-013 | Adopt post-CTS legalization gate in production? | Fixes off-grid CTS; changes flow | 24/24 regression; byte-identical output | PD lead | 12 | PROPOSED (ready for review) | Phase 4.22 report |
| TD-014 | Antenna strategy: jumper insertion vs diode cells vs router option | Residual violation closure | Phase 4.20/4.22 antenna reports | PD lead | 13, 14 | OPEN | — |
| TD-015 | Die/core size and utilization target for full chip | Floorplan, PDN, routability | Only timer block 95.49 × 95.49 µm | PD lead | 9, 10, 11 | OPEN | — |
| TD-016 | Package pin budget and pinmux | RTL cannot fit QFN-64 with 81 pad signals; 32 IRQ pins dead | `has_soc.sv:25-62`; pin CSV | SoC architect + PD lead | 1, 2, 9, 17 | READY FOR APPROVAL (54-pin plan) | `reports/ASIC_STAGE1_INTERFACE_AND_ADDRESS_MAP.md` §6 |
| TD-017 | Requirements baseline and descopes | SRS describes unimplemented product; 37 FR/IF absent | `architecture/requirements_traceability.csv` | User/design owner | 1, 2, 4, 16, 17 | READY FOR APPROVAL | `reports/ASIC_STAGE1_REQUIREMENTS_TRACEABILITY.md`; `ASIC_STAGE1_DECISION_PACKAGE.md` §11 |
| M1 | Approved pclk period | Timing | Phase 4.21 | Design owner | 8 | OPEN | — |
| M2 | Input delays (71 ports) | Timing | Phase 4.21 | Design owner | 8 | OPEN | — |
| M3 | Output delays (35 ports) | Timing | Phase 4.21 | Design owner | 8 | OPEN | — |
| M4 | Clock latency/transition targets | CTS/STA | Phase 4.21 | Design owner | 8, 12 | OPEN | — |
| M5 | Clock source drive/load model | STA | Phase 4.21 | Design owner | 8 | OPEN | — |
| M6 | Clock uncertainty approval | STA | Phase 4.21 | Design owner | 8 | OPEN | — |
| M7 | APB CDC strategy | RTL/bus | Phase 4.21 | Verification lead | 2, 6 | OPEN | — |
| M8 | Confirm 26 unused inputs | Pinout/STA | Phase 4.21 | Design owner | 8 | OPEN | — |
| M9 | 25 MHz peripheral divider implementation | RTL/clock | Phase 4.21 | SoC architect | 2, 6 | READY FOR APPROVAL | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md` |
| M10 | Timing thresholds | Flow gate | Phase 4.22 | Design owner | 8, 12 | READY FOR APPROVAL | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md`; Phase 4.22 report |

## Rules

- A decision moves to APPROVED only with an owner, date, and evidence path; silence is not approval.
- A PROPOSED decision may unblock design work at risk, never a stage completion gate.
- New decisions use the next `TD-*` ID; historical IDs are preserved verbatim.
