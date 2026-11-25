@echo off
call "D:\tools\oss-cad-suite\environment.bat"
cd /d D:\Home-Automation-SoC
iverilog -g2012 -DUSE_POWER_PINS -o build\sim\tb_sram_macro_wrap.vvp -s tb_sram_macro_wrap_leaf ^
  sim\sim_top\tb_macro_leaf.v ^
  sim\sim_top\tb_macro_leaf_1kb.v ^
  sim\sim_top\tb_sram_macro_wrap.v ^
  sim\sim_top\tb_sram_simple.v ^
  rtl\rtl_top\sram_macro_wrap.sv 2>&1
if exist build\sim\tb_sram_macro_wrap.vvp (
  vvp build\sim\tb_sram_macro_wrap.vvp > build\sim\tb_sram_macro_wrap_out.txt 2>&1
  echo "=== T5-T10 + DBG lines ==="
  findstr /R "T5|T6|T7|T8|T9|T10|addr1=|DBG|FAIL|pass T" build\sim\tb_sram_macro_wrap_out.txt
) else (
  echo NO_BINARY
)
