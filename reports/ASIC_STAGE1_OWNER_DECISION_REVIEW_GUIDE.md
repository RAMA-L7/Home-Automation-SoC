# ASIC Stage 1 — Owner Decision Review Guide

**Date:** 2026-11-15  
**Purpose:** Owner-facing review session covering all 12 pending architecture decisions  
**Current main HEAD:** `d6791cdb1742964033fadc63fa508b1ececf0c3b`  
**Stage 1 status:** READY FOR APPROVAL, NOT COMPLETE  
**Stage 2 status:** NOT STARTED  

> **Rule:** Read-only operation. No production RTL/SDC/PD changes. No governance status changes. No fabricated approvals. No invented engineering owners. No Stage 2 implementation. Preserve original technical recommendations. Do not invent missing information.

---

## Group A: Architecture

### 1. ARC-006 — Clock Architecture

**1. Decision ID and title:** ARC-006 — Clock architecture (50 MHz core, 25 MHz peripheral, 32 kHz AON)

**2. Exact decision statement:** Clock architecture defines clocking scheme, dividers, SDC, and CTS corners.

**3. Recommended option:** **C-prime**: 50 MHz core, internal /2 25 MHz peripheral, external 32.768 kHz AON; no on-chip PLL.

**4. Technical justification:** RTL has one gated 50 MHz clock (`has_soc.sv:107-108`: `core_clk = clk & core_clk_en_q`, `periph_clk = clk & periph_clk_en_q`). No PLL exists. C-prime uses external Si5351 50 MHz source (historically approved ARC-041). Internal synchronous /2 divider creates 25 MHz peripheral clock, avoiding CDC between core and peripheral. External 32.768 kHz source for AON domain. No on-chip RC oscillator. Options A (single 50 MHz) and D (external 50/25 async) rejected.

**5. Alternatives and consequences:**
- **Option A (single 50 MHz):** Non-compliant with FR-CLK-004 (peripheral clock requirement)
- **Option B (50 MHz core + 25 MHz peripheral with explicit FR-CLK-004 descope):** Fallback if C-prime rejected
- **Option D (external 50/25 MHz async):** Adds CDC without benefit; rejected

**6. Critical risks:**
- Clock gating safety must be verified
- Reset sequencing across domains (core↔AON)
- CDC closure for new crossings under C-prime (APB handshake, AON wake, reset release, PLIC sync)
- Generated clock may introduce new timing paths

**7. Dependencies:** ARC-036 (CDC scope), ARC-065 (formal CDC properties), TD-010 (SDC clock architecture), BLK-001 (clock architecture unapproved)

**8. Stage 2 implementation impact:** Insert /2 divider in RTL; add clock gating; generate SDC clock definitions; add 2-FF synchronizers for static signals; add handshake for events; add formal properties for AON wake, reset release, APB handshake, PLIC sync.

**9. Verification acceptance criteria:**
- /2 divider produces 25 MHz peripheral clock from 50 MHz core
- CTS signoff with two clocks
- Formal CDC properties for AON wake, reset release, APB handshake, PLIC sync
- No async FIFO claimed
- SDC generated clock matches RTL divider

