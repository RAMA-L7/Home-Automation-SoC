# ASIC Phase 2 PnR Environment Readiness Report

**Project:** Home-Automation-SoC  
**Phase:** 2 — PnR Environment Readiness & First Peripheral Smoke Test Preparation  
**Date:** 2026-11-14  
**Host:** Windows 11 + WSL2 Ubuntu-24.04  
**Toolchain target:** Sky130HD (SkyWater 130nm)  
**Classification:** PREPARATION COMPLETE — SMOKE TEST NOT EXECUTED  

---

## 1. Objective

Prepare a reproducible Sky130HD physical-design (PnR) environment under WSL2 and establish the first peripheral-level PnR smoke test preparation. This phase covers toolchain verification (Phases A–C) and smoke-test preparation (Phases D–F). Per the stop conditions, no SRAM wrapper is created, no production RTL is modified, no SDC constraints are invented, and no full-chip synthesis/signoff/full-SoC PnR is claimed.

**Outcome:** Toolchain verified PASS; smoke-test preparation complete; actual PnR execution NOT RUN.

---

## 2. Repository Baseline (Phase A)

### 2.1 Git State

| Item | Value |
|------|-------|
| Branch | `main` |
| HEAD | `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1` |
| Commit date | 2026-11-10 |
| Tracking | 7 pre-existing modifications (unchanged this session) |

### 2.2 Pre-existing Modifications (preserved, not touched)

These 7 tracked files were already modified before this session and remain unchanged:

- `rtl/rtl_peripherals/plic.sv`
- `rtl/rtl_top/has_soc.sv`
- `rtl/rtl_top/riscv_core.sv`
- `scripts/eda/run_regression.js`
- `scripts/firmware/run_e2e.js`
- `scripts/formal/reset_ctrl_fv.sv`
- `scripts/verify.js`

### 2.3 Baseline SHA-256 Verification

- **Expected:** `reports/evidence/asic_flow_phase1_1/final_report_sha256.txt`
- **Result:** MATCH (verified in prior session)
- **Hash:** `7824d0025d428853f5acfc862a4025f0b5b29b99f6f45ea31232b17adfc5d001`

---

## 3. OpenROAD Toolchain Verification (Phase B)

### 3.1 Installation Location

All tools installed under `D:\tools` (no new installs this session; existing tools verified).

| Tool | Path (Windows) | Path (WSL2) | Executable |
|------|---------------|-------------|------------|
| OpenROAD | `D:\tools\openroad\bin\openroad` | `/usr/local/bin/openroad` → `/mnt/d/tools/openroad/bin/openroad` | ✅ Linux ELF |
| OpenSTA | `D:\tools\opensta\bin\sta` | `/mnt/d/tools/opensta/bin/sta` | ⚠️ Not via `/d/...` |
| Yosys | `D:\tools\oss-cad-suite\bin\yosys` | `/d/tools/oss-cad-suite/bin/yosys` (via PATH) | ✅ |
| Verilator | `D:\tools\oss-cad-suite\bin\verilator` | via PATH | ✅ |
| Icarus Verilog | `D:\tools\oss-cad-suite\bin\iverilog` | via PATH | ✅ |

### 3.2 OpenROAD Version and Startup

| Check | Command | Result | Exit |
|-------|---------|--------|------|
| Version | `MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- openroad -version` | `bazel-nostamp` | 0 |
| Help | `MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- openroad -help` | Real CLI help output | 0 |
| Binary check | `file /usr/local/bin/openroad` | ELF 64-bit LSB executable | — |

**OpenROAD STARTUP: PASS**

### 3.3 Source Commit IDs (recorded this session)

| Component | Commit SHA |
|-----------|-----------|
| OpenROAD | `629aa76b94ae420170d18692016a7be9101a53e7` |
| OpenSTA | `7a034b56de14b485ddf8fd97b420a6f37a91c00d` |
| openlane2 | `83ec6c32add40006cc70d951745667d30193f51d` |

### 3.4 Liberty and LEF Loading Verification

