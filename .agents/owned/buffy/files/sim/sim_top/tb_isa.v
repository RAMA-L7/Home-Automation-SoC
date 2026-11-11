//------------------------------------------------------------------------------
// Home-Automation-SoC — Directed RV32IM instruction test
//
// Purpose: reproduce/falsify the specific ISA defects reported in the
// independent review, using instruction words encoded by hand and expected
// results derived from the RISC-V spec.  It does NOT use scripts/fw/as.js, so
// a defect in the custom assembler cannot hide a defect in the core (or agree
// with it).
//
// DUT: rtl/rtl_top/riscv_core.sv, driven through its real req/gnt/rvalid
// memory interface with simple behavioural memories.  Results are observed in
// data memory, which also exercises the store path (S-type immediate).
//
// Run:
//   iverilog -g2012 -o build/sim/tb_isa.vvp -s tb_isa sim/sim_top/tb_isa.v \
//            rtl/rtl_top/riscv_core.sv
//   vvp build/sim/tb_isa.vvp          # exits nonzero on any failure
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_isa;

  reg clk = 0;
  reg reset_n = 0;
  always #10 clk = ~clk;

  //--------------------------------------------------------------------------
  // Instruction memory (57 words, hand encoded)
  //--------------------------------------------------------------------------
  reg [31:0] imem [0:1023];
  reg [31:0] dmem [0:1023];

  wire        instr_req;
  wire [31:0] instr_addr, instr_rdata;
  wire        instr_rvalid;
  reg         instr_gnt;

  wire        data_req, data_we;
  wire [31:0] data_addr, data_wdata, data_rdata;
  wire [3:0]  data_wstrb;
  wire        data_rvalid;
  reg         data_gnt;

  wire        irq_irq, irq_timer, irq_soft;
  wire        debug_halted, debug_running;

  riscv_core #(.RESET_PC(32'h0000_0000)) dut (
    .clk          (clk),
    .reset_n      (reset_n),
    .instr_req    (instr_req),
    .instr_addr   (instr_addr),
    .instr_gnt    (instr_gnt),
    .instr_rdata  (instr_rdata),
    .instr_rvalid (instr_rvalid),
    .data_req     (data_req),
    .data_we      (data_we),
    .data_addr    (data_addr),
    .data_wdata   (data_wdata),
    .data_wstrb   (data_wstrb),
    .data_gnt     (data_gnt),
    .data_rdata   (data_rdata),
    .data_rvalid  (data_rvalid),
    .irq_irq      (1'b0),
    .irq_timer    (1'b0),
    .irq_soft     (1'b0),
    .debug_req    (1'b0),
    .debug_halted (debug_halted),
    .debug_running(debug_running)
  );

  //--------------------------------------------------------------------------
  // Behavioural memories: gnt on accept, rvalid one cycle later.
  //--------------------------------------------------------------------------
  reg instr_pend = 0;
  reg [31:0] instr_rdata_q = 0;
  reg data_pend = 0;
  reg [31:0] data_rdata_q = 0;

  assign instr_gnt    = instr_req & ~instr_pend;
  assign instr_rvalid = instr_pend;
  assign instr_rdata  = instr_rdata_q;

  assign data_gnt    = data_req & ~data_pend;
  assign data_rvalid = data_pend;
  assign data_rdata  = data_rdata_q;

  wire [9:0] di = data_addr[11:2];

  always @(posedge clk) begin
    if (!reset_n) begin
      instr_pend <= 0;
    end else begin
      if (instr_gnt) begin
        instr_rdata_q <= imem[instr_addr[11:2]];
        instr_pend    <= 1;
      end else if (instr_pend) begin
        instr_pend    <= 0;
      end
    end
  end

  always @(posedge clk) begin
    if (!reset_n) begin
      data_pend <= 0;
    end else begin
      if (data_gnt) begin
        if (data_we) begin
          if (data_wstrb[0]) dmem[di][7:0]   <= data_wdata[7:0];
          if (data_wstrb[1]) dmem[di][15:8]  <= data_wdata[15:8];
          if (data_wstrb[2]) dmem[di][23:16] <= data_wdata[23:16];
          if (data_wstrb[3]) dmem[di][31:24] <= data_wdata[31:24];
        end else begin
          data_rdata_q <= dmem[di];
        end
        data_pend <= 1;
      end else if (data_pend) begin
        data_pend <= 0;
      end
    end
  end

  //--------------------------------------------------------------------------
  // Program
  //--------------------------------------------------------------------------
  initial begin
    for (int k = 0; k < 1024; k = k + 1) begin imem[k] = 32'h00000013; dmem[k] = 32'h0; end

    imem[16'h000 >> 2] = 32'h00200093;  // addi x1,x0,2
    imem[16'h004 >> 2] = 32'h0010F113;  // andi x2,x1,1        -> 0 (not 3)
    imem[16'h008 >> 2] = 32'h00202023;  // sw   x2,0(x0)
    imem[16'h00C >> 2] = 32'h0040E193;  // ori  x3,x1,4        -> 6
    imem[16'h010 >> 2] = 32'h00302223;  // sw   x3,4(x0)
    imem[16'h014 >> 2] = 32'h0030C213;  // xori x4,x1,3        -> 1
    imem[16'h018 >> 2] = 32'h00402423;  // sw   x4,8(x0)
    imem[16'h01C >> 2] = 32'hFF800293;  // addi x5,x0,-8       -> 0xFFFFFFF8
    imem[16'h020 >> 2] = 32'h01C2D313;  // srli x6,x5,28       -> 0xF
    imem[16'h024 >> 2] = 32'h00602623;  // sw   x6,12(x0)
    imem[16'h028 >> 2] = 32'h41C2D393;  // srai x7,x5,28       -> 0xFFFFFFFF
    imem[16'h02C >> 2] = 32'h00702823;  // sw   x7,16(x0)
    imem[16'h030 >> 2] = 32'h00500413;  // addi x8,x0,5
    imem[16'h034 >> 2] = 32'hFFF42493;  // slti x9,x8,-1       -> 0
    imem[16'h038 >> 2] = 32'h00902A23;  // sw   x9,20(x0)
    imem[16'h03C >> 2] = 32'h00001517;  // auipc x10,1         -> 0x03C+0x1000
    imem[16'h040 >> 2] = 32'h00A02C23;  // sw   x10,24(x0)
    imem[16'h044 >> 2] = 32'h00700593;  // addi x11,x0,7
    imem[16'h048 >> 2] = 32'hFFD00613;  // addi x12,x0,-3
    imem[16'h04C >> 2] = 32'h02C586B3;  // mul  x13,x11,x12    -> -21
    imem[16'h050 >> 2] = 32'h00D02E23;  // sw   x13,28(x0)
    imem[16'h054 >> 2] = 32'h02C59733;  // mulh x14,x11,x12    -> 0xFFFFFFFF
    imem[16'h058 >> 2] = 32'h02E02023;  // sw   x14,32(x0)
    imem[16'h05C >> 2] = 32'h02C5A7B3;  // mulhsu x15,x11,x12  -> 6
    imem[16'h060 >> 2] = 32'h02F02223;  // sw   x15,36(x0)
    imem[16'h064 >> 2] = 32'h80000837;  // lui  x16,0x80000    -> 0x80000000
    imem[16'h068 >> 2] = 32'hFFF00893;  // addi x17,x0,-1      -> 0xFFFFFFFF
    imem[16'h06C >> 2] = 32'h03185933;  // divu x18,x16,x17    -> 0
    imem[16'h070 >> 2] = 32'h03202423;  // sw   x18,40(x0)
    imem[16'h074 >> 2] = 32'h031879B3;  // remu x19,x16,x17    -> 0x80000000
    imem[16'h078 >> 2] = 32'h03302623;  // sw   x19,44(x0)
    imem[16'h07C >> 2] = 32'h03184A33;  // div  x20,x16,x17    -> 0x80000000 (overflow)
    imem[16'h080 >> 2] = 32'h03402823;  // sw   x20,48(x0)
    imem[16'h084 >> 2] = 32'h03186AB3;  // rem  x21,x16,x17    -> 0
    imem[16'h088 >> 2] = 32'h03502A23;  // sw   x21,52(x0)
    imem[16'h08C >> 2] = 32'h0200DB33;  // divu x22,x1,x0      -> 0xFFFFFFFF (div by 0)
    imem[16'h090 >> 2] = 32'h03602C23;  // sw   x22,56(x0)
    imem[16'h094 >> 2] = 32'h0200EBB3;  // rem  x23,x1,x0      -> 2 (rem by 0)
    imem[16'h098 >> 2] = 32'h03702E23;  // sw   x23,60(x0)
    imem[16'h09C >> 2] = 32'h12345C37;  // lui  x24,0x12345
    imem[16'h0A0 >> 2] = 32'h678C0C13;  // addi x24,x24,0x678  -> 0x12345678
    imem[16'h0A4 >> 2] = 32'h05802023;  // sw   x24,0x40(x0)
    imem[16'h0A8 >> 2] = 32'h04002C83;  // lw   x25,0x40(x0)   -> 0x12345678
    imem[16'h0AC >> 2] = 32'h05902223;  // sw   x25,0x44(x0)
    imem[16'h0B0 >> 2] = 32'h04100D03;  // lb   x26,0x41(x0)   -> 0x56
    imem[16'h0B4 >> 2] = 32'h05A02423;  // sw   x26,0x48(x0)
    imem[16'h0B8 >> 2] = 32'h04104D83;  // lbu  x27,0x41(x0)   -> 0x56
    imem[16'h0BC >> 2] = 32'h05B02623;  // sw   x27,0x4C(x0)
    imem[16'h0C0 >> 2] = 32'h04201E03;  // lh   x28,0x42(x0)   -> 0x1234
    imem[16'h0C4 >> 2] = 32'h05C02823;  // sw   x28,0x50(x0)
    imem[16'h0C8 >> 2] = 32'hFFF00F13;  // addi x30,x0,-1
    imem[16'h0CC >> 2] = 32'h05E00A23;  // sb   x30,0x54(x0)   -> byte 0xFF
    imem[16'h0D0 >> 2] = 32'h05400F83;  // lb   x31,0x54(x0)   -> 0xFFFFFFFF
    imem[16'h0D4 >> 2] = 32'h05F02C23;  // sw   x31,0x58(x0)
    imem[16'h0D8 >> 2] = 32'h00409E93;  // slli x29,x1,4       -> 32
    imem[16'h0DC >> 2] = 32'h05D02E23;  // sw   x29,0x5C(x0)
    imem[16'h0E0 >> 2] = 32'h0000006F;  // jal  x0,0 (halt loop)
  end

  //--------------------------------------------------------------------------
  // Checking
  //--------------------------------------------------------------------------
  integer errors = 0;
  integer checks = 0;

  task chk(input [11:0] addr, input [31:0] exp, input [8*40-1:0] name);
    begin
      checks = checks + 1;
      if (dmem[addr >> 2] !== exp) begin
        errors = errors + 1;
        $display("[isa] FAIL %0s: mem[0x%03h] = 0x%08h, expected 0x%08h",
                 name, addr, dmem[addr >> 2], exp);
      end
    end
  endtask

  initial begin
    $display("=== HAS-SoC directed RV32IM test ===");
    repeat (10) @(posedge clk);
    reset_n = 1;

    // 57 instructions, each taking a handful of cycles.
    repeat (4000) @(posedge clk);

    chk(12'h000, 32'h0000_0000, "andi  2 & 1");
    chk(12'h004, 32'h0000_0006, "ori   2 | 4");
    chk(12'h008, 32'h0000_0001, "xori  2 ^ 3");
    chk(12'h00C, 32'h0000_000F, "srli  -8 >> 28");
    chk(12'h010, 32'hFFFF_FFFF, "srai  -8 >>> 28");
    chk(12'h014, 32'h0000_0000, "slti  5 < -1");
    chk(12'h018, 32'h0000_103C, "auipc pc=0x03C + 0x1000");
    chk(12'h01C, 32'hFFFF_FFEB, "mul   7 * -3");
    chk(12'h020, 32'hFFFF_FFFF, "mulh  7 * -3");
    chk(12'h024, 32'h0000_0006, "mulhsu 7 * u(-3)");
    chk(12'h028, 32'h0000_0000, "divu  0x80000000 / 0xFFFFFFFF");
    chk(12'h02C, 32'h8000_0000, "remu  0x80000000 % 0xFFFFFFFF");
    chk(12'h030, 32'h8000_0000, "div   signed overflow");
    chk(12'h034, 32'h0000_0000, "rem   signed overflow");
    chk(12'h038, 32'hFFFF_FFFF, "divu  by zero");
    chk(12'h03C, 32'h0000_0002, "rem   by zero");
    chk(12'h040, 32'h1234_5678, "sw/lw 0x12345678");
    chk(12'h044, 32'h1234_5678, "lw    0x12345678");
    chk(12'h048, 32'h0000_0056, "lb    0x41");
    chk(12'h04C, 32'h0000_0056, "lbu   0x41");
    chk(12'h050, 32'h0000_1234, "lh    0x42");
    chk(12'h054, 32'h0000_00FF, "sb    0xFF");
    chk(12'h058, 32'hFFFF_FFFF, "lb    0xFF sign-extends");
    chk(12'h05C, 32'h0000_0020, "slli  2 << 4");

    $display("[isa] checks: %0d, failures: %0d", checks, errors);
    if (errors != 0) begin
      $display("[isa] RESULT: FAIL");
      $fatal(1, "[isa] %0d check(s) failed", errors);
    end
    $display("[isa] RESULT: PASS");
    $finish;
  end

  initial begin
    #2_000_000;
    $display("[isa] TIMEOUT");
    $fatal(1, "[isa] simulation timeout");
  end

endmodule
