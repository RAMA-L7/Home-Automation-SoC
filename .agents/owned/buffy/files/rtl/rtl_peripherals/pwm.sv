//------------------------------------------------------------------------------
// Home-Automation-SoC — PWM Controller (APB)
// Stage 2 RTL
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

  logic [WIDTH-1:0] period0, period1, period2, period3;
  logic [WIDTH-1:0] duty0,   duty1,   duty2,   duty3;
  logic [WIDTH-1:0] cnt0, cnt1, cnt2, cnt3;
  logic [CHANNELS-1:0] enable;

  //------------------------------------------------------------------------------
  // Channel 0
  //------------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      cnt0    <= '0;
      pwm_out[0] <= 1'b0;
    end else if (enable[0]) begin
      if (cnt0 >= period0) cnt0 <= '0;
      else                 cnt0 <= cnt0 + 1'b1;
      pwm_out[0] <= (duty0 != 0) && (cnt0 < duty0);
    end else begin
      cnt0    <= '0;
      pwm_out[0] <= 1'b0;
    end
  end

  //------------------------------------------------------------------------------
  // Channel 1
  //------------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      cnt1    <= '0;
      pwm_out[1] <= 1'b0;
    end else if (enable[1]) begin
      if (cnt1 >= period1) cnt1 <= '0;
      else                 cnt1 <= cnt1 + 1'b1;
      pwm_out[1] <= (duty1 != 0) && (cnt1 < duty1);
    end else begin
      cnt1    <= '0;
      pwm_out[1] <= 1'b0;
    end
  end

  //------------------------------------------------------------------------------
  // Channel 2
  //------------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      cnt2    <= '0;
      pwm_out[2] <= 1'b0;
    end else if (enable[2]) begin
      if (cnt2 >= period2) cnt2 <= '0;
      else                 cnt2 <= cnt2 + 1'b1;
      pwm_out[2] <= (duty2 != 0) && (cnt2 < duty2);
    end else begin
      cnt2    <= '0;
      pwm_out[2] <= 1'b0;
    end
  end

  //------------------------------------------------------------------------------
  // Channel 3
  //------------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      cnt3    <= '0;
      pwm_out[3] <= 1'b0;
    end else if (enable[3]) begin
      if (cnt3 >= period3) cnt3 <= '0;
      else                 cnt3 <= cnt3 + 1'b1;
      pwm_out[3] <= (duty3 != 0) && (cnt3 < duty3);
    end else begin
      cnt3    <= '0;
      pwm_out[3] <= 1'b0;
    end
  end

  //------------------------------------------------------------------------------
  // APB Register Interface
  //------------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      period0  <= '0; duty0   <= '0;
      period1  <= '0; duty1   <= '0;
      period2  <= '0; duty2   <= '0;
      period3  <= '0; duty3   <= '0;
      enable   <= '0;
    end else if (penable && pwrite) begin
      case (paddr[11:2])
        10'd0:  period0 <= pwdata[WIDTH-1:0];   // 0x00 PWM0_PERIOD
        10'd1:  duty0   <= pwdata[WIDTH-1:0];   // 0x04 PWM0_DUTY
        10'd2:  period1 <= pwdata[WIDTH-1:0];   // 0x08 PWM1_PERIOD
        10'd3:  duty1   <= pwdata[WIDTH-1:0];   // 0x0C PWM1_DUTY
        10'd4:  period2 <= pwdata[WIDTH-1:0];   // 0x10 PWM2_PERIOD
        10'd5:  duty2   <= pwdata[WIDTH-1:0];   // 0x14 PWM2_DUTY
        10'd6:  period3 <= pwdata[WIDTH-1:0];   // 0x18 PWM3_PERIOD
        10'd7:  duty3   <= pwdata[WIDTH-1:0];   // 0x1C PWM3_DUTY
        10'd8:  enable  <= pwdata[CHANNELS-1:0];// 0x20 PWM_CTRL
      endcase
    end
  end

  always_comb begin
    prdata = 32'd0;
    if (penable && !pwrite) begin
      case (paddr[11:2])
        10'd0: prdata = {{(32-WIDTH){1'b0}}, period0};
        10'd1: prdata = {{(32-WIDTH){1'b0}}, duty0};
        10'd2: prdata = {{(32-WIDTH){1'b0}}, period1};
        10'd3: prdata = {{(32-WIDTH){1'b0}}, duty1};
        10'd4: prdata = {{(32-WIDTH){1'b0}}, period2};
        10'd5: prdata = {{(32-WIDTH){1'b0}}, duty2};
        10'd6: prdata = {{(32-WIDTH){1'b0}}, period3};
        10'd7: prdata = {{(32-WIDTH){1'b0}}, duty3};
        10'd8: prdata = {{(32-CHANNELS){1'b0}}, enable};
        10'd9: prdata = {{(32-CHANNELS){1'b0}}, enable};
        default: prdata = 32'd0;
      endcase
    end
  end

  assign irq     = 1'b0;
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule