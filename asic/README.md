# Home-Automation-SoC — ASIC Physical Design
# Stage 6 ASIC

## PDK Status: BLOCKED
- No SkyWater 130nm PDK installed on disk
- volare (PDK version manager) not installed
- OpenLane / OpenROAD not installed
- OpenSTA build failed (CUDD make failed)

## Recommended Flow (when PDK available)
1. Install SkyWater 130nm PDK via volare:
   ```
   volare add sky130
   volare pin sky130
   ```
2. Install OpenLane 2:
   ```
   pip install openlane2  # or build from source
   ```
3. Run synthesis + P&R:
   ```
   openlane2 flow.tcl -design has_soc -pdk sky130A
   ```

## Gaps (documented honestly)
- **DFT/ATPG**: No open-source scan chain insertion or ATPG tool. Commercial tool required for production test.
- **IR-drop/EM sign-off**: No open-source power grid sign-off. RedHawk or equivalent required.
- **DRC/LVS sign-off**: Magic/Netgen available for MPW shuttle; Calibre required for production.
- **PLL**: No sky130-qualified open PLL IP. External clock generator (e.g., Si5351) recommended.

## Status: BLOCKED (no PDK, no OpenROAD/OpenLane installed)
