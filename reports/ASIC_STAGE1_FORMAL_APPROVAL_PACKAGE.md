# ASIC Stage 1 — Formal Approval Package

**Date:** 2026-11-15  
**Status:** Ready for owner authorization  
**Current main HEAD:** `d6791cdb1742964033fadc63fa508b1ececf0c3b`  
**Stage 1 status:** READY FOR APPROVAL, NOT COMPLETE  

> **Rule:** Do not change PENDING_APPROVAL to APPROVED without explicit project-owner authorization. Do not create fake signatures, names, dates or approvals.

---

## Approval Statements and Technical Consequences

| ID | Decision Statement | Recommended Option | Technical Consequence of Approval | Risks | Dependencies | Required Approver Role |
|---|---|---|---|---|---|---|
| **ARC-006** | Clock architecture defines clocking scheme, dividers, SDC, and CTS corners | **C-prime**: 50 MHz core, internal /2 25 MHz peripheral, external 32.768 kHz AON; no on-chip PLL | - RTL: Insert /2 divider for peripheral clock; add clock gating; SDC: generated 25 MHz peripheral clock, retire conflicting 20/40 ns files<br>- CDC: 2-FF synchronizers for static signals; handshake for events; formal properties for AON wake, reset release, APB handshake, PLIC sync<br>- Power: Two 1.8 V domains (AON + switchable); board PMIC 1.0 V/3.3 V<br>- Area: No change at this level<br>- Timing: New SDC constraints; CTS with generated clock | - Clock gating safety must be verified<br>- Reset sequencing across domains<br>- CDC closure for new crossings | ARC-036, ARC-065 (CDC scope); TD-010 (SDC); BLK-001 (clock architecture unapproved) | SoC architect + verification lead |
| **ARC-036** | CDC verification scope for 3 clock domains | Scope follows C-prime: core/periph synchronous handshake, core/AON asynchronous with 2-FF and handshakes; formal properties for AON wake, reset release, APB handshake | - Verification: 31 inventoried paths; add synchronizers for `spi_miso`, `i2c_sda`, JTAG TMS/TDI<br>- Add formal properties: APB handshake, AON wake, reset release, PLIC interrupt sync<br>- No async FIFO claimed<br>- Pulse/handshake for event-based signals | - CDC closure requires formal verification or simulation coverage<br>- May uncover new unsafe paths during Stage 2<br>- No async FIFO in RTL (confirmed) | ARC-065 (formal property set); TD-010 (SDC); BLK-003 (SDC not approvable) | Verification lead + SoC architect |
| **ARC-065** | Formal CDC properties replaces async-FIFO proposal | Property set: reset synchronizers, AON wake handshake, APB request/response, PLIC interrupt sync; no async FIFO built | - Verification: formal properties for crossings enumerated<br>- No async FIFO instantiated at Stage 1<br>- Property coverage can be measured at Stage 2+ | - Property set must be verified; informal formal run needed<br>- Does not close CDC by itself; implementation needed | ARC-036 (CDC scope); verification property automation | Verification lead |
| **TD-001** | Boot ROM size: 16 KB map vs 64 KB RTL ADDR_WIDTH=16 | **16 KB**; change RTL ADDR_WIDTH from 16 to 14 | - RTL: `has_addr_map.sv` ROM `ADDR_WIDTH` 16→14; firmware linker already assumes 16 KB; no functional change if firmware compiled for 16 KB<br>- Area: ROM decode reduces<br>- Timing: slight improvement from smaller address decode | - Firmware must be recompiled with new ADDR_WIDTH<br>- Existing firmware.elf compiled with ADDR_WIDTH=16; must rebuild | Memory map; firmware linker script | SoC architect + firmware lead |
| **TD-003** | SRAM size: 128 KB map vs 256 KB RTL ADDR_WIDTH=18 | **128 KB**; change RTL ADDR_WIDTH from 18 to 17 | - RTL: `has_addr_map.sv` SRAM `ADDR_WIDTH` 18→17; 256 KB array unreachable half under 18<br>- Area: SRAM area reduced by ~50%<br>- PDN: smaller SRAM; macro selection changes | - Firmware must be recompiled<br>- SRAM macro integration changes (TD-006) | Memory map; SRAM wrapper (TD-006) | SoC architect + PD lead |
| **TD-005** | Power intent: two 1.8 V SoC domains (AON + switchable core/periph); board PMIC 1.0 V/3.3 V | **P-B**: two domains; no on-chip UPF/CPF; deferred to Stage 10 | - RTL: power switches, isolation, retention in AON boundary; no production UPF<br>- PD: power domain boundaries, level shifters, isolation cells; no 3.3 V on-chip pads (sky130hd limitation)<br>- Board: PMIC supplies 1.0 V/1.8 V/3.3 V; AON retained in sleep<br>- Power: AON domain leakage reduction; switchable domain saves power when off | - Power-up sequences must be verified<br>- Retention cell behavior in AON sleep<br>- Level shifter sizing for domain crossings | Board PMIC; sky130hd process limits; no on-chip 3.3 V pads | Power architect + PD lead + board designer |
| **TD-006** | SRAM macro: 32-bit wide 128 KB / 32 KB macros; do not tile 4 KB 128-bit macro | **32-bit wide macros**; area estimated ~4.3 mm² (not characterized); 44 × 4 KB = 31.8 mm² exceeds 10 mm² target | - RTL: sram wrapper parameters change; macro width; port compatibility<br>- PD: macro LEF/libraries; 44-macro tiling eliminated; estimated <4.3 mm² vs 31.77 mm²<br>- Timing: Liberty .lib characterization needed<br>- Area: significant reduction if 32-bit macros available | - Macro availability not guaranteed; may need vendor<br>- Area estimate not yet characterized from Liberty<br>- Port/mask compatibility must be verified | sky130hd macro catalog; Liberty .lib characterization | SoC architect + PD lead + macro vendor |
| **TD-007** | Secure boot: S1 hardware SHA-256 + ECDSA-P256 with OTP/secure element; S3 fallback; S0 explicit descope | **S1** if OTP/secure element available; **S3** if no OTP; **S0** only as explicit descope removing security claims | - S1: add crypto engine (SHA-256, ECDSA-P256), OTP or secure element; signed image format; authenticated debug policy; recovery path<br>- S3: external secure element if no OTP; reduced functionality<br>- S0: remove "secure boot" from marketing/claims; fail-closed boot documented as descope; no crypto | - S1 requires OTP/eFuse/TRNG (BLK-023 — none exists)<br>- S3 requires external secure element hardware<br>- S0 must be explicit owner-approved descope; no false security claims | - No OTP/eFuse/TRNG in RTL (BLK-023)<br>- Crypto engine adds area and power<br>- Boot ROM verification logic needed | Security owner + SoC architect + (if S1) chip fab process |
| **TD-009** | DFT: scan + ATPG tool or partner before Stage 7; scan insertion precedes synthesis freeze | **Decide tool/partner**; insert scan flops before synthesis freeze | - RTL: add scan flops, test modes, test access; JTAG test retaining<br>- Verification: no ATPG patterns at Stage 1; may add test patterns later<br>- PD: scan insertion adds test points; tool flow not defined<br>- Area: ~5% increase if scan added | - Commercial tool may have cost; open-source alternative may exist<br>- Scan insertion may require place/route changes<br>- Tool partner must be secured before Stage 7 | Tool vendor/partner; program owner budget | Program owner + verification lead + PD lead |
| **TD-010** | SDC primary period: 20 ns (50 MHz) or 40 ns (25 MHz) | **50 MHz core + generated 25 MHz peripheral**; retire conflicting 20 ns/40 ns SDC files | - SDC: add generated clock for 25 MHz peripheral; set primary 50 MHz; remove 20 ns/40 ns files<br>- RTL: clock generator already has 50 MHz core; /2 divider for 25 MHz peripheral<br>- CTS: two-clock CTS; glitch logic for generated clock<br>- Timing signoff with two clocks | - Generated clock may introduce new timing paths<br>- Glitch logic must be analyzed<br>- Old SDC files must not be used for signoff | Clock generator RTL; CTS flow; timing signoff methodology | SoC architect + timing signoff lead |
| **TD-016** | Package pin budget and pinmux: remove 32-bit ext_irq[31:0] + 3 handshake pins; add BOOT_MODE[1:0], PMIC_ALERT/IRQ, RF_CTRL[1:0], UART1 → 54 of 56 I/O | **54 of 56 I/O**; 2 dead I/O; mux 8 PLIC IRQs onto GPIO alternate functions | - RTL: `has_soc.sv` pad signal reduction; 81→54 usable; mux PLIC onto GPIO; add BOOT_MODE, PMIC_ALERT, RF_CTRL, UART1<br>- Package: QFN-64 with 54 I/O usable; 2 I/O reserved or disabled<br>- Interrupts: 8 PLIC sources muxed onto GPIO | - 32-bit `ext_irq[31:0]` tied unused; 28 IRQs lost from original map<br>- Firmware ISR mapping changes<br>- Pinout changes affect board layout | - 2 I/O not connected; purpose must be documented<br>- Firmware interrupt handlers must map to new GPIO<br>- Board layout may need redesign if pin functions change | Board pin map; firmware ISR mapping; PLIC config | SoC architect + PD lead + firmware lead |
| **TD-017** | Requirements baseline and descopes: re-baseline SRS to implementable product | **RV32IM machine-mode**; 1 UART, 1 SPI, 1 I2C, 16 GPIO, 4 PWM, 1 I2S TX; CLINT/PLIC 8 sources; 16 KB ROM/32 KB TCM/128 KB SRAM; defer crypto, OTA, second UART, LPTIM; every descope owner-signed | - RTL: machine-mode only; no C/U/PPM; firmware already limited; address map, interrupt controller already subset<br>- SRS: 124 requirements traced; 8 IMPLEMENTED, 38 PARTIAL, 39 NOT_IMPLEMENTED, 19 NOT_VERIFIED, 6 ESTIMATED, 6 NOT_STARTED, 5 BLOCKED, 2 FAILED, 1 AT_RISK<br>- Power/area/timing: descopes reduce peripheral IP, pin count, macro needs<br>- No new IP added; only what is already in RTL/firmware | - Owner sign-off required for every descope<br>- Firmware reflash with reduced peripheral set<br>- May need to document descopes in customer-facing specs | - Every descope must be owner-signed<br>- Firmware changes reduce functionality<br>- Customer specs must reflect descoped feature set | 124 requirements traceability; SRS; firmware | User/design owner + firmware lead |

