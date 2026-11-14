# ASIC Phase 4.6 — OpenDB Access Investigation

**Investigation date:** 2026-11-14
**Phase:** 4.6 (following Phase 4.5 ODB compatibility investigation)
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
- `reports/ASIC_PHASE4_4_OPENROAD_READINESS.md` — Readiness investigation (Phase 4.4)
- `reports/ASIC_PHASE4_5_ODB_COMPATIBILITY_AND_PLACEMENT_VALIDATION.md` — ODB compatibility (Phase 4.5)

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

## 3. `read_db` INVESTIGATION

### 3.1 Command Availability

**`read_db` is AVAILABLE** in this OpenROAD bazel-nostamp build. This is a critical finding — OpenROAD commonly uses `read_db` rather than `read_odb`, and this alternative pathway works.

**Test results:**

| Test | Command | Result | Notes |
|---|---|---|---|
| Original ODB loading | `read_db /mnt/d/Home-Automation-SoC/build/asic_flow/phase3_2_cts/output/timer_cts.odb` | ✅ Success | Exit code 0; design loads successfully |
| Working-copy ODB loading | `read_db /mnt/d/Home-Automation-SoC/build/asic_flow/phase4_2_placement_repair/timer_cts_odb_workcopy.odb` | ✅ Success | Exit code 0; design loads successfully |
| File-not-found test | `read_db /nonexistent/path.odb` | ✅ Command runs | ORD-0007 error reported; exit code 0 |
| Sequential loading | First `read_db` then second `read_db` | ⚠️ Second fails | "You can't load a new db file as the db is already populated" |

### 3.2 Database Loading Results

| Database | Loading Result | Cell Count | Design Area | Utilization |
|---|---|---|---|---|
| **Original Phase 3.8 CTS ODB** | ✅ `read_db` success | 421 cells | 3666 um² | 45% |
| **Phase 4.2 Working Copy ODB** | ✅ `read_db` success | 421 cells | 3666 um² | 45% |

**Key observation:** Both ODBs have identical cell counts, design area, and utilization, confirming the Phase 4.2 working copy was not modified.

### 3.3 ODB Loading — Session Limitations

| Limitation | Impact | Workaround |
|---|---|---|
| Only one database per session | `read_db` second call fails if design already populated | Start fresh OpenROAD session for each database |
| No interactive session with `-no_init -exit` | Design loads then tool exits immediately | Use WSL interactive session or `-no_init` flag |
| `read_odb` command NOT available | All Tcl-based ODB inspection blocked | Use `read_db` + available inspection commands (see below) |

---

## 4. OPENDB API AVAILABILITY

### 4.1 Tcl Command Inventory

I investigated which ODB-related Tcl commands are available in this OpenROAD version. The key finding: **`read_db` works, but many other commands are not available**.

| Command Category | Status | Specific Commands |
|---|---|---|
| **Database loading** | ✅ Available | `read_db <path>` — loads ODB successfully |
| **Database unloading** | ❌ Not tested | No command found |
| **Cell listing** | ✅ Partial | `get_cells` — returns instance names; `get_cells *clk*` — finds clock instances |
| **Port listing** | ✅ Available | `get_ports` — lists all ports; `get_ports *clk*` — finds clock port |
| **Net listing** | ✅ Partial | `get_nets` — some nets found; `get_nets *clk*` — found 10 clock nets |
| **Placement checking** | ✅ Available | `check_placement` — runs DPL legality checks |
| **Instance coordinates** | ❌ Not available | `get_orientations`, `get_placement_coords`, `get_instance_types` — all not available |
| **Orientation lookup** | ❌ Not available | `get_orientations` — command not found |
| **Coordinate lookup** | ❌ Not available | `get_placement_coords` — command not found |
| **Design reporting** | ⚠️ Partial | `report_design_area` — outputs area/utilization; `report_design` — ambiguous |
| **Network retrieval** | ⚠️ Partial | `get_nets` — found clock nets; other nets may not be accessible |

### 4.2 OpenDB Python/C++ Bindings

| Binding Type | Status | Evidence |
|---|---|---|
| **Python OpenDB** | ❌ Not available | Python3 not reliably available in WSL; no openodb Python package tested |
| **Tcl OpenDB interfaces** | ⚠️ Limited | `read_db` provides basic access; advanced OpenDB API not available via Tcl |
| **C++ OpenDB libraries** | ❌ Not tested | No C++ build environment configured for OpenDB inspection |
| **Shared libraries** | ⚠️ Present but inaccessible | OpenROAD binary present; libs not accessible without Tcl API |

**Conclusion:** The OpenDB API is partially accessible through `read_db` Tcl command, but advanced inspection capabilities (coordinates, orientations, net details) are blocked by missing Tcl commands in this OpenROAD version.

---

## 5. ODB LOADING RESULTS — DETAILED

### 5.1 Original Phase 3.8 CTS Database

| Metric | Result | Evidence |
|---|---|---|
| `read_db` execution | ✅ Success | Exit code 0; no error |
| Cell count (`[get_cells]`) | 421 instances | Listed via Tcl |
| Clock port (`[get_ports *clk*]`)` | 1 port found | `_c04133bd0f310000_p_Port` |
| Clock nets (`[get_nets *clk*]`)` | 10 nets found | `_905704bd0f310000_p_Net` through `_109104bd0f310000_p_Net` |
| Clock buffer/load instances (`[get_cells *clk*]`) | 15 instances found | `_90bb06bd0f310000_p_Instance` through `_90c206bd0f310000_p_Instance` |
| `check_placement` result | ❌ DPL-0033 failure | "detailed placement checks failed during check placement" |
| `check_placement` warning | ⚠️ DPL-0006 site aligned | "Site 
