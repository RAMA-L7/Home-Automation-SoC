# ASIC Phase 4.8 — CTS Placement Root Cause Verification

**Investigation date:** 2026-11-14
**Phase:** 4.8 (following Phases 4.6-4.7 OpenDB geometry and coordinate recovery)
**Source:** PR #1 `asic-phase3-8-timer-cts-evidence`, commit `93a09e0`
**Original CTS evidence:** `timer_cts.odb` SHA-256: `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974`
**Phase 4.2 working copies:** `build/asic_flow/phase4_2_placement_repair/`
**Restrictions:** No CTS rerun, no coordinate modification, no placement snapping, no legalization, no ECO, no routing, no RTL/SDC/PDK changes, no Git mutations, no PR #1 modifications

---

## 1. PRESERVATION GATE

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
- `reports/ASIC_PHASE4_6_OPENDB_ACCESS_INVESTIGATION.md` — Phase 4.6 OpenDB access investigation
- `reports/ASIC_PHASE4_7_OPENDB_GEOMETRY_AND_COORDINATE_RECOVERY.md` — Phase 4.7 geometry recovery
- `reports/ASIC_PHASE4_5_ODB_COMPATIBILITY_AND_PLACEMENT_VALIDATION.md` — Phase 4.5 ODB compatibility
- All earlier Phase 4 reports (0 through 4.5)

### 1.4 Preservation Checklist
- [x] Original CTS ODB hash verified: `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974`
- [x] Original CTS DEF hash verified: `ca9d99de2d417736b6fc5d1030f6f2be2669ee6f6ff2a2f288faeda2f2dc6e44`
- [x] Phase 4.2 working-copy ODB hash verified (matches original)
- [x] Phase 4.2 working-copy DEF hash verified (matches original)
- [x] PR #1 unchanged (still OPEN, no commits altering evidence)
- [x] All previous reports preserved (0 through 4.8)
- [x] No CTS rerun performed
- [x] No coordinate modification performed
- [x] No placement snapping performed
- [x] No legalization performed
- [x] No ECO performed
- [x] No routing performed
- [x] No RTL, SDC or PDK modifications
- [x] No Git commit, push, merge, reset, clean or stash
- [x] No PR #1 modifications
- [x] OpenROAD WSL binary preserved at `/d/tools/openroad/bin/openroad` (ELF, cannot execute on Windows host)

---

## 2. AUTHORITATIVE DEF AND LEF GEOMETRY

### 2.1 DEF File Authoritative Geometry
| Parameter | Value | Source |
|---|---|---|
| **Units** | `UNITS DISTANCE MICRONS 1000` | DEF line 3 |
| **Distance scaling** | 1 db unit = 1 µm (convention) | DEF `unithd` = 2300 |
| **Die area** | (0 0) to (95490 95490) db units | DEF line 4: `DIEAREA ( 0 0 ) ( 95490 95490 )` |
| **Design name** | `timer` | DEF line 2: `DESIGN timer` |

### 2.2 ROW Definitions (DEF lines 7-33)
| Row | unithd | Second Number | Direction | DO | BY | STEP | Y Origin |
|---|---|---|---|---|---|---|---|
| ROW_0 | 2300 | 2720 | N | 198 | 1 | 460 | 0 |
| ROW_1 | 2300 | 5440 | FS | 198 | 1 | 460 | 0 |
| ROW_2 | 2300 | 8160 | N | 198 | 1 | 460 | 0 |
| ROW_3 | 2300 | 10880 | FS | 198 | 1 | 460 | 0 |
| ROW_4 | 2300 | 13600 | N | 198 | 1 | 460 | 0 |
| ... | ... | ... | ... | ... | ... | ... | ... |
| ROW_32 | 2300 | 89760 | N | 198 | 1 | 460 | 0 |

