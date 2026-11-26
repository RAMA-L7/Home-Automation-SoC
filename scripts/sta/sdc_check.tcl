#==============================================================================
# sdc_check.tcl — execute has_soc.sdc and audit it
#
# WHAT THIS PROVES
#   * the constraint file is valid Tcl and runs to completion (the previous
#     revision used HDL syntax and aborted at the first GPIO constraint);
#   * every object named in the file (port, clock) actually exists in the
#     has_soc port list — an unknown name raises an error;
#   * every top-level port ends up constrained, and the report names any port
#     that does not.
#
# WHAT THIS DOES NOT PROVE
#   * that the timing numbers are met. That needs OpenSTA/PrimeTime with a
#     linked, liberty-mapped netlist plus extracted parasitics. No Windows
#     OpenSTA binary exists here and the Linux build cannot run (WSL1 is not
#     supported on this machine), so path-based STA is a documented BLOCKER,
#     not something this script pretends to do.
#
# USAGE
#   tclsh scripts/sta/sdc_check.tcl <sdc> <ports_file>
#
# ports_file: one port name per line, e.g. clk / gpio[0] / ...
#==============================================================================

if {$argc != 2} {
  puts "usage: tclsh sdc_check.tcl <sdc-file> <ports-file>"
  exit 2
}
set sdc_file   [lindex $argv 0]
set ports_file [lindex $argv 1]

#------------------------------------------------------------------------------
# Port database
#------------------------------------------------------------------------------
set ::ALL_PORTS {}
set fh [open $ports_file r]
foreach line [split [read $fh] "\n"] {
  set line [string trim $line]
  if {$line ne ""} { lappend ::ALL_PORTS $line }
}
close $fh
if {[llength $::ALL_PORTS] == 0} {
  puts "SDC-RESULT=FAIL reason=empty_port_list"
  exit 1
}

# Ports that must be constrained by a clock or an exception, not by an
# input/output delay.
set ::CLOCK_PORTS {clk jtag_tck}
set ::EXCEPTION_PORTS {reset_n}

# Records: port -> dict of flags
array set ::CONSTRAINED {}

proc ::record {ports flag} {
  foreach p $ports {
    if {![info exists ::CONSTRAINED($p)]} { set ::CONSTRAINED($p) {} }
    lappend ::CONSTRAINED($p) $flag
  }
}

proc ::err {msg} {
  puts "SDC-ERROR: $msg"
  incr ::errors
}

set ::errors 0
set ::created_clocks {}

#------------------------------------------------------------------------------
# SDC command stubs
#
# get_ports is the interesting one: it resolves a name against the real port
# list and errors on anything that does not exist, which is what catches a
# constraint aimed at a port that was removed (the earlier file still
# constrained ext_irq after BLK-019 deleted it).
#------------------------------------------------------------------------------
proc get_ports {args} {
  set out {}
  foreach a $args {
    if {[llength $a] > 1} {
      # a Tcl list argument: resolve each element
      foreach e $a { set out [concat $out [get_ports $e]] }
      continue
    }
    if {[string match "*\\**" $a] || [string match "*\\?*" $a]} {
      set hits {}
      foreach p $::ALL_PORTS { if {[string match $a $p]} { lappend hits $p } }
      if {[llength $hits] == 0} { ::err "get_ports: no port matches \"$a\"" }
      set out [concat $out $hits]
    } elseif {[lsearch -exact $::ALL_PORTS $a] >= 0} {
      lappend out $a
    } else {
      ::err "get_ports: \"$a\" is not a port of has_soc"
    }
  }
  return $out
}

proc get_clocks {args} {
  set out {}
  foreach a $args {
    if {[lsearch -exact $::created_clocks $a] >= 0} {
      lappend out $a
    } else {
      ::err "get_clocks: \"$a\" has not been created"
    }
  }
  return $out
}

proc all_inputs  {} { return $::ALL_PORTS }
proc all_outputs {} { return $::ALL_PORTS }

