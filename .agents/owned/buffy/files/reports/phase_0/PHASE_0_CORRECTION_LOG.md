# Phase 0 Correction Log

| Decision ID | Original Problem | Correction Applied | Evidence Source |
|-------------|------------------|--------------------|-----------------|
| ARC-019 | Inconsistent memory map (different address widths, overlapping regions). | Defined a single, consistent 32‑bit memory map covering ROM, TCM, SRAM, QSPI, APB peripherals and interrupt controller. | DS‑01 Sec.3, DS‑05 Sec.11 |
| ARC-013 | Boot ROM address overlapped APB peripheral base address. | Relocated Boot ROM to 0x0000_0000‑0x0000_3FFF (16 KB) and APB space to start at 0x5000_0000, eliminating conflict. | DS‑01 Sec.5, DS‑02 Sec.4 |
| ARC-010 | Ibex native req/gnt signals incorrectly described as APB. | Clarified that Ibex uses simple handshake (request/grant) signals, not an APB bus. | DS‑01 Sec.1 (Ibex core description) |
| ARC-011 | Missing description of Ibex‑to‑interconnect adapter. | Specified use of LiteX ibex_axi_bridge to translate Ibex handshake to AXI4‑Lite master. | DS‑02 Sec.5, DS‑01 Sec.5 |
| ARC-012 | Bridge implementation unspecified. | Identified LiteX pb_bridge (AXI4‑Lite to APB) as the concrete bridge component. | DS‑01 Sec.2, DS‑02 Sec.5 |
| ARC-010 (duplicate) – already fixed above. |
| ARC-041 | Regulator assignments for TPS65217 were vague. | Assigned Buck1 → Core 1.0 V, Buck2 → IO 1.8 V, LDO → AON 3.3 V. | DS‑06 Sec.2 |
| ARC-043 | Power‑loss calculation methodology was missing. | Adopted worst‑case current × voltage ÷ efficiency + safety margin (10 %). | DS‑06 Sec.2 |
| ARC-030 | FPGA and ASIC power budgets were conflated. | Separated FPGA prototype budget (3.3 V @ 500 mA) from ASIC core budget (1.0 V @ 350 mA). | DS‑06 Sec.1 |
| ARC‑031 | Reset signal description contained corrupted text. | Defined active‑low eset_n distributed via multi‑stage POR, core reset, and peripheral reset registers. | DS‑02 Sec.4 |
| ARC‑024 | JTAG vs SWD ambiguous. | Documented both JTAG (TCK, TMS, TDI, TDO) and optional SWD (SWCLK, SWDIO) support per OpenOCD. | DS‑06 Sec.3 |
| ARC‑025 | Security key‑provisioning details missing. | Added flow: TRNG generates device‑unique key → stored in OTP region → used by Secure Boot ROM for firmware signature verification. | DS‑04 Sec.6 |
| ARC‑034 | Summary‑table decision IDs/count mismatched. | Updated table to reflect actual 72 entries, aligned with ADR list. | This matrix |
| ARC‑035‑037 | Blocker classifications needed clarification. | Added explicit blocker categories: architecture‑freeze (processor approval), RTL verification (formal CDC proofs), ASIC sign‑off (DFT/ATPG, IR‑drop). | ADR‑001, ADR‑010, ADR‑012 |

All corrections respect the evidence classification (VERIFIED, DOCUMENTED, PROPOSED, PENDING APPROVAL, BLOCKED) and do not modify any original research reports.
