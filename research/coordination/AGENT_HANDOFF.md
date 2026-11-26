# Agent handoff — Home-Automation-SoC

**Last updated:** 2026-11-20 21:05 IST (2026-11-20T15:35Z)
**Handoff owner:** `Agent: Buffy (model: Nemotron 3.5 Lightning)` — session `S-2026-11-20-23`
**Read this file first, then:** `research/coordination/WORK_LOG.md` (last entry),
`research/coordination/REVIEW_LOG.md` (open items), `research/findings.csv`.

This file is the project's status report. It is the only file a new agent must
read to know where the project stands. The logs beside it are append-only
history; this file is the one document rewritten at session boundaries.

---

## STATUS (current)
### Current override — 2026-11-26 (external review intervention)

The table below describes the tree as of `67132f5` / RUN-0022 and is kept as
history. **These are the fields to trust today:**

| Field | Value |
|---|---|
| Tested commit | `3a71175` on `main` (fixes) + the evidence commit that publishes RUN-0025 |
| Regression | **PASS 28 / 28**, exit 0, from a detached worktree containing only tracked files (`research/runs/RUN-0025-external-review-2026-11-26/logs/clean_worktree_regression.log`) |
| Macro wrapper | **81 checks / 0 errors** at production geometry (64-bank SRAM + 16-bank TCM); 2 negative controls rejected (3 and 30 errors) |
| ROM | synthesizable, 1059 checks against the behavioural model on both modules, CPU boot 7/7, Yosys maps 32,840 `$_MUX_` with no `$mem` cell — still **BLOCKED** as an ASIC memory decision (mux tree, no characterised array) |
| Timing constraints | SDC executes as Tcl, 49/49 ports constrained, 0 object errors; **path-based STA BLOCKED** (no runnable OpenSTA) |
| Functional defects found and fixed | peripheral-interrupt bus left unconnected after BLK-019 (F12); TCM/SRAM preload silently dropped (F13); read+write deadlock in the memory slave (F14); untracked wrappers/missing include path (F15) |
| Highest verified stage | RTL functionally verified in simulation + synthesizable ROM + validated constraints; **ASIC readiness, physical implementation and signoff BLOCKED** |
| Report / evidence | `reports/REVIEW_INTERVENTION_2026-11-26.md`; `research/runs/RUN-0025-external-review-2026-11-26/` (manifest pins the source commit, tools, commands and file hashes) |

Hard deadline unchanged: **2026-11-28T12:17:36Z**.


