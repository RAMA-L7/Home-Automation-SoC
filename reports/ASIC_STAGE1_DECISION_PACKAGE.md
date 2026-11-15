# ASIC Stage 1 — Decision Package

Date: 2026-11-15
Status: **READY FOR APPROVAL**
Authority: User remains project decision authority. No decision below is approved by this document.

How to use: approve, reject or amend each decision; record the choice in `TAPEOUT_DECISION_REGISTER.md`. Stage 1 cannot be COMPLETE until all mandatory decisions are resolved.

---

## 1. Decision summary

| ID | Decision | Recommendation | Blocks | Status |
|---|---|---|---|---|
| ARC-006 | Clock architecture | C-prime: 50 MHz core, /2 25 MHz periph, external 32.768 kHz AON | 2, 6, 8, 12, 15 | READY |
| ARC-036 | CDC/RDC scope | Replace 3-domain async FIFO plan with crossing set in CDC report | 5, 6 | READY |
| ARC-041 | External clock source | Keep Si5351; no on-chip PLL | — | APPROVED (historical) |
| ARC-065 | Formal CDC properties | Property set: APB handshake, AON wake, reset release, PLIC sync | 5, 6 | READY |
| TD-001 | Boot ROM size | 16 KB; fix RTL to 14-bit address | 2, 3, 7 | READY |
| TD-003 | SRAM size | 128 KB; fix RTL to 17-bit address | 2, 3, 7 | READY |
| TD-006 | Memory macro | 32-bit wide 128 KB/32 KB macros; do not tile 4 KB macro | 3, 9, 10 | READY |
| TD-005 | Power domains/UPF | Two 1.8 V domains (AON + switchable); UPF in Stage 10 | 1, 10, 15 | READY |
| TD-007 | Security/boot | S1 hardware verified boot with OTP/secure element; S0 only as explicit descope | 1, 2, 17 | READY |
| TD-010 | SDC clock plan | 50 MHz + generated 25 MHz + 32 kHz; retire conflicting files | 8, 12, 15 | READY |
| TD-016 | Pin/interface baseline | 54-pin package plan; RTL map is authoritative | 1, 2, 9, 17 | READY |
| TD-017 | Requirements baseline | Re-baseline to implementable product; explicit descopes | 1, 2, 4, 16, 17 | READY |
| TD-009 | DFT scope | Decide scan/ATPG tool/budget before Stage 7 | 16, 17, 18 | READY |

---

## 2. ARC-006 — Clock architecture

- **Current:** one 50 MHz clock; core/periph gated copies; no divider, AON or PLL; FR-CLK-002/004 unmet.
- **Options:** A single 50 MHz + enables; B 50 + /2 25; C B + 32 kHz AON; D external 50/25/32k.
- **Pros of C:** meets peripheral and low-power requirements; synchronous core/periph divider; single clock source; scalable.
- **Cons of C:** AON domain, CDC, power intent and verification work; firmware timing changes.
- **Risks:** AON isolation/sequencing bugs; 2:1 APB handshake; schedule pressure to choose A.
- **Downstream:** SDC, CTS, STA, power, firmware, CDC.
- **Recommendation:** C-prime with external 32.768 kHz source.
- **Fallback:** B with explicit FR-CLK-004 descope.
- **Approval:** user/design owner.
- **Acceptance:** ARC-006 rewritten and signed; SDC plan signed; board 32 kHz accepted; firmware change list accepted.

## 3. ARC-036 / ARC-065 — CDC and RDC

- **Current:** single clock; three unsafe pin crossings (SPI MISO, I2C SDA, JTAG TMS/TDI); one reset domain.
- **Options:** keep 3-domain async FIFO plan (no object in RTL); adopt crossing-specific plan; defer CDC.
- **Pros of adopted plan:** matches actual and proposed crossings; avoids fake FIFO work; formalizable.
- **Cons:** real async AON paths; handshake verification effort.
- **Risks:** APB 2:1 handshake data loss; reset release metastability; pulse loss on PLIC/GPIO.
- **Downstream:** Stage 5 formal, Stage 6 closure, Stage 12 CTS.
- **Recommendation:** approve the crossing matrix and property set in `ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md` §3.2.
- **Approval:** user/design owner + verification owner.
- **Acceptance:** property list approved; unsafe crossings accepted for Stage 2 fix; no 3-domain claim remains.

## 4. ARC-041 — External clock source

- **Current:** approved historical decision to use Si5351; RTL has a single clock pin; no PLL.
- **Options:** keep external source; integrate PLL (no qualified IP); use crystal + internal PLL (unavailable).
- **Recommendation:** keep ARC-041; require board 50 MHz and 32.768 kHz sources.
- **Approval:** confirm in Stage 1 package (no change requested).
- **Acceptance:** board clock tree documented; clock pins in pin plan.

## 5. TD-001 / TD-003 — Memory sizes

- **Current:** ROM array 64 KB vs 16 KB map; SRAM array 256 KB vs 128 KB map.
- **Options:**
  - Fix RTL to map (recommended): 16 KB ROM, 128 KB SRAM.
  - Enlarge map to RTL: 64 KB ROM, 256 KB SRAM (firmware/linker/area change).
  - Reduce both (not justified).
- **Pros of fix RTL:** matches firmware/linker; halves SRAM area; 4× ROM area reduction.
- **Cons:** RTL parameter change and re-verification.
- **Risks:** forgetting address bit width in wrapper/decode.
- **Downstream:** Stage 3 macro mapping, Stage 7 synthesis, Stage 9 floorplan.
- **Recommendation:** 16 KB / 32 KB / 128 KB.
- **Approval:** user/design owner.
- **Acceptance:** approved memory table; RTL change tickets for Stage 2.

## 6. TD-006 — Memory macro strategy

- **Current:** 4 KB 128-bit macro audited, not integrated; tiling 176 KB needs 44 macros / 31.8 mm².
- **Options:** M-A tile 4 KB macro; M-B generate 32-bit macros; M-C reduce memory; M-D external SRAM.
- **Pros of M-B:** meets <10 mm²; 32-bit native; fewer instances.
- **Cons:** generation/characterization effort; multi-corner Liberty required.
- **Risks:** OpenRAM macro not available in time; TT-only views block signoff.
- **Downstream:** Stage 3, 9, 10, 15.
- **Recommendation:** M-B; if unavailable, re-approve area or memory size before Stage 9.
- **Approval:** user/design owner + PD lead.
- **Acceptance:** macro list with LEF/Liberty/area; no 4 KB tiling in floorplan.

## 7. TD-005 — Power domains and UPF

- **Current:** one 1.8 V domain; clock gating only; no UPF/isolation/retention.
- **Options:** P-A single domain (descope deep sleep); P-B two domains (AON + switchable); P-C three; P-D documented 1.0/1.8/3.3 (not feasible).
- **Pros of P-B:** meets AON/deep-sleep intent; same voltage avoids level shifters; moderate complexity.
- **Cons:** isolation/sequencing, UPF, AON area.
- **Risks:** state corruption on power-down; PMIC contract mismatch; UPF not supported by flow.
- **Downstream:** Stage 10 PDN, Stage 15 electrical signoff.
- **Recommendation:** P-B.
- **Approval:** user/design owner; board/PMIC owner.
- **Acceptance:** domain diagram, UPF scope, pin handshake, PMIC contract approved.

## 8. TD-007 — Security and boot

- **Current:** fail-closed boot with no verifier; no crypto/OTP/TRNG; OTA stub; no debug lock.
- **Options:** S0 no secure boot; S1 hardware SHA-256 + ECDSA-P256; S2 HMAC; S3 external secure element.
- **Pros of S1:** meets FR-SEC-001/002; supports attestation and OTA later.
- **Cons:** RTL effort; key storage; provisioning; boot time.
- **Risks:** no OTP macro; ECDSA performance; key management infrastructure absent.
- **Downstream:** Stage 2, 4, 16, 17.
- **Recommendation:** S1 with OTP if available, else S3; S0 only with explicit descope and removal of security claims.
- **Approval:** user/design owner + security owner.
- **Acceptance:** option chosen; key storage; image format; debug policy; OTA in/out of first silicon.

