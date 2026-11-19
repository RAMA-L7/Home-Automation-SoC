# RUN-0012 — claim → evidence matrix

Tested revision: `c79cbdca0be4656cab3c3856a6c9aedf7c2d228f` (branch
`closure/publication-repair`, worktree clean, 0 modified tracked files).
Reviewed revision this run responds to: `418688b260a4a6036b60dffe2b21efdc11ffc177`.
All results are **SELF-EVALUATED**: no independent evaluator existed, so G4.4
remains OPEN and nothing here is described as independently validated.
This run predates the evidence-only commit that publishes it; the evidence
commit is not a second execution. The run directory was staged outside the
repository during execution and moved back afterwards, so the tree that ran and
the tree that is published contain the same inputs — a first attempt that left
the evidence in place correctly reported `PUBLICATION: 2 gap entries, exit 1`,
which is recorded here rather than deleted.

| # | Claim | Checked with | Evidence | Independently evaluated | What it does not establish |
|---|---|---|---|---|---|
| 1 | Every input the supported commands, reports and evidence manifests reference is in the Git tree | `node scripts/publication/check_publication.js` (reads `git ls-files`, not the disk) | `logs/closure_publication.log` — 58 exact paths, 2 trees, 0 gaps, exit 0 | No | That the files are *correct*, only that they are published and unmodified relative to HEAD |
| 2 | The publication check fails when a required file is present but untracked | same script, 4 controls in a scratch repo | `logs/publication_controls.log` — untracked 1, tracked 0, deleted 1, modified 1 | No | That every future manifest entry is right; only that the failure mode is detected |
| 3 | The gate runs from a clean checkout without the original working directory's untracked files | `node scripts/closure.js` on a clean worktree | `logs/closure_stdout.log`, `logs/closure_summary.txt` | No | That a different machine with different tools reproduces it; only this clean tree |
| 4 | Checker self-tests and design checks are separate stages | `node scripts/verify.js` stage list | `logs/closure_verify.log` — `structural-self-test` and `memory-self-test` reported apart from `structural-design` and `memory-design` | No | That the checks themselves are complete |
| 5 | The structural checker discriminates the required failure modes | `node scripts/eda/check_structure.js --self-test` | `logs/structural_self_test.log` — 16/16, including missing input, introduced defect, undeclared generic cell, stale declared gap, empty mapping, truncated report, broken tool | No | That the *design* is clean; that is claim 6 |
| 6 | The actual current design is structurally BLOCKED, not qualified | `yosys -s asic/synthesis/fullsoc_map.ys` + `check_structure.js` | `logs/stage_structural-design.log` — 262013 leaf cells, 8 types, 4 declared `$mem_v2` gaps, exit 2 | No | Anything about timing, area or physical legality |
| 7 | Memory inventory/implementation evaluation is BLOCKED by name | `yosys -s asic/synthesis/memory_audit.ys` + `node scripts/eda/audit_memory.js` | `logs/stage_memory-design.log` — 4 gaps: MEM-ROM 16384 B, MEM-TCM 32768 B, MEM-SRAM 131072 B, MEM-DECODE-LUT 18 B, exit 2 | No | That a macro exists; it does not |
| 8 | The memory contract is self-consistent (F5) | `audit_memory.js` + `sim/sim_top/tb_mem_contract.v` | `logs/stage_memory-design.log` (all regions match), `logs/stage_memory-contract.log` (26 checks, 0 errors) | No | That the implementation is a macro; see claim 7 |
| 9 | The memory audit detects drift | `node scripts/eda/audit_memory.js --self-test` | `logs/memory_self_test.log` — 7/7, including a changed map, a changed aperture and a missing initialisation | No | That no drift mode is unmodelled |
| 10 | I²C standard-mode timing is met at the pins (F10) | `node scripts/eda/run_i2c_timing.js` | `logs/stage_i2c-timing.log` — fSCL 100.00 kHz, tHIGH 4700 ns, tLOW 5300 ns, tSU;DAT 2500 ns, tHD;DAT 20 ns, tHD;STA 5000 ns, tSU;STO 5000 ns, tBUF 14720 ns; 5/5 including 3 failing controls | No | Fast mode, clock stretching, repeated START; pad delay, drive strength, real bus electricals |
| 11 | I²C timing checks fail when the timing is wrong | same runner | `logs/stage_i2c-timing.log` — too-short divider fails 8 checks; simultaneous STOP release rejected; one-quarter START hold fails tHD;STA | No | That other timing corners are covered |
| 12 | Functional regressions still pass | gate stage `regression` | `logs/closure_verify.log` — `PASS regression exit 0` | No | That the tests are exhaustive |
| 13 | ASIC readiness stays BLOCKED while declared gaps exist | gate summary | `logs/closure_verify.log` — `ASIC readiness: BLOCKED (0/2 design stages pass)`, overall exit 2 | No | When it will clear; that needs a PDK and a macro |

## Failure and blocker classification

| Item | Classification | Reason |
|---|---|---|
| `structural-design` | BLOCKED | 4 inferred `$mem_v2` with no macro implementation (F7/TD-006) |
| `memory-design` | BLOCKED | same 4 memories, each named with its capacity |
| F7 macro integration | BLOCKED | no `.lib`/`.lef`/`.gds`, no memory compiler, no provisioned PDK |
| G4.4 independent review | BLOCKED | no independent evaluator available |

Nothing in this run is classified FAIL: every executed check passed, and the
two design stages cannot pass until an implementation exists. The distinction
matters — a BLOCKED stage is not a false PASS and is not reported as one.

## Cost and duration

Total closure wall clock 320.6 s, dominated by the full-SoC synthesis inside
`structural-design`. The gate is re-runnable end to end from a clean checkout.
