// ---------------------------------------------------------------------------
// Sky130 HD technology map for Yosys `techmap`.
//
// Corrections vs. the previous version (see ASIC_* review findings):
//   * Port names taken from the library itself (sky130_full_subset.lib):
//       inv_1            A -> Y
//       buf_1            A -> X          <-- output is X, not Y
//       and2_1/and3_1/and4_1  ... -> X  <-- output is X, not Y
//       or2_1/or3_1/or4_1     ... -> X
//       xor2_1/xor3_1         ... -> X
//       nand2_1/nand3_1/nand4_1 ... -> Y
//       nor2_1/nor3_1/nor4_1    ... -> Y
//       mux2_1           A0,A1,S -> X
//       mux4_1           A0..A3,S0,S1 -> X
//       dfrtp_1/2/4      CLK,D -> Q, RESET_B     (scalar pins)
//       dfstp_1/2/4      CLK,D -> Q, SET_B       (scalar pins)
//       dfxtp_1/2/4      CLK,D -> Q              (scalar pins)
//       dfrbp_1/2        CLK,D -> Q,Q_N, RESET_B (scalar pins)
//     The _1/_2/_4 suffix is DRIVE STRENGTH, not bus width. Every sky130 HD
//     sequential cell has 1-bit D and Q. This file therefore instantiates one
//     scalar cell per bit for every register, and never connects a vector to a
//     scalar pin.
//
//   * `$dff` has NO reset port in Yosys (ports are CLK, D, Q). It is mapped to
//     dfxtp_1 (also reset-less). The previous file declared an `R` port, so it
//     could never match a real `$dff` cell.
//   * `$adff` now honours ARST_VALUE: reset-to-0 uses dfrtp (RESET_B),
//     reset-to-1 uses dfstp (SET_B). The previous file declared ARST_VALUE but
//     ignored it, silently resetting every flop to 0.
//   * `$logic_and` / `$logic_or` reduce each operand to a boolean before the
//     2-input gate. The previous file fed wide vectors into scalar pins.
//   * `$eq` / `$ne` / `$logic_not` / `$not` handle any width by extending
//     operands to the result width and building a gate-level chain; the
//     previous bitwise-XNOR hack produced wrong values for Y_WIDTH > 1.
//   * `$add` / `$sub` are decomposed into ordinary gates (xor2/and2/or2 carry
//     chain). Dedicated adder cells are not required; arithmetic therefore no
//     longer has to stay unmapped.
//
// Anything not covered here is left as a Yosys internal cell, so `check` and
// `stat` report it instead of it being silently mis-mapped.
// ---------------------------------------------------------------------------

// =========================== bitwise invert ================================
// $not: Y = ~A, with A extended (sign or zero) to Y_WIDTH.
module $not (A, Y);
  parameter A_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  output [Y_WIDTH-1:0] Y;
  genvar i;
  generate
    for (i = 0; i < Y_WIDTH; i = i + 1) begin : g_bit
      wire a_bit;
      if (i < A_WIDTH) begin : g_in
        assign a_bit = A[i];
      end else begin : g_ext
        assign a_bit = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      sky130_fd_sc_hd__inv_1 u_inv (.A(a_bit), .Y(Y[i]));
    end
  endgenerate
endmodule

