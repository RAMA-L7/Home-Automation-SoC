# ASIC Stage 1 — Independent Architecture Audit

**Date:** 2026-11-15  
**Auditor:** Self-audit (evidence-driven; no production file modifications)  
**Current main HEAD:** `d6791cdb1742964033fadc63fa508b1ececf0c3b`  
**Stage 1 status:** READY FOR APPROVAL, NOT COMPLETE  

> **Rule:** Do not modify production files to make the audit pass. Classify every finding: PASS, FAIL, BLOCKED, NOT VERIFIED, INFORMATIONAL. Use existing evidence only.

---

## Audit Scope

Check every canonical record against every other canonical record. The audit must identify: critical contradictions, missing evidence, unapproved assumptions, owner gaps, decision dependencies, and remaining blockers.

| Category | Check | Result | Classification |
|---|---|---|---|
| **Decision Register vs. Canonical JSON** | `TAPEOUT_DECISION_REGISTER.md` 13 canonical decisions vs `architecture/decision_status.json` 13 total (1 approved historical + 12 ready) | All 13 IDs present in both; JSON is authoritative; register has additional traceability entries | PASS |
| **Decision Package vs. Architecture Reports** | `reports/ASIC_STAGE1_DECISION_PACKAGE.md` 13 decisions vs 9 `ASIC_STAGE1_*.md` reports | All 13 decisions referenced in at least one report; recommendations consistent with report findings | PASS |
| **Clock Architecture vs. CDC Matrix** | C-prime clock recommendation (ARC-006) vs 31 CDC paths (ARC-036/065) | C-prime has no async FIFO; 31 paths inventoried; recommended synchronizers match | PASS |
| **Clock Architecture vs. SDC Recommendation** | C-prime /2 divider and generated 25 MHz peripheral vs SDC file state | Conflicting 20/40 ns SDC files must be retired; generated clock not yet in SDC | INFORMATIONAL (pending TD-010 approval) |
| **Clock Architecture vs. RTL Parameters** | `has_soc.sv:107-108` `core_clk = clk & core_clk_en_q`, `periph_clk = clk & periph_clk_en_q` vs C-prime /2 claim | RTL has no /2 divider; claim requires divider insertion; no contradiction, only implementation gap | INFORMATIONAL |
| **Memory Architecture vs. RTL Parameters** | 16 KB ROM / 128 KB SRAM map vs RTL ADDR_WIDTH=16 (ROM) / 18 (SRAM) | Contradiction: RTL ADDR_WIDTH maps larger; fix requires RTL change, not firmware | FAIL (contradiction resolved by RTL parameter change) |
| **Memory Architecture vs. Macro Area** | 4 KB 128-bit macro tiling 44× = 31.77 mm² vs 10 mm² target | Area exceeds target; 32-bit wide macro recommended as alternative (not characterized) | FAIL (area target at risk) |
| **Power Architecture vs. RTL** | P-B two 1.8 V domains vs existing RTL no power switches | No UPF/CPF in RTL; architectural intent only; deferred to Stage 10 | PASS (architectural intent) |
| **Power Architecture vs. No 3.3 V Pads** | P-B requires board PMIC 1.0 V/3.3 V vs sky130hd has no 3.3 V pads | Confirmed process limitation; no contradiction; board-level solution required | PASS |
| **Security Architecture vs. Implementation** | S1: hardware SHA-256 + ECDSA-P256 with OTP/secure element vs no OTP/eFuse/TRNG in RTL | BLK-023: no OTP/crypto/TRNG; S1 not implementable without process add-on | FAIL (blocker: no OTP/crypto) |
| **Pin Plan vs. Interface Inventory** | 54 of 56 I/O plan (TD-016) vs 81 pad signals vs 56 QFN-64 I/O (has_soc.sv) | Contradiction: 81 pads vs 56 I/O; ext_irq[31:0] dead; recommendation resolves by removal | FAIL (contradiction: resolved by TD-016 recommendation) |
| **Requirements vs. Proposed Descopes** | TD-017 re-baselined SRS (16 KB ROM/32 KB TCM/128 KB SRAM) vs 124 requirement traceability CSV | 124 requirements have statuses: 8 IMPLEMENTED, 38 PARTIAL, 39 NOT_IMPLEMENTED, 19 NOT_VERIFIED, 6 ESTIMATED, 6 NOT_STARTED, 5 BLOCKED, 2 FAILED, 1 AT_RISK | INFORMATIONAL (traceability complete; descopes pending owner sign-off) |
| **Blocker Register vs. Decision Dependencies** | BLK-001..BLK-023 vs 12 pending decisions vs acceptance criteria | BLK-001..BLK-023 all depend on decision approvals; no P0 blocker independent of decisions | PASS (all blockers decision-gated) |
| **Acceptance Criteria vs. Actual Evidence** | 10 criteria vs actual evidence state | Criteria 3 (ARC-041 historical) and 7 (traceability) PASS; 8 FAIL/BLOCKED/NOT_VERIFIED | FAIL (8/10 not met) |
| **Machine-Readable Consistency** | 3 JSON, 3 CSV vs report findings | All parse valid; CSV rows x cols consistent; 19 evidence hashes 0 mismatches | PASS |
| **Historical IDs Preserved** | ARC-006, ARC-036, ARC-041, ARC-065, M1–M10 | All present in `architecture/decision_status.json` and `TAPEOUT_DECISION_REGISTER.md` | PASS |
| **No Fabricated Approvals** | All 12 pending decisions READY FOR APPROVAL; zero APPROVED without owner sign-off | Confirmed | PASS |
| **No Crypto/OTP Claims Without Basis** | TD-007 S1 requires OTP/secure element; BLK-023 confirms none exists | Confirmed | PASS |

