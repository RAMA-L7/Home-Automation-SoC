# ASIC Stage 1 — CDC and RDC Architecture

Date: 2026-11-15
Status: **READY FOR APPROVAL** (ARC-036 / ARC-065)
Machine-readable: `architecture/cdc_rdc_matrix.csv` (31 crossings)

---

## 1. Verified current state

The SoC has **one functional clock** (`clk`). `core_clk` and `periph_clk` are gated copies, so there are **no internal clock-domain crossings** today. All internal CDC risk is at pin boundaries.

| Crossing / path | Current implementation | Status | Evidence |
|---|---|---|---|
| `reset_n` → `rst_sys_n` | async assert; counter-based watchdog pulse | Safe for single clock | `reset_ctrl.sv` |
| `uart_rx` → `pclk` | 2-FF `rx_sync1/rx_sync2` | Safe | `uart.sv:144-153` |
| `gpio[15:0]` → `pclk` | 2-FF + previous-value edge detect | Safe | `gpio.sv:46-73` |
| `wake_ack` → `clk` | 2-FF `wake_sync` | Safe (formal BMC) | `power_mgr.sv:38-43` |
| PLIC internal IRQ → `clk` | 2-FF `irq_meta/irq_sync` + event capture | Safe for level inputs; pulses <2 cycles can be lost | `plic.sv:48-72` |
| `spi_miso` → `pclk` | **no synchronizer**; sampled at SCK high | **Unsafe** | `spi_ctrl.sv:50` |
| `i2c_sda` → `pclk` | **no synchronizer**; combinational input | **Unsafe** | `i2c_ctrl.sv:48` |
| `jtag_tms`/`jtag_tdi` → TCK | single flop in TAP | **Unsafe** | `debug_jtag.sv` |
| `jtag_tdo` | driven in TCK domain | Partial | `debug_jtag.sv` |
| `qspi_io[1]` | source-synchronous read, sampled in `clk` | Needs timing/IO constraint, no metastability if SCK is generated and round-trip is constrained | `qspi_flash_ctrl.sv` |
| `ext_irq[31:0]` | tied to unused XOR | Dead, not a functional crossing | `has_soc.sv:555` |
| `clk` input | board clock | Must be constrained at implementation | `has_soc.sv:25` |

### Why the unsafe inputs matter

- `spi_miso` is sampled at the end of the SCK high phase. SCK is generated from `pclk`, so the *protocol* is source-synchronous and a 2-FF is not automatically required; however the input delay is unconstrained and there is no input capture register. It is marked unsafe because no IO timing constraint or synchronizer exists. Stage 6 must either add a proper source-synchronous input constraint or a capture flop.
- `i2c_sda` is an open-drain asynchronous input. The FSM samples it combinationally in the `pclk` domain. A 2-FF synchronizer plus a small filter is required; clock stretching (slave holding SCL) is not implemented at all.
- JTAG TMS/TDI are asynchronous to TCK. A single flop is not a synchronizer; the TAP must use 2-FF on TMS/TDI or a proper functional-clock crossing.

---

## 2. Crossings under the recommended architecture (C-prime)

The full 31-row matrix is in `architecture/cdc_rdc_matrix.csv`. The essential ones:

| ID | Source → destination | Signal | Mechanism required |
|---|---|---|---|
| PROP-01 | `clk_core` → `clk_periph` | APB request/address/wdata | Request held until acknowledge; no data overwrite |
| PROP-02 | `clk_periph` → `clk_core` | APB prdata/pslverr/pready | Response captured; handshake complete |
| PROP-03 | `clk_periph` → `clk_core` | PLIC source levels | 2-FF + event capture (existing PLIC pattern) |
| PROP-04 | `clk_core` → `clk_aon` | PMU command | Request/ack 2-FF handshake |
| PROP-05 | `clk_aon` → `clk_core` | Wake event | 2-FF + pulse stretcher |
| PROP-06 | `clk_aon` → `clk_core` | LPTIM interrupt | 2-FF then PLIC event |
| PROP-07 | `clk_aon` → `clk_periph` | AON APB registers | APB bridge with 2-FF handshake |
| PROP-08 | `clk_core` → `clk_periph` | Peripheral reset | Async assert, 2-FF deassert |
| PROP-09 | `clk_core` → `clk_aon` | Debug halt | 2-FF handshake |
| PROP-11 | TCK → `clk_core` | JTAG TMS/TDI | 2-FF or TCK-domain capture |
| PROP-12 | pad → `clk_periph` | UART1 RX | 2-FF |
| PROP-13 | pad → `clk_core` | I2C SDA | 2-FF + filter |
| PROP-14 | pad → `clk_core` | SPI MISO | Source-synchronous constraint + capture |
| PROP-15 | `clk_core` → pad | QSPI SCK | Output clock, constrained |

### 2.1 Is a 2:1 synchronous crossing safe without a FIFO?

