# RUN-0011 — Verification evidence matrix (F4/F9)

**Baseline:** `025ef24f2f4444cac4c38dc62b659fac724770f4` (`main`), worktree **dirty**
(15 modified tracked files; source manifest hashes 248 files).
**Run:** 2026-11-18 20:58–21:40 IST (15:28–16:10Z).
**Classification:** all results SELF-EVALUATED; no independent evaluator exists.

The source state below is the state every command actually read. The dirty set
contains the I²C STOP fix (`rtl/rtl_peripherals/i2c_ctrl.sv`,
`sim/sim_top/tb_i2c_xfer.v`), the corrected `$pmux` techmap
(`build/asic_evidence/sky130_map.v`), the corrected `dfrbp` stub
(`build/asic_evidence/arith_work/sky130_stub.v`) and the toolchain/verification
scripts. A result "at 025ef24" without this dirty set describes **different
source** and is not interchangeable.

## 1. Current, reproduced results

| # | Target | Source state | Exact command | Tools (version) | Exit | Result | Artifact / SHA-256 | Limitations |
|---|---|---|---|---|---|---|---|---|
| 1 | RTL regression | `025ef24` + dirty (RTL incl. I²C fix) | `cmd /c "call …environment.bat && node scripts/eda/run_regression.js"` | Icarus 14.0 `s20260301-500` | 0 | **PASS 27/27** | `logs/regression.log`; images rebuilt in-run: `firmware.elf` `e0d791b3…`, `firmware.bin` `d948ee8f…` | No coverage metric; QSPI flash has no model |
| 2 | Unified gate | same | `node scripts/verify.js` | Icarus, Yosys 0.69+154, SBY v0.69, Verible v0.0-4298, xPack GCC 12.2.0, Node 26.7.0 | 0 | **10 passed, 0 failed, 0 blocked** | `build/verify/summary.txt` `aca2675b…`, `logs/gate.log` | Gate itself is self-checked, not externally reviewed |
| 3 | Firmware build | same | `node scripts/fw_build/build_fw.js` | xPack GCC 12.2.0 (`riscv-none-elf`) | 0 | **PASS**, `.text` 3,684 B | `firmware.elf` 34,544 B `e0d791b3…` | Single compiler available; no second target to cross-check |
| 4 | Firmware image generation | same | `node scripts/fw_build/gen_fw_mem.js` | same | 0 | rom 26 words, tcm 895 words | `rom.hex` `c1fbc10c…`, `tcm.hex` `625cda23…` | Image is a demo, not a boot chain |
| 5 | Firmware E2E | same | `node scripts/firmware/run_e2e.js` | Icarus 14.0 + GCC 12.2.0 | 0 | **7/7 steps**, corruption control detected | `logs/e2e.log` | Positive path only; no sensor model |
| 6 | Formal (SBY) | same | `cmd /c "call …environment.bat && node scripts/formal/run_formal.js"` | SBY v0.69, Yosys 0.69+154, boolector, abc pdr | 0 | **PASS 6/6** | `build/formal/formal.log` `ac90f7a7…` | 5 of 6 bounded; block-level, not full SoC |
| 7 | Verilator lint | same | `verilator_bin.exe --lint-only -Wall --top-module has_soc -f rtl/filelist.f` | Verilator 5.053 devel | **1** | **0 errors, 123 warnings** (exit 1 because `-Wall` warnings) | `logs/verilator_lint.log` | Warnings are style/unused, not functional; claim "PASS" must say "warnings only" |
| 8 | Verilator C++ full-SoC boot | same | `scripts\eda\verilator_build_soc.bat tb_boot sim\sim_top\tb_boot.v build\obj_soc_r11` then `verilator_run.bat` | Verilator 5.053 + MinGW g++ 16.1.0 + GNU Make 4.4.1 | 0 | **7/7 sub-tests PASS**, 4 ms simulated in 0.233 s | `Vtb_boot.exe` `e25ee3f6…` (565,835 B) | Build required a shim-path fix (see §4); no Icarus cross-run at this revision |
| 9 | Structural check (full SoC) | same | `node scripts/eda/check_structure.js --script asic/synthesis/fullsoc_map.ys --top has_soc --json … --tag fullsoc` | Yosys 0.69+154 | **2** | **BLOCKED** — 4 × `$mem_v2` with no macro | `build/asic_evidence/structural_check/has_soc_cells.json` `17a8a63b…` | Expected until F5/F7; not a pass |
| 10 | Memory audit | same | `yosys -s asic/synthesis/memory_audit.ys && node scripts/eda/audit_memory.js` | Yosys 0.69+154, Node | **2** | **BLOCKED** — ROM 4× and SRAM 2× their aperture (F5) | `logs/memory_audit.log` | Inventory only; no implementation |
| 11 | Core synthesis | same | `yosys -s` (`read_verilog rtl_top/riscv_core.sv; hierarchy; synth; stat`) | Yosys 0.69+154 | 0 | **44,323 generic cells**, pre-ABC | `logs/synth_riscv_core.log` | Not PPA; no timing, no ABC `-liberty` |
| 12 | `$pmux` mapping experiment | same | `node scripts/eda/run_pmux_map_test.js` | Yosys 0.69+154, Icarus 14.0 | 0 | **7/7**, 393,608 vectors, 0 mismatches | `build/asic_evidence/pmux_map_test/` | One mapping rule; other rules unproven |
| 13 | `dfrbp` model fidelity | same | `node scripts/eda/run_dfrbp_model_test.js` | Icarus 14.0, Yosys | 0 | **11/11**, pre-fix control exits 1 | `logs/dfrbp_model_test.log` | Mapper emits no `dfrbp`; model is unreferenced |
| 14 | Arithmetic provenance (F4) | same, source now at `asic/synthesis/provenance/` | `yosys -s asic/synthesis/provenance/map_arith.ys`, then `iverilog -DUSE_MAPPED … && vvp` | Yosys 0.69+154, Icarus 14.0 | 0 | **1028 checks PASS**; corrupt-map control exits 1 | `arith_test.v` `4085e764…`, `tb_equiv.v` `55e7bd5b…`, netlist `1cf2f89b…` | One 4-bit module; cell-level stub has no timing |

