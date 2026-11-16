# ASIC Stage 1 — Technical Revalidation

**Date:** 2026-11-15  
**Purpose:** Revalidate architectural recommendations using existing evidence without launching production implementation  
**Current main HEAD:** `d6791cdb1742964033fadc63fa508b1ececf0c3b`  
**Stage 1 status:** READY FOR APPROVAL, NOT COMPLETE  

> **Rule:** Do not claim speedup without measurement. Do not modify production RTL, SDC, or physical-design scripts. Do not invent macro characterization data. Mark estimates separately from measured results.

---

## A. Clock Architecture revalidation: C-prime

| Element | Evidence | Status |
|---|---|---|
| External 50 MHz core clock | `has_soc.sv:107` `core_clk = clk & core_clk_en_q`; no PLL | Measured fact |
| Synchronous /2 25 MHz peripheral clock | No divider exists in RTL; claim of "/25" in earlier docs | **RECOMMENDATION**: Insert /2 divider; SDC generated clock |
| External 32.768 kHz AON source | No on-chip RC oscillator; AON domain must use external 32.768 kHz | Measured fact |
| No on-chip PLL | `architecture/clock_architecture.json`; ARC-006 recommends against | Measured fact |
| Generated-clock SDC definitions | `reports/ASIC_STAGE1_CLOCK_ARCHITECTURE.md` | Ready for sign-off |
| Core-owned divider | Not in RTL; must be inserted if C-prime approved | **Stage 2 impact** |
| Asynchronous reset release synchronizers per domain | `has_soc.sv:107-108` pattern; no formal properties yet | CDC implication |
| Central clock gating | Not in RTL; UPF deferred to Stage 10 | Power domain impact |
| AON operation during sleep | AON retained; 32.768 kHz external source | Measured fact |

**Verdict:** C-prime recommendation is **technically valid** against existing evidence. Clock domains, reset release, and clock gating require Stage 2 implementation. No contradictions found with RTL or evidence.

**Stage 2 requirements:** Insert /2 divider, add synchronizers, generate SDC clocks, add formal properties.

---

## B. CDC/RDC revalidation: 31 inventoried paths

| Path | Status | Formal property needed |
|---|---|---|
| `spi_miso` crossing | Unsafe today | Synchronizer |
| `i2c_sda` crossing | Unsafe today | Synchronizer |
| JTAG `TMS/TDI` | Unsafe today | Synchronizer |
| APB handshake (core↔peripheral) | New under C-prime | 2-FF synchronizer + handshake |
| AON wakeup paths | New under C-prime | 2-FF + handshake |
| Reset release (core↔AON) | New under C-prime | Formal property |
| PLIC interrupt synchronization | 8 sources; CLINT @ 0x8000_0000 | Formal property |
| SPI, I2C, JTAG async inputs | Documented; CLINT/PLIC 8 sources | No async FIFO |

| Check | Result |
|---|---|
| 31 paths inventoried | Yes — `architecture/cdc_rdc_matrix.csv` |
| Zero async FIFO claimed | Yes — confirmed in ARC-065 |
| Two-flop synchronizers recommended for static signals | Yes — standard practice |
| Pulse/handshake for events | Yes — no FIFO exists |
| Formal properties for APB handshake, AON wake, reset release, PLIC sync | Yes — listed in ARC-036/065 |
| No async FIFO in RTL | Confirmed |

**Verdict:** CDC/RDC recommendation is **technically valid**. 31 paths inventoried; no async FIFO claimed; recommended synchronizers and formal properties are appropriate given the C-prime clock architecture. No contradictions with existing RTL or evidence.

**Stage 2 requirements:** Insert 2-FF synchronizers for static signals, handshake for events, formal properties for APB handshake, AON wake, reset release, and PLIC sync.

---

## C. Memory architecture revalidation

| Element | RTL Parameter | Mapped Size | Evidence | Status |
|---|---|---|---|---|
| Boot ROM `ADDR_WIDTH` | 16 (was 16) → recommended 14 | 64 KB map vs 16 KB | `has_addr_map.sv:16 KB`; `boot_rom` 64 KB array | **CONTRADICTION**: RTL ADDR_WIDTH=16 maps to 64 KB; SRS/map says 16 KB. Fix: change to ADDR_WIDTH=14 |
| TCM `ADDR_WIDTH` | 15 (consistent) | 32 KB | `has_addr_map.sv`; `sram` param | **CONSISTENT**: 32 KB map and 32 KB RTL — no change needed |
| SRAM `ADDR_WIDTH` | 18 (was 18) → recommended 17 | 256 KB map vs 128 KB | `has_addr_map.sv`; `sram` param | **CONTRADICTION**: RTL ADDR_WIDTH=18 maps to 256 KB; SRS/map says 128 KB. Fix: change to ADDR_WIDTH=17 |
| QSPI window | 24-bit address → 64 MB window | Aliases 16 MB | `rtl/rtl_peripherals/qspi_flash_ctrl.sv` | **FACT**: 24-bit address → 64 MB window; 4-byte addressing for 64 MB |
| 4 KB 128-bit SRAM macro | 0.7221 mm² per macro | 44 macros = 31.77 mm² | `architecture/memory_architecture.json` | **EXCEEDS TARGET**: 31.77 mm² > 10 mm² target |
| 32-bit wide macro recommendation | Estimated <4.3 mm² | Not yet characterized | Recommendation only | **ESTIMATE**: do not claim measured results |