No, not by itself. A 25 MHz peripheral cannot accept a new APB transfer every 50 MHz cycle. The bridge must:

1. assert request and hold address/data stable until `pready`;
2. wait for a synchronized acknowledge;
3. return response to the core exactly once;
4. never issue a second request while one is outstanding.

The existing `axi_lite_to_apb.sv` assumes a single clock and a fixed 2–3 cycle FSM. It must be reworked for the 2:1 ratio; this is Stage 2 work, not a Stage 1 implementation.

### 2.2 Reset-domain crossings (RDC)

Under C-prime there are three reset domains. Required structure:

| Domain | Assert | Deassert | Notes |
|---|---|---|---|
| AON | async from POR | 2-FF on `clk_aon` | never reset by core/watchdog |
| Core | async from POR/watchdog/PMU | 2-FF on `clk_core` | watchdog pulse bounded by `reset_ctrl` |
| Peripheral | async from core reset request | 2-FF on `clk_periph` | per-peripheral reset bits added later |

Unsafe pattern to avoid: using `rst_sys_n` directly in a `clk_periph` or `clk_aon` flop without a local synchronizer. Reset removal must be synchronous to each destination clock; assertion can be asynchronous.

---

## 3. ARC-036 / ARC-065 proposal

### 3.1 Scope change

The historical ARC-036/065 text assumes **three asynchronous clock domains with async FIFOs, gray pointers and 3-flop synchronizers**. That does not match the current RTL and would not match C-prime either:

- Core ↔ peripheral is **synchronous 2:1**, not asynchronous; an async FIFO is the wrong mechanism.
- Core ↔ AON is asynchronous and needs 2-FF/handshake, not a data FIFO unless AON carries bulk data (it does not).
- No gray-pointer FIFO exists or is required for the planned crossings.

### 3.2 Proposed property set

| Property | Domain | What is proven |
|---|---|---|
| CDC-APB-REQ | core/periph | Request held stable until acknowledge; exactly one response per request |
| CDC-APB-DATA | core/periph | No data loss or duplication across the 2:1 ratio |
| CDC-AON-WAKE | AON/core | Every wake event is observed; no spurious wake; no event lost if asserted during reset release |
| CDC-AON-CMD | core/AON | PMU command accepted once; busy blocks a second command |
| CDC-PLIC-EVENT | periph/core | Level and pulse events captured; claim clears correctly |
| RDC-CORE-REL | core | Reset deassert synchronized; no flop leaves reset on a metastable edge |
| RDC-PERIPH-REL | periph | Same, relative to core reset request |
| RDC-AON-REL | AON | POR-only release; no core reset coupling |
| CLK-GATE | core/periph | No glitch on gate enable/disable; enable captured on the inactive edge |
| CLK-DIV2 | core/periph | Generated clock has 50% duty and one edge per two core cycles |

Formal harnesses: extend the existing SBY flow. Bounded BMC is acceptable for directed scenarios; the reset release and handshake protocols should use `abc pdr` where the state space permits.

### 3.3 Verification method

- SVA assertions on the APB bridge handshake and the AON wake handshake.
- Formal BMC/PDR for reset release and handshake protocols.
- CDC structural lint (existing `cdc_inventory.js`) updated to the new domains.
- Gate-level simulation of reset release after Stage 7.
- STA constraints for all synchronous crossings; `set_clock_groups -asynchronous` only for true async domains (core/AON, JTAG).

### 3.4 Unsafe crossings to fix in Stage 2

1. `spi_miso`: add capture flop and IO constraint, or document a source-synchronous exception with timing evidence.
2. `i2c_sda`: add 2-FF + filter; implement clock stretching or explicitly descope it.
3. `jtag_tms/tdi`: 2-FF in TCK domain; add IDCODE/DMI only if debug scope requires it.
4. `qspi_io[1]`: constrain SCK-to-input round trip; add input capture if the round trip cannot meet setup at 25 MHz.
5. PLIC pulse loss: document minimum pulse width or add a pulse stretcher.

---

## 4. Approval package

| Item | Content |
|---|---|
| Current state | Single clock; 3 unsafe pin crossings; no internal CDC; RDC single reset |
| Recommended | C-prime crossing set + property list in §3.2 |
| Rejected | Three-domain async FIFO plan as written (no object in RTL) |
| Risks | AON domain adds true async paths; 2:1 APB handshake is easy to get wrong and must be formal |
| Downstream | Stage 2 RTL, Stage 5 formal, Stage 6 closure, Stage 8 SDC |
| Approval | ARC-036 and ARC-065 by user/design owner |
| Acceptance | Property list approved; unsafe crossings accepted for fix; no "3-domain FIFO" claim left in docs |

**Verified:** current synchronizer inventory, unsafe inputs, reset structure.
**Recommended:** crossing mechanisms and property set.
**Not approved:** ARC-036/065 remain unapproved until owner sign-off.