| Field | Value |
|---|---|
| Phase | Day 2 of the 10-day research mandate (`research/protocol.md`) — the clock was **not** restarted |
| Hard deadline | **2026-11-28T12:17:36Z** (2026-11-28 17:47 IST) |
| Baseline commit | `67132f5` on `main` (= `origin/main`) — current tested revision; `67132f5` not `5ae3165` (stale entry corrected 2026-11-19 by RUN-0015) |
| Branch | `main` — the `closure/publication-repair` branch was merged; the fast-forward note above is obsolete |
| Worktree | **dirty** — 4 modified tracked files at the start of RUN-0016 (`research/coordination/AGENT_HANDOFF.md`, `…/WORK_LOG.md`, `…/REVIEW_LOG.md`, `research/findings.csv`), all under `research/` and all from RUN-0015/RUN-0016. `git diff --stat -- rtl/ asic/ sim/ scripts/ docs/` is **empty** |
| Verification gate | **13 of 15 stages passed, 0 failed, 2 BLOCKED** (ASIC readiness), exit 2 — `node scripts/closure.js`, RUN-0012 |
| Publication check | **COMPLETE** — 58 exact paths + 2 trees read from the Git index, 0 gaps (RUN-0012) |
| Clean-checkout reproduction | **PASS at `eff293d`** — the gate re-run in a separate worktree with only tracked files: publication COMPLETE, 13/13 functional, 2 design BLOCKED (RUN-0014). Two `build/`-dependent commands found and fixed there (F11) |
| Regression | **PASS 27 / 27**, exit 0 |
| Toolchain | one resolver (F6); xPack GCC **12.2.0-2**, target `riscv-none-elf` (RUN-0010) |
| Verilator | **rebuilt and re-run (F9)** — boot 7/7, 4 ms simulated in 0.233 s; no exe existed before RUN-0011 |
| Evidence state | **RUN-0011 matrix**: every current PASS traced to source state, command, tools, exit and hash; historical reports banner-marked |
| Highest gate | **G0 PASS** — G1/G2 PARTIAL, G3/G4 OPEN; no ASIC-readiness claim |
| Memory audit | **F5 FIXED (RUN-0012)** — arrays sized to the approved contract (16 KiB ROM / 32 KiB TCM / 128 KiB SRAM); the earlier Option-B recommendation is superseded in the same document |
| Tooling (gate-level sim) | **The sky130 cell models in `oss-cad-suite/examples/eqy/spm/sky130_fd_sc_hd.v` are unusable as shipped.** Their behavioural sequential cells declare `D_delayed`/`CLK_delayed`/`RESET_B_delayed`, pass them to the UDP, and never drive them (the assigns live in the uncompiled timing branch). Every flop is x for the whole simulation, including while held in async reset. This — and nothing in the design — is why RUN-0015's ROM gate-level comparison returned x. Repair with `research/runs/RUN-0018-rom-gl-failure-investigation/prototype/patch_cell_models.py` (240 delayed nets driven, 33 supply declarations) and use the patched copy for every GL run. With it, RUN-0015's unmodified netlist reproduces all 4096 ROM words exactly. Any gate-level result produced before this fix is suspect. |
| Memory technology (width) | **RUN-0017 answered it at fixed depth: narrowing costs area.** No 32×256/128×512 sky130 macro exists and there is still no compiler, so a controlled sky130 measurement is BLOCKED (not faked). Using the controlled pairs that exist: 64×256 is **+16.2%** per usable byte vs 128×256 at depth 256, and 44×64 is **+5.6%** vs 80×64 at depth 64. A real compiled grid on disk (IHP SG13G2, 10 points, shape only) agrees — area/byte ∝ depth^−0.345 (r² 0.91) and a width halving costs 1.03–1.14×. So RUN-0016's −21.3% was a **depth** effect. Hypothetical 32×256 loses under every case (33.6–39.0 mm², +16…+35% vs 28.962 mm²); hypothetical **128×512** wins under every case (19.6–22.8 mm², −21…−32%). Packing verified: zero bit and zero aperture waste for the three candidates. **Recommendation: keep 128×256 today; if a compiler is authorised, compile deeper (128×512), not narrower.** |
| Memory technology (RUN-0016) | **RUN-0016 measured the width question and could not close it.** There is **no memory compiler** on this machine (openram/openlane/klayout absent from PATH and from the venv; the only `*openram*` path is documentation images), so no native 32-bit macro was generated and none was invented. A genuine 32-bit 1RW1R **does** already exist — `sky130_sram_2kbyte_1rw1r_32x512_8` (32×512, 284,538 µm²) in OpenROAD `src/psm/test` data — but with **no Verilog model and no GDS**. One parameterised adapter (`MACRO_DW` 128/64/32 → 32/64/64 banks) is bit-identical to `sram.sv` in all three configurations (7,156 cycles, 0 mismatches, identical stimulus; 4 negative controls + a read-during-write control all detected). Cost: 128-bit 28.962 mm², 64-bit 33.637 mm² (+16.1%), 32×512 22.803 mm² (−21.3%) — but the 32-bit macro is **512 deep vs 256**, so the gain cannot be attributed to width; a 32×256 macro would need only 176.53 µm²/B to win. Keep the 128-bit macro among validated options |
| Memory technology | **F7 PARTIALLY RESOLVED (RUN-0015)** — the "no macro/PDK" reason was **false** and is retracted: a full sky130 PDK, the 452-cell std-cell liberty and four pre-built 1RW+1R SRAM macros are installed locally. A banked 4 KiB-macro 2R1W adapter matches `sram.sv` bit-identically (7,086 cycles, 0 mismatches) after two measured contract fixes (AXI rdata hold: 703 cycles; same-word read-during-write: 319 cycles). **Area is the open half**: 28.89 mm² of macro area for the two RAMs. The **ROM cannot use these macros** (no init), and a standard-cell synthesis failed gate-level equivalence (4,096/4,096 words read `x`), so no ROM area is claimed |
| I²C timing | **F10 FIXED (RUN-0012)** — standard mode 100 kHz only: fSCL 100.00 kHz, tHIGH 4700 ns, tLOW 5300 ns, tHD;STA 5000 ns, tSU;STO 5000 ns, tBUF 14720 ns measured at the pins; 400 kHz explicitly unsupported |
| Evaluation status | SELF-EVALUATED — no independent evaluator exists in this environment |
| ASIC readiness (RUN-0019) | **NOT READY — the handoff package does not exist.** 14 handoff requirements: **1 PASS, 4 PARTIAL, 9 BLOCKED**; 16-domain scorecard: 1 PASS, 6 PARTIAL, 8 BLOCKED, 1 NOT MEASURED (`research/runs/RUN-0019-asic-handoff-readiness-audit/scorecard.csv`). Re-measured at `67132f5`: gate 13 PASS / 2 BLOCKED (exit 2), regression 27/27, full-SoC mapping exit 0 with 0 structural problems but **4 `$mem_v2` and no PPA pass**. Critical path: memory architecture infeasible at 176 KiB (44 macros = 31.8 mm² vs <10 mm² target) → clock architecture unimplemented (BLK-001) so no approvable SDC → pads/pinout (81 pad bits for 56 usable QFN-64 pins). Physical, DFT and signoff evidence is **absent**, not weak: 0 `.gds`, timer-block-only P&R, no scan/ATPG/BIST, no UPF/CPF, LVS never run. |
| Memory architecture (RUN-0020) | **The `<10 mm2` target and the 176 KiB plan are mutually exclusive on sky130.** Measured from real macro LEF data: 160 KiB of RAM = **22.96 mm2** at the densest packing (2.3x the whole die), so the target implies **25-39 KiB of total RAM**. `NFR-AREA-003` (3.5 mm2 for 128 KiB) is **5-6.6x optimistic**. Recommended: **TCM 16 KiB + SRAM 8 KiB + 2 KiB std-cell boot ROM = 3.44 mm2 memory, ~8.9 mm2 die**, which needs no new IP and no firmware source change — firmware uses 3.7 KiB of code, a 4 KiB stack and **0 B of SRAM** (`research/runs/RUN-0020-soc-memory-feasibility/`). Alternative keeping capacity: 128 KiB off-chip (7.8 mm2). A denser or deeper macro does not fix it (hypothetical 128x512: 28.7 mm2 for 160 KiB). |
| TCM macro physical pilot (RUN-0021) | Prototype only, no production RTL change (`research/runs/RUN-0021-tcm-physical-pilot/`). Equivalence PASS (258,286 checks, 0 mismatches). Synthesis: 1,353 logic cells / 10,068 um2 + 4 macros (A), 843 / 6,526 um2 + 8 macros (B). Completed OpenROAD run: 2.959 mm2 at 73% util, WNS -9.537 ns / TNS -272.371 ns at 20 ns (~34 MHz unrepaired), 74.7 mW (97.3% macro). **16 KiB TCM = 2.898 mm2 (4x128x256) or 2.283 mm2 (8x32x512)** — RUN-0020's B3 confirmed to 0.13%. Failures preserved: detailed route did not converge (10,133 -> 3,348 violations over 9 iterations), PDN failed (PDN-0217), 1,291 antenna-flagged nets on global-route wiring. Open question is now read-path timing, not area. |
| TCM bank-mux timing (RUN-0022) | Prototype only, no production RTL change (`research/runs/RUN-0022-tcm-bank-mux-timing/`). Baseline reproduces RUN-0021 bit-identically (-9.537 ns). Five runs, identical netlists/SDC/floorplan/flow: v1 narrow mux **-7.696** (TNS worse, -360.1), v2 narrow+replicated select **-4.016** / TNS -86.4 (+16.4% logic area), **v0+repair_design -1.124 / TNS -7.213**, v2+repair -1.152. Repaired path: macro access **0.871 ns** of 18.624 ns; 6.888 ns is buffer chain. Verdict: keep the mux, repair fanout; no architecture change warranted, and the last 1.12 ns needs an output register (latency change).
| Active task | RUN-0022 closed the TCM timing question the wrong way round, which is the useful answer: **mux restructuring loses to plain buffering** (`research/runs/RUN-0022-tcm-bank-mux-timing/report.md`). Baseline+`repair_design` reaches WNS -1.124 ns / TNS -7.213 (~47.3 MHz) where the best rewrite alone reaches -4.016; the macro is 0.87 ns of the path and 6.9 ns is buffer chain. Next executable steps: (1) adopt fanout repair (or max_fanout on select registers) in the TCM flow and re-measure on the routed design with SPEF; (2) decide with the SoC owner whether a one-cycle-latency output register is acceptable, since that is the only remaining lever for 50 MHz; (3) still open: converging detailed routing and a PDN that builds (RUN-0021).

### Dirty worktree (must be preserved)

