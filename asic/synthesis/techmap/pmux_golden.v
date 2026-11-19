// Golden reference models for the $pmux probes (asic/synthesis/techmap/pmux_probe.il).
//
// Module names are distinct from the mapped netlist names so that a mapped
// netlist and its reference can be linked into one simulation.
//
// The $pmux contract is "S is one-hot". For overlapping selects the chain the
// mapper builds (and these models) implement "highest set index wins"; the
// multi-bit-set cases below check that deterministic choice, not a standard.

// S_WIDTH = 1 : Y = S ? B : A  (the default case is S = 0 -> A).
module gold_s1_w8 (input [7:0] a, input [7:0] b, input s, output [7:0] y);
  assign y = s ? b : a;
endmodule

// S_WIDTH = 3 : Y = A, then each set select bit replaces the slice.
module gold_s3_w8 (input [7:0] a, input [23:0] b, input [2:0] s, output [7:0] y);
  reg [7:0] t;
  always @* begin
    t = a;
    if (s[0]) t = b[7:0];
    if (s[1]) t = b[15:8];
    if (s[2]) t = b[23:16];
  end
  assign y = t;
endmodule

// S_WIDTH = 1, WIDTH = 1 : scalar payload.
module gold_s1_w1 (input a, input b, input s, output y);
  assign y = s ? b : a;
endmodule
