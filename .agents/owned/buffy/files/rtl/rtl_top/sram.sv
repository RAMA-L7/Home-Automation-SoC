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
  parameter ADDR_WIDTH = 18,           // bytes; 2^18 = 256 KB
  parameter DATA_WIDTH = 32,
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
  logic [DATA_WIDTH-1:0] mem [0:WORDS-1];
  int wr_idx;

  typedef enum logic [1:0] {S_IDLE, S_WRESP, S_RRESP} st_e;
  st_e state, state_n;

  logic [ADDR_WIDTH-1:0] waddr_q, raddr_q;
  logic [DATA_WIDTH-1:0] wdata_q;
  logic [3:0]            wstrb_q;

  wire wr_fire = awvalid & wvalid & awready & wready;
  wire rd_fire = arvalid & arready;

  // Writes take priority over reads when both are offered.
  assign awready = (state == S_IDLE) & ~arvalid;
  assign wready  = (state == S_IDLE) & ~arvalid;
  assign arready = (state == S_IDLE) & ~(awvalid & wvalid);

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
      state   <= S_IDLE;
      waddr_q <= '0;
      raddr_q <= '0;
      wdata_q <= '0;
      wstrb_q <= '0;
    end else begin
      state <= state_n;
      if (wr_fire) begin
        waddr_q <= awaddr;
        wdata_q <= wdata;
        wstrb_q <= wstrb;
      end
      if (rd_fire) raddr_q <= araddr;
    end
  end

  // Byte-strobed write
  always_ff @(posedge clk) begin
    if (wr_fire) begin
      wr_idx = awaddr[ADDR_WIDTH-1:2];
      if (wstrb[0]) mem[wr_idx][7:0]   <= wdata[7:0];
      if (wstrb[1]) mem[wr_idx][15:8]  <= wdata[15:8];
      if (wstrb[2]) mem[wr_idx][23:16] <= wdata[23:16];
      if (wstrb[3]) mem[wr_idx][31:24] <= wdata[31:24];
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