| File | Change | Evidence |
|---|---|---|
| `rtl/rtl_peripherals/i2c_ctrl.sv` | I²C STOP now a real four-quarter sequence | RUN-0002/0003/0004 |
| `sim/sim_top/tb_i2c_xfer.v` | STOP assertion requires SCL high at the previous sample | RUN-0002/0003 |
| `build/asic_evidence/sky130_map.v` | `$pmux` is one scalar mux per bit for every `S_WIDTH` | RUN-0005/0006 |
| `build/asic_evidence/arith_work/sky130_stub.v` | `dfrbp_1/_2` capture on `posedge CLK` | RUN-0008 |
| `scripts/verify.js` | `structural-check`, toolchain probe, `verilator_bin` fallback | RUN-0007, 0010, 0011 |
| `scripts/fw_build/{toolchain,build_fw}.js` | single validated resolver; build prints it | RUN-0010 |
| `scripts/fw_build/build_fw.{py,bat}` | delegate to the resolver / `build_fw.js` | RUN-0010 |
| `scripts/firmware/run_e2e.js` | hardcoded xpack path removed | RUN-0010 |
| `scripts/eda/run_regression.js` | logs the resolved compiler | RUN-0010 |
| `scripts/eda/verilator_build{,_soc}.bat` | forward-slash `VERILATOR_ROOT` (makefile-safe) | RUN-0011 |
| `README.md` | current claims corrected to measured values | RUN-0011 |
| `reports/verification/{README,TEST_RESULTS}.md` | historical banners only; numbers untouched | RUN-0011 |
| `AGENTS.md` | change-log rows + coordination pointer | — |
| `research/**` | study evidence tree, runs RUN-0001…RUN-0011 | manifests |

New untracked study paths: `research/`, `asic/synthesis/` (memory audit, dfrbp
techmap, and `provenance/` with the published arith source + TB),
`scripts/fw_build/toolchain_test.js`,
`scripts/eda/{check_structure,run_pmux_map_test,run_dfrbp_model_test,audit_memory}.js`.
Pre-existing untracked files are **not** this study's and must not be cleaned.

### Completed work (all measured, all with runs)

| Item | Result | Run |
|---|---|---|
| Baseline reproduced at `025ef24` | regression 27/27, gate 9/9 | RUN-0001 |
| F1 — I²C STOP | fixed; negative control failed first | RUN-0002/0003/0004 |
| F2 — `$pmux` width | fixed; 130,048 mismatches before, 0 after | RUN-0005/0006 |
| F8 — fail-closed structure | fixed; 7/7 controls, SoC BLOCKED on 4 memories | RUN-0007 |
| F3 — `dfrbp` clock edge | fixed; 11/11 checks, pre-fix control fails 3/11 | RUN-0008 |
| F5/F7 — memory architecture | inventory reconciled; 4 memories measured; no macro | RUN-0009 |
| F6 — toolchain discovery | one validated resolver; 10/10 + 6 negative controls | RUN-0010 |
| F4 — arithmetic provenance | source+TB published; 1,028 equivalence checks; corrupt control fails | RUN-0011 |
| F9 — evidence correlation | all named targets re-run at the current state; README corrected; Verilator rebuilt | RUN-0011 |

### Memory facts to carry forward (RUN-0009)

| Region | Array | Addressable aperture | Ports |
|---|---|---|---|
| Boot ROM `0x0` | 65,536 B (16384×32) | 16,384 B | 2R 0W |
| TCM `0x1_0000` | 32,768 B (8192×32) | 32,768 B | 2R, 1W ×4 lanes |
| SRAM `0x2000_0000` | 262,144 B (65536×32) | 131,072 B | 2R, 1W ×4 lanes |
| APB decode LUT | 18 B (16×9) | not addressable | 1R 0W |

360,466 B of arrays, 180,224 B addressable, 136 B of register storage
(`rf` 1024 bits, `plic prio` 64 bits), no FIFOs. Checker:
`node scripts/eda/audit_memory.js` (exit 2 BLOCKED, 7/7 drift controls).

### Open findings (`research/findings.csv`)

| ID | Severity | Status | Gist | Next step |
|---|---|---|---|---|
| F5 | high | CONFIRMED | ROM array is 4× and SRAM 2× the aperture; surplus is unreachable | decide shrink vs enlarge map/linker/requirements, then size the macro |
| F7 | high | PARTIAL | 4 inferred memories, inventory complete, **no macro** | needs PDK + 2R1W byte-enable macro, ROM init strategy |
| F9 | medium | PARTIAL | current targets traced; no PPA, no independent review; historical reports banner-marked | scope gate logs per run; never cite pre-`025ef24` numbers |

F1, F2, F3, F4, F6, F8 FIXED. F5 needs a decision; F7 cannot close without a macro.

### Blockers (environment, not design)

- **No memory macro and no memory compiler** → F7 cannot pass; no `.lib/.lef/.gds`.
- **No independent evaluator** → G4.4 unreachable; every result is SELF-EVALUATED.
- **No volare-provisioned sky130A PDK** → no PPA, no P&R/DRC/LVS/STA; ABC `-liberty` broken.
- **No Vivado / FPGA hardware** → FPGA claims stay unverified.
- `python` on PATH is the Windows Store stub; use `D:/tools/venv/Scripts/python.exe`.
- `build_fw.py` needs `node` (delegates resolution); only one real toolchain exists.
- `verilator` Perl wrapper broken; `verilator_bin.exe` 5.053 works and is what the gate lists.
- `build/verify/` is a shared mutable log directory: a negative-control run
  overwrites a real run's logs (happened 20:51, repaired by re-running).
- Full-SoC `flatten` dies with `std::bad_alloc`; counts are per module definition.
- `build/asic_evidence/sky130_tt.lib` and `memories.il` are untracked; runs record sha256.

---

## How to resume

```bash
cd /d/Home-Automation-SoC          # D: only; do not write project data to C:

# 1. state
git rev-parse --short HEAD          # expect 025ef24
git status --porcelain              # expect the dirty set above, unchanged

# 2. verification (fast first, then the full gate ~4 min)
node scripts/eda/check_structure.js --self-test     # expect 7/7, exit 0
node scripts/eda/run_pmux_map_test.js               # expect 7/7, exit 0
node scripts/eda/run_dfrbp_model_test.js            # expect 11/11, exit 0 (F3)
node scripts/eda/run_dfrbp_model_test.js \
  --stub asic/synthesis/techmap/dfrbp_model/sky130_stub_prefix.v --tag control
                                                    # expect exit 1 (negative control)
node scripts/verify.js                              # expect 10/10, exit 0

# 2a. toolchain (F6) — one resolver; overrides are validated, never silently ignored
node scripts/fw_build/toolchain.js                  # resolved path, source, version, flags
node scripts/fw_build/toolchain_test.js             # expect 10/10, exit 0 (5 negative)
node scripts/fw_build/build_fw.js                   # expect exit 0, prints the same gcc path
D:/tools/venv/Scripts/python.exe scripts/fw_build/build_fw.py build   # same gcc path
node scripts/firmware/run_e2e.js                    # expect 7/7, exit 0

# 2b. memory inventory (needs the OSS CAD Suite environment for yosys, ~15 s)
yosys -s asic/synthesis/memory_audit.ys             # expect exit 0
node scripts/eda/audit_memory.js --self-test        # expect 7/7, exit 0
node scripts/eda/audit_memory.js                    # expect BLOCKED, exit 2

# 2c. evidence re-run (F4/F9, RUN-0011) — Verilator and the published arith source
scripts\eda\verilator_build_soc.bat tb_boot sim\sim_top\tb_boot.v build\obj_soc_r11
scripts\eda\verilator_run.bat build\obj_soc_r11\Vtb_boot.exe   # expect 7/7
cmd //c "call D:\tools\oss-cad-suite\environment.bat && yosys -s asic/synthesis/provenance/map_arith.ys"
# then iverilog -DUSE_MAPPED over tb_equiv/arith_test/netlist/stub -> 1028 checks
# corrupt-map build (-DCORRUPT_MAP) must exit 1

# 3. the expensive structural target (~200 s, expected BLOCKED = exit 2)
node scripts/eda/check_structure.js --script asic/synthesis/fullsoc_map.ys \
  --top has_soc --json build/asic_evidence/structural_check/has_soc_cells.json --tag fullsoc
```

