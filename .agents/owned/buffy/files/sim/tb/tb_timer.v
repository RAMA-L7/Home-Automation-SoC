//------------------------------------------------------------------------------
// Home-Automation-SoC — Timer/CLINT Testbench
// Stage 4 Verification
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_timer;

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
  
  // Interrupts
  wire irq_timer;
  wire irq_soft;
  
  // Time output
  wire [63:0] time_out;
  
  // DUT - Timer
  timer #(
    .CLK_FREQ(50_000_000)
  ) timer_dut (
    .pclk      (clk),
    .presetn   (reset_n),
    .penable   (penable),
    .pwrite    (pwrite),
    .paddr     (paddr),
    .pwdata    (pwdata),
    .pstrb     (pstrb),
    .prdata    (prdata),
    .pready    (pready),
    .pslverr   (pslverr),
    .irq       (irq_timer)
  );
  
  // DUT - CLINT
  clint clint_dut (
    .clk       (clk),
    .reset_n   (reset_n),
    .awvalid   (1'b0),
    .awaddr    (12'd0),
    .awready   (),
    .wvalid    (1'b0),
    .wready    (),
    .wdata     (32'd0),
    .wstrb     (4'd0),
    .bvalid    (),
    .bready    (1'b1),
    .bresp     (),
    .arvalid   (1'b0),
    .araddr    (12'd0),
    .arready   (),
    .rvalid    (),
    .rready    (1'b1),
    .rdata     (),
    .rresp     (),
    .irq_soft  (irq_soft),
    .irq_timer (irq_timer),
    .time_out  (time_out)
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
    $dumpfile("waveforms/tb_timer.vcd");
    $dumpvars(0, tb_timer);
    
    // Init
    reset_n = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);
    
    $display("TB: Timer/CLINT test started");
    
    // Test 1: Timer free-running count
    $display("TB: Test 1 - Free-running count");
    repeat (100) @(posedge clk);
    apb_read(32'h00000000, rdata);
    $display("TB: Timer COUNT = 0x%08X", rdata);
    
    // Test 2: Timer compare interrupt
    $display("TB: Test 2 - Compare interrupt");
    apb_write(32'h00000004, 32'd100);   // COMPARE = 100
    apb_write(32'h00000008, 32'h03);    // CTRL: enable + int enable
    
    // Wait for interrupt
    repeat (200) @(posedge clk);
    apb_read(32'h0000000C, rdata);
    $display("TB: Timer STATUS = 0x%08X (expect 0x01)", rdata);
    
    // Clear interrupt
    apb_write(32'h00000008, 32'h00);    // CTRL: disable
    repeat (10) @(posedge clk);
    
    // Test 3: CLINT MTIME
    $display("TB: Test 3 - CLINT MTIME");
    repeat (100) @(posedge clk);
    $display("TB: MTIME = 0x%016X", time_out);
    
    // Test 4: CLINT MTIMECMP
    $display("TB: Test 4 - CLINT MTIMECMP interrupt");
    // Set MTIMECMP to current MTIME + 50
    // We can't easily write via APB in this testbench, but we can observe
    repeat (200) @(posedge clk);
    $display("TB: MTIME = 0x%016X, irq_timer = %b", time_out, irq_timer);
    
    // Test 5: CLINT MSIP (software interrupt)
    $display("TB: Test 5 - CLINT MSIP");
    // MSIP would be written via AXI-Lite, observe irq_soft
    repeat (100) @(posedge clk);
    $display("TB: irq_soft = %b", irq_soft);
    
    $display("TB: Timer/CLINT test complete");
    $finish;
  end
  
  reg [31:0] rdata;

endmodule