@echo off
REM Home-Automation-SoC — Firmware Build Script
REM Stage 3 Firmware
REM
REM Requires: riscv32-unknown-elf-gcc toolchain (not installed)
REM Set RISCV_GCC_PREFIX to your toolchain prefix, e.g. riscv32-unknown-elf-
REM
REM Example usage:
REM   set RISCV_GCC_PREFIX=riscv32-unknown-elf-
REM   build_fw.bat

setlocal

if "%RISCV_GCC_PREFIX%"=="" (
    echo ERROR: RISCV_GCC_PREFIX environment variable not set.
    echo   Example: set RISCV_GCC_PREFIX=riscv32-unknown-elf-
    exit /b 1
)

set CC=%RISCV_GCC_PREFIX%gcc
set OBJCOPY=%RISCV_GCC_PREFIX%objcopy
set SIZE=%RISCV_GCC_PREFIX%size

set FW_DIR=..\..\firmware\bare_metal
set OUT_DIR=build

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo Building firmware for RV32IM (core has no C extension)...

"%CC%" -march=rv32im -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding ^
  -Wall -Wextra -O2 -g ^
  -T "%FW_DIR%\linker.ld" ^
  -o "%OUT_DIR%\firmware.elf" ^
  "%FW_DIR%\startup.S" ^
  "%FW_DIR%\main.c" ^
  "%FW_DIR%\drivers.c" ^
  "%FW_DIR%\boot.c" ^
  "%FW_DIR%\host_comm.c" ^
  "%FW_DIR%\ota.c" 2>&1

if errorlevel 1 (
    echo ERROR: Compilation failed.
    exit /b 1
)

echo Generating binary...
"%OBJCOPY%" -O binary "%OUT_DIR%\firmware.elf" "%OUT_DIR%\firmware.bin"

echo Generating listing...
"%OBJCOPY%" -O srec "%OUT_DIR%\firmware.elf" "%OUT_DIR%\firmware.srec"

echo Firmware size:
"%SIZE%" "%OUT_DIR%\firmware.elf"

echo Build complete: %OUT_DIR%\firmware.bin

endlocal
