# ASIC Phase 3 — Exploratory OpenROAD Physical Design (Timer)

**Project:** Home-Automation-SoC (`D:\Home-Automation-SoC`)
**Phase:** 3 — first actual OpenROAD physical-design experiment
**Target block:** `timer` peripheral (`rtl/rtl_peripherals/timer.sv`, unmodified)
**Platform:** Sky130HD (pre-existing install under `D:\tools`)
**Date:** 2026-11-14
**Branch / HEAD:** `main` / `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`

**Status in one line:** OpenROAD executed for real. Floorplan → IO placement → tap cells → PDN →
global placement → detailed placement all **PASS** on a genuine Sky130HD-mapped timer netlist
(67 × `sky130_fd_sc_hd__dfrtp_1`, 0 generic cells). A DEF and an OpenDB database were written.
CTS and routing were **not** run because no SDC / clock period exists and inventing one is forbidden.

---

## 1. What was actually executed

| # | Run | Input | Outcome |
|---|-----|-------|---------|
| 1 | `01_generic_timer/run_generic_timer.tcl` | Generic-cell timer netlist (`$_AND_`, `$_OR_`, `$_DFFE_PN0P_`, …) | **BLOCKED at link** — no LEF master for generic cells (`ORD-2013`) |
| 2 | `03_mapped_timer/run_mapped_timer.tcl` | Sky130HD-mapped timer netlist (this phase's mapping) | **PASS** through detailed placement; DEF + ODB written |

Run 1 exists precisely so the difference between "generic netlist" and "technology-mapped netlist"
is recorded rather than glossed over.

---

## 2. Environment verification (Phase 1)

| Item | Value | Evidence |
|------|-------|----------|
| AGENTS.md | read | tool policy: all EDA under `D:\tools` |
| Git status | 8 modified tracked files + untracked reports, all **pre-existing** to this session | `git status --short` |
| Git mutations | **none made** | no commit/stage/checkout run |
| Production RTL changes | **none** (`timer.sv` byte-identical to HEAD) | — |
| PDK / Liberty changes | **none** (platform read-only) | — |
| OpenROAD | `bazel-nostamp`, WSL Ubuntu-24.04, `/mnt/d/tools/openroad/bin/openroad` | `openroad -version` |
| OpenROAD features | `-GPU -GUI`, `ord::thread_count = 8` | `ord::openroad_gui_compiled` = 0 |
| Tool installs | **none performed** | — |

### 2.1 Platform paths (the only Sky130HD platform present on this host)

```
/mnt/d/tools/src/OpenROAD/test/sky130hd/
    sky130hd.tlef                              tech LEF   (13 layers, 25 vias)
    sky130_fd_sc_hd_merged.lef                 cell LEF   (437 cells)
    sky130_fd_sc_hd__tt_025C_1v80.lib          Liberty    (TT, 0.25 C, 1.80 V)
    sky130hd.tracks                            make_tracks definitions
    sky130hd.pdn.tcl                           PDN configuration
    sky130hd.rc / sky130hd.rcx_rules           RC extraction (not used)
```

`libs/` does not exist in the project and no volare-managed PDK is installed; the OpenROAD test
platform above is the only Sky130HD platform on the machine, and it is what was used.

Platform file hashes (SHA-256), unchanged before and after the runs:

```
92eb4e93a3d4c2563018ac81cdec2f02fdeaced9b39337ed5c141fa63e0ad8f8  sky130_fd_sc_hd__tt_025C_1v80.lib
c8351e320a3d89640a1aae4cc0991d41646553362007fb45f40d3882d3b1688f  sky130hd.tlef
41edf421b336e163cdfab97aca8d11e96f4563ceae857f0618d402aef063e980  sky130_fd_sc_hd_merged.lef
b4b280f0d5f3d52007e2531d2abd74d7f4aa600ceb9fffdf3041c781fe82ad8c  sky130hd.tracks
b195cd440b8ec849b54a5e40e2f82b1eb5209afed011b72b5e47300245ffbc67  sky130hd.pdn.tcl
```

---

## 3. Input selection (Phase 2)

### 3.1 What existed before this phase

`00_inventory_inputs.log` inventories every candidate. Summary:

| Candidate | Reality |
|-----------|---------|
| `phase2_1_timer_mapping/timer_generic.v`, `timer_g.v`, `timer_gate.v`, `timer_prepared.v` | **not netlists** — 5 behavioural `always` blocks, no cell instances |
| `phase2_4/timer_mapped_ignore_miss_func.v` (and `phase2_5` / `phase2_6` siblings) | timer module contains **0 Liberty cells** and **392 generic cells**: 126 `$_AND_`, 92 `$_OR_`, 63 `$_XOR_`, 35 `$_MUX_`, 9 `$_NOT_`, 67 `$_DFFE_PN0P_` |

So at the start of this phase the timer had **no** technology-mapped netlist — not even a
combinational one. The "mapped" file name was misleading; the 548 `sky130_fd_sc_hd__` strings in it
are dumped Liberty *module definitions* sitting in front of `module timer`, not instances.

### 3.2 Classification of the netlists used

- **Run 1 input** — `01_generic_timer/timer_generic_only.v` (extracted `module timer` only, 2360 lines):
  **GENERIC-NETLIST EXPERIMENT.** Yosys generic cells only. No standard-cell technology mapping.
  Not placeable, and it was not claimed to be.
- **Run 2 input** — `02_mapping_probe/timer_sky130.v`:
  **Sky130HD technology-mapped.** Produced in this phase with the standard Yosys flow against the
  platform Liberty (see §4). This is a real cell-level mapping, and only this netlist was placed.

---

## 4. The mapping that made Run 2 possible (and the correction it implies)

```
read_verilog -sv rtl/rtl_peripherals/timer.sv
synth -top timer -flatten
dfflibmap -liberty sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty      sky130_fd_sc_hd__tt_025C_1v80.lib
opt_clean
stat
write_verilog -noattr timer_sky130.v
```

Result (`02_mapping_probe/timer.log`, `timer_sky130.v`):

| Metric | Value |
|--------|-------|
| Total cells | **301** |
| `sky130_fd_sc_hd__dfrtp_1` | **67** |
| Remaining generic `$_*` cells | **0** |
| Behavioural `always` blocks | **0** |
| `RESET_B` connections | `presetn` on **67 / 67** |
| Enable implementation | **27 × `sky130_fd_sc_hd__mux2_1`** feedback (`A0 = Q`, `A1 = D`, `S = enable`) |
| Combinational cells | 234 (a22o, xnor2, nand2/3/4, nor2/3/4, xor2, o21ai, o22ai, o2bb2ai, …) |

The enable is therefore realised exactly as `D_next = enable ? D_input : Q_current`, with the
asynchronous reset untouched on `dfrtp_1.RESET_B` — the semantics Phases 2.5/2.6 were looking for.

**Measured contrast with Phases 2.5/2.6 (recorded, not asserted beyond the evidence):**

- Here the design flows RTL → RTLIL → technology cells **inside one Yosys session**, so Yosys knows
  the cell types and their semantics. `dfflibmap` (which internally runs `dfflegalize`) maps them:
  log line `mapped 67 $_DFF_PN0_ cells to \sky130_fd_sc_hd__dfrtp_1 cells`.
- Phases 2.5/2.6 operated on a netlist **re-read from a Verilog dump**. In that form the generic
  cells are undefined module names — OpenROAD reports exactly this in Run 1:
  `module $_DFFE_PN0P_ not found. Creating black box`. No pass can decompose a black box.

That is the operative difference and it is why the earlier "BLOCKED" verdict and this "PASS" are both
true statements about different inputs. The Phase 2.5/2.6 reports remain accurate for the netlists
they examined; they should not be read as "the timer cannot be mapped".

---

## 5. Run 1 — generic netlist (recorded failure)

Command:

```bash
wsl -d Ubuntu-24.04 -- bash -lc \
 'export PATH=/mnt/d/tools/openroad/bin:$PATH; \
  export LD_LIBRARY_PATH=/mnt/d/tools/opensta/lib:/usr/lib/wsl/lib; \
  cd /mnt/d/Home-Automation-SoC && \
  openroad -no_init -exit build/asic_flow/phase3_exploratory_pnr/01_generic_timer/run_generic_timer.tcl'
```

Exact results (`01_generic_timer/run_generic_timer.log`):

```
STAGE LOAD_LIBERTY : PASS
STAGE LOAD_TECHLEF : PASS      (13 layers, 25 vias)
STAGE LOAD_CELLLEF : PASS      (437 library cells)
STAGE READ_VERILOG : PASS      (5x WARNING STA-0198: module $_NOT_/$_XOR_/$_AND_/$_OR_/$_MUX_/$_DFFE_PN0P_ not found -> black box)
STAGE LINK_DESIGN  : FAIL : ORD-2013     -> "instance _235_ LEF master $_NOT_ not found."
STAGE FLOORPLAN    : FAIL : Error: no network has been linked.
STAGE PLACE_PINS   : FAIL : PPL-0019     -> "Design without pins."
STAGE TAPCELL      : PASS                (vacuous: "Inserted 0 tapcells")
STAGE PDN_GEN      : FAIL : PDN-0190     -> "Unable to determine the pitch of the rows."
STAGE GLOBAL_PLACEMENT   : FAIL : GPL-0130  -> "No rows defined in design."
STAGE DETAILED_PLACEMENT : FAIL : DPL-0027  -> "no rows defined in design."
STAGE WRITE_DB / WRITE_DEF : PASS        (vacuous: empty design, 4x4 um placeholder die)
```

`01_generic_timer/timer_generic.def` and `.odb` are therefore **empty placeholders** and are not
placement results. They are kept only as evidence of the failure mode.

Conclusion: a generic Yosys netlist cannot be placed on Sky130HD. No result was fabricated for it.

---

## 6. Run 2 — mapped timer, exploratory placement (PASS)

### 6.1 Exact Tcl sequence (`03_mapped_timer/run_mapped_timer.tcl`, verbatim order)

```tcl
read_lib  $platform_root/sky130_fd_sc_hd__tt_025C_1v80.lib
read_lef  $platform_root/sky130hd.tlef
read_lef  $platform_root/sky130_fd_sc_hd_merged.lef
read_verilog $netlist                 ;# 02_mapping_probe/timer_sky130.v
link_design timer

initialize_floorplan -utilization 40 -aspect_ratio 1.0 -core_space 2.0 -site unithd
source   $platform_root/sky130hd.tracks          ;# must come after the block exists
place_pins -hor_layers met3 -ver_layers met2
tapcell    -distance 14 -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1
source   $platform_root/sky130hd.pdn.tcl
pdngen
global_placement -density 0.40
detailed_placement
report_design_area
check_placement -verbose
write_db  timer_mapped_placed.odb
write_def timer_mapped_placed.def
```

Two ordering facts were discovered empirically and are worth keeping:

1. **Tracks must be loaded after `initialize_floorplan`.** `make_tracks` needs a block
   (`ORD-0037: No block loaded` otherwise), and without tracks `place_pins` fails with
   `PPL-0021: Horizontal routing tracks not found for layer met3`.
2. **This OpenROAD build has no `get_db`.** It exposes the odb Tcl API instead
   (`ord::get_db_block`, `$block getInsts`, `$i getMaster`, `ord::get_die_area`). Scripts copied
   from newer OpenROAD docs will fail on `get_db`.

### 6.2 Floorplan (provisional parameters — not signoff)

| Parameter | Value |
|-----------|-------|
| Die area | `(0,0)-(95490,95490)` DBU = **95.49 µm × 95.49 µm** (9118.3 µm²) |
| Core area | `(2300,2720)-(93380,92480)` DBU = **91.08 µm × 89.76 µm** (8175.341 µm²) |
| Rows | **33** (`unithd`, 0.46 µm × 2.72 µm, 198 sites per row) |
| Utilisation target | 40 % (floorplan), 42.6 % reported by detailed placement |
| Core margin | 2.0 µm requested → snapped to (2.300, 2.720) (`IFP-0028`) |

### 6.3 Cell counts

| Class | Count |
|-------|-------|
| Logic instances | **301** |
| — sequential (`dfrtp_1`) | 67 |
| — combinational | 234 |
| Tap cells (`sky130_fd_sc_hd__tapvpwrvgnd_1`) | **105** |
| Total COMPONENTS in DEF | **406** |
| Nets | 373 (placement view) / 375 (DEF) |
| Pins | 107 (79 with sink, 28 without) |
| SPECIALNETS | 2 (VDD, VSS) |

### 6.4 Placement results

| Metric | Value |
|--------|-------|
| Global placement | converged at **iteration 379** |
| Final HPWL | **8342.54 µm** |
| Legalised HPWL | **8743.4 µm** (+5 % after legalisation) |
| Movable cell area | 3586.8801 µm² |
| Fixed (tap) area | 131.376 µm² |
| Free area | 8043.9648 µm² |
| Minimum feasible density | 0.4500 |
| Detailed placement | **PASS** — no `DPL-0033`, 0 `UNPLACED` components |
| Design area | **3480 µm², 43 % utilisation** (`report_design_area`) |

### 6.5 Stage classifications (Run 2)

| Stage | Result | Evidence / note |
|-------|--------|-----------------|
| DESIGN LOADING | **PASS** | `LINK_DESIGN : PASS`, `instances without LEF master: 0` (301 instances) |
| FLOORPLAN | **PASS** | die 95.49 × 95.49 µm, core 91.08 × 89.76 µm, 33 rows |
| PLACE_PINS (added) | **PASS** | 107 pins on met3 (hor) / met2 (ver) |
| TAPCELL INSERTION | **PASS** | 105 × `tapvpwrvgnd_1`, `-distance 14` |
| PDN GENERATION | **PASS** | grid + 2 specialnets, 0.02 s; 2 × `PDN-1051` (no macros, benign) |
| GLOBAL PLACEMENT | **PASS** | iter 379, HPWL 8342.54 µm; `GPL-0302` warns 0.40 < min feasible 0.45 |
| DETAILED PLACEMENT | **PASS** | legal, +5 % HPWL, no legality error |
| CTS | **NOT RUN** | no SDC / no clock period exists; inventing one is a stop condition |
| GLOBAL ROUTING | **NOT RUN** | same |
| DETAILED ROUTING | **NOT RUN** | same |

### 6.6 Errors and warnings (Run 2 only)

```
WARNING IFP-0028   core lower-left (2.000,2.000) snapped to (2.300,2.720)
WARNING PDN-1051   x2  no instances for CORE_macro_grid_1 / CORE_macro_grid_2 (design has no macros)
WARNING GPL-0302   target density 0.4000 below minimum feasible 0.4500
WARNING ORD-0046   x9  -defer_connection deprecated (inside the platform's own pdn.tcl)
ERROR              none
```

---

## 7. Outputs (Run 2)

| Artifact | Path | SHA-256 |
|----------|------|---------|
| Design database | `build/asic_flow/phase3_exploratory_pnr/03_mapped_timer/timer_mapped_placed.odb` | `75e445acb4c6a969463f8083ac16d5f4ccdbff8d4109833276445bb00cdbc921` |
| DEF | `build/asic_flow/phase3_exploratory_pnr/03_mapped_timer/timer_mapped_placed.def` | `32f3daf76f7c49c111b5ff15bfe9a1200bc399cbcd31cf2c5ac0011946aeaa29` |
| OpenROAD log | `build/asic_flow/phase3_exploratory_pnr/03_mapped_timer/run_mapped_timer.log` | `d4f37cccb779ad6740cb0160796f78288ec5cebc5ea6f483682c3a932acb84c1` |
| Tcl script | `build/asic_flow/phase3_exploratory_pnr/03_mapped_timer/run_mapped_timer.tcl` | `b179bda64b0bdbc84cf6f38682fac63fcaca87b56ae746f6ab676fc2f8a55d21` |
| Placement summary | `build/asic_flow/phase3_exploratory_pnr/03_mapped_timer/placement_summary.txt` | `a16888af4c1f825b9d27458d1ada71afc841272b19c322567b0e310028832618` |
| Mapped netlist | `build/asic_flow/phase3_exploratory_pnr/02_mapping_probe/timer_sky130.v` | `42c0c3e21fde026fa7657dadbba9a576ec346fee1498db0a960f119326bafbb9` |
| Mapping log | `build/asic_flow/phase3_exploratory_pnr/02_mapping_probe/timer.log` | `558a5efd7dab56460337a0f8230e505c1452ab4d038eb7494504f2d382d26452` |

Full tree manifest: `build/asic_flow/phase3_exploratory_pnr/manifest.sha256`
(**49 files, verified 49/49 OK** with `sha256sum -c` from the project root).

DEF structure sanity check: `COMPONENTS 406`, `PINS 107`, `ROWS 33`, `SPECIALNETS 2`, `NETS 375`,
`DIEAREA ( 0 0 ) ( 95490 95490 )`, 406/406 components `PLACED`, 0 `UNPLACED`.

---

## 8. Phase 4 — MCP

No OpenROAD MCP tool was available in this session and the project contains no `.mcp.json` or MCP
server configuration (the only MCP-related file is the Phase 2.2 investigation report). Per the task's
fallback instruction the **verified OpenROAD CLI was used directly** for every operation listed above,
and every command, log and stage result is recorded in this report. No MCP setup work was attempted
and it did not delay the experiment.

---

## 9. Honesty boundaries — what this does and does not show

**Does:**

- OpenROAD genuinely ran on Sky130HD with the real `sky130_fd_sc_hd` cells (437 masters loaded).
- The timer has a real technology-mapped netlist: 301 cells, 67 `dfrtp_1` with async reset preserved,
  enable realised as `mux2_1` feedback, 0 generic cells, 0 behavioural processes.
- Floorplan, IO placement, 105 tap cells, PDN, global placement and detailed placement all completed
  on that netlist, and a legal, fully placed DEF/ODB was written.

**Does not:**

- **No CTS, no routing, no STA, no power, no DRC/LVS, no GDS.** There is no SDC and no clock period;
  the mapping was not timing-driven, so nothing here is timing-closed.
- The floorplan parameters (40 % utilisation, square die, 2 µm margin, density 0.40) are **provisional
  exploration values**, not a signoff floorplan.
- Placement legality is proven by `detailed_placement`/`check_placement` only; the DEF was not
  independently re-verified by a second tool.
- Nothing here is a technology-mapping claim for the *whole SoC* — only the timer block was mapped.
- This is **not** ASIC signoff and must not be presented as such.

---

## 10. Stop-condition conformance

| Condition | Status |
|-----------|--------|
| No production RTL changes | **met** — `timer.sv` untouched; mapping wrote only into `build/` |
| No original PDK modifications | **met** — platform files read-only, hashes recorded |
| No invented standard cells | **met** — only cells present in the platform Liberty/LEF were used |
| No invented timing constraints | **met** — no SDC, no clock period; consequently no CTS/routing |
| No false technology-mapping claims | **met** — generic netlist labelled GENERIC-NETLIST EXPERIMENT and reported as BLOCKED at link |
| No ASIC signoff claims | **met** |
| No Git mutations | **met** — no commit, stage, checkout or branch operation |
