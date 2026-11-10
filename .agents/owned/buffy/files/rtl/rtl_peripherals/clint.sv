//------------------------------------------------------------------------------
// Home-Automation-SoC — CLINT (Core Local Interruptor)
//
// mtime / mtimecmp / msip registers with a simple synchronous register port.
// Bus timing is owned by intc_axi, so no AXI handshakes appear here.
//
// Register offsets (12-bit, within the CLINT 4 KB window):
//   0x000 MSIP       RW  software interrupt (bit 0)
//   0x3F8 MTIMECMP   RW  low word
//   0x3FC MTIMECMPH  RW  high word
//   0x7F8 MTIME      RO  low word
//   0x7FC MTIMEH     RO  high word
//
// The architectural CLINT MTIME offset is 0xBFF8, which does not fit the 4 KB
// window used here; the pair is aliased at 0x7F8.  Firmware must use the
// addresses defined in has_addr_map_pkg.
//------------------------------------------------------------------------------
module clint (
  input  logic         clk,
  input  logic         reset_n,
  // register port
  input  logic         wr_en,
  input  logic [11:0]  wr_addr,
  input  logic [31:0]  wr_data,
  input  logic [11:0]  rd_addr,
  output logic [31:0]  rd_data,
  // interrupts / time
  output logic         irq_soft,
  output logic         irq_timer,
  output logic [63:0]  time_out
);

  logic [31:0] msip;
  logic [63:0] mtime;
  logic [63:0] mtimecmp;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      mtime    <= 64'd0;
      mtimecmp <= 64'hFFFF_FFFF_FFFF_FFFF;   // no timer interrupt until armed
      msip     <= 32'd0;
    end else begin
      mtime <= mtime + 64'd1;
      if (wr_en) begin
        case (wr_addr)
          12'h000: msip            <= {31'd0, wr_data[0]};
          12'h3F8: mtimecmp[31:0]  <= wr_data;
          12'h3FC: mtimecmp[63:32] <= wr_data;
          default: ;
        endcase
      end
    end
  end

  assign time_out  = mtime;
  assign irq_soft  = msip[0];
  assign irq_timer = (mtime >= mtimecmp);

  always_comb begin
    case (rd_addr)
      12'h000: rd_data = msip;
      12'h3F8: rd_data = mtimecmp[31:0];
      12'h3FC: rd_data = mtimecmp[63:32];
      12'h7F8: rd_data = mtime[31:0];
      12'h7FC: rd_data = mtime[63:32];
      default: rd_data = 32'd0;
    endcase
  end

endmodule
