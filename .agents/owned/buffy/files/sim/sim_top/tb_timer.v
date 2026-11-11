`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Timer Testbench (Verilog-2001, Icarus-compatible)
//------------------------------------------------------------------------------
module tb_timer;

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
  wire        irq;

  timer dut (
    .pclk(pclk), .presetn(presetn),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_wire), .pready(pready), .pslverr(pslverr),
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
    $dumpfile("../waveforms/tb_timer.vcd");
    $dumpvars(0, tb_timer);

    presetn = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (5) @(posedge pclk);

    $display("TB_TIMER: Starting timer test...");

    apb_write(32'h50005008, 32'h00000001);
    apb_write(32'h50005004, 32'h00000010);
    apb_read(32'h50005004, prdata);
    $display("TB_TIMER: Wrote compare=0x10, read 0x%08X", prdata);
    if (prdata != 32'h00000010) begin
      $display("TB_TIMER: FAIL - compare mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_TIMER: PASS - compare OK");
    end

    repeat (50) @(posedge pclk);
    apb_read(32'h50005000, prdata);
    $display("TB_TIMER: Counter value = 0x%08X", prdata);

    repeat (20) @(posedge pclk);

    if (errors == 0)
      $display("TB_TIMER: ALL TESTS PASSED");
    else
      $display("TB_TIMER: %0d ERRORS", errors);

    $finish;
  end

endmodule
