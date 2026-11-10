@echo off
REM Home-Automation-SoC — Firmware Flash Script
REM Stage 3 Firmware
REM
REM Flashes firmware.bin to QSPI flash via OpenOCD/JTAG.
REM Requires: openocd (available in D:\tools\oss-cad-suite\bin)
REM
REM Example usage:
REM   set PATH=D:\tools\oss-cad-suite\bin;%PATH%
REM   flash_fw.bat

setlocal

set FW_BIN=build\firmware.bin
set OPENOCD=openocd.exe
set OCD_CFG=..\..\fpga\constraints\openocd.cfg

if not exist "%FW_BIN%" (
    echo ERROR: %FW_BIN% not found. Run build_fw.bat first.
    exit /b 1
)

echo Flashing %FW_BIN% to QSPI flash via OpenOCD...

"%OPENOCD%" -f "%OCD_CFG%" -c "program %FW_BIN% 0x40000000 verify reset exit" 2>&1

if errorlevel 1 (
    echo ERROR: Flash failed.
    exit /b 1
)

echo Flash complete.

endlocal
