foreach var {STA_LIBERTY STA_NETLIST} {
  if {![info exists ::env($var)]} { puts "missing $var"; exit 2 }
}
foreach lib [split $::env(STA_LIBERTY) ";"] { read_liberty $lib }
read_verilog $::env(STA_NETLIST)
link_design has_soc

set net [get_nets -of_objects [get_pins _76320_/X]]
set pins [get_pins -quiet -of_objects $net]
puts "pins_on_net=[llength $pins]"
foreach p [lrange $pins 0 12] { puts "   $p" }
set drv [get_nets -quiet -of_objects [get_pins _76319_/X]]
puts "pins_on_76319_X_net=[llength [get_pins -quiet -of_objects $drv]]"
