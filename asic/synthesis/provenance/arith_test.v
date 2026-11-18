module arith_test(input logic clk, rst_n, en, input logic [3:0] a, b, input logic [1:0] op, output logic [3:0] y, output logic y_eq_zero);
  logic [3:0] sum, diff, alu;
  assign sum = a + b;
  assign diff = a - b;
  always_comb begin
    case (op)
      2'b00: alu = sum;
      2'b01: alu = diff;
      2'b10: alu = a & b;
      2'b11: alu = a | b;
      default: alu = 4'b0;
    endcase
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) y <= 4'b0;
    else if (en) y <= alu;
  end
  assign y_eq_zero = (y == 4'b0);
endmodule
