# ASIC Stage 1 — Owner Approval Workflow

**Date:** 2026-11-15  
**Purpose:** Allow project owners to approve, reject, request amendment, or defer each of the 12 pending architecture decisions  
**Current main HEAD:** `d6791cdb1742964033fadc63fa508b1ececf0c3b`  
**Stage 1 status:** READY FOR APPROVAL, NOT COMPLETE  

> **Rule:** Do not create fake signatures, names, dates or approvals. Do not mark any decision approved through generated documentation. Each decision requires explicit project-owner authorization.

---

## Workflow Groups

Decisions are grouped for review convenience:

### Group A: Architecture
| ID | Decision | Approve | Reject | Amendment | Defer |
|---|---|---|---|---|---|
| **ARC-006** | Clock architecture C-prime | Approve C-prime: 50 MHz core, /2 25 MHz peripheral, external 32.768 kHz AON; no PLL | Reject C-prime (specify alternative) | Request amendment (specify revised clock plan) | Defer pending additional clock evidence |
| **ARC-036** | CDC scope and verification | Approve CDC scope as redefined | Reject (specify alternative scope) | Request amendment (specify revised property set) | Defer pending CDC tool/partner |
| **ARC-065** | Formal CDC properties | Approve property set | Reject (specify alternative properties) | Request amendment (add/remove properties) | Defer pending formal verification run |

### Group B: Memory and Interfaces
| ID | Decision | Approve | Reject | Amendment | Defer |
|---|---|---|---|---|---|
| **TD-001** | Boot ROM size 16 KB | Approve 16 KB; change RTL ADDR_WIDTH 16→14 | Reject (specify alternative ROM size) | Request amendment (specify revised ADDR_WIDTH) | Defer pending firmware compatibility |
| **TD-003** | SRAM size 128 KB | Approve 128 KB; change RTL ADDR_WIDTH 18→17 | Reject (specify alternative SRAM size) | Request amendment (specify revised ADDR_WIDTH) | Defer pending macro integration |
| **TD-006** | SRAM macro architecture | Approve 32-bit wide macros; do not tile 4 KB macro | Reject (specify alternative macro strategy) | Request amendment (specify revised macro width/area) | Defer pending macro availability |
| **TD-016** | Package pin budget 54 of 56 I/O | Approve 54-pin plan; mux PLIC onto GPIO | Reject (specify alternative pin plan) | Request amendment (specify revised pinmux) | Defer pending board layout |

### Group C: Security and Project Requirements
| ID | Decision | Approve | Reject | Amendment | Defer |
|---|---|---|---|---|---|
| **TD-007** | Secure boot scope S1/S3/S0 | Approve S1 (if OTP/secure element available), S3 (fallback), or S0 (explicit descope) | Reject (specify alternative security strategy) | Request amendment (specify revised security option) | Defer pending OTP/eFuse/TRNG availability |
| **TD-009** | DFT tool and budget | Approve selected tool/partner; insert scan before synthesis freeze | Reject (specify alternative tool/partner) | Request amendment (specify revised tool criteria) | Defer pending tool contract |
| **TD-010** | SDC clock architecture | Approve 50 MHz core + generated 25 MHz peripheral; retire 20/40 ns SDC | Reject (specify alternative clock strategy) | Request amendment (specify revised SDC plan) | Defer pending timing signoff |

### Group D: Requirements Baseline
| ID | Decision | Approve | Reject | Amendment | Defer |
|---|---|---|---|---|---|
| **TD-017** | Requirements baseline and descopes | Approve re-baselined SRS; owner-signed descopes | Reject (specify alternative baseline) | Request amendment (specify revised descopes) | Defer pending owner sign-off on each descope |

---

## Approval Statements

For each decision, the owner must provide a concise approval statement containing exactly:

1. **Decision ID** (e.g., ARC-006)
2. **Exact choice** (APPROVED, REJECTED, AMENDMENT_REQUESTED, PENDING_APPROVAL retained, BLOCKED, or SUPERSEDED)
3. **Technical consequence** — the exact technical consequence of this choice
4. **Risks** — any newly introduced risks
5. **Dependencies** — any dependencies that must be resolved