## 2. Historical results — preserved, not current

| Artifact | What it actually describes | Why it is not a current PASS |
|---|---|---|
| `reports/verification/VERIFICATION_BASELINE_2826b5b.md` | Parent commit `2826b5b`, clean tree, 2026-11-17 | Predates the I²C STOP fix, the `$pmux`/`dfrbp` map corrections and the toolchain unification; its 26/26 and 9/9 are not this tree |
| `reports/verification/TEST_RESULTS.md` | Nov 11 snapshot: 8 PASS / 4 BLOCKED, 13 blocks | Superseded by the regression suite; already classified stale in the evidence registry |
| `reports/verification/README.md` | Nov 12 snapshot: regression 22/22, gate 9/9, "22 files, 279 warnings" | Gate now has 10 stages and 27 tests; RTL is 24 files; lint count not reproducible with current flags |
| `build/baseline/*` | RUN-0001-era logs at a clean tree | Kept as history; `build/verify/*` now holds the RUN-0011 clean run |
| `build/obj_soc/*` | Only `verilated.o` from Nov 12, **no executable** | The documented Verilator boot had no surviving binary; rebuilt here in `build/obj_soc_r11` |

## 3. Unverified claims (no current evidence)

| Claim (location) | Status | Reason |
|---|---|---|
| "~20,000× real time" (README ×4, old report) | **FALSE as written** | Measured 4 ms simulated in 0.233 s wall = 17.2 ms simulated per wall-second (Verilator's own report), i.e. ~58× *slower* than real time |
| "226 cells" for `riscv_core` (README ×2) | **Not reproducible** | Fresh `synth -top riscv_core` reports 44,323 generic cells pre-ABC |
| "three `$mem_v2`" (README) | **Stale** | RUN-0009 and this run both measure four (ROM, TCM, SRAM, APB decode LUT) |
| PPA / area numbers in older ASIC reports | **Out of scope, unverified here** | No ABC `-liberty`, no PDK, no place/route; pre-ABC counts only |
| "Full-SoC Icarus boot" (README) | **Conflated** | The 7/7 boot is the Verilator C++ model; the Icarus regression covers `boot` as one of 27 tests, not a 7/7 boot count |
| FPGA, silicon, DRC/LVS/STA, DFT | **Unverified / absent** | No Vivado, no board, no PDK, no layout |

## 4. Provenance defects found and what was done

1. **F4 — DUT cited by evidence lived only in a gitignored directory.**
   `build/asic_evidence/arith_test.v` and its testbench were untracked under
   `build/`, so the 1,028-check equivalence claim could not be reproduced from a
   published input. Fixed by publishing byte-identical copies under
   `asic/synthesis/provenance/` (hashes equal to the originals) with a
   reproducible `map_arith.ys`; the claim was then re-measured end to end.
2. **Gate logs were overwritten by a negative control.** RUN-0010's bogus-prefix
   control wrote `build/verify/*` at 20:51, leaving `tools.log` claiming the
   RISC-V toolchain was missing while a real gate run had passed. `build/verify`
   is a mutable single-path log store (documented limitation); the clean RUN-0011
   gate was executed last, so the directory now reflects a real run.
3. **Verilator build script was broken on this host.** `VERILATOR_ROOT` was
   substituted with backslashes into a makefile, producing
   `…\obj_soc_r11\toolsverilator-shim\…`. Reproduced with the pre-fix script
   (`logs/verilator_build_control.log`, exit 1), fixed by substituting forward
   slashes in `verilator_build.bat` / `verilator_build_soc.bat`, rebuild exit 0.
4. **Tool inventory hid a working simulator.** `verify.js` reported
   `verilator: not installed` because only the broken Perl wrapper was probed.
   The `tools` stage now falls back to `verilator_bin` and says so.
5. **Artifact freshness.** `build/verify/regression.log` at 20:51 matched the
   negative-control run; every number in §1 was regenerated after that.

## 5. Verdicts

- **F4: FIXED.** Source and testbench are published in a non-ignored path with
  hashes equal to the originals; mapping and equivalence are reproducible from
  those files; the 1,028-check result is reproduced and its corruption control
  fails as designed.
- **F9: PARTIAL.** Every target listed in the request now has a current,
  commit-and-dirty-state-matched run with command, tool versions, exit code and
  artifact hashes. It cannot become PASS while historical reports still carry
  superseded numbers in place (now banner-marked) and while PPA/Verilator-wrapper
  claims depend on unavailable tooling or on independent review.
- **Highest gate: `PARTIAL`.** G0.4/G0.5 move to PASS on provenance grounds, but
  G0 remains partial on independent reproduction; G1, G2 partial; G3/G4 open.
  Nothing here supports an ASIC-readiness claim.
