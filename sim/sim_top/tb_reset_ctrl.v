//------------------------------------------------------------------------------
// Home-Automation-SoC — reset controller testbench
//
// Verifies the watchdog-to-system-reset path:
//   1. external reset dominates
//   2. a timeout asserts rst_sys_n for exactly HOLD_CYCLES
//   3. the pulse releases and the system runs again
//   4. a second timeout produces a second pulse (repeatability)
//   5. wdog_reset_n_out mirrors the internal reset
//   6. no pulse without a timeout
//   7. a timeout held during external reset does not extend the external reset
//
// The watchdog's own behaviour (counting, CTRL/STATUS, petting) is covered by
// sim/sim_top/tb_watchdog.v.  This bench models the electrical contract: the
// watchdog is reset by rst_sys_n, so its timeout level drops when the pulse
// starts.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_reset_ctrl;

  localparam int HOLD = 8;

  logic clk = 0;
  logic reset_n = 0;
  logic wdog_timeout = 0;
  logic rst_sys_n, wdog_reset_n_out;

  integer errors = 0;
  integer checks = 0;

  always #5 clk = ~clk;

  reset_ctrl #(.HOLD_CYCLES(HOLD)) dut (
    .clk(clk), .reset_n(reset_n), .wdog_timeout(wdog_timeout),
    .rst_sys_n(rst_sys_n), .wdog_reset_n_out(wdog_reset_n_out)
  );

  `define CHK(cond, name) \
    if (!(cond)) begin errors = errors + 1; $display("[rst] FAIL: %s", name); end \
    else checks = checks + 1;

  // Count how many clocks rst_sys_n stays low after a timeout, and clear the
  // timeout level when the pulse begins (the watchdog is reset by rst_sys_n).
  integer low_cycles;
  logic   measuring;
  always @(posedge clk) begin
    if (!measuring) begin
      if (wdog_timeout && !rst_sys_n) begin measuring <= 1; low_cycles <= 1; end
    end else begin
      if (!rst_sys_n) low_cycles <= low_cycles + 1;
      else measuring <= 0;
    end
  end

  task wait_timeout(input int cycles);
    begin
      repeat (cycles) @(posedge clk);
    end
  endtask

  initial begin
    //------------------------------------------------------------------ 1
    repeat (3) @(posedge clk);
    `CHK(rst_sys_n === 1'b0, "external reset asserts system reset")
    // wdog_reset_n_out reports a *watchdog* reset; during an external reset it
    // stays deasserted so a board supervisor is not told the wrong source.
    `CHK(wdog_reset_n_out === 1'b1, "external reset leaves the watchdog reset pin released")
    repeat (2) @(posedge clk);
    reset_n = 1'b1;
    @(posedge clk); #1;
    `CHK(rst_sys_n === 1'b1, "system reset releases with the external reset")
    `CHK(wdog_reset_n_out === 1'b1, "watchdog reset pin releases")

    //------------------------------------------------------------------ 6
    repeat (10) @(posedge clk);
    `CHK(rst_sys_n === 1'b1, "no timeout, no reset")

    //------------------------------------------------------------------ 2
    measuring = 1'b0;
    wdog_timeout = 1'b1;
    @(posedge clk); @(posedge clk); #1;
    `CHK(rst_sys_n === 1'b0, "timeout asserts system reset")
    `CHK(wdog_reset_n_out === 1'b0, "timeout asserts the watchdog reset pin")
    // The watchdog is reset by the system reset, so its level drops.
    wdog_timeout = 1'b0;

    //------------------------------------------------------------------ 3
    wait (rst_sys_n === 1'b1);
    @(posedge clk); #1;
    `CHK(rst_sys_n === 1'b1, "system reset releases after the pulse")
    `CHK(low_cycles == HOLD, "reset pulse is exactly HOLD_CYCLES wide")
    $display("[rst] pulse width: %0d cycles (expected %0d)", low_cycles, HOLD);

    //------------------------------------------------------------------ 4
    repeat (10) @(posedge clk);
    `CHK(rst_sys_n === 1'b1, "system runs after the pulse")
    measuring = 1'b0;
    wdog_timeout = 1'b1;
    @(posedge clk); @(posedge clk); #1;
    `CHK(rst_sys_n === 1'b0, "second timeout asserts system reset again")
    wdog_timeout = 1'b0;
    wait (rst_sys_n === 1'b1);
    @(posedge clk); #1;
    `CHK(rst_sys_n === 1'b1, "second pulse releases")
    `CHK(low_cycles == HOLD, "second pulse width matches")

    //------------------------------------------------------------------ 7
    // External reset while a timeout is pending: the external reset is not
    // extended by the timeout, and release is governed by reset_n.
    repeat (5) @(posedge clk);
    wdog_timeout = 1'b1;
    reset_n = 1'b0;
    #1;
    `CHK(rst_sys_n === 1'b0, "external reset during timeout asserts reset")
    // The watchdog itself is reset by rst_sys_n, so its timeout level drops
    // with the reset; the external reset must not be extended by it.
    wdog_timeout = 1'b0;
    repeat (4) @(posedge clk);
    reset_n = 1'b1;
    #1;
    `CHK(rst_sys_n === 1'b1, "release follows the external reset, not the timeout")

    //------------------------------------------------------------------ end
    $display("[rst] checks: %0d, failures: %0d", checks, errors);
    if (errors != 0) begin
      $display("[rst] RESULT: FAIL");
      $fatal(1, "reset controller failures: %0d", errors);
    end
    $display("[rst] RESULT: PASS");
    $finish;
  end

  initial begin
    #100_000;
    $display("[rst] FAIL: hang guard expired");
    $fatal(1, "reset controller testbench timed out");
  end

endmodule
