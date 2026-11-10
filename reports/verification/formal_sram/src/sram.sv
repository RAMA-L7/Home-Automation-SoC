//------------------------------------------------------------------------------
// Home-Automation-SoC — On-Chip SRAM (simple model)
// Stage 2 RTL
//
// Single-cycle synchronous SRAM model for simulation/FPGA. In ASIC this is
// replaced by an OpenRAM-generated sky130 SRAM macro with the same AXI4-Lite
// slave interface.
//
// Map: 0x2000_0000 .. 0x2001_FFFF (128 KB), byte-addressable, 32-bit data.
//------------------------------------------------------------------------------
module sram #(
  parameter ADDR_WIDTH = 18,           // 128 KB = 2^18 bytes
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
  input  logic                   rready
);

  localparam int WORDS = 1 << (ADDR_WIDTH - 2);
  logic [DATA_WIDTH-1:0] mem [0:WORDS-1];

  // Write address handshake
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) awready <= 1'b0;
    else          awready <= awvalid & ~awready;
  end

  // Write data handshake
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) wready <= 1'b0;
    else          wready <= wvalid & ~wready;
  end

  // Write data capture + memory write
  logic [ADDR_WIDTH-1:0] waddr_q;
  logic [DATA_WIDTH-1:0] wdata_q;
  logic [3:0]            wstrb_q;
  logic                  write_d;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      waddr_q <= '0; wdata_q <= '0; wstrb_q <= 4'b0; write_d <= 1'b0;
    end else begin
      write_d <= awvalid & awready & wvalid & wready;
      if (awvalid & awready)  waddr_q <= awaddr;
      if (wvalid & wready) begin
        wdata_q <= wdata;
        wstrb_q <= wstrb;
      end
    end
  end

  // Memory write (byte strobed)
  always_ff @(posedge clk) begin
    if (write_d) begin
      int word_idx = waddr_q[ADDR_WIDTH-1:2];
      if (wstrb_q[0]) mem[word_idx][7:0]   <= wdata_q[7:0];
      if (wstrb_q[1]) mem[word_idx][15:8]  <= wdata_q[15:8];
      if (wstrb_q[2]) mem[word_idx][23:16] <= wdata_q[23:16];
      if (wstrb_q[3]) mem[word_idx][31:24] <= wdata_q[31:24];
    end
  end

  // Read address handshake
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) arready <= 1'b0;
    else          arready <= arvalid & ~arready;
  end

  // Read data path: capture address, drive data next cycle
  logic [ADDR_WIDTH-1:0] raddr_q;
  logic                  read_d;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      raddr_q <= '0; read_d <= 1'b0;
    end else begin
      read_d <= arvalid & arready;
      if (arvalid & arready) raddr_q <= araddr;
    end
  end

  assign bvalid = write_d;            // one-cycle write response
  assign bresp  = 2'b00;              // OKAY
  assign rvalid = read_d;
  assign rdata  = mem[raddr_q[ADDR_WIDTH-1:2]];
  assign rresp  = 2'b00;

  // Optional init (simulation only)
  initial begin
    if (MEM_FILE != "") $readmemh(MEM_FILE, mem);
  end

endmodule
