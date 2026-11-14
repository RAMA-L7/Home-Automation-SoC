# ---------------------------------------------------------------------------
# Phase 3.8 — read-only post-CTS verification of the timer block
#
# Opens the CTS output ODB (never the baseline), and reports:
#   design stats, placement legality, unplaced instances, clock-sink coverage,
#   clock-tree topology (depth / fanout, traced through the ODB netlist),
#   routed-segment count, multi-pin/disconnected nets, and STA summaries.
#
# Writes nothing. No routing, no legalisation, no ECO.
#
# Run:
#   openroad -exit build/asic_flow/phase3_8_cts_execution/post_cts_checks.tcl
# ---------------------------------------------------------------------------

set P    "/mnt/d/tools/src/OpenROAD/test/sky130hd"
set LIB  "$P/sky130_fd_sc_hd__tt_025C_1v80.lib"
set ODB  "/mnt/d/Home-Automation-SoC/build/asic_flow/phase3_2_cts/output/timer_cts.odb"
set SDC  "/mnt/d/Home-Automation-SoC/build/asic_flow/phase3_2_cts/constraints/timer_pclk_provisional.sdc"

proc hdr {t} { puts ""; puts "--- $t ---" }

hdr "0. inputs (read-only)"
read_liberty $LIB
puts "  liberty : $LIB"
read_db $ODB
puts "  odb     : $ODB"
set block [ord::get_db_block]
set die [$block getDieArea]
puts [format "  die     : %.2f x %.2f um" [expr {([$die xMax]-[$die xMin])/1000.0}] [expr {([$die yMax]-[$die yMin])/1000.0}]]
puts "  insts   : [llength [$block getInsts]]"
puts "  nets    : [llength [$block getNets]]"
puts "  rows    : [llength [$block getRows]]"

hdr "1. placement legality and unplaced instances"
set unplaced 0
set placed 0
set other 0
foreach i [$block getInsts] {
  set st [$i getPlacementStatus]
  switch -- $st {
    PLACED { incr placed }
    UNPLACED { incr unplaced }
    default { incr other }
  }
}
puts "  PLACED   : $placed"
puts "  UNPLACED : $unplaced"
puts "  other    : $other (FIXED/LOCKED tapcells, etc.)"
if {[catch {check_placement} e]} { puts "  RESULT check_placement : FAILED ($e)" } else { puts "  RESULT check_placement : PASS (no violations)" }

hdr "2. clock buffers / inverters in the CTS database"
array set bufcount {}
foreach i [$block getInsts] {
  set mn [[$i getMaster] getName]
  if {[string match "*clkbuf*" $mn] || [string match "*clkinv*" $mn]} {
    if {[info exists bufcount($mn)]} { incr bufcount($mn) } else { set bufcount($mn) 1 }
  }
}
foreach k [lsort [array names bufcount]] { puts [format "  %-32s %d" $k $bufcount($k)] }

hdr "3. clock sinks and clock-tree topology (traced in the ODB netlist)"
proc io_type {mterm} {
  if {[catch {set t [$mterm getIoType]} e]} { return "" }
  return $t
}
proc sinks_of_net {net} {
  set out {}
  if {$net eq "NULL"} { return $out }
  foreach it [$net getITerms] {
    if {[io_type [$it getMTerm]] eq "INPUT"} { lappend out $it }
  }
  return $out
}
proc out_net_of_inst {inst} {
  foreach it [$inst getITerms] {
    if {[io_type [$it getMTerm]] eq "OUTPUT"} {
      set n [$it getNet]
      if {$n eq "NULL"} { return "" }
      return $n
    }
  }
  return ""
}
proc master_of {it} { return [[[$it getInst] getMaster] getName] }

