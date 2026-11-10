//------------------------------------------------------------------------------
// Home-Automation-SoC — Address Map (Verilog-2001 compatible header)
// Stage 2 RTL
//------------------------------------------------------------------------------
`ifndef HAS_ADDR_MAP_VH
`define HAS_ADDR_MAP_VH

// Region base addresses
`define ADDR_BOOT_ROM_BASE  32'h0000_0000
`define ADDR_BOOT_ROM_SIZE  32'h0000_4000   // 16 KB
`define ADDR_TCM_BASE       32'h0001_0000
`define ADDR_TCM_SIZE       32'h0000_8000   // 32 KB
`define ADDR_SRAM_BASE      32'h2000_0000
`define ADDR_SRAM_SIZE      32'h0002_0000   // 128 KB
`define ADDR_QSPI_FLASH_BASE 32'h4000_0000
`define ADDR_QSPI_FLASH_SIZE 32'h0400_0000  // 64 MB
`define ADDR_APB_BASE       32'h5000_0000
`define ADDR_APB_SIZE       32'h0010_0000   // 1 MB
`define ADDR_INTC_BASE      32'h8000_0000
`define ADDR_INTC_SIZE      32'h0001_0000   // 64 KB

// APB peripheral sub-map
`define ADDR_GPIO_BASE      32'h5000_0000
`define ADDR_GPIO_SIZE      32'h0000_1000
`define ADDR_UART_BASE      32'h5000_1000
`define ADDR_UART_SIZE      32'h0000_1000
`define ADDR_I2C_BASE       32'h5000_2000
`define ADDR_I2C_SIZE       32'h0000_1000
`define ADDR_SPI_BASE       32'h5000_3000
`define ADDR_SPI_SIZE       32'h0000_1000
`define ADDR_PWM_BASE       32'h5000_4000
`define ADDR_PWM_SIZE       32'h0000_1000
`define ADDR_TIMER_BASE     32'h5000_5000
`define ADDR_TIMER_SIZE     32'h0000_1000
`define ADDR_WDOG_BASE      32'h5000_6000
`define ADDR_WDOG_SIZE      32'h0000_1000
`define ADDR_I2S_BASE       32'h5000_7000
`define ADDR_I2S_SIZE       32'h0000_1000
`define ADDR_PWRMGR_BASE    32'h5000_8000
`define ADDR_PWRMGR_SIZE    32'h0000_1000

// INTC sub-map
`define ADDR_CLINT_BASE     32'h8000_0000
`define ADDR_CLINT_SIZE     32'h0000_1000
`define ADDR_PLIC_BASE      32'h8000_1000
`define ADDR_PLIC_SIZE      32'h0000_F000

`endif
