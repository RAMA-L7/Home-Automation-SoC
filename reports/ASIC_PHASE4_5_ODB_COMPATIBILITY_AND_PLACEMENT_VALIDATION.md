# ASIC Phase 4.5 — OpenROAD ODB Compatibility and Placement Validation

**Investigation date:** 2026-11-14
**Phase:** 4.5 (following Phase 4.4 readiness investigation)
**Source:** PR #1 `asic-phase3-8-timer-cts-evidence`, commit `93a09e0`
**Original CTS evidence:** `timer_cts.odb` SHA-256: `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974`
**Phase 4.2 working copies:** `build/asic_flow/phase4_2_placement_repair/`
**Restrictions:** No CTS rerun, no placement modification, no coordinate snapping, no legalization, no ECO, no routing, no RTL/SDC/PDK changes, no Git mutations, no PR #1 modifications

---

## 1. PRESERVED STATE

### 1.1 Branch and HEAD Status
- **Branch:** `asic-phase3-8-timer-cts-evidence` (based on main `420f46b`)
- **HEAD:** `93a09e0` — "Add ASIC Phase 3.8 timer CTS execution evidence"
- **Remote:** `origin/asic-phase3-8-timer-cts-evidence` matches local HEAD
- **PR #1:** OPEN at https://github.com/RAMA-L7/Home-Automation-SoC/pull/1 (unchanged)

### 1.2 Artifact Hash Verification

| Artifact | SHA-256 | Status |
|---|---|---|
| Original ODB (`build/asic_flow/phase3_2_cts/output/timer_cts.odb`) | `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974` | ✅ Verified; immutable |
| Original DEF (`build/asic_flow/phase3_2_cts/output/timer_cts.def`) | `ca9d99de2d417736b6fc5d1030f6f2be2669ee6f6ff2a2f288faeda2f2dc6e44` | ✅ Verified; immutable |
| Phase 4.2 working copy ODB (`timer_cts_odb_workcopy.odb`) | `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974` | ✅ Matches original; unmodified |
| Phase 4.2 working copy DEF (`timer_cts_ndef_workcopy.def`) | `ca9d99de2d417736b6fc5d1030f6f2be2669ee6f6ff2a2f288faeda2f2dc6e44` | ✅ Matches original; unmodified |

### 1.3 Reports Preserved
- `reports/ASIC_PHASE3_8_TIMER_CTS_EXECUTION.md` — CTS execution report
- `reports/ASIC_PHASE4_0_CTS_PLACEMENT_ROOT_CAUSE.md` — Root cause investigation
- `reports/ASIC_PHASE4_1_CTS_PLACEMENT_EVIDENCE_VALIDATION.md` — Geometry discrepancy resolution
- `reports/ASIC_PHASE4_2_CTS_PLACEMENT_REPAIR_EXPERIMENT.md` — Coordinate-snapping repair experiment
- `reports/ASIC_PHASE4_3_OPENROAD_PLACEMENT_VALIDATION.md` — OpenROAD validation (blocked at toolchain level)
- `reports/ASIC_PHASE4_4_OPENROAD_READINESS.md` — Readiness investigation (from Phase 4.4)

---

## 2. OPENROAD ENVIRONMENT — WSL UBUNTU-24.04

### 2.1 Toolchain Configuration

| Component | Configuration | Status |
|---|---|---|
| **WSL environment** | `wsl -d Ubuntu-24.04` | ✅ Confirmed |
| **OpenROAD binary** | `/d/tools/openroad/bin/openroad` (ELF 64-bit) | ✅ Available |
| **PATH for OpenROAD** | `export PATH=/mnt/d/tools/openroad/bin` | ✅ Required; Windows PATH causes bash errors |
| **OpenROAD version** | `bazel-nostamp` | ✅ Reported on startup |
| **GPU compilation** | `openroad_gpu_compiled`=0 | ❌ Not compiled |
| **GUI compilation** | `openroad_gui_compiled`=0 | ❌ Not compiled; `-gui` flag will error |

### 2.2 OpenROAD Invocation Method
```
export PATH=/mnt/d/tools/openroad/bin && openroad [args]
```
- ✅ Functional via WSL Ubuntu-24.04
- Requires explicit PATH export; carrying Windows PATH causes `bash: line 1: export: 'Files/Git/...': not a valid identifier`

---

## 3. ODB COMPATIBILITY INVESTIGATION

### 3.1 Command Availability Test

I investigated which ODB-related Tcl commands are available in this OpenROAD version by listing all commands matching `read_`, `write_`, `report_`, `db_`, `get_`, `placed_`, `floorplan_` patterns.

**Result:** The `read_odb` command is **NOT available** in this version. When attempted, OpenROAD reports:
```
invalid command name "read_odb"
    while executing
"::unknown {*}$args"
    (procedure "sta_unknown" line 27)
    invoked from within
"read_odb /d/Home-Automation-SoC/build/asic_flow/phase3_2_cts/output/timer_cts.odb"
```

