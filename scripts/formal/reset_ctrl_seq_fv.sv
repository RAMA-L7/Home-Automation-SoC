//------------------------------------------------------------------------------
// Home-Automation-SoC — directed timing proof for `reset_ctrl`
//
// reset_ctrl_fv.sv proves the *invariants* (width bound, prompt assertion, pin
// agreement) for an arbitrary `wdog_timeout`.  This harness complements it with
// a deterministic timeline, which is what makes those invariants non-vacuous:
// it proves a pulse actually happens, and that its width and phase are exactly
// right rather than merely legal.
//
// Timeline (HOLD = 16, POR = 2 cycles):
//
//   cycles 0..2   power-on reset, timeout low
//   cycle  3      timeout rises (idle controller)
//   cycles 4..19  first pulse: 16 consecutive cycles of rst_sys_n low
//   cycle  20     release
//   cycles 21..36 second pulse (timeout still high, controller re-armed)
//   cycle  37     release
//   cycles 38..53 third pulse; the timeout drops at cycle 40 (inside the
//                 pulse) and must NOT truncate it
//   cycle  54     release; controller stays idle afterwards
//
// Properties:
//   S1  no reset while the timeout is low after POR
//   S2  every cycle in a pulse window is asserted (exact width, not a bound)
//   S3  every release cycle is deasserted
//   S4  a mid-pulse timeout deassertion does not shorten the pulse
//   S5  both pins carry the pulse
//   S6  the controller stays idle once the timeout is gone
//
// Deterministic stimulus => BMC past the end of the timeline is a complete
// check of this scenario (see reset_ctrl_seq.sby, depth 60).
//------------------------------------------------------------------------------
module reset_ctrl_seq_fv (
  input logic clk
);

  localparam int         HOLD    = 16;
  localparam logic [1:0] POR_LEN = 2'd2;

  localparam int C_TMO_FIRST   = 3;    // timeout rises
  localparam int C_TMO_LAST    = 40;   // ... and falls here (mid third pulse)
  localparam int C_P1_FIRST    = 4;
  localparam int C_P1_LAST     = 19;
  localparam int C_P1_RELEASE  = 20;
  localparam int C_P2_FIRST    = 21;
  localparam int C_P2_LAST     = 36;
  localparam int C_P2_RELEASE  = 37;
  localparam int C_P3_FIRST    = 38;
  localparam int C_P3_LAST     = 53;
  localparam int C_P3_RELEASE  = 54;
  localparam int END_CYC       = 60;

  logic [1:0]  por = 2'd0;
  logic [15:0] cyc = 16'd0;
  logic        booted;
  logic        reset_n;

  assign booted  = (por == POR_LEN);
  assign reset_n = booted;

  always @(posedge clk)
    if (!booted) por <= por + 2'd1;

  always @(posedge clk)
    if (booted && (cyc < 16'(END_CYC))) cyc <= cyc + 16'd1;

  // High from C_TMO_FIRST (inclusive) and already low *at* C_TMO_LAST, so the
  // timeout falls inside the third pulse window.
  wire wdog_timeout = booted &&
                      (cyc >= 16'(C_TMO_FIRST)) && (cyc < 16'(C_TMO_LAST));

  logic rst_sys_n;
  logic wdog_reset_n_out;

  reset_ctrl #(.HOLD_CYCLES(HOLD)) dut (
    .clk              (clk),
    .reset_n          (reset_n),
    .wdog_timeout     (wdog_timeout),
    .rst_sys_n        (rst_sys_n),
    .wdog_reset_n_out (wdog_reset_n_out)
  );

  always @(posedge clk) begin
    if (booted) begin
      // S1 — nothing fires before the timeout.
      if (cyc < 16'(C_TMO_FIRST)) begin
        assert (rst_sys_n);
        assert (wdog_reset_n_out);
      end

      // S2 — exact asserted windows.
      if (((cyc >= 16'(C_P1_FIRST)) && (cyc <= 16'(C_P1_LAST))) ||
          ((cyc >= 16'(C_P2_FIRST)) && (cyc <= 16'(C_P2_LAST))) ||
          ((cyc >= 16'(C_P3_FIRST)) && (cyc <= 16'(C_P3_LAST))))
        assert (!rst_sys_n);

      // S3 — exact release cycles.
      if ((cyc == 16'(C_P1_RELEASE)) || (cyc == 16'(C_P2_RELEASE)) ||
          (cyc == 16'(C_P3_RELEASE)))
        assert (rst_sys_n);

      // S4 — the timeout falls at C_TMO_LAST, inside the third pulse; the
      // pulse still runs to C_P3_LAST (already asserted by S2) and releases
      // exactly at C_P3_RELEASE (S3).  Named here so the intent is explicit.
      if (cyc == 16'(C_TMO_LAST)) assert (!wdog_timeout);

      // S5 — both pins agree on every cycle.
      assert (wdog_reset_n_out == rst_sys_n);

      // S6 — idle after the last release.
      if (cyc > 16'(C_P3_RELEASE)) begin
        assert (rst_sys_n);
        assert (wdog_reset_n_out);
      end

      // Non-vacuity: the timeline really does produce pulses.
      if (cyc == 16'(C_P1_FIRST))    cover (!rst_sys_n);
      if (cyc == 16'(C_P1_RELEASE))  cover (rst_sys_n);
      if (cyc == 16'(C_P3_RELEASE))  cover (rst_sys_n && !wdog_timeout);
    end
  end

endmodule
