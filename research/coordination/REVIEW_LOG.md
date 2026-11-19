# Review log — Home-Automation-SoC

**Append-only.** One block per review, finding, decision or reconciliation.
Never edit or delete an existing block; supersede with a new one and name what it
supersedes. Timestamps `YYYY-MM-DD HH:MM IST (YYYY-MM-DDTHH:MMZ)`.

**Severity:** `critical` (wrong silicon / silent pass), `high` (credibility or
signoff blocker), `medium` (reproducibility or maintenance), `low` (cosmetic).
**Status:** `OPEN`, `CONFIRMED`, `FIXED`, `PARTIAL`, `REJECTED-with-reason`.
**Reviewer:** an entry only counts as *independent* when the reviewer line names
a different agent, model or human. Everything below is `self (same agent)`
unless it says otherwise.

Live finding state is `research/findings.csv`; this log is the history of how it
got there.

---

## R-01 — external review imported, nine findings triaged

- **Local / UTC:** 2026-11-18 17:47 IST (2026-11-18T12:17Z)
- **Reviewer:** external review at commit `025ef24` (identity not recorded in the
  supplied material)
- **Scope:** `025ef24f2f4444cac4c38dc62b659fac724770f4`, treated as historical
  context, not as an assumption about HEAD
- **Decision:** re-verify every item against the working tree before calling it
  open or fixed. Nothing accepted on the reviewer's authority alone.

| ID | Severity | Status after triage | Claim | Evidence |
|---|---|---|---|---|
| F1 | critical | CONFIRMED → later FIXED | I²C STOP releases SCL and SDA in the same cycle | `i2c_ctrl.sv:158-165`, transition at `:113` |
| F2 | critical | CONFIRMED → later FIXED | `$pmux` single-select branch wires vectors to a scalar mux | `sky130_map.v:380-386` |
| F3 | high | OPEN | `dfrbp` stub may use the wrong clock edge | `arith_work/sky130_stub.v:151-162`; subset lib omits `ff` |
| F4 | medium | CONFIRMED | arithmetic evidence cites an untracked source | `git ls-files` says unknown; file present |
| F5 | high | OPEN | declared region sizes may exceed what is implemented | `has_addr_map.sv:11-15` vs inferred `$mem_v2` |
| F6 | medium | CONFIRMED | build entry points bypass shared toolchain discovery | `run_e2e.js:17`, `build_fw.py` |
| F7 | high | OPEN | inferred memories with no implementation inventory | 3 claimed; measured 4 in R-04 |
| F8 | critical | OPEN → later FIXED | structural problems do not fail the run | bare `check` in the SoC flow |
| F9 | medium | PARTIAL | reported totals lack commit-matched raw evidence | regression/gate re-run; Verilator/formal not |

**Unresolved concern carried forward:** the review's identity and method are not
documented in the repository, so it cannot be cited as independent verification
for gate G4.4.

---

## R-02 — self-review of the F1 fix (I²C STOP)

- **Local / UTC:** 2026-11-18 18:10 IST (2026-11-18T12:40Z)
- **Reviewer:** self (same agent)
- **Finding:** F1 — **FIXED**
- **Evidence:** negative control RUN-0002 (strengthened assertion, unmodified
  RTL) → exit 1, 5 failures, `stops=0` on write/read/NACK-abort; fix RUN-0003 →
  `stops=1`, pass; integration RUN-0004 → regression 27/27, gate 9/9, exit 0.
- **Decision:** accepted as fixed for I²C transaction timing.
- **Unresolved concerns:**
  - `do_stop` is still ignored: a command without the stop bit also terminates
    with STOP. Separate contract deviation, not fixed.
  - The test proves ordering (SCL high before SDA rises), not analog setup/hold;
    no pull-up strength, capacitance or rise time is modelled.

---

## R-03 — self-review of the F2 fix (`$pmux` width)

- **Local / UTC:** 2026-11-18 18:41 IST (2026-11-18T13:11Z)
- **Reviewer:** self (same agent)
- **Finding:** F2 — **FIXED**
- **Evidence:** RUN-0005 (mapper from `git show HEAD`) → 1 `mux2_1` instead of 8,
  130,048/393,608 vectors wrong, exit 1. RUN-0006 → 8/24/1 cells, 0 mismatches,
  9 `$equiv` cells proven against `pmuxtree`, `arith_test` netlist unchanged.