EDA invocations need the OSS CAD Suite environment:
`cmd //c "call D:\tools\oss-cad-suite\environment.bat && <tool>"`.
`run_pmux_map_test.js`, `run_dfrbp_model_test.js`, `check_structure.js` and
`run_e2e.js` prepend `D:/tools/oss-cad-suite/{bin,lib}` themselves.
`run_regression.js` and `run_formal.js` do **not**: without the environment call
they report `iverilog: unavailable` / missing tools (preserved as
`regression_no_oss_env.log` in RUN-0011).

---

## Coordination protocol

**Timestamp format:** `YYYY-MM-DD HH:MM IST (YYYY-MM-DDTHH:MMZ)`. Local time is
IST (UTC+0530). Both labels are required; never a bare time.

**Files and who writes them**

| File | Writer | Rule |
|---|---|---|
| `AGENT_HANDOFF.md` | session owner only, at session end | rewrite the STATUS block; move the previous block into STATUS HISTORY; never delete |
| `WORK_LOG.md` | every agent | **append-only**; one block per event (start, checkpoint, block, completion) |
| `REVIEW_LOG.md` | every reviewer | **append-only**; one block per review or decision |
| `DAILY/YYYY-MM-DD.md` | session owner at end of day | append a new day file; use the template in an existing one |
| `agents/<agent>-<date>.md` | that agent | assignment + report for one session |
| `research/findings.csv`, `results.csv` | working agent | append rows; never rewrite another session's row — supersede with a new status |
| `research/runs/<RUN-ID>/` | working agent | immutable once written; a rerun gets a new RUN-ID |

**Anti-overwrite rules**

1. Append to logs; do not edit another agent's block. A correction is a new
   block that says what it supersedes.
2. Only the handoff owner rewrites `AGENT_HANDOFF.md`, and must re-read it
   immediately before writing. The previous STATUS block goes to STATUS HISTORY
   verbatim — a merge that drops a fact is a defect.
3. Two sessions may overlap. If both produced work, the later writer keeps both
   facts and records the conflict in `REVIEW_LOG.md` under "reconciliation".
4. Never reuse or delete a RUN-ID, log line, or findings row.

**Session start (required of every agent)**

1. Read this file, the last 3 `WORK_LOG.md` blocks, and the open items in
   `REVIEW_LOG.md`.
2. Append a WORK_LOG block: id, local+UTC time, agent, objective, files you
   expect to touch.
3. Create `agents/<agent>-<date>.md` if you are a new agent/session.

**Session end (required)**

1. Append a WORK_LOG block with actions, files changed, commands + exit codes,
   results, blockers, and what is unfinished.
2. Append a REVIEW_LOG block for anything you reviewed or decided.
3. Update `AGENT_HANDOFF.md` STATUS + STATUS HISTORY; state the exact stage.
4. Append your part of `DAILY/<date>.md`.

---

## What NOT to trust

These files exist but are **stale** relative to the state above. Do not quote
numbers from them without re-running:

- `resume.md` — says regression 17/17 and Verilator "blocked"; both superseded
  (regression is 27/27; `verilator_bin.exe` works).
- `README.md` status tables, `AGENTS.md` sections 1–7, `reports/MASTER_PROJECT_STATUS.md` —
  snapshots from earlier sessions, not current.
- `build/asic_evidence/arith_test_mapped.v` — does not match a fresh mapping of
  `arith_test.v` (module name, widths, 93 vs 102 cells); provenance unknown (F4).

Authoritative for current facts: this file, `research/findings.csv`,
`research/results.csv`, `research/runs/**` logs.

---

## Subagent orchestration

This environment exposes **no subagent or agent-spawning tool** (verified: the
available toolset has no delegation primitive). Work in this repository is
therefore executed sequentially by one agent, and "independent review" cannot be
manufactured locally — it needs a different model, agent or human.

The structure for delegation is ready if a tool becomes available: one task card
per assignment in `agents/` (objective, inputs, acceptance, owner, due), results
consolidated by the session owner into `WORK_LOG.md` + `REVIEW_LOG.md`, with the
reviewer recorded. Until then, every review entry states
`reviewer: self (same agent)` and is not evidence of independence.

---

## STATUS HISTORY
### Superseded 2026-11-18 20:54 IST (15:24Z) — session `S-2026-11-18-6`

## STATUS (current)

| Field | Value |
|---|---|
| Phase | Day 1 of the 10-day research mandate (`research/protocol.md`) |
| Hard deadline | **2026-11-28T12:17:36Z** (2026-11-28 17:47 IST) |
| Baseline commit | `025ef24f2f4444cac4c38dc62b659fac724770f4` — "test: gate I2C transactions and auto-discover the RISC-V toolchain" |
| Branch | `main`, study commit pushed to origin/main |
| Worktree | **dirty** — 12 modified tracked files (RTL/testbench rows unchanged from earlier runs), new untracked study paths (below) |
| Verification gate | **10 passed, 0 failed, 0 blocked** (re-run 2026-11-18 20:39 IST on the final code state, exit 0) |
| Regression | **PASS 27 / 27**, exit 0 |
| Toolchain | **one resolver, F6 FIXED** — `scripts/fw_build/toolchain.js`; resolved xPack GCC **12.2.0-2**, target `riscv-none-elf` (RUN-0010) |
| Highest gate | `PARTIAL` — G0/G1/G2 partial, G3/G4 open; **no gate is satisfied** |
| Memory audit | **F5 PASS (reconciled) / F7 BLOCKED (no macro)** — RUN-0009 |
| Evaluation status | SELF-EVALUATED — no independent evaluator exists in this environment |
| Active task | none in flight (last completed: F6 toolchain unification, RUN-0010) |

### Dirty worktree (must be preserved)