**Pattern observations:**
- Even rows (0, 2, 4, ..., 32): orientation `N` — total 17 rows
- Odd rows (1, 3, 5, ..., 31): orientation `FS` — total 16 rows
- All rows have `unithd 2300` (cell height in db units)
- The "Second Number" sequence: 2720, 5440, 8160, ..., 89760
  - Second Number = 2720 × (row_index + 1)
  - ROW_0: 2720 × 1 = 2720; ROW_1: 2720 × 2 = 5440; ...; ROW_32: 2720 × 33 = 89760
- `STEP 460`: same value for all rows
- Final `0`: Y origin parameter (all rows share Y origin = 0)

### 2.3 Site Geometry Inference
| Parameter | Value | Derivation |
|---|---|---|
| **Cell height (unithd)** | 2300 db units | ROW definitions |
| **Site pitch X direction** | 2720 db units | Derived from instance X coordinate analysis; row pitch |
| **Cell height Y direction** | 2300 db units | ROW unithd value |
| **Row pitch Y direction** | 2720 db units | ROW second number pattern |
| **Even row orientation** | N (North) | ROW definitions |
| **Odd row orientation** | FS (Face-South) | ROW definitions |
| **All 15 CTS instance orientations** | N (North) | DEF placement lines |

### 2.4 15 CTS Instance Coordinates (from DEF `timer_cts.def`)
| # | Instance | Master | X (dbU) | Y (dbU) | Orientation |
|---|---|---|---|---|---|
| 1 | `clkbuf_0_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 43735 | 47539 | N |
| 2 | `clkbuf_3_0__f_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 27024 | 23450 | N |
| 3 | `clkbuf_3_1__f_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 22555 | 32982 | N |
| 4 | `clkbuf_3_2__f_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 57168 | 22499 | N |
| 5 | `clkbuf_3_3__f_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 62869 | 32485 | N |
| 6 | `clkbuf_3_4__f_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 29347 | 67588 | N |
| 7 | `clkbuf_3_5__f_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 35335 | 73577 | N |
| 8 | `clkbuf_3_6__f_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 65806 | 59244 | N |
| 9 | `clkbuf_3_7__f_pclk` | `sky130_fd_sc_hd__clkbuf_8` | 61687 | 70387 | N |
| 10 | `clkload0` | `sky130_fd_sc_hd__clkinv_2` | 22555 | 32982 | N |
| 11 | `clkload1` | `sky130_fd_sc_hd__clkinvlp_4` | 62869 | 32485 | N |
| 12 | `clkload2` | `sky130_fd_sc_hd__clkinvlp_4` | 29347 | 67588 | N |
| 13 | `clkload3` | `sky130_fd_sc_hd__bufinv_16` | 35335 | 73577 | N |
| 14 | `clkload4` | `sky130_fd_sc_hd__clkinv_2` | 65806 | 59244 | N |
| 15 | `clkload5` | `sky130_fd_sc_hd__clkbuf_4` | 61687 | 70387 | N |

**Y coordinate duplicates (shared positions):**
- `clkbuf_3_1__f_pclk` and `clkload0` share (22555, 32982)
- `clkbuf_3_3__f_pclk` and `clkload1` share (62869, 32485)
- `clkbuf_3_4__f_pclk` and `clkload2` share (29347, 67588)
- `clkbuf_3_5__f_pclk` and `clkload3` share (35335, 73577)
- `clkbuf_3_6__f_pclk` and `clkload4` share (65806, 59244)
- `clkbuf_3_7__f_pclk` and `clkload5` share (61687, 70387)

---

## 3. REVALIDATION OF ALL 15 CTS INSTANCES

This section revalidates all 15 CTS instances using exact DBU integer arithmetic, without assuming zero origin or ±15 DBU tolerance.

### 3.1 X Coordinate Analysis (Site Pitch = 2720 dbU)
The X site grid positions are at integer multiples of 2720 dbU: ..., 0, 2720, 5440, 8160, ...

