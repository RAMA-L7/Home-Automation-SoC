//------------------------------------------------------------------------------
// Home-Automation-SoC — AXI4-Lite to APB3 Bridge
// Stage 2 RTL (reworked)
//
// Converts one AXI4-Lite transaction at a time to APB3 (SETUP -> ACCESS).
//
// Differences from the previous version:
//   * AW and W are captured independently (both may arrive on the same cycle).
//   * BVALID / RVALID are held until the master accepts the response, instead
//     of being single-cycle pulses that can be missed.
//   * PADDR/PWRITE/PWDATA are stable for the whole SETUP and ACCESS phases.
//------------------------------------------------------------------------------
module axi_lite_to_apb #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
) (
  input  logic                   clk,
  input  logic                   reset_n,
  //---------------------- AXI4-Lite slave side ------------------------------
  input  logic                   s_awvalid,
  output logic                   s_awready,
  input  logic [ADDR_WIDTH-1:0]  s_awaddr,
  input  logic [2:0]             s_awprot,
  input  logic                   s_wvalid,
  output logic                   s_wready,
  input  logic [DATA_WIDTH-1:0]  s_wdata,
  input  logic [3:0]             s_wstrb,
  output logic                   s_bvalid,
  input  logic                   s_bready,
  output logic [1:0]             s_bresp,
  input  logic                   s_arvalid,
  output logic                   s_arready,
  input  logic [ADDR_WIDTH-1:0]  s_araddr,
  input  logic [2:0]             s_arprot,
  output logic                   s_rvalid,
  input  logic                   s_rready,
  output logic [DATA_WIDTH-1:0]  s_rdata,
  output logic [1:0]             s_rresp,
  //---------------------- APB master side -----------------------------------
  output logic                   penable,
  output logic                   pwrite,
  output logic [ADDR_WIDTH-1:0]  paddr,
  output logic [DATA_WIDTH-1:0]  pwdata,
  output logic [3:0]             pstrb,
  input  logic                   pslverr,
  input  logic [DATA_WIDTH-1:0]  prdata,
  input  logic                   pready
);

  typedef enum logic [2:0] {
    B_IDLE,
    B_SETUP,
    B_ACCESS,
    B_WRESP,
    B_RRESP
  } bp_state_e;

  bp_state_e state, state_n;

  logic                  wr_q;
  logic [ADDR_WIDTH-1:0] addr_q;
  logic [DATA_WIDTH-1:0] wdata_q;
  logic [3:0]            wstrb_q;
  logic [1:0]            resp_q;

  // AW and W may arrive in different cycles (the request/grant adapter always
  // does), so each channel is latched on its own and the transaction starts
  // when both have been seen.  Without this the write never left B_IDLE and
  // every APB store hung the core in its memory state.
  logic                  have_aw, have_w;
  logic [ADDR_WIDTH-1:0] awaddr_q;

  // APB guarantees PRDATA is valid during ACCESS only, so it must be captured
  // at the end of ACCESS.  Driving s_rdata straight from the peripheral's
  // combinational prdata returned 0 (most peripherals gate it on penable),
  // which made every APB read-back fail.
  logic [DATA_WIDTH-1:0] rdata_q;

  logic aw_ok, w_ok, ar_ok;
  logic wr_complete;

  assign aw_ok = s_awvalid & s_awready;
  assign w_ok  = s_wvalid  & s_wready;
  assign ar_ok = s_arvalid & s_arready;
  assign wr_complete = (have_aw | aw_ok) & (have_w | w_ok);

  assign s_awready = (state == B_IDLE);
  assign s_wready  = (state == B_IDLE);
  assign s_arready = (state == B_IDLE);

  always_comb begin
    state_n = state;
    unique case (state)
      B_IDLE: begin
        if (wr_complete)                       state_n = B_SETUP;
        else if (ar_ok && !have_aw && !have_w && !aw_ok && !w_ok)
                                               state_n = B_SETUP;
      end
      B_SETUP:                  state_n = B_ACCESS;
      B_ACCESS:  if (pready) begin
                   if (wr_q) state_n = B_WRESP;
                   else      state_n = B_RRESP;
                 end
      B_WRESP:   if (s_bready)  state_n = B_IDLE;
      B_RRESP:   if (s_rready)  state_n = B_IDLE;
      default:                  state_n = B_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state   <= B_IDLE;
      wr_q    <= 1'b0;
      addr_q  <= '0;
      wdata_q <= '0;
      wstrb_q <= '0;
      resp_q  <= 2'b00;
      rdata_q <= '0;
      have_aw <= 1'b0;
      have_w  <= 1'b0;
      awaddr_q <= '0;
    end else begin
      state <= state_n;

      if (state == B_IDLE) begin
        // Latch whichever half of the write has arrived.
        if (aw_ok) begin awaddr_q <= s_awaddr; have_aw <= 1'b1; end
        if (w_ok)  begin wdata_q  <= s_wdata; wstrb_q <= s_wstrb; have_w <= 1'b1; end

        if (wr_complete) begin
          // Both halves present: start the APB cycle and free the latches.
          wr_q     <= 1'b1;
          addr_q   <= aw_ok ? s_awaddr : awaddr_q;
          have_aw  <= 1'b0;
          have_w   <= 1'b0;
        end else if (ar_ok && !have_aw && !have_w && !aw_ok && !w_ok) begin
          wr_q    <= 1'b0;
          addr_q  <= s_araddr;
        end
      end

      if (state == B_ACCESS && pready) begin
        resp_q  <= pslverr ? 2'b10 : 2'b00;
        rdata_q <= prdata;
      end
    end
  end

  assign penable = (state == B_ACCESS);
  assign pwrite  = wr_q;
  assign paddr   = addr_q;
  assign pwdata  = wdata_q;
  assign pstrb   = wstrb_q;

  assign s_bvalid = (state == B_WRESP);
  assign s_bresp  = resp_q;
  assign s_rvalid = (state == B_RRESP);
  assign s_rdata  = rdata_q;
  assign s_rresp  = resp_q;

endmodule
