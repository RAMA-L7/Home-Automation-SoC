`timescale 1ns/1ps
//------------------------------------------------------------------------------
// CLINT Testbench (Verilog-2001, Icarus-compatible)
// Uses register-port interface (wr_en/wr_addr/wr_data/rd_addr/rd_data)
// matches clint.sv after Buffy's rewrite
//------------------------------------------------------------------------------
module tb_clint;

  reg         clk;
  reg         reset_n;

  // Register port
  reg         wr_en;
  reg  [11:0] wr_addr;
  reg  [31:0] wr_data;
  reg  [11:0] rd_addr;
  wire [31:0] rd_data_wire;
  reg  [31:0] rd_data;

  // Interrupts / time
  wire        irq_soft;
  wire        irq_timer;
  wire [63:0] time_out;

  clint dut (
    .clk(clk), .reset_n(reset_n),
    .wr_en(wr_en), .wr_addr(wr_addr), .wr_data(wr_data),
    .rd_addr(rd_addr), .rd_data(rd_data_wire),
    .irq_soft(irq_soft), .irq_timer(irq_timer), .time_out(time_out)
  );

  always @(*) rd_data = rd_data_wire;

  initial clk = 0;
  always #5 clk = ~clk;

  integer errors = 0;

  task do_write;
    input [11:0] addr;
    input [31:0] data;
    begin
      wr_en = 1; wr_addr = addr; wr_data = data;
      @(posedge clk);
      wr_en = 0;
      @(posedge clk);
    end
  endtask

  task do_read;
    input [11:0] addr;
    output reg [31:0] val;
    begin
      rd_addr = addr;
      @(posedge clk);
      val = rd_data_wire;
      @(posedge clk);
    end
  endtask

  initial begin
    $dumpfile("build/sim/tb_clint.vcd");
    $dumpvars(0, tb_clint);

    reset_n = 0;
    wr_en = 0;
    wr_addr = 0; wr_data = 0; rd_addr = 0;
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);

    $display("TB_CLINT: Starting CLINT test...");

    // Write MSIP = 1 at offset 0x000
    do_write(12'h000, 32'h00000001);
    do_read(12'h000, rd_data);
    $display("TB_CLINT: Wrote MSIP=1, read 0x%08X", rd_data);
    if (rd_data != 32'h00000001) begin
      $display("TB_CLINT: FAIL - MSIP mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_CLINT: PASS - MSIP OK");
    end

    // Read MTIME low at offset 0x7F8
    do_read(12'h7F8, rd_data);
    $display("TB_CLINT: MTIME low = 0x%08X", rd_data);

    // Check irq_soft is asserted (MSIP=1)
    $display("TB_CLINT: irq_soft = %b", irq_soft);
    if (irq_soft !== 1'b1) begin
      $display("TB_CLINT: FAIL - irq_soft should be 1");
      errors = errors + 1;
    end else begin
      $display("TB_CLINT: PASS - irq_soft OK");
    end

    repeat (20) @(posedge clk);

    if (errors != 0) begin
      $display("TB_CLINT: %0d ERRORS", errors);
      $fatal(1, "TB_CLINT: failed");
    end
    $display("TB_CLINT: ALL TESTS PASSED");
    $finish;
  end

endmodule
