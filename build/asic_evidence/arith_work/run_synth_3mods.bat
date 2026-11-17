@echo off
rem Run the 3-module techmap validation from the repository root.
cd /d "%~dp0..\..\.."
call "D:\tools\oss-cad-suite\environment.bat"
yosys -s build/asic_evidence/arith_work/synth_3mods.ys
