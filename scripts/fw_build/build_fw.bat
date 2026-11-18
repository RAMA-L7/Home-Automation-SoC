@echo off
REM Home-Automation-SoC — firmware build (compatibility wrapper)
REM
REM This file used to carry its own build logic and required a pre-set
REM RISCV_GCC_PREFIX.  It now delegates to build_fw.js, which resolves the
REM toolchain through scripts/fw_build/toolchain.js — the one discovery
REM algorithm used by every driver (F6).
REM
REM   build_fw.bat            same as: node scripts/fw_build/build_fw.js
REM
REM Set RISCV_GCC_PREFIX or RISCV_TOOLCHAIN_BIN to override discovery; an
REM override that does not work fails the build instead of being ignored.

setlocal

where node >nul 2>nul
if errorlevel 1 (
    echo ERROR: node not found on PATH; it is required to resolve the toolchain.
    exit /b 2
)

node "%~dp0build_fw.js" %*
exit /b %errorlevel%
