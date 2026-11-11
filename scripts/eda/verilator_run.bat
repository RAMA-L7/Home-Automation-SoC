@echo off
rem ---------------------------------------------------------------------------
rem Home-Automation-SoC — Verilator C++ model runner (Windows)
rem
rem Runs a previously built Verilator model. D:\tools\mingw64\bin must be on
rem PATH so the MinGW runtime DLLs (libstdc++-6.dll, libgcc_s_seh-1.dll,
rem libwinpthread-1.dll) are found at load time.
rem
rem Usage: verilator_run.bat <exe> [args...]
rem ---------------------------------------------------------------------------
setlocal

set MINGW=D:\tools\mingw64
set PATH=%MINGW%\bin;%PATH%

set EXE=%~1
shift
if "%EXE%"=="" (
  echo ERROR: no executable given
  exit /b 1
)

"%EXE%" %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b %ERRORLEVEL%
