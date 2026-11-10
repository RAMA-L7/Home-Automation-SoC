@echo off
set PATH=D:\tools\oss-cad-suite\bin;D:\tools\oss-cad-suite\lib;%PATH%
cd /D D:\Home-Automation-SoC\sim\sim_top
verilator_bin.exe --cc --build --top-module has_soc --exe sim_main.cpp ^
  ../../rtl/rtl_top/has_addr_map.sv ^
  ../../rtl/rtl_top/boot_rom.sv ^
  ../../rtl/rtl_top/sram.sv ^
  ../../rtl/rtl_top/axi_lite_interconnect.sv ^
  ../../rtl/rtl_top/axi_lite_to_apb.sv ^
  ../../rtl/rtl_top/req_gnt_to_axi_lite.sv ^
  ../../rtl/rtl_top/riscv_core.sv ^
  ../../rtl/rtl_top/has_soc.sv ^
  ../../rtl/rtl_peripherals/gpio.sv ^
  ../../rtl/rtl_peripherals/uart.sv ^
  ../../rtl/rtl_peripherals/timer.sv ^
  ../../rtl/rtl_peripherals/clint.sv ^
  ../../rtl/rtl_peripherals/plic.sv ^
  ../../rtl/rtl_peripherals/power_mgr.sv ^
  ../../rtl/rtl_peripherals/debug_jtag.sv ^
  ../../rtl/rtl_peripherals/watchdog.sv ^
  ../../rtl/rtl_peripherals/pwm.sv ^
  ../../rtl/rtl_peripherals/i2c_ctrl.sv ^
  ../../rtl/rtl_peripherals/spi_ctrl.sv ^
  ../../rtl/rtl_peripherals/i2s.sv ^
  ../../rtl/rtl_peripherals/qspi_flash_ctrl.sv ^
  ../../rtl/rtl_peripherals/power_mgr_regs.sv
echo BUILD_DONE
