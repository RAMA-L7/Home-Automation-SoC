//------------------------------------------------------------------------------
// Home-Automation-SoC — UART Testbench
// Stage 4 Verification
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_uart;

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
  
  // UART pins
  wire uart_tx;
  reg  uart_rx;
  
  // Interrupt
  wire irq;
  
  // DUT
  uart #(
    .CLK_FREQ(50_000_000),
    .BAUD(115200)
  ) dut (
    .pclk    (clk),
    .presetn (reset_n),
    .penable (penable),
    .pwrite  (pwrite),
    .paddr   (paddr),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata),
    .pready  (pready),
    .pslverr (pslverr),
    .uart_tx (uart_tx),
    .uart_rx (uart_rx),
    .irq     (irq)
  );
  
  // Clock
  initial clk = 0;
  always #10 clk = ~clk;  // 50 MHz
  
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
  
  // Test sequence
  initial begin
    $dumpfile("waveforms/tb_uart.vcd");
    $dumpvars(0, tb_uart);
    
    // Init
    reset_n = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    uart_rx = 1;
    
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);
    
    $display("TB: UART test started");
    
    // Configure UART: 8N1, no DLAB
    apb_write(32'h0000000C, 32'h03);  // LCR = 8N1
    apb_write(32'h00000004, 32'h00);  // IER = no interrupts
    
    // Test TX
    $display("TB: Testing TX...");
    apb_write(32'h00000000, 32'h41);  // Send 'A'
    apb_write(32'h00000000, 32'h42);  // Send 'B'
    apb_write(32'h00000000, 32'h43);  // Send 'C'
    
    // Wait for TX to complete (roughly 3 * 10 bits * 16 * 50MHz/115200 cycles)
    repeat (200000) @(posedge clk);
    
    // Test RX by driving RX line
    $display("TB: Testing RX...");
    // Send 'X' (0x58) with start/stop bits
    uart_rx = 0;  // Start bit
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 0;  // Bit 0
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 0;  // Bit 1
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 1;  // Bit 2
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 1;  // Bit 3
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 0;  // Bit 4
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 1;  // Bit 5
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 0;  // Bit 6
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 1;  // Bit 7
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    uart_rx = 1;  // Stop bit
    repeat (16 * 50_000_000 / 115_200) @(posedge clk);
    
    // Read received data
    apb_read(32'h00000000, rdata);
    $display("TB: Received 0x%02X", rdata & 8'hFF);
    
    repeat (100) @(posedge clk);
    $display("TB: UART test complete");
    $finish;
  end
  
  reg [31:0] rdata;

endmodule