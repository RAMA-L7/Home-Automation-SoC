# Independent Architectural Review – Home‑Automation‑SoC (Phase 0)

**Prepared by:** DeepSeek Lead (lead)  
**Date:** 2026‑11‑10 (Asia/Calcutta)  

## 1. Executive Assessment
The Phase 0 architecture for the Home‑Automation‑SoC (HAS‑SoC) is a technically sound proposal that leverages proven open‑source IP (Ibex core, OpenTitan security) and industrial‑standard components (TI TPS65217 PMIC). However, the independent review against the six specialist research reports identifies several critical technical risks and documentation gaps—specifically in power analysis, clocking implementation, and verification tooling—that prevent full approval at this stage:

| Category | Status |
|----------|--------|
| **Core selection** | ✔️ Consistent (Ibex) |
| **Bus architecture** | ⚠️ Lacks detailed address map & AXI‑Lite bridge spec |
| **Memory subsystem** | ⚠️ Sizes defined, but timing/placement not verified |
| **Clock / Reset** | ⚠️ PLL source **UNKNOWN**, POR/CDC not fully specified |
| **Power Management** | ⚠️ Buck current limits **PENDING**, DFT/ATPG absent |
| **Security** | ✔️ OpenTitan secure‑boot present, but key‑provision flow missing |
| **PCB / Carrier** | ✔️ KiCad 4‑layer plan, but power‑rail sequencing analysis incomplete |
| **Verification** | ⚠️ No open‑source UPF/CDC tools, formal CDC required |

The **overall recommendation** is **“APPROVE WITH CONDITIONS”** – the architecture may proceed to the next phase provided the "Critical" and "High" severity findings identified in Section 2 are addressed with concrete mitigation plans.

---

## 2. Detailed Findings and Review Matrix

| Ref | Finding | Classification | Severity | Impact | Recommended Mitigation |
|:---:|:--------|:--------------:|:--------:|:-------|:-----------------------|
| **F01** | **PLL Implementation Gap:** The primary 50 MHz PLL source is marked as UNKNOWN/ASSUMED. No vendor‑qualified PLL IP is cited. | UNKNOWN | **CRITICAL** | Timing closure failure; unreliable system clock. | Select a proven PLL IP (e.g., OpenPLL, TI PLL) and add its datasheet reference. Verify jitter & lock time. |
| **F02** | **Power‑budget vs. PMIC Rating:** Estimated current draw for 1.0 V core rail (ASIC + SRAM) may exceed the 500 mA‑600 mA limit of the TPS65217 buck converter. | ESTIMATED | **CRITICAL** | System instability, thermal shutdown, or power rail droop. | Perform rigorous power estimation (incl. FPGA prototype) and either select a higher‑current PMIC or add external buck converters. |
| **F03** | **DFT/ATPG Tooling Absence:** No official open‑source ATPG tool compatible with the OpenLane/OpenROAD flow. Production testability is high‑risk. | DOCUMENTED | **HIGH** | Inability to verify silicon health post‑fabrication; high escape rate. | Allocate budget for a commercial ATPG/DFT tool (e.g., Synopsys DFTMAX) or adopt a minimal open‑source scan‑chain insertion and outsource ATPG. |
| **F04** | **Clock Domain Crossing (CDC) Verification:** Multiple domains (50 MHz, 25 MHz, 32 kHz) exist without an open‑source formal CDC verification tool. | DOCUMENTED | **HIGH** | Meta‑stability bugs and intermittent functional failures. |
| **F05** | **Bus Bridge Specification:** The AXI4‑Lite to APB bridge is mentioned as "estimated" but lacks a defined IP source or register timing spec. | ESTIMATED | **MEDIUM** | Peripheral access latency issues or bus hangs. | Choose a concrete bridge implementation (e.g., LiteX AXI‑Lite to APB) and document its timing. |
| **F06** | **Security Key Provisioning:** The OpenTitan‑derived secure boot is defined but the key‑injection mechanism is absent. | UNKNOWN | **MEDIUM** | Security vulnerability; inability to establish root‑of‑trust. |
| **F07** | **Traceability Gap (Binary Files):** Key architecture files (Security, Boot, Bus/Memory) are unreadable binary/UTF‑16. | UNKNOWN | **MEDIUM** | Lack of visibility into critical subsystems for verification teams. |
| **F08** | **RF Isolation:** Integration of external Wi‑Fi/Zigbee modules lacks a physical isolation or interference mitigation plan. | ASSUMED | **LOW** | Signal integrity issues; reduced wireless range. |
| **F09** | **Clock‑gating cells are claimed VERIFIED but source IP not cited.** | DOCUMENTED | **LOW** | Potential mismatched cell library timing. |
| **F10** | **Low‑power timer (LPTIM) placed in always‑on domain – no power budget or wake‑up latency provided.** | ASSUMED | **LOW** | May affect deep‑sleep wake‑up performance. |
| **F11** | **Boot ROM size and contents not quantified; secure‑boot flow may need additional storage for signatures.** | UNKNOWN | **MEDIUM** | Insufficient ROM for keys/signatures. |
| **F12** | **Safety standards (UL/CE/FCC) mentioned but compliance workplan missing.** | UNKNOWN | **MEDIUM** | Certification risk. |

