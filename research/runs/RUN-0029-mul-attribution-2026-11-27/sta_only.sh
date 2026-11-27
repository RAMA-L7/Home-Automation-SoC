#!/usr/bin/env bash
# RUN-0029 — WSL side: run the project's STA gate on an ablation netlist.
#   wsl bash sta_only.sh <tag>
set -u
TAG=${1:?usage: sta_only.sh <tag>}

R=/mnt/d/Home-Automation-SoC
LOGS=$R/research/runs/RUN-0029-mul-attribution-2026-11-27/logs
CORE_COMMIT=0fe599b2afb6708d281543108caf8310912f54af
PDK=/root/.volare/volare/sky130/versions/$CORE_COMMIT/sky130A

export LD_LIBRARY_PATH=/mnt/d/tools/opensta/lib
export STA_LIBERTY="$PDK/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
STA_LIBERTY="$STA_LIBERTY;$PDK/libs.ref/sky130_sram_macros/lib/sky130_sram_2kbyte_1rw1r_32x512_8_TT_1p8V_25C.lib"
STA_LIBERTY="$STA_LIBERTY;$PDK/libs.ref/sky130_sram_macros/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
export STA_LIBERTY
export STA_NETLIST="$R/build/sta/has_soc_gate_${TAG}.v"
export STA_SDC="$R/constraints/timing_constraints/has_soc.sdc"
export STA_TOP=has_soc

/mnt/d/tools/opensta/bin/sta -no_splash -no_init -exit \
  "$R/scripts/sta/has_soc_sta.tcl" > "$LOGS/sta_${TAG}.log" 2>&1
echo "sta_exit=$?"
grep -E "sta: (clocks|WNS|TNS|RESULT)|STA-WNS-SETUP|STA-TNS-SETUP|slack \(VIOLATED\)" "$LOGS/sta_${TAG}.log" | head -20
