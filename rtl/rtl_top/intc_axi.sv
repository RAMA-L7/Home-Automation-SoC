//------------------------------------------------------------------------------
// Home-Automation-SoC — INTC AXI4-Lite Slave (CLINT + PLIC)
// Stage 2 RTL
//
// Presents CLINT and PLIC as a single AXI4-Lite slave port:
//   addr[12] == 0  -> CLINT (4 KB at 0x8000_0000)
//   addr[12] == 1  -> PLIC  (4 KB at 0x8000_1000)
//
// This wrapper replaces the previous arrangement in which clint and plic were
// both connected to the same AXI signals, producing multiple drivers on the
// shared bus and undefined behaviour.
//------------------------------------------------------------------------------
module intc_axi (
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
  // Interrupt sources / outputs
  input  logic [7:0]   ext_irq,
  output logic         irq_ext,
  output logic         irq_timer,
  output logic         irq_soft,
  output logic [63:0]  mtime
);

  typedef enum logic [1:0] {S_IDLE, S_WRESP, S_RRESP} st_e;
  st_e state, state_n;

  logic [31:0] addr_q;
  logic        wr_en;
  logic [11:0] clint_waddr, clint_raddr, plic_waddr, plic_raddr;
  logic [31:0] clint_rdata, plic_rdata;
  logic [31:0] wdata_q;

  wire is_plic   = addr_q[12];
  wire wr_fire   = awvalid & wvalid & awready & wready;
  wire rd_fire   = arvalid & arready;

  assign awready = (state == S_IDLE) & ~arvalid;
  assign wready  = (state == S_IDLE) & ~arvalid;
  assign arready = (state == S_IDLE) & ~(awvalid & wvalid);

  always_comb begin
    state_n = state;
    unique case (state)
      S_IDLE:  if (wr_fire) state_n = S_WRESP;
               else if (rd_fire) state_n = S_RRESP;
      S_WRESP: if (bready) state_n = S_IDLE;
      S_RRESP: if (rready) state_n = S_IDLE;
      default: state_n = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state      <= S_IDLE;
      addr_q     <= '0;
      wdata_q    <= '0;
      wr_en      <= 1'b0;
    end else begin
      state <= state_n;
      wr_en <= wr_fire;
      if (wr_fire) begin
        addr_q  <= awaddr;
        wdata_q <= wdata;
      end
      if (rd_fire) addr_q <= araddr;
    end
  end

  // Register-port addressing (offsets within each 4 KB window)
  assign clint_waddr = addr_q[11:0];
  assign plic_waddr  = addr_q[11:0];
  assign clint_raddr = addr_q[11:0];
  assign plic_raddr  = addr_q[11:0];

  clint clint_inst (
    .clk       (clk),
    .reset_n   (reset_n),
    .wr_en     (wr_en & ~is_plic),
    .wr_addr   (clint_waddr),
    .wr_data   (wdata_q),
    .rd_addr   (clint_raddr),
    .rd_data   (clint_rdata),
    .irq_soft  (irq_soft),
    .irq_timer (irq_timer),
    .time_out  (mtime)
  );

  plic plic_inst (
    .clk      (clk),
    .reset_n  (reset_n),
    .wr_en    (wr_en & is_plic),
    .wr_addr  (plic_waddr),
    .wr_data  (wdata_q),
    .rd_addr  (plic_raddr),
    .rd_data  (plic_rdata),
    .ext_irq  (ext_irq),
    .irq_out  (irq_ext)
  );

  assign bvalid = (state == S_WRESP);
  assign bresp  = 2'b00;
  assign rvalid = (state == S_RRESP);
  assign rdata  = is_plic ? plic_rdata : clint_rdata;
  assign rresp  = 2'b00;

endmodule
