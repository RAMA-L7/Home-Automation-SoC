# Home-Automation-SoC — Verification Results
# Stage 4 Verification
# Agent: OpenCode (nemotron-3.5-super-vl-free)

## Test Summary

All tests executed with actual tool output (MEASURED). No results fabricated.

| Test | Tool | Result | Details | Location |
|------|------|--------|---------|----------|
| RTL Lint | Verilator 5.053 | **PASS** (0 errors) | 22 SystemVerilog files, 279 benign warnings | `rtl/` |
| SRAM Read/Write | Icarus 14.0 | **PASS** | Full-word + byte write/read | `sim/sim_top/tb_sram_simple.v` |
| GPIO Register | Icarus 14.0 | **PASS** | OE + data out write/read | `sim/sim_top/tb_gpio.v` |
| Timer Compare | Icarus 14.0 | **PASS** | Compare value set + counter runs | `sim/sim_top/tb_timer.v` |
| Watchdog Expiry | Icarus 14.0 | **PASS** | Load=5, expires after 5 cycles | `sim/sim_top/tb_watchdog.v` |
| PWM Register | Icarus 14.0 | **PASS** | Period + duty write/read | `sim/sim_top/tb_pwm.v` |
| I2C Register | Icarus 14.0 | **PASS** | Enable + slave address | `sim/sim_top/tb_i2c.v` |
| SPI Register | Icarus 14.0 | **PASS** | Enable + status read | `sim/sim_top/tb_spi.v` |
| I2S Register | Icarus 14.0 | **PASS** | Enable + status read | `sim/sim_top/tb_i2s.v` |
| CLINT Register | Icarus 14.0 | **PASS** | MSIP write/read + MTIME read | `sim/sim_top/tb_clint.v` |
| PLIC Register | Icarus 14.0 | **PASS** | Priority + enable + IRQ out | `sim/sim_top/tb_plic.v` |
| Power Mgr Regs | Icarus 14.0 | **PASS** | Sleep req + wake enable | `sim/sim_top/tb_power_mgr.v` |
| JTAG TAP | Icarus 14.0 | **PASS** | TAP state machine exercised | `sim/sim_top/tb_debug_jtag.v` |
| GPIO Synthesis | Yosys 0.69 | **PASS** | 603 cells, 0 problems | `rtl_peripherals/gpio.sv` |
| UART Synthesis | Yosys 0.69 | **PASS** | 358 cells, 0 problems | `rtl_peripherals/uart.sv` |
| Timer Synthesis | Yosys 0.69 | **PASS** | 359 cells, 0 problems | `rtl_peripherals/timer.sv` |
| Watchdog Synthesis | Yosys 0.69 | **PASS** | 307 cells, 0 problems | `rtl_peripherals/watchdog.sv` |
| I2C Synthesis | Yosys 0.69 | **PASS** | 66 cells, 0 problems | `rtl_peripherals/i2c_ctrl.sv` |
| SPI Synthesis | Yosys 0.69 | **PASS** | 329 cells, 0 problems | `rtl_peripherals/spi_ctrl.sv` |
| I2S Synthesis | Yosys 0.69 | **PASS** | 25 cells, 0 problems | `rtl_peripherals/i2s.sv` |
| CLINT Synthesis | Yosys 0.69 | **PASS** | 963 cells, 0 problems | `rtl_peripherals/clint.sv` |
| PLIC Synthesis | Yosys 0.69 | **PASS** | 412 cells, 0 problems | `rtl_peripherals/plic.sv` |
| Power Mgr Regs Synthesis | Yosys 0.69 | **PASS** | 31 cells, 0 problems | `rtl_peripherals/power_mgr_regs.sv` |
| Debug JTAG Synthesis | Yosys 0.69 | **PASS** | 0 cells (stub), 0 problems | `rtl_peripherals/debug_jtag.sv` |
| Watchdog formal (pet/timeout) | SBY 0.69 + smtbmc/boolector | **PASS** | BMC depth 96, 13 properties + 2 covers, 0 fail | `scripts/formal/watchdog_fv.sv` |
| Reset controller formal (invariants) | SBY 0.69 + abc pdr | **PASS** | Unbounded proof, 5 properties, 0 fail | `scripts/formal/reset_ctrl_fv.sv` |
| Reset controller formal (timing) | SBY 0.69 + smtbmc/boolector | **PASS** | BMC depth 60, 6 properties, exact pulse width/phase | `scripts/formal/reset_ctrl_seq_fv.sv` |
| CDC formal (async wake) | SBY 0.69 + smtbmc/boolector | **PASS** | BMC depth 30, 5 properties: wake synchronized and never lost | `scripts/formal/cdc_power_mgr_fv.sv` |
| CDC structural inventory | `scripts/formal/cdc_inventory.js` | **PASS** | 12 classified crossings, all structural checks pass | `rtl/**/*.sv` |

