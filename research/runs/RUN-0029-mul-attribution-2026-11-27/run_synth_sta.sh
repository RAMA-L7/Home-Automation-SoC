#!/usr/bin/env bash
# RUN-0029 — attribution experiment: map a core variant with the project's
# exact synthesis template and run the same OpenSTA gate on it.
#
#   bash run_synth_sta.sh <rtl/rtl_top/riscv_core variant> <tag>
#
# Everything else is byte-identical to `node scripts/eda/run_sta.js`:
# rtl/filelist.f order, scripts/sta/synth_has_soc.ys with the same liberty and
# ABC line, the same `wire signed` strip, the same SDC, liberty set and OpenSTA
# invocation. The variant file only ever exists under this run directory; no
# tracked RTL is modified.
set -u

CORE=${1:?usage: run_synth_sta.sh <core variant> <tag>}
TAG=${2:?usage: run_synth_sta.sh <core variant> <tag>}

R=/d/Home-Automation-SoC
RV=/mnt/d/Home-Automation-SoC/research/runs/RUN-0029-mul-attribution-2026-11-27
OUT=$R/research/runs/RUN-0029-mul-attribution-2026-11-27/logs
mkdir -p "$OUT"

SKY130_COMMIT=0fe599b2afb6708d281543108caf8310912f54af
WINPDK="//wsl\$/Ubuntu-24.04/root/.volare/volare/sky130/versions/$SKY130_COMMIT/sky130A"
PDK="/root/.volare/volare/sky130/versions/$SKY130_COMMIT/sky130A"
WINLIB="$WINPDK/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

NETLIST="build/sta/has_soc_gate_${TAG}.v"
YS="research/runs/RUN-0029-mul-attribution-2026-11-27/logs/synth_${TAG}.ys"

cd "$R" || exit 1

# RTL list in filelist.f order with the core replaced by the variant.
RTL=$(grep -v '^[[:space:]]*//' rtl/filelist.f | grep -v '^[[:space:]]*$' |
      sed "s|^rtl/rtl_top/riscv_core.sv$|$CORE|" | tr '\n' ' ')

sed -e "s|@RTL@|read_verilog -sv -Irtl/rtl_top $RTL|" \
    -e "s|@LIBERTY@|$WINLIB|g" \
    -e "s|@NETLIST@|$NETLIST|" \
    scripts/sta/synth_has_soc.ys > "$YS"

export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"

echo "tag=$TAG"
echo "core=$CORE sha256=$(sha256sum "$CORE" | cut -d' ' -f1)"
echo "core_diff_vs_tracked=$(diff <(cat rtl/rtl_top/riscv_core.sv) <(cat "$CORE") | grep -c '^[<>]')"
echo "ys_sha256=$(sha256sum "$YS" | cut -d' ' -f1)"
echo "sdc_sha256=$(sha256sum constraints/timing_constraints/has_soc.sdc | cut -d' ' -f1)"
echo "start_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

yosys -s "$YS" > "research/runs/RUN-0029-mul-attribution-2026-11-27/logs/synth_${TAG}.log" 2>&1
echo "synth_exit=$?"
[ -f "$NETLIST" ] || { echo "no netlist"; exit 1; }

# Same post-processing as run_sta.js: OpenSTA rejects `wire signed`.
/d/tools/venv/Scripts/python.exe - "$NETLIST" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding='utf8', errors='replace').read()
open(p, 'w', encoding='utf8', newline='\n').write(
    re.sub(r'\b(wire|reg|input|output|inout)\s+signed\b', r'\1', s))
PY

UNMAPPED=$(grep -cE '^[[:space:]]+\\?\$[A-Za-z_][A-Za-z0-9_]*[[:space:]]' "$NETLIST" || true)
echo "unmapped_cells=$UNMAPPED"
echo "netlist=$(sha256sum "$NETLIST" | cut -d' ' -f1)"

# OpenSTA is a Linux ELF inside WSL, so the timing half runs there.
MSYS_NO_PATHCONV=1 wsl bash /mnt/d/Home-Automation-SoC/research/runs/RUN-0029-mul-attribution-2026-11-27/sta_only.sh "$TAG"
echo "end_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