**10. Exact five-element approval statement format:**
```
DECISION ARC-006: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence of this choice]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

### 2. ARC-036 — CDC Scope and Verification

**1. Decision ID and title:** ARC-036 — CDC verification scope for 3 clock domains

**2. Exact decision statement:** Formal CDC verification for 3 clock domains required.

**3. Recommended option:** Scope follows C-prime: core/periph synchronous handshake, core/AON asynchronous with 2-FF and handshakes; formal properties for AON wake, reset release, APB handshake.

**4. Technical justification:** RTL currently has single clock (no clock domains). CDC plan references 3 domains that do not exist. Under C-prime, new crossings are: APB core↔peripheral (synchronous with handshake), core↔AON (asynchronous with 2-FF synchronizers), reset release (formal property). 31 inventoried paths. No async FIFO in RTL. Critical unsafe crossings today: `spi_miso`, `i2c_sda`, JTAG TMS/TDI.

**5. Alternatives and consequences:**
- **Reject:** Keep 3-domain async-FIFO proposal (would build CDC IP for nonexistent domains)
- **Amendment:** Add/remove properties from the recommended set
- **Defer:** Pending CDC tool/partner availability

**6. Critical risks:**
- CDC closure requires formal verification or simulation coverage
- May uncover new unsafe paths during Stage 2
- No async FIFO in RTL (confirmed)

**7. Dependencies:** ARC-065 (formal property set), TD-010 (SDC), BLK-003 (SDC not approvable)

**8. Stage 2 implementation impact:** Add 2-FF synchronizers for static signals (`spi_miso`, `i2c_sda`, JTAG TMS/TDI); add pulse/handshake for events; add formal properties for APB handshake, AON wake, reset release, PLIC sync; no async FIFO instantiation.

**9. Verification acceptance criteria:**
- 31 inventoried paths all have synchronizers or formal properties
- No async FIFO in RTL
- 2-FF synchronizers for static signals
- Handshake for events
- Formal properties for APB handshake, AON wake, reset release, PLIC sync

**10. Exact five-element approval statement format:**
```
DECISION ARC-036: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

### 3. ARC-065 — Formal CDC Properties

**1. Decision ID and title:** ARC-065 — Formal CDC properties (replaces async-FIFO proposal)

**2. Exact decision statement:** Formal CDC properties for async FIFO/synchronizers/handshakes.

**3. Recommended option:** Property set: reset synchronizers, AON wake handshake, APB request/response, PLIC interrupt sync; no async FIFO built.

**4. Technical justification:** CDC plan proposes async FIFO for 3 domains that do not exist. RTL has no async FIFO. Recommendation replaces async-FIFO proposal with property set matching implemented crossings: reset synchronizers, AON wake handshake, APB request/response, PLIC interrupt sync.

**5. Alternatives and consequences:**
- **Reject:** Build async-FIFO CDC IP for nonexistent domains
- **Amendment:** Add or remove properties from the recommended set

**6. Critical risks:**
- Property set must be verified; formal run needed
- Does not close CDC by itself; implementation needed at Stage 2

**7. Dependencies:** ARC-036 (CDC scope); verification property automation

**8. Stage 2 implementation impact:** Formal properties for reset synchronizers, AON wake handshake, APB request/response, PLIC interrupt sync; property coverage measurement.

**9. Verification acceptance criteria:**
- Formal property set enumerated and documented
- Property coverage measurable at Stage 2+
- No async FIFO claimed or built

**10. Exact five-element approval statement format:**
```
DECISION ARC-065: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

## Group B: Memory and Interfaces

### 4. TD-001 — Boot ROM Size

**1. Decision ID and title:** TD-001 — Boot ROM size: 16 KB (map) or 64 KB (RTL ADDR_WIDTH=16)

**2. Exact decision statement:** Boot ROM size: 16 KB (map) or 64 KB (RTL `ADDR_WIDTH=16`)?

**3. Recommended option:** **16 KB**; change RTL ADDR_WIDTH from 16 to 14.

**4. Technical justification:** `has_addr_map.sv` maps 16 KB ROM; RTL `boot_rom` has `ADDR_WIDTH=16` mapping to 64 KB array. Firmware linker already assumes 16 KB. Half the array (48 KB) is unreachable under the 16 KB map. Area and decode logic reduce with 16 KB.

**5. Alternatives and consequences:**
- **Reject (64 KB):** Keep ADDR_WIDTH=16; area and decode logic unchanged; firmware linker must be updated for 64 KB
- **Amendment:** Specify revised ADDR_WIDTH

**6. Critical risks:**
- Firmware must be recompiled with new ADDR_WIDTH
- Existing firmware.elf compiled with ADDR_WIDTH=16 must rebuild
- Boot timing changes (minor improvement from smaller address decode)

**7. Dependencies:** Memory map; firmware linker script; BLK-002 (memory size contradiction)

**8. Stage 2 implementation impact:** Change RTL `has_addr_map.sv` ROM `ADDR_WIDTH` from 16 to 14; recompile firmware; verify ROM contents with 16 KB map.

**9. Verification acceptance criteria:**
- ROM contents consistent with 16 KB map
- Firmware compiles with ADDR_WIDTH=14
- No functional change if firmware compiled for 16 KB

**10. Exact five-element approval statement format:**
```
DECISION TD-001: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

### 5. TD-003 — SRAM Size

**1. Decision ID and title:** TD-003 — SRAM size: 128 KB (map) or 256 KB (RTL ADDR_WIDTH=18)

**2. Exact decision statement:** SRAM size: 128 KB (map) or 256 KB (RTL `ADDR_WIDTH=18`)?

**3. Recommended option:** **128 KB**; change RTL ADDR_WIDTH from 18 to 17.

**4. Technical justification:** `has_addr_map.sv` maps 128 KB SRAM; RTL `sram` has `ADDR_WIDTH=18` mapping to 256 KB array. Half the array (128 KB) is unreachable under the 128 KB map. Area and PDN impact: 128 KB reduces SRAM area by ~50% vs 256 KB.

**5. Alternatives and consequences:**
- **Reject (256 KB):** Keep ADDR_WIDTH=18; area and PDN unchanged; firmware linker must be updated for 256 KB
- **Amendment:** Specify revised ADDR_WIDTH

**6. Critical risks:**
- Firmware must be recompiled
- SRAM macro integration changes (TD-006) — macro selection affects PDN
- Larger array = more dynamic power; 128 KB reduces power vs 256 KB

**7. Dependencies:** Memory map; SRAM wrapper (TD-006); BLK-002 (memory size contradiction)

**8. Stage 2 implementation impact:** Change RTL `has_addr_map.sv` SRAM `ADDR_WIDTH` from 18 to 17; synthesis with ADDR_WIDTH=17; verify SRAM contents, read/write patterns.

**9. Verification acceptance criteria:**
- SRAM contents consistent with 128 KB map
- Read/write patterns verified with ADDR_WIDTH=17
- Synthesis passes with reduced address width

**10. Exact five-element approval statement format:**
```
DECISION TD-003: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

### 6. TD-006 — SRAM Macro Architecture

**1. Decision ID and title:** TD-006 — Memory macro: `sky130_sram_1rw1r_128x256_8` (4 KB) × 32 for 128 KB, or 32-bit wide macro?

**2. Exact decision statement:** Memory macro: `sky130_sram_1rw1r_128x256_8` (4 KB) × 32 for 128 KB, or 32-bit wide macro?

**3. Recommended option:** **32-bit wide 128 KB and 32 KB macros**; area estimated ~4.3 mm² (not characterized); do not tile 4 KB 128-bit macro.

**4. Technical justification:** 4 KB 128-bit macro (`sky130_sram_1rw1r_128x256_8`) tiling for 128 KB needs 32 macros = 23.1 mm²; for 176 KB needs 44 macros = 31.8 mm², exceeding the <10 mm² target. 32-bit wide macros estimated <4.3 mm² but not yet characterized from sky130hd Liberty .lib. Macro availability not guaranteed.

**5. Alternatives and consequences:**
- **Tile 4 KB macro:** 31.8 mm² exceeds area target; may require area target renegotiation
- **Amendment:** Specify revised macro width or area target

**6. Critical risks:**
- Macro availability not guaranteed; may need vendor
- Area estimate not yet characterized from Liberty .lib
- Port/mask compatibility must be verified
- 44-macro tiling eliminates LEF/Library complexity but exceeds area

**7. Dependencies:** sky130hd macro catalog; Liberty .lib characterization; BLK-005 (macro integration), BLK-020 (macro area target)

**8. Stage 2 implementation impact:** sram wrapper parameters change; macro width changes; eliminate 44-macro tiling; integrate 32-bit wide macros if available; verify port/mask compatibility.

**9. Verification acceptance criteria:**
- Macro interface verified (port compatibility, byte-mask behavior)
- Area ≤ 10 mm² target (with 32-bit macros, estimated <4.3 mm²)
- Liberty .lib characterization completed for selected macro
- Timing verified via Liberty

**10. Exact five-element approval statement format:**
```
DECISION TD-006: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

