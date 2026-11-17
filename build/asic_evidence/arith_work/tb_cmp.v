`timescale 1ns/1ps
module tb_cmp;
  logic [3:0] a, b;
  wire lt, gt, le, ge, slt, sgt, sle, sge;
  integer errors = 0, checks = 0;
  wire signed [3:0] sa = a, sb = b;

  cmp_test_mapped dut(.a(a), .b(b), .lt(lt), .gt(gt), .le(le), .ge(ge),
                      .slt(slt), .sgt(sgt), .sle(sle), .sge(sge));

  initial begin
    for (int i = 0; i < 16; i = i + 1) begin
      for (int j = 0; j < 16; j = j + 1) begin
        a = i[3:0]; b = j[3:0]; #1;
        checks = checks + 1;
        if (lt !== (a < b) || gt !== (a > b) || le !== (a <= b) || ge !== (a >= b)) begin
          $display("UNSIGNED MISMATCH a=%0d b=%0d got lt/gt/le/ge=%b%b%b%b", a, b, lt, gt, le, ge);
          errors = errors + 1;
        end
        if (slt !== (sa < sb) || sgt !== (sa > sb) || sle !== (sa <= sb) || sge !== (sa >= sb)) begin
          $display("SIGNED MISMATCH a=%0d b=%0d got=%b%b%b%b", $signed(a), $signed(b), slt, sgt, sle, sge);
          errors = errors + 1;
        end
      end
    end
    if (errors == 0) begin
      $display("PASS: %0d comparator checks (signed+unsigned)", checks);
      $finish;
    end else begin
      $fatal(1, "comparator failures: %0d", errors);
    end
  end
endmodule
