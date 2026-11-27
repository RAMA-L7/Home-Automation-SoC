# External review intervention — 2026-11-27

**Type:** external intervention (not a project phase)
**Reviewed HEAD:** `aa80783217016ffdd108172bdfa4e43d58a52b2a`
**Inspected at:** `04c30844` (one commit past the reviewed SHA)
**Fix commit:** `b5e0642`
**Evidence:** `research/runs/RUN-0026-external-review-2026-11-27/`
**Standing:** authoritative for the state after these fixes. It does not rewrite
any earlier report; those keep their own dated claims.

Deadline unchanged: **2026-11-28T12:17:36Z**. This intervention did not restart
the clock.

---

## 1. Finding-by-finding outcome

| # | Finding | Outcome |
|---|---|---|
| 1 | Split-channel AXI writes not implemented; slaves required AW and W in one cycle | **FIXED** in `sram.sv`, `sram_macro_wrap.sv`, `boot_rom.sv` (and the ROM generator template). New `tb_axi_split.v` fails 24/127 checks pre-fix and passes 127/127 post-fix; simultaneous read/write and byte-strobe coverage retained and extended |
| 2 | No production boot path; preloaded memories were being counted as initialisation | **FIXED for ROM boot** — `firmware/boot/loader.S` + `payload.S` + `gen_boot_image.js`; `tb_boot_loader.v` compiles **without** `-DSIM_MEM_PRELOAD`, proves TCM/SRAM are `x` at t=0, and boots twice (cold + watchdog recovery). Flash boot is **BLOCKED** and stated as such |
| 3 | Constraints did not match the RTL; TCK rate contradicted the documented ratio; exceptions unjustified; no real STA | **FIXED** — JTAG modelled as implemented (TAP on `sys_clk`, TCK sampled), virtual `jtag_tck` at the 200 ns ratio floor, CDC bounded by a 2 ns datapath max delay, both exceptions justified. OpenSTA 3.1.0 now runs: **WNS −106.4775 ns**, TNS −104736.49 ns (a real FAIL, not BLOCKED) |
| 4 | Memory/ROM not qualified; generated ROM not in the canonical flow | **PARTIALLY FIXED** — generated ROM is in a canonical mapping flow (`fullsoc_map_rom.ys`) and structurally checked (`$mem_v2` 4 → 3, ROM = 262,262 cells). ROM **remains BLOCKED** as an ASIC memory: it is a mux tree, not an array |
| 5 | Publication and documentation incomplete / not reconciled | **PARTIALLY FIXED** — new reports, RUN-0026 evidence, README/handoff/findings/gate tables reconciled. Remaining gaps listed in §4 |
| 6 | No clean-checkout verification | **FIXED** — full regression from a detached worktree at `b5e0642` containing only tracked files (log in RUN-0026) |

Three things this intervention found that document review had not:

* **F17 — the AXI wiring defect was masked by the interconnect.** Every slave
  looked correct because `axi_lite_interconnect` holds both channels and
  presents them together. The slaves were not AXI-compliant on their own
  boundary, so any second master (debug bridge, DMA, third-party IP) would have
  hit it immediately.
* **F18 — the SDC described a JTAG block that does not exist.** It timed
  `sys_clk` registers against a `jtag_tck` port clock. That is worse than no
  constraint: it makes the interface look checked while nothing on the interface
  was being checked, and it advertised 10 MHz against a documented 5 MHz ceiling.
* **F19 — "path-based STA BLOCKED" was itself stale.** The machine has run
  WSL2 for some time and OpenSTA 3.1.0 executes. A BLOCKED claim was shielding
  the design from a −106 ns result that was measured months earlier in this same
  tree.

## 2. Verification performed at `b5e0642`

| Target | Command | Result |
|---|---|---|
| AXI split channels (post-fix) | `vvp build/sim/tb_axi_split.vvp` | **PASS** 127/127 |
| AXI split channels (pre-fix RTL, same bench) | same bench against `HEAD~1` sources | **FAIL** 24/127 — preserved in `logs/axi_split_prefix_failure.log` |
| Production boot, no preload | `vvp build/sim/tb_boot_loader.vvp` | **PASS** 11/11, two boots + watchdog reset |
| ROM behavioural vs generated | `node scripts/eda/run_rom_check.js` | **PASS** 1059 + 1059 checks, 0 errors |
| SDC validity / coverage | `node scripts/eda/run_sdc_lint.js` | **PASS** 49/49 ports (constraint file only) |
| Path-based timing | `node scripts/eda/run_sta.js` | **FAIL** WNS −106.4775 ns — the measured result |
| ROM expansion to cells | `yosys -s asic/synthesis/rom_map.ys` | 262,262 cells, 21 s |
| Full SoC with generated ROM | `yosys -s asic/synthesis/fullsoc_map_rom.ys` + `check_structure.js` | **BLOCKED** — 274,757 cells, 3 `$mem_v2`, 80 macro blackboxes |
| Full regression, clean worktree | `node scripts/eda/run_regression.js` at `b5e0642` | **PASS 30/30**, exit 0, 1,010 s — `logs/clean_worktree_regression.log` in RUN-0026 |

## 3. Highest honestly verified stage

**RTL functionally verified in simulation, with a verified preload-free boot
path, a synthesizable (non-array) ROM, constraints that match the RTL, and a
measured failing timing result. ASIC readiness, physical implementation and
signoff remain BLOCKED.**

Specifically:

* Simulation and boot: verified, including the case that matters (memories
  unknown at power-on).
* Constraints: validated as a file *and* exercised by a real STA engine.
* Timing: **does not meet 20 ns** — WNS −106.48 ns. No exception was added to
  hide it.
* Synthesis: ROM maps; memories remain blackboxes; structural verdict BLOCKED.
* Physical: nothing. No P&R, no DRC/LVS, no power, no GDS.

No tapeout-readiness claim is made, and none of the above supports one.

## 4. What remains BLOCKED or open

| Item | State | Reason |
|---|---|---|
| Boot from external QSPI flash | BLOCKED | `qspi_flash_ctrl` has a read engine only; program/erase return SLVERR, so no image can be placed in flash |
| 50 MHz timing | FAIL (not blocked) | WNS −106.48 ns from fanout/logic depth; needs a design change, not a constraint |
| Real-macro simulation | BLOCKED | vendor Verilog models do not elaborate in Icarus 14 |
| ASIC ROM (array) | BLOCKED | no compiler, no characterisation; the mux tree is not an array |
| Physical implementation / signoff | BLOCKED | no routed netlist, no extracted parasitics, no PDN, no DRC/LVS |
| Independent evaluation | OPEN | self-evaluated; no independent evaluator exists in this environment |
| Historical evidence predating `b5e0642` | LABELLED | earlier run directories keep their own commits; do not quote them as current |

## 5. Publication notes

* Only project-authored sources and generated evidence are published. No PDK
  Liberty/LEF/GDS, no vendor macro models, no tool binaries.
* External dependencies (xPack GCC 12.2.0-2, Icarus 14.0, Yosys 0.69+154,
  OpenSTA 3.1.0, Node 26.7.0, Python 3.10.11, Tcl 8.6, volare sky130 pin
  `0fe599b2afb6708d281543108caf8310912f54af`) are recorded with versions and
  hashes in `docs/EXTERNAL_DEPENDENCIES.md`.
* The tested commit is `b5e0642`; the evidence commit that publishes RUN-0026
  comes after it and changes no source.
