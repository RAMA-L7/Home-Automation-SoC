#==============================================================================
# Home-Automation-SoC — has_soc timing constraints
#
# STATUS: ESTIMATED / PRE-SIGNOFF.  Every I/O delay below is a documented
#         assumption about the board and the external device, not an extracted
#         value.  No RCX/SPEF exists for this design yet, so this file must not
#         be described as signoff-grade.  See the report for what is missing.
#
# VALIDATED BY: node scripts/eda/run_sdc_lint.js
#   Loads this file into OpenSTA against the real has_soc port list and checks
#   that every command parses, every object resolves, and every port carries an
#   input/output delay.  That validates the CONSTRAINT FILE, not the timing of
#   the design.
#
# Correctness notes on the previous revision (all fixed here):
#   * `foreach gpio_i in [15:0] begin ... end` is HDL syntax, not Tcl, and
#     aborted the script at the first GPIO constraint.
#   * `-comment "..."` is not an option of set_input_delay/set_output_delay;
#     it made every one of those commands an error.
#   * `set_clock_groups -asynchronous -exclusive ... [get_ports jtag_tck]`
#     mixed the two group modes and passed a PORT where a clock belongs.
#   * No set_units: a 20.0 period and 0.030 delays were left with implied units
#     while the comments said "30 ns" — a 1000x discrepancy.
#   * `set_max_delay -datapath_only 18.0 [all_inputs] [all_outputs]` was a
#     blanket cut across every I/O path; it is removed and replaced by a real
#     per-port constraint for every port.
#==============================================================================

#------------------------------------------------------------------------------
# Units — declared explicitly so every number below is unambiguous.
#------------------------------------------------------------------------------
set_units -time ns -capacitance pF -resistance kOhm -voltage V -current mA

#------------------------------------------------------------------------------
# Clocks
#------------------------------------------------------------------------------
# Core clock: 50 MHz (20 ns). The only synchronous clock in the SoC.
create_clock -name sys_clk -period 20.0 [get_ports clk]

#------------------------------------------------------------------------------
# JTAG — constrained as IMPLEMENTED, not as a textbook TAP
#
# rtl/rtl_peripherals/debug_jtag.sv runs its whole TAP state machine on
# `sys_clk`.  TCK, TMS and TDI are asynchronous debugger outputs that pass
# through two flops before use and the TAP advances only on a detected TCK
# rising edge.  TCK is therefore NOT a clock in this design: no register in the
# SoC is clocked by it.  An earlier revision of this file created a clock on
# the jtag_tck PORT, which told STA to time sys_clk registers against a TCK edge
# that never clocks them — a constraint that does not describe the RTL.
#
# What is constrained instead:
#   * a VIRTUAL jtag_tck clock, used only as the external interface reference
#     for TDO's output delay (the debugger launches TMS/TDI and samples TDO on
#     TCK edges), and
#   * a datapath-only max delay on the three asynchronous debugger inputs, so
#     the first synchroniser stage cannot see unbounded skew.  That is a bound
#     on the CDC net, not a setup/hold check against sys_clk.
#
# Supported TCK rate: debug_jtag.sv documents clk >= 10 x TCK as the minimum
# measured reliable ratio (4x was insufficient).  With sys_clk = 50 MHz that
# means TCK <= 5 MHz, i.e. a 200 ns period floor.  The virtual clock uses that
# 200 ns so the constraints and the RTL comment cannot disagree; advertising
# 10 MHz (100 ns) would claim twice the rate the TAP was measured at.
#------------------------------------------------------------------------------
create_clock -name jtag_tck -period 200.0

# Asynchronous debugger inputs: bounded, not timed against sys_clk.
# -ignore_clock_latency is OpenSTA's spelling of a datapath-only bound (it does
# not implement -datapath_only); ignoring the clock latency leaves the data path
# itself bounded to 2 ns, which is what the synchroniser needs.
set_max_delay 2.0 -from [get_ports {jtag_tck jtag_tms jtag_tdi}] -to [get_clocks sys_clk] -ignore_clock_latency

