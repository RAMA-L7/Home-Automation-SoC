`timescale 1ns/1ps
module tb_cpu_arch;
  reg clk=0; reg reset_n=0;
  always #10 clk=~clk;
  reg [31:0] imem [0:1023]; reg [31:0] dmem [0:1023];
  wire instr_req,instr_rvalid,instr_err,data_req,data_we,data_rvalid,data_err;
  wire [31:0] instr_addr,instr_rdata,data_addr,data_wdata,data_rdata;
  wire [3:0] data_wstrb; wire instr_gnt,data_gnt;
  reg instr_pend=0,data_pend=0; reg [31:0] instr_rdata_q=0,data_rdata_q=0; reg instr_err_q=0,data_err_q=0;
  assign instr_gnt=instr_req & ~instr_pend; assign instr_rvalid=instr_pend; assign instr_rdata=instr_rdata_q; assign instr_err=instr_err_q;
  assign data_gnt=data_req & ~data_pend; assign data_rvalid=data_pend; assign data_rdata=data_rdata_q; assign data_err=data_err_q;
  wire [9:0] di=data_addr[11:2];
  riscv_core #(.RESET_PC(32'h0)) dut(.clk(clk),.reset_n(reset_n),.instr_req(instr_req),.instr_addr(instr_addr),.instr_gnt(instr_gnt),.instr_rdata(instr_rdata),.instr_rvalid(instr_rvalid),.instr_err(instr_err),.data_req(data_req),.data_we(data_we),.data_addr(data_addr),.data_wdata(data_wdata),.data_wstrb(data_wstrb),.data_gnt(data_gnt),.data_rdata(data_rdata),.data_rvalid(data_rvalid),.data_err(data_err),.irq_irq(1'b0),.irq_timer(1'b0),.irq_soft(1'b0),.debug_req(1'b0),.debug_halted(),.debug_running());
  always @(posedge clk) begin
    if(!reset_n) instr_pend<=0; else begin
      if(instr_gnt) begin instr_rdata_q<=imem[instr_addr[11:2]]; instr_err_q<=0; instr_pend<=1; end
      else if(instr_pend) instr_pend<=0;
    end
  end
  always @(posedge clk) begin
    if(!reset_n) data_pend<=0; else begin
      if(data_gnt) begin data_err_q<=0; if(data_we) begin if(data_wstrb[0]) dmem[di][7:0]<=data_wdata[7:0]; if(data_wstrb[1]) dmem[di][15:8]<=data_wdata[15:8]; if(data_wstrb[2]) dmem[di][23:16]<=data_wdata[23:16]; if(data_wstrb[3]) dmem[di][31:24]<=data_wdata[31:24]; end else data_rdata_q<=dmem[di]; data_pend<=1; end
      else if(data_pend) data_pend<=0;
    end
  end
  integer errors=0,checks=0;
  task chk(input [31:0] addr,input [31:0] exp,input [8*40-1:0] name); begin checks=checks+1; if(dmem[addr>>2]!==exp) begin errors=errors+1; $display("[cpuarch] FAIL %0s: got %08h exp %08h",name,dmem[addr>>2],exp); end else $display("[cpuarch] pass %0s",name); end endtask
  initial begin
    for(int k=0;k<1024;k++) begin imem[k]=32'h00000013; dmem[k]=0; end
    $readmemh("build/sim/tb_cpu_arch.hex", imem);
    repeat(10) @(posedge clk); reset_n=1;
    repeat(20000) @(posedge clk);
    chk(0, 32'd0, "CSR imm old mscratch");
    chk(4, 32'd7, "CSR imm new mscratch");
    // minstret increased
    if(dmem[3] <= dmem[2]) begin errors=errors+1; $display("[cpuarch] FAIL minstret did not increase"); end else $display("[cpuarch] pass minstret increased");
    chk(16, 32'h00001234, "LHU aligned");
    // final trap mcause from odd-address LHU = 4 (load misaligned)
    chk(32, 32'd4, "trap mcause (LHU odd)");
    if(errors==0) begin $display("CPU ARCH: ALL TESTS PASSED"); end else begin $display("CPU ARCH: %0d FAILURES",errors); $fatal; end
    $finish;
  end
  initial begin #1000000; $display("CPU ARCH: TIMEOUT"); $fatal; end
endmodule