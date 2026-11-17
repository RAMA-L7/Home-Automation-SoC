module ops_test (
  input  logic [7:0] a,
  input  logic [7:0] b,
  output logic [7:0] mul, dv, md, neg,
  output logic [7:0] shl, shr, sra
);
  assign mul = a * b;
  assign dv  = (b != 8'd0) ? (a / b) : 8'd0;
  assign md  = (b != 8'd0) ? (a % b) : 8'd0;
  assign neg = -a;
  assign shl = a << b[2:0];
  assign shr = a >> b[2:0];
  assign sra = $signed(a) >>> b[2:0];
endmodule