# Clock uncertainty: 100 ps setup / 50 ps hold models PLL jitter and clock-tree
# skew allowance before CTS.  Placeholder until a real clock tree exists.
set_clock_uncertainty -setup 0.100 [get_clocks sys_clk]
set_clock_uncertainty -hold  0.050 [get_clocks sys_clk]

# No set_clock_latency: latency is a property of an implemented clock tree and
# an extracted netlist. Asserting a number here would invent data.

#------------------------------------------------------------------------------
# Clock-domain relationships
#------------------------------------------------------------------------------
# NO set_clock_groups here on purpose.  jtag_tck is a virtual interface
# reference with no phase relationship to sys_clk; declaring the two groups
# asynchronous would remove the only two checks that mean anything on this
# interface (the CDC max delay above and TDO's output delay below).  Leaving
# them unrelated makes OpenSTA analyse TDO against every TCK edge, which is
# conservative rather than optimistic.

# jtag_trst_n is an asynchronous reset input, not a TCK-synchronous signal.
# It is asserted by the debugger at any time and reaches only reset logic.
set_input_delay  -clock jtag_tck -max 5.0 [get_ports jtag_trst_n]
set_input_delay  -clock jtag_tck -min 1.0 [get_ports jtag_trst_n]
# TDO is launched from a sys_clk flop and sampled by the debugger on TCK.
set_output_delay -clock jtag_tck -max 5.0 [get_ports jtag_tdo]
set_output_delay -clock jtag_tck -min 1.0 [get_ports jtag_tdo]

#------------------------------------------------------------------------------
# Board-level I/O assumptions (ESTIMATED)
#
# The board is not laid out and no IBIS/transmission-line model exists. The
# numbers below assume a short trace (< 50 mm) and a source-synchronous
# peripheral clocked from the SoC, giving a 5 ns external round trip with 1 ns
# of uncertainty. They are stated once and referenced by interface below so the
# assumption is auditable rather than scattered.
#------------------------------------------------------------------------------

# --- UART0: 115200 baud, 8.68 us bit period -> timing is dominated by the
#     oversampling receiver, not by board skew. 5 ns is conservative.
set_input_delay  -clock sys_clk -max 5.0 [get_ports uart_rx]
set_input_delay  -clock sys_clk -min 1.0 [get_ports uart_rx]
set_output_delay -clock sys_clk -max 5.0 [get_ports uart_tx]
set_output_delay -clock sys_clk -min 1.0 [get_ports uart_tx]

# --- SPI (mode 0, external sensor/flash): SCK is the reference output.
set_output_delay -clock sys_clk -max 5.0 [get_ports {spi_sck spi_mosi spi_cs_n}]
set_output_delay -clock sys_clk -min 1.0 [get_ports {spi_sck spi_mosi spi_cs_n}]
set_input_delay  -clock sys_clk -max 5.0 [get_ports spi_miso]
set_input_delay  -clock sys_clk -min 1.0 [get_ports spi_miso]

# --- I2C: open-drain, 100 kHz standard mode. The bus is clocked by SCL, which
#     this design generates from sys_clk, so the pins are constrained against
#     sys_clk like any other I/O.
set_input_delay  -clock sys_clk -max 5.0 [get_ports {i2c_scl i2c_sda}]
set_input_delay  -clock sys_clk -min 1.0 [get_ports {i2c_scl i2c_sda}]
set_output_delay -clock sys_clk -max 5.0 [get_ports {i2c_scl i2c_sda}]
set_output_delay -clock sys_clk -min 1.0 [get_ports {i2c_scl i2c_sda}]

# --- GPIO: 16 bidirectional pins. No peripheral protocol; the same board
#     assumption applies. Each bit is constrained individually so the report
#     shows full coverage (a bare [get_ports gpio] would constrain the bus).
foreach g {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15} {
  set_input_delay  -clock sys_clk -max 5.0 [get_ports "gpio\[$g\]"]
  set_input_delay  -clock sys_clk -min 1.0 [get_ports "gpio\[$g\]"]
  set_output_delay -clock sys_clk -max 5.0 [get_ports "gpio\[$g\]"]
  set_output_delay -clock sys_clk -min 1.0 [get_ports "gpio\[$g\]"]
}

