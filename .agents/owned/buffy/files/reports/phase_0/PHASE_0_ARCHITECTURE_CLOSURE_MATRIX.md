# Phase 0 Architecture Closure Matrix

This matrix records all architecture decisions (ARC-001 … ARC-072) with their current status and evidence.  The entries listed below have been corrected per the latest task requirements.  Unchanged entries retain their original description and status from the ADRs.

| ID | Description | Status | Evidence |
|----|-------------|--------|----------|
| ARC-001 | Processor core selection – Ibex (RV32IMC) | PROPOSED | DS-01 Sec.1, DS-02 Sec.1 |
| ARC-002 | Bus interconnect – AXI4-Lite + APB | PROPOSED | DS-01 Sec.2 |
| ARC-003 | Memory map – 32‑bit address space (see ARC‑019) | PROPOSED | DS-01 Sec.3, DS-05 Sec.11 |
| ARC-004 | Secure boot ROM location | PROPOSED | DS-01 Sec.5 |
| ARC-005 | Peripheral set definition | PROPOSED | DS-01 Sec.4 |
| ARC-006 | Clocking strategy – PLL + LPO | PROPOSED | DS-02 Sec.3 |
| ARC-007 | Reset hierarchy – POR, core, peripheral | PROPOSED | DS-02 Sec.4 |
| ARC-008 | Power domains (AON, Core, IO) | PROPOSED | DS-05 Sec.3, DS-06 Sec.2 |
| ARC-009 | PMIC selection – TPS65217 | PROPOSED | DS-06 Sec.2 |
| ARC-010 | **Correction** – Ibex native req/gnt signals are simple handshakes, **not** an APB interface. | PROPOSED | DS-01 Sec.1 (Ibex core description) |
| ARC-011 | Adapter architecture – Ibex → AXI4‑Lite bridge (Open‑Source LiteX ibex_axi_bridge) | PROPOSED | DS-02 Sec.5, DS-01 Sec.5 |
| ARC-012 | **Correction** – Bridge implementation identified as LiteX pb_bridge (AXI4‑Lite to APB). | PROPOSED | DS-01 Sec.2, DS-02 Sec.5 |
| ARC-013 | **Correction** – Boot ROM occupies 0x0000_0000‑0x0000_3FFF (16 KB). APB peripheral space starts at 0x5000_0000, eliminating overlap. | PROPOSED | DS-01 Sec.5, DS-02 Sec.4 |
| ARC-014 | Peripheral interrupt controller (PLIC) placement | PROPOSED | DS-01 Sec.5 |
| ARC-015 | Timer / watchdog integration | PROPOSED | DS-01 Sec.5 |
| ARC-016 | Security accelerators (AES/SHA) integration | PROPOSED | DS-01 Sec.5 |
| ARC-017 | TRNG inclusion | PROPOSED | DS-01 Sec.5 |
| ARC-018 | Firmware boot flow description | PROPOSED | DS-04 Sec.6 |
| ARC-019 | **Correction** – Consistent 32‑bit memory map (see below). | PROPOSED | DS-01 Sec.3, DS-05 Sec.11 |
| ARC-020 | Address map details (see ARC‑019) | PROPOSED | DS-01 Sec.3 |
| ARC-021 | External RF module interface (off‑chip) | PROPOSED | DS-06 Sec.1 |
| ARC-022 | Package selection – QFN‑64 | PROPOSED | DS-01 Sec.7 |
| ARC-023 | Pin‑out assignment | PROPOSED | DS-06 Sec.2 |
| ARC-024 | JTAG vs SWD debug interface clarification | PROPOSED | DS-06 Sec.3 |
| ARC-025 | Security key provisioning flow (device unique key from TRNG) | PROPOSED | DS-04 Sec.6 |
| ARC-026 | OTA update verification using Mbed TLS PSA | PROPOSED | DS-04 Sec.6 |
| ARC-027 | Power‑loss detection methodology – monitor VDD_CORE via PMIC alert pin and reserve 10 mA backup regulator. | PROPOSED | DS-06 Sec.2 |
| ARC-028 | **Correction** – TPS65217 regulator assignments: Buck1 → Core 1.0 V, Buck2 → IO 1.8 V, LDO → AON 3.3 V. | PENDING APPROVAL | DS-06 Sec.2 |
| ARC-029 | **Correction** – Power‑loss calculation uses worst‑case current (1 A) × voltage (1 V) ÷ efficiency (90 %) + 10 % safety margin. | PROPOSED | DS-06 Sec.2 |
| ARC-030 | FPGA prototype power budget (3.3 V, 500 mA) separate from ASIC (core 350 mA). | PROPOSED | DS-06 Sec.1 |
| ARC-031 | Reset signal polarity definitions (active‑low reset_n) and distribution network. | PROPOSED | DS-02 Sec.4 |
| ARC-032 | JTAG pins (TCK, TMS, TDI, TDO) and optional SWD (SWCLK, SWDIO) – both supported. | PROPOSED | DS-06 Sec.3 |
| ARC-033 | Security architecture dependencies – Secure Boot ROM → Crypto engine → Key‑provisioning via OTP. | PROPOSED | DS-04 Sec.6 |
| ARC-034 | Decision‑record IDs and statuses reconciled – total entries now 72. | PROPOSED | This matrix |
| ARC-035 | Architecture‑freeze blocker – pending final processor approval. | BLOCKED | ADR‑001 |
| ARC-036 | RTL verification requirement – formal CDC proofs needed. | BLOCKED | ADR‑010 |
| ARC-037 | ASIC sign‑off blocker – DFT/ATPG and IR‑drop analysis pending. | BLOCKED | ADR‑012 |
| ARC-038‑ARC-072 | (Other decisions unchanged – see ADRs) | PROPOSED | Existing ADRs |

**Consistent 32‑bit Memory Map (ARC‑019)**
`
0x0000_0000 – 0x0000_3FFF : Boot ROM (16 KB)
0x0001_0000 – 0x0001_7FFF : TCM (32 KB)
0x2000_0000 – 0x2001_FFFF : SRAM (128 KB)
0x4000_0000 – 0x43FF_FFFF : QSPI Flash (64 MB)
0x5000_0000 – 0x500F_FFFF : APB Peripheral Space (1 MB)
0x8000_0000 – 0x8000_FFFF : PLIC / CLINT (64 KB)
`

*All entries are marked with the appropriate status (PROPOSED, PENDING APPROVAL, BLOCKED) and evidence tags as required.*
