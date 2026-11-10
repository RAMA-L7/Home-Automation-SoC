# Formal CDC Verification Plan — Home-Automation-SoC

**Document ID:** HAS-SoC-CDC-PLAN-001  
**Version:** 1.0  
**Date:** 2026-11-11  
**Status:** DRAFT — For Review  
**Addresses:** ARC-036 (BLOCKED), ARC-065 (BLOCKED), ADR-010

---

## 1. Clock Domain Overview

| Domain | Frequency | Voltage | Source | Description |
|--------|-----------|---------|--------|-------------|
| **clk_core** | 50 MHz | 1.0 V | Si5351 CLK0 | Ibex, SRAM, TCM, Bus Fabric, Crypto |
| **clk_periph** | 25 MHz | 1.8 V | clk_core / 2 | APB Peripherals, UART, SPI, I²C, PWM, Timers |
| **clk_aon** | 32.768 kHz | 3.3 V | Internal LPO | LPTIM, PMIC I²C, Wake Logic, POR |

---

## 2. Clock Domain Crossings (CDC) — Complete Enumeration

| CDC ID | From Domain | To Domain | Signal Type | Mechanism | Depth/Stages | Verification Method |
|--------|-------------|-----------|-------------|-----------|--------------|---------------------|
| **CDC-001** | clk_core | clk_periph | AXI4-Lite → APB Bridge (addr/data/control) | Async FIFO (2-deep) + Gray code pointers | 2 entries | Formal (sby) + Sim |
| **CDC-002** | clk_periph | clk_core | APB → AXI4-Lite Bridge (read data/resp) | Async FIFO (2-deep) + Gray code pointers | 2 entries | Formal (sby) + Sim |
| **CDC-003** | clk_core | clk_aon | Power-domain control (enable/gate) | 3-flop synchronizer | 3 stages | Formal (sby) |
| **CDC-004** | clk_aon | clk_core | Wake interrupts (LPTIM, GPIO, PMIC) | 3-flop synchronizer + edge detect | 3 stages | Formal (sby) + Sim |
| **CDC-005** | clk_periph | clk_aon | Peripheral sleep requests | 3-flop synchronizer | 3 stages | Formal (sby) |
| **CDC-006** | clk_aon | clk_periph | PMIC alerts, RTC alarms | 3-flop synchronizer + pulse stretch | 3 stages | Formal (sby) |
| **CDC-007** | clk_core | clk_core | Reset synchronizer (async assert, sync deassert) | 3-flop per domain | 3 stages | Formal (sby) |
| **CDC-008** | clk_periph | clk_periph | Reset synchronizer | 3-flop | 3 stages | Formal (sby) |
| **CDC-009** | clk_aon | clk_aon | Reset synchronizer (LPO) | 3-flop | 3 stages | Formal (sby) |
| **CDC-010** | clk_core | clk_qspi* | QSPI Controller (if separate clock) | Async FIFO / synchronizer | TBD | Formal (sby) |

*clk_qspi = clk_core or clk_core/4 (derived, same PLL) — treat as synchronous if derived, async if external*

---

## 3. Formal Verification Properties (SymbiYosys)

### 3.1 Asynchronous FIFO Properties (CDC-001, CDC-002)

```systemverilog
// Async FIFO: clk_core → clk_periph (AXI-Lite → APB)
// Module: axi_lite_to_apb_bridge

// Property 1: No data loss (write/read pointers never cross incorrectly)
assert property (@(posedge clk_wr) disable iff (!rst_n)
    $rose(wr_en) |-> ##[0:$] $rose(rd_en) || (wr_ptr != rd_ptr));

// Property 2: No overflow (wr_ptr - rd_ptr < DEPTH)
assert property (@(posedge clk_wr) disable iff (!rst_n)
    (wr_ptr - rd_ptr) < DEPTH);

// Property 3: No underflow (rd_en only when data valid)
assert property (@(posedge clk_rd) disable iff (!rst_n)
    rd_en |-> (wr_ptr != rd_ptr));

// Property 4: Data integrity (data_out matches data_in at corresponding pointer)
// Requires data comparison logic in testbench

// Property 5: Gray code pointer crossing correctness
assert property (@(posedge clk_wr) disable iff (!rst_n)
    $onehot0(wr_ptr_gray ^ $past(wr_ptr_gray))); // Only 1 bit changes
```

### 3.2 Multi-Flop Synchronizer Properties (CDC-003–006, 007–009)

```systemverilog
// 3-Flop Synchronizer: clk_aon → clk_core (Wake interrupt)
// Module: cdc_sync_3flop

// Property 1: Metastability resolution (output stable after 3 cycles)
assert property (@(posedge clk_dst) disable iff (!rst_n)
    $rose(src_async) |-> ##3 dst_sync);

// Property 2: No glitch propagation (output doesn't toggle spuriously)
assert property (@(posedge clk_dst) disable iff (!rst_n)
    !$rose(dst_sync) || $rose(src_async) || $fell(src_async));

// Property 3: Pulse width preservation (input pulse ≥ 1 src cycle → output pulse ≥ 1 dst cycle)
assert property (@(posedge clk_dst) disable iff (!rst_n)
    (##1 src_async) |-> ##[1:3] dst_sync);
```

