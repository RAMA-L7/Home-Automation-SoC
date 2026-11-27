//------------------------------------------------------------------------------
// RUN-0027 — directed signed/unsigned divide + remainder sign-fixup check
//
// tb_isa.v already checks the architecturally defined special cases (divide by
// zero, signed overflow, DIVU/REMU of 0x80000000/0xFFFFFFFF) but not ordinary
// division with negative operands, which is where the sign fixup lives.  This
// bench runs the same program against the published core (prefix) and the
// iterative-divider core (postfix); identical memory contents on both is the
// equivalence evidence for the rewrite.
//
// Instructions are hand-encoded RV32IM words (not produced by scripts/fw/as.js)
// so an assembler defect cannot agree with a core defect.
//
//   iverilog -g2012 -o build/sim/tb_muldiv_sign.vvp -s tb_muldiv_sign \
//            research/runs/RUN-0027-.../tb_muldiv_sign.v <riscv_core.sv>
//   vvp build/sim/tb_muldiv_sign.vvp
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_muldiv_sign;

  reg clk = 0;
  reg reset_n = 0;
  always #10 clk = ~clk;

  reg [31:0] imem [0:255];
  reg [31:0] dmem [0:255];

  wire        instr_req;
  wire [31:0] instr_addr, instr_rdata;
  wire        instr_rvalid, instr_err;
  reg         instr_gnt;

  wire        data_req, data_we;
  wire [31:0] data_addr, data_wdata, data_rdata;
  wire [3:0]  data_wstrb;
  wire        data_rvalid, data_err;
  reg         data_gnt;

  wire irq_irq, irq_timer, irq_soft, debug_halted, debug_running;

  riscv_core #(.RESET_PC(32'h0000_0000)) dut (
    .clk(clk), .reset_n(reset_n),
    .instr_req(instr_req), .instr_addr(instr_addr), .instr_gnt(instr_gnt),
    .instr_rdata(instr_rdata), .instr_rvalid(instr_rvalid), .instr_err(instr_err),
    .data_req(data_req), .data_we(data_we), .data_addr(data_addr),
    .data_wdata(data_wdata), .data_wstrb(data_wstrb), .data_gnt(data_gnt),
    .data_rdata(data_rdata), .data_rvalid(data_rvalid), .data_err(data_err),
    .irq_irq(1'b0), .irq_timer(1'b0), .irq_soft(1'b0),
    .debug_req(1'b0), .debug_halted(debug_halted), .debug_running(debug_running)
  );

  reg instr_pend = 0, data_pend = 0;
  reg [31:0] instr_rdata_q = 0, data_rdata_q = 0;

  assign instr_gnt    = instr_req & ~instr_pend;
  assign instr_rvalid = instr_pend;
  assign instr_rdata  = instr_rdata_q;
  assign instr_err    = 1'b0;
  assign data_gnt     = data_req & ~data_pend;
  assign data_rvalid  = data_pend;
  assign data_rdata   = data_rdata_q;
  assign data_err     = 1'b0;

  wire [7:0] di = data_addr[9:2];

  always @(posedge clk) begin
    if (!reset_n) instr_pend <= 0;
    else if (instr_gnt) begin
      instr_rdata_q <= imem[instr_addr[9:2]];
      instr_pend    <= 1;
    end else if (instr_pend) instr_pend <= 0;
  end

  always @(posedge clk) begin
    if (!reset_n) data_pend <= 0;
    else if (data_gnt) begin
      if (data_we) begin
        if (data_wstrb[0]) dmem[di][7:0]   <= data_wdata[7:0];
        if (data_wstrb[1]) dmem[di][15:8]  <= data_wdata[15:8];
        if (data_wstrb[2]) dmem[di][23:16] <= data_wdata[23:16];
        if (data_wstrb[3]) dmem[di][31:24] <= data_wdata[31:24];
      end else data_rdata_q <= dmem[di];
      data_pend <= 1;
    end else if (data_pend) data_pend <= 0;
  end

  integer checks = 0, errors = 0;

  task chk(input [7:0] idx, input [31:0] exp, input [8*40-1:0] name);
    begin
      checks = checks + 1;
      if (dmem[idx] !== exp) begin
        errors = errors + 1;
        $display("[muldiv] FAIL %0s: mem[%0d] = 0x%08h, expected 0x%08h",
                 name, idx, dmem[idx], exp);
      end
    end
  endtask

  initial begin
    for (int k = 0; k < 256; k = k + 1) begin
      imem[k] = 32'h0000_0013;   // NOP
      dmem[k] = 32'h0;
    end
    imem[0]  = 32'hff90_0093;  // addi x1, x0, -7
    imem[1]  = 32'h0020_0113;  // addi x2, x0, 2
    imem[2]  = 32'h0220_c1b3;  // div  x3, x1, x2   -> -3
    imem[3]  = 32'h0220_e233;  // rem  x4, x1, x2   -> -1
    imem[4]  = 32'h0070_0293;  // addi x5, x0, 7
    imem[5]  = 32'hffe0_0313;  // addi x6, x0, -2
    imem[6]  = 32'h0262_c3b3;  // div  x7, x5, x6   -> -3
    imem[7]  = 32'h0262_e433;  // rem  x8, x5, x6   -> 1
    imem[8]  = 32'h0260_c4b3;  // div  x9, x1, x6   -> 3
    imem[9]  = 32'h0260_e533;  // rem  x10, x1, x6  -> -1
    imem[10] = 32'h3e80_0593;  // addi x11, x0, 1000
    imem[11] = 32'h0070_0613;  // addi x12, x0, 7
    imem[12] = 32'h02c5_d6b3;  // divu x13, x11, x12 -> 142
    imem[13] = 32'h02c5_f733;  // remu x14, x11, x12 -> 6
    imem[14] = 32'hc180_0793;  // addi x15, x0, -1000
    imem[15] = 32'h02c7_c833;  // div  x16, x15, x12 -> -142
    imem[16] = 32'h02c7_e8b3;  // rem  x17, x15, x12 -> -6
    imem[17] = 32'h0030_2023;  // sw x3,  0(x0)
    imem[18] = 32'h0040_2223;  // sw x4,  4(x0)
    imem[19] = 32'h0070_2423;  // sw x7,  8(x0)
    imem[20] = 32'h0080_2623;  // sw x8, 12(x0)
    imem[21] = 32'h0090_2823;  // sw x9, 16(x0)
    imem[22] = 32'h00a0_2a23;  // sw x10,20(x0)
    imem[23] = 32'h00d0_2c23;  // sw x13,24(x0)
    imem[24] = 32'h00e0_2e23;  // sw x14,28(x0)
    imem[25] = 32'h0300_2023;  // sw x16,32(x0)
    imem[26] = 32'h0310_2223;  // sw x17,36(x0)
  end

  initial begin
    $display("=== M-extension signed divide/remainder check ===");
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (2000) @(posedge clk);

    chk(8'd0, 32'hFFFF_FFFD, "-7 / 2");
    chk(8'd1, 32'hFFFF_FFFF, "-7 % 2");
    chk(8'd2, 32'hFFFF_FFFD, " 7 / -2");
    chk(8'd3, 32'h0000_0001, " 7 % -2");
    chk(8'd4, 32'h0000_0003, "-7 / -2");
    chk(8'd5, 32'hFFFF_FFFF, "-7 % -2");
    chk(8'd6, 32'h0000_008E, "1000 / 7 unsigned");
    chk(8'd7, 32'h0000_0006, "1000 % 7 unsigned");
    chk(8'd8, 32'hFFFF_FF72, "-1000 / 7");
    chk(8'd9, 32'hFFFF_FFFA, "-1000 % 7");

    $display("[muldiv] checks: %0d, failures: %0d", checks, errors);
    if (errors != 0) begin
      $display("[muldiv] RESULT: FAIL");
      $fatal(1, "[muldiv] %0d check(s) failed", errors);
    end
    $display("[muldiv] RESULT: PASS");
    $finish;
  end

  initial begin
    #400_000;
    $display("[muldiv] TIMEOUT");
    $fatal(1, "[muldiv] simulation timeout");
  end

  initial begin
    $dumpfile("build/sim/tb_muldiv_sign.vcd");
    $dumpvars(0, tb_muldiv_sign);
  end

endmodule
