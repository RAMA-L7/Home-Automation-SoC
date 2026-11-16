//------------------------------------------------------------------------------
// Home-Automation-SoC — CPU architectural test (CSR semantics, retirement,
// alignment)
//
// The instruction words below were produced by GNU as 2.38, NOT by the DUT and
// NOT by scripts/fw/as.js, so a decoder assumption in either cannot make the
// test agree with the bug it is meant to catch:
//
//   riscv-none-elf-as -march=rv32im_zicsr -mabi=ilp32 \
//       -o build/asm/csr_arch.o sim/asm/csr_arch.S
//   riscv-none-elf-objdump -d build/asm/csr_arch.o
//
// sim/asm/csr_arch.S is the source of record; the words here are its listing.
//
// Defects targeted:
//   A1  CSRRWI/CSRRSI/CSRRCI must use the zero-extended zimm in the rs1 field,
//       not the contents of the register with that index.  x7 is set to -1 and
//       the zimm field is 7, so the two readings are 7 vs 0xFFFFFFFF.
//   A2  An unsupported CSR access must raise illegal instruction (mcause 2);
//       it used to read 0 and discard writes silently.
//   A3  A write to a read-only CSR must trap, while a *read* of the same CSR
//       with rs1 = x0 must not (the CSRRS/CSRRC "no write when rs1 == 0" rule).
//   A4  minstret counts architectural retirement, not fetches, so a trapping
//       instruction must not increment it.
//   A5  A faulting load must not write its destination register.
//   A6  Odd-addressed LHU must trap with cause 4 and the faulting address in
//       mtval.  Testing only funct3 == 001 (LH) let LHU escape the alignment
//       check and return the aligned halfword instead.
//
// DUT: rtl/rtl_top/riscv_core.sv through its real req/gnt/rvalid interface.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_csr_arch;

  reg clk = 1'b0;
  reg reset_n = 1'b0;
  always #10 clk = ~clk;

  reg [31:0] imem [0:1023];
  reg [31:0] dmem [0:1023];

  wire        instr_req, instr_rvalid, instr_err;
  wire [31:0] instr_addr, instr_rdata;
  wire        data_req, data_we, data_rvalid, data_err;
  wire [31:0] data_addr, data_wdata, data_rdata;
  wire [3:0]  data_wstrb;
  wire        instr_gnt, data_gnt;

  // Two-phase memory: gnt in the cycle after the request, rvalid one cycle
  // later.  This is the contract req_gnt_to_axi_lite provides in the SoC.
  reg         instr_pend = 1'b0, data_pend = 1'b0;
  reg [31:0]  instr_rdata_q = 32'd0, data_rdata_q = 32'd0;
  reg         instr_err_q = 1'b0, data_err_q = 1'b0;

  assign instr_gnt    = instr_req & ~instr_pend;
  assign instr_rvalid = instr_pend;
  assign instr_rdata  = instr_rdata_q;
  assign instr_err    = instr_err_q;
  assign data_gnt     = data_req & ~data_pend;
  assign data_rvalid  = data_pend;
  assign data_rdata   = data_rdata_q;
  assign data_err     = data_err_q;

  wire [9:0] di = data_addr[11:2];

  riscv_core #(.RESET_PC(32'h0000_0000)) dut (
    .clk(clk), .reset_n(reset_n),
    .instr_req(instr_req), .instr_addr(instr_addr), .instr_gnt(instr_gnt),
    .instr_rdata(instr_rdata), .instr_rvalid(instr_rvalid), .instr_err(instr_err),
    .data_req(data_req), .data_we(data_we), .data_addr(data_addr),
    .data_wdata(data_wdata), .data_wstrb(data_wstrb), .data_gnt(data_gnt),
    .data_rdata(data_rdata), .data_rvalid(data_rvalid), .data_err(data_err),
    .irq_irq(1'b0), .irq_timer(1'b0), .irq_soft(1'b0),
    .debug_req(1'b0), .debug_halted(), .debug_running()
  );

  always @(posedge clk) begin
    if (!reset_n) begin
      instr_pend   <= 1'b0;
      instr_err_q  <= 1'b0;
    end else if (instr_gnt) begin
      instr_rdata_q <= imem[instr_addr[11:2]];
      instr_err_q   <= 1'b0;
      instr_pend    <= 1'b1;
    end else if (instr_pend) begin
      instr_pend    <= 1'b0;
    end
  end

  always @(posedge clk) begin
    if (!reset_n) begin
      data_pend  <= 1'b0;
      data_err_q <= 1'b0;
    end else if (data_gnt) begin
      data_err_q <= 1'b0;
      if (data_we) begin
        if (data_wstrb[0]) dmem[di][7:0]   <= data_wdata[7:0];
        if (data_wstrb[1]) dmem[di][15:8]  <= data_wdata[15:8];
        if (data_wstrb[2]) dmem[di][23:16] <= data_wdata[23:16];
        if (data_wstrb[3]) dmem[di][31:24] <= data_wdata[31:24];
      end else begin
        data_rdata_q <= dmem[di];
      end
      data_pend <= 1'b1;
    end else if (data_pend) begin
      data_pend <= 1'b0;
    end
  end

  //--------------------------------------------------------------------------
  // Program image (listing of sim/asm/csr_arch.S)
  //--------------------------------------------------------------------------
  task load_program;
    begin
      for (int k = 0; k < 1024; k = k + 1) begin
        imem[k] = 32'h0000_0013;      // nop
        dmem[k] = 32'h0000_0000;
      end
      // 0x000 — setup and the CSR probes
      imem[ 0] = 32'h000002b7;  // lui   t0, 0
      imem[ 1] = 32'h20000293;  // addi  t0, x0, 0x200
      imem[ 2] = 32'h30529073;  // csrw  mtvec, t0
      imem[ 3] = 32'h0000c2b7;  // lui   t0, 0xc
      imem[ 4] = 32'heef28293;  // addi  t0, t0, -273        (t0 = 0xBEEF)
      imem[ 5] = 32'h04501023;  // sh    t0, 0x40(x0)
      imem[ 6] = 32'hfff00393;  // addi  x7, x0, -1
      imem[ 7] = 32'h3403d573;  // csrrwi x10, mscratch, 7   <- A1
      imem[ 8] = 32'h340025f3;  // csrrs  x11, mscratch, x0
      imem[ 9] = 32'h00a02023;  // sw    x10, 0(x0)
      imem[10] = 32'h00b02223;  // sw    x11, 4(x0)
      imem[11] = 32'h34086673;  // csrrsi x12, mscratch, 0x10
      imem[12] = 32'h00c02423;  // sw    x12, 8(x0)
      imem[13] = 32'h3400f6f3;  // csrrci x13, mscratch, 0x01
      imem[14] = 32'h00d02623;  // sw    x13, 12(x0)
      imem[15] = 32'hf1429073;  // csrw  mhartid, t0         <- A3 (must trap)
      imem[16] = 32'hf14020f3;  // csrrs x1, mhartid, x0     <- A3 (must not trap)
      imem[17] = 32'h00102823;  // sw    x1, 16(x0)
      imem[18] = 32'h30102773;  // csrr  x14, 0x301          <- A2 (must trap)
      imem[19] = 32'h00e02a23;  // sw    x14, 20(x0)
      imem[20] = 32'hb0202a73;  // csrr  x20, minstret       <- A4
      imem[21] = 32'h07402623;  // sw    x20, 0x6C(x0)
      imem[22] = 32'h00000000;  // illegal instruction       <- A4 (must not retire)
      imem[23] = 32'hdeadbf37;  // lui   x30, 0xDEADB
      imem[24] = 32'h7eff0f13;  // addi  x30, x30, 0x7EF     (x30 = 0xDEADB7EF)
      imem[25] = 32'h04000313;  // addi  x6, x0, 0x40
      imem[26] = 32'h00232f03;  // lw    x30, 2(x6)          <- A5 (misaligned)
      imem[27] = 32'h09e02c23;  // sw    x30, 0x98(x0)
      imem[28] = 32'h04000313;  // addi  x6, x0, 0x40
      imem[29] = 32'h00135c03;  // lhu   x24, 1(x6)          <- A6 (must trap)
      imem[30] = 32'h09802e23;  // sw    x24, 0x9C(x0)
      imem[31] = 32'h04000313;  // addi  x6, x0, 0x40
      imem[32] = 32'h00035c83;  // lhu   x25, 0(x6)          (aligned control)
      imem[33] = 32'h0b902023;  // sw    x25, 0xA0(x0)
      imem[34] = 32'h0000006f;  // j     .

      // 0x200 — trap handler (word index 128)
      imem[128] = 32'hb02024f3; // csrr  s1, minstret
      imem[129] = 32'h30002283; // lw    t0, 0x300(x0)
      imem[130] = 32'h00128313; // addi  t1, t0, 1
      imem[131] = 32'h30602023; // sw    t1, 0x300(x0)
      imem[132] = 32'h00229293; // slli  t0, t0, 2
      imem[133] = 32'h40000393; // li    t2, 0x400
      imem[134] = 32'h007282b3; // add   t0, t0, t2
      imem[135] = 32'h30000393; // li    t2, 0x300
      imem[136] = 32'h007283b3; // add   t2, t0, t2
      imem[137] = 32'h0093a023; // sw    s1, 0(t2)
      imem[138] = 32'h34202373; // csrr  t1, mcause
      imem[139] = 32'h0062a023; // sw    t1, 0(t0)
      imem[140] = 32'h34302373; // csrr  t1, mtval
      imem[141] = 32'h10000393; // li    t2, 0x100
      imem[142] = 32'h007283b3; // add   t2, t0, t2
      imem[143] = 32'h0063a023; // sw    t1, 0(t2)
      imem[144] = 32'h34102373; // csrr  t1, mepc
      imem[145] = 32'h20000393; // li    t2, 0x200
      imem[146] = 32'h007283b3; // add   t2, t0, t2
      imem[147] = 32'h0063a023; // sw    t1, 0(t2)
      imem[148] = 32'h00430313; // addi  t1, t1, 4
      imem[149] = 32'h34131073; // csrw  mepc, t1
      imem[150] = 32'h30200073; // mret
    end
  endtask

  //--------------------------------------------------------------------------
  // Checks
  //--------------------------------------------------------------------------
  integer errors = 0;
  integer checks = 0;

  task chk(input [8*44-1:0] name, input [31:0] got, input [31:0] exp);
    begin
      checks = checks + 1;
      if (got !== exp) begin
        errors = errors + 1;
        $display("[csrarch] FAIL %0s: got 0x%08h expected 0x%08h", name, got, exp);
      end else begin
        $display("[csrarch] pass %0s = 0x%08h", name, got);
      end
    end
  endtask

  task chk_ne(input [8*44-1:0] name, input [31:0] got, input [31:0] not_exp);
    begin
      checks = checks + 1;
      if (got === not_exp) begin
        errors = errors + 1;
        $display("[csrarch] FAIL %0s: got the rejected value 0x%08h", name, got);
      end else begin
        $display("[csrarch] pass %0s = 0x%08h", name, got);
      end
    end
  endtask

  initial begin
    load_program;
    reset_n = 1'b0;
    repeat (10) @(posedge clk);
    reset_n = 1'b1;

    // The program is short; 4000 cycles is ~800 instructions on this
    // multi-cycle core, far more than the ~90 it executes.
    repeat (4000) @(posedge clk);

    // Word indices of the handler's per-trap slots (byte address / 4).
    //   mcause 0x400+i -> 256+i   mtval 0x500+i -> 320+i
    //   mepc   0x600+i -> 384+i   minstret-at-entry 0x700+i -> 448+i
    $display("");
    $display("[csrarch] trap count (handler index) = %0d", dmem[192]);
    chk("A0 trap count", dmem[192], 32'd5);

    // A1 — CSR-immediate forms use zimm, not rf[rs1].
    chk("A1 mscratch old value (csrrwi rd)", dmem[0], 32'd0);
    chk_ne("A1 csrrwi wrote zimm, not rf[7]", dmem[1], 32'hFFFF_FFFF);
    chk("A1 mscratch == 7 after csrrwi", dmem[1], 32'd7);
    chk("A1 mscratch before csrrsi", dmem[2], 32'd7);
    chk("A1 csrrsi OR'd 0x10 from zimm", dmem[3], 32'h17);

    // A3 — read-only CSR read is legal, write is not.
    chk("A3 mhartid reads 0", dmem[4], 32'd0);
    chk("A3 write to mhartid raised illegal", dmem[256], 32'd2);
    // A2 — unsupported CSR access raises illegal.
    chk("A2 unsupported misa raised illegal", dmem[257], 32'd2);
    // A4 — the illegal instruction itself traps too.
    chk("A4 illegal instruction raised illegal", dmem[258], 32'd2);

    // A4 — retirement: minstret advances by exactly 2 across
    // (csrr, sw, trapping instruction).  Counting at fetch made it 3.
    chk("A4 minstret at trap entry == before + 2", dmem[450], dmem[27] + 32'd2);

    // A5 — faulting load traps and does not write back.
    chk("A5 misaligned LW raised load-misaligned", dmem[259], 32'd4);
    chk("A5 misaligned LW mtval = faulting address", dmem[323], 32'h0000_0042);
    chk("A5 destination register unchanged", dmem[38], 32'hDEAD_B7EF);

    // A6 — odd LHU traps.
    chk("A6 odd LHU raised load-misaligned", dmem[260], 32'd4);
    chk("A6 odd LHU mtval = faulting address", dmem[324], 32'h0000_0041);
    chk("A6 odd LHU did not write its destination", dmem[39], 32'd0);
    // Control: the aligned LHU worked, so A6 is not "all LHU trap".
    chk("A6 aligned LHU returns the stored halfword", dmem[40], 32'h0000_BEEF);
    chk("A6 aligned LHU data (word at 0x40)", dmem[16], 32'h0000_BEEF);

    $display("");
    $display("[csrarch] checks: %0d, failures: %0d", checks, errors);
    if (errors == 0) begin
      $display("CPU CSR ARCH: ALL TESTS PASSED");
      $finish;
    end else begin
      $display("CPU CSR ARCH: %0d FAILURES", errors);
      $fatal(1, "CPU architectural test failed");
    end
  end

  initial begin
    #1_000_000;
    $display("CPU CSR ARCH: TIMEOUT");
    $fatal(1, "cpu architectural test timed out");
  end

endmodule