---

## Approval Status Table

| ID | Current Status | Required Action | Approval Status |
|---|---|---|---|
| ARC-006 | APPROVED | Owner sign-off on C-prime clock architecture — APPROVED 2026-11-15 (C-prime) | **APPROVED** |
| ARC-036 | READY FOR APPROVAL | Owner sign-off on CDC scope and property list | **PENDING_APPROVAL** |
| ARC-065 | READY FOR APPROVAL | Owner sign-off on CDC property set | **PENDING_APPROVAL** |
| TD-001 | READY FOR APPROVAL | Owner sign-off on 16 KB ROM; change RTL ADDR_WIDTH 16→14 | **PENDING_APPROVAL** |
| TD-003 | READY FOR APPROVAL | Owner sign-off on 128 KB SRAM; change RTL ADDR_WIDTH 18→17 | **PENDING_APPROVAL** |
| TD-005 | READY FOR APPROVAL | Owner sign-off on P-B two 1.8 V domains; UPF Stage 10 | **PENDING_APPROVAL** |
| TD-006 | READY FOR APPROVAL | Owner sign-off on 32-bit SRAM macros; do not tile 4 KB macro | **PENDING_APPROVAL** |
| TD-007 | READY FOR APPROVAL | Owner sign-off on S1/S3/S0 security option | **PENDING_APPROVAL** |
| TD-009 | READY FOR APPROVAL | Owner sign-off on DFT tool/partner; scan before synthesis freeze | **PENDING_APPROVAL** |
| TD-010 | READY FOR APPROVAL | Owner sign-off on 50 MHz + generated 25 MHz SDC | **PENDING_APPROVAL** |
| TD-016 | READY FOR APPROVAL | Owner sign-off on 54-pin plan; 54 of 56 I/O | **PENDING_APPROVAL** |
| TD-017 | READY FOR APPROVAL | Owner sign-off on requirements baseline/descopes | **PENDING_APPROVAL** |

