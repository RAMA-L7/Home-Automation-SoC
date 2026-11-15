# Tapeout Stage 0 — Repository Baseline and Evidence Audit

Date: 2026-11-15
Repository: `D:\Home-Automation-SoC`
Branch: `main`
HEAD: `3fb1f0492b0dd460bd70d1a06a36b536b3d4280e`
Scope: read-only audit. No RTL, constraint, flow script, PDK, experiment or report was modified. No Git mutation.

---

## 1. Executive conclusion

The project contains a **functional RTL prototype that boots and passes a 22-test simulation regression**, plus a **single-block (timer) physical-design experiment** taken as far as extracted STA with DRC 0. It does **not** contain a full-SoC synthesizable netlist, approved constraints, full-chip floorplan/PDN/placement/CTS/routing, LVS, DFT or GDSII.

**No tapeout stage beyond Stage 0 is complete.** Stage 1 (architecture closure) is the earliest incomplete stage on the critical path.

The dominant technical problem is not missing code volume; it is **architecture/RTL mismatch**: the specified 50/25/32 kHz clocking, memory map and power domains do not exist in the RTL, and the two SDC files disagree on the clock period.

---

## 2. Preservation and Git state (Part 1.2)

| Item | Measured value |
|---|---|
| Branch | `main` |
| HEAD | `3fb1f0492b0dd460bd70d1a06a36b536b3d4280e` |
| Tracked modifications | **none** (`git status --porcelain` shows only `??`) |
| Untracked paths | 52 |
| Historical "8 modified files" | **not present in the working tree today.** Historical status is not reproducible; no attempt was made to recreate it. |
| Existing experiment dirs | `experiments/asic_phase4_18_cts_repair`, `_19`, `_20`, `_21`, `_22` |
| Production CTS artifacts | `build/asic_flow/phase3_2_cts/output/timer_cts.{def,odb}` present, hashes unchanged |
| Production SDC | `build/asic_flow/phase3_2_cts/constraints/timer_pclk_provisional.sdc` hash unchanged |
| Git mutations | none (no add/commit/push/reset/clean/stash/checkout) |

Preservation hashes (SHA-256, first 8 bytes): CTS DEF `ca9d99de…6e44`; SDC `d9d77685…4c69`; production `run_cts.tcl` `91d37121…`; Phase 4.21 gate `afc91caf…122f`. Phase 4.22's own preservation audit is EV-021.

Untracked content includes the entire `experiments/` tree, all ASIC phase reports, several new testbenches and `reports/evidence/`. These are the project's de-facto evidence base and must be committed or archived by the owner, not deleted.

---

## 3. Repository inventory (Part 2.1)

| Category | Count | Paths |
|---|---:|---|
| SystemVerilog RTL files | 24 | `rtl/rtl_top/`, `rtl/rtl_peripherals/` |
| Unique RTL modules | 23 | 22 submodules + `has_soc` top |
| Testbench files | 36 | `sim/` (28 at `sim/sim_top`) |
| Registered regression tests | 22 | `scripts/eda/run_regression.js` |
| Firmware C/asm/header files | 9 | `firmware/bare_metal/`, `firmware/boot/` |
| Constraint files | 3 | `constraints/`, `build/asic_flow/...` |
| Scripts | 40 | `scripts/{eda,formal,fw,docs,agents}` |
| Documentation | 26 md | `docs/` |
| Reports | 72 md | `reports/` |
| ASIC experiment trees | 5 | `experiments/asic_phase4_18…22` |
| Flow build dirs | 15 | `build/asic_flow/**` |
| UPF/CPF | **0** | none anywhere |
| GDSII | **0** | none |
| LVS reports | **0** | none |

Tooling measured this session: Icarus Verilog 14.0 (`s20260301-500-g2e81fcccb-dirty`), Node v26.7.0. Formal: SBY v0.69, Yosys 0.69+154. PD: OpenROAD `bazel-nostamp` under WSL Ubuntu-24.04. Verilator, Magic, Netgen, KLayout and OpenLane 2 are installed per `D:\tools\EDA_TOOL_REGISTRY.md` but were not exercised in this audit except OpenROAD via the existing Phase 4.22 artifacts.

---

## 4. RTL completeness audit (Part 2.2)

Module inventory (all 23 modules):