## Verification Coverage

### Covered
- Bus protocol (AXI4-Lite read/write, byte strobes)
- Peripheral register read/write (all 12 APB peripherals)
- Timer compare match
- Watchdog expiry
- PWM period/duty configuration
- GPIO output enable + data
- I2C enable + slave address
- SPI enable
- I2S enable
- CLINT MSIP + MTIME
- PLIC priority + enable + interrupt output
- Power manager sleep/wake registers
- JTAG TAP state machine
- Reset behavior (all peripherals reset to known state)
- Synthesis of all major peripherals (Yosys)

### Now Covered (2026-11-12)
- Full-SoC functional simulation — Verilator C++ model (boot 7/7) and Icarus
- RISC-V instruction execution — `tb_isa.v` 24/24 directed + 47/47 trap checks
- UART protocol at pin level — `tb_uart.v` 153/153 checks
- Watchdog reset path — `tb_reset_ctrl.v` 15/15 checks
- Firmware-driven test — `tb_firmware.v` runs the compiled C image
  (banner → UART command → watchdog reset → reboot → LED); suite is 17/17 PASS
- Formal properties — four SymbiYosys tasks prove behaviour, not just parse:
  `watchdog` (BMC 96), `reset_ctrl` (unbounded `abc pdr`), `reset_ctrl_seq`
  (BMC 60) and `cdc_power_mgr` (BMC 30).  Run with
  `node scripts/formal/run_formal.js` → **PASS 4 / 4, exit 0**, and the runner
  rejects false PASSes (`--self-test` → 5/5 negative controls rejected).
- CDC structural inventory — `node scripts/formal/cdc_inventory.js` derives the
  crossing table from the RTL instead of from the architecture plan.

## Formal property inventory

| Task | Engine | Bound | Property | Expectation | Class |
|---|---|---|---|---|---|
| watchdog | smtbmc/boolector | 96 | W0 APB shape | ACCESS repeats SETUP control/data | Bounded proven |
| watchdog | | | W9 completion | `pready` always 1, `pslverr` always 0 | Bounded proven |
| watchdog | | | W1 idle | untouched block: no irq, no reset | Bounded proven |
| watchdog | | | W2 pet suppresses expiry | no irq while petted every 2nd cycle, to the cycle before expiry | Bounded proven |
| watchdog | | | W3 armed mapping | `reset_n_out == ~irq` while armed | Bounded proven |
| watchdog | | | W4 expiry after feeding stops | irq at the computed cycle, not later | Bounded proven |
| watchdog | | | W5 pet after expiry | latched timeout and reset clear | Bounded proven |
| watchdog | | | W6 disable | counter frozen, no expiry for 10 cycles | Bounded proven |
| watchdog | | | W7 re-enable | reloads from LOAD, expires one period later | Bounded proven |
| watchdog | | | W8 max value | 0xFFFF_FFFF does not wrap or expire early | Bounded proven |
| watchdog | | | W10 KEY lock | CTRL write ignored; read-back 111 | Bounded proven |
| watchdog | | | W11 zero value | expires one latch delay after the write | Bounded proven |
| watchdog | | | W12 async reset | reset dominates, incl. a LOAD in flight | Bounded proven |
| watchdog | | | W13 reset clears | LOAD/CTRL read 0; lock cleared | Bounded proven |
| reset_ctrl | abc pdr | unbounded | R1 width bound | `rst_sys_n` never low > HOLD cycles | **Unbounded proven** |
| reset_ctrl | | | R1b no early release | not released before HOLD | **Unbounded proven** |
| reset_ctrl | | | R2 release | released the cycle after full width | **Unbounded proven** |
| reset_ctrl | | | R3 prompt assert | idle + timeout ⇒ reset next cycle | **Unbounded proven** |
| reset_ctrl | | | R4 pins agree | both pins carry the pulse | **Unbounded proven** |
| reset_ctrl_seq | smtbmc/boolector | 60 | S1..S6 | exact 16-cycle pulses, exact release cycles, mid-pulse timeout does not truncate | Bounded proven |
| cdc_power_mgr | smtbmc/boolector | 30 | CD1..CD5 | clocks gated in sleep; 2-cycle wake always delivered within 3 cycles; no re-sleep; no spurious ack | Bounded proven |