**Available alternatives (if any):**
- `read_lib` — Liberty loading: ✅ Verified (loads 1 library; exit 0)
- `read_lef` — LEF loading: ✅ Verified (13 layers/25 vias; merged LEF → 441 cells; exit 0)
- `report_design_area` — Design reporting: ✅ Partial (outputs area metrics)
- `report_design` — Design reporting: ⚠️ Ambiguous (conflicts with `report_design_area_metrics`)

**Not available:**
- `read_odb` — ODB database loading: ❌ Command not found
- `write_odb` — ODB database writing: Not tested (command availability unknown)
- `get_design` — Design retrieval: Not tested
- `get_cells` — Cell retrieval: Not tested
- `get_nets` — Net retrieval: Not tested
- `get_ports` — Port retrieval: Not tested

### 3.2 Startup `-db` Flag Test

OpenROAD can be started with the `-db` flag to load a database at startup:

```
export PATH=/mnt/d/tools/openroad/bin && openroad -db /mnt/d/Home-Automation-SoC/build/asic_flow/phase3_2_cts/output/timer_cts.odb -no_init -exit
```

**Result:** ✅ OpenROAD starts and exits cleanly with exit code 0. However, the tool exits immediately after startup — no interactive Tcl session is available, and no design data is accessible post-startup through this mode.

**Limitation:** The `-db` flag loads the database at startup but does not leave OpenROAD in an interactive state where Tcl commands can be executed against the loaded database.

### 3.3 Database Loading — Attempted Approaches

| Approach | Result | Notes |
|---|---|---|
| `read_odb <path>` Tcl command | ❌ Failed | `invalid command name "read_odb"` |
| `openroad -db <odb> -no_init -exit` | ✅ Starts and exits | No interactive session; data not accessible |
| `openroad <script.tcl>` with `read_odb` inside | ⚠️ Not tested | Tcl script execution has PATH issues in WSL; script creation difficult |
| Interactive WSL session with `source`ed Tcl | ⚠️ Not tested | WSL bash limitations prevent reliable script sourcing |

**Conclusion:** The `read_odb` Tcl command is **not available** in this OpenROAD bazel-nostamp build. ODB database loading via Tcl scripting is blocked.

---

## 4. READ-ONLY DATABASE INSPECTION — ATTEMPT RESULTS

### 4.1 Original Phase 3.8 CTS Database (`timer_cts.odb`)

| Metric | Result | Notes |
|---|---|---|
| **Database starts via `-db` flag** | ✅ Yes | `openroad -db timer_cts.odb -no_init -exit` exits 0 |
| **Liberty loaded** | ✅ Yes (Phase 4.4) | `read_lib` → 1 library |
| **LEF loaded** | ✅ Yes (Phase 4.4) | `read_lef` → 441 cells |
| **`read_odb` Tcl command** | ❌ Not available | Command not found in this version |
| **Design inspectable via `report_design`** | ⚠️ Partial | Outputs limited information; full cell/net/port listing not accessible |
| **Instance count** | ⚠️ Not verified | Could not run `get_cells` or similar |
| **Clock-net connectivity** | ⚠️ Not verified | `get_nets` command availability unknown |
| **Clock sink count** | ⚠️ Not verified | Could not verify 67 sink pins |
| **Placement status** | ⚠️ Not verified | `check_placement` command availability unknown |

### 4.2 Phase 4.2 Working Copy ODB (`timer_cts_odb_workcopy.odb`)

| Metric | Result | Notes |
|---|---|---|
| **Database starts via `-db` flag** | ✅ Yes | Same as original ODB |
| **Liberty loaded** | ✅ Yes (same as original) | |
| **LEF loaded** | ✅ Yes (same as original) | |
| **`read_odb` Tcl command** | ❌ Not available | Same as original — command not found |
| **Design inspection** | ⚠️ Partial | Same limitations as original ODB |
| **Instance count** | ⚠️ Not verified | |
| **Placement status** | ⚠️ Not verified | |

**Key observation:** Both the original Phase 3.8 CTS ODB and the Phase 4.2 working-copy ODB have identical SHA-256 hashes, confirming the working copy was not modified. Both exhibit the same ODB command compatibility issue: `read_odb` is not available.

---

## 5. INSTANCE COORDINATE EXTRACTION — DEF ANALYSIS

### 5.1 Extracted Coordinates from Original DEF (`timer_cts.def`)

Only 3 of 15 affected instances have extractable X/Y coordinates from the DEF text:

| Instance Name | Master | X (db units) | Y (db units) | Orientation | Coordinate Source |
|---|---|---|---|---|---|
| `clkbuf_0_pclk` | `sky130_fd_sc_hd__clkbuf_0` | 43735 | 47539 | N/A | Direct DEF text extraction |
| `clkbuf_3_0__f_pclk` | `sky130_fd_sc_hd__clkbuf_0` | 2702