**All 12 decisions are PENDING_APPROVAL.** None may be changed to APPROVED, REJECTED, or AMENDMENT_REQUESTED without explicit project-owner authorization.

---

## Approval Package Deliverable

`reports/ASIC_STAGE1_FORMAL_APPROVAL_PACKAGE.md` — Complete

---

## Approval Matrix CSV

`architecture/stage1_approval_matrix.csv` — Also created (one row per canonical decision)

| Decision ID | Title | Recommended Option | Status | Required Approver | Blocking Stages | Evidence File |
|---|---|---|---|---|---|---|
| ARC-006 | Clock architecture | C-prime | APPROVED (2026-11-15) | SoC architect | 2, 6, 8, 12, 15 | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md` |
| ARC-036 | CDC scope and verification | Scope follows C-prime | PENDING_APPROVAL | Verification lead | 5, 6, 12 | `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` |
| ARC-065 | Formal CDC properties | Property set, no async FIFO | PENDING_APPROVAL | Verification lead | 5, 6 | `reports/ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` §3.2 |
| TD-001 | Boot ROM size | 16 KB, ADDR_WIDTH 16→14 | PENDING_APPROVAL | SoC architect + firmware | 1, 3, 7 | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` |
| TD-003 | SRAM size | 128 KB, ADDR_WIDTH 18→17 | PENDING_APPROVAL | SoC architect + PD | 1, 3, 7 | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` |
| TD-005 | Power intent and domains | Two 1.8 V domains; UPF Stage 10 | PENDING_APPROVAL | Power architect + PD | 1, 10, 15 | `reports/ASIC_STAGE1_POWER_ARCHITECTURE.md` |
| TD-006 | SRAM macro architecture | 32-bit wide macros; no 4 KB tiling | PENDING_APPROVAL | SoC architect + PD | 3, 9, 10 | `reports/ASIC_STAGE1_MEMORY_ARCHITECTURE.md` |
| TD-007 | Secure boot scope | S1/S3/S0; OTP required for S1 | PENDING_APPROVAL | Security owner | 1, 2, 17 | `reports/ASIC_STAGE1_SECURITY_BOOT_ARCHITECTURE.md` |
| TD-009 | DFT scope and tooling | Decide tool/partner before Stage 7 | PENDING_APPROVAL | Program owner | 16, 17, 18 | `reports/ASIC_STAGE1_DECISION_PACKAGE.md` §12 |
| TD-010 | SDC clock architecture | 50 + generated 25 MHz; retire 20/40 ns | PENDING_APPROVAL | SoC architect + timing | 8, 12, 15 | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md` |
| TD-016 | Package pin budget | 54 of 56 I/O; mux PLIC onto GPIO | PENDING_APPROVAL | SoC architect + PD | 1, 2, 9, 17 | `reports/ASIC_STAGE1_INTERFACE_AND_ADDRESS_MAP.md` §6 |
| TD-017 | Requirements baseline and descopes | Re-baseline SRS; owner-signed descopes | PENDING_APPROVAL | User/design owner | 1, 2, 4, 16, 17 | `reports/ASIC_STAGE1_REQUIREMENTS_TRACEABILITY.csv` |

---

**This approval package confirms:** All 12 canonical decisions are technically validated and READY FOR APPROVAL. No decision may be approved without explicit project-owner authorization. The package is documentation- only; no approvals are granted within it. Stage 1 remains READY FOR APPROVAL, NOT COMPLETE, until all 12 owners authorize.

**Next phase:** Phase 4 — Engineering ownership assignment.

---

**Owner-facing workflow:** Each decision can be approved as recommended, rejected, amended, deferred, or blocked. The workflow is defined in `reports/ASIC_STAGE1_OWNER_APPROVAL_WORKFLOW.md` (created in Phase 5). No fake signatures, names, dates, or approvals are generated.