@echo off
call "D:\tools\oss-cad-suite\environment.bat"
cd /d D:\Home-Automation-SoC
iverilog -g2012 -DUSE_POWER_PINS -I rtl\rtl_top -o build\sim\tb_has_soc.vvp -s tb_has_soc sim\sim_top\tb_has_soc.v rtl\rtl_top\has_soc.sv rtl\rtl_top\sram_macro_wrap.sv rtl\rtl_top\tcm_macro_wrap.sv rtl\rtl_top\boot_rom.sv 2> build\sim\tb_has_soc_compile.txt
echo COMPILE_EXIT: %ERRORLEVEL%
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
vvp build\sim\tb_has_soc.vvp > build\sim\tb_has_soc_out.txt 2>&1
echo RUN_EXIT: %ERRORLEVEL%
