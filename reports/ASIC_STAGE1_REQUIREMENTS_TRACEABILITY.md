# ASIC Stage 1 — Requirements Traceability

Date: 2026-11-15
Source: `docs/requirements/system_requirements.md` (SRS v1.0, 115 unique IDs + 1 duplicate + 8 VR)
Machine-readable: `architecture/requirements_traceability.csv` (124 rows)
Generator: `architecture/generate_traceability.py` (re-runnable)

---

## 1. Coverage summary

| Class | Count | Percentage |
|---|---:|---:|
| Functional + interface requirements (FR/IF) | 81 | 100% mapped |
| Non-functional targets (NFR) | 35 | 100% mapped |
| Verification requirements (VR) | 8 | 100% mapped |
| **Total** | **124** | **100% mapped** |

| Status | Count | Meaning |
|---|---:|---|
| IMPLEMENTED | 8 | Implemented and exercised (not necessarily signoff) |
| PARTIAL | 38 | Some behavior exists; requirement not met |
| NOT_IMPLEMENTED | 39 | No RTL/feature |
| NOT_VERIFIED | 19 | Exists or estimated; no evidence |
| ESTIMATED | 6 | Area estimates only |
| NOT_STARTED | 6 | Verification activity absent |
| BLOCKED | 5 | Tool/DFT dependency |
| FAILED | 2 | Measured/known to miss target |
| AT_RISK | 1 | Area target likely missed |

For FR/IF only: **8 implemented, 34 partial, 37 not implemented, 1 failed, 1 not verified.**

---

## 2. Status by architecture block

| Block | Requirements | Status distribution |
|---|---:|---|
| Core | 5 | 3 partial; 2 not implemented |
| Memory | 6 | 5 partial; 1 not implemented |
| Bus | 5 | 4 implemented; 1 partial |
| Peripherals | 16 | 11 partial; 3 implemented; 2 not implemented |
| Security | 9 | 9 not implemented |
| Clock | 5 | 2 partial; 3 not implemented |
| Reset | 3 | 2 partial; 1 not implemented |
| Power | 13 | 4 not implemented; 1 partial; 8 not verified |
| External interfaces | 3 | 3 not implemented |
| Debug | 3 | 1 implemented; 1 partial; 1 not implemented |
| Performance | 8 | 1 partial; 4 not verified; 1 failed; 2 not implemented |
| Physical/area | 7 | 1 at risk; 6 estimated |
| Environmental | 7 | 7 not verified |
| DFT/signoff | 6 | 5 blocked; 1 partial |
| Package | 4 | 3 partial; 1 failed |
| Electrical | 9 | 8 not implemented; 1 partial |
| Software | 7 | 4 partial; 3 not implemented |
| Verification | 8 | 2 partial; 6 not started |

---

## 3. Implemented requirements (8)

| ID | Requirement | Evidence | Caveat |
|---|---|---|---|
| FR-BUS-001 | AXI4-Lite 32-bit CPU-memory | boot/firmware regression | No burst, correct |
| FR-BUS-002 | APB peripherals via bridge | 22/22 regression | 9 slots only |
| FR-BUS-003 | req/gnt → AXI bridge | boot | Custom bridge, not LiteX |
| FR-BUS-005 | 32-bit registers, 4-byte aligned | register map | Partial writes rejected |
| FR-PER-005 | 4× PWM 16-bit | `tb_pwm`, boot | No dead time/center align |
| FR-PER-010 | CLINT MTIME/MTIMECMP/MSIP | `tb_clint`, boot | Non-standard 4 KB offsets |
| FR-DBG-003 | UART0 115200 8N1 console | `tb_uart`, boot | No FIFO |
| IF-COM-001 | UART0 115200 8N1 | `tb_uart` | No flow control |

No requirement is **SIGNOFF VERIFIED**; these are implemented and simulation-exercised.

---

## 4. Requirements without RTL (major)

| Requirement group | Missing implementation |
|---|---|
| FR-SEC-001..008 | ECDSA, SHA, AES, TRNG, OTP, rollback, debug fuse |
| FR-PER-008 | LPTIM / AON timer |
| FR-PER-001 (second) | UART1 |
| FR-PER-009 | PLIC ≥32 sources (only 8) |
| FR-PER-003 | SPI 3 CS, modes 0–3, DDR |
| FR-PER-002 | I2C clock stretching, multi-byte/FIFO |
| FR-PER-004 | GPIO pulls, drive strength, alternate functions/pinmux |
| FR-PER-006 | I2S RX, 24/32-bit, master/slave |
| FR-RST-003 | Per-peripheral reset registers |
| FR-PWR-003/004/006 | Power gating, LPTIM/GPIO/PMIC wake, brown-out |
| FR-EXT-001..003 | UART1/RF_CTRL/second radio path |
| FR-DBG-002 | SWD |
| IF-ELE-001..007 | Pad ring, voltage domains, 3.3 V I/O |
| IF-SW-003/004/006 | Zephyr, Mbed TLS, OTA |
| ARC-058 | Pinmux |

---

## 5. RTL without a requirement

