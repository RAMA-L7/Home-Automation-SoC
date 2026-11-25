@echo off
call "D:\tools\oss-cad-suite\environment.bat"
cd /d D:\Home-Automation-SoC
vvp build\sim\tb_sram_macro_wrap.vvp > build\sim\tb_sram_macro_wrap_out.txt 2>&1
echo VVP_EXIT: %ERRORLEVEL%
