//------------------------------------------------------------------------------
// Home-Automation-SoC — SPI Master Testbench
// Stage 4 Verification
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_spi;

  reg clk;
  reg reset_n;
  
  // APB interface
  reg        penable;
  reg        pwrite;
  reg [31:0] paddr;
  reg [31:0] pwdata;
  reg [3:0]  pstrb;
  wire [31:0] prdata;
  wire        pready;
  wire        pslverr;
  
  // SPI pins
  wire spi_sck;
  wire spi_mosi;
  reg  spi_miso;
  wire spi_cs_n;
  
  // DUT
  spi_ctrl #(
    .CLK_FREQ(50_000_000),
    .SPI_FREQ_MAX(25_000_000)
  ) dut (
    .pclk     (clk),
    .presetn  (reset_n),
    .penable  (penable),
    .pwrite   (pwrite),
    .paddr    (paddr),
    .pwdata   (pwdata),
    .pstrb    (pstrb),
    .prdata   (prdata),
    .pready   (pready),
    .pslverr  (pslverr),
    .spi_sck  (spi_sck),
    .spi_mosi (spi_mosi),
    .spi_miso (spi_miso),
    .spi_cs_n (spi_cs_n)
  );
  
  // Clock
  initial clk = 0;
  always #10 clk = ~clk;  // 50 MHz
  
  // Simple SPI slave model
  reg [7:0] slave_rx_data;
  reg [7:0] slave_tx_data;
  reg [3:0] slave_bit_cnt;
  reg       slave_sck_prev;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      slave_sck_prev <= 1'b0;
      slave_bit_cnt <= 4'd0;
      slave_rx_data <= 8'd0;
      spi_miso <= 1'b1;
    end else begin
      slave_sck_prev <= spi_sck;
      
      if (!spi_cs_n) begin
        // Detect rising edge of SCK (Mode 0: sample on rising, change on falling)
        if (!slave_sck_prev && spi_sck) begin
          slave_rx_data <= {slave_rx_data[6:0], spi_mosi};
          slave_bit_cnt <= slave_bit_cnt + 1;
          
          // Output MISO on falling edge (prepare for next rising edge)
          if (slave_bit_cnt < 8) begin
            spi_miso <= slave_tx_data[7 - slave_bit_cnt];
          end
        end
        
        // Detect falling edge of SCK
        if (slave_sck_prev && !spi_sck) begin
          // Could update MISO here for next bit
        end
      end else begin
        slave_bit_cnt <= 4'd0;
        spi_miso <= 1'b1;
      end
    end
  end
  
  // Tasks
  task apb_write(input [31:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      penable = 1; pwrite = 1; paddr = addr; pwdata = data; pstrb = 4'b1111;
      @(posedge clk);
      penable = 0;
      @(posedge clk);
    end
  endtask
  
  task apb_read(input [31:0] addr, output [31:0] data);
    begin
      @(posedge clk);
      penable = 1; pwrite = 0; paddr = addr; pstrb = 4'b1111;
      @(posedge clk);
      data = prdata;
      penable = 0;
      @(posedge clk);
    end
  endtask
  
  task spi_transfer(input [7:0] tx_byte, output [7:0] rx_byte);
    begin
      slave_tx_data = tx_byte;
      // Write to TX register
      apb_write(32'h00000000, {24'd0, tx_byte});
      
      // Wait for transfer complete (poll status)
      repeat (500) @(posedge clk);
      
      // Read RX register
      apb_read(32'h00000000, rx_data);
      rx_byte = rx_data[7:0];
    end
  endtask
  
  // Test sequence
  initial begin
    $dumpfile("waveforms/tb_spi.vcd");
    $dumpvars(0, tb_spi);
    
    // Init
    reset_n = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    spi_miso = 1;
    
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);
    
    $display("TB: SPI test started");
    
    // Configure SPI: Mode 0, 1 MHz, CS0
    apb_write(32'h00000004, 32'h00000001);  // CTRL: enable, mode 0
    apb_write(32'h00000008, 32'h00000019);  // CLK_DIV: 50MHz/25 = 2MHz
    
    // Test 1: Simple byte transfer
    $display("TB: Test 1 - Byte transfer");
    slave_tx_data = 8'h55;  // Slave will send 0x55
    apb_write(32'h00000000, 32'h000000AA);  // Master sends 0xAA
    
    // Wait for transfer (8 bits * 25 cycles/bit = 200 cycles + overhead)
    repeat (500) @(posedge clk);
    
    apb_read(32'h00000000, rdata);
    $display("TB: Master RX = 0x%02X (expected 0x55)", rdata & 8'hFF);
    
    // Test 2: Multiple bytes
    $display("TB: Test 2 - Multiple bytes");
    slave_tx_data = 8'h12;
    apb_write(32'h00000000, 32'h00000034);
    repeat (500) @(posedge clk);
    apb_read(32'h00000000, rdata);
    $display("TB: RX = 0x%02X", rdata & 8'hFF);
    
    slave_tx_data = 8'h34;
    apb_write(32'h00000000, 32'h00000056);
    repeat (500) @(posedge clk);
    apb_read(32'h00000000, rdata);
    $display("TB: RX = 0x%02X", rdata & 8'hFF);
    
    slave_tx_data = 8'h56;
    apb_write(32'h00000000, 32'h00000078);
    repeat (500) @(posedge clk);
    apb_read(32'h00000000, rdata);
    $display("TB: RX = 0x%02X", rdata & 8'hFF);
    
    // Test 3: CS control
    $display("TB: Test 3 - CS control");
    apb_write(32'h0000000C, 32'h00000002);  // CS_SEL = CS1
    apb_write(32'h00000000, 32'h00000099);
    repeat (500) @(posedge clk);
    
    apb_write(32'h0000000C, 32'h00000000);  // CS_SEL = CS0
    apb_write(32'h00000000, 32'h000000BB);
    repeat (500) @(posedge clk);
    
    $display("TB: SPI test complete");
    $finish;
  end
  
  reg [31:0] rdata;
  reg [31:0] rx_data;
  reg [7:0] rx_byte;

endmodule