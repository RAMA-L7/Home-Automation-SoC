#!/usr/bin/env bash
# RUN-0029 — WSL side: STA the standalone multiplier probe with the project's
# liberty set and the probe's own minimal SDC.
set -u
R=/mnt/d/Home-Automation-SoC
LOGS=$R/research/runs/RUN-0029-mul-attribution-2026-11-27/logs
CORE_COMMIT=0fe599b2afb6708d281543108caf8310912f54af
PDK=/root/.volare/volare/sky130/versions/$CORE_COMMIT/sky130A

export LD_LIBRARY_PATH=/mnt/d/tools/opensta/lib
export STA_LIBERTY="$PDK/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
export STA_NETLIST="$R/build/sta/mul_probe_gate.v"
export STA_SDC="$R/research/runs/RUN-0029-mul-attribution-2026-11-27/probe/probe.sdc"
export STA_TOP=mul_probe

/mnt/d/tools/opensta/bin/sta -no_splash -no_init -exit \
  "$R/scripts/sta/has_soc_sta.tcl" > "$LOGS/sta_probe.log" 2>&1
echo "sta_exit=$?"
grep -E "sta: (WNS|TNS|RESULT)|slack \(VIOLATED\)|slack \(MET\)" "$LOGS/sta_probe.log" | head -12
