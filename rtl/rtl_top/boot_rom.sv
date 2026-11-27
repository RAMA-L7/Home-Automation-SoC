//------------------------------------------------------------------------------
// Home-Automation-SoC — Boot ROM
// Stage 2 RTL (reworked)
//
// 16 KB synchronous ROM initialised from a $readmemh file.  Two independent
// read interfaces:
//   * instruction port  : req / gnt / rvalid (used by the core fetch path)
//   * AXI4-Lite slave   : read-only  (used by the data path for constants)
// Writes through AXI return SLVERR; the ROM is not writable.
//
// Map: 0x0000_0000 .. 0x0000_3FFF
//------------------------------------------------------------------------------
module boot_rom #(
  // 14 address bits -> 2^14 bytes = 16 KB, the FR-MEM-003 aperture.  The
  // default used to be 16 (64 KB), which silently allocated 4x the aperture
  // the address map and the interconnect decode (F5).
  parameter int ADDR_WIDTH = 14,           // 16 KB
  parameter int DATA_WIDTH = 32,
  // verilog_lint: waive explicit-parameter-storage-type
  parameter MEM_FILE   = "",
  // verilog_lint: waive explicit-parameter-storage-type
  parameter INIT_FILE  = ""            // alias kept for tool compatibility
) (
  input  logic                   clk,
  input  logic                   reset_n,
  // Instruction fetch port
  input  logic                   req,
  input  logic [ADDR_WIDTH-1:0]  addr,
  output logic                   gnt,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic                   rvalid,
  // AXI4-Lite slave (data path, read-only)
  input  logic                   awvalid,
  output logic                   awready,
  input  logic [DATA_WIDTH-1:0]  awaddr,
  input  logic                   wvalid,
  output logic                   wready,
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   bvalid,
  input  logic                   bready,
  output logic [1:0]             bresp,
  input  logic                   arvalid,
  output logic                   arready,
  input  logic [DATA_WIDTH-1:0]  araddr,
  output logic                   r_rvalid,
  input  logic                   r_rready,
  output logic [DATA_WIDTH-1:0]  r_rdata,
  output logic [1:0]             r_rresp
);

  localparam int WORDS = 1 << (ADDR_WIDTH - 2);
  logic [DATA_WIDTH-1:0] mem [WORDS];

  //----------------------------------------------------------------------------
  // Instruction port: accept in IDLE, return data on the following cycle.
  //----------------------------------------------------------------------------
  typedef enum logic {IF_IDLE, IF_DATA} if_state_e;
  if_state_e if_state;
  logic [ADDR_WIDTH-1:0] if_addr_q;

  assign gnt    = (if_state == IF_IDLE) && req;
  assign rvalid = (if_state == IF_DATA);
  assign rdata  = mem[if_addr_q[ADDR_WIDTH-1:2]];

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      if_state  <= IF_IDLE;
      if_addr_q <= '0;
    end else begin
      case (if_state)
        IF_IDLE: if (req) begin
                   if_addr_q <= addr;
                   if_state  <= IF_DATA;
                 end
        IF_DATA: if_state <= IF_IDLE;
        default: ;
      endcase
    end
  end

  //----------------------------------------------------------------------------
  // AXI4-Lite slave: read-only
  //----------------------------------------------------------------------------
  typedef enum logic [1:0] {AX_IDLE, AX_RRESP, AX_BRESP} ax_state_e;
  ax_state_e ax_state;
  logic [ADDR_WIDTH-1:0] ax_raddr_q;

  // AW and W are independent channels: the ROM is read-only, but it still has
  // to ACCEPT the write address and data (in either order) and answer with a
  // single SLVERR.  The previous version required `awvalid && wvalid` in the
  // same cycle, so an address-first master was acknowledged and then never got
  // a response — a bus hang, not an error.
  logic aw_have_q, w_have_q;

  wire aw_accept = awvalid & awready;
  wire w_accept  = wvalid  & wready;
  wire have_aw_c = aw_have_q | awvalid;
  wire have_w_c  = w_have_q  | wvalid;
  wire wr_pair   = (ax_state == AX_IDLE) & have_aw_c & have_w_c;

  // Same arbitration as the memory slaves: a completable write wins, otherwise
  // a presented read is served.  Neither ready depends on the other ready.
  assign arready = reset_n & (ax_state == AX_IDLE) & ~wr_pair;
  assign awready = reset_n & (ax_state == AX_IDLE) & ~aw_have_q & ~(arvalid & ~wr_pair);
  assign wready  = reset_n & (ax_state == AX_IDLE) & ~w_have_q  & ~(arvalid & ~wr_pair);

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ax_state   <= AX_IDLE;
      ax_raddr_q <= '0;
      aw_have_q  <= 1'b0;
      w_have_q   <= 1'b0;
    end else begin
      case (ax_state)
        AX_IDLE: begin
          if (aw_accept) aw_have_q <= 1'b1;
          if (w_accept)  w_have_q  <= 1'b1;
          if (wr_pair) begin
            // Both halves present: answer SLVERR and release them.
            aw_have_q <= 1'b0;
            w_have_q  <= 1'b0;
            ax_state  <= AX_BRESP;
          end else if (arvalid && arready) begin
            ax_raddr_q <= araddr[ADDR_WIDTH-1:0];
            ax_state   <= AX_RRESP;
          end
        end
        AX_RRESP: if (r_rready) ax_state <= AX_IDLE;
        AX_BRESP: if (bready)   ax_state <= AX_IDLE;
        default: ;
      endcase
    end
  end

  assign bvalid   = (ax_state == AX_BRESP);
  assign bresp    = 2'b10;                        // SLVERR: ROM is read-only
  assign r_rvalid = (ax_state == AX_RRESP);
  assign r_rdata  = mem[ax_raddr_q[ADDR_WIDTH-1:2]];
  assign r_rresp  = 2'b00;

  //----------------------------------------------------------------------------
  // Contents
  //----------------------------------------------------------------------------
  initial begin
    for (int i = 0; i < WORDS; i++) mem[i] = 32'h0000_0013;  // nop fill
    if ((MEM_FILE != "") || (INIT_FILE != ""))
      $readmemh((MEM_FILE != "") ? MEM_FILE : INIT_FILE, mem);
  end

endmodule
