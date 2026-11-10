# Home-Automation-SoC

## Project Objective

Home-Automation-SoC is a semiconductor engineering project for a home automation System-on-Chip (SoC). The goal is to deliver an integrated silicon solution combining custom RTL, firmware, and board support for home automation applications.

## Current Status

**Phase 0 - Not Started**

This repository has been initialized with the project directory structure, placeholder documentation, and version control. No RTL, firmware, testbenches, PCB designs, or ASIC scripts have been generated yet.

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
