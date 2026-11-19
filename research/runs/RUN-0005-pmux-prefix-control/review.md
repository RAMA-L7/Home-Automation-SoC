# Self-review — RUN-0005 ($pmux negative control)

Status: **SELF-EVALUATED** (no independent reviewer available).

## What this run shows
With the test in place but the mapper exactly as committed (`git show HEAD:` of
`build/asic_evidence/sky130_map.v`), the probe `pmux_s1_w8` produces **one**
`sky130_fd_sc_hd__mux2_1` instead of eight, and the 8-bit payload on its scalar
pins is truncated: `B = 0x08` maps to `0x00`, `B = 0x09` to `0x01`. 130048 of
393608 simulated vectors mismatch, exit 1.

## Why `check` did not catch it
`check` reports **0 problems** on the broken netlist. Yosys accepts a wider
signal on a narrower port (it resizes), so there is no structural error to
report. This is the reason the finding needed a value-level test rather than a
structural assertion, and it is recorded so nobody later "fixes" this by adding
a `check` call that cannot fail.

## Limitations
- The runner receives `--map` pointing at the pre-fix mapper reconstructed from
  git; the byte-for-byte identity of that file with HEAD is by construction, not
  independently attested.
- Only the single-select probe fails. `pmux_s3_w8` and `pmux_s1_w1` pass here,
  which shows the test is targeted rather than universally failing.