| Module | Source | Function | Inst | Verification | Synthesis | Status | Blockers |
|---|---|---|---|---|---|---|---|
| `has_soc` | `rtl/rtl_top/has_soc.sv` | Top-level SoC, clock gates, address decode, IRQ aggregation | top | `tb_boot`, `tb_firmware` | **full-SoC FAILED** (Yosys parse) | IMPLEMENTED, PARTIAL | BLK-001, BLK-002, BLK-004 |
| `riscv_core` | `rtl/rtl_top/riscv_core.sv` | RV32IMC 2-stage core | 1 | `tb_isa`, boot | block-level historical | IMPLEMENTED | ignores `rresp/bresp`; no misaligned fault |
| `boot_rom` | `rtl/rtl_top/boot_rom.sv` | Boot ROM (inferred array) | 1 | boot | block-level | IMPLEMENTED | 64 KB array vs 16 KB map |
| `sram` | `rtl/rtl_top/sram.sv` | Dual-access inferred SRAM | 2 | `tb_sram`, `tb_sram_audit` | generic block-level | IMPLEMENTED | size mismatch; no macro |
| `axi_lite_interconnect` | `rtl/rtl_top/axi_lite_interconnect.sv` | 1×6 AXI4-Lite fabric | 1 | exercised in boot | block-level | IMPLEMENTED | no dedicated TB/formal |
| `axi_lite_to_apb` | `rtl/rtl_top/axi_lite_to_apb.sv` | AXI4-Lite→APB bridge | 1 | exercised in boot | block-level | IMPLEMENTED | APB CDC strategy open (M7) |
| `req_gnt_to_axi_lite` | `rtl/rtl_top/req_gnt_to_axi_lite.sv` | Core req/gnt adapter | 1 | exercised in boot | block-level | IMPLEMENTED | — |
| `intc_axi` | `rtl/rtl_top/intc_axi.sv` | CLINT+PLIC AXI wrapper | 1 | exercised in boot | not proven | IMPLEMENTED | no direct TB |
| `plic` | `rtl/rtl_peripherals/plic.sv` | 4-source PLIC | 1 | `tb_plic`, `tb_plic_proto`, formal | block-level | IMPLEMENTED | pulse-loss documented |
| `clint` | `rtl/rtl_peripherals/clint.sv` | Timer/software IRQ | 1 | `tb_clint` | block-level | IMPLEMENTED | — |
| `gpio` | `rtl/rtl_peripherals/gpio.sv` | 16-bit GPIO | 1 | `tb_gpio`, boot | block-level | IMPLEMENTED | — |
| `uart` | `rtl/rtl_peripherals/uart.sv` | 115200 UART | 1 | `tb_uart`, boot | block-level | IMPLEMENTED | no FIFO/parity |
| `i2c_ctrl` | `rtl/rtl_peripherals/i2c_ctrl.sv` | I²C master | 1 | `tb_i2c` | block-level | IMPLEMENTED | — |
| `spi_ctrl` | `rtl/rtl_peripherals/spi_ctrl.sv` | SPI master | 1 | `tb_spi`, `tb_spi_device` | block-level | IMPLEMENTED | mode 0 only; `pstrb` ignored |
| `pwm` | `rtl/rtl_peripherals/pwm.sv` | 4-channel PWM | 1 | `tb_pwm`, boot | block-level | IMPLEMENTED | — |
| `timer` | `rtl/rtl_peripherals/timer.sv` | General timer | 1 | `tb_timer` | block-level | IMPLEMENTED | — |
| `watchdog` | `rtl/rtl_peripherals/watchdog.sv` | Watchdog | 1 | `tb_watchdog`, `tb_watchdog_audit`, formal | block-level | IMPLEMENTED | — |
| `i2s` | `rtl/rtl_peripherals/i2s.sv` | I²S | 1 | `tb_i2s` | block-level | IMPLEMENTED | — |
| `qspi_flash_ctrl` | `rtl/rtl_peripherals/qspi_flash_ctrl.sv` | QSPI read controller | 1 | **none** | block-level | PARTIAL | program/erase absent (BLK-015) |
| `power_mgr` | `rtl/rtl_peripherals/power_mgr.sv` | Power/wake FSM | 1 | `tb_power_mgr`, formal CDC | block-level | IMPLEMENTED | brown-out detector absent |
| `power_mgr_regs` | `rtl/rtl_peripherals/power_mgr_regs.sv` | APB power regs | 1 | `tb_power_mgr` | block-level | IMPLEMENTED | — |
| `debug_jtag` | `rtl/rtl_peripherals/debug_jtag.sv` | JTAG TAP subset | 1 | `tb_debug_jtag`, `tb_jtag_proto` | **0 cells (stub) historically** | PARTIAL | no DMI/IDCODE (BLK-018) |
| `reset_ctrl` | `rtl/rtl_top/reset_ctrl.sv` | Bounded watchdog reset | 1 | `tb_reset_ctrl`, unbounded formal | block-level | IMPLEMENTED | — |

