`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// RTL <-> Sky130-mapped equivalence check for arith_test.
//
// Build requirements:
//   iverilog -g2012 -DUSE_MAPPED \
//            tb_equiv.v arith_test.v arith_test_mapped.v sky130_stub.v
//
// USE_MAPPED is mandatory.  Without it the testbench aborts with $fatal(1)
// instead of silently comparing the RTL against itself (the previous version
// fell back to a second RTL instance, which could never fail).
//
// Failure signalling: every mismatch calls $fatal(1, ...), so the simulator
// exits with a nonzero status.  A plain $finish would exit 0 and hide the
// failure from a Makefile or CI script.
//
// Negative control: build with -DCORRUPT_MAP to invert one mapped output bit.
// The run MUST fail; a passing run means the harness is not actually comparing
// anything.
// ---------------------------------------------------------------------------
module tb_equiv;
  logic        clk = 0, rst_n = 1, en = 0;
  logic [3:0]  a = 0, b = 0;
  logic [1:0]  op = 0;
  logic [3:0]  y_rtl, y_map;
  logic        zero_rtl, zero_map;
  integer      checks = 0;

  // ------------------------------ RTL ---------------------------------------
  arith_test rtl (
    .clk(clk), .rst_n(rst_n), .en(en), .a(a), .b(b), .op(op),
    .y(y_rtl), .y_eq_zero(zero_rtl)
  );

  // -------------------------- mapped netlist --------------------------------
`ifdef USE_MAPPED
  logic [3:0] y_raw;
  logic       zero_raw;
  arith_test_mapped map (
    .clk(clk), .rst_n(rst_n), .en(en), .a(a), .b(b), .op(op),
    .y(y_raw), .y_eq_zero(zero_raw)
  );
  `ifdef CORRUPT_MAP
    // Deliberately damaged netlist: invert the LSB of the result.
    assign y_map    = y_raw ^ 4'b0001;
    assign zero_map = zero_raw;
  `else
    assign y_map    = y_raw;
    assign zero_map = zero_raw;
  `endif
`else
  initial begin
    $display("FATAL: tb_equiv requires -DUSE_MAPPED (mapped netlist).");
    $display("       Refusing to compare the RTL against itself.");
    $fatal(1);
  end
  assign y_map    = 'x;
  assign zero_map = 'x;
`endif

  task automatic check(input [8*32-1:0] tag);
    checks = checks + 1;
    if (y_rtl !== y_map || zero_rtl !== zero_map) begin
      $display("MISMATCH [%0s] op=%b a=%0d b=%0d en=%b rst_n=%b",
               tag, op, a, b, en, rst_n);
      $display("  rtl: y=%b zero=%b", y_rtl, zero_rtl);
      $display("  map: y=%b zero=%b", y_map, zero_map);
      $fatal(1, "equivalence check failed");
    end
  endtask

  initial begin
    $display("=== RTL vs Sky130-mapped arith_test ===");
`ifdef CORRUPT_MAP
    $display("*** NEGATIVE CONTROL: mapped netlist is intentionally corrupted ***");
`endif

    rst_n = 0; en = 0; a = 0; b = 0; op = 0;
    #2 rst_n = 1;
    #2 check("reset");

    en = 1;
    for (int opv = 0; opv < 4; opv = opv + 1) begin
      op = opv[1:0];
      for (int av = 0; av < 16; av = av + 1) begin
        for (int bv = 0; bv < 16; bv = bv + 1) begin
          a = av[3:0];
          b = bv[3:0];
          #2 check("sweep");
        end
      end
    end

    // hold state (en low)
    en = 0; a = 4'hF; b = 4'hF; op = 2'b11;
    #2 check("hold");

    // asynchronous reset
    en = 1; a = 4'hF; b = 4'hF; op = 2'b11;
    #2 rst_n = 0;
    #2 check("async_reset");
    rst_n = 1; #2 check("post_reset");

    $display("PASS: %0d checks, RTL and mapped netlist agree", checks);
    $finish;
  end

  always #1 clk = ~clk;
endmodule
