`timescale 1ns/1ps
//------------------------------------------------------------------------------
// PWM Controller Testbench (Verilog-2001, Icarus-compatible)
//------------------------------------------------------------------------------
module tb_pwm;

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
  wire [3:0]  pwm_out;
  wire        irq;

  pwm #(.WIDTH(16), .CHANNELS(4)) dut (
    .pclk(pclk), .presetn(presetn),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_wire), .pready(pready), .pslverr(pslverr),
    .pwm_out(pwm_out), .irq(irq)
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
    $dumpfile("../waveforms/tb_pwm.vcd");
    $dumpvars(0, tb_pwm);

    presetn = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (5) @(posedge pclk);

    $display("TB_PWM: Starting PWM test...");

    // Enable channel 0
    apb_write(32'h50004020, 32'h00000001);

    // Set period = 100, duty = 50 (50%)
    apb_write(32'h50004000, 32'h00000064);   // PWM0_PERIOD = 100
    apb_write(32'h50004004, 32'h00000032);   // PWM0_DUTY = 50

    apb_read(32'h50004000, prdata);
    $display("TB_PWM: Wrote period=100, read 0x%08X", prdata);
    if (prdata != 32'h00000064) begin
      $display("TB_PWM: FAIL - period mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_PWM: PASS - period OK");
    end

    apb_read(32'h50004004, prdata);
    $display("TB_PWM: Wrote duty=50, read 0x%08X", prdata);
    if (prdata != 32'h00000032) begin
      $display("TB_PWM: FAIL - duty mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_PWM: PASS - duty OK");
    end

    // Run for some cycles to see PWM toggle
    repeat (300) @(posedge pclk);

    // Read control register
    apb_read(32'h50004020, prdata);
    $display("TB_PWM: Control register = 0x%08X (bit0=en)", prdata);
    if ((prdata & 32'h1) != 32'h1) begin
      $display("TB_PWM: FAIL - channel not enabled");
      errors = errors + 1;
    end else begin
      $display("TB_PWM: PASS - channel enabled");
    end

    repeat (20) @(posedge pclk);

    if (errors == 0)
      $display("TB_PWM: ALL TESTS PASSED");
    else
      $display("TB_PWM: %0d ERRORS", errors);

    $finish;
  end

endmodule
