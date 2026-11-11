# Home-Automation-SoC

## Project Objective

Home-Automation-SoC is a semiconductor engineering project for a home automation System-on-Chip (SoC). The goal is to deliver an integrated silicon solution combining custom RTL, firmware, and board support for home automation applications. The SoC collects sensor data, controls household devices, and communicates with an external host running Home Assistant and a Claude-based voice assistant.

## Current Status

**Stage 0 – Requirements (COMPLETE)** | **Stage 1 – Architecture (PARTIAL, ADRs PROPOSED)** | **Stage 2 – RTL (IMPLEMENTED, SIMULATED)** | **Stage 3 – Firmware (PARTIAL)** | **Stages 4–8 (PARTIAL / BLOCKED)**

What is actually proven in simulation (MEASURED, `node scripts/eda/run_regression.js`):

- ✅ A hand-written RV32IM assembly image boots from the boot ROM on the full SoC, prints over the UART, takes a PLIC interrupt, and drives GPIO and PWM: **7/7 firmware subtests, PASS**
- ✅ 24/24 hand-encoded RV32IM instruction checks against the core (`sim/sim_top/tb_isa.v`) — independent of the in-tree assembler
- ✅ 47/47 trap-program checks covering all 7 synchronous exception causes plus recovery and no-invalid-writeback (`tb_isa.v` phase-2 trap program)
- ✅ 16/16 sleep/wake power-manager checks, including asynchronous wake and the wake-versus-sleep race
- ✅ Peripheral register tests for CLINT, PLIC, GPIO, SPI, I²C, PWM, timer, watchdog, I²S, SRAM, JTAG TAP
- ✅ UART pin-level protocol test: 153 checks PASS (`sim/sim_top/tb_uart.v`)
- ✅ Watchdog internal-reset controller: 15/15 checks PASS (`sim/sim_top/tb_reset_ctrl.v`); converts the watchdog's level output into a bounded reset pulse and resets the watchdog itself
- ✅ Regression runner is strict: a build error, a timeout, a missing test, or a `FAIL` line makes the suite exit nonzero
- ✅ Verilator lint: 0 errors

Last full regression (MEASURED, `node scripts/eda/run_regression.js`):
- `PASS 16 / 17` — 16 tests pass; `firmware (C demo)` times out at 120 ms, `wdog pulses 0`.
- The firmware image boots, prints the full banner (`=== Home-Automation-SoC Firmware ===`, `Core: RV32IM`, `SRAM: 128 KB @ 0x2000_0000`, `Boot: Complete`, `Ready for commands.`), receives the UART `r` command, echoes `Cmd: r` / `Reboot requested`, but the watchdog internal-reset pulse is **not yet observed in this bench**. The C firmware build and run remain OPEN.

What is **not** proven, and must not be described as working:

- ❌ Secure boot fails closed by design (no signature verifier is linked in); OTA **always** returns unsupported.
- ❌ Flash is read-only; I²S is transmit-only; there is no peripheral wake detector, retention mode, or deep-sleep power gating.
- ❌ No SPI/I²C device models, no I²S sample scoreboard; no formal; no synthesis; no FPGA/ASIC/PCB evidence.
- ❌ The **firmware (C demo)** regression entry does **not yet pass** — boot, UART RX, and watchdog reset are individually proven at block/pulse level, but the full `tb_firmware.v` demo has not reached PASS.

Toolchain reality: Icarus 14.0 simulates; Verilator 5.053 lints but cannot build a C++ model (no `g++`/`make`); Yosys 0.69+154 is installed but full-chip synthesis is blocked by unpacked-array ports in the interconnect; SymbiYosys, Vivado, OpenLane/OpenROAD, Magic/Netgen and a host C++ compiler are absent. A RISC-V toolchain **is available** at `/d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin` (gcc 12.2.0, readelf/objdump 2.38); the C firmware is built with `build_fw.js`, not `build_fw.py` (no Python).

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

4. Rebuild the C firmware (toolchain is present at `/d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin`):

```bash
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
RISCV_TOOLCHAIN_BIN="/d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin" node scripts/fw_build/build_fw.js
node scripts/fw_build/gen_fw_mem.js build/fw/firmware.elf /d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin
iverilog -g2012 -o build/sim/tb_firmware.vvp -s tb_firmware sim/sim_top/tb_firmware.v \
  $(grep -v '^//' rtl/filelist.f | tr '\n' ' ')
vvp build/sim/tb_firmware.vvp
```

5. Run the strict regression suite (Icarus only; Verilator is lint-only here):

```bash
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
node scripts/eda/run_regression.js            # PASS 16 / 17 today
node scripts/eda/run_regression.js --self-test # harness sanity check
```

Current suite result is **PASS 16 / 17**; the one failing entry is `firmware (C demo)`, which times out at 120 ms with `wdog pulses 0`.

## Licensing

A LICENSE file is intentionally left blank. Do not select or apply an open-source license without explicit approval from the project owner.

