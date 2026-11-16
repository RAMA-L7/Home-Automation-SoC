//------------------------------------------------------------------------------
// Home-Automation-SoC — formal harness for `reset_ctrl`
//
// Proves the bounded-pulse contract that makes a watchdog reset survivable.
// Everything is measured on the two output pins (no internal references — this
// Yosys SV frontend mis-resolves hierarchical references inside assertions):
//
//   R1  `rst_sys_n` can never stay low longer than HOLD_CYCLES.  An unbounded
//       level would deadlock the SoC: the watchdog can only be petted by
//       software, and software is held in reset.
//   R1b No premature release: while the pulse has not reached HOLD_CYCLES it
//       stays asserted.  R1 + R1b together fix the width at exactly HOLD.
//       (The exact width is also proven by reset_ctrl_seq.sby.)
//
//       R1b is deliberately phrased over `streak`, the count of low cycles up
//       to and including the PREVIOUS cycle, and not over `low_run`, which is a
//       function of the current rst_sys_n.  A previous revision used low_run:
//           if (low_run > 0 && low_run < HOLD) assert (!rst_sys_n);
//       but low_run > 0 holds exactly when rst_sys_n is low, so the assertion
//       restated its own antecedent and was a tautology — it could not fail on
//       any implementation, including one that releases after one cycle.
//       `streak` is registered history, so releasing early while streak is
//       still below HOLD is a genuine violation.  The mutation task
//       reset_ctrl_short.sby (HOLD_DUT = 8 against HOLD = 16) demonstrates
//       that this property now detects a shortened pulse.
//   R2  The pulse releases on the cycle after it has run its full width.
//   R3  A timeout seen while the controller is idle asserts the reset in the
//       very next cycle.
//   R4  The board-level pin carries the same pulse.
// Not asserted here: "the pad reset forces both outputs low" for the very first
// cycles after power-on.  Yosys leaves the DUT's registers free in the initial
// state (the async reset only becomes observable from the first clock edge), so
// that window cannot be proven in this flow.  The directed harness
// reset_ctrl_seq_fv.sv covers it with a concrete power-on timeline (S1).
//
// `wdog_timeout` is a free input, so R1..R4 hold for any watchdog behavior,
// including a timeout that is stuck high.
//
// The wrapper drives `reset_n` through the POR model below (low for POR_LEN
// cycles, high afterwards) so the proof starts from a defined state.  The
// asynchronous external-reset path is covered by sim/sim_top/tb_reset_ctrl.v.
//
// Engine: `abc pdr`.  The width bound is a counter invariant, so temporal
// induction alone reports a false failure from an unreachable start state;
// PDR keeps the reachable-state restriction.
//------------------------------------------------------------------------------
// HOLD_EXPECT is what the properties demand; HOLD_DUT is what the instance under
// test implements.  They are equal in the real task (reset_ctrl.sby).  The
// mutation control reset_ctrl_short.sby compiles this same harness with
// -DHOLD_DUT=8 so a deliberately short pulse must be detected as a failure.
`ifndef HOLD_EXPECT
  `define HOLD_EXPECT 16
`endif
`ifndef HOLD_DUT
  `define HOLD_DUT `HOLD_EXPECT
`endif

module reset_ctrl_fv (
  input logic clk,
  input logic wdog_timeout
);

  localparam int         HOLD    = `HOLD_EXPECT;
  localparam logic [1:0] POR_LEN = 2'd2;

  logic [1:0] por = 2'd0;
  logic       booted;
  logic       reset_n;
  logic       rst_sys_n;
  logic       wdog_reset_n_out;

  assign booted  = (por == POR_LEN);
  assign reset_n = booted;

  always @(posedge clk)
    if (!booted) por <= por + 2'd1;

  reset_ctrl #(.HOLD_CYCLES(`HOLD_DUT)) dut (
    .clk               (clk),
    .reset_n           (reset_n),
    .wdog_timeout      (wdog_timeout),
    .rst_sys_n         (rst_sys_n),
    .wdog_reset_n_out  (wdog_reset_n_out)
  );

  // `low_run` is the number of consecutive cycles rst_sys_n has been low
  // *including the current one*; `streak` holds it across the edge so the
  // next-cycle claims can refer to it.
  logic [7:0] streak = 8'd0;
  wire  [7:0] low_run = rst_sys_n ? 8'd0 : (streak + 8'd1);

  // Previous-cycle observations used by the next-cycle claims.
  logic       q_full         = 1'b0;  // this cycle completes a full-width pulse
  logic       q_idle_timeout = 1'b0;  // timeout seen with the controller idle

  always @(posedge clk) begin
    if (!reset_n) begin
      streak <= 8'd0;
      q_full <= 1'b0;
      q_idle_timeout <= 1'b0;
    end else begin
      streak         <= low_run;
      q_full         <= (low_run == 8'(HOLD));
      q_idle_timeout <= (rst_sys_n && wdog_timeout);
    end
  end

  always @(posedge clk) begin
    if (reset_n) begin
      // R1 — bounded pulse width.
      assert (low_run <= 8'(HOLD));

      // R1b — no premature release.  `streak` is the low-run length through the
      // previous cycle: registered history, independent of the current
      // rst_sys_n, so this can actually fail (see the header note).
      if ((streak > 8'd0) && (streak < 8'(HOLD))) assert (!rst_sys_n);

      // R2 — release on the cycle after the full width.
      if (q_full) assert (rst_sys_n);

      // R3 — a timeout turns into a reset immediately.
      if (q_idle_timeout) assert (!rst_sys_n);

      // R4 — both pins carry the same pulse.
      assert (wdog_reset_n_out == rst_sys_n);

      // Non-vacuity.  The second cover is what proves R1b's antecedent is
      // reachable: a state where the pulse is mid-flight (streak strictly
      // between 0 and HOLD) must be covered, otherwise R1b could pass by never
      // being evaluated.
      cover (!rst_sys_n);
      cover (rst_sys_n && wdog_timeout);
      cover (low_run == 8'(HOLD));
      cover ((streak > 8'd0) && (streak < 8'(HOLD)) && !rst_sys_n);
    end
  end

endmodule
