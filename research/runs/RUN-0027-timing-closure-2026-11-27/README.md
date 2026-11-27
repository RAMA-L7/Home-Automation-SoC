# RUN-0027 — timing closure investigation (critical-path driven)

**Date:** 2026-11-27
**Baseline (published, untouched):** `09e2eaa1835d1bda7f950a918b447df5318f1650`
**Deadline:** unchanged — 2026-11-28T12:17:36Z
**Purpose:** attribute the −106.48 ns setup violation to a specific RTL
construct, rank the bottlenecks, make **one** evidence-supported change, and
measure regression + STA before and after.

## Result

| Metric | Baseline `09e2eaa` | After | Change |
|---|---|---|---|
| WNS setup | −106.4775 ns | **−8.4509 ns** | +98.03 ns |
| TNS setup | −104736.49 ns | **−848.81 ns** | 123× smaller |
| WNS hold | +0.2544 ns | +0.2544 ns | unchanged |
| Violating endpoints | 1,160 | 632 | −528 |
| Endpoints < −90 ns | 992 (99.25% of TNS) | 0 | cluster removed |
| Sky130 cells | 52,549 | 46,696 | −5,853 |
| Registers | 3,422 | 3,594 | +172 |
| Full regression | — | **30/30 PASS, exit 0** | — |

**Timing still FAILS at 50 MHz.** This run fixes one defect; it does not close
timing and makes no signoff claim.

## Cause

`riscv_core.sv` computed DIV/DIVU/REM/REMU combinationally. Yosys expanded the
operators into a 32-step restoring divider (32 serial conditional subtracts,
each a 32-bit carry chain). `muldiv_out` feeds the write-data input of every
register-file bit, so 1,024 write ports sat behind a 469-cell path; 992 of them
violated at −103…−106 ns.

## Change

`rtl/rtl_top/riscv_core.sv` only:

* new `S_DIV` state (`logic [2:0]`), 32 quotient-bit cycles + one fixup cycle;
* DIV/DIVU/REM/REMU retire from `S_DIV`; MUL stays combinational in `S_EXEC`;
* divide-by-zero and signed-overflow cases bypass the iteration;
* one shared register-file write port for both retirement paths (see below).

## Negative result kept on purpose

The first post-fix synthesis used a separate `if (div_wb) rf[rd] <= div_result;`
statement. Synthesis turned it into one enable net with **909 loads**, 3.19 pF,
36 ns slew and 25.15 ns of net delay, giving WNS −9.37 ns and TNS −9267 ns.
Merging both retirement paths into a single write port restored the per-entry
select; worst fanout is 69 (baseline: 67). Both runs are kept:
`logs/sta_postfix_v1_*` and `logs/sta_postfix_v2_*`.

## Provenance

| Input | SHA-256 |
|---|---|
| Baseline netlist (from `09e2eaa` RTL) | `f9cdd8338c12a22fc35b3433eb68f0c4dfeb589326d4090c8ff67d07eba7252b` |
| Post-fix netlist | `16d833870fb7fefea6a7f54c7c0b05a6fa622618f2cf8555b54dc1c18fa45af8` |
| SDC (identical in both runs) | `6abd7b41c262b9d3cb32e7c6beafdf28bd4cf11bec8961e6027c0fabce21c80c` |
| Published `riscv_core.sv` (prefix) | `e8e46c9aded0d99bce1dfd68b4aa57d15604416a23c3789c5efe18e6c6783710` |
| Post-fix `riscv_core.sv` (final, v2) | `d48f839decf7df83e1eb0377e6452df74fbbd0b0ca9a77818f47d748b7762057` |
| Post-fix `riscv_core.sv` (v1, before the write-port merge) | `84a458a3852c4ec62b82c7fd193aa629ec00dcf0cee339e3ae041c9ca0065932` |

The baseline netlist is archived gzipped at
`artifacts/has_soc_gate_prefix.v.gz` (874 KB, sha256
`d69a6837bbcc515d704483fc6b1a82cf248f5232c3249c62bb5f4aea349515a7`) so the
"before" analysis can be reproduced without re-synthesising.

