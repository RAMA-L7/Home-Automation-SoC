`timescale 1ns/1ps
//------------------------------------------------------------------------------
// I2C Controller Testbench (Verilog-2001, Icarus-compatible)
//------------------------------------------------------------------------------
module tb_i2c;

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
  wire        i2c_scl;
  wire        i2c_sda;
  wire        irq;

  i2c_ctrl dut (
    .pclk(pclk), .presetn(presetn),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_wire), .pready(pready), .pslverr(pslverr),
    .i2c_scl(i2c_scl), .i2c_sda(i2c_sda),
    .irq(irq)
  );

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
    $dumpfile("build/sim/tb_i2c.vcd");
    $dumpvars(0, tb_i2c);

    presetn = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (5) @(posedge pclk);

    $display("TB_I2C: Starting I2C test...");

    // Enable I2C
    apb_write(32'h50002000, 32'h00000001);

    // Set slave address
    apb_write(32'h50002004, 32'h00000050);   // slave_addr = 0x50

    apb_read(32'h50002000, prdata);
    $display("TB_I2C: Wrote enable=1, read 0x%08X (bit0=en)", prdata);
    if ((prdata & 32'h1) != 32'h1) begin
      $display("TB_I2C: FAIL - enable mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_I2C: PASS - enable OK");
    end

    apb_read(32'h50002004, prdata);
    $display("TB_I2C: Wrote slave_addr=0x50, read 0x%08X", prdata);
    if ((prdata & 32'h7F) != 32'h50) begin
      $display("TB_I2C: FAIL - slave_addr mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_I2C: PASS - slave_addr OK");
    end

    repeat (20) @(posedge pclk);

    if (errors == 0)
      $display("TB_I2C: ALL TESTS PASSED");
    else
      $display("TB_I2C: %0d ERRORS", errors);

    $finish;
  end

endmodule
