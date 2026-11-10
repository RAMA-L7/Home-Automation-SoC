//------------------------------------------------------------------------------
// Home-Automation-SoC — QSPI Flash Controller (AXI4-Lite)
// Stage 2 RTL (reworked — previous version was an internal array with no pins)
//
// Memory-mapped read engine issuing a real single-line SPI READ (opcode 0x03)
// to an external NOR flash:
//     CS# low, 0x03, 24-bit address, 32 data bits clocked in, CS# high.
// The data is assembled into the AXI R channel.  Quad output (0x6B) and
// program/erase are NOT implemented (see docs; they are reported as gaps, not
// silently faked).
//
// HALF_DIV sets the SCK half period in pclk cycles.  A testbench flash model
// drives qspi_io[1]; in FPGA/board bring-up a real NOR part does the same.
//
// Writes return SLVERR.  qspi_io[0] is driven for MOSI, [1] is input (MISO),
// [3:2] are tri-stated in single-line mode.
//------------------------------------------------------------------------------
module qspi_flash_ctrl #(
  parameter int HALF_DIV = 4
) (
  input  logic         clk,
  input  logic         reset_n,
  // AXI4-Lite slave
  input  logic         awvalid,
  output logic         awready,
  input  logic [31:0]  awaddr,
  input  logic         wvalid,
  output logic         wready,
  input  logic [31:0]  wdata,
  input  logic [3:0]   wstrb,
  output logic         bvalid,
  input  logic         bready,
  output logic [1:0]   bresp,
  input  logic         arvalid,
  output logic         arready,
  input  logic [31:0]  araddr,
  output logic         rvalid,
  input  logic         rready,
  output logic [31:0]  rdata,
  output logic [1:0]   rresp,
  // QSPI pins
  output logic         qspi_sck,
  output logic         qspi_cs_n,
  inout  wire [3:0]    qspi_io
);

  typedef enum logic [2:0] {
    Q_IDLE, Q_CS_SETUP, Q_OUT, Q_TURN, Q_IN, Q_CS_HOLD, Q_RRESP, Q_BRESP
  } qst_e;
  qst_e state, state_n;

  logic [23:0] addr_q;
  logic [31:0] out_sr;     // {0x03, addr[23:0]}
  logic [31:0] in_sr;
  logic [5:0]  bitcnt;     // 0..31 within OUT or IN phase
  logic        phase;      // 0 = sck low, 1 = sck high
  logic [7:0]  half_cnt;
  logic        sck_r, cs_n_r;
  logic        io0_out;

  assign qspi_sck  = sck_r;
  assign qspi_cs_n = cs_n_r;
  assign qspi_io[0] = (cs_n_r == 1'b0) ? io0_out : 1'bz;
  assign qspi_io[2] = 1'bz;
  assign qspi_io[3] = 1'bz;

  wire miso = qspi_io[1];

  wire half_done = (half_cnt == 8'd0);

  //--------------------------------------------------------------------------
  // Control
  //--------------------------------------------------------------------------
  assign awready = (state == Q_IDLE) & ~arvalid;
  assign wready  = (state == Q_IDLE) & ~arvalid;
  assign arready = (state == Q_IDLE) & ~(awvalid & wvalid);

  always_comb begin
    state_n = state;
    case (state)
      Q_IDLE:     if (awvalid && wvalid) state_n = Q_BRESP;
                  else if (arvalid)      state_n = Q_CS_SETUP;
      Q_CS_SETUP: if (half_done)         state_n = Q_OUT;
      Q_OUT:      if (half_done && phase && bitcnt == 6'd31) state_n = Q_TURN;
      Q_TURN:     if (half_done)         state_n = Q_IN;
      Q_IN:       if (half_done && phase && bitcnt == 6'd31) state_n = Q_CS_HOLD;
      Q_CS_HOLD:  if (half_done)         state_n = Q_RRESP;
      Q_RRESP:    if (rready)            state_n = Q_IDLE;
      Q_BRESP:    if (bready)            state_n = Q_IDLE;
      default:                           state_n = Q_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state    <= Q_IDLE;
      addr_q   <= '0;
      out_sr   <= '0;
      in_sr    <= '0;
      bitcnt   <= 6'd0;
      phase    <= 1'b0;
      half_cnt <= 8'd0;
      sck_r    <= 1'b0;
      cs_n_r   <= 1'b1;
      io0_out  <= 1'b0;
    end else begin
      state <= state_n;

      if (state == Q_IDLE && arvalid && !(awvalid && wvalid)) begin
        addr_q   <= araddr[23:0];
        out_sr   <= {8'h03, araddr[23:0]};
        in_sr    <= 32'd0;
        bitcnt   <= 6'd0;
        phase    <= 1'b0;
        half_cnt <= HALF_DIV[7:0];
      end else if (half_done) begin
        half_cnt <= HALF_DIV[7:0];
        phase    <= ~phase;

        case (state)
          Q_CS_SETUP: begin
            cs_n_r <= 1'b0;
            sck_r  <= 1'b0;
            io0_out<= out_sr[31];
          end
          Q_OUT: begin
            sck_r <= phase;                 // 0 -> 1 drives the clock high
            if (phase) begin
              out_sr <= {out_sr[30:0], 1'b0};
              io0_out<= out_sr[30];
              bitcnt <= bitcnt + 6'd1;
            end
          end
          Q_TURN: begin
            sck_r <= 1'b0;                  // clock low for turnaround
            io0_out <= 1'b0;
            bitcnt  <= 6'd0;
          end
          Q_IN: begin
            sck_r <= phase;
            if (phase) begin
              in_sr  <= {in_sr[30:0], miso};
              bitcnt <= bitcnt + 6'd1;
            end
          end
          Q_CS_HOLD: begin
            sck_r  <= 1'b0;
            cs_n_r <= 1'b1;
          end
          default: ;
        endcase
      end

      if (state == Q_BRESP) begin
        cs_n_r <= 1'b1;
        sck_r  <= 1'b0;
      end
    end
  end

  assign rvalid = (state == Q_RRESP);
  assign rdata  = in_sr;
  assign rresp  = 2'b00;

  assign bvalid = (state == Q_BRESP);
  assign bresp  = 2'b10;    // writes not supported yet

endmodule