Notes:
- No `TODO`/`FIXME`/`XXX`/`TBD` markers exist in RTL. Gaps are documented in prose instead, which is why they are easy to miss.
- All 23 modules are instantiated except the top.
- `debug_jtag` synthesizing to 0 cells while its testbench passes is a **contradiction**: either the synthesis script excluded it or the logic is optimized away. It must be resolved before Stage 2 can close.

---

## 5. Architecture audit (Part 2.3)

### 5.1 Requirements vs RTL

| Requirement / decision | Documented | RTL reality | Discrepancy |
|---|---|---|---|
| 50 MHz core | ARC-006, requirements | `clk` directly gates core; SDC says 20 ns | Implemented only if the pad is 50 MHz; no PLL |
| 25 MHz peripheral (core/2) | ARC-006, FR-CLK-002 | `periph_clk = clk & periph_clk_en_q` | **No divider.** Peripherals run at 50 MHz |
| 32 kHz always-on | ARC-006, clock doc | No AON clock, no `clk_aon`, watchdog on `clk` | **Absent** |
| Boot ROM 16 KB | `has_addr_map.sv` | `ADDR_WIDTH=16` → 64 KB array | RTL 4× larger |
| TCM 32 KB | map + RTL | `ADDR_WIDTH=15` → 32 KB | Consistent |
| SRAM 128 KB | map | `ADDR_WIDTH=18` → 256 KB array | RTL 2× larger; half unreachable |
| APB 1 MB @ `0x5000_0000` | map/ADR | decode present | consistent |
| Secure boot with signature | security doc | verifier returns failure by design | **Requirement unmet** |
| 3 power domains (1.0/1.8/3.3 V) | clock/power doc | single 1.8 V sky130hd flow | Not implemented; no UPF |
| JTAG debug | docs | TAP subset only, no DMI | Partial |

### 5.2 Recorded contradictions (do not silently resolve)

1. **C-01 Clocking:** three-domain specification vs one gated clock; no divider; no AON (BLK-001).
2. **C-02 Memory map:** ROM/SRAM array sizes vs decode sizes (BLK-002).
3. **C-03 SDC:** `has_soc.sdc` 20 ns vs `timer_pclk_provisional.sdc` 40 ns (BLK-003).
4. **C-04 Security:** "secure boot" documented; implementation intentionally rejects every image (BLK-006).
5. **C-05 Debug:** JTAG described as debug interface; RTL lacks DMI/IDCODE and synthesizes to 0 cells.
6. **C-06 Verification counts:** `TEST_RESULTS.md` says 8 PASS/4 BLOCKED; runner says 22/22; `build/verify/summary.txt` says 25/25.
7. **C-07 Power:** board-level PMIC domains presented alongside SoC architecture; no SoC power intent.
8. **C-08 ASIC status:** `AGENTS.md` stage table says "scripts only"; five experiment phases and a routed block exist.

---

## 6. Clock, reset and power audit (Part 2.4)

- **Core clock:** `assign core_clk = clk & core_clk_en_q` (`has_soc.sv:107`). Gated copy, not divided.
- **Peripheral clock:** `assign periph_clk = clk & periph_clk_en_q` (`:108`). Same frequency as core.
- **Enable synchronizer:** enables are captured on `negedge clk` before gating — glitch-safe for a single clock.
- **No PLL, no `clk_aon`, no 32 kHz, no divider.**
- **Reset:** external `reset_n` asynchronously asserts `rst_sys_n`; watchdog timeout is converted by `reset_ctrl` into a 16-cycle pulse. `reset_ctrl` is the only **unbounded** formal proof.
- **CDC:** the design has one clock. The CDC plan's three-domain content has no object in RTL. Real pin-level crossings: `spi_miso` (same SCK domain, argued safe), `plic.ext_irq` (2-FF sync, pulse-loss documented), `debug_jtag.tms/tdi` (single flop).
- **RDC:** no separate reset domains; `rst_sys_n` is the only internal reset. No RDC analysis tool run.