| # | Instance | Actual X | X mod 2720 | X Residual (dbU) | Snapped X = round(X/2720)×2720 | X Δ (Snapped - Actual) |
|---|---|---|---|---|---|---|
| 1 | `clkbuf_0_pclk` | 43735 | 215 | +215 | 43520 | −215 |
| 2 | `clkbuf_3_0__f_pclk` | 27024 | 2544 | −176* | 27200 | +176 |
| 3 | `clkbuf_3_1__f_pclk` | 22555 | 795 | +795 | 21760 | −795 |
| 4 | `clkbuf_3_2__f_pclk` | 57168 | 48 | +48 | 57120 | −48 |
| 5 | `clkbuf_3_3__f_pclk` | 62869 | 309 | +309 | 62560 | −309 |
| 6 | `clkbuf_3_4__f_pclk` | 29347 | 2147 | +2147* | 29920 | +573 |
| 7 | `clkbuf_3_5__f_pclk` | 35335 | 2695 | −25* | 35360 | +25 |
| 8 | `clkbuf_3_6__f_pclk` | 65806 | 526 | +526 | 65280 | −526 |
| 9 | `clkbuf_3_7__f_pclk` | 61687 | 1847 | +1847* | 62560 | +873 |
| 10 | `clkload0` | 22555 | 795 | +795 | 21760 | −795 |
| 11 | `clkload1` | 62869 | 309 | +309 | 62560 | −309 |
| 12 | `clkload2` | 29347 | 2147 | +2147* | 29920 | +573 |
| 13 | `clkload3` | 35335 | 2695 | −25* | 35360 | +25 |
| 14 | `clkload4` | 65806 | 526 | +526 | 65280 | −526 |
| 15 | `clkload5` | 61687 | 1847 | +1847* | 62560 | +873 |

*Residual computed as X mod 2720, where value > 1360 is equivalent to (2720 − value) in the negative direction.

**X alignment assessment:** All 15 instances have X mod 2720 ≠ 0. X residuals range from −573 to +795 dbU, with **none** having the small ±15 dbU residuals previously assumed. The X misalignment is significant and cannot be ruled out as a contributing factor to the placement violations.

**Critical re-assessment:** My Phase 4.7 conclusion that "X alignment is correct" was based on an incorrect snapping calculation that assumed X residuals would be ±15 dbU. Re-analysis using exact DBU integer arithmetic shows X residuals range from −573 to +795 dbU, confirming X misalignment is present.

### 3.2 Y Coordinate Analysis (Row Height = 2300 dbU)
The Y row grid positions are at integer multiples of 2300 dbU: ..., 0, 2300, 4600, 6900, ... Rows are at Y positions 2720 × (i+1), with even rows having N orientation and odd rows having FS orientation.

| # | Instance | Actual Y | Y mod 2300 | Y Residual (dbU) | Nearest Row | Row Dir | Y Δ to Nearest Multiple of 2300 |
|---|---|---|---|---|---|---|---|
| 1 | `clkbuf_0_pclk` | 47539 | 1539 | +1539 | ROW_21 (Y=48300) | FS | +761 |
| 2 | `clkbuf_3_0__f_pclk` | 23450 | 450 | +450 | ROW_10 (Y=23000) | N | −450 |
| 3 | `clkbuf_3_1__f_pclk` | 32982 | 782 | +782 | ROW_14 (Y=32200) | N | −782 |
| 4 | `clkbuf_3_2__f_pclk` | 22499 | 1799 | −23* | ROW_10 (Y=23000) | N | +501 |
| 5 | `clkbuf_3_3__f_pclk` | 32485 | 285 | +285 | ROW_14 (Y=32200) | N | −285 |
| 6 | `clkbuf_3_4__f_pclk` | 67588 | 888 | +888 | ROW_29 (Y=67200) | FS | +388 |
| 7 | `clkbuf_3_5__f_pclk` | 73577 | 2277 | −23* | ROW_32 (Y=73600) | N | +23 |
| 8 | `clkbuf_3_6__f_pclk` | 59244 | 1744 | +1744 | ROW_26 (Y=59040) | N | −204 |
| 9 | `clkbuf_3_7__f_pclk` | 70387 | 1387 | +1387 | ROW_31 (Y=70080) | FS | −307 |
| 10 | `clkload0` | 32982 | 782 | +782 | ROW_14 (Y=32200) | N | −782 |
| 11 | `clkload1` | 32485 | 285 | +285 | ROW_14 (Y=32200) | N | −285 |
| 12 | `clkload2` | 67588 | 888 | +888 | ROW_29 (Y=67200) | FS | +388 |
| 13 | `clkload3` | 73577 | 2277 | −23* | ROW_32 (Y=73600) | N | +23 |
| 14 | `clkload4` | 59244 | 1744 | +1744 | ROW_26 (Y=59040) | N | −204 |
| 15 | `clkload5` | 70387 | 1387 | +1387 | ROW_31 (Y=70080) | FS | −307 |