Working tree at run time was **dirty**: the fix and the analysis script were
uncommitted. The tested RTL is exactly the committed diff in
`rtl/rtl_top/riscv_core.sv`; no other RTL file changed.

## Tools

| Tool | Version |
|---|---|
| Icarus Verilog | 14.0 (devel) s20260301-500-g2e81fcccb-dirty |
| Yosys | 0.69+154 (git sha1 30d62572e-dirty) |
| OpenSTA | 3.1.0 (WSL2 Ubuntu-24.04) |
| Node | v26.7.0 |
| Python | 3.10.11 |

Libraries: sky130_fd_sc_hd TT 025C 1.80 V, sky130_sram_macros 2 kB and 1 kB TT.
Single corner, ideal clocks, no SPEF/CTS — pre-layout timing, not signoff.

## Reproduction

```bash
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"

# timing gate (writes build/sta/has_soc_gate.v and build/sta/sta.log)
node scripts/eda/run_sta.js --verbose

# endpoint enumeration for a mapped netlist
MSYS_NO_PATHCONV=1 wsl bash research/runs/RUN-0027-timing-closure-2026-11-27/run_analysis.sh \
  /mnt/d/Home-Automation-SoC/build/sta/has_soc_gate.v postfix 3000

# functional evidence
iverilog -g2012 -o build/sim/tb_isa_final.vvp -s tb_isa sim/sim_top/tb_isa.v rtl/rtl_top/riscv_core.sv
vvp build/sim/tb_isa_final.vvp
iverilog -g2012 -o build/sim/tb_muldiv_postfix.vvp -s tb_muldiv_sign \
  research/runs/RUN-0027-timing-closure-2026-11-27/tb_muldiv_sign.v rtl/rtl_top/riscv_core.sv
vvp build/sim/tb_muldiv_postfix.vvp

# full regression
node scripts/eda/run_regression.js
```

`tb_isa.v` ends with `$finish`, so the pass signal is the marker
`[isa] RESULT: PASS`, not the process exit status; `run_regression.js` fails on
a missing marker.

## Contents

| Path | What it is |
|---|---|
| `commands.jsonl` | one record per command with UTC time and exit status |
| `logs/sta_postfix_v1_run.txt` | first post-fix gate run (fanout regression), exit 1 |
| `logs/sta_postfix_v1_full.log` | its full OpenSTA report |
| `logs/sta_postfix_v2_run.txt` | final gate run, exit 1 (timing still fails) |
| `logs/prefix/` | baseline enumeration: `paths_setup.rpt`, `paths_hold.rpt`, `paths_unconstrained.rpt`, `design_rules.rpt`. The top-50 JSON is omitted here (11 MB, since each baseline path serializes 469 cells); it regenerates in seconds from `artifacts/has_soc_gate_prefix.v.gz` with `run_analysis.sh` |
| `logs/postfix/` | same reports for the post-fix netlist, including the 1.7 MB top-50 JSON |
| `logs/cluster_summary.txt` | endpoint/slack histogram for both netlists |
| `logs/tb_isa_postfix.log` | directed RV32IM bench, 47/47 |
| `logs/tb_muldiv_prefix.log`, `logs/tb_muldiv_postfix.log` | sign-fixup equivalence, 10/10 each |
| `logs/regression_postfix.txt` | 30/30 PASS, exit 0 |
| `tb_muldiv_sign.v` | directed signed divide/remainder bench (archived, not in the 30-test regression) |
| `prefix_rtl/riscv_core.sv` | published core the equivalence bench was run against |
| `artifacts/has_soc_gate_prefix.v.gz` | archived baseline netlist |

## Remaining bottlenecks (ranked)

1. **SRAM bank read-data select** — `sram_macro_wrap.sv` builds a 64-deep
   priority mux (`for (k…) if (rd_bank_q == k)`), currently ~60 cascaded 2:1
   muxes, 28.23 ns arrival, 96 endpoints, −752 ns. Indexed/balanced selection
   would be 6 levels.
2. Residual −1…0 ns endpoints (536).
3. No clock tree (ideal clocks).

Rank 1 was not bundled into this run so the before/after attribution stays
clean; it is the next recommended change.
