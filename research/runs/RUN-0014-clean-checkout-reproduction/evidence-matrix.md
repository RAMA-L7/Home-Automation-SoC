# RUN-0014 — clean-checkout reproduction → evidence

Tested revision: `eff293d` in a **separate Git worktree** containing only tracked
files (`git status` empty, `git clean -xdff` before the run). Pre-fix revision
where the defects were re-created: `d09d59e`. All results are SELF-EVALUATED.

| # | Claim | Checked with | Evidence | What it does not establish |
|---|---|---|---|---|
| 1 | The supported commands reproduce from a clean checkout, not just the author's working directory | `node scripts/closure.js` in a fresh worktree | `logs/closure_stdout.log` — publication COMPLETE, 13/13 functional, 2 design BLOCKED, exit 2 | That a different machine or a different OS reproduces it; only this host and this clean tree |
| 2 | The two clean-checkout defects were real | the three commands at `d09d59e` with no `build/fw` and no audit output | `logs/defects_at_d09d59e.log` — `ENOENT ... build/fw/boot.hex`, `ERROR: Can't create file build/asic_evidence/memory_audit/memory_cells.json`, `MEMORY_AUDIT: BLOCKED` | — |
| 3 | The same commands now succeed | same three commands at `eff293d`, output directories removed first | `logs/same_commands_at_eff293d.log` — assembler exit 0, audit BLOCKED as declared, self-test 7/7 | — |
| 4 | Firmware images are rebuilt from source, so a stale image cannot fake a pass | `run_regression.js` image provenance step | `logs/regression.log` — `PASS 27 / 27`, every image rebuilt and hashed in the log | That the images are correct for silicon; they are simulation images |
| 5 | ASIC readiness stays BLOCKED in a clean checkout too | gate summary | `logs/closure_verify.log` | When it clears — that needs a memory macro |

## What this run changed

`F11` (new, FIXED): `scripts/fw/as.js` and `asic/synthesis/memory_audit.ys`
wrote into `build/` subdirectories that nothing created. The assembler now
creates its output directory; `audit_memory.js --elaborate` creates the audit
directory, runs the elaboration and then the checker, and elaborates the
self-test baseline on demand.

## Preservation note

The raw logs of the *first* failing worktree were lost when that worktree was
removed, before they had been archived. The defects were therefore reproduced
deterministically at `d09d59e` and that reproduction is logged; it is a
re-creation of the failure, not the original capture, and row 2 says so.