Deliberately **not** asserted (would be unsound with this model):

| Candidate | Why not |
|---|---|
| "pad reset forces both outputs low in the first cycle after power-on" | Yosys leaves the DUT registers free in the initial state; the async reset is only observable from the first clock edge. Covered instead by reset_ctrl_seq S1 on a concrete timeline. |
| Delivery of a 1-cycle wake pulse | A level synchronizer may legitimately miss it; asserting delivery would be wrong, not strong. |
| Any CDC-001..CDC-007 property from the plan | Those crossings (async FIFO, gray pointers, 3-flop syncs, clk_aon) **do not exist in the RTL** — see the CDC section below. |

## CDC inventory (from the RTL, 2026-11-12)

**The SoC has one clock.** `core_clk` and `periph_clk` are gated copies of
`clk` (`clk & en_q`, enables re-timed on the falling edge), so there is no
asynchronous clock-domain crossing between blocks. Real crossings are pin-level
asynchronous inputs only — `clk_core`/`clk_periph`/`clk_aon` from the CDC plan
are not implemented.

| Crossing | Source | Synchronization in RTL | Evidence | Status |
|---|---|---|---|---|
| GPIO pads | async pin | `gpio_in_sync1 → gpio_in_sync2 → gpio_in_prev` (2 FF + edge detect) | `gpio.sv:65-74` | Structurally checked |
| UART RX | async pin | `rx_sync1 → rx_sync2` + 16× oversample | `uart.sv` | Structurally checked |
| Wake request | other domain | 2-bit shift `wake_sync` (`{wake_sync[0], wake_ack}`) | `power_mgr.sv:35-40` | **Formally proven (behavioural, BMC 30)** |
| JTAG TCK | async clock | `tck_sync1 → tck_sync2`, used as a level + edge detect | `debug_jtag.sv:28-32` | Structurally checked |
| JTAG TMS/TDI | TCK domain | 2-FF (`tms_meta/tms_sync`, `tdi_meta/tdi_sync`) | `debug_jtag.sv` | structurally checked; TDO one shift edge late (documented) |
| SPI MISO | pad (SCK domain) | protocol: sampled at end of SCK high phase; SCK generated by pclk (no second domain) | `spi_ctrl.sv` | simulation tested (mode 0) |
| PLIC `ext_irq` (fed by `periph_irq`) | gated clk (core/periph) | 2-FF + rising-edge capture (`irq_meta/irq_sync/irq_prev`) | `plic.sv` | structurally checked; source is synchronous, 2-FF is defensive |
| I2S `i2s_din` | async pin | declared but unused (TX-only block) | `i2s.sv:29` | Not a crossing |

What these results do **not** establish:

- No metastability/MTBF claim: logic-level formal cannot model it, and a two-flop
  chain is a structural mitigation, not proof.
- The three findings above are real gaps, not proven-safe paths. Fixing them is
  RTL work that has not been done (SPI/I²C/JTAG have no device-model tests, so a
  change there could not be regression-protected yet).
- The inventory script is a text scan: it cannot tell an intentionally
  asynchronous port from a synchronizer input, and it does not prove the
  destination reads the *last* stage.

### Bugs found by the new formal tasks

| Bug | Found by | Fix |
|-----|----------|-----|
| Watchdog pet never reloaded the counter: the LOAD write and the count-down
  were in the same `always_ff`, so the decrement overwrote `count <= pwdata`.
  A petted dog expired ~N cycles later anyway, and firmware only masked it by
  petting faster than the reload value. | `watchdog_fv.sv` W2 failed at cycle
  14 of 56 with a legal pet every cycle | `rtl/rtl_peripherals/watchdog.sv`:
  new `reload` term gates the decrement |

