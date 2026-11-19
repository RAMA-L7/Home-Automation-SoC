// Injected defect: incomplete technology mapping. `$div` is not in sky130_map.v
// and the control run disables the generic expansion, so it must survive and be
// reported rather than silently shipped as an internal cell.
module unmapped_div_top (
  input  [7:0] a,
  input  [7:0] b,
  output [7:0] y
);
  assign y = a / b;
endmodule
