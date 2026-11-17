module cmp_test (
  input  logic [3:0] a,
  input  logic [3:0] b,
  output logic       lt, gt, le, ge,
  output logic       slt, sgt, sle, sge
);
  wire signed [3:0] sa = a;
  wire signed [3:0] sb = b;
  assign lt  = a <  b;
  assign gt  = a >  b;
  assign le  = a <= b;
  assign ge  = a >= b;
  assign slt = sa <  sb;
  assign sgt = sa >  sb;
  assign sle = sa <= sb;
  assign sge = sa >= sb;
endmodule
