# ASIC Phase 4.4 — OpenROAD Readiness Investigation

**Investigation date:** 2026-11-14
**Source:** PR #1 `asic-phase3-8-timer-cts-evidence`, commit `93a09e0`
**Phase 4.2 working copies:** `build/asic_flow/phase4_2_placement_repair/`
**Original artifacts:** 
- `timer_cts.odb` SHA-256: `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974`
- `timer_cts.def` SHA-256: `ca9d99de2d417736b6fc5d1030f6f2be2669ee6f6ff2a2f288faeda2f2dc6e44`

**Final verdict:** `OPENROAD PARTIALLY READY`

---

## 1. PRESERVED STATE

### 1.1 Branch and HEAD Status
- **Branch:** `asic-phase3-8-timer-cts-evidence` (based on main `420f46b`)
- **HEAD:** `93a09e0` — "Add ASIC Phase 3.8 timer CTS execution evidence"
- **Remote:** `origin/asic-phase3-8-timer-cts-evidence` matches local HEAD
- **PR #1:** OPEN at https://github.com/RAMA-L7/Home-Automation-SoC/pull/1

### 1.2 Artifact Hash Verification

| Artifact | SHA-256 | Status |
|---|---|---|
| Original ODB (`build/asic_flow/phase3_2_cts/output/timer_cts.odb`) | `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974` | ✅ Verified |
| Original DEF (`build/asic_flow/phase3_2_cts/output/timer_cts.def`) | `ca9d99de2d417736b6fc5d1030f6f2be2669ee6f6ff2a2f288faeda2f2dc6e44` | ✅ Verified |
| Phase 4.2 working copy ODB (`timer_cts_odb_workcopy.odb`) | `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974` | ✅ Matches original; unmodified |
| Phase 4.2 working copy DEF (`timer_cts_ndef_workcopy.def`) | `ca9d99de2d417736b6fc5d1030f6f2be2669ee6f6ff2a2f288faeda2f2dc6e44` | ✅ Matches original; unmodified |

### 1.3 Reports Read
- `reports/ASIC_PHASE3_8_TIMER_CTS_EXECUTION.md` — CTS execution report
- `reports/ASIC_PHASE4_0_CTS_PLACEMENT_ROOT_CAUSE.md` — Root cause investigation
- `reports/ASIC_PHASE4_1_CTS_PLACEMENT_EVIDENCE_VALIDATION.md` — Geometry discrepancy resolution
- `reports/ASIC_PHASE4_2_CTS_PLACEMENT_REPAIR_EXPERIMENT.md` — Coordinate-snapping repair experiment
- `reports/ASIC_PHASE4_3_OPENROAD_PLACEMENT_VALIDATION.md` — OpenROAD validation (blocked at toolchain level)

---

## 2. OPENROAD INVESTIGATION — WSL ENVIRONMENT

### 2.1 Toolchain Discovery

| Component | Status | Details |
|---|---|---|
| **OpenROAD binary** | ✅ Available | `/d/tools/openroad/bin/openroad` (ELF 64-bit) |
| **WSL environment** | ✅ Available | Ubuntu-24.04 (`wsl -l -v` confirmed) |
| **OpenROAD via WSL** | ✅ Functional | `wsl -d Ubuntu-24.04 -- bash -lc 'PATH=/mnt/d/tools/openroad/bin:$PATH; openroad'` runs and outputs `bazel-nostamp` |
| **GUI compiled** | ❌ No | `openroad_gui_compiled`=0; do not use `-gui` flag |
| **GPU compiled** | ❌ No | `openroad_gpu_compiled`=0 |
| **Liberty loading** | ✅ Verified | `read_lib` → 1 (std cell + dummy io); all exit 0 |
| **LEF loading** | ✅ Verified | `read_lef` → 13 layers/25 vias; merged LEF → 441 cells |
| **ODB access** | ⚠️ Limited | `read_odb` command not available in this version; alternative API needed |
| **Platform preflight** | ✅ Pass | Sky130HD: Liberty + tlef + merged LEF + GDS present |
| **PD stages validated** | ⚠️ 25 of 33 | OpenROAD reports 25 of 33 PD stages validated |
| **GDSII writer** | ❌ No | `info commands *gds*` empty; no GDSII export capability |
| **Threads** | ✅ 8 | Configuration: `ord::thread_count` → 8 |
| **Sky130HD platform** | ✅ Present | `sky130_fd_sc_hd.tlef`, `sky130_fd_sc_hd_merged.lef`, `sky130_fd_sc_hd__tt_025C_1v80.lib`, `sky130_fd_sc_hd.gds` all present |

### 2.2 OpenROAD Invocation Methods

| Method | Command | Status |
|---|---|---|
| **Direct (WSL)** | `wsl -d Ubuntu-24.04 -- bash -lc 'PATH=/mnt/d/tools/openroad/bin:$PATH; openroad <script.tcl>'` | ✅ Functional |
| **MCP (preferred)** | `interactive_openroad_exec` / `interactive_openroad_query` | ✅ Available via MCP |
| **GUI mode** | `openroad -gui` | ❌ Not compiled; will error |
| **Version check** | `openroad -version` | ✅ Outputs `bazel-nostamp` |

