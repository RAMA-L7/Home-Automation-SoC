//------------------------------------------------------------------------------
// Home-Automation-SoC — GPIO Testbench
// Stage 4 Verification
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_gpio;

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
  
  // GPIO pads
  wire [15:0] gpio;
  
  // Interrupt
  wire irq;
  
  // Test stimulus
  reg [15:0] gpio_drive;
  reg [15:0] gpio_drive_en;
  
  genvar i;
  generate
    for (i = 0; i < 16; i++) begin : g_pad
      assign gpio[i] = gpio_drive_en[i] ? gpio_drive[i] : 1'bz;
    end
  endgenerate
  
  // DUT
  gpio #(
    .WIDTH(16)
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
    .gpio    (gpio),
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
    $dumpfile("waveforms/tb_gpio.vcd");
    $dumpvars(0, tb_gpio);
    
    // Init
    reset_n = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    gpio_drive = 16'h0000;
    gpio_drive_en = 16'h0000;
    
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);
    
    $display("TB: GPIO test started");
    
    // Test 1: Configure GPIO[0:3] as outputs
    $display("TB: Test 1 - Output mode");
    apb_write(32'h00000008, 32'h0000000F);  // OE = 0x000F (pins 0-3 output)
    apb_read(32'h00000008, rdata);
    $display("TB: OE = 0x%04X", rdata & 16'hFFFF);
    
    // Write output data
    apb_write(32'h00000000, 32'h00000005);  // DATA_OUT = 0x5 (pins 0,2 high)
    apb_read(32'h00000000, rdata);
    $display("TB: DATA_OUT = 0x%04X", rdata & 16'hFFFF);
    
    // Read back input (should reflect outputs since we're driving)
    repeat (5) @(posedge clk);
    apb_read(32'h00000004, rdata);
    $display("TB: DATA_IN = 0x%04X", rdata & 16'hFFFF);
    
    // Test 2: Configure GPIO[8:11] as inputs, drive external values
    $display("TB: Test 2 - Input mode");
    apb_write(32'h00000008, 32'h0000000F);  // OE = 0x000F (pins 0-3 output, rest input)
    gpio_drive_en = 16'h0F00;  // Drive pins 8-11
    gpio_drive = 16'h0A00;     // Pattern 1010 on pins 8-11
    repeat (5) @(posedge clk);
    apb_read(32'h00000004, rdata);
    $display("TB: DATA_IN[11:8] = 0x%01X (expected 0xA)", (rdata >> 8) & 4'hF);
    
    // Test 3: Interrupt on rising edge
    $display("TB: Test 3 - Rising edge interrupt");
    apb_write(32'h0000000C, 32'h00000100);  // INT_EN pin 8
    apb_write(32'h00000010, 32'h00000100);  // INT_RISE pin 8
    apb_write(32'h00000014, 32'h00000000);  // INT_FALL none
    
    // Drive pin 8 low, then high (rising edge)
    gpio_drive[8] = 0;
    repeat (5) @(posedge clk);
    gpio_drive[8] = 1;
    repeat (5) @(posedge clk);
    
    apb_read(32'h00000018, rdata);
    $display("TB: INT_PEND after rising edge = 0x%04X", rdata & 16'hFFFF);
    
    // Clear interrupt
    apb_write(32'h00000018, 32'h00000100);  // Write 1 to clear
    apb_read(32'h00000018, rdata);
    $display("TB: INT_PEND after clear = 0x%04X", rdata & 16'hFFFF);
    
    // Test 4: Interrupt on falling edge
    $display("TB: Test 4 - Falling edge interrupt");
    apb_write(32'h00000014, 32'h00000200);  // INT_FALL pin 9
    
    // Drive pin 9 high, then low (falling edge)
    gpio_drive[9] = 1;
    repeat (5) @(posedge clk);
    gpio_drive[9] = 0;
    repeat (5) @(posedge clk);
    
    apb_read(32'h00000018, rdata);
    $display("TB: INT_PEND after falling edge = 0x%04X", rdata & 16'hFFFF);
    
    // Test 5: Toggle output
    $display("TB: Test 5 - Toggle output");
    repeat (10) begin
      apb_write(32'h00000000, 32'h00000001);  // Pin 0 high
      repeat (20) @(posedge clk);
      apb_write(32'h00000000, 32'h00000000);  // Pin 0 low
      repeat (20) @(posedge clk);
    end
    
    $display("TB: GPIO test complete");
    $finish;
  end
  
  reg [31:0] rdata;

endmodule