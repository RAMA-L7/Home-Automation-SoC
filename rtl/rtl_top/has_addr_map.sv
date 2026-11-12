//------------------------------------------------------------------------------
// Home-Automation-SoC — Address Map
// Stage 2 RTL
//------------------------------------------------------------------------------
// The file name is the name the filelist, the docs and every include use.
// verilog_lint: waive package-filename
package has_addr_map_pkg;

  // Region base addresses
  localparam logic [31:0] ADDR_BOOT_ROM_BASE  = 32'h0000_0000;
  localparam logic [31:0] ADDR_BOOT_ROM_SIZE  = 32'h0000_4000;   // 16 KB
  localparam logic [31:0] ADDR_TCM_BASE       = 32'h0001_0000;
  localparam logic [31:0] ADDR_TCM_SIZE       = 32'h0000_8000;   // 32 KB
  localparam logic [31:0] ADDR_SRAM_BASE      = 32'h2000_0000;
  localparam logic [31:0] ADDR_SRAM_SIZE      = 32'h0002_0000;   // 128 KB
  localparam logic [31:0] ADDR_QSPI_FLASH_BASE= 32'h4000_0000;
  localparam logic [31:0] ADDR_QSPI_FLASH_SIZE= 32'h0400_0000;   // 64 MB
  localparam logic [31:0] ADDR_APB_BASE       = 32'h5000_0000;
  localparam logic [31:0] ADDR_APB_SIZE       = 32'h0010_0000;   // 1 MB
  localparam logic [31:0] ADDR_INTC_BASE      = 32'h8000_0000;
  localparam logic [31:0] ADDR_INTC_SIZE      = 32'h0001_0000;   // 64 KB

  // APB peripheral sub-map (within 0x5000_0000, 1 MB space)
  localparam logic [31:0] ADDR_GPIO_BASE      = 32'h5000_0000;
  localparam logic [31:0] ADDR_GPIO_SIZE      = 32'h0000_1000;
  localparam logic [31:0] ADDR_UART_BASE      = 32'h5000_1000;
  localparam logic [31:0] ADDR_UART_SIZE      = 32'h0000_1000;
  localparam logic [31:0] ADDR_I2C_BASE       = 32'h5000_2000;
  localparam logic [31:0] ADDR_I2C_SIZE       = 32'h0000_1000;
  localparam logic [31:0] ADDR_SPI_BASE       = 32'h5000_3000;
  localparam logic [31:0] ADDR_SPI_SIZE       = 32'h0000_1000;
  localparam logic [31:0] ADDR_PWM_BASE       = 32'h5000_4000;
  localparam logic [31:0] ADDR_PWM_SIZE       = 32'h0000_1000;
  localparam logic [31:0] ADDR_TIMER_BASE     = 32'h5000_5000;
  localparam logic [31:0] ADDR_TIMER_SIZE     = 32'h0000_1000;
  localparam logic [31:0] ADDR_WDOG_BASE      = 32'h5000_6000;
  localparam logic [31:0] ADDR_WDOG_SIZE      = 32'h0000_1000;
  localparam logic [31:0] ADDR_I2S_BASE       = 32'h5000_7000;
  localparam logic [31:0] ADDR_I2S_SIZE       = 32'h0000_1000;
  localparam logic [31:0] ADDR_PWRMGR_BASE    = 32'h5000_8000;
  localparam logic [31:0] ADDR_PWRMGR_SIZE    = 32'h0000_1000;

  // INTC sub-map
  localparam logic [31:0] ADDR_CLINT_BASE     = 32'h8000_0000;
  localparam logic [31:0] ADDR_CLINT_SIZE     = 32'h0000_1000;
  localparam logic [31:0] ADDR_PLIC_BASE      = 32'h8000_1000;
  localparam logic [31:0] ADDR_PLIC_SIZE      = 32'h0000_F000;

  // Address decode helper
  function automatic int unsigned addr_region(logic [31:0] a);
    if      (a >= ADDR_BOOT_ROM_BASE  && a < ADDR_BOOT_ROM_BASE  + ADDR_BOOT_ROM_SIZE)  addr_region = 0;
    else if (a >= ADDR_TCM_BASE       && a < ADDR_TCM_BASE       + ADDR_TCM_SIZE)       addr_region = 1;
    else if (a >= ADDR_SRAM_BASE      && a < ADDR_SRAM_BASE      + ADDR_SRAM_SIZE)      addr_region = 2;
    else if (a >= ADDR_QSPI_FLASH_BASE&& a < ADDR_QSPI_FLASH_BASE + ADDR_QSPI_FLASH_SIZE) addr_region = 3;
    else if (a >= ADDR_APB_BASE       && a < ADDR_APB_BASE       + ADDR_APB_SIZE)       addr_region = 4;
    else if (a >= ADDR_INTC_BASE      && a < ADDR_INTC_BASE      + ADDR_INTC_SIZE)      addr_region = 5;
    else                                                                               addr_region = 6;
  endfunction

endpackage