---

## 3. Consistency Check Against Specialist Reports

| Research Report | Architectural Alignment | Review Conclusion |
|:----------------|:-----------------------|:------------------|
| **ds01 (IP)** | Ibex RV32IMC selection matches research recommendations. | **ALIGNED** |
| **ds02 (RTL)** | Low‑power gating and AXI‑Lite/APB bus structure align with report. | **ALIGNED** |
| **ds03 (Verif)** | Flow matches (Verilator/cocotb), but report warns of CDC tool gap. | **RISK IDENTIFIED** |
| **ds04 (FW)** | Zephyr RTOS and riscv‑gnu‑toolchain are consistent with report. | **ALIGNED** |
| **ds05 (ASIC)** | OpenLane 2 / sky130 flow matches; ATPG/DFT gap is a known issue. | **RISK IDENTIFIED** |
| **ds06 (PCB)** | KiCad 4‑layer and Nexys A7 prototyping align with recommendations. | **ALIGNED** |

---

## 4. Traceability Gaps & Unverifiable Content
The following documents could not be directly inspected (binary/UTF‑16):
- `docs/architecture/BUS_AND_MEMORY_ARCHITECTURE.md`
- `docs/architecture/SECURITY_ARCHITECTURE.md`
- `docs/architecture/BOOT_AND_FIRMWARE_ARCHITECTURE.md`

**Risk:** Decisions regarding memory map, security primitives, and boot sequencing are inferred from summaries and ADRs rather than primary design specifications. **Action:** Convert these files to UTF‑8 Markdown (or provide PDFs) and attach them for full audit.

---

## 5. Consistency Checks
| Item | Consistency Issue | Impact |
|------|-------------------|--------|
| **Processor core vs. bus bridge** | Ibex expects an AXI‑Lite master; bridge spec is only “estimated”. | May cause integration mismatches; need concrete bridge IP. |
| **Power domains vs. PMIC** | PMIC provides 3 buck outputs (1.0 V, 1.8 V, 3.3 V) but core domain current estimate exceeds buck rating. | Risk of voltage droop, brown‑out. |
| **Clock domains vs. CDC verification** | Three domains defined, but CDC verification tooling is missing. | Potential hidden functional bugs under clock‑domain crossing. |
| **Security vs. key provisioning** | Secure‑boot ROM is present, but no key‑provision path. | Security claim incomplete; could undermine trust. |
| **Peripheral register map vs. address space** | No full address map → risk of overlapping registers. | Functional conflicts, debug difficulty. |