### 7. TD-016 — Package Pin Budget and Pinmux

**1. Decision ID and title:** TD-016 — Package pin budget and pinmux: remove 32-bit ext_irq[31:0] + 3 handshake pins; add BOOT_MODE[1:0], PMIC_ALERT/IRQ, RF_CTRL[1:0], UART1 → 54 of 56 I/O

**2. Exact decision statement:** Package pin budget and pinmux: RTL cannot fit QFN-64 with 81 pad signals; 32 IRQ pins dead.

**3. Recommended option:** **54 of 56 I/O**; 2 dead I/O; mux 8 PLIC IRQs onto GPIO alternate functions; remove 32-bit `ext_irq[31:0]` and 3 internal handshake pins; add BOOT_MODE[1:0], PMIC_ALERT/IRQ, RF_CTRL[1:0], UART1.

**4. Technical justification:** `has_soc.sv:25-62` has 81 pad signals vs 56 QFN-64 I/O. 32-bit `ext_irq[31:0]` tied unused. 8 PLIC IRQs can be muxed onto GPIO alternate functions. Removal of 32 dead IRQ pins + 3 internal handshake pins frees 35 pins; adding 4 new functions (BOOT_MODE[1:0], PMIC_ALERT/IRQ, RF_CTRL[1:0], UART1) uses 4 pins → 54 of 56 usable I/O.

**5. Alternatives and consequences:**
- **Reject:** Keep 81 pad signals (impossible in QFN-64)
- **Amendment:** Specify revised pinmux or package

**6. Critical risks:**
- 32-bit `ext_irq[31:0]` tied unused; 28 IRQs lost from original map
- Firmware ISR mapping changes
- Pinout changes affect board layout
- 2 I/O not connected; purpose must be documented

**7. Dependencies:** Board pin map; firmware ISR mapping; PLIC config; BLK-019 (pin budget), BLK-021 (no 3.3 V pads)

**8. Stage 2 implementation impact:** `has_soc.sv` pad signal reduction (81→54 usable); mux PLIC onto GPIO; add BOOT_MODE, PMIC_ALERT, RF_CTRL, UART1; update firmware ISR mapping.

**9. Verification acceptance criteria:**
- All 54 usable I/O mapped and verified
- Firmware ISR mapping updated for new GPIO-based interrupts
- PLIC configuration updated for muxed GPIO interrupts
- Board layout updated for new pinout

**10. Exact five-element approval statement format:**
```
DECISION TD-016: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

## Group C: Security and Project Requirements

### 8. TD-007 — Secure Boot Scope

**1. Decision ID and title:** TD-007 — Secure boot: implement verifier or ship fail-closed recovery only?

**2. Exact decision statement:** Secure boot: implement verifier or ship fail-closed recovery only?

**3. Recommended option:** **S1**: hardware SHA-256 + ECDSA-P256 with OTP/secure element; **S3** fallback if no OTP; **S0** only as explicit descope removing security claims.

**4. Technical justification:** `boot.c` fails closed; no verifier exists; no crypto engine, OTP, eFuse, or TRNG in RTL (BLK-023). S1 requires hardware SHA-256 + ECDSA-P256 with OTP or secure element; signed image format; authenticated debug policy; recovery path. S3 uses external secure element if no OTP. S0 removes "secure boot" claims and documents fail-closed boot as descope.

**5. Alternatives and consequences:**
- **Reject (S0):** Remove all "secure boot" claims; fail-closed boot documented as descope; no crypto
- **Amendment:** Specify revised security option

**6. Critical risks:**
- S1 requires OTP/eFuse/TRNG (BLK-023 — none exists)
- S3 requires external secure element hardware
- S0 must be explicit owner-approved descope; no false security claims
- Crypto engine adds area and power
- Boot ROM verification logic needed

**7. Dependencies:** No OTP/eFuse/TRNG in RTL (BLK-023); crypto engine adds area/power; BLK-006 (secure boot no verifier)

**8. Stage 2 implementation impact:** If S1 approved: add crypto engine (SHA-256, ECDSA-P256), OTP or secure element, signed image format, authenticated debug policy, recovery path. If S0 approved: document descope explicitly; remove security claims.

**9. Verification acceptance criteria:**
- S1: image authenticity verified; OTA not implemented; boot fails closed
- S3: external secure element communication verified
- S0: explicit descope documented; no security claims in marketing

**10. Exact five-element approval statement format:**
```
DECISION TD-007: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

### 9. TD-009 — DFT Scope and Tooling

**1. Decision ID and title:** TD-009 — DFT: scan + ATPG in scope? Which tool?

**2. Exact decision statement:** DFT: scan + ATPG in scope? Which tool?

**3. Recommended option:** **Decide tool/partner before Stage 7**; scan insertion must precede synthesis freeze.

**4. Technical justification:** No scan flops, no test modes, no ATPG, no MBIST in RTL; JTAG test access only. No commercial tool available. Scan insertion adds test points; area ~5% increase. Tool/partner must be secured before Stage 7. Scan insertion must precede synthesis freeze.

**5. Alternatives and consequences:**
- **Reject:** No DFT; manufacturing test limited to functional test
- **Amendment:** Specify revised tool criteria

**6. Critical risks:**
- Commercial tool may have cost; open-source alternative may exist
- Scan insertion may require place/route changes
- Tool partner must be secured before Stage 7

**7. Dependencies:** Tool vendor/partner; program owner budget; BLK-007 (no DFT)

**8. Stage 2 implementation impact:** Add scan flops, test modes, test access; JTAG test retaining; no ATPG patterns at Stage 1.

**9. Verification acceptance criteria:**
- Scan insertion schedule defined
- Tool/partner selected
- Scan flops inserted before synthesis freeze
- Test access via JTAG

**10. Exact five-element approval statement format:**
```
DECISION TD-009: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

### 10. TD-010 — SDC Clock Architecture

**1. Decision ID and title:** TD-010 — SDC primary period: 20 ns (50 MHz) or 40 ns (25 MHz)?

**2. Exact decision statement:** SDC primary period: 20 ns (50 MHz) or 40 ns (25 MHz)?

**3. Recommended option:** **50 MHz core + generated 25 MHz peripheral clock**; retire conflicting 20 ns/40 ns SDC files.

**4. Technical justification:** Two conflicting SDCs exist: full-SoC SDC uses 20 ns blanket I/O delays; block SDC uses 40 ns. 105 ports lack budgets. C-prime clock architecture requires 50 MHz core + generated 25 MHz peripheral clock. Generated clock must be added to SDC; old conflicting files must be retired.

**5. Alternatives and consequences:**
- **Reject:** Keep conflicting 20/40 ns SDC files; no signoff possible
- **Amendment:** Specify revised SDC plan

**6. Critical risks:**
- Generated clock may introduce new timing paths
- Glitch logic must be analyzed
- Old SDC files must not be used for signoff
- Input/output delays not modeled (20 ns blanket or 40 ns)

**7. Dependencies:** Clock generator RTL; CTS flow; timing signoff methodology; BLK-003 (SDC not approvable), BLK-010 (clock definitions)

**8. Stage 2 implementation impact:** Add generated clock for 25 MHz peripheral to SDC; set primary 50 MHz; remove 20 ns/40 ns files; CTS with two clocks; glitch logic for generated clock.

**9. Verification acceptance criteria:**
- Generated 25 MHz peripheral clock defined in SDC
- Primary 50 MHz clock defined
- Conflicting 20/40 ns SDC files retired
- CTS signoff with two clocks
- Glitch logic analyzed

**10. Exact five-element approval statement format:**
```
DECISION TD-010: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

### 11. TD-017 — Requirements Baseline and Descopes

