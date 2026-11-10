`timescale 1ns/1ps
//------------------------------------------------------------------------------
// CLINT Testbench (Verilog-2001, Icarus-compatible)
// Agent: OpenCode (nemotron-3.5-super-vl-free)
// Simplified test - single cycle read/write
//------------------------------------------------------------------------------
module tb_clint;

  reg         clk;
  reg         reset_n;
  reg         awvalid;
  reg  [11:0] awaddr;
  wire        awready;
  reg         wvalid;
  reg  [31:0] wdata;
  reg  [3:0]  wstrb;
  wire        wready;
  wire        bvalid;
  reg         bready;
  wire [1:0]  bresp;
  reg         arvalid;
  reg  [11:0] araddr;
  wire        arready;
  wire        rvalid;
  reg         rready;
  wire [31:0] rdata_wire;
  reg  [31:0] rdata;
  wire [1:0]  rresp;
  wire        irq_soft;
  wire        irq_timer;
  wire [63:0] time_out;

  clint dut (
    .clk(clk), .reset_n(reset_n),
    .awvalid(awvalid), .awaddr(awaddr), .awready(awready),
    .wvalid(wvalid), .wdata(wdata), .wstrb(wstrb), .wready(wready),
    .bvalid(bvalid), .bready(bready), .bresp(bresp),
    .arvalid(arvalid), .araddr(araddr), .arready(arready),
    .rvalid(rvalid), .rready(rready), .rdata(rdata_wire), .rresp(rresp),
    .irq_soft(irq_soft), .irq_timer(irq_timer), .time_out(time_out)
  );

  always @(*) rdata = rdata_wire;

  initial clk = 0;
  always #5 clk = ~clk;

  integer errors = 0;

  task do_write;
    input [11:0] addr;
    input [31:0] data;
    begin
      awvalid = 1; awaddr = addr;
      wvalid = 1; wdata = data; wstrb = 4'b1111;
      repeat (2) @(posedge clk);
      awvalid = 0; wvalid = 0;
      repeat (2) @(posedge clk);
    end
  endtask

  task do_read;
    input [11:0] addr;
    output reg [31:0] val;
    begin
      arvalid = 1; araddr = addr;
      repeat (2) @(posedge clk);
      arvalid = 0;
      rready = 1;
      repeat (3) @(posedge clk);
      val = rdata_wire;
      rready = 0;
    end
  endtask

  initial begin
    $dumpfile("../waveforms/tb_clint.vcd");
    $dumpvars(0, tb_clint);

    reset_n = 0;
    awvalid = 0; wvalid = 0; bready = 0;
    arvalid = 0; rready = 0;
    awaddr = 0; wdata = 0; wstrb = 0; araddr = 0;
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);

    $display("TB_CLINT: Starting CLINT test...");

    do_write(12'h000, 32'h00000001);
    do_read(12'h000, rdata);
    $display("TB_CLINT: Wrote MSIP=1, read 0x%08X", rdata);
    if (rdata != 32'h00000001) begin
      $display("TB_CLINT: FAIL - MSIP mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_CLINT: PASS - MSIP OK");
    end

    do_read(12'h7F8, rdata);
    $display("TB_CLINT: MTIME low = 0x%08X", rdata);

    repeat (20) @(posedge clk);

    if (errors == 0)
      $display("TB_CLINT: ALL TESTS PASSED");
    else
      $display("TB_CLINT: %0d ERRORS", errors);

    $finish;
  end

endmodule
