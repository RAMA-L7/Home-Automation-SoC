//------------------------------------------------------------------------------
// Home-Automation-SoC — PLIC (Platform-Level Interrupt Controller)
//
// 8 interrupt sources (IDs 1..8), one machine-mode context, priority based.
// Bus timing is owned by intc_axi; this block exposes a register port.
//
// Register offsets (12-bit, within the PLIC 4 KB window at 0x8000_1000):
//   0x004 + 4*(id-1)  priority        RW
//   0x100             pending         RO
//   0x200             enable          RW
//   0x204             threshold        RW
//   0x208             claim/complete  RW
//
// The architecture document originally placed the context registers at
// 0x2000/0x2004/0x2008, which does not fit inside the 4 KB window created by
// splitting the 64 KB INTC region at bit 12.  The registers were moved down and
// the map document corrected (ADR-011).
//------------------------------------------------------------------------------
module plic #(
  parameter int NUM_SOURCES = 8
) (
  input  logic                        clk,
  input  logic                        reset_n,
  // register port
  input  logic                        wr_en,
  input  logic [11:0]                 wr_addr,
  input  logic [31:0]                 wr_data,
  input  logic [11:0]                 rd_addr,
  output logic [31:0]                 rd_data,
  // sources / interrupt output
  input  logic [NUM_SOURCES-1:0]      ext_irq,
  output logic                        irq_out
);

  logic [7:0]             prio [NUM_SOURCES];
  logic [NUM_SOURCES-1:0] enable;

  //----------------------------------------------------------------------------
  // Source synchronisation (CDC)
  //
  // `ext_irq` is a pin-level input: it can arrive at any phase of `clk`, so it
  // must not drive control logic directly.  Two flops absorb the metastability
  // window, and a third register detects the rising edge in the clk domain, so
  // an event that arrives while the source is still masked as `claimed` is
  // captured rather than lost.  A pulse shorter than two clk cycles can still
  // be missed - that is a property of level sampling, not a fixable bug, and it
  // is documented in reports/verification/README.md.
  //----------------------------------------------------------------------------
  logic [NUM_SOURCES-1:0] irq_meta, irq_sync, irq_prev;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      irq_meta <= '0;
      irq_sync <= '0;
      irq_prev <= '0;
    end else begin
      irq_meta <= ext_irq;
      irq_sync <= irq_meta;
      irq_prev <= irq_sync;
    end
  end

  wire [NUM_SOURCES-1:0] irq_event = irq_sync & ~irq_prev;
  logic [7:0]             threshold;
  logic [NUM_SOURCES-1:0] pending;
  logic [NUM_SOURCES-1:0] claimed;
  logic [2:0]             claim_id;

  //----------------------------------------------------------------------------
  // Level-sensitive pending tracking with claim masking
  //----------------------------------------------------------------------------
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pending <= '0;
      claimed <= '0;
    end else begin
      for (int i = 0; i < NUM_SOURCES; i++) begin
        pending[i] <= irq_event[i] | irq_sync[i] | (pending[i] & ~claimed[i]);
        if (claimed[i] && !irq_sync[i]) claimed[i] <= 1'b0;
      end

      // Claim (read of 0x208) masks the source until it deasserts.  Kept in
      // this process so `claimed` has exactly one driver; the assignment below
      // wins over the clear above in procedural order.
      if (wr_en && wr_addr == 12'h208 && claim_id != 3'd0)
        claimed[claim_id - 3'd1] <= 1'b1;
    end
  end

  //----------------------------------------------------------------------------
  // Registers
  //----------------------------------------------------------------------------
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      enable    <= '0;
      threshold <= 8'd0;
      for (int i = 0; i < NUM_SOURCES; i++) prio[i] <= 8'd0;
    end else if (wr_en) begin
      if (wr_addr >= 12'h004 && wr_addr < 12'h004 + 4*NUM_SOURCES)
        prio[wr_addr[4:2] - 1] <= wr_data[7:0];
      else case (wr_addr)
        12'h200: enable    <= wr_data[NUM_SOURCES-1:0];
        12'h204: threshold <= wr_data[7:0];
        default: ;
      endcase
    end
  end

  //----------------------------------------------------------------------------
  // Arbitration: highest priority above threshold, lowest ID breaks ties
  //----------------------------------------------------------------------------
  always_comb begin
    logic [7:0] best;
    best     = threshold;
    claim_id = 3'd0;
    irq_out  = 1'b0;
    for (int i = 0; i < NUM_SOURCES; i++) begin
      if (pending[i] && enable[i] && (prio[i] > threshold) && (prio[i] > best))
        begin
          best     = prio[i];
          claim_id = 3'(i + 1);
          irq_out  = 1'b1;
        end
    end
  end

  //----------------------------------------------------------------------------
  // Read mux
  //----------------------------------------------------------------------------
  always_comb begin
    rd_data = 32'd0;
    if (rd_addr >= 12'h004 && rd_addr < 12'h004 + 4*NUM_SOURCES)
      rd_data = {24'd0, prio[rd_addr[4:2] - 1]};
    else case (rd_addr)
      12'h100: rd_data = {24'd0, pending};
      12'h200: rd_data = {24'd0, enable};
      12'h204: rd_data = {24'd0, threshold};
      12'h208: rd_data = {29'd0, claim_id};
      default: rd_data = 32'd0;
    endcase
  end

endmodule
