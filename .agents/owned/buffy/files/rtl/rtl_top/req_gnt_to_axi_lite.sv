//------------------------------------------------------------------------------
// Home-Automation-SoC — req/gnt to AXI4-Lite Adapter
// Stage 2 RTL (reworked)
//
// Adapts the core's native request/grant memory interface to an AXI4-Lite
// master port.  One transaction in flight.
//
// Contract (this is the interface the core is written against):
//   * req is held high until gnt is observed.
//   * gnt is asserted for one cycle when the request is accepted.
//   * rvalid is asserted for one cycle when the transaction completes,
//     for BOTH reads and writes.  rdata is valid only for reads.
//
// The previous implementation deasserted gnt and asserted rvalid in a way that
// could never satisfy a master waiting for completion, and it drove AWVALID
// only while req was high, so AW could be dropped before handshake.  This
// version drives each AXI channel independently until its handshake occurs.
//------------------------------------------------------------------------------
module req_gnt_to_axi_lite #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
) (
  input  logic                   clk,
  input  logic                   reset_n,
  //------------------ req/gnt side (core) ------------------
  input  logic                   req,
  input  logic [ADDR_WIDTH-1:0]  addr,
  input  logic                   we,           // 1 = write, 0 = read
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   gnt,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic                   rvalid,
  //------------------ AXI4-Lite master side ------------------
  output logic                   m_awvalid,
  input  logic                   m_awready,
  output logic [ADDR_WIDTH-1:0]  m_awaddr,
  output logic [2:0]             m_awprot,
  output logic                   m_wvalid,
  input  logic                   m_wready,
  output logic [DATA_WIDTH-1:0]  m_wdata,
  output logic [3:0]             m_wstrb,
  input  logic                   m_bvalid,
  output logic                   m_bready,
  input  logic [1:0]             m_bresp,
  output logic                   m_arvalid,
  input  logic                   m_arready,
  output logic [ADDR_WIDTH-1:0]  m_araddr,
  output logic [2:0]             m_arprot,
  input  logic                   m_rvalid,
  output logic                   m_rready,
  input  logic [DATA_WIDTH-1:0]  m_rdata,
  input  logic [1:0]             m_rresp
);

  typedef enum logic [2:0] {
    A_IDLE,
    A_WR_AW,
    A_WR_W,
    A_WR_B,
    A_RD_AR,
    A_RD_R,
    A_DONE
  } adapter_state_e;

  adapter_state_e state, state_n;

  logic                  is_write_q;
  logic [ADDR_WIDTH-1:0] addr_q;
  logic [DATA_WIDTH-1:0] wdata_q;
  logic [3:0]            wstrb_q;

  logic aw_fire, w_fire, b_fire, ar_fire, r_fire;

  assign aw_fire = m_awvalid & m_awready;
  assign w_fire  = m_wvalid  & m_wready;
  assign b_fire  = m_bvalid  & m_bready;
  assign ar_fire = m_arvalid & m_arready;
  assign r_fire  = m_rvalid  & m_rready;

  // Accept a request only when idle; grant is combinational so a master that
  // waits for gnt in the same cycle makes forward progress immediately.
  assign gnt = req && (state == A_IDLE);

  always_comb begin
    state_n = state;
    unique case (state)
      A_IDLE:   if (req) begin
                  if (we) state_n = A_WR_AW;
                  else    state_n = A_RD_AR;
                end
      A_WR_AW:  if (aw_fire) state_n = A_WR_W;
      A_WR_W:   if (w_fire)  state_n = A_WR_B;
      A_WR_B:   if (b_fire)  state_n = A_DONE;
      A_RD_AR:  if (ar_fire) state_n = A_RD_R;
      A_RD_R:   if (r_fire)  state_n = A_DONE;
      A_DONE:                state_n = A_IDLE;
      default:               state_n = A_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state      <= A_IDLE;
      is_write_q <= 1'b0;
      addr_q     <= '0;
      wdata_q    <= '0;
      wstrb_q    <= '0;
      rdata      <= '0;
      rvalid     <= 1'b0;
    end else begin
      state <= state_n;

      if (state == A_IDLE && req) begin
        is_write_q <= we;
        addr_q     <= addr;
        wdata_q    <= wdata;
        wstrb_q    <= wstrb;
      end

      rvalid <= (state == A_RD_R && r_fire) || (state == A_WR_B && b_fire);
      if (state == A_RD_R && r_fire) rdata <= m_rdata;
    end
  end

  assign m_awvalid = (state == A_WR_AW);
  assign m_awaddr  = addr_q;
  assign m_awprot  = 3'b000;

  assign m_wvalid  = (state == A_WR_W);
  assign m_wdata   = wdata_q;
  assign m_wstrb   = wstrb_q;

  assign m_bready  = (state == A_WR_B);

  assign m_arvalid = (state == A_RD_AR);
  assign m_araddr  = addr_q;
  assign m_arprot  = 3'b000;

  assign m_rready  = (state == A_RD_R);

endmodule