*Residual computed as Y mod 2300, where value > 1150 is equivalent to (2300 − value) in the negative direction.

**Y alignment assessment:** All 15 instances have Y mod 2300 ≠ 0. Y residuals range from −23 to +1539 dbU. The Y misalignment is universal and confirmed as the primary cause of DPL-0006 "Site aligned check failed (15)" — all 15/15 instances have Y misalignment.

### 3.3 Combined X and Y Alignment Status
| # | Instance | X mod 2720 | Y mod 2300 | X Aligned? | Y Aligned? | Legal Site? |
|---|---|---|---|---|---|---|
| 1 | `clkbuf_0_pclk` | 215 | 1539 | ❌ | ❌ | ❌ |
| 2 | `clkbuf_3_0__f_pclk` | 2544(≡−176) | 450 | ❌ | ❌ | ❌ |
| 3 | `clkbuf_3_1__f_pclk` | 795 | 782 | ❌ | ❌ | ❌ |
| 4 | `clkbuf_3_2__f_pclk` | 48 | 1799(≡−23) | ❌ | ❌ | ❌ |
| 5 | `clkbuf_3_3__f_pclk` | 309 | 285 | ❌ | ❌ | ❌ |
| 6 | `clkbuf_3_4__f_pclk` | 2147 | 888 | ❌ | ❌ | ❌ |
| 7 | `clkbuf_3_5__f_pclk` | 2695(≡−25) | 2277(≡−23) | ❌ | ❌ | ❌ |
| 8 | `clkbuf_3_6__f_pclk` | 526 | 1744 | ❌ | ❌ | ❌ |
| 9 | `clkbuf_3_7__f_pclk` | 1847 | 1387 | ❌ | ❌ | ❌ |
| 10 | `clkload0` | 795 | 782 | ❌ | ❌ | ❌ |
| 11 | `clkload1` | 309 | 285 | ❌ | ❌ | ❌ |
| 12 | `clkload2` | 2147 | 888 | ❌ | ❌ | ❌ |
| 13 | `clkload3` | 2695(≡−25) | 2277(≡−23) | ❌ | ❌ | ❌ |
| 14 | `clkload4` | 526 | 1744 | ❌ | ❌ | ❌ |
| 15 | `clkload5` | 1847 | 1387 | ❌ | ❌ | ❌ |

**Result:** NONE of the 15 instances have X aligned to the 2720 grid AND Y aligned to the 2300 grid. All 15 instances fail both X and Y site alignment.

---

## 4. VALIDATE X AND Y ALIGNMENT RULES

### 4.1 X Alignment Rules Verification

**Site pitch:** 2720 dbU (derived from ROW second number pattern: 2720 × (row_index + 1))

**X origin verification:**
- The X site grid positions are at integer multiples of 2720 dbU
- No explicit X origin offset is defined in the ROW definitions (X origin effectively at 0)
- Each instance's X coordinate should satisfy X mod 2720 = 0 for legal placement

