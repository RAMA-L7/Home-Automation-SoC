# Self-review — RUN-0007 (F8, fail-closed structural validation)

Status: **SELF-EVALUATED** (no independent reviewer available).

## The defect, measured
The full-SoC flow ended in a bare `check`. On a design with undriven outputs it
printed `Found and reported 2 problems` and exited **0** (`logs/legacy-undriven.log`).
No exit status, no gate, nothing downstream looked at the count. That is the F8
gap: a structural problem could be observed and still pass.

## What now fails the run
1. `check -assert` in `asic/synthesis/fullsoc_map.ys` — undriven wires and
   outputs, multiple drivers, port problems abort with a nonzero exit.
2. Leaf-cell allowlist (`scripts/eda/check_structure.js`): every leaf cell must
   be a `sky130_fd_sc_hd__*` library cell, unless declared as a gap. Anything
   else is listed and exits 1.
3. Declared-gap accounting: the policy count must match the design exactly.
   A memory count that drifts makes the run fail rather than "declared, so fine".
4. Incomplete mapping: a design with no leaf cells cannot pass.
5. The unified gate runs the checker's 7-control matrix, so the gate itself
   fails if the checker ever stops rejecting a defect.

## Controls actually observed (all in logs/structural_self_test.log)
| control | expected | observed |
|---|---|---|
| legacy flow, undriven output | exit 0 (the bug) | exit 0, 2 problems |
| undriven output, enforced | exit 1 | exit 1 |
| multiple drivers | exit 1 | exit 1 |
| undeclared inferred memory | exit 1 | exit 1 |
| declared inventory mismatch | exit 1 | exit 1 |
| cell the map does not handle | exit 1 | exit 1 |
| fully mapped clean design | exit 0 | exit 0 |

## Real target
`has_soc`: 261999 leaf cells of 8 types, 0 `check` problems, **BLOCKED (exit 2)**
because 4 `$mem_v2` cells remain. Reported, never passed.

## Remaining gaps (not fixed here)
- The memories are declared, not implemented. 4 inferred `$mem_v2` cells
  (1 in `has_soc`, 1 `boot_rom`, 2 distinct `sram` parameterizations) still have
  no macro; F7/TD-006 stays open. The earlier "3 memories" note undercounted.
- Counts are per module definition, because the SoC is not flattened
  (`flatten` dies with `std::bad_alloc` on the behavioural SRAM). Every module
  in `has_soc` is instantiated exactly once today; if that changes, the
  declared counts become ambiguous and the check would need instance-aware
  accounting.
- The declared inventory is a hand-maintained policy value. It is not derived
  from `has_addr_map.sv`, so F5 (declared sizes vs implemented capacity) is
  still unverified.
- Structural only: no equivalence, timing, power, DRC, LVS, DFT or pad-ring
  property is covered.
- The gate runs the fast control matrix, not the 194 s full-SoC mapping. The
  SoC verdict is reproduced by an explicit command; it is not part of every
  gate run, so a regression that only appears in the SoC needs that command.
