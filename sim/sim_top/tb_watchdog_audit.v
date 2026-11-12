`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Watchdog independent audit testbench
//
// Written to be sensitive to the phase-2 reload defect: when the count-down
// was not gated by the APB write, `count <= pwdata` was overwritten by
// `count <= count - 1` in the same cycle and a pet silently failed to restart
// the period.  The existing tb_watchdog.v does not catch that mutant; this one
// does (T2), and it also covers the rest of the audited behaviours.
//
// Register map: 0x00 LOAD, 0x04 CTRL (bit0 enable, bit1 reset_en),
//               0x08 STATUS (bit0 expired), 0x0C LOCK (0x5A5A0001).
//------------------------------------------------------------------------------
module tb_watchdog_audit;

  reg         pclk = 0;
  reg         presetn;
  reg         penable, pwrite;
  reg  [31:0] paddr, pwdata;
  reg  [3:0]  pstrb;
  wire [31:0] prdata;
  wire        pready, pslverr, irq, reset_n_out;

  always #5 pclk = ~pclk;

  watchdog dut (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb), .prdata(prdata),
    .pready(pready), .pslverr(pslverr), .irq(irq), .reset_n_out(reset_n_out)
  );

  integer errors = 0;
  integer checks = 0;

  task apb_write(input [31:0] a, input [31:0] d);
    begin
      @(negedge pclk);
      paddr = a; pwdata = d; pwrite = 1; pstrb = 4'hF; penable = 0;
      @(negedge pclk); penable = 1;
      @(negedge pclk); penable = 0; pwrite = 0;
      if (!pready) begin
        $display("[wdog] FAIL pready low writing %h", a);
        errors = errors + 1;
      end
    end
  endtask

  task apb_read(input [31:0] a, output [31:0] d);
    begin
      @(negedge pclk);
      paddr = a; pwrite = 0; pstrb = 4'hF; penable = 0;
      @(negedge pclk); penable = 1;
      @(negedge pclk); d = prdata; penable = 0;
    end
  endtask

  task check(input cond, input [255:0] msg);
    begin
      checks = checks + 1;
      if (!cond) begin
        $display("[wdog] FAIL %0s", msg);
        errors = errors + 1;
      end else begin
        $display("[wdog] pass %0s", msg);
      end
    end
  endtask

  reg [31:0] rd;
  integer    i;

  task hard_reset;
    begin
      presetn = 0; penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
      repeat (3) @(posedge pclk);
      presetn = 1;
      repeat (2) @(posedge pclk);
    end
  endtask

  initial begin
    $dumpfile("build/sim/tb_watchdog_audit.vcd");
    $dumpvars(0, tb_watchdog_audit);

    hard_reset;

    // T1 — reset values
    apb_read(32'h00, rd);
    check(rd == 32'd0, "T1 LOAD reset value 0");
    apb_read(32'h04, rd);
    check(rd[1:0] == 2'b00, "T1 CTRL reset value 0");
    check(irq == 1'b0 && reset_n_out == 1'b1, "T1 irq/reset_n_out idle after reset");

    // T2 — a pet restarts the period (this is the reload-priority check)
    apb_write(32'h00, 32'd10);          // LOAD=10
    apb_write(32'h04, 32'h1);           // enable
    repeat (5) @(posedge pclk);
    apb_read(32'h08, rd);
    check(rd[0] == 1'b0, "T2 not expired mid-period");
    apb_write(32'h00, 32'd10);          // pet
    repeat (8) @(posedge pclk);
    apb_read(32'h08, rd);
    check(rd[0] == 1'b0, "T2 pet restarted the period (still not expired)");
    repeat (6) @(posedge pclk);
    apb_read(32'h08, rd);
    check(rd[0] == 1'b1, "T2 expires after the reloaded period");

    // T3 — expiry is sticky until a LOAD write clears it
    repeat (4) @(posedge pclk);
    apb_read(32'h08, rd);
    check(rd[0] == 1'b1, "T3 expired stays set");
    check(irq == 1'b1, "T3 irq asserted on expiry");
    apb_write(32'h00, 32'd20);
    apb_read(32'h08, rd);
    check(rd[0] == 1'b0, "T3 LOAD clears expired");
    check(irq == 1'b0, "T3 irq cleared by LOAD");

    // T4 — LOAD while disabled does not start counting
    apb_write(32'h04, 32'h0);           // disable
    apb_write(32'h00, 32'd5);
    repeat (12) @(posedge pclk);
    apb_read(32'h08, rd);
    check(rd[0] == 1'b0, "T4 no expiry while disabled");

    // T5 — reset_en drives reset_n_out during expiry
    apb_write(32'h04, 32'h3);           // enable + reset_en
    repeat (12) @(posedge pclk);
    apb_read(32'h08, rd);
    check(rd[0] == 1'b1, "T5 expired with reset_en");
    check(reset_n_out == 1'b0, "T5 reset_n_out asserted on expiry");

    // T6 — lock blocks CTRL writes but not LOAD
    hard_reset;
    apb_write(32'h0C, 32'h5A5A_0001);   // lock
    apb_write(32'h04, 32'h1);           // ignored
    apb_read(32'h04, rd);
    check(rd[0] == 1'b0, "T6 CTRL write ignored while locked");
    apb_write(32'h00, 32'd7);           // LOAD still allowed
    apb_read(32'h00, rd);
    check(rd == 32'd7, "T6 LOAD writable while locked");
    apb_read(32'h0C, rd);
    check(rd[0] == 1'b1, "T6 lock bit set");

    // T7 — reset during countdown
    hard_reset;
    apb_write(32'h00, 32'd50);
    apb_write(32'h04, 32'h1);
    repeat (6) @(posedge pclk);
    presetn = 0;
    repeat (2) @(posedge pclk);
    check(dut.count == 32'd0 && dut.enable == 1'b0 && dut.expired == 1'b0,
          "T7 reset during countdown clears state");
    presetn = 1;
    repeat (3) @(posedge pclk);

    // T8 — reset asserted while an APB transaction is in flight
    @(negedge pclk);
    paddr = 32'h00; pwdata = 32'd99; pwrite = 1; pstrb = 4'hF; penable = 1;
    @(negedge pclk);
    presetn = 0;
    repeat (2) @(posedge pclk);
    presetn = 1;
    penable = 0; pwrite = 0;
    apb_read(32'h00, rd);
    check(rd == 32'd0, "T8 reset during APB access leaves no written state");

    // T9 — back-to-back LOAD writes while enabled keep reloading
    apb_write(32'h04, 32'h1);
    for (i = 0; i < 6; i = i + 1) begin
      apb_write(32'h00, 32'd4);
      repeat (2) @(posedge pclk);
    end
    apb_read(32'h08, rd);
    check(rd[0] == 1'b0, "T9 repeated pets keep the watchdog from expiring");

    $display("WATCHDOG AUDIT: %0d checks run, %0d failures", checks, errors);
    if (errors == 0) begin
      $display("WATCHDOG AUDIT: ALL TESTS PASSED");
    end else begin
      $display("WATCHDOG AUDIT: %0d FAILURES", errors);
      $fatal;
    end
    $finish;
  end

  initial begin
    #500000;
    $display("WATCHDOG AUDIT: TIMEOUT");
    $fatal;
  end

endmodule
