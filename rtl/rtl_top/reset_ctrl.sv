//------------------------------------------------------------------------------
// Home-Automation-SoC — Reset controller
//
// Turns the watchdog's level-style timeout output into a bounded system reset.
//
// Why this exists: `watchdog.reset_n_out` is a level that stays low until a
// LOAD write pets it.  Software cannot pet it while it is held in reset, so
// wiring that level straight into the SoC reset would deadlock: the device
// would never leave reset.  This block converts the assertion into a fixed
// HOLD_CYCLES-wide pulse, and the watchdog itself is reset by that same pulse,
// so it comes back with CTRL = 0 (disabled) and the SoC boots normally.
//
// Reset domains:
//   * `reset_n` (external pad) resets this block and can never be extended.
//   * `rst_sys_n` resets the CPU, interconnect, peripherals and both clock
//     gates.  It is released HOLD_CYCLES after a watchdog timeout.
//   * `wdog_reset_n_out` keeps the original pin semantics for a board-level
//     supervisor, but is now the pulse rather than an unbounded level.
//
// The block runs on the ungated `clk`: it must be able to reset a SoC whose
// core clock has been gated by the power manager.
//------------------------------------------------------------------------------
module reset_ctrl #(
  parameter int HOLD_CYCLES = 16
) (
  input  logic clk,
  input  logic reset_n,        // external asynchronous reset (active low)
  input  logic wdog_timeout,   // level from watchdog.reset_n_out, active high
  output logic rst_sys_n,      // internal system reset (active low)
  output logic wdog_reset_n_out
);

  logic [7:0] cnt;
  logic       active;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      active <= 1'b0;
      cnt    <= 8'd0;
    end else if (!active) begin
      if (wdog_timeout) begin
        active <= 1'b1;
        cnt    <= 8'(HOLD_CYCLES - 1);
      end
    end else begin
      if (cnt == 8'd0) active <= 1'b0;
      else             cnt    <= cnt - 8'd1;
    end
  end

  assign rst_sys_n        = reset_n & ~active;
  assign wdog_reset_n_out = ~active;

endmodule
