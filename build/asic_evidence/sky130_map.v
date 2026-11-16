// Technology mapping: Yosys internal cells -> Sky130 HD cells
// Loaded by techmap to replace internal cells with Sky130 target cells
//
// Cells available in the verified Sky130 HD subset (sky130_full_subset.lib):
//   comb: inv_1, buf_1, and2_1/3/4, nand2_1/3_1/4_1, or2_1/3_1/4_1,
//          nor2_1/3_1/4_1, xor2_1/xor3_1, mux2_1, mux4_1
//   seq:  dfrtp_1/2/4, dfxtp_1/2/4, dfrbp_1/2, dfstp_1/2/4
//   No adder cells, no SR-latch cells in the verified subset.
//
// PORT NAMES are taken from the Liberty data (RTLIL cell declarations in
// arith_test.rtlil / sky130_full_subset.lib) and MUST match exactly:
//   inv_1:  A, Y
//   and2_1: A, B, Y       or3_1: A, B, C, X   or4_1: A, B, C, D, X
//   or2_1:  A, B, X       nor2_1: A, B, Y      nor4_1: A, B, C, D, Y
//   xor2_1: A, B, X       nand2_1: A, B, Y
//   mux2_1: A0, A1, S, X
//   dfrtp_1/2/4: CLK, D, Q, RESET_B   (posedge clk, async reset active-low)
//   dfxtp_1/2/4: CLK, D, Q            (posedge clk, NO async reset)
//   dfrbp_1/2:   CLK, D, Q, Q_N, RESET_B  (negedge clk, async reset active-low)
//
// Strategy for multi-bit Yosys cells: decompose to WIDTH identical single-bit
// target cells.  This preserves bitwise behaviour exactly and uses only cells
// that already exist in the verified liberty subset.

// $not -> inv_1  (1-bit and multi-bit)
module $not (A, Y);
  parameter A_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  output [Y_WIDTH-1:0] Y;
  generate
    if (A_WIDTH == 1 && Y_WIDTH == 1) begin
      sky130_fd_sc_hd__inv_1 u_inv (.A(A), .Y(Y));
    end else if (A_WIDTH == Y_WIDTH) begin
      genvar i;
      for (i = 0; i < A_WIDTH; i = i + 1) begin : g_inv
        sky130_fd_sc_hd__inv_1 u_inv_bit (.A(A[i]), .Y(Y[i]));
      end
    end
  endgenerate
endmodule