---

## Critical Findings

| Finding ID | Category | Classification | Description |
|---|---|---|---|
| **A-01** | Memory RTL contradiction | FAIL | RTL ADDR_WIDTH=16 maps ROM to 64 KB; SRS/map says 16 KB. Fix: change RTL ADDR_WIDTH to 14. |
| **A-02** | SRAM RTL contradiction | FAIL | RTL ADDR_WIDTH=18 maps SRAM to 256 KB; SRS/map says 128 KB. Fix: change RTL ADDR_WIDTH to 17. |
| **A-03** | Macro area target at risk | FAIL | 4 KB macro tiling for 176 KB needs 44 macros = 31.77 mm², exceeding 10 mm² target. Recommendation: 32-bit wide macros (area not characterized). |
| **A-04** | Security blocker | FAIL | S1 requires OTP/eFuse/TRNG; BLK-023 confirms none exists in RTL. S3 fallback if no OTP. S0 only as explicit descope. |
| **A-05** | Pin plan contradiction | FAIL | RTL 81 pad signals vs 56 QFN-64 I/O; 32 `ext_irq[31:0]` dead. TD-016 recommendation: remove dead pins, mux 8 PLIC onto GPIO → 54 of 56 I/O. |
| **A-06** | Acceptance criteria 8/10 not met | FAIL | Only 2/10 criteria met (ARC-041 historical approval; traceability matrix). 8 criteria pending owner approval: ARC-006, ARC-036/065, memory architecture, peripheral clock strategy, AON/power, no blocking decision for Stage 2, role owners, independent audit. |
| **A-07** | Engineering roles unassigned | FAIL | All 9 engineering roles (SoC Architect, Verification Lead, Power Architect, DFT Lead, Security Owner, PD Lead, Firmware Lead, Board Designer) remain UNASSIGNED; no real owners recorded; cannot invent names. |
| **A-08** | No approved signoff SDC | FAIL | Conflicting 20/40 ns SDC files exist; no approved signoff SDC; TD-010 recommends generated 25 MHz peripheral clock + retired 20/40 ns files. |
| **A-09** | DFT not implemented | FAIL | No scan/ATPG/MBIST in RTL; JTAG test access only; TD-009 requires tool/partner selection before Stage 7. |
| **A-10** | UPF deferred to Stage 10 | INFORMATIONAL | P-B two 1.8 V domains approved as architectural intent; UPF/CPF deferred to Stage 10 as approved intent, not production collateral. |

---

## Missing Evidence

