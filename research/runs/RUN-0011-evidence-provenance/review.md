# Review — RUN-0011 (F4/F9 evidence provenance)

**Reviewer:** self (same agent) — **not independent**. G4.4 remains open.

## Verdict

**F4: FIXED. F9: PARTIAL.** The provenance question is answered for every target
the request named: each current number now has one source state, one command, one
exit code, one tool set and one hashed artifact behind it. It is not a full PASS
because the repository still contains historical reports with superseded numbers
(now marked), because PPA cannot be produced without ABC `-liberty` and a PDK,
and because no independent party has checked any of it.

## What changed the answer

- The arithmetic equivalence claim was **re-derivable from a publishable path**:
  the same 1,028 checks pass from `asic/synthesis/provenance/`, and a corrupted
  netlist fails. Before this run the source existed only in a gitignored tree.
- The Verilator boot claim went from **unverifiable to reproduced**: no executable
  existed; the build was broken by a path-substitution bug; after the fix the
  model builds and the 7/7 boot passes. Its reported speed is ~17 ms simulated
  per wall-second, not 20,000× real time — the old figure is off by ~6 orders of
  magnitude and has been corrected in README.
- The gate's tool inventory now sees `verilator_bin`, so "Verilator not
  installed" no longer contradicts a working Verilator.

## Failures found, not hidden

| Failure | Handling |
|---|---|
| Regression without the OSS environment: 0/27, exit 1 | Preserved as `logs/regression_no_oss_env.log`; it is an environment control, not a regression |
| Verilator build attempt 1: exit 1, `toolsverilator-shim` path | Reproduced deliberately with the pre-fix script (`logs/verilator_build_control.log`, exit 1) after the fix; the original attempt log was overwritten by the rerun — disclosed in the matrix rather than presented as a clean first try |
| `build/verify/*` contained a 20:51 negative-control run (bogus `RISCV_GCC_PREFIX`) | Detected during audit; clean gate run executed last so the directory matches the current PASS |
| First `rename -top` in the new Yosys script: `ERROR: Invalid number of arguments!` | Script corrected to `rename <old> <new>`; re-run exit 0 |

## Unresolved concerns

- `build/verify` is a single mutable log directory shared by real runs and
  negative controls. Any audit that reads it without a timestamp can be misled.
  A run-id-scoped log directory would fix it; that is tooling work not done here.
- Historical reports (`reports/verification/*`, `build/baseline/*`) still contain
  old numbers. They are preserved as history and marked with a banner; the
  evidence registry treatment of them is unchanged.
- Verilator lint exits 1 on `-Wall` warnings. It is honest to call that "0
  errors, 123 warnings", not "PASS".
- No Icarus full-SoC boot 7/7 was produced; the 7/7 figure belongs to the
  Verilator model. README now says so.
- PPA, timing, DRC/LVS, FPGA and silicon remain unmeasured or absent.
