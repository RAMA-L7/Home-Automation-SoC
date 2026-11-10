//------------------------------------------------------------------------------
// Home-Automation-SoC — CLINT (Core Local Interruptor)
// Stage 2 RTL
//
// mtime / mtimecmp / msip registers with AXI4-Lite interface.
//
// Register offsets (12-bit, within the CLINT 4 KB window at 0x8000_0000):
//   0x000 MSIP       RW  software interrupt (bit 0)
//   0x3F8 MTIMECMP   RW  low word
//   0x3FC MTIMECMPH  RW  high word
//   0x7F8 MTIME      RO  low word
//   0x7FC MTIMEH     RO  high word
//------------------------------------------------------------------------------
module clint (
  input  logic         clk,
  input  logic         reset_n,
  // AXI4-Lite write address channel
  input  logic         awvalid,
  input  logic [11:0]  awaddr,
  output logic         awready,
  // AXI4-Lite write data channel
  input  logic         wvalid,
  input  logic [31:0]  wdata,
  input  logic [3:0]   wstrb,
  output logic         wready,
  // AXI4-Lite write response channel
  output logic         bvalid,
  input  logic         bready,
  output logic [1:0]   bresp,
  // AXI4-Lite read address channel
  input  logic         arvalid,
  input  logic [11:0]  araddr,
  output logic         arready,
  // AXI4-Lite read data channel
  output logic         rvalid,
  input  logic         rready,
  output logic [31:0]  rdata,
  output logic [1:0]   rresp,
  // Interrupts / time
  output logic         irq_soft,
  output logic         irq_timer,
  output logic [63:0]  time_out
);

  logic [31:0] msip;
  logic [63:0] mtime;
  logic [63:0] mtimecmp;

  // Time counter
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) mtime <= 64'd0;
    else          mtime <= mtime + 1;
  end
  assign time_out = mtime;

  // MSIP (software interrupt)
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) msip <= 32'd0;
    else if (awvalid && awready && wvalid && wready && awaddr == 12'h000)
      msip <= wdata;
  end
  assign irq_soft = |msip;

  // MTIMECMP
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) mtimecmp <= 64'd0;
    else if (awvalid && awready && wvalid && wready) begin
      if (awaddr == 12'h3F8) mtimecmp[31:0]  <= wdata;
      if (awaddr == 12'h3FC) mtimecmp[63:32] <= wdata;
    end
  end

  assign irq_timer = (mtime >= mtimecmp);

  // AXI4-Lite handshake (single cycle)
  assign awready = 1'b1;
  assign wready  = 1'b1;
  assign arready = 1'b1;

  always_comb begin
    rdata = 32'd0;
    unique case (araddr)
      12'h000: rdata = msip;
      12'h3F8: rdata = mtime[31:0];
      12'h3FC: rdata = mtime[63:32];
      12'h7F8: rdata = mtime[31:0];
      12'h7FC: rdata = mtime[63:32];
      default: rdata = 32'd0;
    endcase
  end

  assign rvalid = arvalid;
  assign bvalid = awvalid && wvalid;
  assign bresp  = 2'b00;
  assign rresp  = 2'b00;

endmodule
