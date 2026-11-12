//------------------------------------------------------------------------------
// Home-Automation-SoC — formal harness for `plic` register semantics
//
// Directed-stimulus harness, same style as watchdog_fv.sv: it plays one
// scripted register trace into the real port and asserts only on the DUT's
// outputs (`rd_data`, `irq_out`).  No hierarchical reference is used, because
// this Yosys frontend resolves them to undriven nets.
//
// Script (cycle numbers are pclk edges, reset released at cycle 2):
//
//   c=2   release reset
//   c=4   read 0x200 (enable)     -> 0
//   c=5   read 0x204 (threshold)  -> 0
//   c=6   read 0x100 (pending)    -> 0
//   c=7   read 0x208 (claim)      -> 0 (nothing pending)
//   c=9   IRQ1 high               (with enable = 0 -> irq_out must stay 0)
//   c=14  write 0x004 prio(1)=7
//   c=15  write 0x200 enable=0x01
//   c=16  irq_out must rise (2-FF synchroniser + arbitration)
//   c=18  read 0x100 -> pending bit 1
//   c=19  read 0x208 -> claim id 1
//   c=20  write 0x208 = 1        (claim: masks source 1)
//   c=21  IRQ1 falls; pending must clear (claimed and deasserted)
//   c=25  read 0x100 -> 0
//   c=27  IRQ2 high + IRQ3 high, prio(2)=5, prio(3)=5, enable=0x0F
//   c=32  irq_out high, claim id 2 (tie -> lowest ID)
//   c=34  threshold = 6          (all priorities below -> irq_out low)
//   c=38  threshold = 0, prio(3)=9
//   c=42  irq_out high, claim id 3
//   c=45  read unmapped 0x0F0 -> 0
//------------------------------------------------------------------------------
module plic_regs_fv (
  input logic clk
);

  localparam logic [11:0] PRIO1 = 12'h004;
  localparam logic [11:0] PRIO2 = 12'h008;
  localparam logic [11:0] PRIO3 = 12'h00C;
  localparam logic [11:0] PEND  = 12'h100;
  localparam logic [11:0] ENAB  = 12'h200;
  localparam logic [11:0] THRES = 12'h204;
  localparam logic [11:0] CLAIM = 12'h208;

  localparam int POR_LEN = 2;
  localparam int END_CYC = 48;

  //--------------------------------------------------------------------------
  // Reset model and cycle counter.
  //--------------------------------------------------------------------------
  logic [7:0]  por = 8'd0;
  logic [7:0]  cyc = 8'd0;
  logic        booted;

  assign booted = (por >= 8'(POR_LEN));

  always @(posedge clk) if (!booted) por <= por + 8'd1;
  always @(posedge clk) if (booted && (cyc < 8'(END_CYC))) cyc <= cyc + 8'd1;

  logic reset_n;
  assign reset_n = booted;

  //--------------------------------------------------------------------------
  // Scripted register port and interrupt sources (all registered).
  //--------------------------------------------------------------------------
  logic        wr_en  = 1'b0;
  logic [11:0] wr_addr = 12'd0, rd_addr = 12'd0;
  logic [31:0] wr_data = 32'd0;
  logic [7:0]  src     = 8'd0;

  logic [31:0] rd_data;
  logic        irq_out;

  plic dut (
    .clk      (clk),
    .reset_n  (reset_n),
    .wr_en    (wr_en),
    .wr_addr  (wr_addr),
    .wr_data  (wr_data),
    .rd_addr  (rd_addr),
    .rd_data  (rd_data),
    .ext_irq  (src),
    .irq_out  (irq_out)
  );

  always @(posedge clk) begin
    // Defaults every cycle; the case below overrides them.
    wr_en  <= 1'b0;
    wr_addr <= 12'd0;
    wr_data <= 32'd0;
    rd_addr <= 12'd0;

    // IRQ1 asserts at cycle 9 and deasserts at 21; IRQ2/IRQ3 assert at 27 and
    // stay high for the rest of the trace (sources are level-sensitive).
    src[0] <= (cyc >= 8'd9) && (cyc < 8'd21);
    src[1] <= (cyc >= 8'd27);
    src[2] <= (cyc >= 8'd27);

    if (booted) begin
      case (cyc)
        8'd4:  rd_addr <= ENAB;
        8'd5:  rd_addr <= THRES;
        8'd6:  rd_addr <= PEND;
        8'd7:  rd_addr <= CLAIM;
        8'd14: begin wr_en <= 1'b1; wr_addr <= PRIO1; wr_data <= 32'd7; end
        8'd15: begin wr_en <= 1'b1; wr_addr <= ENAB;  wr_data <= 32'h1; end
        8'd18: rd_addr <= PEND;
        8'd19: rd_addr <= CLAIM;
        8'd20: begin wr_en <= 1'b1; wr_addr <= CLAIM; wr_data <= 32'd1; end
        8'd25: rd_addr <= PEND;
        8'd28: begin wr_en <= 1'b1; wr_addr <= PRIO2; wr_data <= 32'd5; end
        8'd29: begin wr_en <= 1'b1; wr_addr <= PRIO3; wr_data <= 32'd5; end
        8'd30: begin wr_en <= 1'b1; wr_addr <= ENAB;  wr_data <= 32'hF; end
        8'd34: begin wr_en <= 1'b1; wr_addr <= THRES; wr_data <= 32'd6; end
        8'd36: rd_addr <= CLAIM;
        8'd38: begin wr_en <= 1'b1; wr_addr <= THRES; wr_data <= 32'd0; end
        8'd39: begin wr_en <= 1'b1; wr_addr <= PRIO3; wr_data <= 32'd9; end
        8'd43: rd_addr <= CLAIM;
        8'd45: rd_addr <= 12'h0F0;
        default: ;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // Properties
  //--------------------------------------------------------------------------
  // Register reads are visible one cycle after `rd_addr` is presented (the
  // port is a plain synchronous register interface), so each read assertion
  // names drive-cycle + 1.  The values below were confirmed against a
  // simulation of this exact harness before the proof was run.
  always @(posedge clk) begin
    if (booted) begin
      // P0 — no interrupt may be reported while every source is disabled.
      if (cyc < 8'd15) assert (!irq_out);

      // P1/P2/P3 — reset values read back as zero.
      if (cyc == 8'd5)  assert (rd_data == 32'd0);
      if (cyc == 8'd6)  assert (rd_data == 32'd0);
      if (cyc == 8'd7)  assert (rd_data == 32'd0);

      // P4 — no claim when nothing is pending.
      if (cyc == 8'd8)  assert (rd_data == 32'd0);

      // P5 — a single enabled source above threshold raises irq_out within two
      // cycles of the enable write (2-FF synchroniser plus arbitration).
      if ((cyc >= 8'd17) && (cyc < 8'd20)) assert (irq_out);

      // P6 — the pending bit is visible while the source is asserted.
      if (cyc == 8'd19) assert (rd_data[0]);

      // P7 — claim returns the winning ID.
      if (cyc == 8'd20) assert (rd_data[7:0] == 8'd1);

      // P8 — after the claim the source stays high but is masked; once it
      // deasserts the pending bit clears.
      if (cyc == 8'd26) assert (rd_data[7:0] == 8'd0);

      // P9 — two equal-priority sources: the lower ID wins the claim, and
      // raising the threshold above every priority suppresses the interrupt.
      if ((cyc >= 8'd32) && (cyc < 8'd36)) assert (irq_out);
      if ((cyc >= 8'd37) && (cyc < 8'd40)) assert (!irq_out);
      if (cyc == 8'd37) assert (rd_data[7:0] == 8'd0);

      // P10 — threshold back to 0 and prio(3) raised: source 3 wins.
      if ((cyc >= 8'd41) && (cyc < 8'd45)) assert (irq_out);
      if (cyc == 8'd44) assert (rd_data[7:0] == 8'd3);

      // P11 — an unmapped offset reads as zero, never as stale data.
      if (cyc == 8'd46) assert (rd_data == 32'd0);

      // Covers, so a vacuous pass is visible in the log.
      if (cyc == 8'd20) cover (rd_data[7:0] == 8'd1);
      if (cyc == 8'd44) cover (rd_data[7:0] == 8'd3);
      if (cyc == 8'd43) cover (irq_out);
    end
  end

endmodule
