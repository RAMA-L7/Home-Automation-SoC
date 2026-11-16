// Sky130 HD cell behavioral stubs for Icarus Verilog equivalence testing.
// Port names and functions match the verified Liberty data in
// sky130_full_subset.lib EXACTLY.  Functional only — no timing.

module sky130_fd_sc_hd__inv_1(input A, output Y);
  assign Y = ~A;
endmodule

module sky130_fd_sc_hd__and2_1(input A, input B, output Y);
  assign Y = A & B;
endmodule

module sky130_fd_sc_hd__or2_1(input A, input B, output X);
  assign X = A | B;
endmodule

module sky130_fd_sc_hd__xor2_1(input A, input B, output X);
  assign X = A ^ B;
endmodule

module sky130_fd_sc_hd__nor2_1(input A, input B, output Y);
  assign Y = ~(A | B);
endmodule

module sky130_fd_sc_hd__nor3_1(input A, input B, input C, output Y);
  assign Y = ~(A | B | C);
endmodule

module sky130_fd_sc_hd__nor4_1(input A, input B, input C, input D, output Y);
  assign Y = ~(A | B | C | D);
endmodule

// mux2_1: Liberty pins A0, A1, S, X.  Function: X = (A0 & !S) | (A1 & S)
module sky130_fd_sc_hd__mux2_1(input A0, input A1, input S, output X);
  assign X = (A0 & ~S) | (A1 & S);
endmodule

// dfrtp_1: posedge CLK, async reset active-low (RESET_B)
module sky130_fd_sc_hd__dfrtp_1(input CLK, input D, output reg Q, input RESET_B);
  always @(posedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 1'b0; else Q <= D;
endmodule

// dfrtp_2: 2-bit, posedge CLK, async reset active-low
module sky130_fd_sc_hd__dfrtp_2(input CLK, input [1:0] D, output reg [1:0] Q, input RESET_B);
  always @(posedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 2'b00; else Q <= D;
endmodule

// dfrtp_4: 4-bit, posedge CLK, async reset active-low
module sky130_fd_sc_hd__dfrtp_4(input CLK, input [3:0] D, output reg [3:0] Q, input RESET_B);
  always @(posedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 4'b0000; else Q <= D;
endmodule

// dfxtp_1: posedge CLK, NO async reset (Liberty: CLK, D, Q only)
module sky130_fd_sc_hd__dfxtp_1(input CLK, input D, output reg Q);
  always @(posedge CLK) Q <= D;
endmodule

// dfxtp_2: 2-bit, no reset
module sky130_fd_sc_hd__dfxtp_2(input CLK, input [1:0] D, output reg [1:0] Q);
  always @(posedge CLK) Q <= D;
endmodule

// dfxtp_4: 4-bit, no reset
module sky130_fd_sc_hd__dfxtp_4(input CLK, input [3:0] D, output reg [3:0] Q);
  always @(posedge CLK) Q <= D;
endmodule

// dfrbp_1: negedge CLK, async reset active-low (RESET_B), also has Q_N
module sky130_fd_sc_hd__dfrbp_1(input CLK, input D, output reg Q, output Q_N, input RESET_B);
  always @(negedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 1'b0; else Q <= D;
  assign Q_N = ~Q;
endmodule

// dfrbp_2: 2-bit, negedge, async reset active-low
module sky130_fd_sc_hd__dfrbp_2(input CLK, input [1:0] D, output reg [1:0] Q, output Q_N, input RESET_B);
  always @(negedge CLK or negedge RESET_B)
    if (!RESET_B) Q <= 2'b00; else Q <= D;
  assign Q_N = ~Q;
endmodule
