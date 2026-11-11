@echo off
rem ---------------------------------------------------------------------------
rem Home-Automation-SoC — Verilator C++ model builder (Windows)
rem
rem Builds a Verilator-generated C++ model on Windows. Solves the problems that
rem previously made Verilator simulation impossible on this machine:
rem
rem  1. verilator_bin.exe has a compiled-in VERILATOR_ROOT of
rem     /yosyshq/share/verilator and ignores VERILATOR_ROOT / YOSYSHQ_ROOT.
rem     D:\tools\patch_verilator_kit.py builds a Windows-native kit shim at
rem     D:\tools\verilator-shim; the generated <top>.mk is then rewritten to
rem     point at that shim.
rem  2. verilator_bin.exe invokes plain "make"; MinGW ships it as
rem     mingw32-make.exe, so a make.exe alias is required.
rem  3. The toolchain (g++, ar, make) comes from D:\tools\mingw64.
rem  4. verilated.mk's "%.a" archive rule uses POSIX shell constructs that
rem     cmd.exe rejects. The archive is therefore built here in a separate
rem     stage and pre-created, so make never runs that rule.
rem  5. The WinLibs GCC 16.1.0 toolchain mis-compiles libstdc++'s std::string
rem     move constructor at -Os (undefined reference to
rem     std::__cxx11::basic_string<...>::basic_string(basic_string&&)), so
rem     -O2 is used instead of verilated.mk's default -Os.
rem
rem Usage: verilator_build.bat <top_module> <source.v> [obj_dir]
rem ---------------------------------------------------------------------------
setlocal EnableDelayedExpansion

set TOOLS=D:\tools
set OSS=%TOOLS%\oss-cad-suite
set MINGW=%TOOLS%\mingw64
set SHIM=%TOOLS%\verilator-shim

set TOP=%~1
set SRC=%~2
set MDIR=%~3
if "%MDIR%"=="" set MDIR=%CD%\build\obj_dir

if not exist "%MDIR%" mkdir "%MDIR%"

if not exist "%OSS%\bin\verilator_bin.exe" (
  echo ERROR: verilator_bin.exe not found
  exit /b 1
)
if not exist "%MINGW%\bin\make.exe" (
  echo ERROR: %MINGW%\bin\make.exe missing - copy mingw32-make.exe to make.exe
  exit /b 1
)
if not exist "%SHIM%\include\verilated.mk" (
  echo ERROR: %SHIM% missing - run: python D:\tools\patch_verilator_kit.py
  exit /b 1
)

set PATH=%OSS%\bin;%OSS%\lib;%MINGW%\bin;%PATH%
set PYTHON3=%OSS%\lib\python3.exe
set YOSYSHQ_ROOT=%OSS%

set OPTARGS=OPT_FAST=-O2 OPT_GLOBAL=-O2 OPT_SLOW=-O2
rem LDFLAGS=-mconsole: MinGW's g++ otherwise links a GUI-subsystem binary and
rem the CRT then demands WinMain instead of main.
set LINKARGS=LDFLAGS=-mconsole

echo === [1/4] Generating C++ model for %TOP% ===
%OSS%\bin\verilator_bin.exe --cc --exe --main --timing -Wno-fatal --Mdir %MDIR% --top-module %TOP% %SRC%
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
rem Build the archive by hand: verilated.mk's "%.a" rule is POSIX-only.
rem The model objects are exactly the V<top>*.o files in this directory; the
rem Verilator runtime objects (verilated*.o) are linked separately and must
rem NOT be archived.
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