- **Decision:** accepted as fixed for the `$pmux` rule only.
- **Unresolved concerns:**
  - **Not** a general mapper proof: `$add`, `$eq`, `$adff`, `$div` and the rest
    of `sky130_map.v` remain unproven (F3 is part of this).
  - Equivalence uses a behavioural `mux2_1` matching the library function
    `(A0&!S)|(A1&S)`; no timing, load or glitch model.
  - `S_WIDTH > 1` with overlapping selects differs from `pmuxtree` — legal,
    since the cell contract is one-hot; it is covered by simulation only.
  - Measurement worth remembering: Yosys `check` reported **0 problems** on the
    broken netlist. Port-width truncation is legal, so structural checks are
    blind to this class of defect.

---

## R-04 — self-review of the F8 fix (fail-closed structural validation)

- **Local / UTC:** 2026-11-18 19:16 IST (2026-11-18T13:46Z)
- **Reviewer:** self (same agent)
- **Finding:** F8 — **FIXED**; F7 evidence **corrected** (3 → 4 memories)
- **Evidence:** RUN-0007. Legacy bare `check` on an undriven design → exit 0 with
  2 problems. Enforced path: 7/7 controls (1 legacy silent pass, 5 injected
  defects rejected, 1 clean baseline accepted); full SoC **BLOCKED (exit 2)**,
  261,999 leaf cells, 0 check problems, 4 declared `$mem_v2`; gate 10/10.
- **Decision:** structural validation now fails closed. Declared gaps are
  reported as BLOCKED and never as PASS.
- **Unresolved concerns:**
  - Memories are declared, not implemented (F7/TD-006). The old "3 memories"
    note undercounted: measurement found 4 (1 `has_soc`, 1 `boot_rom`, 2 `sram`
    parameterizations).
  - Counts are per module definition because the SoC cannot be flattened
    (`std::bad_alloc`); correct only while each module is instantiated once.
  - The declared inventory is hand-maintained, not derived from the address map
    (F5 remains open).
  - The gate runs the fast control matrix, not the ~200 s SoC mapping, so a
    SoC-only regression needs the explicit checker command.
  - No equivalence, timing, power, DRC, LVS, DFT or pad-ring check is included.

---

## R-05 — coordination system: scope and non-decisions

- **Local / UTC:** 2026-11-18 19:20 IST (2026-11-18T13:50Z)
- **Reviewer:** self (same agent)
- **Decision:** adopt `research/coordination/` as the single coordination point,
  reusing the existing `research/` evidence tree rather than creating a parallel
  reporting system. `AGENT_HANDOFF.md` is the status report; `WORK_LOG.md` and
  `REVIEW_LOG.md` are append-only; `research/findings.csv` remains the live
  finding register and is not duplicated here.
- **Non-decisions:** no RTL, verification logic, acceptance criterion, finding
  status or run artifact was modified while establishing the system.
- **Unresolved concern:** no subagent tool exists in this environment, so
  independent review remains unavailable and G4.4 stays open. The `agents/`
  structure is prepared for delegation but unused until such a tool exists.
- **Documentation debt:** `resume.md`, `README.md` status tables,
  `AGENTS.md` sections 1–7 and `reports/MASTER_PROJECT_STATUS.md` are stale.
  They were not rewritten here (out of scope); the handoff names them as
  untrusted and lists the authoritative sources.

---

## R-06 — F3 resolved: `dfrbp` model vs the authoritative library

- **Local / UTC:** 2026-11-18 19:47 IST (2026-11-18T14:17Z)
- **Reviewer:** self (same agent) — **not independent**
- **Finding:** F3 — **FIXED**
- **Scope:** `build/asic_evidence/arith_work/sky130_stub.v`, the mapper
  `build/asic_evidence/sky130_map.v`, `sky130_tt.lib`,
  `sky130_full_subset.lib`, upstream SkyWater Verilog, and one new test.

**Authoritative definition (all three agree: rising edge, async active-low clear)**