// $logic_and -> and2_1  (1-bit AND reduction, 2 single-bit inputs)
// Yosys $logic_and: Y = & (A & B) for 1-bit inputs — equivalent to 2-input AND.
// Parameters: A_WIDTH=1, B_WIDTH=1, Y_WIDTH=1 always.
module $logic_and (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter B_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  input [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  sky130_fd_sc_hd__and2_1 u_and (.A(A), .B(B), .Y(Y));
endmodule

// $logic_or -> or2_1  (1-bit OR reduction, 2 single-bit inputs)
// Yosys $logic_or: Y = | (A | B) for 1-bit inputs — equivalent to 2-input OR.
module $logic_or (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter B_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  input [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  sky130_fd_sc_hd__or2_1 u_or (.A(A), .B(B), .X(Y));
endmodule

// $and (2-input) -> and2_1  (1-bit and multi-bit)
module $and (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter B_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  input [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  generate
    if (A_WIDTH == 1 && B_WIDTH == 1 && Y_WIDTH == 1) begin
      sky130_fd_sc_hd__and2_1 u_and (.A(A), .B(B), .Y(Y));
    end else if (A_WIDTH == B_WIDTH && B_WIDTH == Y_WIDTH) begin
      genvar i;
      for (i = 0; i < A_WIDTH; i = i + 1) begin : g_and
        sky130_fd_sc_hd__and2_1 u_and_bit (.A(A[i]), .B(B[i]), .Y(Y[i]));
      end
    end
  endgenerate
endmodule

// $or (2-input) -> or2_1  (1-bit and multi-bit)
// Liberty or2_1 pins: A, B, X  (output is named X, NOT Y)
module $or (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter B_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  input [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  generate
    if (A_WIDTH == 1 && B_WIDTH == 1 && Y_WIDTH == 1) begin
      sky130_fd_sc_hd__or2_1 u_or (.A(A), .B(B), .X(Y));
    end else if (A_WIDTH == B_WIDTH && B_WIDTH == Y_WIDTH) begin
      genvar i;
      for (i = 0; i < A_WIDTH; i = i + 1) begin : g_or
        sky130_fd_sc_hd__or2_1 u_or_bit (.A(A[i]), .B(B[i]), .X(Y[i]));
      end
    end
  endgenerate
endmodule

// $xor (2-input) -> xor2_1  (1-bit and multi-bit)
// Liberty xor2_1 pins: A, B, X
module $xor (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter B_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  input [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  generate
    if (A_WIDTH == 1 && B_WIDTH == 1 && Y_WIDTH == 1) begin
      sky130_fd_sc_hd__xor2_1 u_xor (.A(A), .B(B), .X(Y));
    end else if (A_WIDTH == B_WIDTH && B_WIDTH == Y_WIDTH) begin
      genvar i;
      for (i = 0; i < A_WIDTH; i = i + 1) begin : g_xor
        sky130_fd_sc_hd__xor2_1 u_xor_bit (.A(A[i]), .B(B[i]), .X(Y[i]));
      end
    end
  endgenerate
endmodule

// $mux -> mux2_1  (1-bit and multi-bit)
// Yosys $mux: Y = S ? B : A   (S active-high selects B)
// Sky130 mux2_1 Liberty pins: A0, A1, S, X
//   Function: X = (A0 & !S) | (A1 & S)
//   Map: A0=A (in0), A1=B (in1), S=S, X=Y  -> Y = (A & !S) | (B & S) = S ? B : A
module $mux (S, B, A, Y);
  parameter WIDTH = 1;
  input S;
  input [WIDTH-1:0] B;
  input [WIDTH-1:0] A;
  output [WIDTH-1:0] Y;
  generate
    if (WIDTH == 1) begin
      sky130_fd_sc_hd__mux2_1 u_mux (.A0(A), .A1(B), .S(S), .X(Y));
    end else begin
      genvar i;
      for (i = 0; i < WIDTH; i = i + 1) begin : g_mux
        sky130_fd_sc_hd__mux2_1 u_mux_bit (.A0(A[i]), .A1(B[i]), .S(S), .X(Y[i]));
      end
    end
  endgenerate
endmodule

// $sff -> dfrtp_1/dfxtp_1/dfrbp_1  (1-bit and multi-bit)
// Yosys $dff: q <= d on clock edge; R is async reset.
// RESET_POLARITY==0: active-low reset (R=1 means reset)
//   -> dfrtp (posedge) .CLK(CLK) .D(D) .Q(Q) .RESET_B(R)
//   -> dfrbp (negedge) .CLK(CLK) .D(D) .Q(Q) .RESET_B(R)
// RESET_POLARITY==1: active-high reset
//   -> dfxtp (posedge, no reset pin!) — CANNOT implement active-high async reset
//      with dfxtp (no reset pin).  For active-high async reset we must use
//      dfrtp/dfrbp with inverted reset: .RESET_B(~R)
//      -> dfrtp: .RESET_B(~R)  (invert active-high R to active-low RESET_B)
//      -> dfrbp: .RESET_B(~R)
// Native multi-bit cells used where WIDTH matches.
module $dff (CLK, D, Q, R);
  parameter WIDTH = 1;
  parameter CLK_POLARITY = 1;
  parameter RESET_POLARITY = 0;
  input CLK;
  input [WIDTH-1:0] D;
  output [WIDTH-1:0] Q;
  input R;
  generate
    if (WIDTH == 1) begin
      if (CLK_POLARITY == 1) begin
        if (RESET_POLARITY == 0) begin
          sky130_fd_sc_hd__dfrtp_1 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(R));
        end else begin
          // active-high reset: invert to RESET_B for dfrtp
          sky130_fd_sc_hd__dfrtp_1 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~R));
        end
      end else begin
        if (RESET_POLARITY == 0) begin
          sky130_fd_sc_hd__dfrbp_1 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(R));
        end else begin
          sky130_fd_sc_hd__dfrbp_1 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~R));
        end
      end
    end else if (CLK_POLARITY == 1 && RESET_POLARITY == 0 && WIDTH == 4) begin
      sky130_fd_sc_hd__dfrtp_4 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(R));
    end else if (CLK_POLARITY == 1 && RESET_POLARITY == 1 && WIDTH == 4) begin
      sky130_fd_sc_hd__dfrtp_4 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~R));
    end else if (CLK_POLARITY == 1 && WIDTH == 2) begin
      if (RESET_POLARITY == 0) begin
        sky130_fd_sc_hd__dfrtp_2 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(R));
      end else begin
        sky130_fd_sc_hd__dfrtp_2 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~R));
      end
    end else if (CLK_POLARITY == 0 && WIDTH == 2) begin
      if (RESET_POLARITY == 0) begin
        sky130_fd_sc_hd__dfrbp_2 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(R));
      end else begin
        sky130_fd_sc_hd__dfrbp_2 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~R));
      end
    end else begin
      genvar i;
      for (i = 0; i < WIDTH; i = i + 1) begin : g_dff
        if (CLK_POLARITY == 1) begin
          if (RESET_POLARITY == 0) begin
            sky130_fd_sc_hd__dfrtp_1 u_dff_bit (.CLK(CLK), .D(D[i]), .Q(Q[i]), .RESET_B(R));
          end else begin
            sky130_fd_sc_hd__dfrtp_1 u_dff_bit (.CLK(CLK), .D(D[i]), .Q(Q[i]), .RESET_B(~R));
          end
        end else begin
          if (RESET_POLARITY == 0) begin
            sky130_fd_sc_hd__dfrbp_1 u_dff_bit (.CLK(CLK), .D(D[i]), .Q(Q[i]), .RESET_B(R));
          end else begin
            sky130_fd_sc_hd__dfrbp_1 u_dff_bit (.CLK(CLK), .D(D[i]), .Q(Q[i]), .RESET_B(~R));
          end
        end
      end
    end
  endgenerate
