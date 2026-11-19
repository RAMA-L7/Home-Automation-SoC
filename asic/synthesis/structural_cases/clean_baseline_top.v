// Structural baseline: every construct here is covered by sky130_map.v, so a
// correct flow maps it to library cells only and the checker must PASS it.
module clean_baseline_top (
  input  [7:0] a,
  input  [7:0] b,
  input       s,
  output [7:0] y
);
  assign y = s ? (a + b) : (a & b);
endmodule
