//------------------------------------------------------------------------------
// Home-Automation-SoC — formal harness for `watchdog`  (rev 2)
//
// Directed-stimulus harness: it plays a scripted sequence of *legal APB
// transfers* into the real APB port and asserts only on the DUT's output pins
// (`irq`, `reset_n_out`, `prdata`, `pready`, `pslverr`).  No internal signal is
// referenced: this Yosys 0.69 frontend resolves hierarchical references inside
// assertions to undriven nets, which produced false failures in rev 1.
//
// APB legality.  The DUT acts on `penable && pwrite`, so the harness models a
// real APB master: every transfer occupies two cycles, SETUP (`penable = 0`)
// then ACCESS (`penable = 1`), with address, direction and data held across the
// pair.  Property W0 checks that shape, so the "legal transactions" claim is
// evidence rather than prose.  Idle transfers drive `penable = 0` in both
// cycles.
//
// Registers under test (4-byte offsets, see rtl/rtl_peripherals/watchdog.sv):
//   0x00 LOAD    RW  reload value / pet (reload clears EXPIRED)
//   0x04 CTRL    RW  bit0 enable, bit1 reset-enable
//   0x0C KEY     WO  0x5A5A_0001 locks CTRL until the next reset
//
// Scenario, K = 4 (odd cycles are ACCESS phases):
//
//   t=1  (cyc  2/3)   LOAD = 4
//   t=2  (cyc  4/5)   CTRL = 3          arm counter + reset enable
//   t=3..20 (7..41)   LOAD = 4          pet every second cycle
//   -- feeding stops --
//   cyc 47            expiry (41 pet, 4 decrements, latch, +1)
//   t=24 (cyc 48/49)  LOAD = 4          pet clears the latched timeout
//   t=25 (cyc 50/51)  CTRL = 2          stop counting, keep reset-enable
//   t=30 (cyc 60/61)  CTRL = 3          re-enable -> counts from LOAD again
//   t=34 (cyc 68/69)  LOAD = FFFF_FFFF  maximum value
//   t=35 (cyc 70/71)  KEY  = 5A5A_0001  lock CTRL
//   t=36 (cyc 72/73)  CTRL = 1          must be *ignored* (locked)
//   t=37 (cyc 74/75)  read CTRL          expect {locked,reset_en,enable} = 111
//   t=38 (cyc 76/77)  LOAD = 0          zero boundary: expire immediately
//   cyc 80..84        presetn low       async reset during active countdown
//   t=41 (cyc 82/83)  LOAD = 4          LOAD in flight when reset asserts
//   t=43 (cyc 86/87)  read LOAD          expect 0  (write was discarded)
//   t=44 (cyc 88/89)  read CTRL          expect 0  (lock cleared by reset)
//
// Because the stimulus is deterministic, `mode bmc` at a depth past the end of
// the script is a complete check *of this script* — not a sample of it.  It is
// still a bounded proof of one scenario and does not quantify over all APB
// traffic; see reports/verification/README.md for the classification.
//------------------------------------------------------------------------------
module watchdog_fv (
  input logic pclk
);

  localparam logic [31:0] K    = 32'd4;
  localparam logic [31:0] LOAD = 32'h0000_0000;
  localparam logic [31:0] CTRL = 32'h0000_0004;
  localparam logic [31:0] KEY  = 32'h0000_000C;

  localparam int POR_LEN = 2;
  localparam int END_CYC = 92;

  // Transfer indices (cycle = 2*t + {0 = setup, 1 = access}).
  localparam int T_LOAD4    = 1;
  localparam int T_ARM      = 2;
  localparam int T_PET_FIRST = 3;
  localparam int T_PET_LAST = 20;
  localparam int T_RECOVER  = 24;
  localparam int T_DISABLE  = 25;
  localparam int T_REENABLE = 30;
  localparam int T_LOADMAX  = 34;
  localparam int T_KEY      = 35;
  localparam int T_LOCKCTRL = 36;
  localparam int T_RDCTRL   = 37;
  localparam int T_LOAD0    = 38;
  localparam int T_LOAD4_R  = 41;
  localparam int T_RDLOAD_R = 43;
  localparam int T_RDCTRL_R = 44;

  // Exact cycles named by the properties.
  localparam int C_EXPIRE1     = 47;  // first cycle with irq after feeding stops
  localparam int C_RECOVERED   = 50;  // first cycle with irq low after the pet
  localparam int C_REENABLE    = 61;  // CTRL = 3 ACCESS
  localparam int C_EXPIRE2     = 67;  // one full period after the re-enable
  localparam int C_ZERO_LOW    = 78;  // LOAD = 0 applied, latch not yet set
  localparam int C_ZERO_EXPIRE = 79;  // latch visible
  localparam int C_RST_FIRST   = 80;
  localparam int C_RST_LAST    = 84;
  localparam int C_RD_LOAD_R   = 87;
  localparam int C_RD_CTRL_R   = 89;

  //--------------------------------------------------------------------------
  // Power-on reset model plus one mid-scenario reset of the asynchronous path.
  //--------------------------------------------------------------------------
  logic [7:0]  por  = 8'd0;
  logic [15:0] cyc  = 16'd0;
  logic        booted;
  logic        mid_reset;

  assign booted    = (por >= 8'(POR_LEN));
  assign mid_reset = booted && (cyc >= 16'(C_RST_FIRST)) && (cyc <= 16'(C_RST_LAST));

  logic presetn;
  assign presetn = booted && !mid_reset;

  always @(posedge pclk)
    if (!booted) por <= por + 8'd1;

  always @(posedge pclk)
    if (booted && (cyc < 16'(END_CYC))) cyc <= cyc + 16'd1;

  //--------------------------------------------------------------------------
  // Scripted APB master, fully registered: `ph` is the phase (0 = SETUP,
  // 1 = ACCESS) and kind/addr/data for the *next* transfer are decoded at the
  // clock edge that ends the previous transfer.  Driving the port from
  // registers (rather than an always @(*) block) removes a delta-cycle race
  // that made the legality assertion sample a stale value in simulation.
  //
  //   kind 0 = idle (both phases drive penable low), 1 = write, 2 = read
  //--------------------------------------------------------------------------
  logic [1:0]  kind_r = 2'd0;
  logic [31:0] a_r    = 32'd0;
  logic [31:0] d_r    = 32'd0;
  logic        ph     = 1'b0;
  logic [5:0]  ti     = 6'd0;

  logic [5:0]  t;          // current transfer index (observability)
  logic        ph_now;     // current phase (observability)
  assign t      = ti;
  assign ph_now = ph;

  always @(posedge pclk) begin
    if (!booted) begin
      ph <= 1'b0;
      ti <= 6'd0;
      kind_r <= 2'd0;      // transfer 0 is idle
      a_r    <= LOAD;
      d_r    <= K;
    end else begin
      ph <= ~ph;
      if (ph) begin          // ACCESS finishes -> decode the next transfer
        ti <= ti + 6'd1;
        case (ti + 6'd1)
          6'd0:           kind_r <= 2'd0;
          6'(T_LOAD4):    begin kind_r <= 2'd1; a_r <= LOAD;   d_r <= K;            end
          6'(T_ARM):      begin kind_r <= 2'd1; a_r <= CTRL;   d_r <= 32'd3;         end
          6'(T_RECOVER):  begin kind_r <= 2'd1; a_r <= LOAD;   d_r <= K;             end
          6'(T_DISABLE):  begin kind_r <= 2'd1; a_r <= CTRL;   d_r <= 32'd2;         end
          6'(T_REENABLE): begin kind_r <= 2'd1; a_r <= CTRL;   d_r <= 32'd3;         end
          6'(T_LOADMAX):  begin kind_r <= 2'd1; a_r <= LOAD;   d_r <= 32'hFFFF_FFFF; end
          6'(T_KEY):      begin kind_r <= 2'd1; a_r <= KEY;    d_r <= 32'h5A5A_0001; end
          6'(T_LOCKCTRL): begin kind_r <= 2'd1; a_r <= CTRL;   d_r <= 32'd1;         end
          6'(T_RDCTRL):   begin kind_r <= 2'd2; a_r <= CTRL;   d_r <= 32'd0;         end
          6'(T_LOAD0):    begin kind_r <= 2'd1; a_r <= LOAD;   d_r <= 32'd0;         end
          6'(T_LOAD4_R):  begin kind_r <= 2'd1; a_r <= LOAD;   d_r <= K;             end
          6'(T_RDLOAD_R): begin kind_r <= 2'd2; a_r <= LOAD;   d_r <= 32'd0;         end
          6'(T_RDCTRL_R): begin kind_r <= 2'd2; a_r <= CTRL;   d_r <= 32'd0;         end
          6'd21, 6'd22, 6'd23, 6'd26, 6'd27, 6'd28, 6'd29,
          6'd31, 6'd32, 6'd33, 6'd39, 6'd40, 6'd42, 6'd45:
                          kind_r <= 2'd0;
          default:        begin kind_r <= 2'd1; a_r <= LOAD;   d_r <= K;             end
        endcase
      end
    end
  end

  wire penable = ph && (kind_r != 2'd0);
  wire pwrite  = (kind_r == 2'd1);

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
    .paddr       (a_r),
    .pwdata      (d_r),
    .pstrb       (4'hF),
    .prdata      (prdata),
    .pready      (pready),
    .pslverr     (pslverr),
    .irq         (irq),
    .reset_n_out (reset_n_out)
  );

  //--------------------------------------------------------------------------
  // APB shape check: ACCESS must repeat the SETUP cycle's control and payload.
  // (Shadow registers instead of $past, which this frontend handles unevenly.)
  //--------------------------------------------------------------------------
  logic        q_ph   = 1'b0;
  logic [1:0]  q_kind = 2'd0;
  logic [31:0] q_a    = 32'd0;
  logic [31:0] q_d    = 32'd0;

  always @(posedge pclk) begin
    q_ph   <= ph;
    q_kind <= kind_r;
    q_a    <= a_r;
    q_d    <= d_r;
  end

  //--------------------------------------------------------------------------
  // Properties.  Each names the expected behaviour; a failure means the DUT
  // broke that contract at the reported step (the trace in
  // build/formal/watchdog/engine_0/ shows the exact APB traffic).
  //--------------------------------------------------------------------------
  always @(posedge pclk) begin
    if (booted) begin
      // W0 — harness legality: every ACCESS is preceded by a SETUP phase that
      // carries the same direction, address and data.
      if (penable)
        assert (!q_ph && (q_kind == kind_r) && (q_a == a_r) && (q_d == d_r));

      // W9 — APB completion: this slave is always ready, never errors.
      assert (pready);
      assert (!pslverr);

      if (!mid_reset) begin
        // W1 — untouched block: no timeout, no reset.
        if (cyc < 16'd2) begin
          assert (!irq);
          assert (reset_n_out);
        end

        // W2 — a petted watchdog must never fire.  The window ends one cycle
        // before the earliest possible expiry, so it also proves the pet
        // "on the boundary" kept the counter alive.
        if ((cyc >= 16'd6) && (cyc < 16'(C_EXPIRE1)))
          assert (!irq);

        // W3 — armed: reset output is exactly the inverse of the timeout.
        if ((cyc >= 16'd6) && (cyc <= 16'(C_ZERO_EXPIRE)))
          assert (reset_n_out == ~irq);

        // W4 — feeding stops -> expiry at the computed cycle (not earlier,
        // see W2; not later, see this bound).
        if ((cyc >= 16'(C_EXPIRE1)) && (cyc <= 16'(C_EXPIRE1 + 2)))
          assert (irq);

        // W5 — a pet after expiration clears the timeout and the reset.
        if (cyc == 16'(C_RECOVERED)) begin
          assert (!irq);
          assert (reset_n_out);
        end

        // W6 — disabled: no expiry for 10 cycles although the counter is
        // mid-count and LOAD is unchanged.
        if ((cyc > 16'd51) && (cyc < 16'(C_REENABLE)))
          assert (!irq);

        // W7 — re-enabling reloads from LOAD and expires one period later.
        if ((cyc >= 16'(C_EXPIRE2)) && (cyc <= 16'(C_EXPIRE2 + 1))) begin
          assert (irq);
          assert (!reset_n_out);
        end

        // W8 — maximum reload value: no wrap, no early expiry.
        if ((cyc >= 16'd70) && (cyc <= 16'd76))
          assert (!irq);

        // W10 — KEY lock: the CTRL write after the key is ignored, so the
        // read-back still shows {locked, reset_en, enable} = 111.
        if (cyc == 16'd75) begin
          assert (penable && !pwrite);
          assert (prdata[2:0] == 3'b111);
        end

        // W11 — zero reload value: expires on the first cycle the counter is
        // zero, one latch delay after the write lands.
        if (cyc == 16'(C_ZERO_LOW))    assert (!irq);
        if (cyc == 16'(C_ZERO_EXPIRE)) assert (irq);
      end

      // W12 — asynchronous reset dominates, including a LOAD in flight.
      if (mid_reset) begin
        assert (!irq);
        assert (reset_n_out);
      end

      // W13 — reset clears LOAD, CTRL and the key lock: the in-flight write
      // was discarded (LOAD reads 0, not 4) and the lock is gone.
      if (cyc == 16'(C_RD_LOAD_R)) begin
        assert (penable && !pwrite);
        assert (prdata == 32'd0);
      end
      if (cyc == 16'(C_RD_CTRL_R)) begin
        assert (penable && !pwrite);
        assert (prdata[2:0] == 3'b000);
      end

      // Non-vacuity: W4/W7/W11 already require a real timeout to occur; these
      // covers document the two states sby cannot report in bmc/prove mode.
      if (cyc == 16'(C_EXPIRE1)) cover (irq && !reset_n_out);
      if (cyc == 16'd75)         cover (prdata[2:0] == 3'b111);
    end
  end

endmodule
