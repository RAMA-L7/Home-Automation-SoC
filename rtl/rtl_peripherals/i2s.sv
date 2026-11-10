//------------------------------------------------------------------------------
// Home-Automation-SoC — I2S Transmitter (APB)
// Stage 2 RTL (reworked — previous version tied bclk to pclk and dout to a
// single bit, which is not an I2S stream)
//
// Philips I2S, 16-bit samples, MSB first, one-bit delay after LRCLK edge.
// bclk = pclk / (2 * (CLKDIV+1)); LRCLK toggles every 16 bclk periods.
//
// Registers (4-byte offsets):
//   0x00 CTRL    RW  bit0 enable
//   0x04 DATA    WO  16-bit left/right sample (same value both channels)
//   0x08 STATUS  RO  bit0 tx_ready (sample slot free)
//   0x0C CLKDIV  RW  half-bit divider (default 8)
//------------------------------------------------------------------------------
module i2s (
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
  output logic         i2s_bclk,
  output logic         i2s_lrclk,
  output logic         i2s_dout,
  input  logic         i2s_din,
  output logic         irq
);

  logic        enable;
  logic [15:0] tx_sample, pending_sample;
  logic        have_sample;
  logic [15:0] clkdiv, div_cnt;
  logic        bclk_r;
  logic [4:0]  bit_cnt;         // 0..31
  logic [15:0] shift;
  logic        lrclk_r;

  assign i2s_bclk  = bclk_r;
  assign i2s_lrclk = lrclk_r;

  wire bclk_tick = (div_cnt == 16'd0);

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      div_cnt <= 16'd0;
      bclk_r  <= 1'b0;
    end else if (bclk_tick) begin
      div_cnt <= clkdiv;
      bclk_r  <= ~bclk_r;
    end else begin
      div_cnt <= div_cnt - 16'd1;
    end
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      enable        <= 1'b0;
      tx_sample     <= 16'd0;
      pending_sample<= 16'd0;
      have_sample   <= 1'b0;
      clkdiv        <= 16'd8;
      bit_cnt       <= 5'd0;
      shift         <= 16'd0;
      lrclk_r       <= 1'b0;
      i2s_dout      <= 1'b0;
    end else begin
      if (penable && pwrite) begin
        case (paddr[11:2])
          10'd0: enable <= pwdata[0];
          10'd1: begin
                   tx_sample     <= pwdata[15:0];
                   pending_sample<= pwdata[15:0];
                   have_sample   <= 1'b1;
                 end
          10'd3: clkdiv <= pwdata[15:0];
          default: ;
        endcase
      end

      // Shift on the falling edge of bclk (data changes on falling edge)
      if (bclk_tick && bclk_r == 1'b0 && enable) begin
        if (bit_cnt[3:0] == 4'd0) begin
          // Start of a channel word
          lrclk_r <= bit_cnt[4];
          shift   <= have_sample ? pending_sample : 16'd0;
          if (have_sample) have_sample <= 1'b0;
          i2s_dout <= 1'b0;              // one-bit I2S delay
        end else if (bit_cnt[3:0] == 4'd1) begin
          i2s_dout <= shift[15];
          shift    <= {shift[14:0], 1'b0};
        end else begin
          i2s_dout <= shift[15];
          shift    <= {shift[14:0], 1'b0};
        end
        bit_cnt <= bit_cnt + 5'd1;
      end else if (!enable) begin
        bit_cnt <= 5'd0;
        i2s_dout<= 1'b0;
        lrclk_r <= 1'b0;
      end
    end
  end

  always_comb begin
    case (paddr[11:2])
      10'd0: prdata = {31'd0, enable};
      10'd2: prdata = {31'd0, ~have_sample};
      10'd3: prdata = {16'd0, clkdiv};
      default: prdata = 32'd0;
    endcase
  end

  assign irq     = 1'b0;
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule
