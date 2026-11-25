@echo off
call "D:\tools\oss-cad-suite\environment.bat"
cd /d D:\Home-Automation-SoC
iverilog -g2012 -DUSE_POWER_PINS -o build\sim\tb_sram_macro_wrap.vvp -s tb_sram_macro_wrap_leaf sim\sim_top\tb_macro_leaf.v sim\sim_top\tb_macro_leaf_1kb.v sim\sim_top\tb_sram_macro_wrap.v sim\sim_top\tb_sram_simple.v rtl\rtl_top\sram_macro_wrap.sv
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
vvp build\sim\tb_sram_macro_wrap.vvp > build\sim\tb_sram_macro_wrap_out.txt 2>&1
echo VVP_EXIT: %ERRORLEVEL%
