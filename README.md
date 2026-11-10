# Home-Automation-SoC

## Project Objective

Home-Automation-SoC is a semiconductor engineering project for a home automation System-on-Chip (SoC). The goal is to deliver an integrated silicon solution combining custom RTL, firmware, and board support for home automation applications. The SoC collects sensor data, controls household devices, and communicates with an external host running Home Assistant and a Claude-based voice assistant.

## Current Status

**Stage 0 – Requirements (IN PROGRESS)** | **Stage 1 – Architecture (PARTIAL, ADRs PROPOSED)** | **Stage 2 – RTL (NOT STARTED)**

Key accomplishments this session:
- ✅ Six specialist research reports (IP, RTL, Verification, Firmware, ASIC, PCB) complete
- ✅ Phase 0 architecture + Phase 1A RTL-readiness docs complete
- ✅ 3 binary architecture files converted to UTF-8 Markdown (Bus/Memory, Security, Boot/Firmware)
- ✅ QFN-64 pin assignment spreadsheet created (`constraints/pin_assignment_qfn64.csv`)
- ✅ Power budget analysis complete — TPS65217 1.2A/buck adequate (`reports/power_budget_analysis.md`)
- ✅ PLL strategy decided — External Si5351 clock generator (`reports/pll_strategy_decision.md`)
- ✅ System Requirements Specification (SRS) created (`docs/requirements/system_requirements.md`)
- ✅ Interface Requirements Specification created (`docs/requirements/interface_requirements.md`)
- ✅ Performance Requirements Specification created (`docs/requirements/performance_requirements.md`)
- ✅ Master project status report updated (`reports/MASTER_PROJECT_STATUS.md`)

- **Documentation:** `docs/` — architecture, requirements (SRS, IRS, PRS), IP licenses, PDK, toolchain, low-power, security, verification, project-management
- **Research reports:** `agents/deepseek/ds01..ds06/` (IP, RTL, Verification, Firmware, ASIC, PCB)
- **Implementation:** `rtl/`, `firmware/`, `tb/`, `sim/`, `board/`, `asic/`, `ip/`, `constraints/`, `scripts/` — **empty** (RTL, firmware, testbenches, PCB, ASIC scripts not yet generated)
- **Blockers:** ADRs still PROPOSED; ARC-001 (Ibex) needs human approval; no Python/cocotb; no sky130 PDK; OpenSTA build failed; no FPGA hardware

See `reports/MASTER_PROJECT_STATUS.md` for stage-by-stage status, tool inventory, blockers, and next executable tasks.


## Repository Layout

| Path | Purpose |
| --- | --- |
| `docs/` | Project management, requirements, and architecture documentation |
| `rtl/` | SystemVerilog RTL sources (top-level and peripherals) |
| `tb/` | Testbenches (UVM and unit-level) |
| `firmware/` | Bare-metal, RTOS, and driver firmware sources |
| `scripts/` | EDA and firmware build scripts |
| `board/` | Schematics, PCB, and BOM artifacts |
| `constraints/` | Pin and timing constraint files |
| `sim/` | Simulation top-level and waveform artifacts |
| `ip/` | Internal and third-party IP (no third-party IP downloaded) |

## Getting Started

1. Review the placeholder documents in `docs/` to define scope and requirements.
2. Populate `rtl/`, `tb/`, `firmware/`, and `board/` as the project progresses.
3. Run EDA and build scripts from `scripts/` once tooling is available.

## Licensing

A LICENSE file is intentionally left blank. Do not select or apply an open-source license without explicit approval from the project owner.

