`timescale 1ns/1ps
// Self-checking test for the Sky130 `$pmux` techmap rule.
//
// Inputs: the techmapped netlist (build/asic_evidence/pmux_map_test/pmux_mapped.v)
// linked against the behavioural Sky130 cell models, plus the golden models in
// pmux_golden.v. It never instantiates the original $pmux cells, so it measures
// the mapped hardware, not the RTL.
//
// Coverage:
//   * WIDTH = 8, S_WIDTH = 1, exhaustive over every A, B and S value (131072
//     vectors). This is the case the single-select branch got wrong.
//   * WIDTH = 1, S_WIDTH = 1, exhaustive (8 vectors).
//   * WIDTH = 8, S_WIDTH = 3, every one-hot select with all 256 values of A and
//     B (262144 vectors), which checks per-bit slicing across all three banks.
//   * Multi-bit selects (011, 101, 110, 111), which check the deterministic
//     "highest set index wins" behaviour of the mapper chain; the $pmux
//     contract only requires one-hot, so this is a documented choice, not a
//     standard.
//   * S = 0 in every case is the default selection (Y = A).
//
// PASS/FAIL: prints "PMUX_MAP_TEST: PASS" and exits 0 only when every vector
// matched. Any mismatch prints the failing vector and exits nonzero via $fatal.

module tb_pmux_map;
  integer checks = 0;
  integer errors = 0;
  integer shown  = 0;
  integer ai, bi, si, k;

  reg  [7:0]  a8, b8;
  reg         s1;
  wire [7:0]  m1, g1;

  reg  [23:0] b24;
  reg  [2:0]  s3;
  wire [7:0]  m3, g3;

  reg         aw, bw, sw;
  wire        mw, gw;

  pmux_s1_w8 dut_s1_w8 (.a(a8), .b(b8), .s(s1), .y(m1));
  gold_s1_w8 ref_s1_w8 (.a(a8), .b(b8), .s(s1), .y(g1));

  pmux_s3_w8 dut_s3_w8 (.a(a8), .b(b24), .s(s3), .y(m3));
  gold_s3_w8 ref_s3_w8 (.a(a8), .b(b24), .s(s3), .y(g3));

  pmux_s1_w1 dut_s1_w1 (.a(aw), .b(bw), .s(sw), .y(mw));
  gold_s1_w1 ref_s1_w1 (.a(aw), .b(bw), .s(sw), .y(gw));

  task chk_s1_w8;
    begin
      checks = checks + 1;
      if (m1 !== g1) begin
        errors = errors + 1;
        if (shown < 10) begin
          shown = shown + 1;
          $display("FAIL s1_w8: a=%02h b=%02h s=%0b mapped=%02h golden=%02h",
                   a8, b8, s1, m1, g1);
        end
      end
    end
  endtask

  task chk_s3_w8;
    begin
      checks = checks + 1;
      if (m3 !== g3) begin
        errors = errors + 1;
        if (shown < 10) begin
          shown = shown + 1;
          $display("FAIL s3_w8: a=%02h b=%06h s=%03b mapped=%02h golden=%02h",
                   a8, b24, s3, m3, g3);
        end
      end
    end
  endtask

  task chk_s1_w1;
    begin
      checks = checks + 1;
      if (mw !== gw) begin
        errors = errors + 1;
        if (shown < 10) begin
          shown = shown + 1;
          $display("FAIL s1_w1: a=%0b b=%0b s=%0b mapped=%0b golden=%0b",
                   aw, bw, sw, mw, gw);
        end
      end
    end
  endtask

  initial begin
    // ---- WIDTH 1, S_WIDTH 1: exhaustive ----------------------------------
    for (k = 0; k < 8; k = k + 1) begin
      aw = k[0];
      bw = k[1];
      sw = k[2];
      #1;
      chk_s1_w1;
    end

    // ---- WIDTH 8, S_WIDTH 1: exhaustive ----------------------------------
    for (ai = 0; ai < 256; ai = ai + 1) begin
      for (bi = 0; bi < 256; bi = bi + 1) begin
        a8 = ai[7:0];
        b8 = bi[7:0];
        s1 = 1'b0;
        #1;
        chk_s1_w8;
        s1 = 1'b1;
        #1;
        chk_s1_w8;
      end
    end

    // ---- WIDTH 8, S_WIDTH 3: every one-hot select ------------------------
    for (si = 0; si < 4; si = si + 1) begin
      case (si)
        0: s3 = 3'b000;
        1: s3 = 3'b001;
        2: s3 = 3'b010;
        default: s3 = 3'b100;
      endcase
      for (ai = 0; ai < 256; ai = ai + 1) begin
        for (bi = 0; bi < 256; bi = bi + 1) begin
          a8  = ai[7:0];
          // Distinct slices so a bank swap cannot hide in equal data.
          b24 = { bi[7:0] ^ 8'hA5, ai[7:0] ^ 8'h5A, bi[7:0] };
          #1;
          chk_s3_w8;
        end
      end
    end

    // ---- Multi-bit selects: documented priority, highest set bit wins ----
    for (si = 0; si < 6; si = si + 1) begin
      case (si)
        0: s3 = 3'b011;
        1: s3 = 3'b101;
        2: s3 = 3'b110;
        3: s3 = 3'b111;
        4: s3 = 3'b110;
        default: s3 = 3'b011;
      endcase
      for (ai = 0; ai < 8; ai = ai + 1) begin
        for (bi = 0; bi < 8; bi = bi + 1) begin
          a8  = ai * 8'h21;
          b24 = { bi[7:0] * 8'h11, ai[7:0] + 8'h33, bi[7:0] ^ 8'h0F };
          #1;
          chk_s3_w8;
        end
      end
    end

    $display("PMUX_MAP_TEST: %0d vectors checked, %0d mismatches", checks, errors);
    if (errors != 0) begin
      $display("PMUX_MAP_TEST: FAIL");
      $fatal(1, "mapped $pmux does not match the reference");
    end
    $display("PMUX_MAP_TEST: PASS");
    $finish;
  end
endmodule
