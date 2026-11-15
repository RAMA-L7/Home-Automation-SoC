# ASIC Stage 1 — Final Engineering Ownership Matrix

**Date:** 2026-11-15
**Source:** `reports/ASIC_STAGE1_ENGINEERING_OWNERSHIP_PLAN.md`
**Status:** All 9 roles UNASSIGNED. No fabricated owners. No acceptance recorded.

## Ownership Status Summary

| Role | Status | Verified Owner | Required Competence | Relevant Decisions | Required Deliverables |
|---|---|---|---|---|---|
| SoC Architect | **UNASSIGNED** | None identified | RISC-V SoC architecture, RTL integration, clock/reset/power/security | All 12 | Architecture audit, decision register, approval package, SRS descopes |
| Verification Lead | **UNASSIGNED** | None identified | Formal verification, CDC/RDC, test strategy, SVA | ARC-036, ARC-065 | CDC matrix, formal property list, verification plan |
| Power Architect | **UNASSIGNED** | None identified | Power intent, UPF/CPF, PDN, low-power design | TD-005 | Power intent architecture, UPF scope (Stage 10) |
| DFT Lead | **UNASSIGNED** | None identified | Scan/ATPG/MBIST, test access, manufacturing test | TD-009 | DFT plan, tool/partner selection, scan insertion schedule |
| Security Owner | **UNASSIGNED** | None identified | Secure boot, crypto, key management, debug policy | TD-007 | Security architecture, S0/S3/S1 decision, OTP/eFuse if S1 |
| PD Lead | **UNASSIGNED** | None identified | Macro integration, LEF/Liberty, pinmux, area/timing signoff | TD-006, TD-005, TD-016 | Macro selection, LEF/Liberty, power domain PL, pinmux, area/timing |
| Firmware Lead | **UNASSIGNED** | None identified | Boot ROM, firmware layout, ISR mapping, peripheral drivers | TD-001, TD-003, TD-017 | Boot ROM firmware, compile, peripheral set reflash |
| Board Designer | **UNASSIGNED** | None identified | QFN-64 pinout, PMIC rails, power integrity, 3.3 V pad absence | TD-005, TD-016 | Pin table, PMIC selection, 3.3 V pad absence, board power nets |
| Timing Signoff Lead | **UNASSIGNED** | None identified | STA, SDC, CTS, multi-corner signoff | TD-010 | SDC clock plan, timing signoff methodology |

## Key Observations

1. **No formal role acceptance exists.** Repository history and documentation do not contain any verified owner assignment. All 9 roles remain UNASSIGNED.
2. **No invented owners.** Per safety rules, no names, signatures, or acceptances were fabricated.
3. **Recommendation:** A single accountable project owner or engineering lead should be formally designated to own the SoC Architect role, which gates all other assignments. Until then, Stage 1 cannot complete (acceptance criterion 9: role owners assigned = NO).
4. **BLK-023** (unassigned role owners) remains an active P0 blocker.

## Impact on Stage 1 Completion

- Acceptance criterion 9 (role owners assigned): **NOT MET**.
- Stage 1 cannot be marked COMPLETE until all 9 roles are formally assigned with evidence.
- This is a governance gap, not a technical gap. The technical decisions are resolved.