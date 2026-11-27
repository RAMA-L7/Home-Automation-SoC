#==============================================================================
# has_soc_path_analysis.tcl — enumerate violating paths for timing closure
#
# scripts/sta/has_soc_sta.tcl answers "does the design meet 20 ns?" and prints
# the three worst paths.  That is enough to gate a release, but not enough to
# rank bottlenecks: WNS is one path, while TNS is the sum over every failing
# endpoint.  This script keeps the same libraries/netlist/SDC and reports the
# wider picture used to decide what to optimise:
#
#   * the top N setup paths in one-line "end" form, so they can be clustered
#     by startpoint/endpoint outside STA (scripts/eda/analyze_paths.js);
#   * the same for hold, and for unconstrained paths (constraint gaps);
#   * design-rule violations (max slew / max cap / max fanout), which show
#     whether a failing path is logic depth or an over-loaded net;
#   * the per-clock-group WNS/TNS.
#
# It changes nothing and adds no exception: it is a report over the same
# analysis the release gate runs.
#
# ENVIRONMENT
#   STA_LIBERTY  ';'-separated liberty files (std cells first, then macros)
#   STA_NETLIST  gate-level netlist written by Yosys
#   STA_SDC      constraint file
#   STA_TOP      top module name (default: has_soc)
#   STA_PATHS    how many paths to enumerate per report (default: 500)
#   STA_OUT      directory for the reports (default: build/sta)
#==============================================================================

set top has_soc
if {[info exists ::env(STA_TOP)] && $::env(STA_TOP) ne ""} {
  set top $::env(STA_TOP)
}
foreach var {STA_LIBERTY STA_NETLIST STA_SDC} {
  if {![info exists ::env($var)]} {
    error "missing environment variable $var"
  }
}
set npaths 500
if {[info exists ::env(STA_PATHS)] && $::env(STA_PATHS) ne ""} {
  set npaths $::env(STA_PATHS)
}
set outdir build/sta
if {[info exists ::env(STA_OUT)] && $::env(STA_OUT) ne ""} {
  set outdir $::env(STA_OUT)
}
file mkdir $outdir

foreach lib [split $::env(STA_LIBERTY) ";"] {
  set lib [string trim $lib]
  if {$lib eq ""} { continue }
  read_liberty $lib
}
read_verilog $::env(STA_NETLIST)
link_design $top
read_sdc $::env(STA_SDC)

puts "ANALYSIS-CLOCKS=[llength [all_clocks]]"
puts "ANALYSIS-REGISTERS=[llength [all_registers -cells]]"
report_wns
report_tns

#------------------------------------------------------------------------------
# Enumerated paths.  "end" format is one line per path: the exact text shape is
# stable and is parsed by scripts/eda/analyze_paths.js.
#------------------------------------------------------------------------------
puts "ANALYSIS: writing $npaths setup paths to $outdir/paths_setup.rpt"
report_checks -path_delay max -sort_by_slack -group_path_count $npaths \
  -endpoint_path_count 1 -unique_paths_to_endpoint -format end -digits 4 \
  > $outdir/paths_setup.rpt

# Structured form of the worst paths: includes both startpoint and endpoint,
# which the one-line "end" format omits and clustering needs.
puts "ANALYSIS: writing top 50 setup paths (json) to $outdir/paths_setup_top50.json"
report_checks -path_delay max -sort_by_slack -group_path_count 50 \
  -endpoint_path_count 1 -unique_paths_to_endpoint -format json -digits 4 \
  > $outdir/paths_setup_top50.json

puts "ANALYSIS: writing $npaths hold paths to $outdir/paths_hold.rpt"
report_checks -path_delay min -sort_by_slack -group_path_count $npaths \
  -endpoint_path_count 1 -unique_paths_to_endpoint -format end -digits 4 \
  > $outdir/paths_hold.rpt

puts "ANALYSIS: writing unconstrained paths to $outdir/paths_unconstrained.rpt"
report_checks -path_delay max -unconstrained -format end -digits 4 \
  > $outdir/paths_unconstrained.rpt

#------------------------------------------------------------------------------
# Design-rule checks: these separate "too much logic" from "one net is too big".
#------------------------------------------------------------------------------
puts "ANALYSIS: writing design-rule violations to $outdir/design_rules.rpt"
report_check_types -violators -max_slew -max_capacitance -max_fanout \
  > $outdir/design_rules.rpt

puts "ANALYSIS-DONE"