Example approval statement format:

```
DECISION ARC-006: APPROVED
Technical consequence: Clock architecture C-prime is approved; RTL /2 divider insertion, SDC generated clock, formal CDC properties to follow.
Risks: Clock gating safety verification; reset sequencing across domains; CDC closure for new crossings.
Dependencies: ARC-036, ARC-065 (CDC scope); TD-010 (SDC); BLK-001 (clock architecture unapproved).
```

No approval is valid without all five elements.

---

## Decision Approval Matrix

| ID | Current | APPROVED | REJECTED | AMENDMENT_REQUESTED | PENDING_APPROVAL | BLOCKED | SUPERSEDED |
|---|---|---|---|---|---|---|---|
| ARC-006 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| ARC-036 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| ARC-065 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-001 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-003 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-005 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-006 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-007 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-009 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-010 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-016 | PENDING_APPROVAL | — | — | — | ✓ | — | — |
| TD-017 | PENDING_APPROVAL | — | — | — | ✓ | — | — |

**Initially all 12 decisions are PENDING_APPROVAL.** Only the project owner (or explicitly authorized delegate) may change a status. Status changes must include the five-element approval statement.

---

## Workflow Rules

| Rule | Description |
|---|---|
| **R1** | Only the project owner or explicitly authorized delegate may change a decision status. |
| **R2** | Status change must include a five-element approval statement (ID, choice, technical consequence, risks, dependencies). |
| **R3** | No decision may be changed from PENDING_APPROVAL to APPROVED without explicit project-owner authorization documented in `TAPEOUT_DECISION_REGISTER.md`. |
| **R4** | A decision may be changed to REJECTED at any time with a written justification. |
| **R5** | A decision may be changed to AMENDMENT_REQUESTED; the owner must specify what is requested amended and why. |
| **R6** | A decision may be changed to DEFERRED pending additional evidence; the owner must specify what evidence is needed and by when. |
| **R7** | No fake signatures, names, dates, or approvals may be generated. |
| **R8** | Status changes must be recorded in `TAPEOUT_DECISION_REGISTER.md` and `architecture/decision_status.json`. |
| **R9** | Stage 1 is COMPLETE only when all 12 decisions are not PENDING_APPROVAL and all 10 acceptance criteria are met. |
| **R10** | Stage 2 must not start before Stage 1 is COMPLETE. |

---

## Owner Action Checklist

For each of the 12 decisions, the owner must:

1. Review the decision recommendation and technical justification in `reports/ASIC_STAGE1_DECISION_PACKAGE.md`
2. Review the validation matrix in `reports/ASIC_STAGE1_DECISION_VALIDATION_MATRIX.md`
3. Review the technical revalidation in `reports/ASIC_STAGE1_TECHNICAL_REVALIDATION.md`
4. Review the formal approval package in `reports/ASIC_STAGE1_FORMAL_APPROVAL_PACKAGE.md`
5. Record the approval statement (5 elements: ID, choice, technical consequence, risks, dependencies)
6. Update `TAPEOUT_DECISION_REGISTER.md` with the new status
7. Update `architecture/decision_status.json` status from READY FOR APPROVAL to APPROVED
8. Update `TAPEOUT_MASTER_TRACKER.md` acceptance criteria
9. When all 12 decisions are approved and 8/10 (or all) acceptance criteria are met, mark Stage 1 COMPLETE
10. Only then may Stage 2 begin

---

## Workflow Deliverable

`reports/ASIC_STAGE1_OWNER_APPROVAL_WORKFLOW.md` — Complete

**Status:** workflow defined; all 12 decisions initially PENDING_APPROVAL; no approvals granted without owner authorization.

**Next phase:** Phase 6 — Independent architecture audit.

---

**This workflow confirms:** The owner may approve, reject, request amendment, or defer each decision. No approvals are granted automatically. Stage 1 cannot complete until all 12 decisions have a non-PENDING_APPROVAL status and all acceptance criteria are met. Stage 2 must not start before Stage 1 COMPLETE.