# Home-Automation-SoC — ASIC Enablement Design Decision Review

**Document type:** Design decision review (no implementation)
**Date:** 2026-11-14
**Repository:** `D:\Home-Automation-SoC`
**Baseline HEAD:** `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`
**Branch:** `main`
**Working-tree diff SHA-256:** `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d`
**Source audit:** `reports/ASIC_FEASIBILITY_AND_SYNTHESIS_READINESS.md`
**Evidence:** `reports/evidence/asic_feasibility_and_synthesis_readiness/`

No production RTL, testbench, SDC, synthesis script, or flow configuration was modified. No tools were installed or updated. No PDK was provisioned. No synthesis or physical implementation was run.

---

## 1. Executive Summary

- The SoC is functionally verified in simulation and generically synthesizable for the CPU core and most peripherals, but it is **not** technology-mapped ASIC ready.
- Four architectural decisions must be made before technology-mapped synthesis: (1) PDK platform, (2) memory architecture, (3) SystemVerilog frontend strategy, (4) clock/reset implementation.
- Recommended PDK: the existing Sky130HD platform (OpenROAD-flow-scripts) as the near-term, reproducible path; provision Sky130A via Volare only if multi-corner signoff and volare-managed reproducibility are required. (Option A recommended for immediate enablement; Option B for production-grade multi-corner.)
- Recommended memory architecture: banked `sky130_sram_1rw1r_*` macros with a wrapper providing AXI byte-write and read/write arbitration; standard-cell ROM for the 16 KB boot ROM in the near term.
- Recommended frontend strategy: primary = RTL refactoring for Yosys compatibility (remove package `import`, convert unpacked array ports); fallback = a stronger-SystemVerilog frontend (e.g., Verilator/Slang-based elaboration to Verilog) without changing RTL semantics.
- Recommended clock/reset: replace combinational AND gating with ICG cells; add reset synchronizers and recovery/removal constraints; declare async clock groups.
- SDC is incomplete; required system-specification inputs are listed in Section 8.
- **Final recommendation: proceed only after explicit approval of the decisions in Section 10.**

---

## 2. Baseline Integrity

| Item | Value | Status |
|------|-------|--------|
| Branch | `main` | VERIFIED |
| HEAD SHA | `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1` | VERIFIED |
| Working-tree diff SHA-256 | `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d` | VERIFIED |
| Modified tracked files (7) | `plic.sv`, `has_soc.sv`, `riscv_core.sv`, `run_regression.js`, `run_e2e.js`, `reset_ctrl_fv.sv`, `verify.js` | VERIFIED |
| Untracked files | audit reports, evidence, targeted testbenches, assembly, sim artifacts | VERIFIED |
| No destructive Git operation performed | confirmed | VERIFIED |

---

## 3. Audit Inconsistencies

| # | Inconsistency | Evidence | Impact | Status |
|---|---------------|----------|--------|--------|
| 1 | Audit report states "23 synthesizable files" but lists 24 entries in `rtl/filelist.f`. | `rtl/filelist.f` contains 24 non-comment lines. | Counting discrepancy only; one of the 24 is a package, not a module. | VERIFIED |
| 2 | Package `has_addr_map_pkg` (in `has_addr_map.sv`) is counted as a source file but is not a module. | `grep -rn "package " rtl/` → one package. | Module count is 23; source-file count is 24. | VERIFIED |
| 3 | Generic synthesis table listed `power_mgr` as "not run individually" but `power_mgr_regs` was run. | `power_mgr.sv` synthesizes to 32 cells when run with `power_mgr_regs.sv`. | Minor; table updated here: `power_mgr` = 32 cells (module alone), `power_mgr_regs` = 43 cells. | VERIFIED (this review) |
| 4 | 787,112-cell SRAM result: reproducible. | `reports/evidence/.../yosys_sram_generic.log`: "Mapping memory \mem … 65536 $dff cells … 787112 cells". | Confirms inferred-memory conclusion. | VERIFIED |
| 5 | Cell counts in audit match logs for `riscv_core` (51,933), `sram` (787,112), and interconnect/has_soc failures. | Evidence logs. | No discrepancy. | VERIFIED |
| 6 | Audit says "23 RTL files" in AGENTS.md (historical) vs 24 in filelist. | Historical documentation. | Documentation drift, not an RTL defect. | VERIFIED |

