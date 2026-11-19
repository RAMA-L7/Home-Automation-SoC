# Self-review — RUN-0006 ($pmux fix verification)

Status: **SELF-EVALUATED** (no independent reviewer available).

## Change under test
`build/asic_evidence/sky130_map.v`: the `$pmux` rule no longer special-cases
`S_WIDTH == 1`. One scalar `mux2_1` per bit is instantiated for every
`S_WIDTH`; for `S_WIDTH == 1` the chain degenerates to the single mux per bit
that was intended. Net effect for `WIDTH = 8, S_WIDTH = 1`: 8 cells instead of
1, and no undriven result bits.

## Evidence
- Structure: 8 / 24 / 1 `mux2_1` instances for the three probes.
- Simulation: 393608 vectors, 0 mismatches. Coverage is exhaustive for
  `S_WIDTH = 1` (every A, B, S) and every one-hot select with all 256 A and B
  values for `S_WIDTH = 3`.
- Equivalence: Yosys proves 9 `$equiv` cells across the two single-select
  probes against `pmuxtree`'s own rewriting of the same `$pmux` cells.
- Real design: `arith_test` mapped with the same map gives an identical
  netlist before and after the fix, 0 check problems, 20 `mux2_1` cells.

## What this does NOT prove
- It is not a general proof that the whole mapper is correct, or that any other
  cell rule is right. Only the `$pmux` rule is covered.
- Equivalence uses a behavioural `mux2_1` model whose function matches the
  library (`(A0&!S)|(A1&S)`); it is not a timing-, load- or glitch-aware proof.
- `S_WIDTH = 3` is not asserted equivalent: for overlapping selects the mapper
  chain and `pmuxtree` choose different priorities, which the one-hot `$pmux`
  contract leaves unspecified. Its one-hot behaviour is covered by simulation
  only.
- No DRC/LVS/P&R consequence is examined here.
