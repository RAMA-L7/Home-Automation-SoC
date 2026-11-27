//------------------------------------------------------------------------------
// Home-Automation-SoC — On-Chip SRAM (AXI4-Lite slave model)
// Stage 2 RTL (reworked)
//
// Behavioural single-port SRAM with a correct AXI4-Lite slave interface.
// In an ASIC flow this is replaced by an OpenRAM sky130 macro behind the same
// interface; on FPGA it infers block RAM.
//
// The previous version toggled AWREADY/WREADY as a divide-by-two of VALID,
// which is not a legal handshake and lost every other transaction.
//------------------------------------------------------------------------------
module sram #(
  // 17 address bits -> 2^17 bytes = 128 KB, the FR-MEM-001 SoC SRAM aperture.
  // The default used to be 18 (256 KB), allocating 2x the decoded aperture
  // (F5).  The TCM instance overrides this with 15 (32 KB, FR-MEM-002).
  parameter int ADDR_WIDTH = 17,           // bytes; 2^17 = 128 KB
  parameter int DATA_WIDTH = 32,
  // verilog_lint: waive explicit-parameter-storage-type
  parameter MEM_FILE   = ""
) (
  input  logic                   clk,
  input  logic                   reset_n,
  // AXI4-Lite write address channel
  input  logic                   awvalid,
  input  logic [ADDR_WIDTH-1:0]  awaddr,
  output logic                   awready,
  // AXI4-Lite write data channel
  input  logic                   wvalid,
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   wready,
  // AXI4-Lite write response channel
  output logic                   bvalid,
  input  logic                   bready,
  output logic [1:0]             bresp,
  // AXI4-Lite read address channel
  input  logic                   arvalid,
  input  logic [ADDR_WIDTH-1:0]  araddr,
  output logic                   arready,
  // AXI4-Lite read data channel
  output logic                   rvalid,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic [1:0]             rresp,
  input  logic                   rready,
  // Instruction read port (execute-in-place support)
  input  logic                   i_req,
  input  logic [ADDR_WIDTH-1:0]  i_addr,
  output logic                   i_gnt,
  output logic [DATA_WIDTH-1:0]  i_rdata,
  output logic                   i_rvalid
);

  localparam int WORDS = 1 << (ADDR_WIDTH - 2);
  logic [DATA_WIDTH-1:0] mem [WORDS];

  typedef enum logic [1:0] {S_IDLE, S_WRESP, S_RRESP} st_e;
  st_e state, state_n;

  logic [ADDR_WIDTH-1:0] raddr_q;
  logic [DATA_WIDTH-1:0] wdata_q;
  logic [3:0]            wstrb_q;

  //--------------------------------------------------------------------------
  // AXI4-Lite write channels are INDEPENDENT.
  //
  // AW and W may be accepted in different cycles in either order, and the
  // slave must remember an accepted half until its partner arrives.  The
  // previous implementation evaluated `awvalid & wvalid` in one cycle and took
  // the write index from the live `awaddr`.  An address-first master therefore
  // saw AWREADY asserted (its address was accepted) and then lost the write
  // entirely, and a data-first master could pair fresh data with a stale
  // address.  The SoC hid this because axi_lite_interconnect holds both
  // channels and presents them together; any other master does not.
  //
  // aw_have_q/w_have_q are the remembered halves.  `*_have_c` includes the
  // half being accepted in the current cycle, so address and data arriving
  // together still commit in the same cycle as before.
  //--------------------------------------------------------------------------
  logic                  aw_have_q;
  logic [ADDR_WIDTH-1:0] aw_addr_q;
  logic                  w_have_q;

  wire aw_accept = awvalid & awready;
  wire w_accept  = wvalid  & wready;

  wire have_aw_c = aw_have_q | awvalid;
  wire have_w_c  = w_have_q  | wvalid;

  // A write can commit as soon as both halves are available.
  wire wr_commit = (state == S_IDLE) & have_aw_c & have_w_c;

  // Arbitration: a completable write wins the cycle; otherwise a presented
  // read is served.  Neither ready depends on the other ready (that is a
  // combinational loop), so no combination of AW/W/AR can stall both sides.
  assign arready = reset_n & (state == S_IDLE) & ~wr_commit;
  assign awready = reset_n & (state == S_IDLE) & ~aw_have_q & ~(arvalid & ~wr_commit);
  assign wready  = reset_n & (state == S_IDLE) & ~w_have_q  & ~(arvalid & ~wr_commit);

  // A write commits only when the slave is not in reset.  Without this gate the
  // byte-strobe write block (which has no reset branch) could commit a word on
  // the same posedge that reset_n falls, so a reset would not reliably abort an
  // in-flight transaction.  The capture registers are cleared by the async
  // reset, which is what drops a half-transaction across a reset.
  wire wr_fire = reset_n & wr_commit;
  wire rd_fire = reset_n & (state == S_IDLE) & arvalid & ~wr_commit;

  // Address and data used by the commit: the remembered half if there is one,
  // otherwise the half arriving now.
  wire [ADDR_WIDTH-1:0] wr_addr = aw_have_q ? aw_addr_q : awaddr;
  wire [DATA_WIDTH-1:0] wr_data = w_have_q  ? wdata_q  : wdata;
  wire [3:0]            wr_strb = w_have_q  ? wstrb_q  : wstrb;
  wire [ADDR_WIDTH-3:0] wr_idx  = wr_addr[ADDR_WIDTH-1:2];

  always_comb begin
    state_n = state;
    unique case (state)
      S_IDLE:  if (wr_fire) state_n = S_WRESP;
               else if (rd_fire) state_n = S_RRESP;
      S_WRESP: if (bready)  state_n = S_IDLE;
      S_RRESP: if (rready)  state_n = S_IDLE;
      default: state_n = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state     <= S_IDLE;
      raddr_q   <= '0;
      wdata_q   <= '0;
      wstrb_q   <= '0;
      aw_have_q <= 1'b0;
      aw_addr_q <= '0;
      w_have_q  <= 1'b0;
    end else begin
      state <= state_n;
      if (aw_accept) begin
        aw_addr_q <= awaddr;
        aw_have_q <= 1'b1;
      end
      if (w_accept) begin
        wdata_q  <= wdata;
        wstrb_q  <= wstrb;
        w_have_q <= 1'b1;
      end
      // Commit clears both halves (ordered last on purpose).
      if (wr_fire) begin
        aw_have_q <= 1'b0;
        w_have_q  <= 1'b0;
      end
      if (rd_fire) raddr_q <= araddr;
    end
  end

  // Byte-strobed write
  always_ff @(posedge clk) begin
    if (wr_fire) begin
      if (wr_strb[0]) mem[wr_idx][7:0]   <= wr_data[7:0];
      if (wr_strb[1]) mem[wr_idx][15:8]  <= wr_data[15:8];
      if (wr_strb[2]) mem[wr_idx][23:16] <= wr_data[23:16];
      if (wr_strb[3]) mem[wr_idx][31:24] <= wr_data[31:24];
    end
  end

  //----------------------------------------------------------------------------
  // Instruction port: one-cycle synchronous read, independent of the AXI FSM.
  // (The array therefore has two read ports; an ASIC flow must instantiate a
  //  dual-port macro — recorded as an implementation note.)
  //----------------------------------------------------------------------------
  logic                  i_req_q;
  logic [ADDR_WIDTH-1:0] i_addr_q;

  assign i_gnt    = i_req;
  assign i_rvalid = i_req_q;
  assign i_rdata  = mem[i_addr_q[ADDR_WIDTH-1:2]];

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      i_req_q  <= 1'b0;
      i_addr_q <= '0;
    end else begin
      i_req_q <= i_req;
      if (i_req) i_addr_q <= i_addr;
    end
  end

  assign bvalid = (state == S_WRESP);
  assign bresp  = 2'b00;
  assign rvalid = (state == S_RRESP);
  assign rdata  = mem[raddr_q[ADDR_WIDTH-1:2]];
  assign rresp  = 2'b00;

  initial begin
    if (MEM_FILE != "") $readmemh(MEM_FILE, mem);
  end

endmodule