### Not Yet Covered
- cocotb-based verification (cocotb 2.1.0 installed, no cocotb testbench written)
- riscv-dv ISA tests (RISC-V toolchain installed, riscv-dv not set up)
- Multi-clock CDC verification: there is no multi-clock design to verify. The
  `clk_core`/`clk_periph`/`clk_aon` domains, async FIFOs and gray-coded pointers
  in `docs/verification/formal_cdc_verification_plan.md` are **not implemented**;
  the prep-only `cdc.sby` scaffold and its failed-run artifacts were removed on
  2026-11-12 because they could be mistaken for a passing CDC proof.
- SPI supports mode 0 only and ignores `pstrb` (documented limitation).
- JTAG has no DMI/DTM/IDCODE and `trst_n` is unused; TDO is one shift edge late.
- PLIC source is synchronous (periph_irq on gated clk); 2-FF is defensive, not a CDC.
- Formal coverage of the full SoC, the RV32IM core, the bus fabric, and the
  APB peripherals other than the watchdog and reset controller
- Low-power/UPF verification (no open-source UPF tool)
- Hardware execution (no FPGA board, no Vivado)

## Waveform Files
- `sim/waveforms/tb_sram.vcd`
- `sim/waveforms/tb_gpio.vcd`
- `sim/waveforms/tb_timer.vcd`
- `sim/waveforms/tb_watchdog.vcd`
- `sim/waveforms/tb_pwm.vcd`
- `sim/waveforms/tb_i2c.vcd`
- `sim/waveforms/tb_spi.vcd`
- `sim/waveforms/tb_i2s.vcd`
- `sim/waveforms/tb_clint.vcd`
- `sim/waveforms/tb_plic.vcd`
- `sim/waveforms/tb_power_mgr.vcd`
- `sim/waveforms/tb_debug_jtag.vcd`

## Build & Test Commands

### Verilator Lint
```cmd
set PATH=D:\tools\oss-cad-suite\bin;D:\tools\oss-cad-suite\lib;%PATH%
cd /D D:\Home-Automation-SoC\rtl
verilator_bin.exe --lint-only -Wall --top-module has_soc <all RTL files>
```
Expected: 0 errors.

### Icarus Simulation (example: GPIO)
```cmd
set PATH=D:\tools\oss-cad-suite\bin;D:\tools\oss-cad-suite\lib;%PATH%
cd /D D:\Home-Automation-SoC\sim\sim_top
iverilog.exe -g2012 -o tb_gpio.vvp ../../rtl/rtl_peripherals/gpio.sv tb_gpio.v
vvp.exe tb_gpio.vvp
```
Expected: "ALL TESTS PASSED".

### Yosys Synthesis (example: GPIO)
```cmd
set PATH=D:\tools\oss-cad-suite\bin;D:\tools\oss-cad-suite\lib;%PATH%
cd /D D:\Home-Automation-SoC\rtl
yosys.exe -p "read_verilog -sv rtl_peripherals\gpio.sv; synth -top gpio; stat"
```
Expected: 0 problems, cell count reported.

### Formal Verification (SymbiYosys)
```bash
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
node scripts/formal/run_formal.js               # all four tasks, strict
node scripts/formal/run_formal.js watchdog      # one task
node scripts/formal/run_formal.js --self-test   # negative controls
node scripts/formal/cdc_inventory.js            # crossing table from RTL
```
Expected: `PASS 4 / 4`, exit 0; self-test prints five `REJECTED` lines and
`RUNNER SELF-TEST: PASS`.  Raw invocation of a single task:
```bash
cd scripts/formal && sby -f -d ../../build/formal/watchdog watchdog.sby
```

## Known Limitations
- No FPGA demonstration (Vivado not installed, no FPGA hardware)
- No ASIC signoff (no sky130 PDK, no OpenROAD/OpenLane)
- All power/timing figures are ESTIMATED, not measured
- Formal proof scope is four tasks: watchdog, reset controller (two tasks) and
  the power-manager wake synchronizer.  Only `reset_ctrl` is unbounded; the other
  three are bounded BMC over directed, deterministic stimuli — complete for the
  scenario, not theorems about all traffic.
- Yosys 0.69's SystemVerilog frontend rejects `|->`/`|=>`/`##1` and mis-resolves
  hierarchical references inside assertions, so every property is an immediate
  assertion on harness-local signals; there are no write-side (assume) constraints.