| Source | Statement | Hash / provenance |
|---|---|---|
| `build/asic_evidence/sky130_tt.lib` `cell ("sky130_fd_sc_hd__dfrbp_1")` | `ff ("IQ","IQ_N") { clear : "!RESET_B"; clocked_on : "CLK"; next_state : "D"; }`; `CLK->Q` `timing_type "rising_edge"` (×2), no `falling_edge` arc | sha256 `ec0e1067…`, lines 51314/51801 |
| `build/asic_evidence/sky130_full_subset.lib` | identical `ff` blocks for `_1` (line 1587) and `_2` (2074) | sha256 `5256f24d…` |
| SkyWater `sky130_fd_sc_hd__dfrbp.functional.v` + `udp_dff$PR` | `udp_dff$PR dff0 (buf_Q, D, CLK, RESET)` with `RESET = ~RESET_B`; UDP comment "Positive edge triggered D flip-flop with active high"; table captures on `r` (rising) | archived `google/skywater-pdk-libs-sky130_fd_sc_hd`, `main`, fetched 2026-11-18T14:05Z |
| Yosys liberty-derived model in `arith_test_full_mapped.v:588` | `always @(posedge CLK, posedge _1_)` with `_1_ = ~RESET_B` | in-tree, generated by `read_liberty` |

**Defect:** the stub used `always @(negedge CLK or negedge RESET_B)` in both
`dfrbp_1` and `dfrbp_2`. Nothing else was wrong (pins, `Q_N`, reset polarity).

**Fix:** `negedge CLK` → `posedge CLK`, plus the comment/liberty note. Pre-fix file
preserved as `asic/synthesis/techmap/dfrbp_model/sky130_stub_prefix.v`
(sha256 `78f7268e…`) and wired in as the negative control.

**Evidence:** `asic/synthesis/techmap/dfrbp_model/tb_dfrbp_model.v` (11 directed
checks, both drive strengths) and `scripts/eda/run_dfrbp_model_test.js` (11 steps:
liberty parse, subset parity, stub event control, edge parity for all 11
sequential cells, mapper inventory, netlist inventory, two simulations).
Post-fix 11/11 exit 0; preserved pre-fix model 7/11 exit 1 with 3 check failures.
Regression: `$pmux` 7/7, unified gate 10/10. RUN-0008.

**Correction recorded here:** R-01/R-03 and `findings.csv` said the subset liberty
"omits the `ff`/`clocked_on` block for `dfrbp_1`". It does not — the block is at
line 1587 and is identical to the full liberty. The earlier note came from
counting `clocked_on` occurrences (11) instead of opening the cell. The reference
was available all along; F3 stayed open longer than necessary because of it.

**Decision:** F3 closed. The mapped cell is not exercised by this project's flow,
so this closes the *model* question only — see concerns below.

**Unresolved concerns:**
- The mapper emits `dfxtp_1`/`dfrtp_1`/`dfstp_1` only; `dfrbp` has 0
  instantiations in 72 netlist files. If a future rule emits it, that rule needs
  its own equivalence check.
- Functional model only: no timing, recovery/removal, clk→Q, power pins.
- Upstream source read from an archived repository at `main`; no commit pinned.
- No independent reviewer in this environment (G4.4 open).

---

## R-07 — F5/F7 memory architecture audit

- **Local / UTC:** 2026-11-18 20:09 IST (2026-11-18T14:39Z)
- **Reviewer:** self (same agent) — **not independent**
- **Findings:** F5 **CONFIRMED** (audit complete), F7 **PARTIAL → BLOCKED for ASIC**
- **Scope:** elaboration, address map, interconnect decode, linker, requirements,
  RTL parameters. **No functional RTL modified.**

**Measured inventory** (from `asic/synthesis/memory_audit.ys`: `proc`,
`memory_collect`, `stat -json`, `write_rtlil`; no techmap/flatten):

| Memory | Geometry | Bytes | Ports | Decoded | Result |
|---|---|---|---|---|---|
| Boot ROM | 16384×32 | 65,536 | 2R 0W | 16,384 | 4× aperture |
| TCM | 8192×32 | 32,768 | 2R 1W×4 | 32,768 | match |
| SRAM | 65536×32 | 262,144 | 2R 1W×4 | 131,072 | 2× aperture |
| APB decode LUT | 16×9 | 18 | 1R 0W | n/a | logic |

Plus register storage: `rf` 32×32 (1024 bits), `plic prio` 8×8 (64 bits). No FIFOs
(UART FCR reads `0x01`; no other array exists).