**Conclusion:** The only substantive discrepancy is the file/module count (24 files = 23 modules + 1 package). No synthesis result is invalidated.

---

## 4. PDK Platform Comparison

### Option A — Existing Sky130HD platform (OpenROAD-flow-scripts)

Path: `/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130hd`

| Attribute | Status | Evidence |
|-----------|--------|----------|
| Availability | VERIFIED (present on disk) | `ls` of platform dir |
| Standard-cell Liberty (TT) | VERIFIED | `lib/sky130_fd_sc_hd__tt_025C_1v80.lib` (13.0 MB) |
| SS/FF Liberty | PARTIALLY VERIFIED | present under `/d/tools/src/OpenROAD/src/sta/test/sky130hd/`, not in platform dir |
| Technology LEF | VERIFIED | `lef/sky130_fd_sc_hd.tlef` |
| Merged cell LEF | VERIFIED | `lef/sky130_fd_sc_hd_merged.lef` (441 cells) |
| Cell GDS | VERIFIED | `gds/sky130_fd_sc_hd.gds` (4.0 MB) |
| RCX rules | VERIFIED | `rcx_patterns.rules` → `../sky130hs/rcx_patterns.rules` (46 KB) |
| DRC deck | VERIFIED | `drc/sky130hd.lydrc` (KLayout) |
| LVS deck | VERIFIED | `lvs/sky130hd.lylvs` (KLayout) |
| Tap cell | VERIFIED | `sky130_fd_sc_hd__tapvpwrvgnd_1` (config.mk) |
| Endcap cells | NOT AVAILABLE (not named) | config.mk has no endcap entry |
| Filler cells | NOT AVAILABLE (not named) | config.mk has no filler entry |
| PDN config | VERIFIED | `pdn.tcl` |
| Timing corners | TT only in platform dir | PARTIALLY VERIFIED |
| Tool compatibility | VERIFIED | OpenROAD runs under WSL; Magic/Netgen installed |
| Reproducibility | PARTIALLY VERIFIED | external path outside project; not volare-managed |
| Maintenance | Low (static snapshot) | — |

### Option B — Provision Sky130A via Volare

| Attribute | Status | Evidence |
|-----------|--------|----------|
| Volare installed | VERIFIED | `/mnt/d/tools/venv-openlane2/bin/volare` |
| PDK provisioned | NOT AVAILABLE | `volare ls` returns `[]` |
| Required views | NOT AVAILABLE | Liberty, LEF, tech LEF, GDS, SPICE, RCX not present for sky130A |
| OpenLane 2 compatibility | VERIFIED | OpenLane 2 v2.0.0b16 runs under WSL with tkinter env |
| Storage/dependencies | PARTIALLY VERIFIED | Volare needs network + disk; not tested |
| Reproducibility | PROPOSED (higher) | volare pins PDK version |
| Timing corners | PROPOSED (TT/SS/FF/FS/SF) | not verified |
| Maintenance | Higher (version pinning, updates) | — |

### Comparison

| Criterion | Option A (Sky130HD) | Option B (Sky130A via Volare) |
|-----------|---------------------|-------------------------------|
| Availability | VERIFIED now | NOT AVAILABLE (not provisioned) |
| Completeness | Standard cells + TT corner + DRC/LVS | Full multi-corner (if provisioned) |
| Tool compatibility | VERIFIED (OpenROAD/Magic/Netgen) | VERIFIED (OpenLane 2) |
| Reproducibility | PARTIALLY VERIFIED (static snapshot) | PROPOSED (version-pinned) |
| Timing-corner coverage | TT only (in platform dir) | PROPOSED (multi-corner) |
| Maintenance | Low | Higher |
| Risk | External dependency path; single corner | Network/storage; not yet tested |

**Recommendation:** Option A for immediate enablement and first technology-mapped synthesis/STA; Option B as the production-grade follow-up when multi-corner signoff is required. Do not assume Sky130HD and Sky130A are interchangeable — they differ in corner availability and tool flow integration.

---

## 5. Memory Architecture Decision

### Current RTL memory architecture
- `sram.sv`: 128 KB behavioral array, AXI4-Lite slave + second read port (instruction fetch). `$readmemh` optional init.
- `boot_rom.sv`: 16 KB behavioral array, NOP fill + `$readmemh`.
- TCM 32 KB: referenced in address map; no separate module (mapped into SRAM/ROM region).