- Verible lint exits 1 on style rules only (`parameter-name-style` 42 in the
  harnesses, 54 + `explicit-parameter-storage-type` 26 in the RTL).  The parser
  (`verible-verilog-syntax --lang=sv`) reports **0 syntax errors, exit 0**.

---

## Phase 3 — CDC hardening, peripheral verification, unified gate (2026-11-12)

All numbers below are measured in this session; commands are in §I of the
delivery report and in `AGENTS.md` §15.

### Verification gate

`node scripts/verify.js` — **9 / 9 tasks PASS, exit 0**.

| Task | Result | Evidence |
|------|--------|----------|
| tool availability | PASS | `build/verify/tools.log` |
| Verible syntax (parser) | PASS | 0 syntax errors over all `rtl/**/*.sv` + `scripts/formal/*.sv` |
| Verible lint | PASS | `lint/verible.rules` (project conventions) + pinned baseline |
| Icarus regression | PASS 22 / 22 | `build/verify/regression.log` |
| Formal (SBY) | PASS 5 / 5 | `build/verify/formal.log` |
| CDC inventory + structural checks | PASS | `build/verify/cdc-inventory.log` |
| Peripheral protocol tests | PASS 5 / 5 | `build/verify/protocol-tests.log` |
| Mermaid render | PASS | `build/verify/mermaid.log` |
| Diagram + docs idempotency | PASS | `build/verify/docs-sync.log` |

Negative controls (`node scripts/verify.js --self-test`): **6 / 6 rejected** —
failed simulation, failed assertion, missing tool, missing configuration, stale
PASS log, incomplete result.

### Formal tasks

| Task | Engine | Depth | Result |
|------|--------|-------|--------|
| watchdog | smtbmc boolector | 96 | PASS |
| reset_ctrl | abc pdr | unbounded | PASS |
| reset_ctrl_seq | smtbmc boolector | 60 | PASS |
| cdc_power_mgr | smtbmc boolector | 30 | PASS |
| plic_regs (new) | smtbmc boolector | 52 | PASS |

All five are bounded proofs over directed stimuli except `reset_ctrl`, which is
unbounded.

### New tests

| Testbench | Checks | Class |
|-----------|--------|-------|
| `tb_plic_proto.v` | 18 | simulation tested |
| `tb_spi_device.v` | 5 transfers, both directions | simulation tested |
| `tb_jtag_proto.v` | 16 (full TAP walk) | simulation tested |
| `tb_watchdog_audit.v` | 19 | simulation tested; rejects the phase-2 mutant |
| `tb_sram_audit.v` | 24 | simulation tested; rejects the phase-2 mutant |

### Defects found and fixed in this phase

1. **JTAG TAP could not shift.** The next-state table only implemented the TMS=1
   arcs; with TMS=0 the state never changed, so `SHIFT_DR`/`SHIFT_IR` were
   unreachable and TDI could never be shifted in. Replaced with the IEEE 1149.1
   transition table; `tb_jtag_proto.v` walks every state.
2. **SPI receive path was one bit late.** MISO was sampled at the end of the SCK
   low phase, where a mode-0 slave has already presented the *next* bit; every
   received byte came back shifted left by one (`0x3C` read as `0x78`). Sampling
   moved to the end of the high phase. **The old loopback test could not see
   this** because loopback feeds back the transmit bit.

Both are reproducible: run the new testbenches against `git show
HEAD:rtl/.../spi_ctrl.sv` and `HEAD:rtl/.../debug_jtag.sv`.

### Classification

| Claim | Class |
|-------|-------|
| watchdog reload priority, PLIC register/claim semantics | bounded proven (formal, directed) |
| reset pulse invariants | proven (unbounded) |
| PLIC synchroniser + event capture, JTAG TAP, SPI mode 0, SRAM strobes | simulation tested |
| CDC mechanism presence for every pin (12 rows) | structurally checked |
| metastability immunity, MTBF, silicon timing | **not claimed** — needs STA and silicon |

Limitations: JTAG has no DMI/DTM and `trst_n` is unused (TAP reset only by
system reset or 5×TMS); SPI supports mode 0 only and ignores `pstrb`; the SRAM
has two read ports on one array (needs a dual-port macro); pulses shorter than
two `clk` cycles on a level-sensitive input can still be missed.
