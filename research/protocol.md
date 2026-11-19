# Research protocol — Home-Automation-SoC capability study

**Agent identity:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`, running in the Freebuff agent framework.
**Repository:** https://github.com/RAMA-L7/Home-Automation-SoC
**Protocol written (UTC):** 2026-11-18T12:17:36Z
**Research start (UTC):** 2026-11-18T12:17:36Z
**Hard deadline (UTC):** 2026-11-28T12:17:36Z — ten consecutive calendar days.

The deadline limits execution time. It does not lower an acceptance criterion.
If the checklist is not satisfied, this study reports the highest verified gate,
the open blockers, and the findings — it does not convert partial work into a
readiness claim.

## 1. Research question

Under fixed requirements, tool access, and resource budgets, how far can an
open-model coding agent autonomously progress an existing SoC toward an
independently audited ASIC handoff?

## 2. What this study is and is not

- The owner does **not** intend to fabricate the chip during this study.
- Deliverables: (a) the strongest technically qualified design package
  achievable in the window, (b) preserved evidence of what the agent actually
  did, (c) a defensible evaluation of autonomy, correctness, limitations, cost.
- No silicon exists. No claim of silicon measurement, foundry approval, or
  manufacturing signoff may appear anywhere in this tree.

## 3. Baseline that this study starts from

- Reviewed revision: `025ef24f2f4444cac4c38dc62b659fac724770f4`
  (`test: gate I2C transactions and auto-discover the RISC-V toolchain`),
  branch `main`, in sync with `origin/main`, 38 untracked files preserved
  (see `runs/RUN-0001-baseline-025ef24/`).
- The previous external review examined that same commit. It is **historical
  context, not an assumption about current HEAD**; every item it raised is
  re-checked against the working tree before being called open or fixed
  (`findings.csv`).
- Pre-existing untracked material (`experiments/`, `reports/ASIC_PHASE*.md`,
  `reports/evidence/`, `reports/verification/VERIFICATION_BASELINE_2826b5b.md`,
  `sky130_comb.lib`, `sim/sim_top/*.vvp`) belongs to earlier sessions and is
  preserved and distinguished from this study's output. This study's own
  artifacts live under `research/`.

## 4. Autonomy and attribution classification

| Category | Classification for this project |
|---|---|
| Agent-authored implementation | RTL fixes, testbenches, harnesses and docs authored by agents in earlier sessions, including Buffy and OpenCode (see `AGENTS.md` change log) |
| Autonomous engineering decisions | Decisions taken without a specific human instruction, recorded per commit message and session log |
| Human-directed work | The objective statements and the master instruction reproduced in this protocol |
| Reviewer-assisted repairs | **The current continuation is classified review-assisted**: an external review raised the defect list in section 4 of the master instruction, and this agent is acting on it. Fixes are therefore not attributable to unaided autonomy |
| Reused third-party IP | sky130 standard cells and library (`sky130_fd_sc_hd`), xPack GCC, OSS CAD Suite, Verible, OpenLane 2, Magic, Netgen, KiCad — all third-party, none authored here |
| EDA-tool automation | Scripts under `scripts/`, `asic/`, `fpga/`; their output is tool-reported, not silicon |
| Independent evaluation | **Not available.** All checks in this study are SELF-EVALUATED |

Original prompts and transcripts from earlier sessions are **not available** in
this tree. That limitation is recorded rather than reconstructed; no fictional
history is written. Every new human hint, decision, manual edit, external
review, scope change and environment repair is logged in `interventions.csv`.

## 5. Evidence rules

- Every quantitative claim in this tree links to a run directory
  `research/runs/<run-id>/` containing the command, exit status, raw log and
  artifact hashes.
- A compile failure, timeout, missing binary, stale artifact, empty log or
  simulator crash is **not** a successful functional test. Infrastructure
  failures are recorded as infrastructure, not as design failures.
- A failed run is never overwritten by a successful rerun. Superseded records
  keep their directory and are linked from the new record's `review.md`.
- Tests are never weakened to make an implementation pass. A test that cannot
  fail is a defect in the test.
- "Planned", "implemented", "tool-tested", "independently evaluated" and
  "externally approved" are separate states and are never conflated.
- Run metadata records the source SHA and whether the worktree was dirty. A
  mutable worktree is not described as corresponding to a clean commit.

## 6. Scope and boundary

- Implementation boundary: **full chip** (QFN-64, sky130, RV32IM SoC as it
  exists in `rtl/`). It is not silently reduced to a hard macro or a peripheral
  subset. Any reduced configuration must be named, justified and versioned.
- Frequency, features, reset behaviour and verification depth may not be
  relaxed to obtain a passing result.
- Where a manufacturing requirement is unavailable (PDK provisioning, foundry
  collateral, commercial signoff tools), it is marked unresolved and the study
  evaluates against a clearly labelled research checklist instead.

## 7. Working rules

- One implementation owner (this agent). Repository instructions in `AGENTS.md`
  are respected; pre-existing changes are preserved.
- No fabrication, no hardware ordering, no spending, no pushing of proprietary
  collateral, no manufacturing submission. Publication to `origin/main` was
  authorized for the I²C/toolchain change (commit `025ef24`); **no further push
  is authorized by this instruction**, so results stay reviewable and local
  unless the owner says otherwise.
- No licence changes to this repository or to third-party material.

## 8. Measurement discipline

Primary metrics are correctness outcomes, mutation detection, false-success
claims rejected, defects introduced/regressed, intervention counts, wall and
EDA runtime, token/cost where available, reproducibility, and tool-reported PPA
under frozen conditions. Lines of code, document counts and test counts are
never primary success metrics. Estimated, tool-reported and measured-silicon
numbers are labelled separately.