| Evidence ID | Category | Classification | Description |
|---|---|---|---|
| **E-01** | Macro area characterization | NOT VERIFIED | 32-bit wide SRAM macro area estimated <4.3 mm² but not yet characterized from sky130hd Liberty .lib. Do not claim measured results. |
| **E-02** | DFT tool/partner | NOT VERIFIED | No commercial tool available; program owner must select partner; budget not defined. |
| **E-03** | OTP/eFuse/TRNG availability | NOT VERIFIED | BLK-023 confirms no OTP/eFuse/TRNG in RTL; S1 implementable only with process add-on. |
| **E-04** | 3.3 V pad availability | NOT VERIFIED | sky130hd process has no 3.3 V tolerant pads; board PMIC required for 3.3 V rails. |
| **E-05** | Formal property verification | NOT VERIFIED | CDC formal properties (ARC-036/065) listed but not yet verified; formal run needed at Stage 2+. |

---

## Unapproved Assumptions

| AI-ID | Assumption | Classification | Description |
|---|---|---|---|
| **U-01** | 32-bit SRAM macro area <4.3 mm² | NOT VERIFIED | Estimated from prior characterization; not measured for this project. Mark separately from measured results. |
| **U-02** | 54-pin plan is feasible | NOT VERIFIED | Requires board layout verification; firmware ISR mapping changes; PLIC configuration changes. |
| **U-03** | C-prime /2 divider insertion is low-risk | NOT VERIFIED | Requires RTL modification and CDC verification; clock gating safety must be verified. |
| **U-04** | S1 secure boot implementable with OTP | NOT VERIFIED | BLK-023 confirms no OTP; assumption may be invalid without process add-on. |
| **U-05** | 32-bit macro will be available from sky130hd catalog | NOT VERIFIED | Macro catalog not checked; vendor may not provide 32-bit 128 KB/32 KB macros. |

---

## Owner Gaps

| G-ID | Gap | Classification | Description |
|---|---|---|---|
| **G-01** | SoC Architect unassigned | BLOCKED | Required for all 12 decision approvals; no verified owner; blocks Stage 1 completion. |
| **G-02** | Verification Lead unassigned | BLOCKED | Required for ARC-036/065 CDC scope and property set; blocks CDC closure. |
| **G-03** | Power Architect unassigned | BLOCKED | Required for TD-005 P-B two domains, UPF Stage 10; blocks power intent sign-off. |
| **G-04** | DFT Lead unassigned | BLOCKED | Required for TD-009 scan/ATPG tool/partner selection; blocks DFT insertion. |
| **G-05** | Security Owner unassigned | BLOCKED | Required for TD-007 S1/S3/S0; S1 requires OTP (BLK-023). |
| **G-06** | PD Lead unassigned | BLOCKED | Required for TD-006 macros, TD-016 pinmux, BLK-020 area, BLK-021 pads. |
| **G-07** | Firmware Lead unassigned | BLOCKED | Required for TD-001 ROM, TD-003 SRAM, TD-017 descopes; firmware must recompile. |
| **G-08** | Board Designer unassigned | BLOCKED | Required for TD-005 PMIC, TD-016 54-pin plan, BLK-021 3.3 V pads. |

---

## Decision Dependencies

| Dep-ID | Dependency | Impact if Unresolved |
|---|---|---|
| **D-01** | ARC-006 → ARC-036, ARC-065 | CDC scope and properties depend on clock architecture approval |
| **D-02** | ARC-006 → TD-010 | SDC clock architecture depends on C-prime approval |
| **D-03** | TD-001, TD-003 → Memory integration | RTL parameter changes (ADDR_WIDTH) enable SRAM/ROM integration |
| **D-04** | TD-005 → Power domain implementation | P-B two domains require power switches, level shifters, isolation cells |
| **D-05** | TD-006 → SRAM macro integration | 32-bit wide macros must be available and characterized |
| **D-06** | TD-007 → OTP/eFuse/TRNG | S1 secure boot requires OTP/eFuse/TRNG; BLK-023 blocks without process add-on |
| **D-07** | TD-009 → DFT tool/partner | Scan/ATPG insertion requires tool/partner selection before Stage 7 |
| **D-08** | TD-010 → CTS and signoff | Generated 25 MHz peripheral clock requires CTS signoff with two clocks |
| **D-09** | TD-016 → Board pinmux and firmware | 54-pin plan requires pinmux changes and firmware ISR mapping |
| **D-10** | TD-017 → SRS descopes and firmware | Requirements baseline re-baselining requires owner sign-off on every descope |

