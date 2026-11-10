#------------------------------------------------------------------------------
# Home-Automation-SoC — SDC Timing Constraints
# Stage 5 FPGA / Stage 6 ASIC
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Clocks
#------------------------------------------------------------------------------
# System clock: 50 MHz target (20 ns period)
create_clock -name sys_clk -period 20.000 [get_ports clk]

# Generated clocks (if PLL used)
# create_clock -name pll_clk -period 20.000 [get_pins pll/clkout]

#------------------------------------------------------------------------------
# Clock uncertainty
#------------------------------------------------------------------------------
set_clock_uncertainty -setup 0.100 [get_clocks sys_clk]
set_clock_uncertainty -hold 0.050 [get_clocks sys_clk]

#------------------------------------------------------------------------------
# Input delay constraints
#------------------------------------------------------------------------------
set_input_delay -clock sys_clk -max 5.0 [all_inputs]
set_input_delay -clock sys_clk -min 0.0 [all_inputs]

#------------------------------------------------------------------------------
# Output delay constraints
#------------------------------------------------------------------------------
set_output_delay -clock sys_clk -max 5.0 [all_outputs]
set_output_delay -clock sys_clk -min 0.0 [all_outputs]

#------------------------------------------------------------------------------
# False paths
#------------------------------------------------------------------------------
# JTAG is asynchronous to system clock
set_false_path -from [get_ports jtag_tck] -to [all_registers]
set_false_path -from [all_registers] -to [get_ports jtag_tdo]

# Reset is asynchronous
set_false_path -from [get_ports reset_n] -to [all_registers]

#------------------------------------------------------------------------------
# Max delay / setup
#------------------------------------------------------------------------------
set_max_delay -datapath_only 18.0 [all_inputs] [all_outputs]

#------------------------------------------------------------------------------
# Multicycle paths (if any)
#------------------------------------------------------------------------------
# Example: APB bridge runs at same clock, no multicycle needed
# set_multicycle_path -setup 2 -from [get_ports apb_paddr] -to [get_ports apb_pready]