| Module | Situation | Action |
|---|---|---|
| `watchdog.sv` | No `FR-PER-*` ID; only ARC-015 mentions watchdog | Add an explicit watchdog requirement and reset semantics |
| `intc_axi.sv` | Implementation wrapper, no requirement | Covered by FR-PER-009/010; document |
| `req_gnt_to_axi_lite.sv` | Covered by FR-BUS-003 | OK |
| `power_mgr.sv` | Covered by FR-PWR-003/004 partially | OK |
| `reset_ctrl.sv` | Covered by FR-RST-002 | OK |
| `debug_jtag.sv` | Covered by FR-DBG-001 | OK |

The watchdog is the only true orphan: it is implemented and tested but has no requirement, no reset-scope definition, and its output resets the whole SoC rather than the core-only scope in the docs.

---

## 6. Contradictory implementations

| Requirement | Document | RTL | Resolution |
|---|---|---|---|
| FR-CLK-002 | 25 MHz periph | 50 MHz gated | ARC-006 |
| FR-MEM-001 | 128 KB SRAM | 256 KB array | TD-003 |
| FR-MEM-003 | 16 KB ROM | 64 KB array | TD-001 |
| FR-MEM-004 | 64 MB XIP | 16 MB single-line read | TD-017 |
| FR-PROC-001 | Ibex RV32IMC | custom RV32IM | ARC-001 / TD-017 |
| FR-PROC-003/004 | M/U + PMP | M-only, no PMP | TD-017 |
| FR-PER-009 | ≥32 PLIC sources | 8 | TD-017 |
| IF-PIN-002 | 56 I/O | 81 pad signals | TD-016 |
| FR-PWR-001 | 1.0/1.8/3.3 V domains | one 1.8 V domain | TD-005 |
| FR-SEC-001 | ECDSA secure boot | fail-closed | TD-007 |

---

## 7. Requirements without verification

| Requirement | Why unverified |
|---|---|
| FR-MEM-004 | No QSPI flash model; no XIP test |
| FR-PER-002 | No I2C device model; no stretch test |
| FR-PER-003 | No multi-CS/mode test |
| FR-PER-006 | No I2S RX/24-bit test |
| FR-PER-009 | PLIC tested with 8 sources only |
| FR-PWR-003/005 | No power measurement/bench |
| NFR-PERF-001..008 | No full-chip STA/hardware |
| NFR-PWR-001..007 | No power intent/measurement |
| NFR-ENV-001..007 | No qualification |
| NFR-QUA-001..006 | No DFT/IR/EM/LVS |
| IF-ELE-001..009 | No pad ring/board |

---

## 8. Proposed requirements (missing from SRS)

| Proposed ID | Requirement | Rationale |
|---|---|---|
| FR-PER-011 | Watchdog: 32-bit down-counter, windowed pet, reset scope defined | Implemented but untraced |
| FR-PER-012 | Pinmux: APB-controlled alternate functions for UART1/SPI1/I2C1/PWM/RF | ARC-058, absent RTL |
| FR-RST-004 | Per-peripheral reset register block | FR-RST-003 lacks address/behavior |
| FR-PWR-007 | Power-state handshake `pwr_hold`/`pwr_ack` | Needed for TD-005 |
| FR-SEC-009 | Debug authentication/lock policy | FR-SEC-008 only says fuse |
| FR-MEM-007 | QSPI program/erase and A/B metadata | OTA prerequisite |
| IF-PIN-005 | Pin budget and mux table matching RTL | Pin mismatch |
| NFR-QUA-007 | LVS clean on full chip | Missing from NFR list |

These are proposals, not requirements; they require owner approval.

---

## 9. Descope candidates (require explicit owner approval)

| Item | Reason | Impact if descoped |
|---|---|---|
| AES/SHA/TRNG accelerators | No RTL, large effort | Security services must be software-only or absent |
| Secure boot/OTA | No verifier, no OTP, no flash write | Product cannot claim secure update |
| UART1 | No RTL/pins | Radio module integration via UART0 only |
| LPTIM/AON | No RTL/power intent | Deep sleep <1 mW not achievable |
| 3.3 V tolerant I/O | No PDK pads | Board level shifters required |
| 32-source PLIC | 8 implemented | Fewer interrupt sources |
| ECC | Optional; area cost | No SECDED |
| Internal 32 kHz RC | No analog IP | External 32.768 kHz source |
| DFT/ATPG | No tool/budget | No manufacturing test (cannot tape out responsibly) |

**No requirement is removed in this stage.** All descopes are proposals in `TAPEOUT_DECISION_REGISTER.md`.

---

## 10. Traceability conclusion

The SRS is **traceable but not implementable as written** with the current RTL and PDK. The matrix gives Stage 2 an exact work list:

1. Re-baseline or implement the 37 not-implemented FR/IF items.
2. Close the 34 partial items with feature work and tests.
3. Re-verify the 8 implemented items under the approved clock/memory baseline.
4. Approve or reject every descope.

**Approval required:** TD-017 (requirements baseline). Traceability is complete as analysis; the requirement baseline is not approved.
