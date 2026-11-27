# External review intervention — 2026-11-26

**Type:** external intervention (not a project-phase milestone)
**Reviewed baseline:** `8acc1a4cf0d0139f33fea3ed3eb5edb63bf2767c`
**Fix commit:** `3a71175` (plus the evidence commit that publishes this report)
**Standing:** this record is authoritative for the state *after* the fixes. It
does not rewrite any earlier report; those keep their own dated claims.

---

## 1. What the review found, and what happened to it

| # | Finding | Outcome |
|---|---|---|
| 1 | Published implementation incomplete: `has_soc.sv` instantiates `sram_macro_wrap`/`tcm_macro_wrap`, which were untracked; `has_addr_map.vh` was on no include path; testbenches still connected the removed `ext_irq` port | **FIXED** — wrappers, simulation model, blackbox declarations and include paths are tracked; every entry point updated |
| 2 | Macro-wrapper verification was too weak: N=2 toy geometry, 5 of 16 strobes, no boundary/alias coverage, `check(1, ...)`, proxy-only | **FIXED** — rewritten at production geometry with 81 checks and 2 negative controls |
| 3 | ROM was a behavioural blackbox claimed as a memory solution | **PARTIALLY FIXED** — a synthesizable case-based ROM now exists and is verified, but the mapped result is a mux tree, so ASIC ROM readiness stays **BLOCKED** |
| 4 | SDC was not valid Tcl, had no units, and blanketed every I/O path | **FIXED (file)** — rewritten and validated by executing it; path-based STA stays **BLOCKED** |
| 5 | No clean-checkout reproduction | **FIXED for simulation** — re-run from a fresh worktree containing only tracked files |
| 6 | Evidence and documentation not reconciled | **DONE** — this report + RUN-0025 evidence + README/handoff/findings updates |

Three **functional defects** were found while making the tree elaborate from a
clean checkout. They are the most important result of this intervention because
they were not visible from document review alone:

* **F12 — peripheral interrupts were dead.** BLK-019 removed the 32-bit
  `ext_irq` *port* from `has_soc` and, in the same edit, replaced the connection
  to `intc_axi.ext_irq` with an open `.ext_irq()`. That 8-bit `intc_axi` port is
  the PLIC's peripheral-interrupt bus; `periph_irq` was computed and consumed by
  nobody. Every UART/timer/GPIO/PWM interrupt was silently lost. `tb_boot`'s
  PLIC subtest (the timer interrupt) failed 6/7; after reconnecting
  `.ext_irq(periph_irq)` it passes 7/7.
* **F13 — TCM/SRAM preload silently dropped.** `TCM_INIT_FILE` /
  `SRAM_INIT_FILE` stayed on the `has_soc` port list but went nowhere: the
  macro wrappers have no init path and no preload hook. Simulation could no
  longer run code out of TCM. Restored as a documented simulation-only hook
  (`SIM_MEM_PRELOAD`); the silicon truth — real macros power up undefined — is
  now stated in the wrappers instead of being implied away.
* **F14 — read+write deadlock in the memory slave.** With
  `awvalid & wvalid & arvalid` all held, `awready = IDLE & ~arvalid` and
  `arready = IDLE & ~(awvalid & wvalid)` are both low, so neither channel could
  start. The comment claimed write priority; the expression did not implement
  it. Present in both `sram.sv` and the wrapper. Fixed to
  `awready = wready = IDLE & (~arvalid | (awvalid & wvalid))`. The SoC never hit
  it because the interconnect serialises transactions; a different master would.

---

## 2. Verification performed (commands and outcomes)

All commands run from the repository root. Simulation uses the Icarus/Verilator
that ships in `D:\tools\oss-cad-suite`; the macro cell itself is the
**proxy model** in `sim/models/sky130_sram_sim_model.v` (protocol-accurate, no
timing/power/area meaning).

