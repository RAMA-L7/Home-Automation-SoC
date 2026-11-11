`timescale 1ns/1ps
//------------------------------------------------------------------------------
// GPIO Controller Testbench (Verilog-2001, Icarus-compatible)
//------------------------------------------------------------------------------
module tb_gpio;

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
  wire [15:0] gpio;
  wire        irq;

  gpio #(.WIDTH(16)) dut (
    .pclk(pclk), .presetn(presetn),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_wire), .pready(pready), .pslverr(pslverr),
    .gpio(gpio), .irq(irq)
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
    $dumpfile("../waveforms/tb_gpio.vcd");
    $dumpvars(0, tb_gpio);

    presetn = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (5) @(posedge pclk);

    $display("TB_GPIO: Starting GPIO test...");

    apb_write(32'h50000008, 32'h00000001);
    apb_write(32'h50000000, 32'h00000001);
    apb_read(32'h50000000, prdata);
    $display("TB_GPIO: Wrote 0x00000001, read 0x%08X", prdata);
    if (prdata != 32'h00000001) begin
      $display("TB_GPIO: FAIL - data out mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_GPIO: PASS - data out OK");
    end

    apb_write(32'h50000000, 32'h00000000);
    apb_read(32'h50000000, prdata);
    $display("TB_GPIO: Wrote 0x00000000, read 0x%08X", prdata);
    if (prdata != 32'h00000000) begin
      $display("TB_GPIO: FAIL - data out clear mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_GPIO: PASS - data out clear OK");
    end

    repeat (20) @(posedge pclk);

    if (errors == 0)
      $display("TB_GPIO: ALL TESTS PASSED");
    else
      $display("TB_GPIO: %0d ERRORS", errors);

    $finish;
  end

endmodule
