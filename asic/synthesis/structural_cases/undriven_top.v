// Injected defect: z[2:1] has no driver. Yosys `check` reports it, but a bare
// `check` still exits 0 (F8); `check -assert` must fail.
module undriven_top (
  input        a,
  output       y,
  output [2:0] z
);
  assign y = a;
  assign z[0] = a;
endmodule
