//------------------------------------------------------------------------------
// Home-Automation-SoC — AXI4-Lite Interconnect (single outstanding)
// Stage 2 RTL (reworked)
//
// Single-master, multi-slave AXI4-Lite interconnect.
//
// Design notes
// ------------
// The previous version derived the slave select combinationally from
// m_awaddr/m_araddr on every cycle, which is incorrect for a master that
// presents AW and W in different cycles (a legal AXI4-Lite behaviour, and
// exactly what the req/gnt adapter does).  This version captures AW and W
// independently into holding registers and only launches the transaction once
// both are present.
//
// One transaction may be outstanding at a time (either one write or one read).
// New transactions are not accepted until the previous one has completed, so
// the master never observes protocol-dependent deadlock.
//
// Unmapped addresses complete locally with SLVERR (DECERR) without touching
// any slave.
//
// Slave indices (see has_addr_map_pkg):
//   0 = Boot ROM (data port), 1 = TCM, 2 = SRAM,
//   3 = QSPI flash, 4 = APB peripherals, 5 = INTC (CLINT + PLIC)
//------------------------------------------------------------------------------
module axi_lite_interconnect #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter NUM_SLAVES = 6
) (
  input  logic                   clk,
  input  logic                   reset_n,
  //---------------------- Master AXI4-Lite (from CPU) ----------------------
  input  logic                   m_awvalid,
  output logic                   m_awready,
  input  logic [ADDR_WIDTH-1:0]  m_awaddr,
  input  logic [2:0]             m_awprot,
  input  logic                   m_wvalid,
  output logic                   m_wready,
  input  logic [DATA_WIDTH-1:0]  m_wdata,
  input  logic [3:0]             m_wstrb,
  output logic                   m_bvalid,
  input  logic                   m_bready,
  output logic [1:0]             m_bresp,
  input  logic                   m_arvalid,
  output logic                   m_arready,
  input  logic [ADDR_WIDTH-1:0]  m_araddr,
  input  logic [2:0]             m_arprot,
  output logic                   m_rvalid,
  input  logic                   m_rready,
  output logic [DATA_WIDTH-1:0]  m_rdata,
  output logic [1:0]             m_rresp,
  //---------------------- Slave AXI4-Lite interfaces ------------------------
  output logic [NUM_SLAVES-1:0]             s_awvalid,
  input  logic [NUM_SLAVES-1:0]             s_awready,
  output logic [ADDR_WIDTH-1:0]             s_awaddr   [NUM_SLAVES],
  output logic [2:0]                        s_awprot   [NUM_SLAVES],
  output logic [NUM_SLAVES-1:0]             s_wvalid,
  input  logic [NUM_SLAVES-1:0]             s_wready,
  output logic [DATA_WIDTH-1:0]             s_wdata    [NUM_SLAVES],
  output logic [3:0]                        s_wstrb    [NUM_SLAVES],
  input  logic [NUM_SLAVES-1:0]             s_bvalid,
  output logic [NUM_SLAVES-1:0]             s_bready,
  input  logic [1:0]                        s_bresp    [NUM_SLAVES],
  output logic [NUM_SLAVES-1:0]             s_arvalid,
  input  logic [NUM_SLAVES-1:0]             s_arready,
  output logic [ADDR_WIDTH-1:0]             s_araddr   [NUM_SLAVES],
  output logic [2:0]                        s_arprot   [NUM_SLAVES],
  input  logic [NUM_SLAVES-1:0]             s_rvalid,
  output logic [NUM_SLAVES-1:0]             s_rready,
  input  logic [DATA_WIDTH-1:0]             s_rdata    [NUM_SLAVES],
  input  logic [1:0]                        s_rresp    [NUM_SLAVES]
);

  import has_addr_map_pkg::*;

  localparam int SELW = (NUM_SLAVES > 1) ? $clog2(NUM_SLAVES) : 1;

  typedef enum logic [2:0] {
    IC_IDLE,       // accepting a new AW/AR/W
    IC_WR_LAUNCH,  // driving AW+W to the selected slave
    IC_WR_RESP,    // waiting for B
    IC_RD_LAUNCH,  // driving AR to the selected slave
    IC_RD_RESP     // waiting for R
  } ic_state_e;

  ic_state_e state, state_n;

  // Held write channels
  logic                aw_hold_valid;
  logic [ADDR_WIDTH-1:0] aw_hold_addr;
  logic [2:0]            aw_hold_prot;
  logic                w_hold_valid;
  logic [DATA_WIDTH-1:0] w_hold_data;
  logic [3:0]            w_hold_strb;

  // Latched transaction target
  logic [SELW-1:0]     txn_sel;
  logic                txn_decode_err;
  logic [ADDR_WIDTH-1:0] rd_hold_addr;
  logic [2:0]            rd_hold_prot;

  //--------------------------------------------------------------------------
  // Address decode
  //--------------------------------------------------------------------------
  // Returns NUM_SLAVES for an unmapped address (decode error).  A function
  // with an output argument is not portable (Icarus rejects it), so the error
  // flag is encoded in the return value instead.
  localparam logic [SELW-1:0] SEL_INVALID = SELW'(NUM_SLAVES);

  function automatic logic [SELW-1:0] decode_sel(input logic [31:0] a);
    case (addr_region(a))
      0: decode_sel = SELW'(0);
      1: decode_sel = SELW'(1);
      2: decode_sel = SELW'(2);
      3: decode_sel = SELW'(3);
      4: decode_sel = SELW'(4);
      5: decode_sel = SELW'(5);
      default: decode_sel = SEL_INVALID;
    endcase
  endfunction

  //--------------------------------------------------------------------------
  // Master-side ready signals
  //--------------------------------------------------------------------------
  logic aw_accept, w_accept, ar_accept;
  assign aw_accept = (state == IC_IDLE) && m_awvalid && !aw_hold_valid;
  assign w_accept  = (state == IC_IDLE) && m_wvalid  && !w_hold_valid;
  assign ar_accept = (state == IC_IDLE) && m_arvalid &&
                     !aw_hold_valid && !w_hold_valid;

  assign m_awready = (state == IC_IDLE) && !aw_hold_valid;
  assign m_wready  = (state == IC_IDLE) && !w_hold_valid;
  assign m_arready = (state == IC_IDLE) && !aw_hold_valid && !w_hold_valid;

  //--------------------------------------------------------------------------
  // Combinational decode of the held addresses
  //--------------------------------------------------------------------------
  logic [SELW-1:0] wr_sel_c, rd_sel_c;
  logic            wr_err_c, rd_err_c;

  assign wr_sel_c = decode_sel(aw_hold_addr);
  assign rd_sel_c = decode_sel(m_araddr);
  assign wr_err_c = (wr_sel_c == SEL_INVALID);
  assign rd_err_c = (rd_sel_c == SEL_INVALID);

  //--------------------------------------------------------------------------
  // Next-state logic
  //--------------------------------------------------------------------------
  logic aw_w_fire;   // both write channels hold valid data
  logic b_fire, r_fire;

  assign aw_w_fire = aw_hold_valid && w_hold_valid;
  assign b_fire    = m_bvalid && m_bready;
  assign r_fire    = m_rvalid && m_rready;

  always_comb begin
    state_n = state;
    case (state)
      IC_IDLE: begin
        if (aw_w_fire)
          if (wr_err_c) state_n = IC_WR_RESP;
          else          state_n = IC_WR_LAUNCH;
        else if (m_arvalid && !aw_hold_valid && !w_hold_valid)
          if (rd_err_c) state_n = IC_RD_RESP;
          else          state_n = IC_RD_LAUNCH;
      end
      IC_WR_LAUNCH: begin
        if (s_awready[txn_sel] && s_wready[txn_sel]) state_n = IC_WR_RESP;
      end
      IC_WR_RESP: begin
        if (b_fire) state_n = IC_IDLE;
      end
      IC_RD_LAUNCH: begin
        if (s_arready[txn_sel]) state_n = IC_RD_RESP;
      end
      IC_RD_RESP: begin
        if (r_fire) state_n = IC_IDLE;
      end
      default: state_n = IC_IDLE;
    endcase
  end

  //--------------------------------------------------------------------------
  // Sequential state + channel holding registers
  //--------------------------------------------------------------------------
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state          <= IC_IDLE;
      aw_hold_valid  <= 1'b0;
      aw_hold_addr   <= '0;
      aw_hold_prot   <= '0;
      w_hold_valid   <= 1'b0;
      w_hold_data    <= '0;
      w_hold_strb    <= '0;
      txn_sel        <= '0;
      txn_decode_err <= 1'b0;
      rd_hold_addr   <= '0;
      rd_hold_prot   <= '0;
    end else begin
      state <= state_n;

      // Capture write address
      if (aw_accept) begin
        aw_hold_valid <= 1'b1;
        aw_hold_addr  <= m_awaddr;
        aw_hold_prot  <= m_awprot;
      end
      // Capture write data
      if (w_accept) begin
        w_hold_valid <= 1'b1;
        w_hold_data  <= m_wdata;
        w_hold_strb  <= m_wstrb;
      end

      // Latch the transaction target once both channels are present
      if (state == IC_IDLE && aw_w_fire) begin
        txn_sel        <= wr_sel_c;
        txn_decode_err <= wr_err_c;
      end
      // Capture read address
      if (state == IC_IDLE && m_arvalid && !aw_hold_valid && !w_hold_valid) begin
        rd_hold_addr   <= m_araddr;
        rd_hold_prot   <= m_arprot;
        txn_sel        <= rd_sel_c;
        txn_decode_err <= rd_err_c;
      end

      // Release holding registers at the end of a transaction
      if (b_fire) begin
        aw_hold_valid <= 1'b0;
        w_hold_valid  <= 1'b0;
      end
      if (r_fire && state == IC_RD_RESP) begin
        aw_hold_valid <= 1'b0;
        w_hold_valid  <= 1'b0;
      end
    end
  end

  //--------------------------------------------------------------------------
  // Slave-side drivers
  //--------------------------------------------------------------------------
  genvar i;
  generate
    for (i = 0; i < NUM_SLAVES; i++) begin : g_slave
      logic sel_w, sel_r;

      assign sel_w = (txn_sel == SELW'(i));

      assign s_awvalid[i] = (state == IC_WR_LAUNCH) && sel_w;
      assign s_wvalid[i]  = (state == IC_WR_LAUNCH) && sel_w;
      assign s_awaddr[i]  = aw_hold_addr;
      assign s_awprot[i]  = aw_hold_prot;
      assign s_wdata[i]   = w_hold_data;
      assign s_wstrb[i]   = w_hold_strb;
      assign s_bready[i]  = (state == IC_WR_RESP) && sel_w && m_bready;

      assign s_arvalid[i] = (state == IC_RD_LAUNCH) && sel_w;
      assign s_araddr[i]  = rd_hold_addr;
      assign s_arprot[i]  = rd_hold_prot;
      assign s_rready[i]  = (state == IC_RD_RESP) && sel_w && m_rready;
    end
  endgenerate

  //--------------------------------------------------------------------------
  // Master-side response drivers
  //--------------------------------------------------------------------------
  assign m_bvalid = (state == IC_WR_RESP) &&
                    (txn_decode_err ? 1'b1 : s_bvalid[txn_sel]);
  assign m_bresp  = (state == IC_WR_RESP) &&
                    (txn_decode_err ? 2'b11 : s_bresp[txn_sel]);

  assign m_rvalid = (state == IC_RD_RESP) &&
                    (txn_decode_err ? 1'b1 : s_rvalid[txn_sel]);
  assign m_rdata  = (state == IC_RD_RESP) &&
                    (txn_decode_err ? 32'h0 : s_rdata[txn_sel]);
  assign m_rresp  = (state == IC_RD_RESP) &&
                    (txn_decode_err ? 2'b11 : s_rresp[txn_sel]);

endmodule