| File | Change | Evidence |
|---|---|---|
| `rtl/rtl_peripherals/i2c_ctrl.sv` | I²C STOP now a real four-quarter sequence | RUN-0002/0003/0004 |
| `sim/sim_top/tb_i2c_xfer.v` | STOP assertion requires SCL high at the previous sample | RUN-0002/0003 |
| `build/asic_evidence/sky130_map.v` | `$pmux` is one scalar mux per bit for every `S_WIDTH` | RUN-0005/0006 |
| `build/asic_evidence/arith_work/sky130_stub.v` | `dfrbp_1/_2` capture on `posedge CLK` | RUN-0008 |
| `scripts/verify.js` | `structural-check` stage + RISC-V toolchain probe in `tools` | RUN-0007, RUN-0010 |
| `scripts/fw_build/toolchain.js` | single validated resolver + `--json` CLI | RUN-0010 |
| `scripts/fw_build/build_fw.js` | prints resolved compiler path/version | RUN-0010 |
| `scripts/fw_build/build_fw.py` | delegates to `toolchain.js --json`; writes `build/fw/` | RUN-0010 |
| `scripts/fw_build/build_fw.bat` | wrapper over `build_fw.js`, no local logic | RUN-0010 |
| `scripts/firmware/run_e2e.js` | hardcoded xpack path removed; uses resolver | RUN-0010 |
| `scripts/eda/run_regression.js` | logs the resolved compiler | RUN-0010 |
| `AGENTS.md` | change-log rows + coordination pointer | — |
| `research/**` | study evidence tree, runs RUN-0001…RUN-0010 | manifests |

