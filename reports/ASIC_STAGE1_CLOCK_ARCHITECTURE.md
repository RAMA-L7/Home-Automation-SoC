# ASIC Stage 1 — Clock Architecture

Date: 2026-11-15
Status: **READY FOR APPROVAL** (ARC-006)
Machine-readable: `architecture/clock_architecture.json`

---

## 1. Verified facts (not recommendations)

| Fact | Evidence |
|---|---|
| RTL has exactly one clock input, `clk` | `rtl/rtl_top/has_soc.sv:25` |
| Core clock is `clk & core_clk_en_q` | `has_soc.sv:107` |
| Peripheral clock is `clk & periph_clk_en_q` | `has_soc.sv:108` |
| No divider, no PLL, no 32 kHz, no `clk_aon` | RTL-wide search |
| UART defaults to 50 MHz | `has_soc.sv:21`; `uart.sv:48` |
| Boot firmware assumes 50 MHz for 115200 baud | `firmware/boot/boot.S:5` |
| Clock enables are captured on `negedge clk` before gating | `has_soc.sv:98-105` |
| JTAG TCK is a second, test-only clock | `has_soc.sv:27` |
| The SoC has no internal CDC today | one clock; only pin-level async inputs |
| ARC-006 is PROPOSED; ARC-041 (Si5351) is APPROVED | `ARCHITECTURE_DECISION_RECORDS.md` |
| Core/peripheral 50/25/32k requirement is mandatory | FR-CLK-001/002/004 |

**Interpretation:** the current implementation is a single-clock 50 MHz prototype with clock gating. It is not a 25 MHz peripheral implementation and has no always-on domain. Clock-enable behavior is **not** equivalent to an independent 25 MHz clock: it changes the effective rate of every divider/counter and does not create a generated clock for STA or CTS.

---

## 2. Requirement tension

| Requirement | Current | Consequence |
|---|---|---|
| FR-CLK-001: 50 MHz core from Si5351 | External `clk` pin only | Board must supply 50 MHz; acceptable |
| FR-CLK-002: 25 MHz peripheral (core/2) | 50 MHz gated copy | **Not met**; all APB timing 2× |
| FR-CLK-003: QSPI 12.5 MHz or 50 MHz DDR | QSPI SCK divider from 50 MHz | Partially met for SDR; no DDR |
| FR-CLK-004: 32 kHz AON LPO | absent | **Not met**; deep sleep impossible |
| FR-CLK-005: per-peripheral gating | two domain gates | Partially met |
| ARC-006 | PROPOSED | Cannot freeze |
| ARC-041 | APPROVED external Si5351 | Keep; no on-chip PLL |

FR-CLK-004 says "internal RC (LPO)". The open sky130 PDK has no qualified, characterized 32 kHz RC oscillator or analog IP in this repository. An on-chip RC would be an unverified analog block. The recommendation therefore uses an **external 32.768 kHz crystal/oscillator pin** for first silicon and treats an integrated RC as a later option.

---

## 3. Options

Scoring: ++ good, + acceptable, − poor, −− unacceptable.

| Criterion | A: single 50 MHz + enables | B: 50 + /2 25 MHz | C: B + 32 kHz AON | D: external 50/25/32k |
|---|---|---|---|---|
| Meets FR-CLK-002 | −− | ++ | ++ | ++ |
| Meets FR-CLK-004 | −− | −− | ++ | ++ |
| Functional correctness of peripheral rates | −− (2×) | ++ | ++ | ++ |
| Clock tree / CTS | ++ | + | − | + |
| CDC requirement | ++ (none) | + (sync handshake) | − (async AON) | −− (async 50/25) |
| Reset complexity | ++ | + | − | − |
| Timing constraints | ++ | + | − | − |
| Power / deep sleep | −− | − | ++ | + |
| Clock gating | + | + | + | + |
| Physical complexity | ++ | + | − | − |
| Verification complexity | ++ | + | − | − |
| External hardware | ++ | ++ | + (32k xtal) | − (3-output generator) |
| Firmware change | ++ (none) | − (all APB constants) | − | − |
| Area | ++ | + | − | + |
| Scalability | −− | + | ++ | + |
| **Verdict** | Descope only | Minimum compliant | **Recommended** | Not recommended |

**A** is the cheapest and is what exists, but it silently ships a product that does not meet its own clock requirements. It is acceptable only if the owner formally re-baselines FR-CLK-002/004 and accepts 2× peripheral rates.

**B** meets the digital frequency requirement with a synchronous divider and no asynchronous 50/25 crossing. It is the minimum compliant baseline if AON is deferred.

**C** is the only option that meets the low-power product requirements. It adds a true asynchronous AON domain, which is real engineering, not a documentation change.

**D** uses Si5351 outputs for both 50 and 25 MHz. It sounds simpler but makes core and peripheral asynchronous, forcing every APB access through a CDC handshake/FIFO. That is strictly worse than an internal /2 derived from the same source.

---

## 4. Recommended architecture (C-prime)

```
                 +---------------------------+
50.000 MHz  ---->| clk_core                  |
                 |   core / AXI / memories   |
                 |   QSPI / JTAG logic       |
                 +-------------+-------------+
                               |
                        toggle FF (/2)
                               |
                 +-------------v-------------+
                 | clk_periph (25.000 MHz)   |
                 |   APB bridge slave side   |
                 |   GPIO UART I2C SPI PWM   |
                 |   TIMER WDOG I2S          |
                 +-------------+-------------+
                               |
                      APB handshake / PLIC sync
                               |
                 +-------------v-------------+
32.768 kHz  ---->| clk_aon                   |
                 |   LPTIM / wake / PMU      |
                 |   reset stretcher         |
                 +---------------------------+
```

