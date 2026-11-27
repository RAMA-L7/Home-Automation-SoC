//------------------------------------------------------------------------------
// RUN-0029 — standalone depth probe for the four RV32M multiply variants.
//
// NOT part of the SoC. It registers both operands and every product so the
// measured path is exactly flop -> multiplier -> flop, mapped by the same
// Yosys/ABC/liberty configuration as the SoC (scripts/sta/synth_has_soc.ys).
// This answers "how deep is each MUL variant" independently of the core's
// surrounding logic.
//------------------------------------------------------------------------------
module mul_probe (
  input  wire        clk,
  input  wire [31:0] a,
  input  wire [31:0] b,
  output reg  [31:0] mul_lo,
  output reg  [31:0] mulh_ss,
  output reg  [31:0] mulh_su,
  output reg  [31:0] mulhu_uu
);

  reg  [31:0] a_q, b_q;
  always @(posedge clk) begin
    a_q <= a;
    b_q <= b;
  end

  wire [63:0] prod_ss = $signed(a_q) * $signed(b_q);
  wire [63:0] prod_su = $signed(a_q) * $signed({1'b0, b_q});
  wire [63:0] prod_uu = a_q * b_q;

  always @(posedge clk) begin
    mul_lo    <= prod_uu[31:0];   // MUL
    mulh_ss   <= prod_ss[63:32];  // MULH
    mulh_su   <= prod_su[63:32];  // MULHSU
    mulhu_uu  <= prod_uu[63:32];  // MULHU
  end

endmodule
