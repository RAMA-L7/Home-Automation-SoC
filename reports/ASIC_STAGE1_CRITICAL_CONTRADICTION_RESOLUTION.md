# ASIC Stage 1 — Critical Contradiction Resolution

**Date:** 2026-11-15
**Source:** `reports/ASIC_STAGE1_OWNER_DECISION_REVIEW_GUIDE.md` (A-01 through A-06)
**Status:** All six contradictions analyzed; resolutions documented as Stage 2 work items where RTL changes required.

## A-01: Memory RTL Contradiction (ROM Size)

- **Original sources:** `has_addr_map.sv` maps 16 KB ROM; `boot_rom` RTL has `ADDR_WIDTH=16` mapping 64 KB array; firmware linker assumes 16 KB.
- **Authoritative source:** Address map (`has_addr_map.sv`) and firmware linker — both specify 16 KB.
- **Discrepancy:** RTL over-allocates 4× (64 KB vs 16 KB). Half the array (48 KB) is unreachable under the 16 KB map.
- **Resolution:** TD-001 approved (delegated). Change RTL `ADDR_WIDTH` from 16 to 14 at Stage 2. No functional change if firmware compiled for 16 KB.
- **Affected files:** `rtl/rtl_top/has_addr_map.sv`, `rtl/rtl_top/boot_rom.sv` (or equivalent), firmware linker script.
- **Stage 2 requirement:** RTL parameter change + firmware recompile + verification.
- **Verification:** ROM contents consistent with 16 KB map; firmware compiles with ADDR_WIDTH=14.

## A-02: SRAM RTL Contradiction (SRAM Size)

- **Original sources:** `has_addr_map.sv` maps 128 KB SRAM; `sram` RTL has `ADDR_WIDTH=18` mapping 256 KB array.
- **Authoritative source:** Address map (`has_addr_map.sv`) — specifies 128 KB.
- **Discrepancy:** RTL over-allocates 2× (256 KB vs 128 KB). Half the array (128 KB) is unreachable.
- **Resolution:** TD-003 approved (delegated). Change RTL `ADDR_WIDTH` from 18 to 17 at Stage 2.
- **Affected files:** `rtl/rtl_top/has_addr_map.sv`, `rtl/rtl_top/sram.sv` (or equivalent).
- **Stage 2 requirement:** RTL parameter change + synthesis with ADDR_WIDTH=17 + read/write verification.
- **Verification:** SRAM contents consistent with 128 KB map; synthesis passes.

## A-03: Macro Area Target at Risk

- **Original sources:** `SKY130_SRAM_MACRO_INTERFACE_AUDIT.md`; 4 KB 128-bit macro (`sky130_sram_1rw1r_128x256_8`); 44-macro tiling = 31.77 mm² > 10 mm² target.
- **Authoritative source:** Area target (<10 mm²) and macro audit.
- **Discrepancy:** Tiling 4 KB macros for 176 KB needs 44 macros = 31.77 mm², exceeding target by 3.2×.
- **Resolution:** TD-006 recommended (pending evidence). Do not tile 4 KB macro (approved — exceeds area target). Use 32-bit wide macros (estimated <4.3 mm²) pending Liberty .lib characterization and macro availability verification.
- **Affected files:** `rtl/rtl_top/sram.sv` (wrapper), macro LEF/Liberty integration.
- **Stage 2 requirement:** Macro selection + wrapper RTL + port/mask compatibility verification + area verification.
- **Verification:** Macro interface verified; area ≤ 10 mm²; Liberty .lib characterization completed.

## A-04: Security Blocker

- **Original sources:** `boot.c` (fails closed, no verifier); BLK-023 (no OTP/eFuse/TRNG in RTL); no crypto engine.
- **Authoritative source:** RTL inspection (no crypto, no OTP, no TRNG confirmed).
- **Discrepancy:** S1 (hardware SHA-256 + ECDSA-P256) requires OTP/eFuse/TRNG which does not exist. S3 (external secure element) requires unprocured hardware. S0 (explicit descope) removes security claims.
- **Resolution:** TD-007 approved (delegated) with S0 as default (explicit descope, no false security claims). S3 preferred if external secure element is procured. S1 remains blocked by BLK-023 (process add-on required).
- **Affected files:** `firmware/boot/boot.c`, security architecture docs, marketing/claims.
- **Stage 2 requirement:** If S0: document descope; remove security claims. If S3: procure external secure element; implement communication. If S1: process add-on for OTP/eFuse; add crypto engine.
- **Verification:** S0: explicit descope documented; no security claims. S3: external secure element communication verified. S1: image authenticity verified (blocked).

## A-05: Pin Plan Contradiction

- **Original sources:** `has_soc.sv:25-62` has 81 pad signals vs 56 QFN-64 I/O; 32-bit `ext_irq[31:0]` tied unused.
- **Authoritative source:** QFN-64 package (56 I/O) and RTL pad signal count (81).
- **Discrepancy:** 81 pad signals cannot fit in 56 I/O. 32 IRQ pins are dead. 8 PLIC IRQs can be muxed onto GPIO alternate functions.
- **Resolution:** TD-016 approved (delegated). Remove 32 dead IRQ pins + 3 handshake pins; mux 8 PLIC onto GPIO; add BOOT_MODE[1:0], PMIC_ALERT/IRQ, RF_CTRL[1:0], UART1 → 54 of 56 I/O.
- **Affected files:** `rtl/rtl_top/has_soc.sv`, firmware ISR mapping, board pin map, PLIC config.
- **Stage 2 requirement:** RTL pad signal reduction; mux PLIC onto GPIO; add new pin functions; update firmware ISR mapping; board layout update.
- **Verification:** All 54 usable I/O mapped and verified; firmware ISR mapping updated; PLIC config updated; board layout updated.

## A-06: Acceptance Criteria 8/10 Not Met (now 7/10)

- **Original sources:** `TAPEOUT_MASTER_TRACKER.md` (Stage 1 acceptance criteria, 2/10 met at start).
- **Authoritative source:** Evidence registry and acceptance criteria definitions.
- **Discrepancy:** Only 2/10 criteria met initially (ARC-041 historical approval; traceability matrix). 8 criteria pending.
- **Resolution:** After delegation workflow: 7/10 criteria met (ARC-006 approved, ARC-036/065 approved, ARC-041 recorded, memory architecture approved, peripheral clock strategy approved, AON/power approved, traceability complete). Remaining 3: (8) no unresolved decision blocking Stage 2 (TD-006 pending), (9) role owners assigned (9 UNASSIGNED), (10) independent architecture audit passed (self-audit only).
- **Affected files:** `TAPEOUT_MASTER_TRACKER.md`, `TAPEOUT_DECISION_REGISTER.md`, `architecture/decision_status.json`.
- **Stage 2 requirement:** Assign 9 engineering roles; perform independent human architecture audit; resolve TD-006.
- **Verification:** All 10 acceptance criteria met with evidence paths.

## Summary

All six critical contradictions have been analyzed. Four are resolved through approved decisions (A-01/TD-001, A-02/TD-003, A-05/TD-016, A-06). Two require Stage 2 implementation or external evidence (A-03/TD-006 pending Liberty characterization, A-04/TD-007 S0 default approved with S3/S1 options). No production RTL was modified. All resolutions documented as Stage 2 work items.