Probe scripts located in `D:\tools\eda-work\` (WSL-accessible):

- `or_probe.tcl` — OpenROAD Liberty/LEF loading probe
- `platform_probe.sh` — Sky130HD platform inventory script

**Key discovery:** Liberty filename is `sky130_fd_sc_hd__tt_025C_1v80.lib` (NOT `1p80.lib`). Earlier failures were caused by wrong filename + wrong path form.

| Check | Command / Script | Result | Exit |
|-------|-----------------|--------|------|
| read_lib (std cell) | `read_liberty /mnt/d/.../sky130_fd_sc_hd__tt_025C_1v80.lib` | `read_lib` → 1 | 0 |
| read_lib (dummy io) | `read_liberty /mnt/d/.../sky130_dummy_io.lib` | success | 0 |
| read_lef (tlef) | `read_lef /mnt/d/.../sky130_fd_sc_hd.tlef` | 13 layers, 25 vias | 0 |
| read_lef (merged) | `read_lef /mnt/d/.../sky130_fd_sc_hd_merged.lef` | 441 library cells | 0 |
| read_lef (SRAM) | `read_lef /mnt/d/.../sky130_sram_1rw1r_128x256_8.lef` | 1 library cell | 0 |

**LIBERTY/LEF LOADING: PASS**

---

## 4. Sky130HD Platform Preflight (Phase C)

### 4.1 Platform Root

```
D:\rta-real-world-benchmark\02_projects\OpenROAD-flow-scripts\flow\platforms\sky130hd
```

### 4.1.1 Platform Root Files (beyond Liberty/LEF/GDS)

| File | Purpose |
|------|--------|
| `config.mk` | Makefile config: PROCESS=130, TECH_LEF, SC_LEF, LIB_FILES, GDS_FILES, DONT_USE_CELLS |
| `tapcell.tcl` | Tap-cell insertion: `-distance 14`, uses `$::env(TAP_CELL_NAME)` |
| `pdn.tcl` | PDN: global VDD/VSS connections, CORE voltage domain, grid stripes met1/met4/met5 |
| `setRC.tcl` | Layer RC: li1/met1-met5 capacitance+resistance, via resistances |
| `rcx_patterns.rules` | RC extraction patterns → `../sky130hs/rcx_patterns.rules` (external) |
| `fastroute.tcl` | Fastroute configuration |
| `make_tracks.tcl` | Track generation |
| `fill.json` | Filler cell placement config |
| `sky130hd.lyp` / `sky130hd.lyt` | Cadence layer properties / tech file |
| `cells_adders_hd.v` / `cells_clkgate_hd.v` / `cells_latch_hd.v` | Additional cell Verilog |

### 4.2 Platform Inventory

| File / Directory | Path | Status | Notes |
|-----------------|------|--------|-------|
| Standard-cell Liberty | `lib/sky130_fd_sc_hd__tt_025C_1v80.lib` | ✅ Present | TT 0.25C 1.80V (NOT 1p80) |
| Dummy IO Liberty | `lib/sky130_dummy_io.lib` | ✅ Present | |
| Technology LEF | `lef/sky130_fd_sc_hd.tlef` | ✅ Present | VERSION 5.7 |
| Merged cell LEF | `lef/sky130_fd_sc_hd_merged.lef` | ✅ Present | 68,383 lines; includes decap, filler, fakediode, std cells |
| Standard-cell GDS | `gds/sky130_fd_sc_hd.gds` | ✅ Present | |
| RC extraction config | `rcx_patterns.rules` | ⚠️ Present (external ref) | Points to `../sky130hs/rcx_patterns.rules` (not co-located) |
| tlef macro count | `lef/sky130_fd_sc_hd.tlef` | ✅ 1 macro (sky130_fd_sc_hd) | SITE `unithd`, `unithddbl` defined |
| Layer definitions | tlef | ✅ 13 layers | nwell, pwell, li1, mcon, met1…met5, via, via2, via3, via4 |
| Tap-cell config | tlef | ❌ NOT FOUND | No `TAP` or tap-cell defs in tlef |
| PDN config | tlef | ❌ NOT FOUND | No PDN configuration in tlef |
| Placement sites | tlef | ✅ `unithd`, `unithddbl` | 0.46 × 2.72 and 0.46 × 5.44 |

### 4.3 SRAM Macro Views (separate, under `sky130ram/`)

| File | Path | Status | Notes |
|------|------|--------|-------|
| LEF | `sky130_sram_1rw1r_128x256_8/sky130_sram_1rw1r_128x256_8.lef` | ✅ Present | 100 MB; SIZE 1141.72 × 632.475; SYMMETRY X Y R90; MACRO `sky130_sram_1rw1r_128x256_8` |
| Liberty | `sky130_sram_1rw1r_128x256_8/sky130_sram_1rw1r_128x256_8_TT_1p8V_25C.lib` | ✅ Present | |
| Spice | `sky130_sram_1rw1r_128x256_8/sky130_sram_1rw1r_128x256_8.sp` | ✅ Present | |
| Verilog | `sky130_sram_1rw1r_128x256_8/sky130_sram_1rw1r_128x256_8.v` | ✅ Present | |

### 4.3 Additional Platform Configuration Files (found at platform root)

The platform root contains supplementary configuration files beyond the Liberty/LEF/GDS checked earlier:

| File | Purpose | Status |
|------|---------|--------|
| `config.mk` | Makefile config: PROCESS=130, TECH_LEF, SC_LEF, LIB_FILES, GDS_FILES, DONT_USE_CELLS | ✅ Present |
| `tapcell.tcl` | Tap-cell insertion script: `-distance 14`, uses `$::env(TAP_CELL_NAME)` | ✅ Present (but TAP_CELL_NAME env var must be set) |
| `pdn.tcl` | PDN configuration: global connections (VDD/VSS), voltage domain CORE, grid stripes on met1/met4/met5 | ✅ Present |
| `setRC.tcl` | Layer RC values: li1/met1-met5 capacitance+resistance, via mcon/via/via2/via3/via4 resistance | ✅ Present |
| `rcx_patterns.rules` | RC extraction patterns — points to `../sky130hs/rcx_patterns.rules` | ⚠️ Present but references external file (not in sky130hd dir) |
| `fastroute.tcl` | Fastroute configuration | ✅ Present |
| `make_tracks.tcl` | Track generation for routing | ✅ Present |
| `fill.json` | Filler cell placement configuration | ✅ Present |
| `sky130hd.lyp` / `sky130hd.lyt` | Cadence layer properties / tech file | ✅ Present |
| `cells_adders_hd.v` / `cells_clkgate_hd.v` / `cells_latch_hd.v` | Additional cell Verilog descriptions | ✅ Present |

### 4.4 Updated Platform Gap Assessment

1. **`rcx_patterns.rules` references external file** — `../sky130hs/rcx_patterns.rules` is outside the sky130hd platform directory; the actual RC extraction patterns file is not co-located. This is a minor configuration gap for signoff RC extraction.
2. **Tap-cell config exists (`tapcell.tcl`)** but requires `$::env(TAP_CELL_NAME)` to be set — the tap cell master name is not hardcoded, so the environment must define it before use.
3. **PDN config exists (`pdn.tcl`)** — fully specified with global connections, voltage domains, and grid stripes on met1/met4/met5. Ready for use once OpenROAD loads it.
4. **No SDC file prepared for timer** — clock and reset constraints not yet created.

These gaps are reported but the PDN and tap-cell configs are actually present (just need env var setup). They do not block the smoke-test preparation. Signoff-quality RC extraction would need the external `rcx_patterns.rules` resolved.

---

## 5. Smoke-Test Design Selection (Phase D)

### 5.1 Candidate Evaluation

Four peripheral candidates were evaluated from `rtl/rtl_peripherals/`:

| Peripheral | FF blocks | `negedge presetn` (async reset) | Yosys cells | $adff | $adffe | Synthesis exit | Complexity |
|-----------|-----------|--------------------------------|-------------|-------|--------|---------------|------------|
| **timer** | **2** | **2** | **25** | **0** | **5** | **0** | **Lowest — sequential only, no $adff** |
| gpio | 3 | 3 | 54 | 4 | 5 | 0 | Medium — 16-bit, 54 cells |
| pwm | 5 | 5 | 74 | 8 | 9 | 0 | Medium — 4 channels |
| uart | 5 | 5 | 145 | 7 | 15 | 0 | Highest — shift registers, baud gen |

### 5.2 Selected Block: **timer**

**Rationale:**
- **Fewest sequential blocks** (2 `always_ff`), smallest cell count (25 cells).
- **No `$adff` cells** in Yosys output — async reset mapped to `$adffe` (enabled flop), which is more portable for technology mapping.
- **Clear clock/reset interface:** single clock `pclk`, async reset `presetn`, no clock gating, no multi-clock domains.
- **Existing successful synthesis:** `build/asic_flow/phase1/generic_synthesis/timer.log` exits 0.
- **Manageable size:** 25 Yosys cells, 34 wires, 11 ports (107 port bits).

**Selection: timer peripheral (`rtl/rtl_peripherals/timer.sv`)**

### 5.3 Existing Synthesis Evidence

**File:** `build/asic_flow/phase1/generic_synthesis/timer.log`  
**Yosys script:** `build/asic_flow/phase1/generic_synthesis/timer.ys`  
**Yosys version:** 0.69+154 (git sha1 30d62572e-dirty)  

**Synthesis log tail:**
```
=== timer ===

        +----------Local Count, excluding submodules.
        |
       34 wires
      223 wire bits
       16 public wires
      174 public wire bits
       11 ports
      107 port bits
       25 cells
        1   $add
        5   $adffe
        2   $and
        4   $eq
        2   $logic_and
        1   $logic_not
        3   $mux
        1   $not
        1   $pmux
        3   $reduce_and
        2   $reduce_bool