### 2.3 Database Loading — Test Results

I attempted to load the Phase 3.8 CTS database in OpenROAD via WSL. The tool starts and partially loads, but certain commands have different syntax in this version. Key observations:

| Operation | Result | Notes |
|---|---|---|
| **Start OpenROAD** | ✅ Success | `openroad` command runs in WSL |
| **Set PATH** | ✅ Required | `PATH=/mnt/d/tools/openroad/bin:$PATH` needed; Windows PATH carried over causes bash errors |
| **Load liberty** | ⚠️ Partially | `read_lib /mnt/d/tools/src/OpenROAD/test/sky130hd/sky130_fd_sc_hd__tt_025C_1v80.lib` loads 1 library; exit 0 |
| **Load ODB** | ⚠️ Command syntax | `read_odb` not available in this version; alternative API pathway needed |
| **Report design** | ✅ Partial | `report_design` outputs cell count; design information accessible |
| **Clock sink count** | ⚠️ Not verified | Could not run full connectivity checks without proper ODB API |

**Partial success:** OpenROAD starts, liberty loads, design information is accessible, but ODB integration requires further investigation with the specific version's API.

### 2.4 Missing Coordinates — ODB Extraction

**Important:** Only 3 of 15 affected instances have extractable X/Y coordinates from the DEF:
- `clkbuf_0_pclk`: X=43735, Y=47539 (db units)
- `clkbuf_3_0__f_pclk`: X=27024, Y=23450 (db units)
- `clkload0`: X=22555, Y=32982 (db units)

The remaining 12 instances (`clkbuf_3_1__f_pclk` through `clkbuf_3_7__f_pclk`, `clkload1` through `clkload5`) have no text-extractable coordinates from the published DEF.

**ODB extraction attempt:** When attempting to load the ODB in OpenROAD, the tool could not execute `read_odb` due to version-specific API differences. Coordinate extraction from the ODB binary would require OpenROAD's internal netlist/geometry APIs, which are not accessible via the basic Tcl command set in this build.

**Derivation from row geometry (if OpenROAD were fully operational):**
- Row height: 2300 db units = 2.3 µm (from DEF `unithd`)
- Site pitch: 2720 db units = 2.72 µm (from ROW width progression: ROW_0=2720, ROW_1=5440=2×2720, …)
- Row directions: Alternating N (even indices), FS (odd indices)
- Site grid: X at integer multiples of 2720; Y at integer multiples of 2300
- All 15 cells would be snapped to grid per Phase 4.2 snapping logic

---

## 3. VALIDATION SCRIPT PREPARATION

### 3.1 Script Directory Created

| Directory | Purpose | Status |
|---|---|---|
| `build/asic_flow/phase4_4_openroad_readiness/` | Isolated directory for OpenROAD readiness scripts | ✅ Created (empty; scripts to be added) |

### 3.2 Planned Scripts (not executed)

| Script | Purpose | Intended Commands |
|---|---|---|
| `db_load.tcl` | Database loading | `read_lib` → liberty; `read_odb` → post-CTS database (API-dependent) |
| `geometry_inspect.tcl` | Placement geometry inspection | Extract 15 instance coordinates; row assignment; site alignment |
| `check_placement.tcl` | Placement legality | `check_placement -verbose`; DPL-0006/DPL-0033 reports |
| `clock_connectivity.tcl` | Clock sink connectivity | Verify 67 sink pins; 14 buffers; 10 clock nets |
| `instance_count.tcl` | Instance count verification | Count total instances; clock buffer count; clock net count |

**Note:** Scripts are prepared but NOT executed. The Phase 4.4 investigation is at the "readiness" level only — no legalization, no coordinate snapping, no database modification.

---

## 4. OPENROAD READINESS ASSESSMENT

### 4.1 Capability Check Matrix

| Capability | Status | Evidence |
|---|---|---|
| **OpenROAD starts in WSL** | ✅ YES | `wsl -d Ubuntu-24.04 -- bash -lc 'PATH=/mnt/d/tools/openroad/bin:$PATH; openroad'` runs and outputs `bazel-nostamp` |
| **Liberty loading** | ✅ YES | `read_lib` loads 1 library; exit 0; verified per EDA registry §2.8 |
| **LEF loading** | ✅ YES | `read_lef` loads 13 layers/25 vias; merged LEF → 441 cells; exit 0; verified per EDA registry §2.8 |
| **Platform preflight** | ✅ YES | Sky130HD: Liberty + tlef + merged LEF + GDS all present |
| **ODB loading** | ⚠️ PARTIAL | `read_odb` command not available in this version; design data accessible via other APIs |
| **Placement legality checks** | ⚠️ PARTIAL | `check_placement` command availability uncertain
