`timescale 1ns/1ps
//------------------------------------------------------------------------------
// PLIC Testbench (Verilog-2001, Icarus-compatible)
// Uses register-port interface (wr_en/wr_addr/wr_data/rd_addr/rd_data)
// matches plic.sv after Buffy's rewrite
//------------------------------------------------------------------------------
module tb_plic;

  reg         clk;
  reg         reset_n;

  // Register port
  reg         wr_en;
  reg  [11:0] wr_addr;
  reg  [31:0] wr_data;
  reg  [11:0] rd_addr;
  wire [31:0] rd_data_wire;
  reg  [31:0] rd_data;

  // Interrupts
  reg  [7:0]  ext_irq;
  wire        irq_out;

  plic #(.NUM_SOURCES(8)) dut (
    .clk(clk), .reset_n(reset_n),
    .wr_en(wr_en), .wr_addr(wr_addr), .wr_data(wr_data),
    .rd_addr(rd_addr), .rd_data(rd_data_wire),
    .ext_irq(ext_irq), .irq_out(irq_out)
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
    $dumpfile("build/sim/tb_plic.vcd");
    $dumpvars(0, tb_plic);

    reset_n = 0;
    wr_en = 0;
    wr_addr = 0; wr_data = 0; rd_addr = 0;
    ext_irq = 8'd0;
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);

    $display("TB_PLIC: Starting PLIC test...");

    // Write priority[0] = 5 at offset 0x004
    do_write(12'h004, 32'h00000005);
    do_read(12'h004, rd_data);
    $display("TB_PLIC: Wrote priority[0]=5, read 0x%08X", rd_data);
    if ((rd_data & 32'hFF) != 32'h05) begin
      $display("TB_PLIC: FAIL - priority mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_PLIC: PASS - priority OK");
    end

    // Write enable = 1 at offset 0x200
    do_write(12'h200, 32'h00000001);
    do_read(12'h200, rd_data);
    $display("TB_PLIC: Wrote enable=1, read 0x%08X", rd_data);
    if (rd_data != 32'h00000001) begin
      $display("TB_PLIC: FAIL - enable mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_PLIC: PASS - enable OK");
    end

    // Assert external IRQ source 0
    ext_irq = 8'h01;
    repeat (5) @(posedge clk);
    $display("TB_PLIC: IRQ out after ext_irq[0]=1: %b", irq_out);
    if (irq_out !== 1'b1) begin
      $display("TB_PLIC: FAIL - irq_out should be 1");
      errors = errors + 1;
    end else begin
      $display("TB_PLIC: PASS - irq_out is 1");
    end

    repeat (20) @(posedge clk);

    if (errors != 0) begin
      $display("TB_PLIC: %0d ERRORS", errors);
      $fatal(1, "TB_PLIC: failed");
    end
    $display("TB_PLIC: ALL TESTS PASSED");
    $finish;
  end

endmodule
