#------------------------------------------------------------------------------
# Home-Automation-SoC — Vivado Implementation-Only Script
# Usage: vivado -mode batch -source impl.tcl
# Prerequisites: synthesis must have been run first
#------------------------------------------------------------------------------

set PROJECT_NAME    has_soc
set PROJECT_DIR     ./projects/has_soc_vivado

open_project $PROJECT_DIR/$PROJECT_NAME.xpr

launch_runs impl_1 -jobs 4
wait_on_run impl_1

set STATUS [get_property status [get_runs impl_1]]
if {$STATUS != "COMPLETED"} {
    puts "ERROR: Implementation failed (status: $STATUS)"
    exit 1
}

report_utilization -file ./projects/has_soc_vivado/reports/impl_utilization.txt
report_timing -file ./projects/has_soc_vivado/reports/impl_timing.txt
report_clock_networks -file ./projects/has_soc_vivado/reports/clock_networks.txt

puts "Implementation complete. Status: $STATUS"
