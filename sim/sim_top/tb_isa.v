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
// Phase 2 (from 0x0E4) exercises the exception paths with a trap handler at
// 0x200: misaligned load/store, illegal instruction, load/store access fault,
// misaligned jump target and instruction access fault.  The words were encoded
// from an assembly listing assembled and disassembled with the independent GNU
// toolchain (riscv-none-elf-as 2.38), not with scripts/fw/as.js — see
// build/fw/isa_ext.s in the review log.  The bench injects bus errors for the
// data address 0x400/0x404 and the instruction address 0x900.
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
  wire        instr_err;
  reg         instr_gnt;

  wire        data_req, data_we;
  wire [31:0] data_addr, data_wdata, data_rdata;
  wire [3:0]  data_wstrb;
  wire        data_rvalid;
  wire        data_err;
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
    .instr_err    (instr_err),
    .data_req     (data_req),
    .data_we      (data_we),
    .data_addr    (data_addr),
    .data_wdata   (data_wdata),
    .data_wstrb   (data_wstrb),
    .data_gnt     (data_gnt),
    .data_rdata   (data_rdata),
    .data_rvalid  (data_rvalid),
    .data_err     (data_err),
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
  reg instr_err_q = 0;
  reg data_err_q = 0;

  assign instr_gnt    = instr_req & ~instr_pend;
  assign instr_rvalid = instr_pend;
  assign instr_rdata  = instr_rdata_q;
  assign instr_err    = instr_err_q;

  assign data_gnt    = data_req & ~data_pend;
  assign data_rvalid = data_pend;
  assign data_rdata  = data_rdata_q;
  assign data_err    = data_err_q;



  wire [9:0] di = data_addr[11:2];

  // Fault injection windows: data 0x400/0x404 and instruction 0x900.
  wire inject_data_err = (di == 10'h100) || (di == 10'h101);

  always @(posedge clk) begin
    if (!reset_n) begin
      instr_pend <= 0;
    end else begin
      if (instr_gnt) begin
        instr_rdata_q <= imem[instr_addr[11:2]];
        instr_err_q   <= (instr_addr == 32'h0000_0900);
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
        data_err_q <= inject_data_err;
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
    imem[16'h0E0 >> 2] = 32'h0040006F;  // jal  x0,+4 (enter the exception phase)

    //--- exception phase setup (from build/fw/isa_ext.s, GNU as) -----------------
    imem[16'h0E4 >> 2] = 32'h20000513;  // addi a0,x0,0x200    (trap log pointer)
    imem[16'h0E8 >> 2] = 32'h30200093;  // addi x1,x0,0x302    (2-byte-aligned target)
    imem[16'h0EC >> 2] = 32'h00001137;  // lui  x2,1
    imem[16'h0F0 >> 2] = 32'h90010113;  // addi x2,x2,-1792    (x2 = 0x900)
    imem[16'h0F4 >> 2] = 32'h20000293;  // addi t0,x0,0x200
    imem[16'h0F8 >> 2] = 32'h30529073;  // csrw mtvec,t0
    imem[16'h0FC >> 2] = 32'h1FC0006F;  // jal  x0,0x2F8
    imem[16'h2F8 >> 2] = 32'h05A00E13;  // addi x28,x0,0x5A    (known value, must survive the failed load)

    //--- trap handler: log mcause/mtval/mepc, advance log, mepc+=4, mret -----------
    imem[16'h200 >> 2] = 32'h342022F3;  // csrr t0,mcause
    imem[16'h204 >> 2] = 32'h00552023;  // sw   t0,0(a0)
    imem[16'h208 >> 2] = 32'h34302373;  // csrr t1,mtval
    imem[16'h20C >> 2] = 32'h00652223;  // sw   t1,4(a0)
    imem[16'h210 >> 2] = 32'h341023F3;  // csrr t2,mepc
    imem[16'h214 >> 2] = 32'h00752423;  // sw   t2,8(a0)
    imem[16'h218 >> 2] = 32'h00C50513;  // addi a0,a0,12
    imem[16'h21C >> 2] = 32'h00438393;  // addi t2,t2,4
    imem[16'h220 >> 2] = 32'h34139073;  // csrw mepc,t2
    imem[16'h224 >> 2] = 32'h30200073;  // mret

    //--- faulting instructions ----------------------------------------------------
    imem[16'h300 >> 2] = 32'h00202283;  // lw   x5,2(x0)       -> cause 4, tval 2
    imem[16'h304 >> 2] = 32'h005011A3;  // sh   x5,3(x0)       -> cause 6, tval 3
    imem[16'h308 >> 2] = 32'h00000000;  // illegal             -> cause 2
    imem[16'h30C >> 2] = 32'h40002E03;  // lw   x28,0x400(x0)  -> cause 5, tval 0x400
    imem[16'h310 >> 2] = 32'h41C02223;  // sw   x28,0x404(x0)  -> cause 7, tval 0x404
    imem[16'h314 >> 2] = 32'h00008067;  // jalr x0,0(x1)=0x302 -> cause 0, tval 0x302
    imem[16'h318 >> 2] = 32'h05500393;  // addi x7,x0,0x55
    imem[16'h31C >> 2] = 32'h10702023;  // sw   x7,0x100(x0)   (survived the bad jump)
    imem[16'h320 >> 2] = 32'h11C02223;  // sw   x28,0x104(x0)  (x28 must be unchanged)
    imem[16'h324 >> 2] = 32'h00010067;  // jalr x0,0(x2)=0x900 -> cause 1, tval 0x900
    imem[16'h400 >> 2] = 32'h0000006F;  // halt loop
    imem[16'h904 >> 2] = 32'hAFDFF06F;  // jal  x0,0x400       (landing after fetch fault)
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

    // 57 instructions plus the exception phase (7 traps, each with a
    // 9-instruction handler), each taking a handful of cycles.
    repeat (8000) @(posedge clk);

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

    //--- phase 2: exception causes, tval, mepc -----------------------------------
    // Each trap logs mcause, mtval, mepc in a 12-byte slot.
    chk(12'h200, 32'h0000_0004, "trap1 mcause misaligned load");
    chk(12'h204, 32'h0000_0002, "trap1 mtval  = 2");
    chk(12'h208, 32'h0000_0300, "trap1 mepc   = 0x300");

    chk(12'h20C, 32'h0000_0006, "trap2 mcause misaligned store");
    chk(12'h210, 32'h0000_0003, "trap2 mtval  = 3");
    chk(12'h214, 32'h0000_0304, "trap2 mepc   = 0x304");

    chk(12'h218, 32'h0000_0002, "trap3 mcause illegal instruction");
    chk(12'h21C, 32'h0000_0000, "trap3 mtval  = instruction word");
    chk(12'h220, 32'h0000_0308, "trap3 mepc   = 0x308");

    chk(12'h224, 32'h0000_0005, "trap4 mcause load access fault");
    chk(12'h228, 32'h0000_0400, "trap4 mtval  = 0x400");
    chk(12'h22C, 32'h0000_030C, "trap4 mepc   = 0x30C");

    chk(12'h230, 32'h0000_0007, "trap5 mcause store access fault");
    chk(12'h234, 32'h0000_0404, "trap5 mtval  = 0x404");
    chk(12'h238, 32'h0000_0310, "trap5 mepc   = 0x310");

    chk(12'h23C, 32'h0000_0000, "trap6 mcause misaligned jump target");
    chk(12'h240, 32'h0000_0302, "trap6 mtval  = 0x302");
    chk(12'h244, 32'h0000_0314, "trap6 mepc   = 0x314");

    chk(12'h248, 32'h0000_0001, "trap7 mcause instruction access fault");
    chk(12'h24C, 32'h0000_0900, "trap7 mtval  = 0x900");
    chk(12'h250, 32'h0000_0900, "trap7 mepc   = 0x900");

    // Execution continued after every trap: the marker store ran, and the
    // faulting load left x28 untouched (no invalid register write-back).
    chk(12'h100, 32'h0000_0055, "recovered after misaligned jump");
    chk(12'h104, 32'h0000_005A, "faulting load did not write rd");

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