# locate the clock net(s) named pclk
set root_net ""
foreach n [$block getNets] {
  if {[$n getName] eq "pclk"} { set root_net $n }
}
if {$root_net eq ""} {
  puts "  ERROR: no net named pclk in the CTS database"
} else {
  set total_sinks 0
  set tree_bufs 0
  set max_depth 0
  set fanouts {}
  # BFS from the root net
  set frontier [list $root_net]
  set depth 0
  set visited {}
  while {[llength $frontier] > 0 && $depth < 32} {
    set next {}
    set leafs_here 0
    foreach n $frontier {
      if {$n eq "NULL"} { continue }
      set name [$n getName]
      if {[lsearch -exact $visited $name] >= 0} { continue }
      lappend visited $name
      set sinks [sinks_of_net $n]
      set buf_fanout 0
      foreach it $sinks {
        incr total_sinks
        set mn [master_of $it]
        if {[string match "*clkbuf*" $mn] || [string match "*clkinv*" $mn]} {
          incr tree_bufs
          incr buf_fanout
          set isn [$it getInst]
          set on [out_net_of_inst $isn]
          if {$on ne ""} { lappend next $on }
        } else {
          incr leafs_here
        }
      }
      lappend fanouts $buf_fanout
    }
    if {[llength $next] > 0} { incr depth }
    set frontier $next
  }
  puts "  clock tree depth (buffer levels) : $depth"
  puts "  buffers seen on the clock tree   : $tree_bufs"
  puts "  sink pins reached                : $total_sinks (pin-endpoints, includes buffer inputs)"
  set fo_sorted [lsort -integer $fanouts]
  puts "  fanout per buffer (sorted)       : $fo_sorted"
  puts "  clock nets in the tree           : [llength $visited]"
}

# every flop CLK pin must sit on a net reached by the traversal
set flop_clk 0
set flop_clk_on_tree 0
foreach i [$block getInsts] {
  set m [$i getMaster]
  if {$m eq "NULL"} { continue }
  set hasclk 0
  catch {
    foreach mt [$m getMTerms] { if {[$mt getName] eq "CLK"} { set hasclk 1 } }
  }
  if {!$hasclk} { continue }
  if {[string match "*dfrtp*" [[$i getMaster] getName]]} { incr flop_clk }
  foreach it [$i getITerms] {
    if {[io_type [$it getMTerm]] eq "INPUT" && [[$it getMTerm] getName] eq "CLK"} {
      set n [$it getNet]
      if {$n ne "" && [lsearch -exact $visited [$n getName]] >= 0} { incr flop_clk_on_tree }
    }
  }
}
puts "  flip-flop CLK pins               : $flop_clk"
puts "  of which on a clock-tree net     : $flop_clk_on_tree"

hdr "4. routing / connectivity state"
set routed 0
set rs 0
foreach n [$block getNets] {
  if {[catch {set w [$n getWire]} e]} { continue }
  if {$w ne "NULL"} {
    incr rs
    catch {set routed [expr {$routed + [llength [$w getSWires]]}]}
  }
}
puts "  nets with any routing wire       : $rs"
puts "  total routed segments            : $routed  (expect 0: no routing in this phase)"

set one_pin 0
set zero_pin 0
foreach n [$block getNets] {
  set cnt [expr {[llength [$n getITerms]] + [llength [$n getBTerms]]}]
  if {$cnt == 1} { incr one_pin }
  if {$cnt == 0} { incr zero_pin }
}
puts "  nets with 1 pin (dangling)      : $one_pin"
puts "  nets with 0 pins                : $zero_pin"

hdr "5. timing (block-level, no I/O budgets, pre-route estimates)"
read_sdc $SDC
puts "  clock: [get_clocks *]  period: [get_property [get_clocks pclk] period] ns"
puts "  --- clock skew ---"
report_clock_skew -digits 3
puts "  --- worst setup / hold (summary) ---"
report_checks -path_delay min_max -format summary -digits 3
puts "  --- check_setup (expected gaps) ---"
catch {check_setup} e
if {[info exists e] && $e ne ""} { puts "  check_setup: $e" }

puts ""
puts "POST_CTS_CHECKS : COMPLETE (read-only; no writes)"
exit 0
