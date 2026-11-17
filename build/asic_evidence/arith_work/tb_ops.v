`timescale 1ns/1ps
module tb_ops;
  logic [7:0] a, b;
  wire  [7:0] mul, dv, md, neg, shl, shr, sra;
  integer errors = 0, checks = 0;

  ops_test_mapped dut(.a(a), .b(b), .mul(mul), .dv(dv), .md(md), .neg(neg),
                      .shl(shl), .shr(shr), .sra(sra));

  task automatic chk(input [7:0] ea, eb, emul, edv, emd, eneg, eshl, eshr, esra);
    checks = checks + 1;
    if (mul !== emul || dv !== edv || md !== emd || neg !== eneg ||
        shl !== eshl || shr !== eshr || sra !== esra) begin
      $display("MISMATCH a=%0d b=%0d", ea, eb);
      $display("  got mul=%0d dv=%0d md=%0d neg=%0d shl=%0d shr=%0d sra=%0d", mul, dv, md, neg, shl, shr, sra);
      $display("  exp mul=%0d dv=%0d md=%0d neg=%0d shl=%0d shr=%0d sra=%0d", emul, edv, emd, eneg, eshl, eshr, esra);
      errors = errors + 1;
    end
  endtask

  initial begin
    for (int i = 0; i < 256; i = i + 1) begin
      for (int j = 0; j < 256; j = j + 1) begin
        a = i[7:0]; b = j[7:0]; #1;
        chk(a, b,
            a * b,
            (b != 0) ? (a / b) : 8'd0,
            (b != 0) ? (a % b) : 8'd0,
            -a,
            a << b[2:0],
            a >> b[2:0],
            $signed(a) >>> b[2:0]);
      end
    end
    if (errors == 0) begin
      $display("PASS: %0d arithmetic-op checks", checks);
      $finish;
    end else begin
      $fatal(1, "arithmetic-op failures: %0d", errors);
    end
  end
endmodule
