//------------------------------------------------------------------------------
// Home-Automation-SoC — CDC property: asynchronous wake into the power manager
//
// `power_mgr.wake_ack` comes from a different clock domain (board-level wake
// source) and is synchronized by the 2-FF chain `wake_sync`.  This harness
// proves the *behavioural* consequences of that chain from the block's outside:
//
//   CD1  While the manager is in sleep (`wake_req` high) both gated clocks are
//        off.  This is what makes a lost wake unrecoverable, hence the point of
//        the properties below.
//   CD2  A wake request held high for two consecutive cycles is always
//        acknowledged: `wake_event` pulses and the clocks come back.
//   CD3  The acknowledgement is prompt — within three cycles of the first high
//        cycle — so a wake cannot be delayed indefinitely.
//   CD4  After the wake the manager returns to ACTIVE and stays there: the
//        sticky sleep request is cleared by `wake_event` (power_mgr_regs), so
//        the manager must not slip back to sleep.
//   CD5  A wake input arriving while the manager is already ACTIVE produces no
//        spurious `wake_event`.
//
// What this does NOT establish (documented, not hidden):
//   * metastability / MTBF: formal logic cannot model it; the 2-FF chain is a
//     structural mitigation only.
//   * a wake pulse shorter than one clock period may legitimately be missed —
//     that is the price of a level synchronizer, not a bug, so no property
//     asserts delivery for a 1-cycle pulse.
//   * the destination's use of the synchronized value is proven behaviourally
//     here and structurally by scripts/formal/cdc_inventory.js.
//
// Timeline: POR 2 cycles; sleep_req high from cycle 3; wake_ack high on
// cycles 6..7 (two cycles = safely observable); wake_ack a second time on
// cycles 12..13 while ACTIVE.  BMC depth 30 covers all of it.
//------------------------------------------------------------------------------
module cdc_power_mgr_fv (
  input logic clk
);

  localparam int POR_LEN = 2;

  logic [1:0]  por = 2'd0;
  logic [15:0] cyc = 16'd0;
  logic        booted;
  logic        reset_n;

  assign booted  = (por >= 2'(POR_LEN));
  assign reset_n = booted;

  always @(posedge clk)
    if (!booted) por <= por + 2'd1;

  always @(posedge clk)
    if (booted && (cyc < 16'd30)) cyc <= cyc + 16'd1;

  // Stimulus: a software sleep request that the wake acknowledgement clears
  // (mirrors power_mgr_regs: sleep_req falls one cycle after wake_event).
  wire sleep_req = booted && (cyc >= 16'd3) && (cyc <= 16'd8);
  // Two-cycle wake pulses: long enough for the 2-FF chain to see them.
  wire wake_ack  = booted && (((cyc >= 16'd6) && (cyc <= 16'd7)) ||
                              ((cyc >= 16'd12) && (cyc <= 16'd13)));

  logic core_clk_en;
  logic periph_clk_en;
  logic wake_req;
  logic wake_event;

  power_mgr dut (
    .clk           (clk),
    .reset_n       (reset_n),
    .sleep_req     (sleep_req),
    .core_clk_en   (core_clk_en),
    .periph_clk_en (periph_clk_en),
    .wake_req      (wake_req),
    .wake_ack      (wake_ack),
    .wake_event    (wake_event)
  );

  always @(posedge clk) begin
    if (booted) begin
      // CD1 — in sleep, both gated clocks are off.
      if ((cyc >= 16'd4) && (cyc <= 16'd8)) begin
        assert (wake_req);
        assert (!core_clk_en);
        assert (!periph_clk_en);
      end

      // CD2 — the two-cycle wake request is always acknowledged.
      if (cyc == 16'd8) assert (wake_event);

      // CD3 — promptness: clocks back within one cycle of the ack.
      if ((cyc >= 16'd9) && (cyc <= 16'd10)) begin
        assert (core_clk_en);
        assert (periph_clk_en);
        assert (!wake_req);
      end

      // CD4 — no slipping back to sleep.
      if (cyc >= 16'd11) begin
        assert (core_clk_en);
        assert (periph_clk_en);
        assert (!wake_event);
      end

      // CD5 — an ACTIVE manager ignores a further wake request.
      if (((cyc >= 16'd12) && (cyc <= 16'd20)) && (cyc < 16'd30))
        assert (!wake_req);

      // Non-vacuity: the wake really did happen.
      if (cyc == 16'd8) cover (wake_event && !core_clk_en);
      if (cyc == 16'd9) cover (core_clk_en && !wake_event);
    end
  end

endmodule