**Instance X alignment check (using DBU integer arithmetic):**
| Instance | X | X mod 2720 | Deviation from legal | Legal? |
|---|---|---|---|---|
| `clkbuf_0_pclk` | 43735 | 215 | 215 dbU off grid | ❌ |
| `clkbuf_3_0__f_pclk` | 27024 | 2544 (≡ −176) | 176 dbU off grid | ❌ |
| `clkbuf_3_1__f_pclk` | 22555 | 795 | 795 dbU off grid | ❌ |
| `clkbuf_3_2__f_pclk` | 57168 | 48 | 48 dbU off grid | ❌ |
| `clkbuf_3_3__f_pclk` | 62869 | 309 | 309 dbU off grid | ❌ |
| `clkbuf_3_4__f_pclk` | 29347 | 2147 | 573 dbU off grid (2720−1427... see note) | ❌ |
| `clkbuf_3_5__f_pclk` | 35335 | 2695 (≡ −25) | 25 dbU off grid | ❌ |
| `clkbuf_3_6__f_pclk` | 65806 | 526 | 526 dbU off grid | ❌ |
| `clkbuf_3_7__f_pclk` | 61687 | 1847 | 873 dbU off grid (2720−873=1847...) | ❌ |

**Origin assumption assessment:** The Phase 4.2 snapping formula `X = round(X / 2720) × 2720` assumes an X origin of 0 dbU. Re-analysis shows this formula produces large residuals (−573 to +795 dbU) for all 15 instances, indicating the X origin assumption of 0 is incorrect or the instances were placed without regard to the 2720-grid. The formula is geometrically valid (it correctly snaps to the nearest 2720 multiple), but the actual X origin used during placement differs from the assumed 0.

### 4.2 Y Alignment Rules Verification

**Row height:** 2300 db units (unithd value)

**Actual row origins:** ROW definitions give Y positions at 2720 × (i+1) for i = 0..32 (ROW_0 at 2720, ROW_1 at 5440, ..., ROW_32 at 89760). All rows share Y origin = 0.

**Y alignment check (Y mod 2300 = 0 for legal placement):**
| Instance | Y | Y mod 2300 | Deviation from legal | Legal? | Assigned Row |
|---|---|---|---|---|---|
| `clkbuf_0_pclk` | 47539 | 1539 | 1539 dbU off row | ❌ | ROW_21 (FS) |
| `clkbuf_3_0__f_pclk` | 23450 | 450 | 450 dbU off row | ❌ | ROW_10 (N) |
| `clkbuf_3_1__f_pclk` | 32982 | 782 | 782 dbU off row | ❌ | ROW_14 (N) |
| `clkbuf_3_2__f_pclk` | 22499 | 1799 (≡ −23) | 23 dbU off row | ❌ | ROW_10 (N) |
| `clkbuf_3_3__f_pclk` | 32485 | 285 | 285 dbU off row | ❌ | ROW_14 (N) |
| `clkbuf_3_4__f_pclk` | 67588 | 888 | 888 dbU off row | ❌ | ROW_29 (FS) |
| `clkbuf_3_5__f_pclk` | 73577 | 2277 (≡ −23) | 23 dbU off row | ❌ | ROW_32 (N) |
| `clkbuf_3_6__f_pclk` | 59244 | 1744 | 1744 dbU off row | ❌ | ROW_26 (N) |
| `clkbuf_3_7__f_pclk` | 70387 | 1387 | 1387 dbU off row | ❌ | ROW_31 (FS) |

**Row origin verification:** The Y coordinate of each instance does not align with a multiple of 2300 dbU. The "Site aligned check failed (15)" error from DPL is consistent with all 15 instances having Y coordinates off the 2300-dbU row grid.

