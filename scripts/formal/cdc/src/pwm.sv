//------------------------------------------------------------------------------
// Home-Automation-SoC — PWM Controller (APB)
// Stage 2 RTL (reworked)
//
// 4 independent channels, 16-bit period/duty.
// Registers (4-byte offsets):
//   0x00 + 8*c  PERIOD[c]
//   0x04 + 8*c  DUTY[c]
//   0x20        CTRL    bit[c] enable
//   0x24        STATUS  bit[c] running
//
// Output duty = DUTY[c] / (PERIOD[c]+1).  With PERIOD=0 the output is a
// constant level (duty >= 1) to avoid a division by zero style hang.
//------------------------------------------------------------------------------
module pwm #(
  parameter WIDTH = 16,
  parameter CHANNELS = 4
) (
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
  output logic [CHANNELS-1:0] pwm_out,
  output logic         irq
);

  logic [WIDTH-1:0] period  [0:CHANNELS-1];
  logic [WIDTH-1:0] duty    [0:CHANNELS-1];
  logic [WIDTH-1:0] counter [0:CHANNELS-1];
  logic [CHANNELS-1:0] enable;

  genvar c;
  generate
    for (c = 0; c < CHANNELS; c++) begin : g_pwm
      always_ff @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
          counter[c] <= '0;
          pwm_out[c] <= 1'b0;
          period[c]  <= '0;
          duty[c]    <= '0;
        end else begin
          if (penable && pwrite) begin
            if (paddr[11:2] == 10'(c*2))     period[c] <= pwdata[WIDTH-1:0];
            if (paddr[11:2] == 10'(c*2 + 1)) duty[c]   <= pwdata[WIDTH-1:0];
          end

          if (enable[c]) begin
            if (counter[c] >= period[c]) counter[c] <= '0;
            else                         counter[c] <= counter[c] + 1'b1;
            pwm_out[c] <= (duty[c] != 0) && (counter[c] < duty[c]);
          end else begin
            counter[c] <= '0;
            pwm_out[c] <= 1'b0;
          end
        end
      end
    end
  endgenerate

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) enable <= '0;
    else if (penable && pwrite && paddr[11:2] == 10'd8)
      enable <= pwdata[CHANNELS-1:0];
  end

  always_comb begin
    prdata = 32'd0;
    if (paddr[11:2] == 10'd8) begin
      prdata = {{(32-CHANNELS){1'b0}}, enable};
    end else if (paddr[11:2] == 10'd9) begin
      prdata = {{(32-CHANNELS){1'b0}}, enable};
    end else if (paddr[11:2] < 10'(CHANNELS*2)) begin
      if (paddr[11:2][0] == 1'b0) prdata = {16'd0, period[paddr[11:2][3:1]]};
      else                        prdata = {16'd0, duty[paddr[11:2][3:1]]};
    end
  end

  assign irq     = 1'b0;
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule
