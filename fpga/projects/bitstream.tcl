#------------------------------------------------------------------------------
# Home-Automation-SoC — Vivado Bitstream Generation Script
# Usage: vivado -mode batch -source bitstream.tcl
# Prerequisites: implementation must have been run first
#------------------------------------------------------------------------------

set PROJECT_NAME    has_soc
set PROJECT_DIR     ./projects/has_soc_vivado

open_project $PROJECT_DIR/$PROJECT_NAME.xpr

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set STATUS [get_property status [get_runs impl_1]]
if {$STATUS != "COMPLETED"} {
    puts "ERROR: Bitstream generation failed (status: $STATUS)"
    exit 1
}

export_hw -hw ./projects/has_soc_vivado/has_soc.hw -force

puts "Bitstream: $PROJECT_DIR/has_soc.runs/impl_1/has_soc.bit"
puts "Hardware:  $PROJECT_DIR/has_soc.hw"
puts "Bitstream generation complete."
