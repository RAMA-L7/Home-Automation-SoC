# RUN-0025 — External review intervention

**Source commit tested:** `3a71175`
**Baseline reviewed:** `8acc1a4`
**Date:** 2026-11-26
**Type:** external intervention — repository repair, not a project phase
**Report:** `reports/REVIEW_INTERVENTION_2026-11-26.md`

This run exists to make the review fixes auditable: every command below was
executed against a **detached `git worktree` at `3a71175`** (`build/clean-check`),
i.e. against tracked files only, with no build output carried over.

## What is in `logs/`

| File | Produced by | Meaning |
|---|---|---|
| `clean_worktree_regression.log` | `node scripts/eda/run_regression.js` | full regression from the clean worktree |
| `macro_wrapper_PROD.log` | `node scripts/eda/run_macro_wrapper.js` | 81 checks, production geometry (64-bank SRAM, 16-bank TCM) |
| `macro_wrapper_NEG_BANK.log` | same | negative control: bank decode broken — **must** fail |
| `macro_wrapper_NEG_STROBE.log` | same | negative control: strobes ignored — **must** fail |
| `macro_wrapper_summary.log` | same | pass/reject verdict per stage and exit status |
| `rom_behavioural.log`, `rom_generated.log` | `node scripts/eda/run_rom_check.js` | 1059 checks each, behavioural vs synthesizable ROM |
| `rom_boot_from_generated.log` | same | CPU boots 7/7 from the generated ROM |
| `rom_map.log` | same (`yosys`) | mapping report — no `$mem` cell remains |
| `rom_check_summary.log` | same | verdict + exit status |
| `sdc_lint.log` | `node scripts/eda/run_sdc_lint.js` | SDC executed under `tclsh`, port coverage |
| `sdc_negative_control.log` | same | validator rejects an unknown port and HDL-style `foreach` |

`manifest.json` pins the tested commit, the dirty state, tool versions, the exact
command lines and a SHA-256 of every file in this directory. Regenerate it with
`python3 scripts/evidence/make_manifest.py --run <this dir> --source-commit <sha>`.

## What this run does NOT establish

* ~~No timing number: path-based STA is **BLOCKED** (no runnable OpenSTA).~~
  **CORRECTED 2026-11-27 (F19):** this was wrong — the machine runs WSL2 and
  OpenSTA 3.1.0 executes. STA was run at `b5e0642` and **fails** (WNS
  −106.4775 ns). See RUN-0026 and `reports/TIMING_AND_CDC_QUALIFICATION.md`.
  This run directory is otherwise immutable and is not updated.
* No real-macro result: the memory cell is the simulation proxy model in
  `sim/models/sky130_sram_sim_model.v`. The vendor Verilog models do not
  elaborate in Icarus 14 (`mem[addr_reg]` non-constant index).
* No physical implementation, no signoff, no tapeout claim.
* The synthesizable ROM maps to a mux tree (~33 k cells); that is a correctness
  demonstration, not an area-optimal ROM.
