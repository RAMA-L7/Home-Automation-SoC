# ASIC Stage 1 — Approval Baseline Audit

**Date:** 2026-11-15  
**Status:** Complete  
**Current main HEAD:** `d6791cdb1742964033fadc63fa508b1ececf0c3b` (merge of PR #1 and PR #2)  
**Branch:** `main`  
**Working tree:** Clean (no tracked modifications; 70+ untracked pre-existing paths preserved)  

---

## 1. Repository and Merge Baseline

| Item | Value |
|---|---|
| Current branch | `main` |
| HEAD commit | `d6791cdb1742964033fadc63fa508b1ececf0c3b` |
| PR #1 status | Merged (publication of Stage 0 governance + Stage 1 architecture audit) |
| PR #2 status | Merged (published 23 documentation + machine-readable evidence files) |
| Main branch baseline | `3fb1f0492b0dd460bd70d1a06a36b536b3d4280e` (original Stage 0 audit) |
| Working tree modifications | **None** (tracked) |
| Untracked files | 70+ pre-existing paths (experiments/, old reports/, sim/, etc.) — all preserved |

---

## 2. Canonical Decision Register vs. Published Documents

| Source | Total decisions | Approved historical | Ready for approval | Approved Stage 1 | Stage 1 complete |
|---|---|---|---|---|---|
| `architecture/decision_status.json` | 13 | 1 (ARC-041) | 12 | 0 | false |
| `TAPEOUT_DECISION_REGISTER.md` | 21 entries (includes FR-* requirements) | 1 (ARC-041 APPROVED) | 17 READY FOR APPROVAL | 0 | — |
| `reports/ASIC_STAGE1_DECISION_PACKAGE.md` | 13 decisions documented | 1 historically approved | 12 awaiting owner approval | 0 | false |

**Reconciliation:** The authoritative 13-decision canonical set is from `architecture/decision_status.json`. The decision register contains additional entries for traceability (FR-CLK-002, FR-PERF-006, IF-PIN-002, etc.) but the JSON is the canonical source. All 13 decisions agree: ARC-041 is APPROVED_HISTORICAL; the remaining 12 are READY FOR APPROVAL awaiting explicit user/design-owner authorization.

**Discrepancy noted:** Historical summaries mentioned "12 pending decisions and 13 total." The JSON confirms: 1 approved historical + 12 ready for approval = 13 total. No inconsistency in the canonical source; earlier verbal summaries may have been imprecise.

---

## 3. All 12 Pending Architecture Decisions (Status: READY FOR APPROVAL)

| ID | Title | Blocking stages | Evidence file | Key technical recommendation |
|---|---|---|---|---|
| **ARC-006** | Clock architecture | [2, 6, 8, 12, 15] | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md`; `architecture/clock_architecture.json` | C-prime: 50 MHz core, /2 25 MHz peripheral, external 32.768 kHz AON; no on-chip PLL |
| **ARC-036** | CDC scope | [5, 6, 12] | `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` | Scope follows C-prime: core/periph synchronous handshake, core/AON async with 2-FF and handshakes; formal properties for AON wake, reset release, APB handshake |
| **ARC-065** | Formal CDC properties | [5, 6] | `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` §3.2 | Property set: reset synchronizers, AON wake handshake, APB request/response, PLIC interrupt sync; no 3-domain async FIFO claim |
| **TD-001** | Boot ROM size | [1, 3, 7] | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` | 16 KB; change RTL ADDR_WIDTH from 16 to 14 |
| **TD-003** | SRAM size | [1, 3, 7] | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` | 128 KB; change RTL ADDR_WIDTH from 18 to 17 |
| **TD-005** | Power intent and domains | [1, 10, 15] | `reports/ASIC_STAGE1_POWER_ARCHITECTURE.md` | Two 1.8 V domains (AON + switchable core/periph); board PMIC provides 1.0 V/3.3 V; no on-chip 3.3 V pads |
| **TD-006** | SRAM macro architecture | [3, 9, 10] | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md`; `architecture/memory_architecture.json` | 32-bit wide 128 KB / 32 KB macros; do not tile 4 KB macro (44 × = 31.8 mm², exceeds 10 mm² target) |
| **TD-007** | Secure boot scope | [1, 2, 17] | `reports/ASIC_STAGE1_SECURITY_BOOT_ARCHITECTURE.md` | S1: hardware SHA-256 + ECDSA-P256 with OTP/secure element, or explicit S0 descope removing security claims; S3 fallback if no OTP |
| **TD-009** | DFT scope and tooling | [16, 17, 18] | `reports/ASIC_STAGE1_DECISION_PACKAGE.md` §12 | Decide scan/ATPG tool or partner before Stage 7; scan insertion must precede synthesis freeze |
| **TD-010** | SDC clock architecture | [8, 12, 15] | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md`; `ASIC_STAGE1_DECISION_PACKAGE.md` §9 | 50 MHz core + generated 25 MHz peripheral; retire conflicting 20 ns/40 ns SDC files |
| **TD-016** | Package pin budget and pinmux | [1, 2, 9, 17] | `reports/ASIC_STAGE1_INTERFACE_AND_ADDRESS_MAP.md` §6 | Remove 32-bit `ext_irq` and 3 internal handshake pins; add BOOT_MODE[1:0], PMIC_ALERT/IRQ, RF_CTRL[1:0], UART1 → 54 of 56 I/O |
| **TD-017** | Requirements baseline and descopes | [1, 2, 4, 16, 17] | `reports/ASIC_STAGE1_REQUIREMENTS_TRACEABILITY.md`; `ASIC_STAGE1_DECISION_PACKAGE.md` §11 | Re-baseline SRS to implementable product: RV32IM, 1 UART, 1 SPI, 1 I2C, 16 GPIO, 4 PWM, 1 I2S TX, CLINT/PLIC 8 sources, 16 KB ROM/32 KB TCM/128 KB SRAM; defer crypto, OTA, second UART, LPTIM |

---

## 4. Stage 1 Acceptance Criteria (10 requirements)

| # | Criterion | Status | Evidence | Action required |
|---|---|---|---|---|
| 1 | ARC-006 approved | **NO** | `architecture/decision_status.json`; `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md` | Owner sign-off on C-prime clock architecture |
| 2 | ARC-036/065 approved | **NO** | `architecture/decision_status.json`; `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` | Owner sign-off on CDC scope and property list |
| 3 | ARC-041 recorded/approved | **YES** (historical) | `architecture/decision_status.json`; `TAPEOUT_DECISION_REGISTER.md` | No action needed — historically approved |
| 4 | One memory architecture approved | **NO** | `architecture/decision_status.json`; `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` | Owner sign-off on 16 KB ROM / 128 KB SRAM / 32-bit macros |
| 5 | Peripheral clock strategy approved | **NO** | `architecture/decision_status.json`; `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md` | Owner sign-off on C-prime /2 divider |
| 6 | AON/power approved or descoped | **NO** | `architecture/decision_status.json`; `reports/ASIC_STAGE1_POWER_ARCHITECTURE.md` | Owner sign-off on P-B two-domain 1.8 V plan |
| 7 | Traceability complete for mandatory requirements | **YES** | `architecture/requirements_traceability.csv` (124 rows) | No action needed — complete |
| 8 | No decision blocking Stage 2 | **NO** | `TAPEOUT_BLOCKER_REGISTER.md`; `architecture/decision_status.json` | Resolve 12 pending decisions |
| 9 | Role owners assigned | **NO** | `TAPEOUT_MASTER_TRACKER.md` §13 | Name or delegate RTL, verification, formal/CDC, PD, DFT, security owners |
| 10 | Independent architecture audit passed | **NO** (self-audit only) | This audit | Independent audit must be performed |

**Met: 2/10** (criteria 3 and 7)

---

## 5. Key Evidence Files (All Present and Hash-Verified)

| File | Rows/Size | Status |
|---|---|---|
| `architecture/clock_architecture.json` | Machine-readable | Valid JSON |
| `architecture/memory_architecture.json` | Machine-readable | Valid JSON |
| `architecture/cdc_rdc_matrix.csv` | 31 paths × 14 cols | Ragged-row free |
| `architecture/requirements_traceability.csv` | 124 requirements × 11 cols | Ragged-row free |
| `architecture/interface_inventory.csv` | 50 entries × 14 cols | Ragged-row free |
| `architecture/decision_status.json` | 13 decisions | Valid JSON |
| `reports/ASIC_STAGE1_ARCHITECTURE_AUDIT.md` | 17 discrepancies D-01..D-17 | Present |
| `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md` | C-prime recommendation | Present |
| `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` | 31 paths, property set | Present |
| `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` | 16/32/128 KB, macro analysis | Present |
| `reports/ASIC_STAGE1_POWER_ARCHITECTURE.md` | P-B two-domain 1.8 V | Present |
| `reports/ASIC_STAGE1_SECURITY_BOOT_ARCHITECTURE.md` | S1/S3/S0 options | Present |
| `reports/ASIC_STAGE1_REQUIREMENTS_TRACEABILITY.md` | 124-row summary | Present |
| `reports/ASIC_STAGE1_INTERFACE_AND_ADDRESS_MAP.md` | APB map, 54-pin plan | Present |
| `reports/ASIC_STAGE1_DECISION_PACKAGE.md` | 13 decisions | Present |

---

## 6. Blockers and Gaps

| Blocker ID | Priority | Description | Dependencies |
|---|---|---|---|
| BLK-001 | P0 | Clock architecture not implemented: RTL has one gated 50 MHz clock; no /2 divider, no 32 kHz AON domain, no PLL | ARC-006 approval |
| BLK-002 | P0 | Memory sizes disagree: ROM 64 KB RTL vs 16 KB mapped; SRAM 256 KB array vs 128 KB mapped | TD-001, TD-003 approval |
| BLK-003 | P0 | No approvable SDC: full-SoC SDC uses 20 ns blanket I/O delays; block SDC uses 40 ns; 105 ports lack budgets | ARC-010, clock approval |
| BLK-004 | P1 | Full-SoC Yosys parse failure at `has_soc.sv:65 unexpected TOK_IMPORT` | Stage 2 RTL implementation |
| BLK-005 | P1 | SRAM macro not integrated: 4 KB macro, 32 needed for 128 KB; wrapper/LEF/Library not integrated | TD-006 approval |
| BLK-006 | P1 | Secure boot has no verifier and fails closed; OTA is a stub | TD-007 approval |
| BLK-007 | P1 | No DFT: no scan/ATPG/MBIST; no commercial tool available | TD-009 approval |
| BLK-008 | P1 | No UPF/CPF: only board-level PMIC prose; no production UPF | TD-005 approval, Stage 10 |
| BLK-019 | P1 | Pin budget: RTL 81 pad signals vs 56 usable QFN-64 I/O; 32 `ext_irq` pins dead | TD-016 approval |
| BLK-020 | P0 | Memory area: tiling 4 KB 128-bit macro for 176 KB needs 44 macros = 31.8 mm², exceeding <10 mm² target | TD-006 approval |
| BLK-021 | P1 | No 3.3 V tolerant pads in sky130hd; SRS requires 3.3 V I/O and 1.0 V core | board/PMI spec resolution |
| BLK-022 | P1 | Engineering role owners unassigned (RTL, verification, formal/CDC, PD, DFT, security) | Role assignment |
| BLK-023 | P1 | No OTP/eFuse, TRNG or crypto engine for any secure-boot option | RTL inventory; security report |

---

## 7. Preservation Verification

- **Git history:** `3fb1f0492b0dd460bd70d1a06a36b536b3d4280e` → `d6791cdb1742964033fadc63fa508b1ececf0c3b` (merge commit only; no rewrites)
- **Tracked modifications:** 0 (confirmed)
- **All Stage 1 artifacts preserved:** 9 reports + 6 machine-readable files + 4 tracker/register files
- **No production RTL/SDC/PD changes:** Confirmed — merge included only documentation and evidence
- **Historical decision IDs preserved:** ARC-006, ARC-036, ARC-041, ARC-065, M1–M10

---

## 8. Baseline Audit Deliverable

`reports/ASIC_STAGE1_APPROVAL_BASELINE_AUDIT.md` — Complete

**Next phase:** Phase 1 — Validate all 12 pending decisions against actual repository state and reports.

---

**This audit confirms:** Stage 1 is **READY FOR APPROVAL, NOT COMPLETE**. Two of ten acceptance criteria are met (ARC-041 historical approval; traceability matrix complete). Twelve mandatory decisions require explicit user/design-owner approval. No production RTL, SDC, or physical-design scripts were modified. Stage 2 must not start before approval.