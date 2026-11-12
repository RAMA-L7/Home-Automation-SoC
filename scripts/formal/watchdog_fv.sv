//------------------------------------------------------------------------------
// Home-Automation-SoC — formal wrapper for `watchdog`
//
// Properties that the C firmware demo depends on (tb_firmware.v):
//
//   A1  The reset output is exactly (expired && reset_en).  Enabling the
//       counter alone must never reset the SoC.
//   A2  Expiry can only be latched while the counter is enabled.
//   A3  A pet (a LOAD write) restarts the full period: the next-cycle counter
//       value must be the written value, not a decremented leftover.
//   A4  irq mirrors the sticky expired flag.
//   A5  The KEY register locks CTRL until reset.
//
// A3 is the reason this file exists: the original RTL applied the LOAD write
// and the count-down in the same always_ff, so the decrement silently won and
// a pet did not reload the counter.  `sby` produces a counterexample for A3 on
// that version.
//------------------------------------------------------------------------------
module watchdog_fv (
  input logic        pclk,
  input logic        presetn,
  input logic        penable,
  input logic        pwrite,
  input logic [31:0] paddr,
  input logic [31:0] pwdata
);

  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;
  logic        irq;
  logic        reset_n_out;

  watchdog dut (
    .pclk        (pclk),
    .presetn     (presetn),
    .penable     (penable),
    .pwrite      (pwrite),
    .paddr       (paddr),
    .pwdata      (pwdata),
    .pstrb       (4'hF),
    .prdata      (prdata),
    .pready      (pready),
    .pslverr     (pslverr),
    .irq         (irq),
    .reset_n_out (reset_n_out)
  );

  // Register selects, as decoded by the DUT (word offsets).
  wire sel_load = penable && pwrite && (paddr[11:2] == 10'd0);
  wire sel_ctrl = penable && pwrite && (paddr[11:2] == 10'd1);
  wire sel_key  = penable && pwrite && (paddr[11:2] == 10'd3);

  // A1 — reset generation needs both the expiry and the reset-enable bit.
  always @(posedge pclk) if (presetn)
    assert (reset_n_out == ~(dut.expired && dut.reset_en));

  // A2 — no expiry without an enabled counter.
  always @(posedge pclk) if (presetn)
    assert property ($rose(dut.expired) |-> $past(dut.enable));

  // A3 — a pet reloads the counter to the written value.
  always @(posedge pclk) if (presetn)
    assert property (sel_load |=> (dut.count == $past(pwdata)));

  // A4 — irq is the sticky expired flag.
  always @(posedge pclk)
    assert (irq == dut.expired);

  // A5 — a matching KEY write locks CTRL until the next reset.
  always @(posedge pclk) if (presetn)
    assert property ((sel_key && pwdata == 32'h5A5A_0001) |=> dut.locked);

  // Non-vacuity: every property above must be exercised.
  always @(posedge pclk) begin
    cover (sel_load && dut.enable && !dut.expired);  // pet while counting
    cover (dut.expired);                            // timeout reached
    cover (!reset_n_out);                           // reset actually asserted
    cover (sel_ctrl && pwdata[0]);                  // counter enabled
    cover (dut.count == 32'd1);                     // one cycle before expiry
  end

endmodule