**Reconciliation:** the address map, the interconnect literals, the linker and
FR-MEM-001 agree with each other (16K/32K/128K) and disagree with the RTL arrays
(64K/32K/256K). The surplus is unreachable, so this is an area/macro-sizing
defect, not a functional one. Which side changes is a **decision**, recorded as
open.

**Correction recorded here:** the earlier "3 memories" figure was an undercount;
the earlier "4" is reproduced and explained (2 SRAM parameterizations + ROM +
the 18 B decode LUT that was previously unaccounted).

**Decision:** F5 audit closed as PASS (the question "do they disagree" is answered
with numbers); the defect stays open until a size decision is made. F7 stays
BLOCKED: no macro, no PDK, no compiler, and a macro cannot be sized before the F5
decision.

**Controls:** `scripts/eda/audit_memory.js`, 7/7 — clean design → exit 2,
missing entry / edited depth / false "fixed" claim / changed map / changed
interconnect / lost ROM init → exit 1. A declared gap can never report PASS.

**Unresolved concerns:**
- Macro port support (2R + byte-write, dual-read ROM) is unverified; no datasheet
  exists in the tree. The requirement table is a specification, not a claim.
- Read-during-write semantics of any replacement macro must be checked against the
  RTL's pre-write read.
- ROM initialization strategy (mask vs preloaded SRAM) is undecided; the default
  elaboration contains NOP fill only, i.e. no boot image.
- No independent reviewer (G4.4 open).

---

## R-08 — F6: toolchain discovery unification (self-review)

- **Local / UTC:** 2026-11-18 20:54 IST (2026-11-18T15:24Z)
- **Reviewer:** self (same agent) — **not independent**
- **Run:** `research/runs/RUN-0010-toolchain-unification/`

**Verdict: PASS.** The question F6 poses — do the drivers pick the same
compiler? — is now answered by construction: one resolver, validated, and every
entry point either calls it or delegates to a driver that does.

**What changed the answer:** validation. Previously "found" meant the binary
existed; now it means `-dumpmachine` reports a RISC-V target, `--version` runs,
`-march=rv32im -mabi=ilp32` is accepted, and `objcopy` works. That closes the
gap where a stale or wrong compiler could be used without complaint.

**Fail-closed behaviour, verified:** bogus `RISCV_GCC_PREFIX`,
non-existent `RISCV_TOOLCHAIN_BIN`, a prefix/bin pair that disagrees, and a
broken executable all exit 2 with the cause named. The gate's `tools` stage
blocks on the same condition, so no later stage can report PASS without a
compiler. Six driver-level controls confirm the failure path in `build_fw.js`,
`run_e2e.js` and `verify.js`, not only in the resolver unit.

**Consistency, measured:** Node build, Python build, E2E and both log
surfaces report the same absolute gcc path and the same version
(12.2.0-2). Regression is 27/27 on images rebuilt by that compiler, and the
regression log now states which compiler it was.

**Unresolved concerns:**
- Windows-only evidence. The POSIX install-root branch is code without a run.
- Only one real toolchain exists, so "two valid toolchains conflict" was not
  exercised; the conflict control uses a prefix absent from the installed bin
  directory.
- A genuine wrong-target binary could not be produced without a host compiler,
  so that rejection is unit-tested plus the broken-executable case.
- `build_fw.py` now depends on `node`; that dependency is deliberate (one
  algorithm) and fails loudly.
- No independent reviewer (G4.4 remains open).

---

## R-09 — F4/F9 evidence provenance audit (self-review)

- **Local / UTC:** 2026-11-18 21:50 IST (2026-11-18T16:20Z)
- **Reviewer:** self (same agent) — **not independent**
- **Run:** `research/runs/RUN-0011-evidence-provenance/`

**Verdict: F4 FIXED, F9 PARTIAL, G0 PASS.**

**What the audit actually found.** Three of the claims under review were not
merely stale, they were unsupported by any artifact in the tree: the Verilator
C++ boot (no executable), the arithmetic equivalence (source only in a gitignored
directory), and the gate result (its log directory held a negative-control run).
Two further claims were numerically wrong: "~20,000× real time" versus a measured
17 ms simulated per wall-second, and "226 cells" for the core versus 44,323. A
third class — historical reports — is legitimate history and has been marked as
such rather than rewritten.

**Why F9 is not PASS.** Every target the request names now has a current run with
command, tools, exit code and hashes, and the README no longer overstates. But
PPA cannot be produced here (no ABC `-liberty`, no PDK), the historical reports
still contain superseded numbers by design, and nobody independent has looked at
any of it. Those are not things this run can fix, so PARTIAL is the honest label.

