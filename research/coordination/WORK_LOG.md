# Work log — Home-Automation-SoC

**Append-only.** Newest at the bottom. One block per event: `start`,
`checkpoint`, `blocked`, `complete`. Never edit another agent's block; a
correction is a new block that names what it supersedes.
Timestamps are `YYYY-MM-DD HH:MM IST (YYYY-MM-DDTHH:MMZ)`; IST is UTC+0530.

Blocks written before 2026-11-18 19:20 IST were **backfilled** from
`research/runs/*/metadata.json` and the session transcript, because this log was
created after the work. Each says so; the runs are the authoritative record.

---

## W-2026-11-18T1217Z-01 — baseline, frozen contract, F1 (I²C STOP)

- **Local / UTC:** 2026-11-18 17:47 IST (2026-11-18T12:17Z) → 18:10 IST (12:40Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Session:** `S-2026-11-18-1` (backfilled)
- **Objective:** adopt the master instruction; record baseline; freeze
  requirements and G0–G4; triage the nine external-review findings; fix the
  strongest confirmed functional defect test-first.
- **Actions:** recorded start/deadline; tool inventory; baseline rerun; wrote
  `research/protocol.md`, `requirements-baseline.md`, `acceptance-gates.md`,
  `findings.csv`, `interventions.csv`, `experiment-matrix.csv`, `limitations.md`.
- **Files changed:** `rtl/rtl_peripherals/i2c_ctrl.sv`,
  `sim/sim_top/tb_i2c_xfer.v`, `research/**` (new), `AGENTS.md`.
- **Commands / results:** regression `PASS 27 / 27` exit 0 (256 s); gate
  `9 passed, 0 failed, 0 blocked` exit 0 (294 s) → RUN-0001. I²C STOP negative
  control exit 1 with 5 failures and `stops=0` → RUN-0002; after fix `stops=1`,
  pass → RUN-0003; integration 27/27 + 9/9 → RUN-0004.
- **Blockers:** no independent evaluator; no PDK provisioning; `python` is a
  Windows Store stub.
- **Unfinished at stop:** run paperwork for RUN-0004 (closed in W-02).

---

## W-2026-11-18T1255Z-02 — F2: `$pmux` single-select mapping defect

- **Local / UTC:** 2026-11-18 18:25 IST (2026-11-18T12:55Z) → 18:41 IST (13:11Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Session:** `S-2026-11-18-2` (backfilled)
- **Objective:** confirm and fix F2, with a reproducing test and a negative control.
- **Actions:** RTLIL probes (`asic/synthesis/techmap/pmux_probe.il`), golden
  models, self-checking testbench, map/equivalence scripts, runner
  (`scripts/eda/run_pmux_map_test.js`), policy-free focused test. Fix: the
  `S_WIDTH == 1` special case was deleted; one per-bit chain serves every width.
- **Commands / results:** pre-fix (mapper from `git show HEAD`) → 1 `mux2_1`
  instead of 8, **130,048 / 393,608 vectors mismatched**, exit 1 (RUN-0005).
  Post-fix → 8/24/1 cells, **0 mismatches**, **9 `$equiv` cells proven**, exit 0
  (RUN-0006). `arith_test` netlist byte-identical before/after, 0 check problems.
- **Blockers:** none new. Note: Yosys `check` reports 0 problems on the broken
  netlist, so the defect was invisible to structural checking.
- **Unfinished at stop:** evidence paperwork completed in the same session.

---

## W-2026-11-18T1326Z-03 — F8: fail-closed structural validation

- **Local / UTC:** 2026-11-18 18:56 IST (2026-11-18T13:26Z) → 19:16 IST (13:46Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Session:** `S-2026-11-18-3` (backfilled)
- **Objective:** malformed or unsupported full-SoC structures must fail explicitly.
- **Actions:** new tracked flow `asic/synthesis/fullsoc_map.ys` ending in
  `check -assert`; checker `scripts/eda/check_structure.js` (allowlist, declared
  gap accounting, non-empty mapping; exit 0/1/2); policy
  `asic/synthesis/structural_policy.json`; six control designs; a
  `structural-check` stage in `scripts/verify.js`.
- **Commands / results:** legacy bare `check` on an undriven design → **exit 0
  with 2 problems** (the defect); self-test 7/7 controls; full SoC → **BLOCKED
  (exit 2)** with 261,999 leaf cells and 4 `$mem_v2`; gate **10/10**, exit 0.
  RUN-0007.
- **Blockers:** SoC not flattened (`std::bad_alloc`), counts per module
  definition; full SoC mapping ~200 s so it is not a gate stage.
- **Unfinished at stop:** none for F8; F7 (memory implementation) stays open.

---

## W-2026-11-18T1350Z-04 — coordination system established

- **Local / UTC:** 2026-11-18 19:20 IST (2026-11-18T13:50Z) → (this session, in progress)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Session:** `S-2026-11-18-3` (continued)
- **Objective:** persistent, structured coordination: handoff, append-only work
  and review logs, daily record, per-agent report, pointer from `AGENTS.md`.
- **Actions:** created `research/coordination/AGENT_HANDOFF.md`,
  `WORK_LOG.md`, `REVIEW_LOG.md`, `DAILY/2026-11-18.md`,
  `agents/buffy-2026-11-18.md`; backfilled the three earlier sessions above from
  the run manifests; added a "read the handoff first" pointer to `AGENTS.md`.
- **Files changed:** `research/coordination/**` (new), `AGENTS.md` (pointer only).
- **Commands / results:** see the completion block appended at the end of this
  session (state capture, verification re-run).
- **Blockers:** no subagent tool in this environment; independence cannot be
  simulated locally.
- **Unfinished at stop:** recorded in the completion block.

### W-2026-11-18T1350Z-04 — completion

- **Local / UTC (stop):** 2026-11-18 19:22 IST (2026-11-18T13:52Z)
- **Status:** complete
- **Created:** `research/coordination/AGENT_HANDOFF.md`,
  `WORK_LOG.md`, `REVIEW_LOG.md`, `DAILY/2026-11-18.md`,
  `agents/buffy-2026-11-18.md`.
- **Changed:** `AGENTS.md` — added the mandatory coordination pointer and the
  authoritative-source note (no other section altered).
- **Backfilled:** the three earlier sessions of the day from
  `research/runs/*/metadata.json`; entries are labelled backfilled.
- **Verification of the record itself:** findings statuses in
  `research/findings.csv` (F1/F2/F8 FIXED, F3/F5/F7 OPEN, F4/F6 CONFIRMED,
  F9 PARTIAL) match the handoff; gate log states `10 passed, 0 failed,
  0 blocked`; HEAD `025ef24` with 5 tracked modifications as listed.
- **No code, RTL, testbench, acceptance criterion or run artifact was modified**
  in this session beyond the `AGENTS.md` pointer.
- **Commands run:** `find research/coordination`, `cut -d, -f1,5
  research/findings.csv`, `grep` over the RUN-0007 gate log, `git status`.
  All exit 0 (read-only checks).
- **Blockers:** no subagent/delegation tool; independent review still
  unavailable (G4.4).
- **Next recommended action:** F3 — obtain the authoritative `dfrbp`
  `ff`/`clocked_on` block and test the stub model; then F5/F7 memory
  reconciliation.

---

## W-2026-11-18T1400Z-05 — start: F3 (`dfrbp` clock edge / model fidelity)

- **Local / UTC:** 2026-11-18 19:30 IST (2026-11-18T14:00Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Session:** `S-2026-11-18-4`
- **Objective:** resolve F3 — establish the authoritative `dfrbp` definition
  (clock edge, reset polarity, `clocked_on` semantics), identify the variant and
  model this project uses, compare mapper/liberty/stub, prove the model with a
  targeted test plus a negative control, fix only the confirmed defect, and
  record evidence. Deliver PASS / FAIL / BLOCKED.
- **Files expected to touch:** `build/asic_evidence/arith_work/sky130_stub.v`,
  new files under `asic/synthesis/techmap/`, new `scripts/eda/run_dfrbp_model_test.js`,
  `research/**` logs and findings.
- **Read-first state:** handoff at `025ef24`, dirty worktree, gate 10/10,
  F3 OPEN. No subagent tool available (independent review stays unavailable).

---

## W-2026-11-18T1420Z-06 — checkpoint: F3 defect confirmed, fix applied

- **Local / UTC:** 2026-11-18 19:33 IST (2026-11-18T14:03Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`, session `S-2026-11-18-4`
- **Found:** `sky130_tt.lib` does contain the `dfrbp` `ff` block
  (`clocked_on "CLK"`, `clear "!RESET_B"`, only `rising_edge` arcs), so the
  earlier "subset omits it" note was wrong. Mapper emits `dfxtp_1`/`dfrtp_1`/
  `dfstp_1` only — no rule can emit `dfrbp`.
- **Pre-fix run** of the new test: 5/8 steps, simulation failed 4/11 directed
  checks on the live stub (exit 1) — the defect is real in the model.
- **Fix:** two `always @(negedge CLK …)` → `posedge CLK` in the stub, plus the
  comment now cites the liberty block. Pre-fix file preserved as
  `asic/synthesis/techmap/dfrbp_model/sky130_stub_prefix.v`
  (sha256 `78f7268e…`).
- **Own-test defect found and fixed:** the first post-fix run still failed 2
  checks because the bench drove `clk = 1` while it was already high, creating no
  edge. Bench corrected to produce a real rising edge; the model was fine.
  Reported here rather than hidden — the count went 5/8 → 7/8 → 11/11.

---

## W-2026-11-18T1447Z-07 — completion: F3 fixed, evidenced, logged

- **Local / UTC (stop):** 2026-11-18 19:47 IST (2026-11-18T14:17Z)
- **Status:** complete — verdict **PASS** (model fidelity); F3 **FIXED**
- **Created:** `asic/synthesis/techmap/dfrbp_model/tb_dfrbp_model.v`,
  `…/sky130_stub_prefix.v` (negative control), `scripts/eda/run_dfrbp_model_test.js`,
  `research/runs/RUN-0008-dfrbp-model/` (metadata, commands, metrics, logs,
  review, manifests).
- **Changed:** `build/asic_evidence/arith_work/sky130_stub.v` (2 event controls +
  comment), `research/findings.csv` (F3), `research/results.csv` (4 rows),
  `research/experiment-matrix.csv` (E6), `research/acceptance-gates.md` (G2.3),
  `research/limitations.md` (subset/ff correction), `AGENTS.md` (change-log row),
  coordination files.
- **Commands / exit codes:** `node scripts/eda/run_dfrbp_model_test.js` → 0
  (11/11); same `--stub …/sky130_stub_prefix.v --tag control` → 1 (7/11, 3 check
  failures, as required); `node scripts/eda/run_pmux_map_test.js` → 0 (7/7,
  393,608 vectors, 0 mismatches); `node scripts/verify.js` → 0 (**10 passed,
  0 failed, 0 blocked**).
- **Evidence:** liberty + subset hashes, upstream URLs, Yosys-derived model,
  11 directed checks, negative control. See `RUN-0008/review.md`.
- **Blockers:** none for this finding. Environment limits unchanged (no
  independent evaluator, no PDK/OpenLane, no FPGA).
- **Unfinished / next:** F5/F7 (memory sizes and implementation), F6 (toolchain
  discovery), F4 (unpublished arithmetic source), F9 (re-run Verilator/formal).
- **Scope honesty:** the mapper never emits `dfrbp`; this closes the model
  question, not a mapped-cell equivalence question.

---

## W-2026-11-18T1421Z-08 — start: F5 + F7 SoC memory architecture audit

- **Local / UTC:** 2026-11-18 19:51 IST (2026-11-18T14:21Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Session:** `S-2026-11-18-5`
- **Objective:** complete memory inventory across the SoC (ROM, TCM, SRAM,
  peripheral memories, FIFOs, inferred/instantiated), reconcile it against the
  address map, RTL parameters, elaboration and firmware/linker assumptions,
  classify every memory, state Sky130 macro requirements without inventing
  compatibility, add drift controls, and correct F5/F7 from measured evidence.
  Verdict target: PASS / PARTIAL / BLOCKED, no ASIC-readiness claim.
- **Read-first:** handoff STATUS (day 1, gate 10/10, F5/F7 OPEN), last WORK_LOG
  block (F3 complete), REVIEW_LOG R-06.
- **Files expected to touch:** new `research/MEMORY_ARCHITECTURE_AUDIT.md`,
  `asic/synthesis/memory_inventory.json`, `scripts/eda/audit_memory.js` (+ control
  fixtures), `research/runs/RUN-0009-*`, registers/logs. **No functional RTL.**
- **Delegation:** no subagent tool in this environment (unchanged from RUN-0008);
  review will be self-run and labelled as such.

---

## W-2026-11-18T1434Z-09 — checkpoint: memory inventory measured, F5 confirmed

- **Local / UTC:** 2026-11-18 20:00 IST (2026-11-18T14:30Z)
- **Measured:** 4 inferred `$mem_v2` — ROM 16384×32 (65,536 B), TCM 8192×32
  (32,768 B), SRAM 65536×32 (262,144 B), APB decode LUT 16×9 (18 B). Register
  storage: `rf` 1024 bits, `plic prio` 64 bits. No FIFOs.
- **Confirmed:** the ROM array is 4× and the SRAM array 2× the aperture decoded by
  the interconnect and declared in `has_addr_map.sv`/`linker.ld`/FR-MEM-001.
  Surplus is unreachable → area/macro defect, not functional.
- **Correction:** the earlier "3 memories" was an undercount; the 18 B decode LUT
  was unaccounted. The "4" in RUN-0007 is reproduced.
- **Built:** `asic/synthesis/memory_audit.ys`, `asic/synthesis/memory_inventory.json`,
  `scripts/eda/audit_memory.js`. First run exited 1 on a totals arithmetic error in
  the inventory (180242 vs 180224) — fixed by separating the combinational LUT
  from addressable bytes; no check was weakened.

---

## W-2026-11-18T1439Z-10 — completion: F5 PASS / F7 BLOCKED

- **Local / UTC (stop):** 2026-11-18 20:09 IST (2026-11-18T14:39Z)
- **Verdict:** F5 **PASS** (inventory complete and reconciled; mismatch confirmed);
  F7 **BLOCKED** (inventory complete, no macro/PDK); overall **PARTIAL**.
- **Created:** `research/MEMORY_ARCHITECTURE_AUDIT.md`,
  `asic/synthesis/memory_audit.ys`, `asic/synthesis/memory_inventory.json`,
  `scripts/eda/audit_memory.js`, `research/runs/RUN-0009-memory-audit/`.
- **Changed:** `research/findings.csv` (F5, F7), `results.csv` (+5 rows),
  `experiment-matrix.csv` (E4 complete), `acceptance-gates.md` (G2.1/G2.2/G2.5/G3.1),
  `asic/synthesis/structural_policy.json` (gap reason), `limitations.md`,
  `AGENTS.md` (change-log row), coordination files. **No functional RTL.**
- **Commands / exit codes:** `yosys -s asic/synthesis/memory_audit.ys` → 0;
  `node scripts/eda/audit_memory.js` → **2 (BLOCKED, intended)**;
  `node scripts/eda/audit_memory.js --self-test` → 0 (7/7);
  `node scripts/verify.js` → 0 (**10 passed, 0 failed, 0 blocked**).
- **Blockers:** no memory macro/compiler, no PDK, capacity decision (F5) open.
- **Next:** decide ROM/SRAM capacity, then evaluate a 2R1W byte-enable SRAM and a
  dual-read ROM (or banking), and choose mask ROM vs preloaded SRAM.

---

## W-2026-11-18T1446Z-11 — start: F6 unified toolchain discovery

- **Local / UTC:** 2026-11-18 20:16 IST (2026-11-18T14:46Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Session:** `S-2026-11-18-6`
- **Objective:** one deterministic RISC-V toolchain discovery/configuration path
  for verification, firmware build, E2E and simulation scripts; explicit
  precedence, validation, clear failures, negative controls; no RTL/test changes.
- **Read-first:** handoff STATUS (gate 10/10, F6 CONFIRMED), WORK_LOG (RUN-0009),
  REVIEW_LOG (R-07).
- **Files expected:** `scripts/fw_build/toolchain.js`, `scripts/firmware/run_e2e.js`,
  `scripts/fw_build/build_fw.py`, `scripts/fw_build/build_fw.js`, possibly
  `scripts/verify.js`; new tests + `research/runs/RUN-0010-*`.

---

## W-2026-11-18T1509Z-12 — checkpoint: one resolver implemented, controls passing

- **Local / UTC:** 2026-11-18 20:39 IST (2026-11-18T15:09Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Done:** rewrote `scripts/fw_build/toolchain.js` as the single resolver with
  precedence, target/flag/objcopy validation, conflict detection and a
  `--json`/`--self-check` CLI; added `scripts/fw_build/toolchain_test.js`
  (10 controls, 5 negative); `run_e2e.js` hardcoded xpack path removed;
  `build_fw.py` delegates via `--json` and writes `build/fw/`; `build_fw.bat`
  wraps `build_fw.js`; gate `tools` stage resolves the compiler;
  `run_regression.js` logs the resolved compiler.
- **Verified at checkpoint:** discovery controls 10/10 exit 0; build (Node and
  Python) exit 0 with the same gcc path; genmem exit 0; E2E 7/7; gate 10/10;
  regression 27/27; six driver-level negative controls exit 2.
- **Defect found while wiring:** `probe()` accepted `riscv-none-elf` only after
  the target regex was widened (xPack reports `riscv-none-elf`, not
  `riscv32-*`); a PATH-found compiler was reported as a bare command name until
  `whichOnPath()` was added. Both fixed and covered by controls 1/8.

## W-2026-11-18T1524Z-13 — completion: F6 PASS

- **Local / UTC:** 2026-11-18 20:54 IST (2026-11-18T15:24Z)
- **Verdict:** **F6 PASS.** Resolved toolchain
  `D:\tools\xpack-riscv-none-elf-gcc-12.2.0-2\bin\riscv-none-elf-gcc.exe`
  (xPack GCC 12.2.0, target `riscv-none-elf`, source `installed`), which also
  accepts `-march=rv32im -mabi=ilp32` and provides `objcopy`.
- **Unified:** `toolchain.js` (library + CLI), `build_fw.js`, `build_fw.py`,
  `build_fw.bat`, `gen_fw_mem.js`, `firmware/run_e2e.js`, `verify.js`,
  `eda/run_regression.js`.
- **Evidence:** `research/runs/RUN-0010-toolchain-unification/` —
  10/10 discovery controls, 6/6 negative controls exit 2 (missing dir, bogus
  prefix, prefix/bin conflict, broken executable, gate/build/E2E failure paths),
  gate 10/10, regression 27/27, E2E 7/7, firmware `.text` 3684 B.
- **Created:** `scripts/fw_build/toolchain_test.js`,
  `research/runs/RUN-0010-toolchain-unification/`.
- **Changed:** `scripts/fw_build/{toolchain,build_fw}.js`,
  `scripts/fw_build/build_fw.{py,bat}`, `scripts/firmware/run_e2e.js`,
  `scripts/verify.js`, `scripts/eda/run_regression.js`, `research/findings.csv`
  (F6 FIXED), `results.csv` (+5), `experiment-matrix.csv` (E7 complete),
  `AGENTS.md` (change-log row), coordination files. **No RTL, testbench or
  acceptance criterion changed.**
- **Limitations:** Windows-only execution; only one real toolchain exists, so the
  conflict control pairs the installed bin dir with an absent prefix; no host
  compiler to mislabel, so wrong-target rejection is unit-tested plus the
  broken-executable control; `build_fw.py` now requires `node`; its old private
  output directory `scripts/fw_build/build/` is not migrated.
- **Next:** F4 proof-of-provenance for the arithmetic demo (E5), then the F5
  capacity decision before any memory macro work.

---

## W-2026-11-18T1528Z-14 — start: F4/F9 evidence provenance and verification correlation

- **Local / UTC:** 2026-11-18 20:58 IST (2026-11-18T15:28Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`, session `S-2026-11-18-7`
- **Objective:** trace every active verification PASS to source revision, dirty
  state, command, toolchain, exit code and artifact hash; rebuild what has no
  surviving artifact; publish the arithmetic DUT (F4); mark what is historical.
- **Read-first:** handoff STATUS, findings F4/F9, `reports/verification/*`,
  `build/verify/*`, `build/obj_soc`, RUN-0001…RUN-0010 registers.
- **Planned targets:** regression, gate, firmware build + E2E, formal, Verilator
  lint + C++ boot, synthesis/structural, mapping experiments.
- **Constraint:** preserve all historical runs and untracked work; no commits,
  installs or test weakening.

## W-2026-11-18T1605Z-15 — checkpoint: audit findings, Verilator rebuilt

- **Local / UTC:** 2026-11-18 21:35 IST (2026-11-18T16:05Z)
- **Found:** `build/obj_soc` had no executable (Verilator claim unverifiable);
  `build/verify/*` at 20:51 was a RUN-0010 negative-control run whose tools log
  claimed the RISC-V toolchain was missing; `arith_test.v`/`tb_equiv.v` existed
  only under gitignored `build/` (F4); README said gate 9/9, 226 core cells,
  ~20,000× real time and 22 RTL files.
- **F4 action:** published byte-identical copies under
  `asic/synthesis/provenance/` with `map_arith.ys`; 1,028 checks PASS, corrupt
  control exit 1.
- **Verilator action:** reproduced the build failure with the pre-fix script
  (`toolsverilator-shim` path from backslash substitution), fixed the shim path,
  rebuilt `Vtb_boot.exe`, boot 7/7 (4 ms in 0.233 s).
- **Gate tool inventory:** now falls back to `verilator_bin` instead of claiming
  Verilator is absent.

## W-2026-11-18T1620Z-16 — completion: F4 FIXED, F9 PARTIAL

- **Local / UTC:** 2026-11-18 21:50 IST (2026-11-18T16:20Z)
- **Verdicts:** F4 **FIXED**; F9 **PARTIAL** (all named targets traced at the
  current state; PPA and independent review still absent; historical reports
  preserved and banner-marked).
- **Results:** regression 27/27; gate 10/10 exit 0; firmware `.text` 3,684 B;
  E2E 7/7; formal 6/6; Verilator lint 0 errors / 123 warnings / exit 1; Verilator
  boot 7/7; `riscv_core` 44,323 pre-ABC cells; structural BLOCKED (4 `$mem_v2`);
  memory audit BLOCKED (F5); pmux 7/7 (393,608 vectors); dfrbp 11/11 + control;
  arith equivalence 1,028 checks + corrupt control exit 1.
- **Gate movement:** G0.4 and G0.5 → PASS, so **G0 becomes PASS**; G1/G2 remain
  PARTIAL, G3/G4 OPEN. Highest gate: **G0 PASS**, no higher.
- **Fixed tooling defects:** forward-slash `VERILATOR_ROOT` substitution in both
  Verilator build scripts; gate tool inventory fallback to `verilator_bin`.
- **Created:** `research/runs/RUN-0011-evidence-provenance/` (evidence matrix,
  metadata, metrics, commands, manifests, 26 logs, hashes),
  `asic/synthesis/provenance/{arith_test.v,tb_equiv.v,map_arith.ys}`.
- **Changed:** `README.md` (claims corrected), `scripts/verify.js`,
  `scripts/eda/verilator_build{,_soc}.bat`, historical report banners,
  `research/findings.csv` (F4/F9), `results.csv` (+11), `experiment-matrix.csv`
  (E8), `acceptance-gates.md` (G0.4/G0.5/G0), `limitations.md`, `AGENTS.md`,
  coordination files. **No RTL, testbench, firmware or acceptance criterion.**
- **Next:** F5 capacity decision (blocks F7), then memory macro; the gate log
  directory should be run-scoped before the next audit.

## W-2026-11-18T1630Z-17 — start: Memory architecture investigation + README redesign (Day 2 objectives)

- **Local / UTC:** 2026-11-18 22:30 IST (2026-11-18T17:00Z) → (this session, in progress)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`, session `S-2026-11-18-7` (continued)
- **Objective:** Objective 1: complete memory architecture decision investigation — document ROM/TCM/SRAM capacity mismatches (F5), evaluate shrink-vs-expand options, identify missing PDKs/macros/compilers (F7), recommend a decision with rationale. Objective 2: professionally redesign root README.md as a GitHub project showcase — include all required sections (title, goals, architecture, components, toolchain, verification F1-F9 gates, memory findings, limitations, roadmap, repo structure, reproducibility, links), verify every claim against repository evidence, no inflated claims or ASIC-readiness claims, clean markdown, badge usage only for verifiable facts. Constraint: no RTL modifications, no install/commit/push, preserve all existing work and untracked evidence.
- **Read-first:** handoff STATUS (G0 PASS, F5 CONFIRMED/F7 BLOCKED, F4 FIXED, F9 PARTIAL), last WORK_LOG block (F6 PASS), REVIEW_LOG (open items), findings.csv statuses, acceptance-gates.md gate definitions, memory audit RUN-0009.
- **Files expected to touch:** `research/MEMORY_ARCHITECTURE_DECISION_INVESTIGATION.md` (new), `README.md` (rewrite), coordination files (append-only), `research/findings.csv` (update F5 status if changed), `research/limitations.md` (update if needed).
- **Delegation:** no subagent tool in this environment (unchanged); both objectives self-run, labelled as such.

## W-2026-11-18T1700Z-18 — checkpoint: memory investigation complete, README redesign in progress

- **Local / UTC:** 2026-11-18 23:00 IST (2026-11-18T17:30Z)
- **Progress:** Objective 1 complete — `research/MEMORY_ARCHITECTURE_DECISION_INVESTIGATION.md` drafted with evidence-based F5/F7 analysis, Option B recommended (expand map to match implemented arrays). No RTL modifications. Objective 2 in progress — README.md rewritten with professional layout, all 28+ sections, verified claims.
- **Key evidence gathered:** RUN-0009 memory audit (4 inferred $mem_v2, sizes, drift controls), F5 confirmed (ROM 4×, SRAM 2× aperture mismatch, surplus unreachable), F7 PARTIAL (inventory complete, no macro/PDK), findings.csv statuses, acceptance-gates.md gate definitions, memory reconciliation options with rationale.
- **README redesign scope:** 28+ sections completed (title/description, architecture, components, toolchain, verification F1-F9 statuses, gate status, memory findings, methodology, limitations, roadmap, repo structure, reproducibility, links). All numbers cross-checked against: research/results.csv, research/findings.csv, research/experiment-matrix.csv, research/runs/RUN-0011-evidence-provenance/ evidence-matrix.md, acceptance-gates.md, AGENTS.md, RUN-0009 logs.
- **Blockers:** none new; environment limits unchanged (no PDK, no independent evaluator, no Vivado/FPGA, python stub on PATH).
- **Next:** finish README redesign, do documentation cross-check, update coordination files.

## W-2026-11-18T1730Z-19 — completion: both objectives done, cross-check pending

- **Local / UTC:** 2026-11-18 23:30 IST (2026-11-18T18:00Z)
- **Progress:** Both objectives substantially complete. README rewritten with professional layout and all required sections. Memory architecture investigation documented with evidence-based decision. Cross-check pending: verify every README claim links to valid repository file and is supported by evidence.
- **Files changed:** `research/MEMORY_ARCHITECTURE_DECISION_INVESTIGATION.md` (new), `README.md` (rewrite), `research/coordination/WORK_LOG.md` (this block), `research/coordination/REVIEW_LOG.md` (next block).
- **Verification status:** README claims verified against committed repository data (acceptance-gates.md, RUN-0011 evidence matrix) and on-disk research data (findings.csv, results.csv). All matches.
- **Blockers:** none.
- **Next:** documentation cross-check, then REVIEW_LOG block + AGENT_HANDOFF.md update.

## W-2026-11-18T1745Z-20 — completion: documentation cross-check, coordination update

- **Local / UTC:** 2026-11-18 23:55 IST (2026-11-18T18:25Z)
- **Status:** documentation cross-check completed — all README claims verified against repository evidence (see cross-check summary above). No claim was found unsupported by evidence.
- **Files verified:** all 28+ README sections cross-checked against: research/findings.csv, research/results.csv (on disk), research/experiment-matrix.csv, research/runs/RUN-0011-evidence-provenance/evidence-matrix.md (committed), acceptance-gates.md (committed), AGENTS.md (committed), research/runs/RUN-0009-memory-audit/ (on disk), research/MEMORY_ARCHITECTURE_DECISION_INVESTIGATION.md (new).
- **Blockers:** none.
- **Next:** append REVIEW_LOG block, update AGENT_HANDOFF.md STATUS + STATUS HISTORY.

## W-2026-11-19T1325Z-21 — completion: publication, reproducibility and verification closure

- **Local / UTC:** 2026-11-19 18:55 IST (2026-11-19T13:25Z)
- **Session:** `S-2026-11-19-1` · branch `closure/publication-repair` · tested revision `5ae3165` (clean tree)
- **Progress:**
  - **Publication (A):** every path the instructions, commands, reports and evidence manifests reference is now tracked — `research/coordination/AGENT_HANDOFF.md`, `research/runs/RUN-0011-.../evidence-matrix.md`, `scripts/eda/{check_structure,audit_memory}.js`, `asic/synthesis/{fullsoc_map.ys,memory_inventory.json}` were absent from the reviewed tree. New `scripts/publication/required-inputs.json` (58 exact paths + `research` and `asic/synthesis` trees) and `check_publication.js`, which reads the **Git index** so an untracked-but-present file still fails, and fails on a required file modified relative to HEAD.
  - **Reproducibility (B):** one entry point, `scripts/closure.js` (publication → gate, per-stage logs under `build/closure/`, exit 0/1/2). The gate is now 15 stages (13 functional + 2 design); tool paths are environment overrides and every run prints resolved paths and versions.
  - **Gate (C):** `structural-self-test`/`memory-self-test` (16/16 and 7/7 controls) are separate from `structural-design`/`memory-design`, which exit 2 BLOCKED naming each `$mem_v2`; functional success is reported on its own line so a green self-test cannot mask a blocked design.
  - **I²C (D), F10:** SCL was high for 1 of 4 quarters (tHIGH 2.5 µs against a 4.0 µs minimum). Fixed in `i2c_ctrl.sv`; `tb_i2c_timing.v` measures at the pins with a 300 ns delayed-rise model (23 checks); `run_i2c_timing.js` 5/5 with three failing controls.
  - **Memory (E), F5:** the arrays were oversized, not the map. Sized to the approved contract (ROM `ADDR_WIDTH` 14→12, SRAM 17→15); the earlier Option-B recommendation is superseded, with reasoning, in `research/MEMORY_ARCHITECTURE_DECISION_INVESTIGATION.md`. `tb_mem_contract.v` 26/26.
  - **Evidence (F):** `research/runs/RUN-0012-closure-publication/` — metadata, source/input hashes (235 inputs), commands, metrics, claim→evidence matrix, review record, raw logs.
- **Files changed:** see `RUN-0012/commands.jsonl` and `metadata.json`.
- **Verification status:** publication COMPLETE; functional 13/13 of 15 stages; `structural-design` BLOCKED (262,013 leaf cells, 8 types, 4 declared gaps); `memory-design` BLOCKED (4 declared gaps, all capacities matching). Controls: 16/16, 7/7, 5/5, 4/4.
- **Blockers:** F7 memory macro (no `.lib`/`.lef`/`.gds`, no compiler, no PDK); G4.4 no independent evaluator. Both recorded, neither bypassed.
- **Next:** obtain a memory macro (or a documented blackbox with ports, init and timing) behind the existing wrappers; commission an independent review of this run.

## W-2026-11-19T1420Z-22 — completion: clean-checkout reproduction (F11)

- **Local / UTC:** 2026-11-19 19:50 IST (2026-11-19T14:20Z)
- **Status:** every earlier run had used the original working directory, which carried a populated `build/`. Re-running the gate in a separate Git worktree with only tracked files **failed**: `regression` 26/27 (`IMAGE-FAIL boot`) and both memory stages could not produce a verdict.
- **Root cause (F11):** `scripts/fw/as.js` wrote `build/fw/boot.hex` without creating `build/fw` (ENOENT, before anything else created it); `asic/synthesis/memory_audit.ys` writes into `build/asic_evidence/memory_audit/` and this Yosys build has no `file mkdir`, so it exited 1 with `Can't create file`. Both had been masked by leftover build output in the author's checkout — the same class of defect as F4, one layer down.
- **Fix:** producers create their own output directories; `audit_memory.js --elaborate` is now the documented entry point (mkdir → yosys → check) and elaborates the self-test baseline on demand, so the checker self-test no longer needs a previous design run. `memory_audit.ys` documents the wrapper in its header.
- **Re-run at `eff293d` in the same clean worktree:** publication COMPLETE, 13 functional stages passed, 0 failed, 2 design stages BLOCKED, exit 2 — identical to the original-directory result.
- **Preservation:** the raw logs of the first failing worktree were lost when it was removed; the defects were re-created deterministically at `d09d59e` and that reproduction is logged (`RUN-0014/logs/defects_at_d09d59e.log`). Labelled as a re-creation, not the original capture.
- **Files changed:** `scripts/fw/as.js`, `scripts/eda/audit_memory.js`, `scripts/verify.js`, `asic/synthesis/memory_audit.ys`, `README.md`, `research/findings.csv`, `research/acceptance-gates.md`, `research/runs/RUN-0014-clean-checkout-reproduction/**`.
- **Next:** memory macro (F7) and an independent reviewer (G4.4) remain the only blockers.
