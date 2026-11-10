//------------------------------------------------------------------------------
// Home-Automation-SoC — PLIC (Platform Level Interrupt Controller)
// Stage 2 RTL
//
// Simple PLIC: 4 external interrupt sources, each with a priority register,
// and one machine-mode context with enable bits, threshold, and claim.
//
// Register offsets (from base at 0x8000_1000):
//   0x0000 : source 0 priority
//   0x0004 : source 1 priority
//   0x0008 : source 2 priority
//   0x000C : source 3 priority
//   0x2000 : context enable bits
//   0x2004 : context threshold
//   0x2008 : context claim (RO, RW1C)
//------------------------------------------------------------------------------
module plic (
  input  logic         clk,
  input  logic         reset_n,
  // AXI4-Lite write address channel
  input  logic         awvalid,
  input  logic [15:0]  awaddr,
  output logic         awready,
  // AXI4-Lite write data channel
  input  logic         wvalid,
  input  logic [31:0]  wdata,
  input  logic [3:0]   wstrb,
  output logic         wready,
  // AXI4-Lite write response channel
  output logic         bvalid,
  input  logic         bready,
  output logic [1:0]   bresp,
  // AXI4-Lite read address channel
  input  logic         arvalid,
  input  logic [15:0]  araddr,
  output logic         arready,
  // AXI4-Lite read data channel
  output logic         rvalid,
  input  logic         rready,
  output logic [31:0]  rdata,
  output logic [1:0]   rresp,
  // Interrupts
  input  logic [31:0]  ext_irq,
  output logic         irq_out
);

  logic [7:0] priority0, priority1, priority2, priority3;
  logic [3:0] enable;
  logic [7:0] threshold;
  logic [3:0] pending;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      priority0 <= 8'd0; priority1 <= 8'd0; priority2 <= 8'd0; priority3 <= 8'd0;
      enable    <= 4'd0;
      threshold <= 8'd0;
    end else begin
      if (awvalid && awready && wvalid && wready) begin
        unique case (awaddr[15:2])
          14'h0000: priority0 <= wdata[7:0];
          14'h0001: priority1 <= wdata[7:0];
          14'h0002: priority2 <= wdata[7:0];
          14'h0003: priority3 <= wdata[7:0];
          14'h0800: enable    <= wdata[3:0];
          14'h0801: threshold <= wdata[7:0];
        endcase
      end
      pending <= ext_irq[3:0];
    end
  end

  logic [7:0] priority_arr [0:3];
  always_comb begin
    priority_arr[0] = priority0;
    priority_arr[1] = priority1;
    priority_arr[2] = priority2;
    priority_arr[3] = priority3;
  end

  logic [3:0] candidates;
  logic [1:0] claim_id;
  always_comb begin
    candidates = pending & enable;
    claim_id   = 2'd0;
    irq_out    = 1'b0;
    for (int i = 0; i < 4; i++) begin
      if (candidates[i] && priority_arr[i] > threshold) begin
        claim_id = i[1:0];
        irq_out  = 1'b1;
      end
    end
  end

  assign awready = 1'b1;
  assign wready  = 1'b1;
  assign arready = 1'b1;

  always_comb begin
    rdata = 32'd0;
    if (arvalid) begin
      unique case (araddr[15:2])
        14'h0000: rdata = {24'd0, priority0};
        14'h0001: rdata = {24'd0, priority1};
        14'h0002: rdata = {24'd0, priority2};
        14'h0003: rdata = {24'd0, priority3};
        14'h0800: rdata = {28'd0, enable};
        14'h0801: rdata = {24'd0, threshold};
        14'h0802: rdata = {28'd0, pending};
        default:  rdata = 32'd0;
      endcase
    end
  end

  assign rvalid = arvalid;
  assign bvalid = awvalid && wvalid;
  assign bresp  = 2'b00;
  assign rresp  = 2'b00;

endmodule