---

## 6. Safe‑to‑Approve Decisions (Low‑Risk)
| Decision | Reason |
|----------|--------|
| Use **Ibex (RV32IMC)** as core – documented tape‑outs and open‑source support. | CONFIRMED, low risk. |
| Adopt **Zephyr RTOS** and **riscv‑gnu‑toolchain** – verified repositories. | CONFIRMED, widely used. |
| Select **QFN‑64** package – matches pin‑count and footprint. | CONFIRMED, standard for low‑pin designs. |
| Use **Ti TPS65217** PMIC – verified three‑buck/dual‑LDO solution. | CONFIRMED, but current limits need analysis (see F02). |
| Proceed with **KiCad 4‑layer PCB design** – open‑source, verified for 4‑layer boards. | CONFIRMED, tooling ready. |

These items can be **approved immediately** pending the higher‑severity mitigations.

---

## 7. Decisions Needing Further Evidence
| Decision | Missing Evidence | Suggested Source |
|----------|------------------|------------------|
| **PLL IP selection** | Vendor datasheet, jitter spec | PLL family (e.g., TI, OpenPLL) |
| **Current rating of buck converters** | Load analysis, peak‑current simulation | SPICE models of TPS65217, ASIC load curves |
| **DFT/ATPG flow** | Tool license, scan‑chain script | Commercial DFT tool (Synopsys DFTMAX) |
| **IR‑drop and power‑grid sign‑off** | Post‑layout extraction results | Calibre Power Integrity |
| **Secure‑boot key provisioning** | Key‑injection procedure, storage format | OpenTitan secure‑boot docs |
| **Full memory map** | Address allocation table | Architecture ADR 003 or HDL file |
| **Pin assignment** | Pin‑out spreadsheet (CSV) | QFN‑64 pin‑map |
| **RF compliance plan** | EMC test plan, antenna layout | FCC/CE standards |

---

## 8. Recommendations & Mitigation Plan (Prioritized)
| Priority | Action | Owner | Target Completion |
|----------|--------|-------|-------------------|
| **P1 – Critical** | Replace/augment TPS65217 with a PMIC that can source **≥1 A** on core buck or add external buck converters. | Power‑engineer | 2026‑12‑01 |
| **P1 – Critical** | Select a **qualified PLL IP** (e.g., TI PLL or OpenPLL) and integrate its datasheet into the RTL. | RTL lead | 2026‑11‑20 |
| **P2 – High** | Secure a **formal CDC verification tool** (commercial) or develop a cocotb CDC test‑bench; document coverage goals. | Verification lead | 2026‑12‑15 |
| **P2 – High** | Define a **complete memory map** (base addresses, alignment, permissions) and publish as a markdown table. | Architecture lead | 2026‑11‑30 |
| **P3 – Medium** | Conduct **IR‑drop and power‑grid extraction** on post‑layout and iterate floorplan. | Physical‑design lead | 2027‑01‑15 |
| **P3 – Medium** | Formalize **secure‑boot key provisioning** (OTP or encrypted blob) and add documentation. | Security lead | 2026‑12‑10 |
| **P4 – Medium** | Produce a **pin‑assignment spreadsheet** and verify against QFN‑64 pinout. | PCB lead | 2026‑11‑25 |
| **P4 – Low** | Draft **EMC/UL/CE compliance checklist** and assign test labs. | PCB lead | 2027‑02‑01 |
| **P5 – Low** | Convert binary architecture docs to UTF‑8 Markdown and commit. | Documentation lead | 2026‑11‑28 |

---

## 9. Final Verdict
**APPROVE WITH CONDITIONS** – The architecture is fundamentally sound but must address the critical power‑budget, PLL, CDC, and DFT/ATPG gaps before proceeding to detailed design and tape‑out.

---

## 10. Review Errata and Corrections

