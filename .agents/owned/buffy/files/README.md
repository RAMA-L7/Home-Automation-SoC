# Home-Automation-SoC

## Project Objective

Home-Automation-SoC is a semiconductor engineering project for a home automation System-on-Chip (SoC). The goal is to deliver an integrated silicon solution combining custom RTL, firmware, and board support for home automation applications. The SoC collects sensor data, controls household devices, and communicates with an external host running Home Assistant and a Claude-based voice assistant.

## Current Status

**Stage 0 – Requirements (COMPLETE)** | **Stage 1 – Architecture (PARTIAL, ADRs PROPOSED)** | **Stage 2 – RTL (IMPLEMENTED, SIMULATED)** | **Stage 3 – Firmware (PARTIAL)** | **Stages 4–8 (PARTIAL / BLOCKED)**

What is actually proven in simulation (MEASURED, `node scripts/eda/run_regression.js`):

- ✅ A hand-written RV32IM assembly image boots from the boot ROM on the full SoC, prints over the UART, takes a PLIC interrupt, and drives GPIO and PWM: **7/7 firmware subtests, PASS**
- ✅ 24/24 hand-encoded RV32IM instruction checks against the core (`sim/sim_top/tb_isa.v`) — independent of the in-tree assembler
- ✅ 16/16 sleep/wake power-manager checks, including asynchronous wake and the wake-versus-sleep race
- ✅ Peripheral register tests for CLINT, PLIC, GPIO, SPI, I²C, PWM, timer, watchdog, I²S, SRAM, JTAG TAP
- ✅ Regression runner is strict: a build error, a timeout, a missing test, or a `FAIL` line makes the suite exit nonzero
- ✅ Verilator lint: 0 errors

What is **not** proven, and must not be described as working:

- ❌ The C firmware in `firmware/bare_metal/` has **never been built or run here** — no RISC-V toolchain is installed. The image under test is `firmware/boot/boot.S`, a diagnostic smoke ROM, **not** a secure-boot qualification.
- ❌ Secure boot fails closed by design (no signature verifier is linked in); OTA **always** returns unsupported.
- ❌ Flash is read-only; I²S is transmit-only; there is no peripheral wake detector, retention mode, or deep-sleep power gating.
- ❌ No UART pin-level protocol test, no SPI/I²C device models, no I²S sample scoreboard.
- ❌ No synthesis, formal, timing, FPGA, ASIC or PCB evidence of any kind.

Toolchain reality: Icarus 14.0 simulates; Verilator 5.053 lints but cannot build a C++ model (no `g++`/`make`); Yosys 0.69+154 is installed but has not been run on the current filelist; SymbiYosys, Vivado, OpenLane/OpenROAD, Magic/Netgen and the RISC-V GCC toolchain are absent.

The RTL instantiates the **in-tree custom RV32IM core** (`rtl/rtl_top/riscv_core.sv`), not Ibex. Ibex remains a PROPOSED architecture decision. All firmware must therefore be built `-march=rv32im -mabi=ilp32`.

See `TECH_STACK.md` for the component-by-component matrix and `reports/INDEPENDENT_REVIEW_2026-11-11.md` for the current findings, commands and remaining work.


## Repository Layout

| Path | Purpose |
| --- | --- |
| `docs/` | Project management, requirements, and architecture documentation |
| `rtl/` | SystemVerilog RTL sources (top-level and peripherals) |
| `tb/` | Legacy testbench directory (superseded by `sim/sim_top/`) |
| `firmware/` | Bare-metal, RTOS, and driver firmware sources |
| `scripts/` | EDA and firmware build scripts |
| `board/` | Schematics, PCB, and BOM artifacts |
| `constraints/` | Pin and timing constraint files |
| `sim/` | Simulation top-level and waveform artifacts |
| `ip/` | Internal and third-party IP (no third-party IP downloaded) |

## Getting Started

1. Read `TECH_STACK.md` for what is implemented versus intended.
2. Run the regression suite (needs the OSS CAD Suite on `PATH`):

```bash
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
node scripts/eda/run_regression.js
```

3. Rebuild the boot image and run the full-SoC test:

```bash
node scripts/fw/as.js firmware/boot/boot.S build/fw/boot.hex build/fw/boot.lst
iverilog -g2012 -o build/sim/tb_boot.vvp -s tb_boot sim/sim_top/tb_boot.v \
  $(grep -v '^//' rtl/filelist.f | tr '\n' ' ')
vvp build/sim/tb_boot.vvp
```

4. The C firmware build (`scripts/fw_build/build_fw.py`) requires a RISC-V GCC toolchain that is not installed in this environment.

## Licensing

A LICENSE file is intentionally left blank. Do not select or apply an open-source license without explicit approval from the project owner.