### Available macros (`sky130_sram_1rw1r_*`)
| Macro | Capacity | Ports | Byte-write |
|-------|----------|-------|------------|
| `sky130_sram_1rw1r_128x256_8` | 128 × 256 bits = 4 KB | 1rw + 1r (clk0/clk1, csb0/csb1, web0, addr0/addr1, din0, dout0/dout1, wmask0) | wmask0[15:0] (16 bytes) — VERIFIED |
| `sky130_sram_1rw1r_64x256_8` | 64 × 256 = 2 KB | same | yes |
| `sky130_sram_1rw1r_80x64_8` | 80 × 64 = 640 B | same | yes |
| `sky130_sram_1rw1r_44x64_8` | 44 × 64 = 352 B | same | yes |

### Option A — Banked SRAM macros
- **Bank count (128 KB / 4 KB per macro) = 32 banks** (using `128x256_8`); 8 banks for 32 KB TCM.
- Port requirement: AXI read/write + instruction-fetch read = 2 reads + 1 write. Macro provides 1rw + 1r. A wrapper must time-multiplex port0 between AXI read and write and use port1 for instruction fetch, or arbitrate.
- Byte-write: supported via `wmask0` (VERIFIED).
- Clocking: two clocks (`clk0`, `clk1`); typically tied to same domain with registered enables.
- Read latency: macro-dependent; Verilog model available for timing verification (not measured here).
- Wrapper requirements: address decode/bank select, AXI-to-macro adapter, byte-strobe mapping, arbitration, read-data mux, init mechanism.
- Area/timing: NOT AVAILABLE (not estimated; do not invent).

### Option B — External memory compiler
- No memory compiler is installed or verified in this environment. Status: NOT AVAILABLE.
- Required views if procured: Liberty (TT/SS/FF), LEF, Verilog model, GDS, SPICE, timing/operating-corner data.

### Option C — Register-based implementation
- Consequence: 128 KB → 787,112 cells (65,536 DFFs + 131,070 muxes) as verified by Yosys. Area and power are infeasible for ASIC; timing closure unlikely. Status: BLOCKED as a default strategy.

### Boot ROM strategy
| Strategy | Pros | Cons | Status |
|----------|------|------|--------|
| Mask-programmed ROM | Lowest area/power, secure | Requires ROM compiler/mask; fixed content; manufacturing cost | NOT AVAILABLE (no ROM macro) |
| Standard-cell ROM | Synthesizable, flexible, no macro dependency | Larger area; init via `$readmemh` not synthesizable to ROM mask | PROPOSED (near-term) |
| SRAM + validated boot | Reuses SRAM macro; updatable | Requires secure boot (currently fail-closed only), SRAM macro, init path | PARTIALLY VERIFIED (boot.c fail-closed) |

**Recommendation:** Banked `sky130_sram_1rw1r_128x256_8` macros for SRAM/TCM with a wrapper; standard-cell ROM for 16 KB boot ROM in the near term; migrate to mask-programmed ROM or SRAM-backed secure boot for production. Memory macro timing must be verified against the Verilog model before committing.

---

## 6. SystemVerilog Frontend Decision

### Current limitations
- `has_soc.sv:65` and `axi_lite_interconnect.sv:76`: `import has_addr_map_pkg::*;` — Yosys 0.69 errors `TOK_IMPORT`.
- `axi_lite_interconnect.sv:57`: unpacked-array ports `s_awaddr [NUM_SLAVES]` etc. — Yosys 0.69 errors `unexpected '['`.

### Option 1 — RTL refactoring for Yosys compatibility
- Replace `import ...::*;` with fully-qualified `has_addr_map_pkg::ADDR_*` references.
- Convert unpacked-array ports to packed vectors or generate-based per-slave interfaces.
- Pros: RTL remains portable; no new tool; maintainable.
- Cons: RTL changes; requires re-verification of all affected modules; risk of functional drift.
- Status: PROPOSED (primary).

### Option 2 — Stronger-SystemVerilog frontend (elaboration to Verilog)
- Use a frontend with full SV support (e.g., Verilator/Slang) to elaborate to Verilog, then synthesize with Yosys.
- Pros: no RTL changes; preserves SV semantics.
- Cons: new tool dependency; elaborated output may be large/unreadable; reproducibility depends on frontend version; Yosys still needs the result.
- Status: PROPOSED (fallback).