| Target | Command | Result |
|---|---|---|
| Macro wrapper, production geometry | `node scripts/eda/run_macro_wrapper.js` | **PASS** — 81 checks, 0 errors (64-bank SRAM + 16-bank TCM) |
| Negative control: bank decode dropped | same runner, `NEG_BANK` | **rejected** — 3 failures (alias checks catch it) |
| Negative control: strobes ignored | same runner, `NEG_STROBE` | **rejected** — 30 failures |
| ROM contents/latency/write (behavioural) | `node scripts/eda/run_rom_check.js` | **PASS** — 1059 checks |
| ROM contents/latency/write (synthesizable) | same | **PASS** — 1059 checks, word-for-word identical |
| CPU boot from the synthesizable ROM | same | **PASS** — 7/7 subtests |
| ROM maps without a memory cell | same (`yosys` + `memory_map`) | **PASS** — 32,840 `$_MUX_` + gates, `select -assert-none t:$mem t:$mem_v2` holds |
| SDC validity + port coverage | `node scripts/eda/run_sdc_lint.js` | **PASS** — 49/49 ports constrained, 0 Tcl/object errors |
| Full regression, clean worktree | `node scripts/eda/run_regression.js` at `3a71175` | see the published log in `research/runs/RUN-0025-external-review-2026-11-26/` |

### Negative controls for the SDC validator

Appending a constraint on the deleted `ext_irq` port and an HDL-style
`foreach ... begin ... end` to a copy of the file produces
`SDC-ERROR: get_ports: "ext_irq" is not a port of has_soc` and
`invalid command name "15:0"`, and the script exits non-zero. The validator
therefore discriminates; it is not a no-op.

---

## 3. What is still BLOCKED, and on what

| Item | Blocker | Consequence |
|---|---|---|
| Path-based STA (slack, WNS) | ~~No runnable OpenSTA. The Linux binary cannot execute (WSL1 is unsupported on this machine)~~ **CORRECTED 2026-11-27 (F19): this was stale.** The machine runs WSL2 and OpenSTA 3.1.0 executes. | ~~The SDC is validated as a *file*~~ At this commit the SDC was still only validated as a file. STA was later run at `b5e0642` and **fails**: WNS −106.4775 ns (`reports/TIMING_AND_CDC_QUALIFICATION.md`). |
| Real-macro simulation | The vendor Verilog models do not elaborate in Icarus 14 (`mem[addr_reg]` non-constant index). | Wrapper results are **proxy-model** results, labelled as such everywhere. |
| TCM/SRAM silicon initialisation | Real SRAM macros have no init port. | Boot code must initialise TCM before use; preload exists only under `SIM_MEM_PRELOAD`. |
| ASIC ROM | A synthesizable ROM exists but maps to a ~33 k-cell mux tree. | ROM readiness is **BLOCKED** as an area/characterisation decision; see F7. |
| Physical implementation / signoff | No PDK provisioning in this environment, WSL mount absent, PDN naming mismatch (RUN-0021 PDN-217). | Full-SoC physical signoff has not been run; no tapeout claim. |

**No claim in this repository is now made from a result that cannot be
reproduced from tracked sources with the tools listed in
`docs/EXTERNAL_DEPENDENCIES.md`.**

---

## 4. Highest honestly verified stage

* **RTL + simulation: verified.** All 28 regression targets build from a clean
  worktree and the functional ones pass; the macro-wrapper design is verified at
  its production geometry with discriminating negative controls.
* **Synthesis (structural): partially verified.** The ROM maps without an
  inferred memory; the full SoC still reports `$mem_v2` for the TCM/SRAM macro
  boundary, which is by design and counted as BLOCKED, not PASS.
* **ASIC physical: NOT verified.** No P&R, no STA, no signoff.

So the highest verified stage is **"RTL functionally verified in simulation,
with a synthesizable ROM and validated constraints — ASIC readiness BLOCKED."**
