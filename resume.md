RESUME.md — one-paragraph redo summary for quick onboarding and GitHub search.

PROJECT
Home-Automation-SoC is a low-power residential home-automation RISC-V SoC
targeting a QFN-64 package on SkyWater 130nm (sky130). Off-chip, it talks to a
Home Assistant host running a Claude-based voice assistant. The RTL instantiates
the in-tree custom `riscv_core.sv` (RV32IM, machine mode only), not Ibex — Ibex
remains a PROPOSED architecture decision.

WHAT IS PROVEN IN SIMULATION (MEASURED)
- Regression suite `node scripts/eda/run_regression.js`: PASS 17/17, exit 0.
- isa: 24/24 directed RV32IM checks + 47/47 trap-program checks (all 7
  synchronous exception causes + recovery + no-invalid-writeback).
- boot: full-SoC boot from ROM, UART banner, PLIC interrupt, GPIO + PWM: 7/7.
- uart: pin-level protocol 153/153 PASS (LSR DR bit0 fix, OE/FE sticky flags,
  THR-drop fix, div_eff clamp and RX-counter fix).
- reset_ctrl: watchdog internal-reset pulse controller 15/15 PASS.
- power_mgr sleep/wake: 16/16 PASS.
- firmware (C demo): PASS. The compiled C image runs on the RTL SoC end to end —
  boot ROM -> TCM image -> UART banner -> host 'r' command received and echoed ->
  watchdog (armed CTRL=0b11, no longer petted) expires at 20.005 ms -> reset_ctrl
  emits a bounded 16-cycle rst_sys_n pulse -> firmware reboots from ROM and
  blinks GPIO0 again. Diagnostic demo only: no image authentication, no flash
  programming, no secure boot.
- clint, plic, gpio, spi, i2c, pwm, timer, watchdog, i2s, sram, debug_jtag:
  all PASS at register level.
- Verilator lint: 0 errors.

WHAT FAILS / IS BLOCKED
- Not implemented and must not be described as working: UART FIFO/parity,
  I2S RX, flash write/erase, OTA, crypto accelerators, retention/deep-sleep
  power gating, peripheral wake detector, formal proofs, FPGA/ASIC/PCB evidence.
- Secure boot is fail-closed by design (no signature verifier linked); OTA always
  returns unsupported.

TOOLCHAIN / HOW TO RUN
- PATH: export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
- RISC-V toolchain: /d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin
  (gcc 12.2.0, readelf/objdump 2.38).
- Build C firmware: RISCV_TOOLCHAIN_BIN="/d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin" node scripts/fw_build/build_fw.js
- Regenerate hex: node scripts/fw_build/gen_fw_mem.js build/fw/firmware.elf /d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin
- Assemble boot ROM image: node scripts/fw/as.js firmware/boot/boot.S build/fw/boot.hex build/fw/boot.lst
- Run regression: node scripts/eda/run_regression.js
- Harness self-test: node scripts/eda/run_regression.js --self-test
- All EDA tools are consolidated under D:\tools (WSL: /mnt/d/tools); read
  D:\tools\EDA_TOOL_REGISTRY.md for exact paths, versions and workarounds.
  31 tools verified by D:\tools\verify_tools.bat / verify_tools_wsl.sh.
- Icarus 14.0 (devel) simulates. Verilator 5.053 works for lint AND C++
  simulation: MinGW-w64 g++ 16.1.0 + make 4.4.1 at D:\tools\mingw64 (build with
  -O2, not -Os) plus the Windows kit shim D:\tools\verilator-shim.
- Yosys 0.69+154 (native) and 0.70 (WASM) present; core-only synthesis ran
  (226 cells, 0 errors); full-chip synthesis is blocked by unpacked-array ports
  in the interconnect. SymbiYosys SBY v0.69 is available, but no property has
  been proven — scripts/formal/cdc still holds a failed-run ERROR file.
- OpenLane 2 v2.0.0b16 (D:\tools\venv-openlane2), OpenROAD, OpenSTA 3.1.0,
  Magic 8.3.105, Netgen 6.2.2401, KLayout, volare 0.20.6 are installed, but no
  ASIC flow has been run: the sky130A PDK is not volare-enabled.
- KiCad 10.0.8 at D:\tools\KiCad\10.0 (kicad-cli 10.0.8) — no project files yet.
- Vivado is proprietary and absent, and there is no FPGA board, so FPGA work is
  limited to constraints and Tcl scripts.
- No usable `python` on PATH (Windows Store stub only) — firmware build uses
  build_fw.js, not build_fw.py. A working interpreter is at D:\tools\venv.

KEY FILES
- RTL top: rtl/rtl_top/has_soc.sv, riscv_core.sv, reset_ctrl.sv, filelist.f
- Peripherals: rtl/rtl_peripherals/uart.sv (the latest fixed one), watchdog.sv,
  power_mgr.sv, power_mgr_regs.sv, clint.sv, plic.sv, gpio.sv, spi_ctrl.sv,
  i2c_ctrl.sv, pwm.sv, timer.sv, i2s.sv, qspi_flash_ctrl.sv, debug_jtag.sv
- Buses: req_gnt_to_axi_lite.sv, axi_lite_interconnect.sv, axi_lite_to_apb.sv
- Testbenches: sim/sim_top/tb_*.v (tb_firmware.v is the slowest: ~1 min wall clock,
  35.7 ms of simulated SoC time)
- Firmware: firmware/bare_metal/main.c + drivers/boot/host_comm/ota, plus
  firmware/boot/boot.S (the diagnostic smoke image that currently passes).
- Build: scripts/fw_build/build_fw.js, gen_fw_mem.js; scripts/fw/as.js;
  scripts/eda/run_regression.js.
- Docs: TECH_STACK.md, README.md, AGENTS.md, docs/architecture/SYSTEM_BLOCK_DIAGRAM.md
  (now Mermaid + ASCII), docs/architecture/*.md (ADRs, memory map, reset, etc.),
  reports/INDEPENDENT_REVIEW_2026-11-11.md.

SEARCH KEYWORDS
RV32IM, QFN-64, SkyWater 130nm, sky130, Icarus Verilog 14.0, Verilator 5.053,
Yosys 0.69, RISC-V GCC 12.2.0, AXI4-Lite, APB, PLIC, CLINT, UART 115200,
watchdog reset controller, reset_ctrl, tb_firmware, regression PASS 17/17,
fail-closed secure boot, OTA unsupported, QSPI read-only, custom RISC-V core.

LICENSING
LICENSE is an explicit placeholder — no license applied without owner approval.
