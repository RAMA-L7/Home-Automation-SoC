//------------------------------------------------------------------------------
// Home-Automation-SoC — Full Integration Testbench
// Stage 4 Verification
//
// Tests the complete SoC data path:
// 1. Reset and boot ROM execution
// 2. SRAM read/write via core data interface
// 3. APB peripheral access (GPIO, UART, Timer)
// 4. Interrupt handling (CLINT + PLIC)
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_integration;

  reg clk;
  reg reset_n;
  
  // JTAG
  reg jtag_tck, jtag_tms, jtag_tdi, jtag_trst_n;
  wire jtag_tdo;
  
  // External interrupts
  reg [31:0] ext_irq;
  
  // UART
  wire uart_tx;
  reg uart_rx;
  
  // SPI
  wire spi_sck, spi_mosi, spi_cs_n;
  reg spi_miso;
  
  // I2C
  wire i2c_scl, i2c_sda;
  
  // GPIO
  wire [15:0] gpio;
  
  // PWM
  wire [3:0] pwm_out;
  
  // I2S
  wire i2s_bclk, i2s_lrclk, i2s_dout;
  reg i2s_din;
  
  // QSPI
  wire qspi_sck, qspi_cs_n;
  wire [3:0] qspi_io;
  
  // Watchdog
  wire wdog_reset_n_out;
  
  // Power
  wire wake_req;
  reg wake_ack;
  
  // Core data interface (req/gnt)
  reg         data_req;
  reg         data_we;
  reg [31:0]  data_addr;
  reg [31:0]  data_wdata;
  reg [3:0]   data_wstrb;
  wire        data_gnt;
  wire [31:0] data_rdata;
  wire        data_rvalid;
  
  // DUT
  has_soc dut (
    .clk              (clk),
    .reset_n          (reset_n),
    .jtag_tck         (jtag_tck),
    .jtag_tms         (jtag_tms),
    .jtag_tdi         (jtag_tdi),
    .jtag_tdo         (jtag_tdo),
    .jtag_trst_n      (jtag_trst_n),
    .ext_irq          (ext_irq),
    .uart_tx          (uart_tx),
    .uart_rx          (uart_rx),
    .spi_sck          (spi_sck),
    .spi_mosi         (spi_mosi),
    .spi_miso         (spi_miso),
    .spi_cs_n         (spi_cs_n),
    .i2c_scl          (i2c_scl),
    .i2c_sda          (i2c_sda),
    .gpio             (gpio),
    .pwm_out          (pwm_out),
    .i2s_bclk         (i2s_bclk),
    .i2s_lrclk        (i2s_lrclk),
    .i2s_dout         (i2s_dout),
    .i2s_din          (i2s_din),
    .qspi_sck         (qspi_sck),
    .qspi_cs_n        (qspi_cs_n),
    .qspi_io          (qspi_io),
    .wdog_reset_n_out (wdog_reset_n_out),
    .wake_req         (wake_req),
    .wake_ack         (wake_ack),
    // Core data interface
    .data_req         (data_req),
    .data_we          (data_we),
    .data_addr        (data_addr),
    .data_wdata       (data_wdata),
    .data_wstrb       (data_wstrb),
    .data_gnt         (data_gnt),
    .data_rdata       (data_rdata),
    .data_rvalid      (data_rvalid)
  );
  
  // Clock
  initial clk = 0;
  always #10 clk = ~clk;  // 50 MHz
  
  // I2C pullups
  pullup (i2c_scl);
  pullup (i2c_sda);
  
  // GPIO stimulus
  reg [15:0] gpio_drive, gpio_drive_en;
  genvar i;
  generate
    for (i = 0; i < 16; i++) begin : g_pad
      assign gpio[i] = gpio_drive_en[i] ? gpio_drive[i] : 1'bz;
    end
  endgenerate
  
  // Tasks
  task axi_write(input [31:0] addr, input [31:0] data, input [3:0] strb);
    begin
      data_req   = 1;
      data_we    = 1;
      data_addr  = addr;
      data_wdata = data;
      data_wstrb = strb;
      @(posedge clk);
      while (!data_gnt) @(posedge clk);
      data_req = 0;
      @(posedge clk);
    end
  endtask
  
  task axi_read(input [31:0] addr, output [31:0] rdata);
    begin
      data_req   = 1;
      data_we    = 0;
      data_addr  = addr;
      data_wdata = 0;
      data_wstrb = 0;
      @(posedge clk);
      while (!data_gnt) @(posedge clk);
      @(posedge clk);  // rvalid next cycle
      rdata = data_rdata;
      data_req = 0;
      @(posedge clk);
    end
  endtask
  
  // Test sequence
  initial begin
    $dumpfile("waveforms/tb_integration.vcd");
    $dumpvars(0, tb_integration);
    
    // Init
    reset_n = 0;
    data_req = 0; data_we = 0; data_addr = 0; data_wdata = 0; data_wstrb = 0;
    jtag_tck = 0; jtag_tms = 0; jtag_tdi = 0; jtag_trst_n = 1;
    ext_irq = 32'd0;
    uart_rx = 1;
    spi_miso = 1;
    i2s_din = 0;
    wake_ack = 0;
    gpio_drive = 16'd0;
    gpio_drive_en = 16'd0;
    
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);
    
    $display("TB: Integration test started");
    
    // Wait for core to fetch from boot ROM (a few hundred cycles)
    $display("TB: Waiting for core to boot...");
    repeat (5000) @(posedge clk);
    
    // Test 1: SRAM access
    $display("TB: Test 1 - SRAM access");
    axi_write(32'h2000_0000, 32'hDEADBEEF, 4'b1111);
    axi_read(32'h2000_0000, rdata);
    $display("TB: SRAM[0x2000_0000] = 0x%08X (expected 0xDEADBEEF)", rdata);
    if (rdata != 32'hDEADBEEF) $display("FAIL");
    else $display("PASS");
    
    // Byte write
    axi_write(32'h2000_0004, 32'h12345678, 4'b0001);
    axi_read(32'h2000_0004, rdata);
    $display("TB: SRAM[0x2000_0004] = 0x%08X (low byte = 0x%02X, expected 0x78)", rdata, rdata & 8'hFF);
    if ((rdata & 8'hFF) != 8'h78) $display("FAIL");
    else $display("PASS");
    
    // Test 2: GPIO access via APB
    $display("TB: Test 2 - GPIO access");
    // Configure GPIO[0] as output
    axi_write(32'h5000_0008, 32'h00000001, 4'b1111);  // OE
    axi_write(32'h5000_0000, 32'h00000001, 4'b1111);  // DATA_OUT = 1
    repeat (10) @(posedge clk);
    axi_read(32'h5000_0004, rdata);  // DATA_IN
    $display("TB: GPIO DATA_IN = 0x%08X", rdata);
    
    // Toggle
    axi_write(32'h5000_0000, 32'h00000000, 4'b1111);
    repeat (10) @(posedge clk);
    axi_write(32'h5000_0000, 32'h00000001, 4'b1111);
    repeat (10) @(posedge clk);
    
    // Test 3: Timer access
    $display("TB: Test 3 - Timer access");
    axi_read(32'h5000_5000, rdata);  // COUNT
    $display("TB: Timer COUNT = 0x%08X", rdata);
    
    axi_write(32'h5000_5004, 32'h00000064, 4'b1111);  // COMPARE = 100
    axi_write(32'h5000_5008, 32'h00000003, 4'b1111);  // CTRL = enable + int_en
    repeat (200) @(posedge clk);
    axi_read(32'h5000_500C, rdata);  // STATUS
    $display("TB: Timer STATUS = 0x%08X", rdata);
    
    // Test 4: UART loopback
    $display("TB: Test 4 - UART");
    axi_write(32'h5000_100C, 32'h03, 4'b1111);  // LCR = 8N1
    axi_write(32'h5000_1004, 32'h00, 4'b1111);  // IER = no interrupts
    
    // Send a character
    axi_write(32'h5000_1000, 32'h41, 4'b1111);  // TX 'A'
    repeat (50000) @(posedge clk);
    
    // Test 5: PWM
    $display("TB: Test 5 - PWM");
    axi_write(32'h5000_4000, 32'h01, 4'b1111);  // CTRL: enable PWM0
    axi_write(32'h5000_4004, 32'h01, 4'b1111);  // CH0_CTRL: enable
    axi_write(32'h5000_4008, 32'hC350, 4'b1111); // CH0_PERIOD: 50000 (1kHz)
    axi_write(32'h5000_400C, 32'h61A8, 4'b1111); // CH0_DUTY: 25000 (50%)
    repeat (200000) @(posedge clk);
    
    // Test 6: CLINT MTIME
    $display("TB: Test 6 - CLINT MTIME");
    // MTIME is at 0x8000_8000+ but we access via AXI-Lite bridge
    // For now just observe it runs
    repeat (1000) @(posedge clk);
    
    // Test 7: PLIC interrupt
    $display("TB: Test 7 - PLIC interrupt");
    axi_write(32'h8000_1000, 32'd10, 4'b1111);  // Priority 0 = 10
    axi_write(32'h8000_1004, 32'd20, 4'b1111);  // Priority 1 = 20
    axi_write(32'h8000_1008, 32'd5, 4'b1111);   // Priority 2 = 5
    axi_write(32'h8000_100C, 32'd30, 4'b1111);  // Priority 3 = 30
    axi_write(32'h8000_2000, 32'h0F, 4'b1111);  // Enable all
    axi_write(32'h8000_2004, 32'd15, 4'b1111);  // Threshold = 15
    
    ext_irq[1] = 1;  // Source 1 (priority 20 > 15)
    repeat (20) @(posedge clk);
    axi_read(32'h8000_2008, rdata);  // Claim
    $display("TB: PLIC Claim = %d (expected 1)", rdata);
    ext_irq[1] = 0;
    repeat (10) @(posedge clk);
    
    // Test 8: Boot ROM
    $display("TB: Test 8 - Boot ROM");
    axi_read(32'h0000_0000, rdata);
    $display("TB: Boot ROM[0] = 0x%08X", rdata);
    axi_read(32'h0000_0004, rdata);
    $display("TB: Boot ROM[1] = 0x%08X", rdata);
    
    $display("TB: Integration test complete");
    $finish;
  end
  
  reg [31:0] rdata;

endmodule