**Classification: clock/reset/power architecture is PARTIAL and cannot close until BLK-001/BLK-008 are resolved.**

---

## 7. Memory and IP audit (Part 2.5)

| Memory | RTL capacity | Mapped capacity | Type | Macro | LEF/Liberty | Verification |
|---|---:|---:|---|---|---|---|
| Boot ROM | 64 KB (`2^16` B) | 16 KB | inferred `logic [31:0] mem[16384]` | none | n/a | boot sim |
| TCM | 32 KB | 32 KB | inferred dual-access array | none | n/a | `tb_sram`, audit |
| SRAM | 256 KB | 128 KB | inferred dual-access array | none | n/a | `tb_sram`, audit |
| Flash | external | 64 MB window | QSPI controller, read-only | external | n/a | none |

Macro candidate: `sky130_sram_1rw1r_128x256_8` — actually **256 × 128 bit = 4 KB**, 1rw+1r, 16-bit write mask, TT-only Liberty, LEF 1141.72 × 632.475 µm. To build 128 KB requires **32 macros** plus a width/mask adapter; no wrapper RTL exists. Audit verdict: macro compatible with a wrapper, **not integrated**.

IP inventory: in-repo RV32IMC core (no third-party CPU IP); AXI4-Lite fabric; APB peripherals; JTAG TAP; no PLL, no USB, no Ethernet, no crypto accelerator, no ADC.

---

## 8. Verification audit (Part 2.6)

### 8.1 Executed this audit

Command (with `D:/tools/oss-cad-suite/bin` on PATH):

```
node scripts/eda/run_regression.js
```

Result: **22/22 PASS, exit 0**, revision `3fb1f04`, iverilog 14.0. Tests: isa, boot, uart, reset_ctrl, power_mgr, clint, plic, gpio, spi, i2c, pwm, timer, watchdog, i2s, sram, debug_jtag, firmware, plic protocol, spi device model, jtag protocol, watchdog audit, sram audit.

Without the tool PATH the same runner reports `iverilog: unavailable` and 0/22 BUILD-FAIL — the toolchain is not on the default PATH and must be set explicitly.

### 8.2 Formal

`build/formal/formal.log`: **5/5 PASS** (watchdog BMC 96; reset_ctrl unbounded PDR; reset_ctrl_seq BMC 60; cdc_power_mgr BMC 30; plic_regs BMC 52). The interconnect formal task is **ERROR 16**: Yosys fails to parse unpacked-array ports in `axi_lite_interconnect.sv:57`.

### 8.3 Evidence integrity findings

1. `build/verify/summary.txt` claims `regression marker "PASS 25 / 25"` but the runner contains 22 tests and prints `PASS 22 / 22`. It cannot have been produced by the current tree.
2. `build/verify/regression.log` was 0 bytes at audit start, yet the summary records a PASS marker that must appear in that log.
3. `reports/verification/TEST_RESULTS.md` still reports 8 PASS / 4 BLOCKED and "13 blocks" — superseded, not reconciled.

These are recorded as BLK-010; no evidence was deleted or rewritten.

### 8.4 Coverage and gaps

No functional coverage, no code coverage, no mutation run in the current gate, no QSPI flash model, no I²C/SPI/JTAG device-level interoperability tests beyond the protocol benches, no full-SoC formal.

---

## 9. Synthesis and physical-design audit (Part 2.7)

### 9.1 Synthesis

| Item | Status |
|---|---|
| RTL elaboration (full SoC) | **FAILED** — Yosys 0.69 `has_soc.sv:65 unexpected TOK_IMPORT` |
| Block-level synthesis | 13 blocks historically 0 problems; `debug_jtag` 0 cells |
| Technology mapping (full SoC) | none |
| Area report (full SoC) | none |
| Full-SoC timing | none |
| Reproducible synthesis script | none for full SoC |

### 9.2 Physical design — measured scope

Only the **timer block** has been physically implemented:

| Metric | Value | Evidence |
|---|---|---|
| Die area | 95.49 × 95.49 µm | `timer_cts.def` |
| Instances | 421 (406 pre-CTS + 15 CTS cells) | Phase 4.22 |
| Nets | 386 | Phase 4.22 |
| Placement | legal (`check_placement` clean) | Phase 4.22 log |
| CTS | 10 clkbufs, 67 sinks, skew 0.105 ns, latency 0.31 ns | Phase 4.22 |
| Routing | DRT complete, **DRC 0**, wire 11,285 µm, vias 2,561 | Phase 4.22 |
| Antenna | **1 net / 1 pin residual** (`pwdata[10]`) | Phase 4.22 |
| Extraction | SPEF generated, single corner | Phase 4.22 |
| STA | setup 38.01 ns, hold 0.43 ns, TNS 0 | Phase 4.22 |
| LVS | **never run** | — |
| IR/EM | **never run** | — |

Full-chip floorplan, PDN, placement, CTS, routing, DRC, LVS, IR and EM: **none**.

### 9.3 Experiment classification

| Phase | Result | Classification |
|---|---|---|
| 3.8 original CTS | 15 off-grid CTS cells | EXPERIMENTAL, not signoff |
| 4.18 selective CTS repair | 15/15 repaired, 0 non-CTS | EXPERIMENTAL |
| 4.19 routing / optimizer | DRC 0, 43,107 dbU displacement | EXPERIMENTAL |
| 4.20 RCX + antenna repair | 0 antenna after repair, WNS 37.42 | EXPERIMENTAL |
| 4.21 SDC audit + gate prototype | 9/9 regression, gate prototype | EXPERIMENTAL |
| 4.22 gate integration | 24/24 regression; gate validated; 1 antenna residual | EXPERIMENTAL, partial integration |

None of these is full-chip evidence. They are correctly scoped as timer-block experiments and must not be presented as tapeout signoff.

---

## 10. Stage assessment summary (Part 6)

| Stage | Genuine status | Basis |
|---|---|---|
| 0 Baseline | **COMPLETE** | this audit |
| 1 Architecture | NOT STARTED (2/8) | ADRs PROPOSED; C-01/C-02 open |
| 2 RTL | PARTIAL (2/6) | boots and passes sim; clock/memory/security gaps |
| 3 IP/memory | PARTIAL (1/6) | inferred memories; macro not integrated |
| 4 Functional verification | PARTIAL (2/5) | 22/22 sim; no coverage |
| 5 Formal | PARTIAL (1/5) | 5 block proofs; fabric/core unproven |
| 6 CDC/RDC | BLOCKED (1/5) | plan assumes domains that do not exist |
| 7 Full synthesis | BLOCKED (0/8) | parser failure |
| 8 SDC | BLOCKED (1/6) | conflicting periods; 105 ports missing |
| 9–15 PD/signoff | NOT STARTED | timer block only |
| 16 DFT | NOT STARTED | none |
| 17–18 GDS/package | NOT STARTED | none |

---

## 11. First engineering objective (Part 6 answer)

**Stage 1 — Architecture and requirements closure**, specifically:

1. Decide the clock architecture: implement core/2 divider + AON, or formally descope 25 MHz/32 kHz and re-baseline requirements, SDC and CDC plan.
2. Publish one memory table that matches RTL parameters and decode; fix arrays or map.
3. Resolve power intent scope (UPF vs single domain).
4. Approve or reject ARC-006/036/041/065 with owner and date.
5. Produce requirements-to-RTL traceability.

Stage 1 is chosen over Stage 7 because synthesizing the current RTL would enshrine the wrong memory sizes and clock architecture, forcing a redo of synthesis, SDC, floorplan and CTS.

---

## 12. Deliverables produced

- `TAPEOUT_MASTER_TRACKER.md`
- `TAPEOUT_EVIDENCE_REGISTRY.md`
- `TAPEOUT_DECISION_REGISTER.md`
- `TAPEOUT_BLOCKER_REGISTER.md`
- `reports/TAPEOUT_STAGE0_BASELINE_AUDIT.md` (this file)
- `reports/TAPEOUT_MASTER_ROADMAP.md`
- `reports/TAPEOUT_CRITICAL_PATH_ANALYSIS.md`
- `reports/TAPEOUT_STAGE_COMPLETION_GOVERNANCE.md`

## 13. Preservation statement

No production file was modified. The audit only created the eight governance documents listed above. Git HEAD and branch are unchanged; no commit, push, reset, clean, stash or checkout was performed. The audit did execute the existing regression runner, which rewrote `build/sim/regression.log` and `build/sim/*.vvp` build outputs — these are generated artifacts, not source; the previous `regression.log` was already 0 bytes. This is disclosed rather than hidden.