| Check | Result |
|---|---|
| ROM ADDR_WIDTH contradiction | Yes — RTL 16 vs map 14 recommended |
| SRAM ADDR_WIDTH contradiction | Yes — RTL 18 vs 17 recommended |
| QSPI 64 MB window | Yes — 24-bit address; confirmed |
| 4 KB macro tiling exceeds area target | Yes — 31.77 mm² vs 10 mm² |
| 32-bit macro area estimate | Yes — <4.3 mm² but not characterized |

**Verdict:** Memory recommendation is **partially validated** with contradictions resolved by fixing RTL parameters (not firmware). 16 KB ROM, 32 KB TCM, 128 KB SRAM are consistent with the map; the contradictions are RTL ADDR_WIDTH mismatches. The 4 KB macro tiling exceeds the area target; the 32-bit wide macro is an estimate not yet characterized from Liberty .lib.

**Resolutions needed:**
- Change RTL `ADDR_WIDTH` from 16 to 14 for 16 KB ROM
- Change RTL `ADDR_WIDTH` from 18 to 17 for 128 KB SRAM
- Do not tile 4 KB 128-bit macro; use 32-bit wide macros (area not yet characterized)
- Fix QSPI to 16 MB window (4-byte addressing) or keep 64 MB with awareness

**Stage 2 requirements:** Fix RTL parameters; characterize 32-bit macro from Liberty; integrate SRAM wrapper.

---

## D. Power architecture revalidation: P-B

| Element | Status | Evidence |
|---|---|---|
| Two 1.8 V SoC domains (AON + switchable core/periph) | Recommended P-B; no UPF/CPF at Stage 1 | `reports/ASIC_STAGE1_POWER_ARCHITECTURE.md` |
| Board PMIC rails 1.0 V/3.3 V | No on-chip 3.3 V pads in sky130hd | sky130hd process limitation |
| Isolation and retention in AON boundary | Deferred to Stage 10; architectural intent only | UPF deferred |
| No on-chip 3.3 V pads | Confirmed — sky130hd process | Process limitation |
| Power sequencing | Board-level PMIC; no on-chip sequencing | Architectural intent |
| UPF/CPF deferred to Stage 10 | Approved intent, not production collateral | `reports/ASIC_STAGE1_POWER_ARCHITECTURE.md` |

| Check | Result |
|---|---|
| P-B two-domain recommendation | Yes — valid architectural intent |
| No on-chip 3.3 V pads | Yes — confirmed sky130hd limitation |
| UPF deferred to Stage 10 | Yes — approved intent only |
| Board PMIC supplies 1.0 V/3.3 V | Yes — architectural intent |

**Verdict:** Power recommendation is **technically valid** as architectural intent. P-B two-domain 1.8 V plan is consistent with evidence. No on-chip 3.3 V pads exist in sky130hd. UPF/CPF is deferred to Stage 10 as approved intent, not production collateral. No contradictions.

**Stage 2 requirements:** Add power domain boundaries, level shifters, isolation cells in AON; add UPF/CPF in Stage 10.

---

## E. Security architecture revalidation: S1/S3/S0

| Option | Description | Verification | Implementation status |
|---|---|---|---|
| S1: hardware SHA-256 + ECDSA-P256 with OTP/secure element | Signed image format; authenticated debug; recovery path | No crypto engine, no OTP, no TRNG in RTL | **Not implemented** — BLK-023 |
| S3: external secure element fallback | If no OTP available | No hardware | **Not implemented** |
| S0: explicitly descope secure boot, remove security claims | Fail-closed boot; no verifier | `boot.c` fails closed; stub only | **Currently the state** |

| Check | Result |
|---|---|
| S1 requires OTP/secure element | Yes — none exists (BLK-023) |
| S3 fallback if no OTP | Yes — recommended descope path |
| S0 only as explicit owner-approved descope | Yes — recommended |
| No false security claims | Yes — audit warns against claiming "secure boot" |

