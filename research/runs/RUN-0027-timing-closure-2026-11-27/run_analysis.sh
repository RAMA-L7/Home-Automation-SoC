#!/usr/bin/env bash
# RUN-0027 — enumerate violating paths for a given mapped netlist.
#
#   wsl bash run_analysis.sh <netlist> <tag> [path_count]
#
# Inputs are read-only: the netlist, the SDC and the RTL are not written.
# Reports land in logs/<tag>/.
set -u

NETLIST=${1:-/mnt/d/Home-Automation-SoC/build/sta/has_soc_gate.v}
TAG=${2:-postfix}
NPATHS=${3:-3000}

PDK=/root/.volare/volare/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A
R=/mnt/d/Home-Automation-SoC
OUT=$R/research/runs/RUN-0027-timing-closure-2026-11-27/logs/$TAG
mkdir -p "$OUT"

export LD_LIBRARY_PATH=/mnt/d/tools/opensta/lib
export STA_LIBERTY="$PDK/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
STA_LIBERTY="$STA_LIBERTY;$PDK/libs.ref/sky130_sram_macros/lib/sky130_sram_2kbyte_1rw1r_32x512_8_TT_1p8V_25C.lib"
STA_LIBERTY="$STA_LIBERTY;$PDK/libs.ref/sky130_sram_macros/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
export STA_LIBERTY
export STA_NETLIST="$NETLIST"
export STA_SDC="$R/constraints/timing_constraints/has_soc.sdc"
export STA_OUT="$OUT"
export STA_PATHS="$NPATHS"

echo "start_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "tag=$TAG"
echo "netlist=$NETLIST"
echo "netlist_sha256=$(sha256sum "$NETLIST" | cut -d' ' -f1)"
echo "sdc_sha256=$(sha256sum "$STA_SDC" | cut -d' ' -f1)"
echo "sta_version=$(/mnt/d/tools/opensta/bin/sta -version 2>/dev/null | tr -d '\r')"
echo "paths=$NPATHS"
echo "out=$OUT"

/mnt/d/tools/opensta/bin/sta -no_splash -no_init -exit \
  "$R/scripts/sta/has_soc_path_analysis.tcl" > "$OUT/analysis.log" 2>&1
rc=$?
echo "exit=$rc"
echo "end_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
exit $rc