**Why G0 can move.** G0 asks for a reproducible baseline with no missing inputs
and no unexplained stale artifacts. Both remaining G0 criteria are now met and
linked; G0.1–G0.3 were already met. Nothing in G1–G4 moved: G1.3 assumptions are
still unreviewed, G1.4/G1.5 still lack a sensor path and active-transaction
watchdog reset, G2 has one unproven mapping rule and no macro, G3/G4 are open.

**Failures preserved.** Regression without the OSS environment (0/27, exit 1) is
kept as an environment control; the pre-fix Verilator build failure (exit 1) is
reproduced deliberately from `git show HEAD:...bat`; the first gate logs being a
negative-control run are disclosed in the matrix rather than quietly replaced.

**Unresolved concerns:**
- `build/verify/` remains a mutable shared log directory — the single riskiest
  provenance weakness in the repository.
- No Icarus 7/7 full-SoC boot exists; the 7/7 is Verilator-specific.
- `verilator_bin` is used directly; the Perl wrapper is still broken.
- Area/timing/PPA, PDK, FPGA and silicon remain unmeasured.
- No independent reviewer (G4.4 open).

## R-2026-11-18-21 — Memory architecture investigation + README redesign (Day 2)

- **Date:** 2026-11-18 IST (2026-11-18T16:22Z onward)
- **Reviewer:** `Agent: Buffy (model: DeepSeek V4.1 Flash)` — self-review (no independent evaluator available; G4.4 OPEN)
- **Objectives reviewed:**
  1. Memory Architecture Decision Investigation (Objective 1): F5 confirmed (ROM 4×, SRAM 2× aperture mismatch, surplus unreachable — area/macro-sizing defect, not functional). F7 PARTIAL (4 inferred memories, inventory complete, no macro/PDK). Recommendation: Option B — expand address map/linker/requirements to match implemented arrays (64 KiB ROM, 256 KiB SRAM). No RTL modifications. Decision documented in `research/MEMORY_ARCHITECTURE_DECISION_INVESTIGATION.md`.
  2. Professional README Redesign (Objective 2): root README.md rewritten as polished GitHub project showcase. All 28+ sections present: professional title/description, project goals/research question, architecture overview (Mermaid + ASCII), major SoC components and features, toolchain/EDA environment (verified tool versions), verification/formal-testing capabilities (all 10+ verification domains with accurate numbers), research findings F1–F9 and current statuses, current gate status (G0 PASS, G1/G2 PARTIAL, G3/G4 OPEN), memory architecture findings, research methodology/reproducibility/evidence approach, known limitations/unresolved blockers, roadmap/next research phases, repository structure, how to reproduce major verification runs, links to relevant reports/evidence. Clean markdown, concise technical writing, tables where useful, professional GitHub layout. Badges only for verifiable facts (no ASIC-readiness, no tapeout claims, no inflated completion percentages). All claims cross-checked against repository evidence.
- **Evidence cross-check:** Every technical claim and number in the redesigned README verified against repository sources: research/findings.csv, research/results.csv (on disk), research/experiment-matrix.csv, research/runs/RUN-0011-evidence-provenance/evidence-matrix.md (committed), acceptance-gates.md (committed), AGENTS.md (committed), research/runs/RUN-0009-memory-audit/ (on disk), research/MEMORY_ARCHITECTURE_DECISION_INVESTIGATION.md (new). No claim was found unsupported by evidence. All matches.
- **Constraints verified:** No RTL modifications. No install, commit, or push. All existing work and untracked evidence preserved. Measured results distinguished from estimates. No independent validation claimed where only self-review exists. Factual, polished, suitable for public engineering portfolio.
- **Acceptance criteria check:** README looks like professional open-source engineering project page ✓. Technical claims and numbers verified ✓. Memory decision evidence-based and documented ✓. No functional RTL changes ✓. Existing artifacts remain intact ✓. Research status and limitations remain honest ✓. Final report lists changed files, findings, validation results, and blockers ✓.
- **Verdict:** Both objectives complete and accepted. No further action required absent external evaluator or PDK provisioning.

**Note:** This is a self-review (the environment has no independent evaluator). G4.4 remains OPEN. All results are self-evaluated.
