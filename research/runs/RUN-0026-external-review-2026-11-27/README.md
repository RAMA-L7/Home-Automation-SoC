# RUN-0026 — second external review intervention (2026-11-27)

**Type:** external intervention (not a project phase)
**Reviewed HEAD:** `aa80783217016ffdd108172bdfa4e43d58a52b2a`
**Inspected at:** `04c308440cb8495c58b0ec5aa868baec999349a5`
**Tested commit:** `b5e0642ea1cf67b1f6fe263a75499b8b94df2384`
**Report:** `reports/REVIEW_INTERVENTION_2026-11-27.md`
**Deadline (unchanged):** `2026-11-28T12:17:36Z`

---

## What this run establishes

| Claim | Where |
|---|---|
| The three AXI4-Lite write slaves now capture AW and W independently, and the old RTL fails the same bench | `logs/axi_split_prefix_failure.log` (24/127 fail) vs `logs/axi_split_postfix.log` (127/127 pass) |
| The SoC boots with no testbench preload: TCM/SRAM are `x` at t=0 and the loader fills them | `logs/boot_loader.log` |
| The generated ROM still matches the behavioural one and still boots the CPU | `logs/rom_check.log` |
| The SDC is valid Tcl, covers every port, and models JTAG as implemented | `logs/sdc_lint.log` |
| Real STA runs and reports the measured violation | `logs/sta.log`, `logs/sta_summary.log` |
| The generated ROM is in the canonical mapping flow, and what remains unmapped | `logs/fullsoc_rom_map.log`, `artifacts/has_soc_rom_cells.json` |
| The ROM's own cell cost | `logs/rom_map.log`, `artifacts/boot_rom_cells.json` |
| A clean worktree of the tested commit reproduces the suite | `logs/clean_worktree_regression.log` |

## Negative controls preserved

1. **Pre-fix AXI RTL** (`git show HEAD~1:` sources, byte-for-byte) against the
   new bench: 24 failures, `AXI SPLIT: FAIL (24 errors)`. Sources kept in
   `artifacts/prefix_rtl/`.
2. **Preload removed** rather than added: `tb_boot_loader.v` is the *absence* of
   `-DSIM_MEM_PRELOAD`, and it asserts the memories are `x` at t=0. Putting the
   define back would make three checks fail.
3. **SDC validator controls** reject a file with an unknown object, an uncovered
   port, and a malformed exception (see `scripts/eda/run_sdc_lint.js --self-test`).

## Honest reading

* Timing **fails**. `logs/sta_summary.log` ends `STA-RESULT=FAIL`. No exception
  was added to hide it; the design needs a fanout/logic-depth change.
* Structural is **BLOCKED** with exact counts, not PASS.
* The ROM is **not** an ASIC ROM; it is a 262,262-cell mux tree. See
  `reports/ROM_QUALIFICATION.md`.
* Boot from QSPI flash is **BLOCKED** — the controller has no program/erase.

## Layout

```
README.md                     this file
manifest.json                 pinned commit, dirty state, tool versions, per-file SHA-256
commands.jsonl               exact command, exit status and argv for each artifact
logs/                        raw stdout/stderr, unedited
artifacts/                   JSON produced by the structural checker and the build
```
