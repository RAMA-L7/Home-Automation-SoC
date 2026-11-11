RESUME.md — one-paragraph redo summary for quick onboarding and GitHub search.

PROJECT
Home-Automation-SoC is a low-power residential home-automation RISC-V SoC
targeting a QFN-64 package on SkyWater 130nm (sky130). Off-chip, it talks to a
Home Assistant host running a Claude-based voice assistant. The RTL instantiates
the in-tree custom `riscv_core.sv` (RV32IM, machine mode only), not Ibex — Ibex
remains a PROPOSED architecture decision.

WHAT IS PROVEN IN SIMULATION (MEASURED)
- Regression suite `node scripts/eda/run_regression.js`: PASS 16/17.
- isa: 24/24 directed RV32IM checks + 47/47 trap-program checks (all 7
  synchronous exception causes + recovery + no-invalid-writeback).
- boot: full-SoC boot from ROM, UART banner, PLIC interrupt, GPIO + PWM: 7/7.
- uart: pin-level protocol 153/153 PASS (LSR DR bit0 fix, OE/FE sticky flags,
  THR-drop fix, div_eff clamp and RX-counter fix).
- reset_ctrl: watchdog internal-reset pulse controller 15/15 PASS.
- power_mgr sleep/wake: 16/16 PASS.
- clint, plic, gpio, spi, i2c, pwm, timer, watchdog, i2s, sram, debug_jtag:
  all PASS at register level.
- Verilator lint: 0 errors.

WHAT FAILS / IS BLOCKED
- firmware (C demo): tb_firmware.v boots the C image, prints the full banner
  (=== Home-Automation-SoC Firmware ===, Core: RV32IM, SRAM: 128 KB @
  0x2000_0000, Boot: Complete, Ready for commands.), receives the UART `r`
  command and echoes Cmd: r / Reboot requested, but does NOT observe a watchdog
  reset pulse within the 120 ms hang guard (wdog pulses 0). Open item is the
  integration/observation in tb_firmware.v; the block-level pieces are already
  proven separately.
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
- Icarus 14.0 (devel) simulates; Verilator 5.053 lints but cannot build a C++
  model here (no g++/make); Yosys 0.69+154 is installed but full-chip synthesis
  is blocked by unpacked-array ports in the interconnect; SymbiYosys/Vivado/
  OpenLane/OpenROAD/Magic/Netgen and a host C++ compiler are absent. No Python
  either — firmware build uses build_fw.js, not build_fw.py.

KEY FILES
- RTL top: rtl/rtl_top/has_soc.sv, riscv_core.sv, reset_ctrl.sv, filelist.f
- Peripherals: rtl/rtl_peripherals/uart.sv (the latest fixed one), watchdog.sv,
  power_mgr.sv, power_mgr_regs.sv, clint.sv, plic.sv, gpio.sv, spi_ctrl.sv,
  i2c_ctrl.sv, pwm.sv, timer.sv, i2s.sv, qspi_flash_ctrl.sv, debug_jtag.sv
- Buses: req_gnt_to_axi_lite.sv, axi_lite_interconnect.sv, axi_lite_to_apb.sv
- Testbenches: sim/sim_top/tb_*.v (tb_firmware.v is the open FAIL case)
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
watchdog reset controller, reset_ctrl, tb_firmware, regression PASS 16/17,
fail-closed secure boot, OTA unsupported, QSPI read-only, custom RISC-V core.

LICENSING
LICENSE is an explicit placeholder — no license applied without owner approval.