endmodule

// $adff -> dfrtp_1/dfxtp_1/dfrbp_1  (1-bit and multi-bit)
// Yosys $adff: async reset, q <= d on clock edge, q <= ARST_VALUE when ARST active.
// ARST_POLARITY==0: active-low  (ARST=0 means reset) -> dfrtp .RESET_B(ARST)
// ARST_POLARITY==1: active-high -> dfrtp .RESET_B(~ARST)
// ARST_VALUE honoured by Yosys before techmap (flop init state).
// dfxtp has NO reset pin — cannot implement async reset.  Use dfrtp/dfrbp with
// inverted reset for active-high case.
module $adff (CLK, ARST, D, Q);
  parameter WIDTH = 1;
  parameter CLK_POLARITY = 1;
  parameter ARST_POLARITY = 1;
  parameter ARST_VALUE = 0;
  input CLK;
  input ARST;
  input [WIDTH-1:0] D;
  output [WIDTH-1:0] Q;
  generate
    if (WIDTH == 1) begin
      if (CLK_POLARITY == 1) begin
        if (ARST_POLARITY == 1) begin
          sky130_fd_sc_hd__dfrtp_1 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~ARST));
        end else begin
          sky130_fd_sc_hd__dfrtp_1 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(ARST));
        end
      end else begin
        if (ARST_POLARITY == 1) begin
          sky130_fd_sc_hd__dfrbp_1 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~ARST));
        end else begin
          sky130_fd_sc_hd__dfrbp_1 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(ARST));
        end
      end
    end else if (CLK_POLARITY == 1 && ARST_POLARITY == 0 && WIDTH == 4) begin
      sky130_fd_sc_hd__dfrtp_4 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(ARST));
    end else if (CLK_POLARITY == 1 && ARST_POLARITY == 1 && WIDTH == 4) begin
      sky130_fd_sc_hd__dfrtp_4 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~ARST));
    end else if (CLK_POLARITY == 1 && ARST_POLARITY == 0 && WIDTH == 2) begin
      sky130_fd_sc_hd__dfrtp_2 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(ARST));
    end else if (CLK_POLARITY == 1 && ARST_POLARITY == 1 && WIDTH == 2) begin
      sky130_fd_sc_hd__dfrtp_2 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~ARST));
    end else if (CLK_POLARITY == 0 && WIDTH == 2) begin
      if (ARST_POLARITY == 0) begin
        sky130_fd_sc_hd__dfrbp_2 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(ARST));
      end else begin
        sky130_fd_sc_hd__dfrbp_2 u_dff (.CLK(CLK), .D(D), .Q(Q), .RESET_B(~ARST));
      end
    end else begin
      genvar i;
      for (i = 0; i < WIDTH; i = i + 1) begin : g_adff
        if (CLK_POLARITY == 1) begin
          if (ARST_POLARITY == 1) begin
            sky130_fd_sc_hd__dfrtp_1 u_dff_bit (.CLK(CLK), .D(D[i]), .Q(Q[i]), .RESET_B(~ARST));
          end else begin
            sky130_fd_sc_hd__dfrtp_1 u_dff_bit (.CLK(CLK), .D(D[i]), .Q(Q[i]), .RESET_B(ARST));
          end
        end else begin
          if (ARST_POLARITY == 1) begin
            sky130_fd_sc_hd__dfrbp_1 u_dff_bit (.CLK(CLK), .D(D[i]), .Q(Q[i]), .RESET_B(~ARST));
          end else begin
            sky130_fd_sc_hd__dfrbp_1 u_dff_bit (.CLK(CLK), .D(D[i]), .Q(Q[i]), .RESET_B(ARST));
          end
        end
      end
    end
  endgenerate
