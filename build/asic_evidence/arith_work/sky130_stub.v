// ---------------------------------------------------------------------------
// Behavioural models of the Sky130 HD cells in sky130_full_subset.lib.
//
// These are FUNCTIONAL models only (no timing).  They exist so the mapped
// netlist can be simulated with Icarus Verilog for equivalence checking.
//
// Every pin name, pin direction and pin WIDTH below matches the library:
//   * The _1/_2/_4 suffix on sequential cells is DRIVE STRENGTH.  All sky130 HD
//     flip-flops have scalar D and Q.  The previous version of this file
//     declared 2-bit/4-bit D/Q for dfrtp_2/dfrtp_4, which hid a real mapping
//     bug (a 4-bit register was being mapped onto one scalar cell).
//   * Combinational outputs are named X for and/or/xor/mux/buf, and Y for
//     nand/nor/inv.  The previous version gave and2_1 a Y output, so the mapper
//     connected a non-existent pin and left the AND result undriven.
// ---------------------------------------------------------------------------

// ---------------------------- combinational --------------------------------
module sky130_fd_sc_hd__inv_1 (input A, output Y);
  assign Y = ~A;
endmodule

module sky130_fd_sc_hd__buf_1 (input A, output X);
  assign X = A;
endmodule

module sky130_fd_sc_hd__clkbuf_1 (input A, output X);
  assign X = A;
endmodule

module sky130_fd_sc_hd__clkbuf_2 (input A, output X);
  assign X = A;
endmodule

module sky130_fd_sc_hd__clkbuf_4 (input A, output X);
  assign X = A;
endmodule

module sky130_fd_sc_hd__and2_1 (input A, input B, output X);
  assign X = A & B;
endmodule

module sky130_fd_sc_hd__and3_1 (input A, input B, input C, output X);
  assign X = A & B & C;
endmodule

module sky130_fd_sc_hd__and4_1 (input A, input B, input C, input D, output X);
  assign X = A & B & C & D;
endmodule

module sky130_fd_sc_hd__or2_1 (input A, input B, output X);
  assign X = A | B;
endmodule

module sky130_fd_sc_hd__or3_1 (input A, input B, input C, output X);
  assign X = A | B | C;
endmodule

module sky130_fd_sc_hd__or4_1 (input A, input B, input C, input D, output X);
  assign X = A | B | C | D;
endmodule

module sky130_fd_sc_hd__xor2_1 (input A, input B, output X);
  assign X = A ^ B;
endmodule

module sky130_fd_sc_hd__xor3_1 (input A, input B, input C, output X);
  assign X = A ^ B ^ C;
endmodule

module sky130_fd_sc_hd__nand2_1 (input A, input B, output Y);
  assign Y = ~(A & B);
endmodule

module sky130_fd_sc_hd__nand3_1 (input A, input B, input C, output Y);
  assign Y = ~(A & B & C);
endmodule

module sky130_fd_sc_hd__nand4_1 (input A, input B, input C, input D, output Y);
  assign Y = ~(A & B & C & D);
endmodule

module sky130_fd_sc_hd__nor2_1 (input A, input B, output Y);
  assign Y = ~(A | B);
endmodule

module sky130_fd_sc_hd__nor3_1 (input A, input B, input C, output Y);
  assign Y = ~(A | B | C);
endmodule

module sky130_fd_sc_hd__nor4_1 (input A, input B, input C, input D, output Y);
  assign Y = ~(A | B | C | D);
endmodule

// mux2_1: X = (A0 & !S) | (A1 & S)
module sky130_fd_sc_hd__mux2_1 (input A0, input A1, input S, output X);
  assign X = (A0 & ~S) | (A1 & S);
endmodule

// mux4_1: X = A0 when S1S0 == 00, A1 for 01, A2 for 10, A3 for 11
module sky130_fd_sc_hd__mux4_1 (input A0, input A1, input A2, input A3,
                               input S0, input S1, output X);
  assign X = (~S1 & ~S0 & A0) | (~S1 & S0 & A1) | (S1 & ~S0 & A2) | (S1 & S0 & A3);
endmodule

// ------------------------- sequential (scalar) -----------------------------
// dfrtp_*: posedge CLK, asynchronous active-low reset (RESET_B). Scalar pins.
module sky130_fd_sc_hd__dfrtp_1 (input CLK, input D, output reg Q, input RESET_B);
  always @(posedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 1'b0; else Q <= D;
endmodule

module sky130_fd_sc_hd__dfrtp_2 (input CLK, input D, output reg Q, input RESET_B);
  always @(posedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 1'b0; else Q <= D;
endmodule

module sky130_fd_sc_hd__dfrtp_4 (input CLK, input D, output reg Q, input RESET_B);
  always @(posedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 1'b0; else Q <= D;
endmodule

// dfstp_*: posedge CLK, asynchronous active-low set (SET_B). Scalar pins.
module sky130_fd_sc_hd__dfstp_1 (input CLK, input D, output reg Q, input SET_B);
  always @(posedge CLK or negedge SET_B)
    if (!SET_B) Q <= 1'b1; else Q <= D;
endmodule

module sky130_fd_sc_hd__dfstp_2 (input CLK, input D, output reg Q, input SET_B);
  always @(posedge CLK or negedge SET_B)
    if (!SET_B) Q <= 1'b1; else Q <= D;
endmodule

module sky130_fd_sc_hd__dfstp_4 (input CLK, input D, output reg Q, input SET_B);
  always @(posedge CLK or negedge SET_B)
    if (!SET_B) Q <= 1'b1; else Q <= D;
endmodule

// dfxtp_*: posedge CLK, no reset. Scalar pins.
module sky130_fd_sc_hd__dfxtp_1 (input CLK, input D, output reg Q);
  always @(posedge CLK) Q <= D;
endmodule

module sky130_fd_sc_hd__dfxtp_2 (input CLK, input D, output reg Q);
  always @(posedge CLK) Q <= D;
endmodule

module sky130_fd_sc_hd__dfxtp_4 (input CLK, input D, output reg Q);
  always @(posedge CLK) Q <= D;
endmodule

// dfrbp_*: posedge CLK, asynchronous active-low reset, complementary output.
// Liberty (sky130_tt.lib): ff ("IQ","IQ_N") { clear : "!RESET_B";
//   clocked_on : "CLK"; next_state : "D"; }, CLK->Q timing_type rising_edge.
// F3: this model previously used negedge CLK; see research/runs/RUN-0008.
module sky130_fd_sc_hd__dfrbp_1 (input CLK, input D, output reg Q, output Q_N, input RESET_B);
  always @(posedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 1'b0; else Q <= D;
  assign Q_N = ~Q;
endmodule

module sky130_fd_sc_hd__dfrbp_2 (input CLK, input D, output reg Q, output Q_N, input RESET_B);
  always @(posedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 1'b0; else Q <= D;
  assign Q_N = ~Q;
endmodule
