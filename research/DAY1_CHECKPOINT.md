# Day 1 checkpoint — 2026-11-18 (UTC 12:17 → 12:40)

Deadline remains `2026-11-28T12:17:36Z`. This is a progress checkpoint, not the
final deliverable.

## What is verified now

| Claim | Evidence | Status |
|---|---|---|
| Baseline at `025ef24` reproduces | RUN-0001: regression 27/27 exit 0 (256 s), gate 9/9 exit 0 (294 s), no env overrides | PASS |
| I²C STOP was an invalid bus condition | RUN-0002: strengthened assertion vs unmodified RTL → 5 failures, exit 1, `stops=0` on all three transactions | CONFIRMED |
| I²C STOP is fixed | RUN-0003: same assertion → `stops=1`, exit 0; RUN-0004: regression 27/27 + gate 9/9 exit 0 | PASS |
| Tool inventory | RUN-0001 `logs/tools.txt` (Icarus 14.0, Yosys 0.69+154, SBY 0.69, Verilator 5.053 bin, Verible v0.0-4298, xPack GCC 12.2.0, Node 26.7.0, Python 3.10.11, git 2.54.0) | PASS |

## Findings triage (nine items from the external review)

- **Fixed today:** F1 (I²C STOP).
- **Confirmed, not yet fixed:** F2 (`$pmux` single-select vector→scalar at
  `sky130_map.v:380-386`), F4 (`build/asic_evidence/arith_test.v` is untracked),
  F6 (`run_e2e.js` hardcodes its toolchain; `build_fw.py` keeps its own).
- **Open, blocked on a reference or an inventory:** F3 (`dfrbp` clock edge — the
  in-tree subset library omits its `ff` block), F5 (declared ROM/TCM/SRAM sizes
  versus implemented capacity), F7 (no memory inventory for the three `$mem_v2`),
  F8 (no fail-closed promotion of full-SoC structural problems).
- **Partially addressed:** F9 (regression and gate now carry commit-matched raw
  evidence; Verilator 7/7, formal 6/6 and PPA claims still unverified at this
  commit).

## Gate status

G0 **PARTIAL** (G0.4, G0.5 open) · G1 **PARTIAL** (G1.7 now passes; no sensor
path, formal assumptions unreviewed, watchdog reset during an active transaction
untested) · G2 **PARTIAL** · G3 **OPEN** · G4 **OPEN** (no independent
evaluator).

## Next actions (in order)

1. F2: make the `$pmux` single-select branch per-bit and add a `WIDTH > 1`
   self-check (mapper defect; cheap, self-verifying).
2. F8: fail closed when a full-SoC structural check reports problems.
3. F5/F7: produce the memory inventory (three `$mem_v2`) and reconcile against
   `has_addr_map.sv` sizes; record the strategy as unresolved if no macro.
4. F6: route `run_e2e.js` and `build_fw.py` through the shared discovery or mark
   them unsupported explicitly.
5. F4: publish or regenerate the arithmetic demonstration from a tracked source.
6. Re-run the Verilator full-SoC boot through `verilator_bin.exe` (the Perl
   wrapper is broken) so that claim becomes verified at the current commit.

## Honest classification

`PARTIAL — HIGHEST VERIFIED GATE: none fully satisfied`. G1 is closest but has
open criteria. Everything here is SELF-EVALUATED; no independent reviewer exists
in this environment, so G4 cannot be claimed regardless of local results.

## Progress after the checkpoint — $pmux (F2)

F2 is fixed and regression-covered; it is no longer an open item.

- Test: `scripts/eda/run_pmux_map_test.js` with probes in
  `asic/synthesis/techmap/pmux_probe.il` (`$pmux` written in RTLIL, so inference
  cannot rewrite it into `$mux` before techmap sees it).
- Negative control (RUN-0005, mapper from `git show HEAD`): 1 `mux2_1` instead
  of 8, 130048 of 393608 vectors mismatched, exit 1. Yosys `check` reported
  **0 problems** on the same netlist, so a structural check could never have
  caught it.
- Fix (RUN-0006): one per-bit chain for every `S_WIDTH`; 8/24/1 cells, 0
  mismatches, 9 `$equiv` cells proven against `pmuxtree`, and the `arith_test`
  netlist is byte-identical before and after the fix (0 check problems).
- Not covered by this test: every other map rule, library timing/load, and
  `S_WIDTH > 1` behaviour for overlapping selects (outside the one-hot `$pmux`
  contract; covered by exhaustive one-hot simulation only).

Gate impact: G2.3 remains PARTIAL — the `$pmux` rule is now proven, the rest of
the map is still unproven and F3 is still open.

## Progress — structural validation fails closed (F8)

- Measured defect: the full-SoC flow ended in a bare `check`; on a design with
  undriven outputs it printed `Found and reported 2 problems` and exited **0**.
- Enforced now: `check -assert` in `asic/synthesis/fullsoc_map.ys`, a library
  cell allowlist, exact declared-gap accounting and a non-empty-mapping rule in
  `scripts/eda/check_structure.js` (exit 0 PASS / 1 FAIL / 2 BLOCKED), plus a
  `structural-check` stage in `scripts/verify.js` that runs the 7 controls.
- Evidence: RUN-0007 — legacy control exits 0 with 2 problems, all five injected
  defects exit 1, the clean baseline exits 0, and the real SoC exits **2**
  (BLOCKED) on 4 inferred `$mem_v2`. Unified gate: 10 passed, 0 failed, 0 blocked.
- Still open: memories are declared, not implemented (F7/TD-006, 4 cells — the
  earlier "3" undercounted); counts are per module definition because the SoC
  cannot be flattened; the inventory is hand-maintained, not derived from the
  address map (F5).