endmodule

// $eq -> xor2_1 + reduce-nor of xor bits (1-bit and multi-bit)
// Yosys $eq(A,B): Y = (A == B)  ->  1 if all bits equal, else 0.
// Implementation: Y = ~(| (A ^ B))  i.e. NOR of all bitwise-xor bits.
// Uses only xor2_1 (A,B,X) + nor2_1/nor3_1/nor4_1 (A,B[,C[,D]],Y).
module $eq (A, B, Y);
  parameter A_SIGNED = 0;
  parameter B_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter B_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  input [B_WIDTH-1:0] B;
  output [Y_WIDTH-1:0] Y;
  generate
    if (A_WIDTH == 1 && B_WIDTH == 1 && Y_WIDTH == 1) begin
      // 1-bit equality: Y = ~(A ^ B) -> xor2_1 (A,B,X) + inv_1 (A,Y)
      wire xor_bit;
      sky130_fd_sc_hd__xor2_1 u_xor (.A(A), .B(B), .X(xor_bit));
      sky130_fd_sc_hd__inv_1 u_inv (.A(xor_bit), .Y(Y));
    end else if (A_WIDTH == B_WIDTH && A_WIDTH == Y_WIDTH && Y_WIDTH > 1) begin
      genvar i;
      for (i = 0; i < A_WIDTH; i = i + 1) begin : g_eq
        wire xor_bit;
        sky130_fd_sc_hd__xor2_1 u_xor (.A(A[i]), .B(B[i]), .X(xor_bit));
        sky130_fd_sc_hd__inv_1 u_inv (.A(xor_bit), .Y(Y[i]));
      end
    end else if (A_WIDTH == B_WIDTH && Y_WIDTH == 1) begin
      genvar i;
      wire [A_WIDTH-1:0] xor_bits;
      for (i = 0; i < A_WIDTH; i = i + 1) begin : g_xor
        sky130_fd_sc_hd__xor2_1 u_xor (.A(A[i]), .B(B[i]), .X(xor_bits[i]));
      end
      if (A_WIDTH == 2) begin
        sky130_fd_sc_hd__nor2_1 u_nor (.A(xor_bits[0]), .B(xor_bits[1]), .Y(Y));
      end else if (A_WIDTH == 3) begin
        sky130_fd_sc_hd__nor3_1 u_nor (.A(xor_bits[0]), .B(xor_bits[1]), .C(xor_bits[2]), .Y(Y));
      end else if (A_WIDTH == 4) begin
        sky130_fd_sc_hd__nor4_1 u_nor (.A(xor_bits[0]), .B(xor_bits[1]), .C(xor_bits[2]), .D(xor_bits[3]), .Y(Y));
      end
    end
  endgenerate
