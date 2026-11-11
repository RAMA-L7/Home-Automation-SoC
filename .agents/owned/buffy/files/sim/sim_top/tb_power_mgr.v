`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Power Manager Testbench (Verilog-2001, Icarus-compatible)
// Agent: OpenCode (nemotron-3.5-super-vl-free)
//------------------------------------------------------------------------------
module tb_power_mgr;

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

  power_mgr_regs dut (
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
    $dumpfile("../waveforms/tb_power_mgr.vcd");
    $dumpvars(0, tb_power_mgr);

    presetn = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (5) @(posedge pclk);

    $display("TB_PWRMGR: Starting power manager test...");

    // Write sleep request = 1
    apb_write(32'h50008000, 32'h00000001);

    // Read back sleep request
    apb_read(32'h50008000, prdata);
    $display("TB_PWRMGR: Wrote sleep_req=1, read 0x%08X", prdata);
    if ((prdata & 32'h1) != 32'h1) begin
      $display("TB_PWRMGR: FAIL - sleep_req mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_PWRMGR: PASS - sleep_req OK");
    end

    // Write wake enable = 1
    apb_write(32'h50008008, 32'h00000001);
    apb_read(32'h50008008, prdata);
    $display("TB_PWRMGR: Wrote wake_en=1, read 0x%08X", prdata);
    if ((prdata & 32'h1) != 32'h1) begin
      $display("TB_PWRMGR: FAIL - wake_en mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_PWRMGR: PASS - wake_en OK");
    end

    repeat (20) @(posedge pclk);

    if (errors == 0)
      $display("TB_PWRMGR: ALL TESTS PASSED");
    else
      $display("TB_PWRMGR: %0d ERRORS", errors);

    $finish;
  end

endmodule