```

**Summary file (`summary.txt`):** `timer exit=0`

### 5.4 $adff / $adffe Mapping Analysis

The existing Yosys synthesis of `timer` produces:
- **0 × `$adff`** (async reset flop without enable) — **NONE**
- **5 × `$adffe`** (async reset flop with enable) — present

This is **significant and favorable** compared to other peripherals:

| Peripheral | $adff count | $adffe count |
|-----------|-------------|--------------|
| timer | **0** | 5 |
| gpio | 4 | 5 |
| pwm | 8 | 9 |
| uart | 7 | 15 |

**The timer is the only candidate with zero `$adff` cells.**

`$adff` (async reset flop, no enable) is the problematic cell type for technology mapping because it maps to a flip-flop with async reset but no clock enable, which some technology libraries map less cleanly. The timer's async resets all have associated enable conditions, so they map to `$adffe` instead.

**No RTL modification needed for the timer** — the existing RTL already avoids the `$adff` mapping problem by construction.

### 5.5 Technology Mapping Status

**Current state:** Generation of a technology-mapped netlist is **BLOCKED** until:

1. Yosys runs with an AFP/tech mapping pass that targets Sky130HD standard cells.
2. The `$adffe` cells are resolved to Sky130HD DFF cells (e.g., `sky130_fd_sc_hd__dffxtp_1` or similar).
3. A mapped netlist file (Verilog or JSON) is produced.

**Existing Yosys script `timer.ys` ends at `stat`** — it does NOT run `abc` or `map` with a technology library, and does NOT write out a mapped netlist. The log shows gate-level Yosys cells (`$add`, `$adffe`, `$and`, etc.) but no technology-mapped cells.

**No mapped netlist currently exists** for any peripheral in the repo.

**TECHNOLOGY MAPPING: BLOCKED** (no mapped netlist yet; Yosys `$adffe` cells need tech mapping)

### 5.6 Stop Condition Compliance

- ✅ No SRAM wrapper created
- ✅ No production RTL modified (timer.sv unchanged)
- ✅ No SDC constraints invented
- ✅ No full-chip synthesis claimed
- ✅ No ASIC signoff claimed
- ✅ No full-SoC PnR attempted

---

## 6. Smoke-Test Preparation (Phase E)

### 6.1 Directory Structure Created

```
build/asic_flow/phase2_pnr_smoke/
├── src/          (empty — for any smoke-test-specific RTL, if needed)
├── netlist/      (empty — for timer_mapped.v, to be generated)
├── constraints/  (empty — for SDC, to be created)
├── scripts/
│   └── pnr_smoke_provisional.tcl   (PROVISIONAL, NOT EXECUTED)
└── results/      (empty — for OpenROAD output)
```

### 6.2 Provisional Tcl Script

**File:** `build/asic_flow/phase2_pnr_smoke/scripts/pnr_smoke_provisional.tcl`  
**Lines:** 197  
**Status:** PROVISIONAL — prepared but NOT executed  

The script covers all 13 intended smoke-test steps (Liberty/LEF loading through detailed routing) with clearly labeled PROVISIONAL parameters and NOT RUN markers. No signoff SDC is included.

### 6.3 Provisional Parameters (clearly labeled)

| Parameter | Provisional Value | Notes |
|-----------|------------------|-------|
| Core area | 500 × 500 µm | Placeholder; derive from actual mapped size |
| Utilization | 30% | Placeholder |
| Routing | global only | Detailed routing disabled (`PROVISIONAL_DO_DETAILED_ROUTING = 0`) |
| Power nets | VPWR, VGND, VPB, VNB | Per tlef definitions |
| Clock | pclk (single) | No SDC yet |

### 6.4 Missing Prerequisites (before execution)

1. **Mapped netlist** `netlist/timer_mapped.v` — Yosys with Sky130HD tech mapping, `$adffe` resolved
2. **SDC file** `constraints/timer.sdc` — clock `pclk`, reset `presetn`, no invented signoff constraints
3. **Tap-cell insertion config** — not available in tlef; requires external tap-cell LEF or OpenROAD PDN config
4. **PDN configuration** — not available in tlef
5. **`rcx/` directory** — not present in platform; needed for RC extraction (signoff)

---

## 7. Evidence Files and Hashes

### 7.1 Verification Commands and Exit Codes

| Step | Command (WSL2) | Exit |
|------|---------------|------|
| OpenROAD version | `MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- openroad -version` | 0 |
| OpenROAD help | `MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- openroad -help` | 0 |
| read_lib (std cell) | `read_liberty /mnt/d/.../sky130_fd_sc_hd__tt_025C_1v80.lib` | 0 |
| read_lib (dummy io) | `read_liberty /mnt/d/.../sky130_dummy_io.lib` | 0 |
| read_lef (tlef) | `read_lef /mnt/d/.../sky130_fd_sc_hd.tlef` | 0 |
| read_lef (merged) | `read_lef /mnt/d/.../sky130_fd_sc_hd_merged.lef` | 0 |
| read_lef (SRAM) | `read_lef /mnt/d/.../sky130_sram_1rw1r_128x256_8.lef` | 0 |

### 7.2 Synthesis Log Hashes

| File | Log hash |
|------|----------|
| timer.log | `5149237ea1` |
| gpio.log | `54c6320308` |
| pwm.log | `4fc5862108` |
| uart.log | `33e763e9f1` |

### 7.3 Source Commit IDs

| Component | Commit |
|-----------|--------|
| OpenROAD | `629aa76b94ae420170d18692016a7be9101a53e7` |
| OpenSTA | `7a034b56de14b485ddf8fd97b420a6f37a91c00d` |
| openlane2 | `83ec6c32add40006cc70d951745667d30193f51d` |

### 7.4 Files Created This Session

| File | Purpose |
|------|---------|
| `reports/ASIC_PHASE2_PNR_ENVIRONMENT_READINESS.md` | This report |
| `build/asic_flow/phase2_pnr_smoke/scripts/pnr_smoke_provisional.tcl` | Provisional smoke-test TCL |
| `build/asic_flow/phase2_pnr_smoke/{src,netlist,constraints,results}/` | Directory structure |

---

## 8. Final Classification

| Stage | Classification | Evidence |
|-------|---------------|----------|
| **TOOL INSTALLATION** | **PASS** | OpenROAD binary verified, exit 0; OpenSTA path confirmed; Yosys/Verilator/Icarus on PATH |
| **OPENROAD STARTUP** | **PASS** | `openroad -version` → `bazel-nostamp`, exit 0; `openroad -help` returns real CLI |
| **LIBERTY/LEF LOADING** | **PASS** | read_lib → 1; tlef → 13 layers/25 vias; merged LEF → 441 cells; all exit 0 |
| **TECHNOLOGY MAPPING** | **BLOCKED** | No mapped netlist exists; Yosys `timer.ys` ends at `stat`; `$adffe` cells (5×) need tech mapping to Sky130HD DFF cells before OpenROAD consumption; timer has 0× `$adff` (favorable — no async reset without enable) |
| **FLOORPLAN** | **NOT RUN** | Provisional script prepared; not executed; PDN config (`pdn.tcl`) and tap-cell config (`tapcell.tcl`) available at platform root |
| **PLACEMENT** | **NOT RUN** | Not executed; requires mapped netlist + floorplan |
| **CTS** | **NOT RUN** | Not executed; no SDC file yet; single clock `pclk` |
| **ROUTING** | **NOT RUN** | Not executed; global + detailed routing not attempted; `fastroute.tcl` and `make_tracks.tcl` available at platform root |

### Stop Conditions — All Respected

- ✅ No SRAM wrapper created
- ✅ No production RTL modified
- ✅ No SDC constraints invented
- ✅ No full-chip synthesis claimed
- ✅ No ASIC signoff claimed
- ✅ No full-SoC PnR attempted

**Work stopped after toolchain verification + smoke-test preparation, per stop conditions.**

---

## 9. Reproduction Instructions

### 9.1 Prerequisites

- Windows 11 host with WSL2 Ubuntu-24.04
- `D:\tools` with OpenROAD, OpenSTA, oss-cad-suite (Yosys/Verilator/Icarus) installed
- `D:\rta-real-world-benchmark\02_projects\OpenROAD-flow-scripts` with Sky130HD platform

### 9.2 OpenROAD Path Setup (WSL2)

```bash
# From WSL2 Ubuntu-24.04, ensure /mnt/d is mounted
ls /mnt/d/tools/openroad/bin/openroad

