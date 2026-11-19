// Injected defect: two process drivers on the same bit.
module multidriver_top (
  input  a,
  input  b,
  output y
);
  reg y_r;
  always @* if (a) y_r = 1'b1;
  always @* if (b) y_r = 1'b0;
  assign y = y_r;
endmodule
