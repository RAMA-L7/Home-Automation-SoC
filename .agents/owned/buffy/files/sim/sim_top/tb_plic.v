`timescale 1ns/1ps
//------------------------------------------------------------------------------
// PLIC Testbench (Verilog-2001, Icarus-compatible)
// Agent: OpenCode (nemotron-3.5-super-vl-free)
// Simplified test - single cycle read/write
//------------------------------------------------------------------------------
module tb_plic;

  reg         clk;
  reg         reset_n;
  reg         awvalid;
  reg  [15:0] awaddr;
  wire        awready;
  reg         wvalid;
  reg  [31:0] wdata;
  reg  [3:0]  wstrb;
  wire        wready;
  wire        bvalid;
  reg         bready;
  wire [1:0]  bresp;
  reg         arvalid;
  reg  [15:0] araddr;
  wire        arready;
  wire        rvalid;
  reg         rready;
  wire [31:0] rdata_wire;
  reg  [31:0] rdata;
  wire [1:0]  rresp;
  reg  [31:0] ext_irq;
  wire        irq_out;

  plic dut (
    .clk(clk), .reset_n(reset_n),
    .awvalid(awvalid), .awaddr(awaddr), .awready(awready),
    .wvalid(wvalid), .wdata(wdata), .wstrb(wstrb), .wready(wready),
    .bvalid(bvalid), .bready(bready), .bresp(bresp),
    .arvalid(arvalid), .araddr(araddr), .arready(arready),
    .rvalid(rvalid), .rready(rready), .rdata(rdata_wire), .rresp(rresp),
    .ext_irq(ext_irq), .irq_out(irq_out)
  );

  always @(*) rdata = rdata_wire;

  initial clk = 0;
  always #5 clk = ~clk;

  integer errors = 0;

  task do_write;
    input [15:0] addr;
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
    input [15:0] addr;
    output reg [31:0] val;
    begin
      arvalid = 1; araddr = addr;
      repeat (2) @(posedge clk);
      rready = 1;
      repeat (3) @(posedge clk);
      val = rdata_wire;
      arvalid = 0;
      rready = 0;
    end
  endtask

  initial begin
    $dumpfile("../waveforms/tb_plic.vcd");
    $dumpvars(0, tb_plic);

    reset_n = 0;
    awvalid = 0; wvalid = 0; bready = 0;
    arvalid = 0; rready = 0;
    awaddr = 0; wdata = 0; wstrb = 0; araddr = 0;
    ext_irq = 32'd0;
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);

    $display("TB_PLIC: Starting PLIC test...");

    do_write(16'h0000, 32'h00000005);
    do_read(16'h0000, rdata);
    $display("TB_PLIC: Wrote priority=5, read 0x%08X", rdata);
    if ((rdata & 32'hFF) != 32'h05) begin
      $display("TB_PLIC: FAIL - priority mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_PLIC: PASS - priority OK");
    end

    do_write(16'h2000, 32'h00000001);
    do_read(16'h2000, rdata);
    $display("TB_PLIC: Wrote enable=1, read 0x%08X", rdata);
    if (rdata != 32'h00000001) begin
      $display("TB_PLIC: FAIL - enable mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_PLIC: PASS - enable OK");
    end

    ext_irq = 32'h00000001;
    repeat (5) @(posedge clk);
    $display("TB_PLIC: IRQ out after ext_irq[0]=1: %b", irq_out);
    if (irq_out !== 1'b1) begin
      $display("TB_PLIC: FAIL - irq_out should be 1");
      errors = errors + 1;
    end else begin
      $display("TB_PLIC: PASS - irq_out is 1");
    end

    repeat (20) @(posedge clk);

    if (errors == 0)
      $display("TB_PLIC: ALL TESTS PASSED");
    else
      $display("TB_PLIC: %0d ERRORS", errors);

    $finish;
  end

endmodule
