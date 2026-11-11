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
  parameter ADDR_WIDTH = 16,           // 16 KB
  parameter DATA_WIDTH = 32,
  parameter MEM_FILE   = "",
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
  logic [DATA_WIDTH-1:0] mem [0:WORDS-1];

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
      endcase
    end
  end

  //----------------------------------------------------------------------------
  // AXI4-Lite slave: read-only
  //----------------------------------------------------------------------------
  typedef enum logic [1:0] {AX_IDLE, AX_RRESP, AX_BRESP} ax_state_e;
  ax_state_e ax_state;
  logic [ADDR_WIDTH-1:0] ax_raddr_q;

  assign awready = (ax_state == AX_IDLE) & ~arvalid;
  assign wready  = (ax_state == AX_IDLE) & ~arvalid;
  assign arready = (ax_state == AX_IDLE) & ~awvalid;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ax_state   <= AX_IDLE;
      ax_raddr_q <= '0;
    end else begin
      case (ax_state)
        AX_IDLE: begin
          if (awvalid && wvalid) ax_state <= AX_BRESP;
          else if (arvalid) begin
            ax_raddr_q <= araddr[ADDR_WIDTH-1:0];
            ax_state   <= AX_RRESP;
          end
        end
        AX_RRESP: if (r_rready) ax_state <= AX_IDLE;
        AX_BRESP: if (bready)   ax_state <= AX_IDLE;
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
