//------------------------------------------------------------------------------
// Home-Automation-SoC — Power Manager Registers (APB)
// Stage 2 RTL
//
// APB registers for the power manager:
//   0x00 PM_CTRL     - RW - bit0: sleep_request
//   0x04 PM_STATUS   - RO - bit0: in_sleep
//   0x08 PM_WAKE_EN  - RW - bit0: wake_enable
//------------------------------------------------------------------------------
module power_mgr_regs (
  input  logic         pclk,
  input  logic         presetn,
  input  logic         penable,
  input  logic         pwrite,
  input  logic [31:0]  paddr,
  input  logic [31:0]  pwdata,
  input  logic [3:0]   pstrb,
  output logic [31:0]  prdata,
  output logic         pready,
  output logic         pslverr,
  output logic         irq,
  output logic         sleep_req_o
);

  logic sleep_req, wake_en;
  logic in_sleep;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      sleep_req <= 1'b0; wake_en <= 1'b0; in_sleep <= 1'b0;
    end else begin
      in_sleep <= sleep_req;
      if (penable && pwrite) begin
        if (paddr[11:2] == 10'd0) sleep_req <= pwdata[0];
        if (paddr[11:2] == 10'd2) wake_en   <= pwdata[0];
      end
    end
  end

  assign irq = 1'b0;
  assign sleep_req_o = sleep_req;

  always_comb begin
    unique case (paddr[11:2])
      10'd0: prdata = {31'd0, sleep_req};
      10'd1: prdata = {31'd0, in_sleep};
      10'd2: prdata = {31'd0, wake_en};
      default: prdata = 32'd0;
    endcase
  end

  assign pready = 1'b1;
  assign pslverr = 1'b0;

endmodule