The following corrections address technical inaccuracies identified during post-review validation against primary sources (TI datasheet, Ibex reference manual, architecture documents).

| # | Original Claim | Corrected Finding | Evidence Source | Confidence | Remaining Engineering Action |
|:---:|:---|:---|:---|:---:|:---|
| **EC01** | TPS65217 buck converters limited to 500–600 mA on 1.0 V core rail (Finding F02, Section 2). | **TPS65217 (Rev. I) provides three buck converters (DCDC1/2/3) rated at 1.2 A each**; LDO1/LDO2 are rated at 100 mA each. The 500 mA figure was an *estimated* FPGA prototype load (ds06 report), not a PMIC limit. The 1.5 A claim in the previous correction was incorrect. | TI TPS65217 Datasheet Rev. I (SLVSB64I), §5 Device Comparison Table & §7.5 Electrical Characteristics: DCDC1/2/3 max output current = 1.2 A; LDO1/2 max output current = 100 mA. ds06 PCB Research Report §2 (ESTIMATED: 500 mA load). | **HIGH** | Re-run power-budget analysis using 1.2 A/buck capability. Verify: (a) output-voltage range of each DCDC covers 1.0 V, 1.8 V, 3.3 V simultaneously; (b) thermal / total power dissipation limits; (c) whether TPS65217 variant (e.g., TPS652170 vs TPS652171) matches default voltages/sequencing. Do not recommend PMIC replacement until SoC power budget is calculated. |
| **EC02** | “Ibex expects an AXI-Lite master” (Section 5 Consistency Check, Finding F05). | **Ibex native interfaces are simple request/grant (req/gnt) memory interfaces** for instruction and data (see Ibex Ref. Manual “Instruction-Side Memory Interface” and “Data-Side Memory Interface”). An AXI/AXI-Lite adapter bridge is required for integration into an AXI fabric. | Ibex User Guide → Core Integration → Interfaces table; Ibex Reference Guide → Instruction Fetch & Load-Store Unit protocol descriptions. | **HIGH** | Select or implement a req/gnt → AXI-Lite bridge (e.g., lowRISC `axi_adapter`, LiteX `AXI2Lite`, or custom). Document bridge latency and outstanding-transaction depth. |
| **EC03** | “Select a proven PLL IP (e.g., OpenPLL, TI PLL)” (Finding F01 mitigation). | **Distinction required:** (a) *External* PLL devices (e.g., TI LMK/LMX clock generators, Si5351) connect via I²C/SPI and provide multiple clock outputs; (b) *Synthesizable on-chip* PLL IP (e.g., OpenPLL, vendor hard macros) must be compatible with the target PDK (sky130). No sky130-qualified open PLL IP is currently documented. | TI clock-generator portfolio; OpenPLL GitHub (no sky130 PDK integration notes); sky130 PDK documentation (no PLL hard macro listed). | **MEDIUM** | Decide clocking strategy: external clock generator (simpler, lower jitter) vs. on-chip PLL (needs PDK-qualified IP). If on-chip, procure/verify sky130 PLL hard macro or use external device (e.g., Si5351) for 50 MHz reference. |
| **EC04** | “QFN-64 package confirmed, standard for low-pin designs” (Section 6 Safe-to-Approve). | **Pin-budget feasibility unverified.** A QFN-64 exposed-pad package typically yields ~56 usable I/O after power/GND/EP allocation. Required: 3 power domains (1.0 V, 1.8 V, 3.3 V) + GND + JTAG (4–6) + RF module headers (2× 8–10) + UART/SPI/I²C/GPIO/PWM/I²S (~30) + QSPI flash (6) + RTC/XTAL (4) + POR/CDC pins. **Likely exceeds 56 I/O.** | ds06 report §2 (3 power rails), architecture report peripheral list, QFN-64 pinout standards (e.g., TI/QFN-64). | **MEDIUM** | Produce a detailed pin-assignment spreadsheet. If budget exceeded, consider QFN-80, BGA, or reduce peripheral count / multiplex pins. |
| **EC05** | “Key architecture files are unreadable binary/UTF-16” (Finding F07, Section 4). | **Files are genuinely binary (not UTF-16 or malformed Markdown).** The `read` tool failed with “binary file” error; hex inspection confirms non-text content (likely .docx or other container). | Direct tool inspection (`read` tool returns “binary file” error for BUS_AND_MEMORY_ARCHITECTURE.md, SECURITY_ARCHITECTURE.md, BOOT_AND_FIRMWARE_ARCHITECTURE.md). | **HIGH** | Convert the three binary files to UTF-8 Markdown (or PDF) and commit. Re-run traceability audit once readable. |
| **EC06** | Implicit universal 6.4 mm clearance for mains circuits (referenced in safety standards section). | **No universal 6.4 mm rule.** Required creepage/clearance depends on: working voltage, pollution degree, material group (CTI), coating, altitude, and standard (IEC 60664-1, IEC 62368-1, UL 840). For 250 V<sub>AC</sub>, Pollution Degree 2, Material Group IIIa: minimum creepage ≈ 2.5 mm (functional), 4.0 mm (basic), 8.0 mm (reinforced). | IEC 60664-1 Table F.4; UL 840 Table 7.1; ds06 report §8 (reinforced isolation 2500 V<sub>rms</sub>). | **HIGH** | Calculate required spacing per applicable standard for each mains-connected interface. Document in PCB design rules. Remove any blanket “6.4 mm” statement. |