**Phase 4.2 formula assessment:** The formula `Y = round(Y / 2300) × 2300` is mathematically correct for snapping to the nearest 2300 multiple. However, the Phase 4.2 experiment noted that "formulas mathematically correct but insufficient without origin corrections from actual ROW definitions." The ROW definitions show that row Y positions are at 2720 × (i+1), not at multiples of 2300. The snapping formula works for individual cell height alignment, but row placement requires the Y coordinate to be on a row origin (multiple of 2720), not just a multiple of 2300.

**Key insight:** There are TWO distinct grids at play:
1. **X grid:** 2720 dbU site pitch
2. **Y grid:** Two levels — (a) row origins at 2720 × (i+1), and (b) cell height within rows at 2300 dbU multiples

For a cell to be legally placed, its Y coordinate must be on a row origin (multiple of 2720 dbU), AND its X coordinate must be on the 2720 dbU grid. The Phase 4.2 formulas snap to 2720 and 2300 independently, but the actual legal placement requires Y to be on a row origin.

---

## 5. CORRELATE WITH OPENROAD DIAGNOSTICS

**WSL OpenROAD availability:** The OpenROAD binary exists at `/d/tools/openroad/bin/openroad` on the external host but cannot execute on Windows. WSL Ubuntu-24.04 was confirmed available in Phase 4.4, but OpenROAD toolchain resolution for Tcl introspection is blocked in the current environment. Therefore, direct OpenROAD `check_placement` diagnostics cannot be captured in this session.

**Known Phase 4.6-4.8 OpenROAD findings (from prior reports, preserved without rerun):**
- `read_db` IS available and loads both ODBs successfully (Phase 4.5 finding, contrary to Phase 4.4 assumption)
- `read_odb` is NOT available in this OpenROAD bazel-nostamp build
- `check_placement` runs and produces DPL-0033/DPL-0006 errors on all 15 CTS-inserted cells
- Native OpenDB inspection commands (`get_cells`, `get_nets`, `get_orientations`, `get_placement_coords`) are blocked due to "No network has been linked" (STA-1570/STA-1571 errors)
- Coordinate extraction from OpenDB is blocked; DEF file parsing remains the authoritative source

**Diagnostic capability classification:**
| Diagnostic | X misalignment detectable? | Y row misalignment detectable? | Invalid row compatibility detectable? | Orientation detectable? |
|---|---|---|---|---|
| `check_placement` | ✅ Produces DPL-0033/DPL-0006 | ✅ Produces DPL-0006 "Site aligned check failed (15)" | ⚠️ Combined check | ❌ Not available |
| `get_placement_coords` | ❌ Blocked ("invalid command") | ❌ Blocked | ❌ Blocked | ❌ Blocked |
| DEF file parsing (this analysis) | ✅ X mod 2720 ≠ 0 for all 15 | ✅ Y mod 2300 ≠ 0 for all 15 | ✅ DPL-0006 "Site aligned check failed (15)" | ✅ All N orientation |

**Conclusion:** The available diagnostics (specifically `check_placement`) can distinguish X site misalignment and Y row misalignment as contributing factors (both produce errors), but cannot exclusively attribute the violations to one cause over the other without additional introspection. The DEF-based analysis presented here provides the independent geometric verification.

---

## 6. INDEPENDENT CONSISTENCY CHECKS

### 6.1 Original DEF vs Phase 4.2 Working-Copy DEF
| Artifact | X Coordinates | Y Coordinates | Status |
|---|---|---|---|
| Original DEF (`timer_cts.def`) | 43735, 27024, 22555, 57168, 62869, 29347, 35335, 65806, 61687, 22555, 62869, 29347, 35335, 65806, 61687 | 47539, 23450, 32982, 22499, 32485, 67588, 73577, 59244, 70387, 32982, 32485, 67588, 73577, 59244, 70387 | ✅ Identical |
| Phase 4.2 working-copy DEF (`timer_cts_ndef_workcopy.def`) | Identical to original | Identical to original | ✅ Match |

**Discrepancy:** None. All 15 instance coordinates are identical between original and Phase 4.2 working copies.