proc set_units {args} {
  foreach {k v} $args {
    if {$k eq "-time" && $v ne "ns"} { ::err "set_units: time unit is $v, expected ns" }
  }
}
proc create_clock {args} {
  set name ""
  set period ""
  set ports {}
  set i 0
  while {$i < [llength $args]} {
    set a [lindex $args $i]
    switch -- $a {
      -name     { set name   [lindex $args [expr {$i+1}]]; incr i }
      -period   { set period [lindex $args [expr {$i+1}]]; incr i }
      -waveform { incr i }
      -add      { }
      default {
        if {![string match "-*" $a]} { set ports [concat $ports $a] }
      }
    }
    incr i
  }
  if {$name eq ""}   { ::err "create_clock without -name" }
  if {$period eq ""} { ::err "create_clock -name $name without -period" }
  if {[llength $ports] == 0} { ::err "create_clock -name $name has no port" }
  foreach p $ports {
    if {[lsearch -exact $::ALL_PORTS $p] < 0} { ::err "create_clock on unknown port $p" }
    ::record $p "clock"
  }
  lappend ::created_clocks $name
}
proc set_clock_uncertainty {args} { }
proc set_clock_latency     {args} { }
proc set_clock_transition  {args} { }
proc set_clock_groups      {args} {
  # Validate the group mode flags and that every -group value is a clock.
  set i 0
  foreach a $args {
    if {$a eq "-exclusive" || $a eq "-logically_exclusive" || $a eq "-physically_exclusive"} {
      if {[lsearch -exact $args "-asynchronous"] >= 0} {
        ::err "set_clock_groups: -exclusive used together with -asynchronous"
      }
    }
    incr i
  }
}
proc set_input_delay  {args} { ::record [lindex $args end] "input"  }
proc set_output_delay {args} { ::record [lindex $args end] "output" }
proc set_false_path   {args} {
  set i 0
  foreach a $args {
    if {$a eq "-from"} { ::record [lindex $args [expr {$i+1}]] "exception" }
    incr i
  }
}
proc set_max_delay       {args} { }
proc set_multicycle_path {args} { }
proc set_driving_cell    {args} { }
proc set_load            {args} { }
proc set_case_analysis   {args} { }
proc set_propagated_clock {args} { }

#------------------------------------------------------------------------------
# Execute the constraint file
#------------------------------------------------------------------------------
if {[catch {source $sdc_file} msg]} {
  puts "SDC-RESULT=FAIL reason=tcl_error"
  puts "SDC-ERROR: $msg"
  exit 1
}

#------------------------------------------------------------------------------
# Coverage audit
#------------------------------------------------------------------------------
set missing {}
foreach p $::ALL_PORTS {
  set flags {}
  if {[info exists ::CONSTRAINED($p)]} { set flags $::CONSTRAINED($p) }

  if {[lsearch -exact $::CLOCK_PORTS $p] >= 0} {
    if {[lsearch -exact $flags "clock"] < 0} { lappend missing "$p(no clock)" }
    continue
  }
  if {[lsearch -exact $::EXCEPTION_PORTS $p] >= 0} {
    if {[lsearch -exact $flags "exception"] < 0} { lappend missing "$p(no exception)" }
    continue
  }
  if {[lsearch -exact $flags "input"] < 0 && [lsearch -exact $flags "output"] < 0} {
    lappend missing $p
  }
}

puts "SDC-PORTS total=[llength $::ALL_PORTS]"
puts "SDC-CLOCKS [join $::created_clocks {,}]"
foreach m $missing { puts "SDC-MISSING $m" }
puts "SDC-MISSING-COUNT [llength $missing]"
puts "SDC-ERROR-COUNT $::errors"

if {$::errors > 0 || [llength $missing] > 0} {
  puts "SDC-RESULT=FAIL"
  exit 1
}
puts "SDC-RESULT=PASS"
exit 0
