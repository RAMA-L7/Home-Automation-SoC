#!/usr/bin/env bash
set -u
R=/mnt/d/Home-Automation-SoC
P=/root/.volare/volare/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A
export LD_LIBRARY_PATH=/mnt/d/tools/opensta/lib
export STA_LIBERTY="$P/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib;$P/libs.ref/sky130_sram_macros/lib/sky130_sram_2kbyte_1rw1r_32x512_8_TT_1p8V_25C.lib;$P/libs.ref/sky130_sram_macros/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
export STA_NETLIST=$R/build/sta/has_soc_gate_stripped.v
/mnt/d/tools/opensta/bin/sta -no_splash -no_init -exit "$R/research/runs/RUN-0029-mul-attribution-2026-11-27/logs/net_probe.tcl"
