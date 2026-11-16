# ASIC Stage 1 — Engineering Ownership Plan

**Date:** 2026-11-15  
**Purpose:** Assign verified engineering owners for the nine unassigned roles; use `UNASSIGNED` when no verified owner exists  
**Current main HEAD:** `d6791cdb1742964033fadc63fa508b1ececf0c3b`  
**Stage 1 status:** READY FOR APPROVAL, NOT COMPLETE  

> **Rule 15:** Do not invent real people's names. Use `UNASSIGNED` when no verified owner exists. A role is assigned only when a real owner or explicitly authorized delegate is recorded.

---

## Ownership Matrix

| Role | Required Responsibility | Required Technical Competence | Relevant Decisions | Required Deliverables | Dependencies | Proposed Owner | Assignment Status |
|---|---|---|---|---|---|---|---|
| **SoC Architect** | Own architecture decisions; integrate RTL/firmware/power/security; sign off on descopes | RV32IM RISC-V, SoC integration, clock gating, power domains, pinmux, security architecture | ARC-006, ARC-036, ARC-065, TD-001, TD-003, TD-005, TD-006, TD-010, TD-016, TD-017 | Architecture audit, decision register, approval package, SRS descopes | All 12 pending decisions; BLK-001..BLK-023 | **UNASSIGNED** | No verified owner recorded |
| **Verification Lead** | Own CDC verification, formal properties, test strategy; sign off on CDC scope | Formal verification, CDC analysis, synchronizer verification, property automation | ARC-036, ARC-065, TD-009 | CDC matrix, formal property list, verification plan | ARC-006 (clock domains); BLK-003 (SDC not approvable) | **UNASSIGNED** | No verified owner recorded |
| **Power Architect** | Own power intent, two 1.8 V domains, UPF/CPF; board PMIC integration | Power domains, isolation, retention, level shifters, sky130hd process, PMIC | TD-005, BLK-008 | Power intent architecture, UPF scope (deferred to Stage 10) | TD-005 decision; BLK-008 (no UPF); BLK-021 (no 3.3 V pads) | **UNASSIGNED** | No verified owner recorded |
| **DFT Lead** | Own scan/ATPG/MBIST tool selection, test access, budget; insert scan before synthesis | Scan design, ATPG test vectors, MBIST, JTAG, tool selection, manufacturing test | TD-009 | DFT plan, tool/partner selection, scan insertion schedule | Tool vendor/partner selection; program owner budget | **UNASSIGNED** | No verified owner recorded |
| **Security Owner** | Own secure boot scope, crypto engine, OTP/eFuse/TRNG; S1/S3/S0 options | Cryptography, OTP/eFuse, TRNG, secure element, boot verification | TD-007, BLK-023 | Security architecture; S1/S3/S0 decision; OTP/eFuse/TRNG if S1 | BLK-023 (no OTP/crypto/TRNG); BLK-006 (secure boot no verifier) | **UNASSIGNED** | No verified owner recorded |
| **PD (Physical Design) Lead** | Own macro integration, LEF/Library, power domain boundaries, pinmux, area/timing signoff | sky130hd process, macro libraries, LEF, timing signoff, CTS, area estimation | TD-006, TD-005, TD-016, BLK-005, BLK-020, BLK-021 | Macro selection, LEF/Library, power domain PL, pinmux, area/timing reports | Macro availability; sky130hd limitations; area target 10 mm² | **UNASSIGNED** | No verified owner recorded |
| **Firmware Lead** | Own boot ROM, firmware layout, ISR mapping, peripheral set; reflash with descoped features | C runtime, boot sequence, ISR mapping, firmware compiles, peripheral drivers | TD-001, TD-003, TD-017, TD-009 | Boot ROM firmware, firmware compile, peripheral set reflash | RTL ADDR_WIDTH changes (TD-001, TD-003); SRS descopes (TD-017) | **UNASSIGNED** | No verified owner recorded |
| **Board Designer** | Own QFN-64 pinout, 3.3 V / 1.8 V / 1.0 V PMIC rails, power integrity, no on-chip 3.3 V pads | Pinmux, power integrity, PMIC selection, sky130hd I/O limits, board stackup | TD-005, TD-016, BLK-021, BLK-023 | Pin table, PMIC selection, 3.3 V pad absence, board power nets | TD-005 (two 1.8 V domains); BLK-021 (no 3.3 V pads); BLK-023 (no OTP/crypto) | **UNASSIGNED** | No verified owner recorded |

---

## Assignment Status Summary

| Role | Status | Action Required |
|---|---|---|
| SoC Architect | **UNASSIGNED** | Name verified owner or delegate; required for all 12 decision approvals |
| Verification Lead | **UNASSIGNED** | Name verified owner or delegate; required for ARC-036/065 and CDC formal properties |
| Power Architect | **UNASSIGNED** | Name verified owner or delegate; required for TD-005 (P-B two domains, UPF Stage 10) |
| DFT Lead | **UNASSIGNED** | Name verified owner or delegate; required for TD-009 (scan/ATPG tool/partner) |
| Security Owner | **UNASSIGNED** | Name verified owner or delegate; required for TD-007 (S1/S3/S0, OTP/eFuse/TRNG) |
| PD Lead | **UNASSIGNED** | Name verified owner or delegate; required for TD-006 (macros), TD-016 (pinmux), BLK-020, BLK-021 |
| Firmware Lead | **UNASSIGNED** | Name verified owner or delegate; required for TD-001 (ROM), TD-003 (SRAM), TD-017 (descopes) |
| Board Designer | **UNASSIGNED** | Name verified owner or delegate; required for TD-005 (PMIC), TD-016 (54-pin plan), BLK-021 |
| **All 9 roles remain UNASSIGNED** | — | No real owners or authorized delegates recorded; cannot invent names |

---

## Ownership Assignment Workflow

| Step | Action | Owner | Output |
|---|---|---|---|
| 1 | Identify real person or authorized delegate for each role | Project lead | List of verified owners/delegates |
| 2 | Record owner name and authority in `TAPEOUT_MASTER_TRACKER.md` | Project lead | Updated tracker |
| 3 | Obtain owner sign-off on each of 12 pending decisions | Each owner | Decision approvals recorded in `TAPEOUT_DECISION_REGISTER.md` |
| 4 | Update `architecture/decision_status.json` status from READY FOR APPROVAL to APPROVED | Project lead | Canonical JSON updated |
| 5 | Update `TAPEOUT_MASTER_TRACKER.md` Stage 1 criteria | Project lead | 2/10 → pass more criteria |
| 6 | Mark Stage 1 COMPLETE when all criteria met | Project lead | Stage 1 → COMPLETE; Stage 2 may begin |

---

## Assignment Deliverable

`reports/ASIC_STAGE1_ENGINEERING_OWNERSHIP_PLAN.md` — Complete

**Status:** All 9 engineering roles remain **UNASSIGNED**. No real owners or explicitly authorized delegates have been recorded. No names may be invented. Assignment requires verified owner or explicitly authorized delegate.

**Next phase:** Phase 5 — Owner approval workflow.

---

**This plan confirms:** Stage 1 cannot move to COMPLETE until all 9 engineering roles are assigned to verified owners or explicitly authorized delegates. All 12 pending architecture decisions require owner sign-off before Stage 1 can complete. Stage 2 must not start before approval.

---

**Owner-facing approval workflow** defined in `reports/ASIC_STAGE1_OWNER_APPROVAL_WORKFLOW.md` (Phase 5).