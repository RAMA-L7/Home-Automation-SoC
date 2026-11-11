@echo off
rem ---------------------------------------------------------------------------
rem Home-Automation-SoC — Full-SoC Verilator C++ model builder (Windows)
rem
rem Builds the complete SoC (all 22 RTL files from rtl/filelist.f) plus a
rem testbench into a Verilator C++ model and links it into an executable.
rem
rem Usage: verilator_build_soc.bat <top_module> <tb_file> [obj_dir]
rem
rem Example:
rem   verilator_build_soc.bat tb_boot sim\sim_top\tb_boot.v build\obj_soc
rem
rem The model must be run from the project root because has_soc.sv takes a
rem relative BOOT_ROM_FILE path ("build/fw/boot.hex").
rem
rem See scripts/eda/verilator_build.bat for the individual work-arounds this
rem script inherits (Windows-native Verilator kit shim, -O2 instead of -Os,
rem hand-rolled archive step, -mconsole link).
rem ---------------------------------------------------------------------------
setlocal EnableDelayedExpansion

set TOOLS=D:\tools
set OSS=%TOOLS%\oss-cad-suite
set MINGW=%TOOLS%\mingw64
set SHIM=%TOOLS%\verilator-shim
set ROOT=D:\Home-Automation-SoC

set TOP=%~1
set TB=%~2
set MDIR=%~3
if "%MDIR%"=="" set MDIR=%ROOT%\build\obj_soc

if not exist "%MDIR%" mkdir "%MDIR%"

set PATH=%OSS%\bin;%OSS%\lib;%MINGW%\bin;%PATH%
set PYTHON3=%OSS%\lib\python3.exe
set YOSYSHQ_ROOT=%OSS%

set OPTARGS=OPT_FAST=-O2 OPT_GLOBAL=-O2 OPT_SLOW=-O2
set LINKARGS=LDFLAGS=-mconsole

rem Collect the RTL file list (rtl/filelist.f, skipping comments).
set RTL=
for /f "usebackq tokens=*" %%F in ("%ROOT%\rtl\filelist.f") do (
  set "LINE=%%F"
  echo %%F | findstr /b /c:"//" >nul || set "RTL=!RTL! %ROOT%\%%F"
)

echo === [1/4] Generating C++ model for %TOP% ===
cd /d %ROOT%
%OSS%\bin\verilator_bin.exe --cc --exe --main --timing -Wno-fatal ^
  --Mdir %MDIR% --top-module %TOP% %TB% !RTL!
if errorlevel 1 goto :fail

echo === [2/4] Pointing VERILATOR_ROOT at the Windows kit shim ===
powershell -NoProfile -Command ^
  "$mk='%MDIR%\V%TOP%.mk'; $c=Get-Content $mk -Raw;" ^
  "$c=$c -replace 'VERILATOR_ROOT = /yosyshq/share/verilator','VERILATOR_ROOT = %SHIM%';" ^
  "Set-Content -Path $mk -Value $c -NoNewline"
if errorlevel 1 goto :fail

echo === [3/4] Compiling objects ===
cd /d %MDIR%
make -f V%TOP%.mk -j 4 %OPTARGS% %LINKARGS% V%TOP%__ALL.o
if errorlevel 1 goto :fail

echo === [4/4] Archiving and linking ===
set OBJLIST=
for /f "delims=" %%F in ('dir /b V%TOP%*.o 2^>nul') do set OBJLIST=!OBJLIST! %%F
echo Objects:!OBJLIST!
if "!OBJLIST!"=="" (
  echo ERROR: no model objects found for %TOP%
  goto :fail
)
del /f /q V%TOP%__ALL.a 2>nul
ar -rc V%TOP%__ALL.a !OBJLIST!
if errorlevel 1 goto :fail
ar -s V%TOP%__ALL.a
if errorlevel 1 goto :fail

make -f V%TOP%.mk -j 4 %OPTARGS% %LINKARGS%
if errorlevel 1 goto :fail

echo === BUILD OK: %MDIR%\V%TOP%.exe ===
exit /b 0

:fail
echo === BUILD FAILED ===
exit /b 1