---

## 11. Impact on Original Findings & Recommendations

| Original Finding | Status After Correction |
|:---|:---|
| **F01 – PLL Gap** | **UNCHANGED (CRITICAL)** – Strategy decision (external vs. on-chip) and PDK compatibility still open. |
| **F02 – Power Budget vs. PMIC** | **DOWNGRADED to MEDIUM** – PMIC *capability* (1.2 A/buck) is adequate; risk shifts to *actual load verification* and thermal design. |
| **F05 – Bus Bridge Spec** | **CLARIFIED (HIGH)** – Bridge type is req/gnt → AXI-Lite, not AXI-Lite master. Selection/implementation still required. |
| **F07 – Binary Architecture Docs** | **CONFIRMED (HIGH)** – Files are binary containers; conversion to Markdown/PDF is a prerequisite for full audit. |
| **QFN-64 Approval** | **WITHDRAWN** – Package confirmation pending pin-budget spreadsheet. |
| **Mains Clearance** | **CORRECTED** – No universal value; per-standard calculation required. |

All other findings (F03 DFT/ATPG, F04 CDC, F06 Key Provisioning, F08 RF Isolation, F09 Clock Gating, F10 LPTIM, F11 Boot ROM, F12 Safety Workplan) remain **unchanged**.

---

## 12. Revised Final Verdict

**APPROVE WITH CONDITIONS** (unchanged overall, but with corrected technical basis).

The architecture is fundamentally sound. The critical corrections **do not introduce new show-stoppers**; they refine the mitigation paths:

1.  **PLL strategy** (external generator vs. on-chip IP) must be decided and documented.
2.  **Power budget** must be completed against the verified 1.2 A/buck capability.
3.  **Req/gnt → AXI-Lite bridge** must be selected/implemented.
4.  **Pin-budget spreadsheet** for QFN-64 (or alternative package) must be produced.
5.  **Three binary architecture files** must be converted to readable Markdown/PDF.
6.  **Mains creepage/clearance** rules must be calculated per IEC 60664-1 / UL 840 for each interface.

Once these six engineering actions are completed and evidenced, the architecture may proceed to detailed RTL and physical implementation.

---

*All evidence tags (VERIFIED, DOCUMENTED, ESTIMATED, ASSUMED, UNKNOWN) are retained from the original specialist reports for traceability.*
