# Home-Automation-SoC — Timing Constraints (SDC)
# Stage 5 FPGA / Stage 6 ASIC

## Clock
- System clock: 50 MHz target (20 ns period)
- Source: onboard crystal / external clock generator (Si5351)

## Constraints File
- `has_soc.sdc` — clock definition, input/output delays, false paths, max delay

## Status
- Constraints written but not yet validated (no Vivado/OpenROAD available)
- 50 MHz timing target is ESTIMATED, not verified by STA

## Next Steps (when tools available)
1. Run Vivado synthesis + implementation → timing report
2. Run OpenSTA → timing verification
3. Iterate floorplan/constraints to meet timing