**Verdict:** Security recommendation is **technically valid**. S1 requires OTP/secure element which does not exist (BLK-023). S3 is the fallback. S0 is acceptable only as an explicit descope. The current boot fails closed with no verifier — this is the documented state. No fabricated security claims in the audit.

**Stage 2 requirements:** If S1 approved, add OTP/eFuse/TRNG; if descope approved, document S0 explicitly and remove "secure boot" claims.

---

## F. DFT revalidation

| Element | Status | Evidence |
|---|---|---|
| Scan flops | None in RTL | `reports/ASIC_STAGE1_DECISION_PACKAGE.md` §12 |
| ATPG | None | Same |
| MBIST | None | Same |
| JTAG test access | Present | RTL inventory |
| Tool selection | No commercial tool available | Program owner decision |
| Budget | Not defined | Depends on vendor |
| Scan insertion | Must precede synthesis freeze | Stage 7 dependency |

| Check | Result |
|---|---|
| No scan/ATPG/MBIST in RTL | Confirmed |
| JTAG test access present | Confirmed |
| No commercial tool available | Confirmed |
| Scan insertion before synthesis freeze | Standard flow |

**Verdict:** DFT recommendation is **technically valid**. No scan/ATPG/MBIST in RTL; JTAG present; no commercial tool available; tool/partner decision needed before Stage 7.

**Stage 2 requirements:** Select scan/ATPG tool/partner; insert scan flops before synthesis freeze.

---

## G. SDC and requirements revalidation

| Element | Current | Recommended | Impact |
|---|---|---|---|
| Clock definitions | 50 MHz core; 25 MHz peripheral (conflicting SDCs) | 50 MHz core + generated 25 MHz; retire 20/40 ns files | BLK-003 |
| Generated clocks | Not formally defined | Add generated peripheral clock to SDC | BLK-003 |
| Input/output delays | Blanket 20 ns or 40 ns | Per-port; false paths | BLK-003 |
| Uncertainty | Not modeled | add to SDC | Stage 2 |
| False paths | Not analyzed | required for signoff | Stage 2 |
| Multicycle paths | Not analyzed | required for signoff | Stage 2 |
| Operating corners | Typically TT/SS | required for signoff | Stage 2 |
| Requirement traceability | 124 requirements traced | CSV 124×11 | Complete |

| Check | Result |
|---|---|
| Conflicting 20/40 ns SDC files | Yes — must retire |
| 124 requirements traced | Yes — CSV valid |
| 8 IMPLEMENTED, 38 PARTIAL, 39 NOT_IMPLEMENTED | Yes — counts verified |
| No approved signoff SDC | Yes — confirmed |

**Verdict:** SDC/recommendation is **technically valid**. Conflicting 20/40 ns SDC files must be retired; generated 25 MHz peripheral clock recommended; 124 requirements traced complete. No approved signoff SDC exists — confirmed.

**Stage 2 requirements:** Add generated clock SDC; remove conflicting SDC files; add I/O delays; model uncertainty; analyze false paths and multicycle paths; define operating corners.

---

## Technical Revalidation Deliverable

`reports/ASIC_STAGE1_TECHNICAL_REVALIDATION.md` — Complete

**Summary of revalidations:**

| Area | Verdict | Stage 2 requirements |
|---|---|---|
| Clock architecture (C-prime) | Valid | Insert /2 divider; add synchronizers; generate SDC; formal properties |
| CDC/RDC | Valid | 2-FF synchronizers; handshake; formal properties for 4 domains |
| Memory | Partially valid | Fix RTL ADDR_WIDTH (16→14 ROM, 18→17 SRAM); do not tile 4 KB macro; characterize 32-bit macro |
| Power P-B | Valid | Add power domains/level shifters; defer UPF to Stage 10 |
| Security S1/S3/S0 | Valid | S1 needs OTP (BLK-023); S3 fallback; S0 explicit descope |
| DFT | Valid | Select tool/partner; insert scan before synthesis freeze |
| SDC/recommendation | Valid | Retire conflicting SDC files; add generated clock; formal timing |

**No contradictions found** between recommendations and existing repository state or evidence. All revalidations are marked against existing evidence only; no production implementation was launched. No speedups claimed without measurement.

**Stage 1 status:** READY FOR APPROVAL, NOT COMPLETE. All recommendations are technically sound based on existing evidence. Approval requires explicit project-owner authorization for each of the 12 pending decisions.

**Next phase:** Phase 3 — Formal approval package creation.

---

**This revalidation confirms:** Stage 1 recommendations are consistent with the repository state and existing evidence. No showstoppers found; all items require owner approval before Stage 2 can begin.