### Option 3 — Preprocessing/elaboration flow
- Script-based preprocessing to strip `import` and flatten unpacked ports.
- Pros: no RTL edits.
- Cons: fragile; maintenance burden; risk of incorrect transformation.
- Status: NOT RECOMMENDED.

**Recommendation:** Primary = Option 1 (RTL refactoring, smallest semantic risk when done carefully and re-verified); Fallback = Option 2 (SV frontend elaboration) if refactoring is deemed too invasive. Option 3 is not recommended.

---

## 7. Clock and Reset Architecture

### Current implementation
- `core_clk = clk & core_clk_en_q`, `periph_clk = clk & periph_clk_en_q` (combinational AND, enable registered on negedge clk).
- Async active-low resets throughout (`negedge reset_n`/`presetn`).
- JTAG TAP runs on ungated `clk`, advances on detected `tck` rising edge (async external clock).
- `power_mgr` has 2-FF sync for `wake_ack`; `wake_event` clears sleep request.

### Evaluation
| Item | Current | ASIC recommendation |
|------|---------|---------------------|
| Clock gating | Combinational AND (glitch-prone) | ICG cells inserted by flow or RTL; clock-gating checks in STA |
| Clock enables | Registered on negedge clk | Keep as enable registers feeding ICG |
| Reset | Async, active-low, widespread | Reset synchronizers per domain; recovery/removal constraints |
| Reset controller | `reset_ctrl.sv` (watchdog → 16-cycle pulse) | Keep; verify pulse width against library recovery times |
| Async clock groups | None declared | Declare `sys_clk` vs `jtag_tck` async group in SDC |
| CDC | wake_ack synchronized; JTAG sync; ext IRQ pads | Formal CDC verification (bounded) already exists; silicon MTBF needs STA/silicon |
| Scan/testability | Async resets complicate scan | Consider sync-reset option or reset-gating for test mode (decision needed) |

**Recommendation:** Replace AND gating with ICG cells; add reset synchronizers and recovery/removal constraints; declare async clock groups; retain existing CDC synchronizers. No changes made in this review.

---

## 8. SDC Requirements

Current file: `constraints/timing_constraints/has_soc.sdc` (single corner, 50 MHz, basic I/O, clock uncertainty, coarse false paths).

### Exact missing constraints
- Input/output transition (slew) assumptions.
- Output load capacitance.
- Generated-clock definitions (if ICGs or PLL added).
- Asynchronous clock groups (`sys_clk` vs `jtag_tck`).
- Reset recovery and removal checks.
- Per-interface input/output delays (currently `all_inputs`/`all_outputs`).
- Multicycle paths (if any; currently none declared, not verified).
- Unconstrained-endpoint report and closure.
- False paths refined (currently coarse: all registers).

### Information required from system specification / external interface requirements
- Confirmed system clock frequency target (currently estimated 50 MHz).
- External device I/O timing (setup/hold) for UART/SPI/I2C/GPIO/PWM/I2S.
- JTAG TCK frequency range and TMS/TDI setup/hold.
- Reset pulse width and power-on reset behavior.
- Wake/sleep transition timing requirements.
- Operating conditions and temperature/voltage corners required for signoff.

Status: PARTIALLY VERIFIED (coarse constraints exist; completion depends on system spec).

---

## 9. Proposed ASIC Synthesis Flow

```
RTL source inventory (rtl/filelist.f)
  → SystemVerilog elaboration (Yosys -sv or SV frontend)
  → Generic synthesis (proc/opt/fsm/memory/techmap)  [Yosys]
  → Memory macro integration (banked SRAM, ROM strategy)
  → Standard-cell technology mapping (abc + sky130 Liberty)
  → Synthesis reports (area, timing, power estimate)
  → STA (OpenROAD/OpenSTA, TT first, then SS/FF)
  → Floorplan eligibility review (NOT executed here)
```

| Step | Required inputs | Expected outputs |
|------|-----------------|------------------|
| RTL inventory | `rtl/filelist.f`, `rtl/rtl_top/has_addr_map.sv` | source list, module hierarchy |
| SV elaboration | RTL, package | elaborated design (Yosys or SV frontend) |
| Generic synthesis | elaborated design | generic netlist, cell count |
| Memory macro integration | macro LEF/Liberty/Verilog, wrapper RTL | memory-integrated netlist |
| Tech mapping | generic netlist, sky130 Liberty | mapped netlist |
| Synthesis reports | mapped netlist | area, timing, power reports |
| STA | mapped netlist, SDC, Liberty | slack, TNS, WNS, violations |
| Floorplan eligibility | STA pass + macro placement needs | go/no-go for physical design |