### 4.1 Clock sources

| Clock | Source | Frequency | Tolerance | Owner |
|---|---|---|---|---|
| `clk_core` | External LVCMOS oscillator or Si5351 CLK0 | 50.000 MHz | per source | Board |
| `clk_periph` | Internal divide-by-2 of `clk_core` | 25.000 MHz | inherited | SoC |
| `clk_aon` | External 32.768 kHz crystal/oscillator | 32.768 kHz | ±20 ppm (xtal) | Board |
| `jtag_tck` | External debug probe | ≤10 MHz | n/a | Test |
| `qspi_sck` | Internal divider of `clk_core` | ≤25 MHz first silicon | inherited | SoC |

### 4.2 Divider

- One toggle flip-flop clocked by `clk_core`, reset to 0, produces 50% duty at 25 MHz.
- This is a **generated clock**, not a clock enable. STA and CTS must define it with `create_generated_clock -divide_by 2`.
- The divider output drives the APB bridge's peripheral side and all APB peripherals.
- It does **not** drive the AXI fabric, memories or QSPI controller.

### 4.3 Reset strategy

| Domain | Assert | Deassert | Sources |
|---|---|---|---|
| AON | asynchronous from POR | 2-FF synchronizer on `clk_aon` | POR only |
| Core | asynchronous from POR or watchdog | 2-FF synchronizer on `clk_core` | POR, watchdog, PMU reset request |
| Peripheral | asynchronous, sourced from core reset request | 2-FF synchronizer on `clk_periph` | core reset, per-peripheral reset register |

All resets are active-low, asynchronously asserted, synchronously deasserted. The existing `reset_ctrl` bounded watchdog pulse is retained and becomes a core-reset source.

### 4.4 Clock gating and power states

| State | clk_core | clk_periph | clk_aon | Retention |
|---|---|---|---|---|
| ACTIVE | on | on | on | all |
| SLEEP | gated | gated | on | registers retained |
| DEEP | off (rail) | off (rail) | on | context saved by firmware |

Per-peripheral enables are added in the `clk_periph` domain (FR-CLK-005), using glitch-free integrated clock-gating cells or the existing enable-flop pattern. AON logic is never gated.

### 4.5 CDC boundaries created

| Boundary | Type | Mechanism |
|---|---|---|
| core → periph APB request | synchronous ratio 2:1 | request held until acknowledge |
| periph → core APB response | synchronous ratio 2:1 | response captured in core |
| core → AON PMU command | asynchronous | request/ack handshake |
| AON → core wake | asynchronous | 2-FF + pulse stretcher |
| AON → core PLIC interrupt | asynchronous | 2-FF + PLIC event capture |
| async pads → core/periph | asynchronous | 2-FF synchronizers |
| reset release per domain | asynchronous assert | 2-FF sync deassert |

A 25 MHz-to-50 MHz path is not automatically safe just because it is synchronous; the 2:1 ratio means a 25 MHz launch has two 50 MHz capture edges to meet. STA must constrain both directions and the handshake must prevent data being overwritten.

---

## 5. Impact

| Area | Impact |
|---|---|
| RTL | New divider, AON domain, reset synchronizers, APB handshake, per-peripheral enables, LPTIM, PMU |
| SDC | Two/three clocks, generated 25 MHz, async groups, max-delay on handshakes |
| CTS | Two synchronous trees, phase-aware; AON tree small and separate |
| STA | New setup/hold relationships; 25→50 and 50→25 paths |
| Firmware | UART divisor 434 → 217; timer/PWM/I2C/SPI/I2S constants halve; AON driver added |
| Area | Divider + synchronizers + AON retention/isolations (small to moderate) |
| Verification | APB handshake assertions, AON wake formal, reset-domain checks, frequency tests |
| Board | 32.768 kHz crystal/oscillator; 50 MHz source already planned |
| Power | Enables genuine deep sleep; requires power intent (see power report) |

---

## 6. ARC-006 decision package

| Item | Content |
|---|---|
| Current state | Single 50 MHz gated clock; no divider/AON/PLL; FR-CLK-002/004 unmet |
| Options | A, B, C, D (§3) |
| Recommended | **C-prime** |
| Why | Only option meeting mandatory clock and low-power requirements with a physically implementable, verifiable structure |
| Main risk | AON domain and power intent add Stage 2/6/10 effort; schedule pressure may tempt option A |
| Fallback | B with explicit, owner-signed descope of FR-CLK-004 and removal of AON claims |
| Not recommended | D (asynchronous 50/25 crossing), A (non-compliant) |
| Downstream | Unblocks Stages 2, 6, 8, 12, 15 |
| Approval required | User/design owner |
| Acceptance criteria | ARC-006 rewritten and signed; SDC clock plan signed; firmware frequency list accepted; board 32 kHz source accepted; AON power strategy linked to TD-005 |

### Verified vs recommended

- **Verified:** current RTL frequencies, absence of divider/AON, firmware assumptions, UART divisor, requirement text.
- **Recommended:** C-prime structure, external 32 kHz source, handshake mechanisms, per-domain reset.
- **Not approved:** any option. This document stops at READY FOR APPROVAL.
