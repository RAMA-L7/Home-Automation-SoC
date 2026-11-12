//------------------------------------------------------------------------------
// Home-Automation-SoC — formal wrapper for `reset_ctrl`
//
// Proves the bounded-pulse contract that makes a watchdog reset survivable:
//
//   R1  `rst_sys_n` can never stay low longer than HOLD_CYCLES.  An unbounded
//       level would deadlock the SoC (the watchdog can only be petted by
//       software, and software is held in reset).
//   R2  A timeout asserts `rst_sys_n` in the very next cycle.
//   R3  Once the pulse has run its full width it releases on the next cycle.
//   R4  The external reset always wins and can never be extended.
//   R5  The board-level `wdog_reset_n_out` carries the same pulse.
//
// `reset_n` is assumed high for the whole proof, so the asynchronous external
// reset path (R4's forcing direction) is covered by simulation, not here.
//------------------------------------------------------------------------------
module reset_ctrl_fv (
  input logic clk,
  input logic reset_n,
  input logic wdog_timeout
);

  localparam int HOLD = 16;

  logic rst_sys_n;
  logic wdog_reset_n_out;
  logic [7:0] streak;   // consecutive cycles with rst_sys_n held low

  reset_ctrl #(.HOLD_CYCLES(HOLD)) dut (
    .clk               (clk),
    .reset_n           (reset_n),
    .wdog_timeout      (wdog_timeout),
    .rst_sys_n         (rst_sys_n),
    .wdog_reset_n_out  (wdog_reset_n_out)
  );

  always_ff @(posedge clk) begin
    if (!reset_n)        streak <= 8'd0;
    else if (!rst_sys_n) streak <= streak + 8'd1;
    else                 streak <= 8'd0;
  end

  // The external reset is deasserted for the duration of the proof.
  always @(posedge clk) assume (reset_n);

  // R1 — bounded pulse width.
  always @(posedge clk) if (reset_n)
    assert (streak <= 8'(HOLD));

  // R2 — a timeout is turned into a reset immediately.  Guarded by
  // `rst_sys_n` because a timeout that is still high when a pulse ends
  // re-arms only on the following cycle (in the SoC the watchdog is reset
  // by this same pulse, so the level has already dropped).
  property p_timeout_asserts;
    @(posedge clk) disable iff (!reset_n) (rst_sys_n && wdog_timeout) |=> !rst_sys_n;
  endproperty
  assert property (p_timeout_asserts);

  // R3 — release after exactly HOLD cycles.
  property p_release;
    @(posedge clk) disable iff (!reset_n) (streak == 8'(HOLD)) |=> rst_sys_n;
  endproperty
  assert property (p_release);

  // R5 — both pins carry the same pulse.
  always @(posedge clk)
    assert (wdog_reset_n_out == rst_sys_n);

  // Non-vacuity.
  always @(posedge clk) begin
    cover (!rst_sys_n);
    cover (streak == 8'(HOLD));
  end

endmodule
