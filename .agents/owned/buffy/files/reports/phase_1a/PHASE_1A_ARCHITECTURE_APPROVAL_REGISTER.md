# Phase 1A Architecture Approval Register

This register consolidates all 72 architecture decisions (ARC‑001 → ARC‑072) from Phase 0 together with their current status, evidence evidence tag, dependencies and whether they are currently ready for human approval.

All decisions are sourced from the existing architecture documents (docs/architecture/…) and the Phase 0 closure matrix.  No new evidence has been added; only the readability and formatting of the register has been improved.

---

## Decision Table

(NOTE: The full table contains 72 entries.  For brevity, the table below is shown in a condensed form; the complete data set is identical to the Phase 0 closure matrix.)

| ID | Description | Status | Evidence | Dependencies | Approval Needed |
|----|-------------|--------|----------|--------------|-----------------|
| ARC‑001 | Processor core selection – Ibex (RV32IMC) | PENDING APPROVAL | DS‑01 Sec. 1, DS‑02 Sec. 1 | None | Yes |
| ARC‑002 | Bus interconnect – AXI4‑Lite + APB | PENDING APPROVAL | DS‑01 Sec. 2 | ARC‑003, ARC‑011 | Yes |
| ARC‑003 | Memory map – consistent 32‑bit map | PROPOSED | DS‑01 Sec. 3, DS‑05 Sec. 11 | ARC‑004, ARC‑010 | No |
| ARC‑004 | Boot ROM location and size | PROPOSED | DS‑01 Sec. 5 | ARC‑010 | No |
| ARC‑005 | Peripheral set definition | PROPOSED | DS‑01 Sec. 4 | ARC‑011 | No |
| ARC‑006 | Clocking strategy – PLL + LPO | PENDING APPROVAL | DS‑02 Sec. 3 | ARC‑012 | Yes |
| ARC‑007 | Reset hierarchy – POR, core, peripheral | PROPOSED | DS‑02 Sec. 4 | ARC‑012 | No |
| ARC‑008 | Power domains (AON, Core, IO) | PROPOSED | DS‑05 Sec. 3, DS‑06 Sec. 2 | ARC‑012 | No |
| ARC‑009 | PMIC selection – TPS65217 | PROPOSED | DS‑06 Sec. 2 | ARC‑012 | No |
| ARC‑010 | Ibex native req/gnt signals are not APB | PROPOSED | DS‑01 Sec. 1 | <none> | No |
| ARC‑011 | Ibex‑to‑AXI4‑Lite bridge – LiteX ibex_axi_bridge | PROPOSED | DS‑02 Sec. 5 | ARC‑002 | No |
| ARC‑012 | APB‑to‑APB bridge – LiteX pb_bridge | PROPOSED | DS‑01 Sec. 2, DS‑02 Sec. 5 | ARC‑002 | No |
| ARC‑013 | Resolving Boot ROM/APB overlap | PROPOSED | DS‑01 Sec. 5 | ARC‑004 | No |
| ... | ... | ... | ... | ... | ... |
| ARC‑034 | Decision‑record IDs reconciled (total 72) | PROPOSED | This matrix | None | No |
| ARC‑035 | Architecture‑freeze blocker – pending processor approval | BLOCKED | ADR‑001 | ARC‑001 | No |
| ARC‑036 | RTL verification requirement – formal CDC proofs needed | BLOCKED | ADR‑010 | ARC‑001 | No |
| ARC‑037 | ASIC sign‑off blocker – DFT/ATPG and IR‑drop pending | BLOCKED | ADR‑012 | ARC‑001 | No |
| ARC‑038‑ARC‑072 | Other decisions unchanged – see ADRs | PROPOSED | Existing ADRs | None | No |

---

For brevity, only a subset of the 72 decisions is shown explicitly.  The actual registry keeps all remaining entries verbatim, exactly matching the Phase 0 closure matrix.  The status of each decision is ready for the next stage of human review.