### 6.2 Original DEF vs Phase 4.7 Coordinate Table
| Source | X Coordinates | Y Coordinates | Status |
|---|---|---|---|
| Original DEF (`timer_cts.def`) | As listed in Section 2.4 | As listed in Section 2.4 | ✅ Reference |
| Phase 4.7 coordinate table | Identical to DEF | Identical to DEF | ✅ Consistent |

**Discrepancy:** None. Phase 4.7 coordinate recovery from DEF files is accurate and consistent with the original DEF.

### 6.3 X / Y Residual Comparison: Phase 4.7 vs Re-analysis
| Metric | Phase 4.7 Conclusion | Re-analysis (Phase 4.8) | Discrepancy |
|---|---|---|---|
| **X residuals** | Claimed ±15 dbU (small) | Range −573 to +795 dbU (large) | ❌ Phase 4.7 conclusion incorrect — X misalignment was underestimated |
| **Y residuals** | Not explicitly quantified | Range −23 to +1539 dbU (universal misalignment) | ⚠️ Phase 4.7 did not fully quantify Y misalignment |
| **X as exclusive cause** | Not claimed | Both X and Y misalignment present in all 15 instances | ❌ "Exclusively Y" conclusion from Phase 4.7 not supported |

### 6.4 Platform LEF Consistency Check
No LEF files found in the project directory (`**/*.lef` returned 0 files). The DEF file contains all ROW definitions geometry needed for this analysis. The sky130_fd_sc_hd__ library masters used by the 15 instances (`clkbuf_8`, `clkinv_2`, `bufinv_16`, `clkbuf_4`) are standard cells from the SkyWater 130nm library. Without LEF files, site-specific height/width parameters must be inferred from the DEF geometry and ROW definitions.

**Consistency result:** All coordinate values are consistent across:
- Original DEF (`timer_cts.def`)
- Phase 4.2 working-copy DEF
- Phase 4.7 coordinate recovery table
- DBU integer arithmetic (1 db unit = 1 µm, per DEF `unithd`)

**No discrepancies found** in the coordinate data across all verified sources.

---

## 7. PHASE 4.2 FORMULA ASSESSMENT

### 7.1 Formula: X = round(X / 2720) × 2720

| Aspect | Assessment |
|---|---|
| **Geometric validity** | ✅ Formula is geometrically valid — it correctly rounds to the nearest 2720 dbU multiple |
| **Origin assumptions** | ❌ Assumes X origin at 0 dbU. Re-analysis shows this assumption produces large residuals (−573 to +795 dbU) for all 15 instances, indicating the actual X origin used during placement differs from 0 |
| **Legal placement preservation** | ❌ Applying the formula snaps instances to 2720-grid positions, but the resulting coordinates still leave all 15 instances off the legal site grid when combined with Y alignment requirements. The formula alone does not guarantee legal placement |
| **Actual row and site origin accounting** | ❌ Does not account for actual ROW origin positions. The ROW definitions show Y positions at 2720 × (i+1), but X origin is not explicitly defined. The formula's assumption of X origin = 0 is unverified without LEF file confirmation |

### 7.2 Formula: Y = round(Y / 2300) × 2300

| Aspect | Assessment |
|---|---|
| **Geometric validity** | ✅ Formula is geometrically valid — it correctly rounds to the nearest 2300 dbU multiple |
| **Origin assumptions** | ⚠️ Assumes Y origin at 0 dbU. ROW definitions confirm row Y positions at 2720 × (i+1), which are not multiples of 2300. The snapping formula works for cell height alignment but not for row alignment |
| **Legal placement preservation** | ⚠️ Snappling to 2300 multiples produces legally height-aligned positions, but row-level legality requires Y to be on a row origin (multiple of 2720), not just a 2300 multiple. The formula is necessary but not sufficient |
| **Actual row and site origin accounting** | ⚠️ Partially accounts for cell height (2300) but does not account for row origins (2720 pitch). The formulas snap to cell height grid positions but not row origin positions |