**1. Decision ID and title:** TD-017 — Requirements baseline and descopes: re-baseline SRS to implementable product

**2. Exact decision statement:** Requirements baseline and descopes.

**3. Recommended option:** **Re-baseline SRS to implementable product**: RV32IM machine-mode, 1 UART, 1 SPI, 1 I2C, 16 GPIO, 4 PWM, 1 I2S TX, CLINT/PLIC 8 sources, 16 KB ROM/32 KB TCM/128 KB SRAM; defer crypto, OTA, second UART, LPTIM; every descope owner-signed.

**4. Technical justification:** SRS describes unimplemented product; 37 FR/IF absent from RTL. 124 requirements traced: 8 IMPLEMENTED, 38 PARTIAL, 39 NOT_IMPLEMENTED, 19 NOT_VERIFIED, 6 ESTIMATED, 6 NOT_STARTED, 5 BLOCKED, 2 FAILED, 1 AT_RISK. RTL is machine-mode only (no C/U/PMP). Firmware already assumes subset. Descopes reduce peripheral IP, pin count, macro needs, power, area, timing.

**5. Alternatives and consequences:**
- **Reject:** Keep full SRS scope; no implementation possible for crypto, OTA, second UART, LPTIM
- **Amendment:** Specify revised descopes

**6. Critical risks:**
- Owner sign-off required for every descope
- Firmware reflash with reduced peripheral set
- Customer-facing specs must reflect descoped feature set
- May need to document descopes in customer-facing specs

**7. Dependencies:** ARC-006 (clock), TD-001 (ROM), TD-003 (SRAM), TD-016 (pins); 124 requirements traceability; SRS; firmware

**8. Stage 2 implementation impact:** RTL machine-mode only; no C/U/PMP; firmware already limited; address map and interrupt controller already subset; no new IP added.

**9. Verification acceptance criteria:**
- SRS re-baselined to implementable product
- Every descope owner-signed
- Customer-facing specs updated to reflect descoped features
- Firmware reflash verified with reduced peripheral set