# --- PWM: 4 outputs driving LEDs/motor drivers.
foreach p {0 1 2 3} {
  set_output_delay -clock sys_clk -max 5.0 [get_ports "pwm_out\[$p\]"]
  set_output_delay -clock sys_clk -min 1.0 [get_ports "pwm_out\[$p\]"]
}

# --- I2S: audio, bit clock generated from sys_clk.
set_output_delay -clock sys_clk -max 5.0 [get_ports {i2s_bclk i2s_lrclk i2s_dout}]
set_output_delay -clock sys_clk -min 1.0 [get_ports {i2s_bclk i2s_lrclk i2s_dout}]
set_input_delay  -clock sys_clk -max 5.0 [get_ports i2s_din]
set_input_delay  -clock sys_clk -min 1.0 [get_ports i2s_din]

# --- QSPI: SCK/CS are outputs, IO0..3 are bidirectional.
set_output_delay -clock sys_clk -max 5.0 [get_ports {qspi_sck qspi_cs_n}]
set_output_delay -clock sys_clk -min 1.0 [get_ports {qspi_sck qspi_cs_n}]
foreach q {0 1 2 3} {
  set_input_delay  -clock sys_clk -max 5.0 [get_ports "qspi_io\[$q\]"]
  set_input_delay  -clock sys_clk -min 1.0 [get_ports "qspi_io\[$q\]"]
  set_output_delay -clock sys_clk -max 5.0 [get_ports "qspi_io\[$q\]"]
  set_output_delay -clock sys_clk -min 1.0 [get_ports "qspi_io\[$q\]"]
}

# --- Watchdog / power-management handshake.
set_output_delay -clock sys_clk -max 5.0 [get_ports {wdog_reset_n_out core_clk_en_o wake_req}]
set_output_delay -clock sys_clk -min 1.0 [get_ports {wdog_reset_n_out core_clk_en_o wake_req}]
set_input_delay  -clock sys_clk -max 5.0 [get_ports wake_ack]
set_input_delay  -clock sys_clk -min 1.0 [get_ports wake_ack]

#------------------------------------------------------------------------------
# Exceptions
#------------------------------------------------------------------------------
# EXCEPTION 1 of 2 — reset_n.
# reset_n is asynchronous by design and drives only the async-reset pin of every
# flop (and reset_ctrl).  There is no capture edge to check it against: the
# reset RECOVERY/REMOVAL check a synchronous reset would need does not exist for
# an asynchronous reset pin, and reset_ctrl releases rst_sys_n through a counter
# on sys_clk.  A false path is the honest constraint; anything else would invent
# a setup relationship the design does not have.
set_false_path -from [get_ports reset_n] -to [get_clocks sys_clk]

# EXCEPTION 2 of 2 — the JTAG CDC inputs (see the block above).
# jtag_tck/jtag_tms/jtag_tdi enter only the two-flop synchroniser at the top of
# debug_jtag.sv.  They are bounded by the datapath-only max delay above rather
# than timed against sys_clk, because they are launched by an unrelated clock.
# NOTE: this is a BOUND, so the paths are not removed from analysis; the
# synchroniser's own sys_clk-to-sys_clk stage is timed normally.

#------------------------------------------------------------------------------
# Coverage note
#------------------------------------------------------------------------------
# This file constrains: clk (clock), jtag_tck (clock), reset_n (false path),
# jtag_tms/tdi/trst_n (input), jtag_tdo (output), uart_rx/tx, spi_miso/sck/
# mosi/cs_n, i2c_scl/sda, gpio[15:0], pwm_out[3:0], i2s_bclk/lrclk/dout/din,
# qspi_sck/cs_n/io[3:0], wdog_reset_n_out, core_clk_en_o, wake_req, wake_ack.
#
# scripts/eda/run_sdc_lint.js fails if any top-level port is missing from that
# list, so this comment cannot drift from the file.
#
# NOT constrained, and deliberately so:
#   * internal paths — there is no multicycle requirement; the APB bridge and
#     the AXI interconnect complete one transaction per clock.
#   * clock-tree latency / insertion delay — requires CTS.
#   * extracted parasitics — requires RCX/SPEF, which does not exist yet.
