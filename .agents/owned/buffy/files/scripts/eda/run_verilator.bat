@echo off
set PATH=D:\tools\oss-cad-suite\bin;D:\tools\oss-cad-suite\lib;%PATH%
cd /D D:\Home-Automation-SoC\rtl
verilator_bin.exe --lint-only -Wall --top-module has_soc ^
  rtl_top\has_addr_map.sv ^
  rtl_top\boot_rom.sv ^
  rtl_top\sram.sv ^
  rtl_top\axi_lite_interconnect.sv ^
  rtl_top\axi_lite_to_apb.sv ^
  rtl_top\req_gnt_to_axi_lite.sv ^
  rtl_top\riscv_core.sv ^
  rtl_top\has_soc.sv ^
  rtl_peripherals\gpio.sv ^
  rtl_peripherals\uart.sv ^
  rtl_peripherals\timer.sv ^
  rtl_peripherals\clint.sv ^
  rtl_peripherals\plic.sv ^
  rtl_peripherals\power_mgr.sv ^
  rtl_peripherals\debug_jtag.sv ^
  rtl_peripherals\watchdog.sv ^
  rtl_peripherals\pwm.sv ^
  rtl_peripherals\i2c_ctrl.sv ^
  rtl_peripherals\spi_ctrl.sv ^
  rtl_peripherals\i2s.sv ^
  rtl_peripherals\qspi_flash_ctrl.sv ^
  rtl_peripherals\power_mgr_regs.sv