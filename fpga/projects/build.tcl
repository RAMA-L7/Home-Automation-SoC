#------------------------------------------------------------------------------
# Home-Automation-SoC — Vivado Build Script
# Stage 5 FPGA
# Target: Digilent Nexys A7-100T (Artix-7 XC7A100TCSG324-1)
#
# Usage (when Vivado is installed):
#   vivado -mode batch -source build.tcl
#
# This script:
#   1. Creates a Vivado project
#   2. Adds all RTL source files
#   3. Adds XDC constraints
#   4. Runs synthesis
#   5. Runs implementation
#   6. Generates bitstream
#   7. Reports timing and utilization
#------------------------------------------------------------------------------

# Project settings
set PROJECT_NAME    has_soc
set PROJECT_DIR     ./projects/has_soc_vivado
set PART            xc7a100tcsg324-1
set TOP_MODULE      has_soc
set XDC_FILE        ../../fpga/constraints/nexys_a7.xdc
set SDC_FILE        ../../constraints/timing_constraints/has_soc.sdc

# RTL source directories
set RTL_TOP_DIR     ../../rtl/rtl_top
set RTL_PERIPH_DIR  ../../rtl/rtl_peripherals

#------------------------------------------------------------------------------
# Step 1: Create project
#------------------------------------------------------------------------------
create_project $PROJECT_NAME $PROJECT_DIR -part $PART -force
set_property top $TOP_MODULE [current_project]

#------------------------------------------------------------------------------
# Step 2: Add RTL source files
#------------------------------------------------------------------------------
# Top-level and SoC integration
add_files -norecurse $RTL_TOP_DIR/has_soc.sv
add_files -norecurse $RTL_TOP_DIR/has_addr_map.sv
add_files -norecurse $RTL_TOP_DIR/boot_rom.sv
add_files -norecurse $RTL_TOP_DIR/sram.sv
add_files -norecurse $RTL_TOP_DIR/axi_lite_interconnect.sv
add_files -norecurse $RTL_TOP_DIR/axi_lite_to_apb.sv
add_files -norecurse $RTL_TOP_DIR/req_gnt_to_axi_lite.sv
add_files -norecurse $RTL_TOP_DIR/riscv_core.sv
add_files -norecurse $RTL_TOP_DIR/intc_axi.sv

# Peripherals
add_files -norecurse $RTL_PERIPH_DIR/gpio.sv
add_files -norecurse $RTL_PERIPH_DIR/uart.sv
add_files -norecurse $RTL_PERIPH_DIR/timer.sv
add_files -norecurse $RTL_PERIPH_DIR/watchdog.sv
add_files -norecurse $RTL_PERIPH_DIR/pwm.sv
add_files -norecurse $RTL_PERIPH_DIR/i2c_ctrl.sv
add_files -norecurse $RTL_PERIPH_DIR/spi_ctrl.sv
add_files -norecurse $RTL_PERIPH_DIR/i2s.sv
add_files -norecurse $RTL_PERIPH_DIR/qspi_flash_ctrl.sv
add_files -norecurse $RTL_PERIPH_DIR/clint.sv
add_files -norecurse $RTL_PERIPH_DIR/plic.sv
add_files -norecurse $RTL_PERIPH_DIR/power_mgr.sv
add_files -norecurse $RTL_PERIPH_DIR/power_mgr_regs.sv
add_files -norecurse $RTL_PERIPH_DIR/debug_jtag.sv

#------------------------------------------------------------------------------
# Step 3: Add constraints
#------------------------------------------------------------------------------
add_files $XDC_FILE

#------------------------------------------------------------------------------
# Step 4: Synthesis settings
#------------------------------------------------------------------------------
set_property general.max_threads 4 [current_project]
set_property strategy Vivado Synthesis Defaults [get_runs synth_1]

#------------------------------------------------------------------------------
# Step 5: Run synthesis
#------------------------------------------------------------------------------
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis status
set SYNTH_STATUS [get_property status [get_runs synth_1]]
if {$SYNTH_STATUS != "COMPLETED"} {
    puts "ERROR: Synthesis did not complete (status: $SYNTH_STATUS)"
    exit 1
}
puts "INFO: Synthesis completed successfully"

# Synthesis reports
report_utilization -file ./projects/has_soc_vivado/reports/synth_utilization.txt
report_timing -file ./projects/has_soc_vivado/reports/synth_timing.txt

#------------------------------------------------------------------------------
# Step 6: Implementation settings
#------------------------------------------------------------------------------
set_property strategy Vivado Implementation Defaults [get_runs impl_1]
set_property phys_opt_design post_place_phys_opt_design [get_runs impl_1]

#------------------------------------------------------------------------------
# Step 7: Run implementation
#------------------------------------------------------------------------------
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check implementation status
set IMPL_STATUS [get_property status [get_runs impl_1]]
if {$IMPL_STATUS != "COMPLETED"} {
    puts "ERROR: Implementation did not complete (status: $IMPL_STATUS)"
    exit 1
}
puts "INFO: Implementation completed successfully"

# Implementation reports
report_utilization -file ./projects/has_soc_vivado/reports/impl_utilization.txt
report_timing -file ./projects/has_soc_vivado/reports/impl_timing.txt
report_clock_networks -file ./projects/has_soc_vivado/reports/clock_networks.txt

#------------------------------------------------------------------------------
# Step 8: Generate bitstream
#------------------------------------------------------------------------------
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set BITSTREAM_STATUS [get_property status [get_runs impl_1]]
if {$BITSTREAM_STATUS != "COMPLETED"} {
    puts "ERROR: Bitstream generation did not complete (status: $BITSTREAM_STATUS)"
    exit 1
}
puts "INFO: Bitstream generated successfully"

#------------------------------------------------------------------------------
# Step 9: Export hardware definition for SDK/Vitis
#------------------------------------------------------------------------------
export_hw -hw ./projects/has_soc_vivado/has_soc.hw -force
puts "INFO: Hardware definition exported to has_soc.hw"

#------------------------------------------------------------------------------
# Step 10: Final summary
#------------------------------------------------------------------------------
puts "========================================"
puts "  Build Complete!"
puts "  Project: $PROJECT_NAME"
puts "  Part: $PART"
puts "  Top Module: $TOP_MODULE"
puts "  Bitstream: $PROJECT_DIR/has_soc.runs/impl_1/has_soc.bit"
puts "  Hardware: $PROJECT_DIR/has_soc.hw"
puts "========================================"
