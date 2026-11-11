//------------------------------------------------------------------------------
// Home-Automation-SoC — Verilator Testbench
// Stage 4 Verification
//
// Exercises the SoC data path:
//   1. Reset the SoC
//   2. Clock for N cycles (core fetches from boot ROM)
//   3. Write a pattern to SRAM (0x2000_0000) via the data AXI4-Lite interface
//   4. Read it back and verify
//
// Build:
//   cd D:\Home-Automation-SoC\sim\sim_top
//   set PATH=D:\tools\oss-cad-suite\bin;D:\tools\oss-cad-suite\lib;%PATH%
//   verilator --cc --build --top-module has_soc --exe sim_main.cpp ^
//     ../../rtl/rtl_top/has_addr_map.sv ../../rtl/rtl_top/boot_rom.sv ^
//     ../../rtl/rtl_top/sram.sv ../../rtl/rtl_top/axi_lite_interconnect.sv ^
//     ../../rtl/rtl_top/axi_lite_to_apb.sv ../../rtl/rtl_top/req_gnt_to_axi_lite.sv ^
//     ../../rtl/rtl_top/riscv_core.sv ../../rtl/rtl_top/has_soc.sv ^
//     ../../rtl/rtl_peripherals/gpio.sv ../../rtl/rtl_peripherals/uart.sv ^
//     ../../rtl/rtl_peripherals/timer.sv ../../rtl/rtl_peripherals/clint.sv ^
//     ../../rtl/rtl_peripherals/plic.sv ../../rtl/rtl_peripherals/power_mgr.sv ^
//     ../../rtl/rtl_peripherals/debug_jtag.sv ../../rtl/rtl_peripherals/watchdog.sv ^
//     ../../rtl/rtl_peripherals/pwm.sv ../../rtl/rtl_peripherals/i2c_ctrl.sv ^
//     ../../rtl/rtl_peripherals/spi_ctrl.sv ../../rtl/rtl_peripherals/i2s.sv ^
//     ../../rtl/rtl_peripherals/qspi_flash_ctrl.sv ../../rtl/rtl_peripherals/power_mgr_regs.sv
//------------------------------------------------------------------------------
#include "Vhas_soc.h"
#include "verilated.h"
#include <cstdio>
#include <cstdlib>

static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

static void clk_tick(Vhas_soc* dut, int cycles) {
  for (int i = 0; i < cycles; i++) {
    dut->clk = 0; dut->eval(); main_time++;
    dut->clk = 1; dut->eval(); main_time++;
  }
}

// AXI4-Lite write via core data interface (req/gnt)
static void axi_write(Vhas_soc* dut, uint32_t addr, uint32_t data, uint8_t strb) {
  dut->data_req   = 1;
  dut->data_we    = 1;
  dut->data_addr  = addr;
  dut->data_wdata = data;
  dut->data_wstrb = strb;
  dut->eval();

  int timeout = 0;
  while (!dut->data_gnt && timeout < 1000) {
    dut->clk = 0; dut->eval(); main_time++;
    dut->clk = 1; dut->eval(); main_time++;
    timeout++;
  }
  if (timeout >= 1000) { printf("FAIL: write gnt timeout @ 0x%08X\n", addr); exit(1); }
  dut->data_req = 0;
  dut->eval();
}

// AXI4-Lite read via core data interface
static uint32_t axi_read(Vhas_soc* dut, uint32_t addr) {
  dut->data_req   = 1;
  dut->data_we    = 0;
  dut->data_addr  = addr;
  dut->data_wdata = 0;
  dut->data_wstrb = 0;
  dut->eval();

  int timeout = 0;
  while (!dut->data_gnt && timeout < 1000) {
    dut->clk = 0; dut->eval(); main_time++;
    dut->clk = 1; dut->eval(); main_time++;
    timeout++;
  }
  if (timeout >= 1000) { printf("FAIL: read gnt timeout @ 0x%08X\n", addr); exit(1); }

  // data_rvalid asserted next cycle after gnt
  dut->clk = 0; dut->eval(); main_time++;
  dut->clk = 1; dut->eval(); main_time++;

  uint32_t rdata = dut->data_rdata;
  dut->data_req = 0;
  dut->eval();
  return rdata;
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  Vhas_soc* dut = new Vhas_soc;

  dut->clk        = 0;
  dut->reset_n    = 0;
  dut->data_req   = 0;
  dut->data_we    = 0;
  dut->data_addr  = 0;
  dut->data_wdata = 0;
  dut->data_wstrb = 0;
  dut->jtag_tck   = 0;
  dut->jtag_tms   = 0;
  dut->jtag_tdi   = 0;
  dut->jtag_trst_n= 0;
  dut->uart_rx    = 1;
  dut->spi_miso   = 1;

  printf("=== Home-Automation-SoC Verilator Testbench ===\n");

  // Reset
  printf("Applying reset...\n");
  clk_tick(dut, 10);
  dut->reset_n = 1;
  clk_tick(dut, 10);
  printf("Reset released.\n");

  // Clock for a while to let core fetch from boot ROM
  printf("Clocking 2000 cycles (core executing from boot ROM)...\n");
  clk_tick(dut, 2000);

  // SRAM full-word write/read
  printf("Testing SRAM full-word at 0x2000_0000...\n");
  axi_write(dut, 0x2000_0000, 0xDEADBEEF, 4'b1111);
  uint32_t rdata = axi_read(dut, 0x2000_0000);
  printf("  Wrote 0xDEADBEEF, read back 0x%08X\n", rdata);
  if (rdata != 0xDEADBEEF) {
    printf("FAIL: SRAM readback mismatch!\n");
    return 1;
  }
  printf("PASS: SRAM full-word readback matches.\n");

  // SRAM byte write
  printf("Testing SRAM byte write at 0x2000_0004...\n");
  axi_write(dut, 0x2000_0004, 0x12345678, 4'b0001);
  rdata = axi_read(dut, 0x2000_0004);
  printf("  Byte wrote 0x78, read back 0x%08X (low byte = 0x%02X)\n", rdata, rdata & 0xFF);
  if ((rdata & 0xFF) != 0x78) {
    printf("FAIL: SRAM byte write mismatch!\n");
    return 1;
  }
  printf("PASS: SRAM byte write works.\n");

  // SRAM halfword write
  printf("Testing SRAM halfword write at 0x2000_0008...\n");
  axi_write(dut, 0x2000_0008, 0xAA55AA55, 4'b0011);
  rdata = axi_read(dut, 0x2000_0008);
  printf("  Halfword wrote 0xAA55, read back 0x%08X (low half = 0x%04X)\n", rdata, rdata & 0xFFFF);
  if ((rdata & 0xFFFF) != 0xAA55) {
    printf("FAIL: SRAM halfword write mismatch!\n");
    return 1;
  }
  printf("PASS: SRAM halfword write works.\n");

  printf("=== All SRAM tests PASSED ===\n");
  dut->final();
  delete dut;
  return 0;
}