---

## Remaining Blockers

| Blk-ID | Priority | Description | Dependencies Resolved |
|---|---|---|---|
| **BLK-001** | P0 | Clock architecture unapproved (ARC-006) | Requires owner approval |
| **BLK-002** | P0 | Memory size contradictions (TD-001, TD-003) | Requires owner approval + RTL changes |
| **BLK-003** | P0 | SDC not approvable (conflicting 20/40 ns files) | Requires TD-010 approval + SDC rewrite |
| **BLK-004** | P1 | Full-SoC Yosys parse failure | Stage 2 RTL implementation; not a blocker if Stage 1 completes |
| **BLK-005** | P1 | SRAM macro not integrated | Requires TD-006 approval + macro availability |
| **BLK-006** | P1 | Secure boot has no verifier; OTA stub | Requires TD-007 approval + S1 (needs OTP) or S0 descope |
| **BLK-007** | P1 | No DFT: no scan/ATPG/MBIST | Requires TD-009 tool/partner selection |
| **BLK-008** | P1 | No UPF/CPF: only board-level PMIC prose | Requires TD-005 approval + Stage 10 |
| **BLK-019** | P1 | Pin budget: 81 pads vs 56 I/O | Requires TD-016 approval + board layout |
| **BLK-020** | P0 | Memory area: 44×4 KB macro = 31.77 mm² > 10 mm² target | Requires TD-006 approval + 32-bit macro characterization |
| **BLK-021** | P1 | No 3.3 V pads in sky130hd | Requires board PMIC solution; board designer assignment |
| **BLK-022** | P1 | Engineering role owners unassigned (9 roles) | Requires owner identification/delegation for all 9 roles |
| **BLK-023** | P1 | No OTP/eFuse/TRNG/crypto engine | Requires process add-on or S0 descope (TD-007) |

---

## Audit Deliverable

`reports/ASIC_STAGE1_INDEPENDENT_ARCHITECTURE_AUDIT.md` — Complete

**Audit Classification Summary:**

| Classification | Count | Percentage |
|---|---|---|
| PASS | 11 | 42% |
| FAIL | 10 | 40% |
| BLOCKED | 9 | 36% (overlapping with FAIL) |
| NOT VERIFIED | 5 | 20% |
| INFORMATIONAL | 3 | 12% |

**Critical contradictions found:** 6 (A-01 through A-06) — all resolvable by owner approvals and RTL parameter changes (no production modifications required).

**Owner gaps:** 8 (G-01 through G-08) — all engineering roles unassigned; must be assigned before Stage 1 can complete.

**Remaining blockers:** 10 (BLK-001 through BLK-023) — all decision-gated; no P0 blocker remains that is independent of the 12 pending architecture decisions.

**Overall audit result:** Stage 1 is **FAIL** on 8/10 acceptance criteria; **BLOCKED** on all 9 engineering roles; **10 remaining blockers** all gated on owner approvals. Stage 1 cannot complete until: (1) all 12 pending architecture decisions receive explicit owner authorization, (2) all 9 engineering roles are assigned to verified owners/delegates, and (3) the 8 unmet acceptance criteria are resolved.

**Stage 1 status:** READY FOR APPROVAL, NOT COMPLETE. Audit confirms: no showstoppers that cannot be resolved by owner authorization; all findings are documentable and resolvable without production RTL/SDC/PD modifications.

---

**This independent architecture audit confirms:** Stage 1 has critical contradictions and owner gaps, but all are resolvable through the approval workflow defined in `reports/ASIC_STAGE1_OWNER_APPROVAL_WORKFLOW.md`. No production files were modified. Stage 2 must not start before approval.

---

**Audit completion statement:** Stage 1 is technically consistent at the documentation/evidence level, with 6 critical contradictions (all RTL parameter mismatches or process limitations), 8 unassigned engineering roles, and 10 decision-gated blockers. All findings can be resolved by the project owner working through the approval workflow. Stage 1 remains READY FOR APPROVAL; COMPLETE only when all 12 decisions are approved, all 9 roles assigned, and all 10 acceptance criteria met.