// =========================== 2-input bitwise ===============================
module $and (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  genvar i;
  generate
    for (i = 0; i < Y_WIDTH; i = i + 1) begin : g_bit
      wire a_bit, b_bit;
      if (i < A_WIDTH) begin : g_a_in
        assign a_bit = A[i];
      end else begin : g_a_ext
        assign a_bit = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_b_in
        assign b_bit = B[i];
      end else begin : g_b_ext
        assign b_bit = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
      // and2_1 output pin is X
      sky130_fd_sc_hd__and2_1 u_and (.A(a_bit), .B(b_bit), .X(Y[i]));
    end
  endgenerate
endmodule

module $or (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  genvar i;
  generate
    for (i = 0; i < Y_WIDTH; i = i + 1) begin : g_bit
      wire a_bit, b_bit;
      if (i < A_WIDTH) begin : g_a_in
        assign a_bit = A[i];
      end else begin : g_a_ext
        assign a_bit = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_b_in
        assign b_bit = B[i];
      end else begin : g_b_ext
        assign b_bit = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
      sky130_fd_sc_hd__or2_1 u_or (.A(a_bit), .B(b_bit), .X(Y[i]));
    end
  endgenerate
endmodule

module $xor (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  genvar i;
  generate
    for (i = 0; i < Y_WIDTH; i = i + 1) begin : g_bit
      wire a_bit, b_bit;
      if (i < A_WIDTH) begin : g_a_in
        assign a_bit = A[i];
      end else begin : g_a_ext
        assign a_bit = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_b_in
        assign b_bit = B[i];
      end else begin : g_b_ext
        assign b_bit = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
      sky130_fd_sc_hd__xor2_1 u_xor (.A(a_bit), .B(b_bit), .X(Y[i]));
    end
  endgenerate
endmodule

// =========================== reductions ====================================
// All reductions are built as explicit gate chains so the map never emits a
// reduction operator that would itself need mapping again.

module $reduce_or (A, Y);
  parameter A_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  output [Y_WIDTH-1:0] Y;
  wire [A_WIDTH:0] chain;
  assign chain[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < A_WIDTH; i = i + 1) begin : g_or
      sky130_fd_sc_hd__or2_1 u_or (.A(chain[i]), .B(A[i]), .X(chain[i+1]));
    end
  endgenerate
  assign Y = chain[A_WIDTH];
endmodule

module $reduce_bool (A, Y);
  parameter A_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  output [Y_WIDTH-1:0] Y;
  wire [A_WIDTH:0] chain;
  assign chain[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < A_WIDTH; i = i + 1) begin : g_or
      sky130_fd_sc_hd__or2_1 u_or (.A(chain[i]), .B(A[i]), .X(chain[i+1]));
    end
  endgenerate
  assign Y = chain[A_WIDTH];
endmodule

module $reduce_and (A, Y);
  parameter A_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  output [Y_WIDTH-1:0] Y;
  wire [A_WIDTH:0] chain;
  assign chain[0] = 1'b1;
  genvar i;
  generate
    for (i = 0; i < A_WIDTH; i = i + 1) begin : g_and
      sky130_fd_sc_hd__and2_1 u_and (.A(chain[i]), .B(A[i]), .X(chain[i+1]));
    end
  endgenerate
  assign Y = chain[A_WIDTH];
endmodule

module $reduce_xor (A, Y);
  parameter A_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  output [Y_WIDTH-1:0] Y;
  wire [A_WIDTH:0] chain;
  assign chain[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < A_WIDTH; i = i + 1) begin : g_xor
      sky130_fd_sc_hd__xor2_1 u_xor (.A(chain[i]), .B(A[i]), .X(chain[i+1]));
    end
  endgenerate
  assign Y = chain[A_WIDTH];
endmodule

// =========================== logical ops ===================================
// $logic_and: Y = (A != 0) && (B != 0).  Reduce both operands to booleans.
module $logic_and (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  wire [A_WIDTH:0] ra;
  wire [B_WIDTH:0] rb;
  assign ra[0] = 1'b0;
  assign rb[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < A_WIDTH; i = i + 1) begin : g_ra
      sky130_fd_sc_hd__or2_1 u_ra (.A(ra[i]), .B(A[i]), .X(ra[i+1]));
    end
    for (i = 0; i < B_WIDTH; i = i + 1) begin : g_rb
      sky130_fd_sc_hd__or2_1 u_rb (.A(rb[i]), .B(B[i]), .X(rb[i+1]));
    end
  endgenerate
  sky130_fd_sc_hd__and2_1 u_and (.A(ra[A_WIDTH]), .B(rb[B_WIDTH]), .X(Y));
endmodule

module $logic_or (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  wire [A_WIDTH:0] ra;
  wire [B_WIDTH:0] rb;
  assign ra[0] = 1'b0;
  assign rb[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < A_WIDTH; i = i + 1) begin : g_ra
      sky130_fd_sc_hd__or2_1 u_ra (.A(ra[i]), .B(A[i]), .X(ra[i+1]));
    end
    for (i = 0; i < B_WIDTH; i = i + 1) begin : g_rb
      sky130_fd_sc_hd__or2_1 u_rb (.A(rb[i]), .B(B[i]), .X(rb[i+1]));
    end
  endgenerate
  sky130_fd_sc_hd__or2_1 u_or (.A(ra[A_WIDTH]), .B(rb[B_WIDTH]), .X(Y));
endmodule

// $logic_not: Y = (A == 0).  NOR of all bits.
module $logic_not (A, Y);
  parameter A_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  output [Y_WIDTH-1:0] Y;
  wire [A_WIDTH:0] ra;
  assign ra[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < A_WIDTH; i = i + 1) begin : g_ra
      sky130_fd_sc_hd__or2_1 u_ra (.A(ra[i]), .B(A[i]), .X(ra[i+1]));
    end
  endgenerate
  sky130_fd_sc_hd__inv_1 u_inv (.A(ra[A_WIDTH]), .Y(Y));
endmodule

// =========================== equality ======================================
// $eq: Y = (A == B), operands extended to the comparison width.
module $eq (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  localparam CW = (A_WIDTH > B_WIDTH) ? A_WIDTH : B_WIDTH;
  wire [CW-1:0] x;
  wire [CW:0]   r;
  assign r[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < CW; i = i + 1) begin : g_bit
      wire a_bit, b_bit;
      if (i < A_WIDTH) begin : g_a_in
        assign a_bit = A[i];
      end else begin : g_a_ext
        assign a_bit = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_b_in
        assign b_bit = B[i];
      end else begin : g_b_ext
        assign b_bit = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
      sky130_fd_sc_hd__xor2_1 u_xor (.A(a_bit), .B(b_bit), .X(x[i]));
      sky130_fd_sc_hd__or2_1  u_or  (.A(r[i]),  .B(x[i]),  .X(r[i+1]));
    end
  endgenerate
  sky130_fd_sc_hd__inv_1 u_inv (.A(r[CW]), .Y(Y));
endmodule

// $ne: Y = (A != B).
module $ne (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  localparam CW = (A_WIDTH > B_WIDTH) ? A_WIDTH : B_WIDTH;
  wire [CW-1:0] x;
  wire [CW:0]   r;
  assign r[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < CW; i = i + 1) begin : g_bit
      wire a_bit, b_bit;
      if (i < A_WIDTH) begin : g_a_in
        assign a_bit = A[i];
      end else begin : g_a_ext
        assign a_bit = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_b_in
        assign b_bit = B[i];
      end else begin : g_b_ext
        assign b_bit = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
      sky130_fd_sc_hd__xor2_1 u_xor (.A(a_bit), .B(b_bit), .X(x[i]));
      sky130_fd_sc_hd__or2_1  u_or  (.A(r[i]),  .B(x[i]),  .X(r[i+1]));
    end
  endgenerate
  assign Y = r[CW];
endmodule

// =========================== mux ===========================================
module $mux (A, B, S, Y);
  parameter WIDTH = 1;
  input  [WIDTH-1:0] A;
  input  [WIDTH-1:0] B;
  input              S;
  output [WIDTH-1:0] Y;
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : g_bit
      // mux2_1: X = (A0 & !S) | (A1 & S); Yosys $mux: Y = S ? B : A
      sky130_fd_sc_hd__mux2_1 u_mux (.A0(A[i]), .A1(B[i]), .S(S), .X(Y[i]));
    end
  endgenerate
endmodule

module $pmux (A, B, S, Y);
  parameter WIDTH   = 1;
  parameter S_WIDTH = 1;
  input  [WIDTH-1:0]          A;
  input  [WIDTH*S_WIDTH-1:0]  B;
  input  [S_WIDTH-1:0]        S;
  output [WIDTH-1:0]          Y;
  genvar i, k;
  generate
    if (S_WIDTH == 1) begin : g_one
      sky130_fd_sc_hd__mux2_1 u_mux (.A0(A), .A1(B), .S(S[0]), .X(Y));
    end else begin : g_many
      for (i = 0; i < WIDTH; i = i + 1) begin : g_bit
        wire [S_WIDTH-1:0] chain;
        sky130_fd_sc_hd__mux2_1 u_m0 (.A0(A[i]), .A1(B[i]), .S(S[0]), .X(chain[0]));
        for (k = 1; k < S_WIDTH; k = k + 1) begin : g_k
          sky130_fd_sc_hd__mux2_1 u_mk (.A0(chain[k-1]), .A1(B[k*WIDTH+i]), .S(S[k]), .X(chain[k]));
        end
        assign Y[i] = chain[S_WIDTH-1];
      end
    end
  endgenerate
endmodule

// =========================== registers =====================================
// $dff: CLK, D, Q only (no reset in Yosys).  -> dfxtp_1 (no reset pin either).
// A negedge register is built as a posedge cell clocked by the inverted clock,
// which is exactly equivalent and avoids needing a negedge cell.
module $dff (CLK, D, Q);
  parameter WIDTH = 1;
  parameter CLK_POLARITY = 1;
  input  CLK;
  input  [WIDTH-1:0] D;
  output [WIDTH-1:0] Q;

  wire clk_n;
  generate
    if (CLK_POLARITY == 0) begin : g_clk_inv
      sky130_fd_sc_hd__inv_1 u_clk (.A(CLK), .Y(clk_n));
    end else begin : g_clk_pass
      assign clk_n = CLK;
    end
  endgenerate

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : g_bit
      sky130_fd_sc_hd__dfxtp_1 u_ff (.CLK(clk_n), .D(D[i]), .Q(Q[i]));
    end
  endgenerate
endmodule

// $adff: async reset to ARST_VALUE.  reset-to-0 -> dfrtp (RESET_B),
// reset-to-1 -> dfstp (SET_B).  Polarity handled by a single shared inverter.
module $adff (CLK, ARST, D, Q);
  parameter WIDTH = 1;
  parameter CLK_POLARITY = 1;
  parameter ARST_POLARITY = 1;
  parameter ARST_VALUE = 0;
  input  CLK;
  input  ARST;
  input  [WIDTH-1:0] D;
  output [WIDTH-1:0] Q;

  // arst_n is "reset asserted" in active-low form: 0 means reset.
  wire arst_n;
  // clk_n equals CLK for a posedge register and ~CLK for a negedge register,
  // so a single posedge cell type covers both polarities.
  wire clk_n;
  generate
    if (ARST_POLARITY == 1) begin : g_pol_inv
      sky130_fd_sc_hd__inv_1 u_pol (.A(ARST), .Y(arst_n));
    end else begin : g_pol_pass
      assign arst_n = ARST;
    end
    if (CLK_POLARITY == 0) begin : g_clk_inv
      sky130_fd_sc_hd__inv_1 u_clk (.A(CLK), .Y(clk_n));
    end else begin : g_clk_pass
      assign clk_n = CLK;
    end
  endgenerate

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : g_bit
      if (((ARST_VALUE >> i) & 1) == 0) begin : g_reset0
        sky130_fd_sc_hd__dfrtp_1 u_ff (.CLK(clk_n), .D(D[i]), .Q(Q[i]), .RESET_B(arst_n));
      end else begin : g_reset1
        sky130_fd_sc_hd__dfstp_1 u_ff (.CLK(clk_n), .D(D[i]), .Q(Q[i]), .SET_B(arst_n));
      end
    end
  endgenerate
endmodule

// =========================== arithmetic ====================================
// $add: ripple-carry sum of A and B extended to Y_WIDTH.
//   p = a ^ b ;  y = p ^ c ;  c' = (a & b) | (c & p)
module $add (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  wire [Y_WIDTH:0] c;
  assign c[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < Y_WIDTH; i = i + 1) begin : g_bit
      wire a_bit, b_bit, p, g1, g2;
      if (i < A_WIDTH) begin : g_a_in
        assign a_bit = A[i];
      end else begin : g_a_ext
        assign a_bit = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_b_in
        assign b_bit = B[i];
      end else begin : g_b_ext
        assign b_bit = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
      sky130_fd_sc_hd__xor2_1 u_p (.A(a_bit), .B(b_bit), .X(p));
      sky130_fd_sc_hd__xor2_1 u_s (.A(p), .B(c[i]), .X(Y[i]));
      sky130_fd_sc_hd__and2_1 u_g1 (.A(a_bit), .B(b_bit), .X(g1));
      sky130_fd_sc_hd__and2_1 u_g2 (.A(c[i]), .B(p), .X(g2));
      sky130_fd_sc_hd__or2_1  u_c  (.A(g1), .B(g2), .X(c[i+1]));
    end
  endgenerate
endmodule

// $sub: Y = A - B = A + (~B) + 1 (two's complement at width Y_WIDTH).
module $sub (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  wire [Y_WIDTH:0] c;
  assign c[0] = 1'b1;          // +1 for two's complement
  genvar i;
  generate
    for (i = 0; i < Y_WIDTH; i = i + 1) begin : g_bit
      wire a_bit, b_ext, b_bit, p, g1, g2;
      if (i < A_WIDTH) begin : g_a_in
        assign a_bit = A[i];
      end else begin : g_a_ext
        assign a_bit = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_b_in
        assign b_ext = B[i];
      end else begin : g_b_ext
        assign b_ext = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
      sky130_fd_sc_hd__inv_1  u_inv (.A(b_ext), .Y(b_bit));
      sky130_fd_sc_hd__xor2_1 u_p   (.A(a_bit), .B(b_bit), .X(p));
      sky130_fd_sc_hd__xor2_1 u_s   (.A(p),     .B(c[i]),  .X(Y[i]));
      sky130_fd_sc_hd__and2_1 u_g1  (.A(a_bit), .B(b_bit), .X(g1));
      sky130_fd_sc_hd__and2_1 u_g2  (.A(c[i]),  .B(p),     .X(g2));
      sky130_fd_sc_hd__or2_1  u_c   (.A(g1),    .B(g2),    .X(c[i+1]));
    end
  endgenerate
endmodule

// =========================== magnitude compare =============================
// Unsigned/signed compare built as an LSB->MSB priority chain:
//   F(i) = (a[i] < b[i]) | ((a[i] == b[i]) & F(i-1))
// Signed operands are compared by inverting the top bit of both sides.
// cell pattern per bit: xor2 (~diff), inv (~a / eq), and2, and2, or2

module $lt (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  localparam CW = (A_WIDTH > B_WIDTH) ? A_WIDTH : B_WIDTH;
  localparam SG = (A_SIGNED && B_SIGNED);
  wire [CW-1:0]   a_ext, b_ext;
  wire [CW:0]     lt;
  assign lt[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < CW; i = i + 1) begin : g_ext
      if (i < A_WIDTH) begin : g_ai
        assign a_ext[i] = A[i];
      end else begin : g_ae
        assign a_ext[i] = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_bi
        assign b_ext[i] = B[i];
      end else begin : g_be
        assign b_ext[i] = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
    end
    for (i = 0; i < CW; i = i + 1) begin : g_cmp
      wire ae, be, na, diff, lti, eqi, andi;
      if (SG && i == CW-1) begin : g_top
        assign ae = ~a_ext[i];
        assign be = ~b_ext[i];
      end else begin : g_norm
        assign ae = a_ext[i];
        assign be = b_ext[i];
      end
      sky130_fd_sc_hd__xor2_1 u_x  (.A(ae),  .B(be),  .X(diff));
      sky130_fd_sc_hd__inv_1  u_na (.A(ae),  .Y(na));
      sky130_fd_sc_hd__and2_1 u_lt (.A(na),  .B(be),  .X(lti));
      sky130_fd_sc_hd__inv_1  u_eq (.A(diff), .Y(eqi));
      sky130_fd_sc_hd__and2_1 u_an (.A(eqi), .B(lt[i]), .X(andi));
      sky130_fd_sc_hd__or2_1  u_or (.A(lti), .B(andi), .X(lt[i+1]));
    end
  endgenerate
  assign Y = lt[CW];
endmodule

// A > B  ==  B < A
module $gt (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  localparam CW = (A_WIDTH > B_WIDTH) ? A_WIDTH : B_WIDTH;
  localparam SG = (A_SIGNED && B_SIGNED);
  wire [CW-1:0]   a_ext, b_ext;
  wire [CW:0]     lt;
  assign lt[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < CW; i = i + 1) begin : g_ext
      if (i < A_WIDTH) begin : g_ai
        assign a_ext[i] = A[i];
      end else begin : g_ae
        assign a_ext[i] = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_bi
        assign b_ext[i] = B[i];
      end else begin : g_be
        assign b_ext[i] = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
    end
    for (i = 0; i < CW; i = i + 1) begin : g_cmp
      wire ae, be, na, diff, lti, eqi, andi;
      if (SG && i == CW-1) begin : g_top
        assign ae = ~b_ext[i];      // swapped: compute B < A
        assign be = ~a_ext[i];
      end else begin : g_norm
        assign ae = b_ext[i];
        assign be = a_ext[i];
      end
      sky130_fd_sc_hd__xor2_1 u_x  (.A(ae),  .B(be),  .X(diff));
      sky130_fd_sc_hd__inv_1  u_na (.A(ae),  .Y(na));
      sky130_fd_sc_hd__and2_1 u_lt (.A(na),  .B(be),  .X(lti));
      sky130_fd_sc_hd__inv_1  u_eq (.A(diff), .Y(eqi));
      sky130_fd_sc_hd__and2_1 u_an (.A(eqi), .B(lt[i]), .X(andi));
      sky130_fd_sc_hd__or2_1  u_or (.A(lti), .B(andi), .X(lt[i+1]));
    end
  endgenerate
  assign Y = lt[CW];
endmodule

// A >= B  ==  ~(A < B)
module $ge (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  localparam CW = (A_WIDTH > B_WIDTH) ? A_WIDTH : B_WIDTH;
  localparam SG = (A_SIGNED && B_SIGNED);
  wire [CW-1:0]   a_ext, b_ext;
  wire [CW:0]     lt;
  assign lt[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < CW; i = i + 1) begin : g_ext
      if (i < A_WIDTH) begin : g_ai
        assign a_ext[i] = A[i];
      end else begin : g_ae
        assign a_ext[i] = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_bi
        assign b_ext[i] = B[i];
      end else begin : g_be
        assign b_ext[i] = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
    end
    for (i = 0; i < CW; i = i + 1) begin : g_cmp
      wire ae, be, na, diff, lti, eqi, andi;
      if (SG && i == CW-1) begin : g_top
        assign ae = ~a_ext[i];
        assign be = ~b_ext[i];
      end else begin : g_norm
        assign ae = a_ext[i];
        assign be = b_ext[i];
      end
      sky130_fd_sc_hd__xor2_1 u_x  (.A(ae),  .B(be),  .X(diff));
      sky130_fd_sc_hd__inv_1  u_na (.A(ae),  .Y(na));
      sky130_fd_sc_hd__and2_1 u_lt (.A(na),  .B(be),  .X(lti));
      sky130_fd_sc_hd__inv_1  u_eq (.A(diff), .Y(eqi));
      sky130_fd_sc_hd__and2_1 u_an (.A(eqi), .B(lt[i]), .X(andi));
      sky130_fd_sc_hd__or2_1  u_or (.A(lti), .B(andi), .X(lt[i+1]));
    end
  endgenerate
  sky130_fd_sc_hd__inv_1 u_inv (.A(lt[CW]), .Y(Y));
endmodule

// A <= B  ==  ~(A > B)
module $le (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH  = 1;
  parameter B_WIDTH  = 1;
  parameter Y_WIDTH  = 1;
  input  [A_WIDTH-1:0] A;
  input  [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  localparam CW = (A_WIDTH > B_WIDTH) ? A_WIDTH : B_WIDTH;
  localparam SG = (A_SIGNED && B_SIGNED);
  wire [CW-1:0]   a_ext, b_ext;
  wire [CW:0]     lt;
  assign lt[0] = 1'b0;
  genvar i;
  generate
    for (i = 0; i < CW; i = i + 1) begin : g_ext
      if (i < A_WIDTH) begin : g_ai
        assign a_ext[i] = A[i];
      end else begin : g_ae
        assign a_ext[i] = A_SIGNED ? A[A_WIDTH-1] : 1'b0;
      end
      if (i < B_WIDTH) begin : g_bi
        assign b_ext[i] = B[i];
      end else begin : g_be
        assign b_ext[i] = B_SIGNED ? B[B_WIDTH-1] : 1'b0;
      end
    end
    for (i = 0; i < CW; i = i + 1) begin : g_cmp
      wire ae, be, na, diff, lti, eqi, andi;
      if (SG && i == CW-1) begin : g_top
        assign ae = ~b_ext[i];      // swapped: compute B < A
        assign be = ~a_ext[i];
      end else begin : g_norm
        assign ae = b_ext[i];
        assign be = a_ext[i];
      end
      sky130_fd_sc_hd__xor2_1 u_x  (.A(ae),  .B(be),  .X(diff));
      sky130_fd_sc_hd__inv_1  u_na (.A(ae),  .Y(na));
      sky130_fd_sc_hd__and2_1 u_lt (.A(na),  .B(be),  .X(lti));
      sky130_fd_sc_hd__inv_1  u_eq (.A(diff), .Y(eqi));
      sky130_fd_sc_hd__and2_1 u_an (.A(eqi), .B(lt[i]), .X(andi));
      sky130_fd_sc_hd__or2_1  u_or (.A(lti), .B(andi), .X(lt[i+1]));
    end
  endgenerate
  sky130_fd_sc_hd__inv_1 u_inv (.A(lt[CW]), .Y(Y));
endmodule

// ================= Yosys gate primitives (from +/techmap.v) =================
// After the standard `techmap -map +/techmap.v` expansion, the design can
// contain internal gate primitives rather than word-level cells.  These map
// one-to-one onto sky130 cells.

module $_NOT_ (A, Y);
  input A; output Y;
  sky130_fd_sc_hd__inv_1 u (.A(A), .Y(Y));
endmodule

module $_AND_ (A, B, Y);
  input A, B; output Y;
  sky130_fd_sc_hd__and2_1 u (.A(A), .B(B), .X(Y));
endmodule

module $_NAND_ (A, B, Y);
  input A, B; output Y;
  sky130_fd_sc_hd__nand2_1 u (.A(A), .B(B), .Y(Y));
endmodule

module $_OR_ (A, B, Y);
  input A, B; output Y;
  sky130_fd_sc_hd__or2_1 u (.A(A), .B(B), .X(Y));
endmodule

module $_NOR_ (A, B, Y);
  input A, B; output Y;
  sky130_fd_sc_hd__nor2_1 u (.A(A), .B(B), .Y(Y));
endmodule

module $_XOR_ (A, B, Y);
  input A, B; output Y;
  sky130_fd_sc_hd__xor2_1 u (.A(A), .B(B), .X(Y));
endmodule

// $_XNOR_ : Y = ~(A ^ B)
module $_XNOR_ (A, B, Y);
  input A, B; output Y;
  wire t;
  sky130_fd_sc_hd__xor2_1 u_x (.A(A), .B(B), .X(t));
  sky130_fd_sc_hd__inv_1  u_i (.A(t), .Y(Y));
endmodule

// $_ANDNOT_ : Y = A & ~B
module $_ANDNOT_ (A, B, Y);
  input A, B; output Y;
  wire nb;
  sky130_fd_sc_hd__inv_1  u_i (.A(B), .Y(nb));
  sky130_fd_sc_hd__and2_1 u_a (.A(A), .B(nb), .X(Y));
endmodule

// $_ORNOT_ : Y = A | ~B
module $_ORNOT_ (A, B, Y);
  input A, B; output Y;
  wire nb;
  sky130_fd_sc_hd__inv_1 u_i (.A(B), .Y(nb));
  sky130_fd_sc_hd__or2_1 u_o (.A(A), .B(nb), .X(Y));
endmodule

// $_MUX_ : Y = S ? B : A
module $_MUX_ (A, B, S, Y);
  input A, B, S; output Y;
  sky130_fd_sc_hd__mux2_1 u (.A0(A), .A1(B), .S(S), .X(Y));
endmodule

// ---------------------------- gate-level flops -----------------------------
// Port names: C (clock), R (reset), D, Q.  Name encodes clock edge, reset
// polarity and reset value:  $_DFF_<C><R><V>_  with C,R in {P,N}, V in {0,1}.

module $_DFF_P_ (C, D, Q);
  input C, D; output Q;
  sky130_fd_sc_hd__dfxtp_1 u (.CLK(C), .D(D), .Q(Q));
endmodule

module $_DFF_N_ (C, D, Q);
  input C, D; output Q;
  wire cn;
  sky130_fd_sc_hd__inv_1 u_i (.A(C), .Y(cn));
  sky130_fd_sc_hd__dfxtp_1 u (.CLK(cn), .D(D), .Q(Q));
endmodule

module $_DFF_PN0_ (C, R, D, Q);
  input C, R, D; output Q;
  sky130_fd_sc_hd__dfrtp_1 u (.CLK(C), .D(D), .Q(Q), .RESET_B(R));
endmodule

module $_DFF_PP0_ (C, R, D, Q);
  input C, R, D; output Q;
  wire rn;
  sky130_fd_sc_hd__inv_1  u_i (.A(R), .Y(rn));
  sky130_fd_sc_hd__dfrtp_1 u (.CLK(C), .D(D), .Q(Q), .RESET_B(rn));
endmodule

module $_DFF_PN1_ (C, R, D, Q);
  input C, R, D; output Q;
  sky130_fd_sc_hd__dfstp_1 u (.CLK(C), .D(D), .Q(Q), .SET_B(R));
endmodule

module $_DFF_PP1_ (C, R, D, Q);
  input C, R, D; output Q;
  wire rn;
  sky130_fd_sc_hd__inv_1  u_i (.A(R), .Y(rn));
  sky130_fd_sc_hd__dfstp_1 u (.CLK(C), .D(D), .Q(Q), .SET_B(rn));
endmodule

module $_DFF_NN0_ (C, R, D, Q);
  input C, R, D; output Q;
  wire cn;
  sky130_fd_sc_hd__inv_1  u_i (.A(C), .Y(cn));
  sky130_fd_sc_hd__dfrtp_1 u (.CLK(cn), .D(D), .Q(Q), .RESET_B(R));
endmodule

module $_DFF_NP0_ (C, R, D, Q);
  input C, R, D; output Q;
  wire cn, rn;
  sky130_fd_sc_hd__inv_1  u_i (.A(C), .Y(cn));
  sky130_fd_sc_hd__inv_1  u_r (.A(R), .Y(rn));
  sky130_fd_sc_hd__dfrtp_1 u (.CLK(cn), .D(D), .Q(Q), .RESET_B(rn));
endmodule

module $_DFF_NN1_ (C, R, D, Q);
  input C, R, D; output Q;
  wire cn;
  sky130_fd_sc_hd__inv_1  u_i (.A(C), .Y(cn));
  sky130_fd_sc_hd__dfstp_1 u (.CLK(cn), .D(D), .Q(Q), .SET_B(R));
endmodule

module $_DFF_NP1_ (C, R, D, Q);
  input C, R, D; output Q;
  wire cn, rn;
  sky130_fd_sc_hd__inv_1  u_i (.A(C), .Y(cn));
  sky130_fd_sc_hd__inv_1  u_r (.A(R), .Y(rn));
  sky130_fd_sc_hd__dfstp_1 u (.CLK(cn), .D(D), .Q(Q), .SET_B(rn));
endmodule
