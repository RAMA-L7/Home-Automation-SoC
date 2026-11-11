#!/bin/bash
#------------------------------------------------------------------------------
# Home-Automation-SoC — ASIC Flow Runner
# Stage 6 ASIC
#
# Usage: ./run_asic.sh
#
# Prerequisites (NOT installed in this environment):
#   - OpenLane 2 (pip install openlane2 or build from source)
#   - SkyWater 130nm PDK (volare add sky130)
#   - Python with working SSL (for pip)
#
# Status: BLOCKED — OpenLane 2 not installed, Python SSL broken
#------------------------------------------------------------------------------

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "========================================"
echo "  Home-Automation-SoC ASIC Flow"
echo "  Project Root: $PROJECT_ROOT"
echo "========================================"

# Check for OpenLane 2
if ! command -v openlane2 &> /dev/null; then
    echo "ERROR: openlane2 not found in PATH"
    echo "Install with: pip install openlane2"
    echo "Or build from source: https://github.com/The-OpenROAD-Project/OpenLane"
    exit 1
fi

# Check for PDK
if [ ! -d "/tools/pdk/skywater-pdk-main" ]; then
    echo "ERROR: SkyWater 130nm PDK not found at /tools/pdk/skywater-pdk-main"
    echo "Install with: volare add sky130"
    exit 1
fi

# Run OpenLane 2 flow
echo "INFO: Running OpenLane 2 flow..."
openlane2 flow.tcl -design has_soc -pdk sky130A

echo "========================================"
echo "  ASIC Flow Complete!"
echo "  Output files in asic/outputs/"
echo "========================================"
