// Policy test double, NOT the real SoC: it uses the top name `has_soc` but has
// two memories, while the policy declares four. The checker must reject the
// stale inventory instead of accepting "some memories are declared".
module has_soc (
  input        clk,
  input  [3:0] a0,
  input  [7:0] d0,
  input        we0,
  input  [3:0] a1,
  input  [7:0] d1,
  input        we1,
  output [7:0] q0,
  output [7:0] q1
);
  reg [7:0] m0 [0:15];
  reg [7:0] m1 [0:15];
  always @(posedge clk) if (we0) m0[a0] <= d0;
  always @(posedge clk) if (we1) m1[a1] <= d1;
  assign q0 = m0[a0];
  assign q1 = m1[a1];
endmodule