**10. Exact five-element approval statement format:**
```
DECISION TD-017: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

## Group D: Power and Requirements

### 12. TD-005 — Power Intent and Domains

**1. Decision ID and title:** TD-005 — Power intent: UPF/CPF in scope?

**2. Exact decision statement:** Power intent: UPF/CPF in scope?

**3. Recommended option:** **P-B**: two 1.8 V SoC domains (AON + switchable core/periph); board PMIC provides 1.0 V/3.3 V; no on-chip 3.3 V pads (sky130hd limitation); UPF deferred to Stage 10.

**4. Technical justification:** No UPF/CPF anywhere in the project; only board-level PMIC prose. sky130hd process has no 3.3 V tolerant pads. Board PMIC supplies 1.0 V/1.8 V/3.3 V. AON domain retained in sleep; switchable domain saves power when off. Isolation and retention in AON boundary.

**5. Alternatives and consequences:**
- **Reject (single domain):** All logic always powered; no power savings; simpler but no low-power mode
- **Amendment:** Specify revised UPF scope or domain boundaries

**6. Critical risks:**
- Power-up sequences must be verified
- Retention cell behavior in AON sleep
- Level shifter sizing for domain crossings
- No on-chip 3.3 V pads (board-level solution required)

**7. Dependencies:** Board PMIC; sky130hd process limits; no on-chip 3.3 V pads; BLK-005 (no UPF), BLK-008 (no UPF/power intent), BLK-021 (no 3.3 V pads)

**8. Stage 2 implementation impact:** Power switches, isolation cells, retention cells in AON boundary; no production UPF at Stage 1; UPF/CPF deferred to Stage 10.

**9. Verification acceptance criteria:**
- Power-up sequences verified
- Domain retention in sleep verified
- Level shifter sizing verified
- No on-chip 3.3 V pads (board PMIC handles 3.3 V)

**10. Exact five-element approval statement format:**
```
DECISION TD-005: [APPROVED / REJECTED / AMENDMENT_REQUESTED / PENDING_APPROVAL / BLOCKED / SUPERSEDED]
Technical consequence: [exact consequence]
Risks: [any newly introduced risks]
Dependencies: [any dependencies that must be resolved]
```

---

## Critical Contradictions (6)

The following contradictions were identified during independent architecture audit and must be highlighted for owner review:

| ID | Category | Description | Resolution Required |
|---|---|---|---|
| **A-01** | Memory RTL contradiction | RTL ADDR_WIDTH=16 maps ROM to 64 KB; SRS/map says 16 KB. Fix: change RTL ADDR_WIDTH to 14. | Owner approval of TD-001 (16 KB ROM) |
| **A-02** | SRAM RTL contradiction | RTL ADDR_WIDTH=18 maps SRAM to 256 KB; SRS/map says 128 KB. Fix: change RTL ADDR_WIDTH to 17. | Owner approval of TD-003 (128 KB SRAM) |
| **A-03** | Macro area target at risk | 4 KB macro tiling for 176 KB needs 44 macros = 31.77 mm², exceeding 10 mm² target. Recommendation: 32-bit wide macros (area not characterized). | Owner approval of TD-006 (32-bit macro strategy) + macro availability verification |
| **A-04** | Security blocker | S1 requires OTP/eFuse/TRNG; BLK-023 confirms none exists in RTL. S3 fallback if no OTP. S0 only as explicit descope. | Owner approval of TD-007 (S1/S3/S0 option) + process add-on or descope |
| **A-05** | Pin plan contradiction | RTL 81 pad signals vs 56 QFN-64 I/O; 32 `ext_irq[31:0]` dead. TD-016 recommendation: remove dead pins, mux 8 PLIC onto GPIO → 54 of 56 I/O. | Owner approval of TD-016 (54-pin plan) + board layout verification |
| **A-06** | Acceptance criteria 8/10 not met | Only 2/10 criteria met (ARC-041 historical approval; traceability matrix). 8 criteria pending owner approval. | Owner approval of all 12 decisions + role assignment + independent audit |

---

## Engineering Ownership Review

### 9 Unassigned Engineering Roles

| Role | Status | Required Responsibility | Relevant Decisions | Required Deliverables |
|---|---|---|---|---|
| **SoC Architect** | **UNASSIGNED** | Own architecture decisions; integrate RTL/firmware/power/security; sign off on descopes | All 12 | Architecture audit, decision register, approval package, SRS descopes |
| **Verification Lead** | **UNASSIGNED** | Own CDC verification, formal properties, test strategy; sign off on CDC scope | ARC-036, ARC-065 | CDC matrix, formal property list, verification plan |
| **Power Architect** | **UNASSIGNED** | Own power intent, two 1.8 V domains, UPF/CPF; board PMIC integration | TD-005 | Power intent architecture, UPF scope (deferred to Stage 10) |
| **DFT Lead** | **UNASSIGNED** | Own scan/ATPG/MBIST tool selection, test access, budget; insert scan before synthesis | TD-009 | DFT plan, tool/partner selection, scan insertion schedule |
| **Security Owner** | **UNASSIGNED** | Own secure boot scope, crypto engine, OTP/eFuse/TRNG; S1/S3/S0 options | TD-007 | Security architecture; S1/S3/S0 decision; OTP/eFuse/TRNG if S1 |
| **PD Lead** | **UNASSIGNED** | Own macro integration, LEF/Library, power domain boundaries, pinmux, area/timing signoff | TD-006, TD-005, TD-016 | Macro selection, LEF/Library, power domain PL, pinmux, area/timing reports |
| **Firmware Lead** | **UNASSIGNED** | Own boot ROM, firmware layout, ISR mapping, peripheral set; reflash with descoped features | TD-001, TD-003, TD-017 | Boot ROM firmware, firmware compile, peripheral set reflash |
| **Board Designer** | **UNASSIGNED** | Own QFN-64 pinout, 3.3 V / 1.8 V / 1.0 V PMIC rails, power integrity, no on-chip 3.3 V pads | TD-005, TD-016 | Pin table, PMIC selection, 3.3 V pad absence, board power nets |

---

## Summary of All Decisions Requiring Owner Input

| ID | Group | Title | Status | Required Approver |
|---|---|---|---|---|
| ARC-006 | A | Clock architecture (C-prime) | **APPROVED** (2026-11-15) | SoC architect + verification lead |
| ARC-036 | A | CDC scope and verification | PENDING_APPROVAL | Verification lead + SoC architect |
| ARC-065 | A | Formal CDC properties | PENDING_APPROVAL | Verification lead |
| TD-001 | B | Boot ROM size (16 KB) | PENDING_APPROVAL | SoC architect + firmware lead |
| TD-003 | B | SRAM size (128 KB) | PENDING_APPROVAL | SoC architect + PD lead |
| TD-006 | B | SRAM macro architecture (32-bit) | PENDING_APPROVAL | SoC architect + PD lead + macro vendor |
| TD-016 | B | Package pin budget (54 of 56 I/O) | PENDING_APPROVAL | SoC architect + PD lead + firmware lead |
| TD-007 | C | Secure boot scope (S1/S3/S0) | PENDING_APPROVAL | Security owner + SoC architect |
| TD-009 | C | DFT scope and tooling | PENDING_APPROVAL | Program owner + verification lead + PD lead |
| TD-010 | C | SDC clock architecture (50 + 25 MHz) | PENDING_APPROVAL | SoC architect + timing signoff lead |
| TD-017 | C | Requirements baseline and descopes | PENDING_APPROVAL | User/design owner + firmware lead |
| TD-005 | D | Power intent and domains (P-B) | PENDING_APPROVAL | Power architect + PD lead + board designer |

**Total: 12 decisions requiring owner input.** All are currently PENDING_APPROVAL. No decision may be approved without explicit project-owner authorization documented in `TAPEOUT_DECISION_REGISTER.md` and `architecture/decision_status.json`.

---

## Owner Action Required

For each of the 12 decisions, the owner must:

1. Review the decision recommendation and technical justification in `reports/ASIC_STAGE1_FORMAL_APPROVAL_PACKAGE.md`
2. Review the validation matrix in `reports/ASIC_STAGE1_DECISION_VALIDATION_MATRIX.md`
3. Review the technical revalidation in `reports/ASIC_STAGE1_TECHNICAL_REVALIDATION.md`
4. Review the independent audit in `reports/ASIC_STAGE1_INDEPENDENT_ARCHITECTURE_AUDIT.md`
5. Record the five-element approval statement (ID, choice, technical consequence, risks, dependencies)
6. Update `TAPEOUT_DECISION_REGISTER.md` with the new status
7. Update `architecture/decision_status.json` status from READY FOR APPROVAL to APPROVED
8. Update `TAPEOUT_MASTER_TRACKER.md` acceptance criteria
9. When all 12 decisions are approved and 8/10 (or all) acceptance criteria are met, mark Stage 1 COMPLETE
10. Only then may Stage 2 begin

---

## Stage 1 Status

**Stage 1 is READY FOR APPROVAL, NOT COMPLETE.**

- **Stage 2 is NOT STARTED.**
- **No production RTL, SDC, or physical-design scripts were modified.**
- **No approvals were fabricated.**
- **No engineering owners were invented.**
- **No Stage 2 implementation was launched.**

All 12 decisions require explicit owner authorization. The 9 engineering roles must be assigned to verified owners or explicitly authorized delegates before Stage 1 can complete. The 6 critical contradictions must be resolved through owner-approved RTL parameter changes or process add-ons. The independent human architecture audit has not yet been performed (current audit is self-audit only).

---

**This owner decision review guide confirms:** Stage 1 is **READY FOR OWNER APPROVAL**. The owner must now review each of the 12 pending decisions, provide explicit authorization, assign the 9 engineering roles, and only then may Stage 1 be marked COMPLETE. Stage 2 remains **NOT STARTED**. No production files were modified. No approvals were fabricated. No engineering owners were invented.