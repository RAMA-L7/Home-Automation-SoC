@echo off
rem Run the full-SoC techmap attempt from the repository root.
cd /d "%~dp0..\..\.."
call "D:\tools\oss-cad-suite\environment.bat"
yosys -s build/asic_evidence/arith_work/synth_soc.ys