New untracked study paths: `research/`, `asic/synthesis/` (including
`memory_audit.ys`, `memory_inventory.json`, `techmap/dfrbp_model/`),
`scripts/fw_build/toolchain_test.js`,
scripts/eda/{check_structure,run_pmux_map_test,run_dfrbp_model_test,audit_memory}.js`.
38 pre-existing untracked files are **not** this study's and must not be cleaned.

### Completed work (all measured, all with runs)

| Item | Result | Run |
|---|---|---|
| Baseline reproduced at `025ef24` | regression 27/27, gate 9/9 | RUN-0001 |
| F1 — I²C STOP | fixed; negative control failed (5 failures, exit 1) first | RUN-0002/0003/0004 |
| F2 — `$pmux` width | fixed; 130,048 mismatches before, 0 after | RUN-0005/0006 |
| F8 — fail-closed structure | fixed; 7/7 controls, SoC BLOCKED on 4 memories | RUN-0007 |
| F3 — `dfrbp` clock edge | fixed; 11/11 checks, pre-fix control fails 3/11 | RUN-0008 |
| F5/F7 — memory architecture | inventory complete and reconciled; 4 inferred memories measured; no macro | RUN-0009 |
| F6 — toolchain discovery | one validated resolver; 10/10 discovery controls, 6/6 negative controls exit 2; gate 10/10, regression 27/27, E2E 7/7 on the same compiler | RUN-0010 |

### Memory facts to carry forward (RUN-0009)

| Region | Array | Addressable aperture | Ports |
|---|---|---|---|
| Boot ROM `0x0` | 65,536 B (16384×32) | 16,384 B | 2R 0W |
| TCM `0x1_0000` | 32,768 B (8192×32) | 32,768 B | 2R, 1W ×4 lanes |
| SRAM `0x2000_0000` | 262,144 B (65536×32) | 131,072 B | 2R, 1W ×4 lanes |
| APB decode LUT | 18 B (16×9) | not addressable | 1R 0W |

360,466 B of arrays, 180,224 B addressable, 136 B of register storage
(`rf` 1024 bits, `plic prio` 64 bits), no FIFOs. Checker:
`node scripts/eda/audit_memory.js` (exit 2 BLOCKED, 7/7 drift controls).

### Open findings (`research/findings.csv`)

| ID | Severity | Status | Gist | Next step |
|---|---|---|---|---|
| F5 | high | CONFIRMED | ROM array is 4× and SRAM 2× the aperture; surplus is unreachable | decide shrink (ADDR_WIDTH 14/17) vs grow map+linker+requirements, then size the macro |
| F7 | high | PARTIAL | 4 inferred memories, inventory complete, **no macro** | needs PDK + 2R1W byte-enable macro, ROM init strategy |
| F4 | medium | CONFIRMED | `arith_test.v` untracked yet cited by evidence | publish or regenerate from a tracked file |
| F6 | medium | **FIXED** | one resolver for all drivers; overrides validated and fail-closed | none — new drivers must call `findToolchain()` |
| F9 | medium | PARTIAL | Verilator/formal/PPA not re-run at this commit | re-run through `verilator_bin.exe` |

F1, F2, F3, F6, F8 FIXED. F5 has a measurement but needs a decision; F7 cannot
close without a macro.

### Blockers (environment, not design)

- **No memory macro and no memory compiler** → F7 cannot pass; no `.lib/.lef/.gds`.
- **No independent evaluator** → G4.4 unreachable; every result is SELF-EVALUATED.
- **No volare-provisioned sky130A PDK** → no OpenRAM, no OpenLane, no P&R/DRC/LVS/STA.
- **No Vivado / FPGA hardware** → FPGA claims stay unverified.
- `python` on PATH is the Windows Store stub; use `D:/tools/venv/Scripts/python.exe`.
- `build_fw.py` now requires `node` (it delegates resolution); it exits 2 without it.
- Only one real RISC-V toolchain exists here (xPack 12.2.0-2), so toolchain-conflict
  behaviour is proven against a missing prefix, not against a second compiler.
- `verilator` Perl wrapper is broken; only `verilator_bin.exe` runs.
- Full-SoC `flatten` dies with `std::bad_alloc`; counts are per module definition.
- `build/asic_evidence/sky130_tt.lib` and the generated `memories.il` are untracked;
  runs record their sha256.


### Superseded 2026-11-18 20:09 IST (14:39Z) — session `S-2026-11-18-5`

## STATUS (current)

| Field | Value |
|---|---|
| Phase | Day 1 of the 10-day research mandate (`research/protocol.md`) |
| Hard deadline | **2026-11-28T12:17:36Z** (2026-11-28 17:47 IST) |
| Baseline commit | `025ef24f2f4444cac4c38dc62b659fac724770f4` — "test: gate I2C transactions and auto-discover the RISC-V toolchain" |
| Branch | `main`, study commit pushed to origin/main |
| Worktree | **dirty** — 6 modified tracked files (unchanged set), new untracked study paths (below) |
| Verification gate | **10 passed, 0 failed, 0 blocked** (re-run 2026-11-18 20:09 IST, exit 0) |
| Regression | **PASS 27 / 27**, exit 0 |
| Highest gate | `PARTIAL` — G0/G1/G2 partial, G3/G4 open; **no gate is satisfied** |
| Memory audit | **F5 PASS (reconciled) / F7 BLOCKED (no macro)** — RUN-0009 |
| Evaluation status | SELF-EVALUATED — no independent evaluator exists in this environment |
| Active task | none in flight (last completed: memory architecture audit, RUN-0009) |

### Dirty worktree (must be preserved)

| File | Change | Evidence |
|---|---|---|
| `rtl/rtl_peripherals/i2c_ctrl.sv` | I²C STOP now a real four-quarter sequence | RUN-0002/0003/0004 |
| `sim/sim_top/tb_i2c_xfer.v` | STOP assertion requires SCL high at the previous sample | RUN-0002/0003 |
| `build/asic_evidence/sky130_map.v` | `$pmux` is one scalar mux per bit for every `S_WIDTH` | RUN-0005/0006 |
| `build/asic_evidence/arith_work/sky130_stub.v` | `dfrbp_1/_2` capture on `posedge CLK` | RUN-0008 |
| `scripts/verify.js` | `structural-check` stage | RUN-0007 |
| `AGENTS.md` | change-log rows + coordination pointer | — |
| `research/**` | study evidence tree, runs RUN-0001…RUN-0009 | manifests |

New untracked study paths: `research/`, `asic/synthesis/` (including
`memory_audit.ys`, `memory_inventory.json`, `techmap/dfrbp_model/`),
`scripts/eda/{check_structure,run_pmux_map_test,run_dfrbp_model_test,audit_memory}.js`.
38 pre-existing untracked files are **not** this study's and must not be cleaned.

### Completed work (all measured, all with runs)

| Item | Result | Run |
|---|---|---|
| Baseline reproduced at `025ef24` | regression 27/27, gate 9/9 | RUN-0001 |
| F1 — I²C STOP | fixed; negative control failed (5 failures, exit 1) first | RUN-0002/0003/0004 |
| F2 — `$pmux` width | fixed; 130,048 mismatches before, 0 after | RUN-0005/0006 |
| F8 — fail-closed structure | fixed; 7/7 controls, SoC BLOCKED on 4 memories | RUN-0007 |
| F3 — `dfrbp` clock edge | fixed; 11/11 checks, pre-fix control fails 3/11 | RUN-0008 |
| F5/F7 — memory architecture | inventory complete and reconciled; 4 inferred memories measured; no macro | RUN-0009 |

### Memory facts to carry forward (RUN-0009)

| Region | Array | Addressable aperture | Ports |
|---|---|---|---|
| Boot ROM `0x0` | 65,536 B (16384×32) | 16,384 B | 2R 0W |
| TCM `0x1_0000` | 32,768 B (8192×32) | 32,768 B | 2R, 1W ×4 lanes |
| SRAM `0x2000_0000` | 262,144 B (65536×32) | 131,072 B | 2R, 1W ×4 lanes |
| APB decode LUT | 18 B (16×9) | not addressable | 1R 0W |

360,466 B of arrays, 180,224 B addressable, 136 B of register storage
(`rf` 1024 bits, `plic prio` 64 bits), no FIFOs. Checker:
`node scripts/eda/audit_memory.js` (exit 2 BLOCKED, 7/7 drift controls).

### Open findings (`research/findings.csv`)

| ID | Severity | Status | Gist | Next step |
|---|---|---|---|---|
| F5 | high | CONFIRMED | ROM array is 4× and SRAM 2× the aperture; surplus is unreachable | decide shrink (ADDR_WIDTH 14/17) vs grow map+linker+requirements, then size the macro |
| F7 | high | PARTIAL | 4 inferred memories, inventory complete, **no macro** | needs PDK + 2R1W byte-enable macro, ROM init strategy |
| F4 | medium | CONFIRMED | `arith_test.v` untracked yet cited by evidence | publish or regenerate from a tracked file |
| F6 | medium | CONFIRMED | `run_e2e.js` hardcodes a toolchain path | route through shared discovery |
| F9 | medium | PARTIAL | Verilator/formal/PPA not re-run at this commit | re-run through `verilator_bin.exe` |

F1, F2, F3, F8 FIXED. F5 has a measurement but needs a decision; F7 cannot close
without a macro.

### Blockers (environment, not design)

- **No memory macro and no memory compiler** → F7 cannot pass; no `.lib/.lef/.gds`.
- **No independent evaluator** → G4.4 unreachable; every result is SELF-EVALUATED.
- **No volare-provisioned sky130A PDK** → no OpenRAM, no OpenLane, no P&R/DRC/LVS/STA.
- **No Vivado / FPGA hardware** → FPGA claims stay unverified.
- `python` on PATH is the Windows Store stub; use `D:/tools/venv/Scripts/python.exe`.
- `verilator` Perl wrapper is broken; only `verilator_bin.exe` runs.
- Full-SoC `flatten` dies with `std::bad_alloc`; counts are per module definition.
- `build/asic_evidence/sky130_tt.lib` and the generated `memories.il` are untracked;
  runs record their sha256.

### Superseded 2026-11-18 19:47 IST (14:17Z) — session `S-2026-11-18-4`

## STATUS (current)

| Field | Value |
|---|---|
| Phase | Day 1 of the 10-day research mandate (`research/protocol.md`) |
| Hard deadline | **2026-11-28T12:17:36Z** (2026-11-28 17:47 IST) |
| Baseline commit | `025ef24f2f4444cac4c38dc62b659fac724770f4` — "test: gate I2C transactions and auto-discover the RISC-V toolchain" |
| Branch | `main`, study commit pushed to origin/main |
| Worktree | **dirty** — 6 modified tracked files, new untracked study paths (below) |
| Verification gate | **10 passed, 0 failed, 0 blocked** (re-run 2026-11-18 19:41 IST, exit 0) |
| Regression | **PASS 27 / 27**, exit 0 |
| Highest gate | `PARTIAL` — G0/G1/G2 partial, G3/G4 open; **no gate is satisfied** |
| Evaluation status | SELF-EVALUATED — no independent evaluator exists in this environment |
| Active task | none in flight (last completed: F3, RUN-0008) |

### Dirty worktree (must be preserved)

Tracked modifications:

| File | Change | Evidence |
|---|---|---|
| `rtl/rtl_peripherals/i2c_ctrl.sv` | I²C STOP now a real four-quarter, SCL-high/SDA-low sequence | RUN-0002/0003/0004 |
| `sim/sim_top/tb_i2c_xfer.v` | STOP assertion requires SCL high at the previous sample; `invalid_stop` counter | RUN-0002/0003 |
| `build/asic_evidence/sky130_map.v` | `$pmux` is one scalar mux per bit for every `S_WIDTH` | RUN-0005/0006 |
| `build/asic_evidence/arith_work/sky130_stub.v` | `dfrbp_1/_2` capture on `posedge CLK` (was `negedge`) | RUN-0008 |
| `scripts/verify.js` | new `structural-check` stage | RUN-0007 |
| `AGENTS.md` | change-log rows + coordination pointer | — |
| `research/**` | study evidence tree, runs RUN-0001…RUN-0008 | manifests |

New untracked paths owned by this study: `research/`, `asic/synthesis/`
(including `asic/synthesis/techmap/dfrbp_model/`),
`scripts/eda/run_pmux_map_test.js`, `scripts/eda/check_structure.js`,
`scripts/eda/run_dfrbp_model_test.js`.
38 pre-existing untracked files (`experiments/`, `reports/ASIC_PHASE*.md`,
`reports/evidence/`, `sky130_comb.lib`, `sim/sim_top/*.vvp`, stray root files)
are **not** this study's and must not be deleted or "cleaned".

### Completed work (all measured, all with runs)

| Item | Result | Run |
|---|---|---|
| Baseline reproduced at `025ef24` | regression 27/27, gate 9/9, both exit 0 | RUN-0001 |
| F1 — I²C STOP invalid on the wire | fixed; negative control failed (5 failures, exit 1) before the fix | RUN-0002/0003/0004 |
| F2 — `$pmux` single-select truncated vectors | fixed; 130,048 mismatches before, 0 after; 9 `$equiv` cells proven | RUN-0005/0006 |
| F8 — structural checks could not fail | fixed; 7/7 controls, gate stage added, SoC BLOCKED on 4 memories | RUN-0007 |
| F3 — `dfrbp` stub captured on the falling edge | fixed to `posedge CLK`; 11/11 directed checks, pre-fix control fails 3/11; gate 10/10 | RUN-0008 |

### Open findings (`research/findings.csv`)

| ID | Severity | Status | Gist | Next step |
|---|---|---|---|---|
| F4 | medium | CONFIRMED | `build/asic_evidence/arith_test.v` is untracked yet cited by the arithmetic mapping evidence | publish the source or regenerate from a tracked file |
| F5 | high | OPEN | declared ROM/TCM/SRAM sizes not reconciled with implemented capacity | derive sizes from `has_addr_map.sv` and compare |
| F6 | medium | CONFIRMED | `run_e2e.js` hardcodes a toolchain path; `build_fw.py` keeps its own discovery | route both through `scripts/fw_build/toolchain.js` |
| F7 | high | OPEN | 4 inferred `$mem_v2` memories (measured), no macro implementation | pick/build a memory, or blackbox it with documented timing |
| F9 | medium | PARTIAL | Verilator 7/7 boot, formal 6/6 and PPA claims are not re-run at this commit | re-run through `verilator_bin.exe` |

F1, F2, F3, F8 are FIXED and were fixed test-first with a negative control.

### Blockers (environment, not design)

- **No independent evaluator** → G4.4 unreachable; every result is SELF-EVALUATED.
- **No volare-provisioned sky130A PDK** → no OpenLane flow, no P&R, DRC, LVS, STA.
- **No Vivado / FPGA hardware** → FPGA claims stay unverified.
- `python` on PATH is the Windows Store stub; use `D:/tools/venv/Scripts/python.exe`.
- `verilator` Perl wrapper is broken (`Can't locate Pod/Usage.pm`); only
  `verilator_bin.exe` runs, and the unified gate treats Verilator as optional.
- Full-SoC `flatten` dies with `std::bad_alloc` on the behavioural SRAM
  (RUN-0007 limitation), so SoC cell counts are per module definition.
- Full-SoC mapping takes ~200 s; it is a separate command, not a gate stage.
- `build/asic_evidence/sky130_tt.lib` (the authoritative liberty) is untracked;
  runs record its sha256, but a clean checkout cannot re-parse it without the PDK.

---

### Superseded 2026-11-18 19:22 IST (13:52Z) — session `S-2026-11-18-3`

## STATUS (current)

| Field | Value |
|---|---|
| Phase | Day 1 of the 10-day research mandate (`research/protocol.md`) |
| Hard deadline | **2026-11-28T12:17:36Z** (2026-11-28 17:47 IST) |
| Baseline commit | `025ef24f2f4444cac4c38dc62b659fac724770f4` — "test: gate I2C transactions and auto-discover the RISC-V toolchain" |
| Branch | `main`, study commit pushed to origin/main |
| Worktree | **dirty** — 5 modified tracked files, 3 new untracked paths (below) |
| Verification gate | **10 passed, 0 failed, 0 blocked** (RUN-0007, 246 s, exit 0) |
| Regression | **PASS 27 / 27**, exit 0 |
| Highest gate | `PARTIAL` — G0/G1/G2 partial, G3/G4 open; **no gate is satisfied** |
| Evaluation status | SELF-EVALUATED — no independent evaluator exists in this environment |
| Active task | none in flight (RUN-0024 BLOCKED: OpenROAD toolchain unavailable, sky130A PDK absent; framework complete, execution pending environment). Round 6 remediation: Phase 1 (A+B) PASS, Phase 3 Workstream D COMPLETE (P0-2 FIXED), Phase 4 Workstream E COMPLETE (P0-3 FIXED); Phase 5 / Workstream F COMPLETE (consumed-state + dependency integrity FIXED, Overall Phase 5 PASS; P0-2 FIXED in Phase 3R) |

### Dirty worktree (must be preserved)

Tracked modifications:

| File | Change | Evidence |
|---|---|---|
| `rtl/rtl_peripherals/i2c_ctrl.sv` | I²C STOP now a real four-quarter, SCL-high/SDA-low sequence | RUN-0002/0003/0004 |
| `sim/sim_top/tb_i2c_xfer.v` | STOP assertion requires SCL high at the previous sample; `invalid_stop` counter | RUN-0002/0003 |
| `build/asic_evidence/sky130_map.v` | `$pmux` is one scalar mux per bit for every `S_WIDTH` | RUN-0005/0006 |
| `scripts/verify.js` | new `structural-check` stage | RUN-0007 |
| `AGENTS.md` | change-log rows for the three sessions | — |
| `research/**` | study evidence tree, runs RUN-0001…RUN-0007 | manifests |

New untracked paths owned by this study: `research/`, `asic/synthesis/`,
`scripts/eda/run_pmux_map_test.js`, `scripts/eda/check_structure.js`.
38 pre-existing untracked files (`experiments/`, `reports/ASIC_PHASE*.md`,
`reports/evidence/`, `sky130_comb.lib`, `sim/sim_top/*.vvp`, stray root files)
are **not** this study's and must not be deleted or "cleaned".

### Completed work (all measured, all with runs)

| Item | Result | Run |
|---|---|---|
| Baseline reproduced at `025ef24` | regression 27/27, gate 9/9, both exit 0 | RUN-0001 |
| F1 — I²C STOP invalid on the wire | fixed; negative control failed (5 failures, exit 1) before the fix | RUN-0002/0003/0004 |
| F2 — `$pmux` single-select truncated vectors | fixed; 130,048 mismatches before, 0 after; 9 `$equiv` cells proven | RUN-0005/0006 |
| F8 — structural checks could not fail | fixed; 7/7 controls, gate stage added, SoC BLOCKED on 4 memories | RUN-0007 |

### Open findings (`research/findings.csv`)

| ID | Severity | Status | Gist | Next step |
|---|---|---|---|---|
| F3 | high | OPEN | `dfrbp` behavioural stub may trigger on the wrong clock edge; the in-tree subset library omits that cell's `ff`/`clocked_on` block | obtain the authoritative block, then test the model |
| F4 | medium | CONFIRMED | `build/asic_evidence/arith_test.v` is untracked yet cited by the arithmetic mapping evidence | publish the source or regenerate from a tracked file |
| F5 | high | OPEN | declared ROM/TCM/SRAM sizes not reconciled with implemented capacity | derive sizes from `has_addr_map.sv` and compare |
| F6 | medium | CONFIRMED | `run_e2e.js` hardcodes a toolchain path; `build_fw.py` keeps its own discovery | route both through `scripts/fw_build/toolchain.js` |
| F7 | high | OPEN | 4 inferred `$mem_v2` memories (measured; the older "3" undercounted), no macro implementation | pick/build a memory, or blackbox it with documented timing |
| F9 | medium | PARTIAL | Verilator 7/7 boot, formal 6/6 and PPA claims are not re-run at this commit | re-run through `verilator_bin.exe` |

F1, F2, F8 are FIXED and were fixed test-first with a negative control.

### Blockers (environment, not design)

- **No independent evaluator** → G4.4 unreachable; every result is SELF-EVALUATED.
- **No volare-provisioned sky130A PDK** → no OpenLane flow, no P&R, DRC, LVS, STA.
- **No Vivado / FPGA hardware** → FPGA claims stay unverified.
- `python` on PATH is the Windows Store stub; use `D:/tools/venv/Scripts/python.exe`.
- `verilator` Perl wrapper is broken (`Can't locate Pod/Usage.pm`); only
  `verilator_bin.exe` runs, and the unified gate treats Verilator as optional.
- Full-SoC `flatten` dies with `std::bad_alloc` on the behavioural SRAM
  (RUN-0007 limitation), so SoC cell counts are per module definition.
- Full-SoC mapping takes ~200 s; it is a separate command, not a gate stage.

---


---

## Round 6 remediation addendum (2026-11-23)

- **Phase 1** (Workstream A: External Trust Root; Workstream B: Provenance
  Non-Elevation) - **PASS** (both), P0-1 blocked; evidence under
  `third_remediation_round6_20261120/PHASE1/`.
- **Phase 3** (Workstream D: Atomic Finalization) - **COMPLETE**, **P0-2
  FIXED**; evidence under `third_remediation_round6_20261120/PHASE3/`.
- **Phase 4** (Workstream E: Execution Identity / P0-3) - **COMPLETE**,
  **P0-3 FIXED**; evidence under `third_remediation_round6_20261120/PHASE4/`.
  Hex/base64-encoded `python -c` execution no longer evades classification:
  `assistant/r6_authority.py:decode_aware_execution_risk` decodes payloads and
  `r6_execution_guard` is called from `assistant/eco.py` before launch.
- **Phase 4 verdict detail (measured):** execution identity enforcement PASS; static-classification bypass resistance PASS; WSL boundary enforcement PASS; P0-3 FIXED (hex, base64, nested, chr()-built all blocked at the spawn boundary). **Phase 3 regression FAIL**: A8 `test_cancel_during_commit_never_leaves_durable_production_pass` still leaves a durable PRODUCTION PASS after cancellation inside `_save_log` (`_AcceptanceGuard.expired()` is deadline-only). The Phase 3 test artifact `PHASE3/attack_tests/test_p02_reproduction.py` does not run. Both predate Phase 4 and were not fixed (out of Workstream E scope). Overall Phase 4 = PARTIAL.
- **Source changed:** `WORKING_COPY/assistant/r6_authority.py` only (recursive decode + dynamic-inline fail-closed); SHA-256 in `PHASE4/evidence/r6_authority.py.snapshot`.
- **Phase 3R (2026-11-23):** remediated the cancellation durable-PASS regression. Reproduced first (`PHASE3R/evidence/repro_cancellation_durable_pass.json`), then fixed `assistant/eco.py::_save_log` so deadline AND cancellation are latched at the commit boundary, with a post-write re-check; persisted terminal aligned to INCONCLUSIVE/INVALIDATED. 15/15 adversarial matrix, Phase 3 harness repaired (3 passed), Phase 4 17 passed, core suites 92 passed. **Supersedes the earlier Phase 3 'P0-2 FIXED' claim**: cancellation was NOT covered before Phase 3R. Snapshot SHA-256 in `PHASE3R/evidence/`.
- **Phase 5 / Workstream F (2026-11-23):** reproduced 8/20 consumed-state and dependency-integrity gaps first (probe + preserved pre-fix module snapshot), then closed them in three files: `eco.VerifiedCandidate` (immutable contents, declared-path + digest-bound reads), `state_machine.derive_authorization` (declared consumption/deps must be verified, empty/opaque closures denied, duplicate evidence denied, structure-preserving dep normalization) and `r6_authority` (re-hashes declared consumed paths). Post-fix: 20/20 probes, 30/30 adversarial tests (11 of them failed on the pre-fix tree), 209+189+76 green regressions, Phase 3R 18 and Phase 4 17 still green. Remaining paths are ADR §1 T1/T3/T5 boundaries plus one Phase 1/2 schema item; **Workstream G not justified and not started**.
- **Constraints honoured:** production repo `D:\audit\repo` untouched;
  production commit `d8f2117e0e09df03e633ff2789faa699e09e748d` unchanged; no
  commits/pushes/publication; all work inside the isolated Round 6 checkout.

### Phase 6 — Cross-Phase Security Assurance Audit (2026-11-23)

- **Verdict:** CROSS-PHASE PARTIAL — 23 of 26 composed scenarios pass their security invariants; 3 are intentionally violated as documented honest findings (F-01, F-02, F-03).
- **Violations:** 
  - F-01 (X12): Execution identity not re-derived at authorization boundary; `authoritative_qualification` returns True despite envelope carrying `execution_identity["path"]` without re-derivation from the actual spawn.
  - F-02 (X19): Cancelled run still qualifies at the unit boundary; `authoritative_qualification` returns True after CANCEL because the legacy decision was PASS.
  - F-03 (X25): exp.json rollback over a later failure restores PASS status; the unsigned descriptive ledger has no integrity protection to erase a later FAIL.
- **Deliverables in `third_remediation_round6_20261120/PHASE6/`:** `skills_used.md`, `cross_phase_invariants.md`, `attack_matrix.md`, `before_after/README.md`, `regression/results.md`, `findings.md`, `final_adjudication.md`, `changed_files.md`, `attack_tests/chains.py`, `attack_tests/run_audit.py`, `attack_tests/test_cross_phase_chains.py`, `evidence/cross_phase_results.json`, `evidence/summary.json`.
- **Stop condition:** "Stop after the final adjudication. Do not automatically begin remediation or Workstream G." No production code changes were made outside `PHASE6/`. The preserved commit `d8f2117e0e09df03e633ff2789faa699e09e748d` is unchanged.