No floorplanning, placement, CTS, or routing is performed in this review.

---

## 10. Decision Register

| ID | Decision | Recommended option | Evidence | Risk | Approval required |
|----|----------|--------------------|----------|------|-------------------|
| D1 | PDK platform | Option A (Sky130HD) now; Option B (Sky130A) for production | Platform files verified; Volare empty | Single corner (A); provisioning effort (B) | YES |
| D2 | Memory architecture | Banked `sky130_sram_1rw1r_128x256_8` + wrapper; standard-cell ROM for boot ROM | Macro LEF/Liberty verified; Yosys SRAM result | Port arbitration complexity; ROM area | YES |
| D3 | Synthesis frontend | Primary: RTL refactoring; Fallback: SV frontend elaboration | Yosys errors logged | RTL change risk; tool dependency | YES |
| D4 | Clock/reset | ICG cells; reset synchronizers; async clock groups | RTL clock gating inspected | Timing closure; scan impact | YES |
| D5 | SDC completion | Complete per Section 8 using system spec | SDC inspected | Missing external interface specs | YES |
| D6 | Reproducible synthesis flow | Yosys generic → memory → tech map → STA, isolated outputs | Evidence logs | Integration effort | YES |

---

## 11. Risks and Dependencies

- **Memory macro timing** must be verified against the Verilog model; not done here.
- **RTL changes for frontend compatibility** require full regression re-run (currently PASS 25/25) and re-verification of targeted tests.
- **Single-corner (TT) analysis** may hide SS/FF failures; multi-corner needed for signoff.
- **External platform path** (`/d/rta-real-world-benchmark/...`) is outside the project; reproducibility depends on that tree remaining available. Volare-based provisioning (Option B) would improve this.
- **Secure boot** is currently fail-closed (no verifier); boot ROM integrity strategy depends on this.
- **Debug JTAG** is a bring-up stub; production DFT needs a real DTM/DMI.

---

## 12. Recommended Implementation Order

1. Approve PDK platform (D1) and integrate path into `asic/config.json` (no provisioning).
2. Approve memory architecture (D2) and create macro wrapper specification.
3. Approve frontend strategy (D3) and perform RTL refactoring with regression.
4. Complete SDC (D5) using system specification inputs.
5. Implement clock/reset changes (D4) and re-run formal/CDC.
6. Execute reproducible synthesis flow (D6): generic → memory → tech map → STA.
7. Review floorplan eligibility (separate approval required).

---

## 13. Evidence and References

- `reports/ASIC_FEASIBILITY_AND_SYNTHESIS_READINESS.md`
- `reports/evidence/asic_feasibility_and_synthesis_readiness/tool_versions.txt`
- `reports/evidence/asic_feasibility_and_synthesis_readiness/yosys_riscv_core_generic.log`
- `reports/evidence/asic_feasibility_and_synthesis_readiness/yosys_sram_generic.log`
- `reports/evidence/asic_feasibility_and_synthesis_readiness/yosys_interconnect_failure.log`
- `reports/evidence/asic_feasibility_and_synthesis_readiness/yosys_has_soc_failure.log`
- `reports/evidence/asic_feasibility_and_synthesis_readiness/cdc_inventory.txt`
- `reports/evidence/asic_feasibility_and_synthesis_readiness/formal_run.txt`
- `rtl/filelist.f`, `constraints/timing_constraints/has_soc.sdc`
- `/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130hd/`
- `/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130ram/`

---

## 14. Final Recommendation

Proceed with **Option A (Sky130HD platform)** for immediate enablement, **banked SRAM macros + standard-cell boot ROM**, **RTL refactoring as the primary frontend strategy**, **ICG-based clock gating with reset synchronizers**, and **SDC completion driven by the system specification**. Migrate to Option B (Volare-provisioned Sky130A) before production multi-corner signoff. No RTL, SDC, or flow changes are made by this review; all items require explicit approval.

**Final recommendation: Hold implementation pending approval of decisions D1–D6.**
EOF
echo written