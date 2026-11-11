`timescale 1ns/1ps
//------------------------------------------------------------------------------
// I2S Controller Testbench (Verilog-2001, Icarus-compatible)
// Agent: OpenCode (nemotron-3.5-super-vl-free)
//------------------------------------------------------------------------------
module tb_i2s;

  reg         pclk;
  reg         presetn;
  reg         penable;
  reg         pwrite;
  reg  [31:0] paddr;
  reg  [31:0] pwdata;
  reg  [3:0]  pstrb;
  wire [31:0] prdata_wire;
  reg  [31:0] prdata;
  wire        pready;
  wire        pslverr;
  wire        i2s_bclk;
  wire        i2s_lrclk;
  wire        i2s_dout;
  wire        irq;

  i2s dut (
    .pclk(pclk), .presetn(presetn),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_wire), .pready(pready), .pslverr(pslverr),
    .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk), .i2s_dout(i2s_dout), .i2s_din(i2s_din),
    .irq(irq)
  );

  assign i2s_din = 1'b0;  // no input for this test
  always @(*) prdata = prdata_wire;

  initial pclk = 0;
  always #5 pclk = ~pclk;

  integer errors = 0;

  task apb_write;
    input [31:0] addr;
    input [31:0] data;
    begin
      penable = 1; pwrite = 1; paddr = addr; pwdata = data; pstrb = 4'b1111;
      @(posedge pclk);
      while (!pready) @(posedge pclk);
      penable = 0; pwrite = 0;
      @(posedge pclk);
    end
  endtask

  task apb_read;
    input [31:0] addr;
    output reg [31:0] data;
    begin
      penable = 1; pwrite = 0; paddr = addr; pstrb = 4'b0000;
      @(posedge pclk);
      while (!pready) @(posedge pclk);
      data = prdata_wire;
      penable = 0;
      @(posedge pclk);
    end
  endtask

  initial begin
    $dumpfile("build/sim/tb_i2s.vcd");
    $dumpvars(0, tb_i2s);

    presetn = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (5) @(posedge pclk);

    $display("TB_I2S: Starting I2S test...");

    // Enable I2S
    apb_write(32'h50007000, 32'h00000001);

    // Write sample data
    apb_write(32'h50007004, 32'h00001234);

    apb_read(32'h50007000, prdata);
    $display("TB_I2S: Wrote enable=1, read 0x%08X (bit0=en)", prdata);
    if ((prdata & 32'h1) != 32'h1) begin
      $display("TB_I2S: FAIL - enable mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_I2S: PASS - enable OK");
    end

    apb_read(32'h50007008, prdata);
    $display("TB_I2S: Status = 0x%08X", prdata);

    repeat (20) @(posedge pclk);

    if (errors == 0)
      $display("TB_I2S: ALL TESTS PASSED");
    else
      $display("TB_I2S: %0d ERRORS", errors);

    $finish;
  end

endmodule