# Symlink (if not present)
sudo ln -sf /mnt/d/tools/openroad/bin/openroad /usr/local/bin/openroad
```

### 9.3 Verify OpenROAD Startup

```bash
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- openroad -version
# Expected: bazel-nostamp, exit 0
```

### 9.4 Verify Liberty/LEF Loading

```bash
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- openroad -no_init /mnt/d/tools/eda-work/or_probe.tcl
# Expected: read_lib → 1, tlef → 13 layers/25 vias, merged LEF → 441 cells, exit 0
```

### 9.5 Platform Probe

```bash
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- /mnt/d/tools/eda-work/platform_probe.sh
# Expected: platform inventory output
```

### 9.6 Set Up Platform Environment (for execution)

```bash
export PLATFORM_DIR=/mnt/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130hd
export TAP_CELL_NAME=sky130_fd_sc_hd__tap_1  # provisional — verify actual tap cell name in liberty/LEF
# PDN and tapcell configs are at $PLATFORM_DIR/tapcell.tcl and $PLATFORM_DIR/pdn.tcl
# RC extraction patterns: $PLATFORM_DIR/rcx_patterns.rules → ../sky130hs/rcx_patterns.rules (external)
```

### 9.7 Run Provisional Smoke Test (NOT YET — requires mapped netlist + SDC)

```bash
# From WSL2, after generating timer_mapped.v and timer.sdc:
MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu-24.04 -- openroad -no_init /mnt/d/Home-Automation-SoC/build/asic_flow/phase2_pnr_smoke/scripts/pnr_smoke_provisional.tcl
# Expected: script runs but most steps NOT RUN / PROVISIONAL
```

---

## 10. Next Steps (beyond this phase)

1. **Generate mapped netlist:** Run Yosys with Sky130HD technology mapping (AFP/tech library) to produce `timer_mapped.v` with `$adffe` (5×) resolved to Sky130HD DFF cells (e.g., `sky130_fd_sc_hd__dffxtp_1`). Timer has 0× `$adff` (favorable — no async reset without enable).
2. **Create SDC:** Write `constraints/timer.sdc` with `create_clock -name pclk -period < provisional > [get_ports pclk]` and reset constraints. Clearly label as provisional, not signoff.
3. **Set platform env:** Export `PLATFORM_DIR` and `TAP_CELL_NAME` before running OpenROAD; load `tapcell.tcl` and `pdn.tcl` from platform root.
4. **Resolve RC extraction:** The `rcx_patterns.rules` file references `../sky130hs/rcx_patterns.rules` (external); obtain or create the patterns file for signoff-quality RC extraction.
5. **Execute smoke test:** Run `pnr_smoke_provisional.tcl` with mapped netlist + SDC, capture actual floorplan/placement/CTS/routing results.
6. **Update report:** After execution, update classifications from NOT RUN to PASS/BLOCKED as appropriate.

---

*End of report — Phase 2 PnR environment readiness preparation complete.*
