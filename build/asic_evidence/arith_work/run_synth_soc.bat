@echo off
call "D:\tools\oss-cad-suite\environment.bat"
D:\tools\oss-cad-suite\bin\yosys.exe -s "D:\Home-Automation-SoC\build\asic_evidence\arith_work\synth_soc.ys"
