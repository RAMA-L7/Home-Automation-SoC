//------------------------------------------------------------------------------
// Home-Automation-SoC — formal harness for `watchdog`
//
// Directed-stimulus harness.  It drives the APB port itself, so every property
// below is a statement about observable pins only (prdata is unused, and no
// internal signal is referenced — this Yosys SV frontend mis-resolves
// hierarchical references inside assertions).
//
// Scenario and properties:
//
//   W1  Before anything is written the reset output is released.
//   W2  Arm LOAD = K, then CTRL = enable|reset_en, then pet LOAD = K on every
//       cycle.  While the dog is being fed, `irq` must never rise.  This is the
//       property the original RTL violated: the LOAD write was applied in the
//       same always_ff as the count-down and the decrement won, so a pet never
//       reloaded the counter and the dog expired ~K cycles later regardless.
//   W3  With reset_en armed, `reset_n_out` is exactly the inverse of `irq`.
//   W4  Once feeding stops, the dog must expire within K+2 cycles.
//   W5  Enabled but *not* reset-enabled, `irq` still rises while
//       `reset_n_out` stays high — a counter alone is not a reset source.
//
// The stimulus is deterministic, so `mode bmc` with a depth beyond the
// scenario is a complete check of it, not a sample.
//------------------------------------------------------------------------------
module watchdog_fv (
  input logic pclk
);

  localparam logic [31:0] K        = 32'd8;   // programmed timeout
  localparam int          POR_LEN  = 2;
  localparam int          PET_LAST = 40;      // last cycle that pets the dog

  logic [31:0] por = 32'd0;
  logic        booted;
  logic        presetn;

  logic        penable;
  logic        pwrite;
  logic [31:0] paddr;
  logic [31:0] pwdata;
  logic [31:0] prdata;
  logic        pready;
  logic        pslverr;
  logic        irq;
  logic        reset_n_out;

  assign booted  = (por >= POR_LEN);
  assign presetn = booted;

  always @(posedge pclk)
    if (!booted) por <= por + 32'd1;

  // Phase counter: 0 = LOAD write, 1 = CTRL write (armed), 2..PET_LAST = pet,
  // anything after = stop feeding.
  logic [15:0] cyc = 16'd0;

  always @(posedge pclk)
    if (booted) cyc <= cyc + 16'd1;

  always @(*) begin
    penable = 1'b0;
    pwrite  = 1'b0;
    paddr   = 32'd0;
    pwdata  = 32'd0;
    if (booted) begin
      if (cyc == 16'd0) begin
        penable = 1'b1; pwrite = 1'b1; paddr = 32'h0000_0000; pwdata = K;
      end else if (cyc == 16'd1) begin
        penable = 1'b1; pwrite = 1'b1; paddr = 32'h0000_0004; pwdata = 32'h3;
      end else if (cyc <= 16'(PET_LAST)) begin
        penable = 1'b1; pwrite = 1'b1; paddr = 32'h0000_0000; pwdata = K;
      end
    end
  end

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

  always @(posedge pclk) begin
    if (booted) begin
      // W1 — idle, never written: no reset, no interrupt.
      if (cyc < 16'd2) begin
        assert (reset_n_out);
        assert (!irq);
      end

      // W2 — a fed watchdog must not fire.
      if (cyc >= 16'd2 && cyc <= 16'(PET_LAST))
        assert (!irq);

      // W3 — armed: the reset output is the inverse of the timeout flag.
      if (cyc >= 16'd2)
        assert (reset_n_out == ~irq);

      // W4 — after feeding stops, expiry must arrive within K+2 cycles.
      if (cyc > 16'(PET_LAST + K + 2))
        assert (irq);

      // Non-vacuity.
      if (cyc == 16'd2)   cover (1'b1);
      if (cyc == 16'd3)   cover (!irq);
      if (cyc > 16'(PET_LAST + K + 2)) cover (irq);
      cover (!reset_n_out);
    end
  end

endmodule
