#------------------------------------------------------------------------------
# Home-Automation-SoC — Vivado Synthesis-Only Script
# Usage: vivado -mode batch -source synth.tcl
#------------------------------------------------------------------------------

set PROJECT_NAME    has_soc
set PROJECT_DIR     ./projects/has_soc_vivado
set PART            xc7a100tcsg324-1
set TOP_MODULE      has_soc
set XDC_FILE        ../../fpga/constraints/nexys_a7.xdc

set RTL_TOP_DIR     ../../rtl/rtl_top
set RTL_PERIPH_DIR  ../../rtl/rtl_peripherals

create_project $PROJECT_NAME $PROJECT_DIR -part $PART -force
set_property top $TOP_MODULE [current_project]

add_files -norecurse $RTL_TOP_DIR/has_soc.sv
add_files -norecurse $RTL_TOP_DIR/has_addr_map.sv
add_files -norecurse $RTL_TOP_DIR/boot_rom.sv
add_files -norecurse $RTL_TOP_DIR/sram.sv
add_files -norecurse $RTL_TOP_DIR/axi_lite_interconnect.sv
add_files -norecurse $RTL_TOP_DIR/axi_lite_to_apb.sv
add_files -norecurse $RTL_TOP_DIR/req_gnt_to_axi_lite.sv
add_files -norecurse $RTL_TOP_DIR/riscv_core.sv
add_files -norecurse $RTL_TOP_DIR/intc_axi.sv

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

add_files $XDC_FILE

set_property general.max_threads 4 [current_project]
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set STATUS [get_property status [get_runs synth_1]]
if {$STATUS != "COMPLETED"} {
    puts "ERROR: Synthesis failed (status: $STATUS)"
    exit 1
}

report_utilization -file ./projects/has_soc_vivado/reports/synth_utilization.txt
report_timing -file ./projects/has_soc_vivado/reports/synth_timing.txt

puts "Synthesis complete. Status: $STATUS"
