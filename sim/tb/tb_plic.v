//------------------------------------------------------------------------------
// Home-Automation-SoC — PLIC Testbench
// Stage 4 Verification
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_plic;

  reg clk;
  reg reset_n;
  
  // APB-like interface (simplified)
  reg        awvalid;
  reg [15:0] awaddr;
  wire       awready;
  reg        wvalid;
  wire       wready;
  reg [31:0] wdata;
  reg [3:0]  wstrb;
  wire       bvalid;
  reg        bready;
  wire [1:0] bresp;
  reg        arvalid;
  reg [15:0] araddr;
  wire       arready;
  wire       rvalid;
  reg        rready;
  wire [31:0] rdata;
  wire [1:0] rresp;
  
  // External interrupts
  reg [31:0] ext_irq;
  
  // Output interrupt
  wire irq_out;
  
  // DUT
  plic dut (
    .clk      (clk),
    .reset_n  (reset_n),
    .awvalid  (awvalid),
    .awaddr   (awaddr),
    .awready  (awready),
    .wvalid   (wvalid),
    .wready   (wready),
    .wdata    (wdata),
    .wstrb    (wstrb),
    .bvalid   (bvalid),
    .bready   (bready),
    .bresp    (bresp),
    .arvalid  (arvalid),
    .araddr   (araddr),
    .arready  (arready),
    .rvalid   (rvalid),
    .rready   (rready),
    .rdata    (rdata),
    .rresp    (rresp),
    .ext_irq  (ext_irq),
    .irq_out  (irq_out)
  );
  
  // Clock
  initial clk = 0;
  always #10 clk = ~clk;  // 50 MHz
  
  // Tasks
  task plic_write(input [15:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      awvalid = 1; awaddr = addr;
      wvalid = 1; wdata = data; wstrb = 4'b1111;
      bready = 1;
      @(posedge clk);
      while (!bvalid) @(posedge clk);
      awvalid = 0; wvalid = 0; bready = 0;
      @(posedge clk);
    end
  endtask
  
  task plic_read(input [15:0] addr, output [31:0] data);
    begin
      @(posedge clk);
      arvalid = 1; araddr = addr;
      rready = 1;
      @(posedge clk);
      while (!rvalid) @(posedge clk);
      data = rdata;
      arvalid = 0; rready = 0;
      @(posedge clk);
    end
  endtask
  
  // Test sequence
  initial begin
    $dumpfile("waveforms/tb_plic.vcd");
    $dumpvars(0, tb_plic);
    
    // Init
    reset_n = 0;
    awvalid = 0; awaddr = 0;
    wvalid = 0; wdata = 0; wstrb = 0;
    bready = 0;
    arvalid = 0; araddr = 0;
    rready = 0;
    ext_irq = 32'd0;
    
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);
    
    $display("TB: PLIC test started");
    
    // Test 1: Set priorities
    $display("TB: Test 1 - Set priorities");
    plic_write(16'h0000, 32'd10);  // Source 0 priority = 10
    plic_write(16'h0004, 32'd20);  // Source 1 priority = 20
    plic_write(16'h0008, 32'd5);   // Source 2 priority = 5
    plic_write(16'h000C, 32'd30);  // Source 3 priority = 30
    
    plic_read(16'h0000, rdata);
    $display("TB: Priority 0 = %d", rdata);
    plic_read(16'h0004, rdata);
    $display("TB: Priority 1 = %d", rdata);
    plic_read(16'h0008, rdata);
    $display("TB: Priority 2 = %d", rdata);
    plic_read(16'h000C, rdata);
    $display("TB: Priority 3 = %d", rdata);
    
    // Test 2: Enable all sources
    $display("TB: Test 2 - Enable sources");
    plic_write(16'h2000, 32'h0F);  // Enable bits 0-3
    plic_read(16'h2000, rdata);
    $display("TB: Enable = 0x%02X", rdata);
    
    // Test 3: Set threshold
    $display("TB: Test 3 - Set threshold");
    plic_write(16'h2004, 32'd15);  // Threshold = 15
    plic_read(16'h2004, rdata);
    $display("TB: Threshold = %d", rdata);
    
    // Test 4: Trigger interrupt source 0 (priority 10 < threshold 15 -> no interrupt)
    $display("TB: Test 4 - Source 0 (prio 10 < thresh 15)");
    ext_irq[0] = 1;
    repeat (10) @(posedge clk);
    $display("TB: irq_out = %b (expected 0)", irq_out);
    ext_irq[0] = 0;
    repeat (10) @(posedge clk);
    
    // Test 5: Trigger interrupt source 1 (priority 20 > threshold 15 -> interrupt)
    $display("TB: Test 5 - Source 1 (prio 20 > thresh 15)");
    ext_irq[1] = 1;
    repeat (10) @(posedge clk);
    $display("TB: irq_out = %b (expected 1)", irq_out);
    
    // Claim interrupt
    plic_read(16'h2008, rdata);
    $display("TB: Claim ID = %d (expected 1)", rdata);
    
    ext_irq[1] = 0;
    repeat (10) @(posedge clk);
    $display("TB: irq_out = %b (expected 0)", irq_out);
    
    // Test 6: Trigger source 3 (priority 30, highest)
    $display("TB: Test 6 - Source 3 (prio 30)");
    ext_irq[3] = 1;
    repeat (10) @(posedge clk);
    $display("TB: irq_out = %b (expected 1)", irq_out);
    plic_read(16'h2008, rdata);
    $display("TB: Claim ID = %d (expected 3)", rdata);
    ext_irq[3] = 0;
    repeat (10) @(posedge clk);
    
    // Test 7: Preemption - lower priority interrupts while handling higher
    $display("TB: Test 7 - Preemption test");
    plic_write(16'h2004, 32'd0);  // Threshold = 0 (accept all)
    
    ext_irq[0] = 1;  // Priority 10
    repeat (10) @(posedge clk);
    plic_read(16'h2008, rdata);
    $display("TB: Claim ID = %d (expected 0)", rdata);
    
    ext_irq[2] = 1;  // Priority 5
    ext_irq[1] = 1;  // Priority 20
    repeat (10) @(posedge clk);
    plic_read(16'h2008, rdata);
    $display("TB: Claim ID = %d (expected 1 - preempted)", rdata);
    
    $display("TB: PLIC test complete");
    $finish;
  end
  
  reg [31:0] rdata;

endmodule