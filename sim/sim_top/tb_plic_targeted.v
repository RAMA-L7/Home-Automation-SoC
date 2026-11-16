`timescale 1ns/1ps
module tb_plic_targeted;
  reg clk=0; reg reset_n;
  reg wr_en; reg [11:0] wr_addr; reg [31:0] wr_data; reg [11:0] rd_addr;
  wire [31:0] rd_data;
  reg [7:0] ext_irq; wire irq_out;
  always #5 clk=~clk;
  plic #(.NUM_SOURCES(8)) dut(.clk(clk),.reset_n(reset_n),.wr_en(wr_en),.wr_addr(wr_addr),.wr_data(wr_data),.rd_addr(rd_addr),.rd_data(rd_data),.ext_irq(ext_irq),.irq_out(irq_out));
  integer errors=0;
  task wr(input [11:0] a,input [31:0] d); begin @(posedge clk); wr_en<=1; wr_addr<=a; wr_data<=d; @(posedge clk); wr_en<=0; @(posedge clk); end endtask
  task rd(input [11:0] a); begin @(posedge clk); rd_addr<=a; @(posedge clk); end endtask
  task chk(input [255:0] name,input [31:0] got,input [31:0] exp); begin if(got!==exp) begin $display("[plic8] FAIL %s: got %0d exp %0d",name,got,exp); errors=errors+1; end else $display("[plic8] pass %s",name); end endtask
  integer s;
  initial begin
    reset_n=0; wr_en=0; wr_addr=0; wr_data=0; rd_addr=0; ext_irq=0;
    repeat(5) @(posedge clk); reset_n=1; repeat(2) @(posedge clk);
    for(s=1;s<=8;s=s+1) begin
      // priority write/read at 0x004+4*(s-1)
      wr(12'h004 + (s-1)*4, 32'(s+2));
      rd(12'h004 + (s-1)*4); chk("prio rd", rd_data, s+2);
      // enable bit
      wr(12'h200, 32'(1<<(s-1)));
      rd(12'h200); chk("enable rd", rd_data & (1<<(s-1)), 1<<(s-1));
      // threshold 0, assert source
      wr(12'h204, 32'd0);
      ext_irq = 8'(1<<(s-1));
      repeat(6) @(posedge clk);
      rd(12'h208); chk("claim id", rd_data[3:0], s);
      wr(12'h208, s);
      ext_irq=0;
      repeat(6) @(posedge clk);
      rd(12'h100); chk("pending cleared", rd_data & (1<<(s-1)), 0);
    end
    // source 8 specific address wrap check
    wr(12'h020, 32'd9); rd(12'h020); chk("src8 prio addr 0x020", rd_data, 9);
    // two simultaneous sources priority
    reset_n=0; ext_irq=0; repeat(2) @(posedge clk); reset_n=1; repeat(2) @(posedge clk);
    wr(12'h004,32'd3); wr(12'h008,32'd5); wr(12'h200,32'h3); wr(12'h204,32'd0);
    ext_irq=8'h3; repeat(6) @(posedge clk); rd(12'h208); chk("simul claim high prio", rd_data[3:0], 2);
    // tie-break
    reset_n=0; ext_irq=0; repeat(2) @(posedge clk); reset_n=1; repeat(2) @(posedge clk);
    wr(12'h004,32'd5); wr(12'h008,32'd5); wr(12'h200,32'h3); wr(12'h204,32'd0);
    ext_irq=8'h3; repeat(6) @(posedge clk); rd(12'h208); chk("tie lowest id", rd_data[3:0], 1);
    // no interrupt claim 0
    reset_n=0; ext_irq=0; repeat(2) @(posedge clk); reset_n=1; repeat(2) @(posedge clk);
    rd(12'h208); chk("no claim", rd_data[3:0], 0);
    // invalid source id completion? claim write id 9 should mask none and not crash
    ext_irq=8'h1; wr(12'h004,32'd5); wr(12'h200,32'h1); repeat(6) @(posedge clk);
    wr(12'h208,32'd9); repeat(4) @(posedge clk); rd(12'h100); chk("invalid claim leaves pending", rd_data&1, 1);
    if(errors==0) begin $display("PLIC TARGETED: ALL TESTS PASSED"); end else begin $display("PLIC TARGETED: %0d FAILURES",errors); $fatal; end
    $finish;
  end
  initial begin #1000000; $display("PLIC TARGETED: TIMEOUT"); $fatal; end
endmodule