### 3.3 Reset Synchronizer Properties (CDC-007–009)

```systemverilog
// Reset Synchronizer: Async assert, sync deassert
// Module: reset_sync

// Property 1: Async assert immediate
assert property (@(posedge clk) disable iff (!rst_n)
    !rst_async_n |-> !rst_sync_n);

// Property 2: Sync deassert (3 cycles after async release)
assert property (@(posedge clk) disable iff (!rst_n)
    $rose(rst_async_n) |-> ##3 rst_sync_n);

// Property 3: No glitches during deassert
assert property (@(posedge clk) disable iff (!rst_n)
    rst_sync_n |-> ##[1:2] rst_sync_n);
```

### 3.4 Bus Protocol CDC Properties

```systemverilog
// AXI4-Lite → APB Bridge: Handshake integrity
// Module: axi_lite_to_apb_bridge

// Property: AWREADY/AWVALID handshake preserved across CDC
assert property (@(posedge clk_core) disable iff (!rst_n)
    awvalid & awready |-> ##[1:3] (apb_psel & apb_penable & apb_pwrite));

// Property: ARREADY/ARVALID handshake preserved
assert property (@(posedge clk_core) disable iff (!rst_n)
    arvalid & arready |-> ##[1:3] (apb_psel & apb_penable & !apb_pwrite));

// Property: Read data returns to correct master
assert property (@(posedge clk_core) disable iff (!rst_n)
    (apb_pready & !apb_pwrite) |-> ##[1:3] (rvalid & (rid == arid)));
```

---

## 4. Verification Environment Setup

### 4.1 SymbiYosys Configuration (`scripts/formal/cdc.sby`)

```tcl
[options]
mode prove
depth 50
multiclock on
append "set_option -auto_clock_en 1"

[engines]
smtbmc yices
smtbmc z3
smtbmc cvc5

[script]
read_verilog -formal rtl/axi_lite_to_apb_bridge.sv
read_verilog -formal rtl/cdc_sync_3flop.sv
read_verilog -formal rtl/reset_sync.sv
read_verilog -formal rtl/async_fifo.sv
prep -top cdc_top

[files]
rtl/axi_lite_to_apb_bridge.sv
rtl/cdc_sync_3flop.sv
rtl/reset_sync.sv
rtl/async_fifo.sv
```

### 4.2 CDC Testbench (Simulation Cross-Check)

```systemverilog
// tb_cdc.sv — Directed + Random CDC Tests
module tb_cdc;
    // Clocks
    logic clk_core, clk_periph, clk_aon;
    initial clk_core = 0; always #10 clk_core = ~clk_core;   // 50 MHz
    initial clk_periph = 0; always #20 clk_periph = ~clk_periph; // 25 MHz
    initial clk_aon = 0; always #15259 clk_aon = ~clk_aon;    // 32.768 kHz

    // Test: AXI-Lite → APB write/read across CDC
    // Test: Wake interrupt from AON to Core
    // Test: PMIC alert from AON to Periph
    // Test: Reset deassert synchronization
    // Coverage: All CDC paths exercised
endmodule
```

---

## 5. Coverage Goals

| Coverage Type | Target | Scope |
|---------------|--------|-------|
| **Formal Proof** | 100% (all properties proven) | All 10 CDC paths |
| **Code Coverage (Line)** | 100% | CDC modules only |
| **Toggle Coverage** | 100% | All CDC signals |
| **FSM Coverage** | 100% | Async FIFO state machines |
| **Assert Coverage** | 100% | All `assert`/`assume` in CDC modules |
| **Simulation CDC Tests** | 100% path coverage | Directed + constrained-random |

---

## 6. Tool Flow

```bash
# Formal CDC Verification
cd scripts/formal
sby -f cdc.sby

# Simulation CDC Tests
cd sim
verilator --cc --coverage --trace tb_cdc.sv rtl/cdc_*.sv
make -C obj_dir -f Vtb_cdc.mk
./obj_dir/Vtb_cdc
```

---

## 7. Sign-off Criteria

| Criterion | Status |
|-----------|--------|
| All 10 CDC paths have formal properties defined | ☐ |
| SymbiYosys proves all properties (no unknowns) | ☐ |
| No CDC violations in simulation regression | ☐ |
| Coverage goals met (≥95% all types) | ☐ |
| CDC review completed by verification lead | ☐ |
| **ARC-036 / ARC-065 Status → PROPOSED** | ☐ |

---

## 8. Open Issues

1. **QSPI Clock Domain** — If QSPI uses separate clock (not derived), add CDC-010 properties
2. **Si5351 I²C Domain** — I²C runs on clk_periph (25 MHz), PMIC on clk_aon — already covered by CDC-005/006
3. **Analog/PLL Interface** — No on-chip PLL; Si5351 external — no analog CDC

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-11 | Lead | Initial CDC plan for ARC-036/065 resolution |

---

*This plan enables ARC-036 and ARC-065 to move from BLOCKED → PROPOSED upon execution and proof completion.*