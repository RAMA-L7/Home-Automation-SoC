//------------------------------------------------------------------------------
// Home-Automation-SoC — C++ model build test
// Verifies that the newly installed g++/mingw32-make toolchain can build a
// generated C++ model. This was the long-standing blocker:
// "No g++/make | C++ simulation unavailable".
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_counter;
  reg       clk;
  reg       rst_n;
  reg       en;
  wire [7:0] count;

  counter dut (
    .clk   (clk),
    .rst_n (rst_n),
    .en    (en),
    .count (count)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  integer i;
  initial begin
    rst_n = 1'b0;
    en    = 1'b0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    en    = 1'b1;
    for (i = 0; i < 5; i = i + 1) @(posedge clk);
    $display("TB_COUNTER: count = %0d (expect 5)", count);
    if (count == 8'd5) $display("TB_COUNTER: PASS");
    else               $display("TB_COUNTER: FAIL");
    $finish;
  end
endmodule

//------------------------------------------------------------------------------
// Minimal DUT
//------------------------------------------------------------------------------
module counter (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       en,
  output reg  [7:0] count
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)      count <= 8'd0;
    else if (en)     count <= count + 8'd1;
  end
endmodule