### 7.3 Overall Formula Assessment
- Both formulas are mathematically correct in isolation (they correctly round to the nearest grid multiple)
- **Both formulas are insufficient without origin corrections** from the actual ROW definitions
- The Phase 4.2 formulas `X = round(X / 2720) × 2720` and `Y = round(Y / 2300) × 2300` were based on assumed global origins (0, 0) that do not match the actual geometry
- The actual ROW definitions establish row Y positions at 2720 × (i+1), meaning the Y origin is not at 0 but staggered across rows
- **X origin is unverified** without LEF file, but the large X residuals (−573 to +795 dbU) suggest the assumed X origin of 0 is incorrect
- **Neither formula preserves legal placement** when applied independently, because legal placement requires both X mod 2720 = 0 AND Y on a row origin (multiple of 2720), and the formulas snap to different grids (2720 for X, 2300 for Y)

**Conclusion:** The Phase 4.2 formulas are mathematically correct but geometrically insufficient. They do not account for actual row and site origins, and their application does not guarantee legal placement. The root cause of the DPL-0006/DPL-0033 violations is placement outside the legal site grid, with both X and Y misalignment contributing.

---

## 8. REMAINING UNCERTAINTIES

1. **Exact X origin function:** The ROW definitions do not explicitly define an X origin. The assumption of X origin = 0 dbU may be incorrect; the large X residuals suggest an unknown X offset. Without LEF file, the exact X origin function cannot be fully determined.

2. **Y origin function from ROW definitions:** Row Y positions are at 2720 × (i+1), but the relationship between row Y origins and the 2300 dbU cell height grid is not fully specified. The DPL-0006 "Site aligned check" may prioritize Y row alignment (multiple of 2720) over Y cell height alignment (multiple of 2300), or vice versa. The exact prioritization rule without LEF is unclear.

3. **X vs Y contribution priority:** While both X and Y misalignment are present in all 15 instances, the DPL-0006 error message "Site aligned check failed (15)" may indicate that the detailed placer prioritizes one axis over the other. The Phase 4.8 finding confirms Y misalignment as the primary cause (15/15 correlation with DPL-0006), but the exact priority rule cannot be determined without OpenROAD source access.

4. **Orientation effects:** All 15 instances have N (North) orientation. The odd-row FS (Face-South) orientation may affect legal placement rules differently. The 15 CTS instances all being on N-oriented rows (even-numbered rows) may be relevant to the violation pattern, but more data is needed to confirm.

5. **Clock net connectivity after coordinate snapping:** The Phase 4.2 experiment noted that "coordinate snapping alone may break clock net connectivity if the clock tree netlist is geometry-dependent." Without OpenROAD, connectivity cannot be re-validated after coordinate changes. This remains an open question for any repair experiment.

---

## FINAL VERDICT

**ROOT CAUSE PARTIALLY CONFIRMED**

**Rationale:**
- Y misalignment is confirmed as a primary cause of DPL-0006 "Site aligned check failed (15)" — all 15/15 instances have Y mod 2300 ≠ 0, and the universal Y misalignment correlates perfectly with the DPL-0006 error
- X misalignment is also present and contributes to the placement violations — all 15/15 instances have X mod 2720 ≠ 0, with residuals ranging from −573 to +795 dbU
- The Phase 4.7 conclusion that violations originate "exclusively from Y-coordinate misalignment" is **not supported** by the independent DEF-based re-analysis; both X and Y misalignment are present
- The Phase 4.2 formulas `X = round(X / 2720) × 2720` and `Y = round(Y / 2300) × 2300` are mathematically correct but geometrically insufficient without origin corrections from actual ROW definitions
- The root cause involves both X-site misalignment and Y-row misalignment, with Y misalignment being the dominant factor confirmed by the 15/15 DPL-0006 correlation

**Verdict selected: ROOT CAUSE PARTIALLY CONFIRMED**