endmodule

// $logic_not -> inv_1  (1-bit and multi-bit)
// Yosys $logic_not(A): Y = ~A (bitwise logical NOT).
module $logic_not (A, Y);
  parameter A_SIGNED = 0;
  parameter A_WIDTH = 1;
  parameter Y_WIDTH = 1;
  input [A_WIDTH-1:0] A;
  output [Y_WIDTH-1:0] Y;
  generate
    if (A_WIDTH == 1 && Y_WIDTH == 1) begin
      sky130_fd_sc_hd__inv_1 u_inv (.A(A), .Y(Y));
    end else if (A_WIDTH == Y_WIDTH && A_WIDTH > 1) begin
      genvar i;
      for (i = 0; i < A_WIDTH; i = i + 1) begin : g_not
        sky130_fd_sc_hd__inv_1 u_not_bit (.A(A[i]), .Y(Y[i]));
      end
    end else if (Y_WIDTH == 1 && A_WIDTH > 1) begin
      // Reduce: Y = ~(|A) = NOR of all bits
      genvar i;
      if (A_WIDTH == 2) begin
        sky130_fd_sc_hd__nor2_1 u_nor (.A(A[0]), .B(A[1]), .Y(Y));
      end else if (A_WIDTH == 3) begin
        sky130_fd_sc_hd__nor3_1 u_nor (.A(A[0]), .B(A[1]), .C(A[2]), .Y(Y));
      end else if (A_WIDTH == 4) begin
        sky130_fd_sc_hd__nor4_1 u_nor (.A(A[0]), .B(A[1]), .C(A[2]), .D(A[3]), .Y(Y));
      end
    end
  endgenerate
endmodule

// $pmux -> tree of mux2_1 (general N:1 multi-bit)
// Yosys $pmux: Y = S[0] ? B[0] : S[1] ? B[1] : ... : S[N-1] ? B[N-1] : A
// S one-hot.  WIDTH=data width, S_WIDTH=N.
// Yosys B is FLAT [WIDTH*S_WIDTH-1:0]: S_WIDTH sources concatenated, each WIDTH bits.
// mux2_1 Liberty pins: A0, A1, S, X.  Function: X = (A0 & !S) | (A1 & S).
module $pmux (A, B, S, Y);
  parameter WIDTH = 1;
  parameter S_WIDTH = 1;
  input [WIDTH-1:0] A;
  input [WIDTH*S_WIDTH-1:0] B;
  input [S_WIDTH-1:0] S;
  output [WIDTH-1:0] Y;
  generate
    if (S_WIDTH == 1) begin
      sky130_fd_sc_hd__mux2_1 u_mux (.A0(A), .A1(B), .S(S), .X(Y));
    end else begin
      genvar i, k;
      for (i = 0; i < WIDTH; i = i + 1) begin : g_pmux_bit
        wire [S_WIDTH-1:0] mux_chain;
        sky130_fd_sc_hd__mux2_1 u_ch0 (.A0(A[i]), .A1(B[0*WIDTH + i]), .S(S[0]), .X(mux_chain[0]));
        for (k = 1; k < S_WIDTH; k = k + 1) begin : g_ch
          sky130_fd_sc_hd__mux2_1 u_chk (.A0(mux_chain[k-1]), .A1(B[k*WIDTH + i]), .S(S[k]), .X(mux_chain[k]));
        end
        assign Y[i] = mux_chain[S_WIDTH-1];
      end
    end
  endgenerate
endmodule

// BLOCKERS (not mapped — documented, no invented cells):
//
// $add / $sub / $alu:
//   No Sky130 HD arithmetic/adder cells exist in the verified 32-cell subset
//   (sky130_full_subset.lib) and no Liberty timing is available for invented
//   adder cells.  $add/$sub remain as unmapped Yosys cells after techmap.
//   The $alu is already decomposed by Yosys proc into $pmux + $add/$sub/$and/$or
//   + $eq comparators; the $and/$or paths now map, the $add/$sub paths do not.
//
// $sr (set-reset latch):
//   No SR-latch cell exists in the verified subset.  The RISC-V CSR sticky bits
//   and interrupt-pending latches will produce $sr cells that remain unmapped.