## 9. TD-010 — SDC clock plan

- **Current:** `has_soc.sdc` 20 ns vs `timer_pclk_provisional.sdc` 40 ns; 105 ports without budgets; 35 unconstrained endpoints.
- **Options:** 50 MHz single clock; 50 + 25 generated; 50 + 25 + 32k.
- **Recommendation:** 50 MHz core + generated 25 MHz + 32 kHz AON, with I/O budgets M1–M10 approved.
- **Risks:** generated-clock constraints wrong; async groups misapplied.
- **Downstream:** Stage 8, 12, 15.
- **Approval:** design owner.
- **Acceptance:** one SDC clock plan; port budgets; zero unexplained unconstrained endpoints.

## 10. TD-016 — Pin and interface baseline

- **Current:** 81 RTL pad signals, 56 usable I/O, 32 dead IRQ pins, docs/CSV with absent signals.
- **Options:** pinmux all functions; remove dead pins + mux 8 IRQs onto GPIO; change package.
- **Recommendation:** remove `ext_irq[31:0]` and three internal handshake pins; add BOOT_MODE, PMIC, RF_CTRL, UART1 → 54 pins.
- **Risks:** losing external IRQ flexibility; pinmux verification; 3.3 V pad absence.
- **Downstream:** Stage 2, 9, 17.
- **Approval:** user/design owner + package/board owner.
- **Acceptance:** approved pin table matching RTL; no dead pins; voltage domains resolved.

## 11. TD-017 — Requirements baseline

- **Current:** SRS describes a product substantially beyond the RTL; 37 FR/IF not implemented.
- **Options:** implement everything (large schedule); re-baseline to implementable product; hybrid (core product now, security/AON later).
- **Pros of re-baseline:** removes ambiguity; lets Stage 2 finish; honest product.
- **Cons:** descoping mandatory features; market/security impact.
- **Risks:** hidden dependencies (secure boot, OTA, radio) discovered late.
- **Recommendation:** hybrid: first silicon = RV32IM, 16/32/128 KB, 1 UART, 1 SPI, 1 I2C, 16 GPIO, 4 PWM, 1 I2S TX, 8-source PLIC, basic boot; defer crypto/OTA/second UART/LPTIM to a later silicon or explicit descope.
- **Approval:** user/design owner.
- **Acceptance:** approved SRS revision; every descope signed; traceability regenerated.

## 12. TD-009 — DFT scope

- **Current:** no scan/ATPG/MBIST/IR/EM; commercial tools absent.
- **Options:** commercial DFT tool; outsourced DFT; no DFT (not acceptable for tapeout); open-source scan insertion + external ATPG.
- **Recommendation:** decide before Stage 7; budget or partner; scan insertion must precede synthesis freeze.
- **Risks:** late decision forces netlist/timing redo; no ATPG means no manufacturing test.
- **Downstream:** Stage 16, 17, 18.
- **Approval:** program owner.
- **Acceptance:** tool/budget approved; scan architecture defined; test coverage target agreed.

## 13. Roles

The user remains decision authority. Proposed roles (no names invented):

| Role | Responsibility | Assignment |
|---|---|---|
| System architecture owner | ARC decisions, memory/clock/power | User (acting) or delegate |
| RTL design owner | Stage 2 implementation | unassigned |
| Verification owner | regression/coverage | unassigned |
| Formal/CDC owner | ARC-036/065 | unassigned |
| PD owner | synthesis/PD/signoff | unassigned |
| DFT owner | scan/ATPG | unassigned |
| Security owner | TD-007 | unassigned |
| Tapeout release authority | final package | User |

Unowned roles are a Stage 1 acceptance gap. Assigning them does not require inventing names; it requires the user to name delegates or accept the role.

---

## 14. Explicit non-approvals

This package does **not** approve:

- any clock option;
- any memory size or macro;
- any power domain or UPF;
- any security option;
- any pin/package plan;
- any requirement descope;
- any DFT tool or budget.

Stage 1 status: **READY FOR APPROVAL**. Stage 2 must not begin.
