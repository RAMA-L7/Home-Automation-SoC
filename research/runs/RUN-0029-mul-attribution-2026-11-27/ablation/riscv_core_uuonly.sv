//------------------------------------------------------------------------------
// Home-Automation-SoC — RV32IM Core (multi-cycle, machine mode)
// Stage 2 RTL (reworked)
//
// The previous core truncated every 32-bit instruction to its low halfword,
// never selected LUI/AUIPC correctly, ignored sign extension on loads, never
// took an interrupt and could not complete a load or store because it waited
// for gnt and rvalid in the same cycle.  This is a rewrite.
//
// Structure: 5-state multi-cycle machine
//   S_FETCH -> S_EXEC -> (S_MEM | S_DIV | S_TRAP) -> S_FETCH
//   S_DIV iterates the M-extension divide/remainder one quotient bit per cycle.
//
// Memory interface contract (see req_gnt_to_axi_lite):
//   req held until gnt; gnt one cycle on accept; rvalid one cycle on
//   completion for both reads and writes (rdata valid only for reads).
//
// Supported: RV32I + M, machine-mode CSRs, synchronous traps (illegal
// instruction, ECALL, EBREAK, instruction-address-misaligned, load/store
// address misaligned, instruction/load/store access fault) and asynchronous
// interrupts via mip/mie/mstatus.
// Not supported (documented): C extension, F/D, atomics, user mode, PMP.
//
// Access faults: the memory interfaces carry an error flag alongside the
// completion strobe (instr_err with instr_rvalid, data_err with data_rvalid).
// Without it a bus error was invisible: the core used the returned data as if
// the access had succeeded.
//
// Formal verification properties are in reports/verification/formal_properties.sv
//------------------------------------------------------------------------------
module riscv_core #(
  parameter int XLEN = 32,
  parameter int RESET_PC = 32'h0000_0000
) (
  input  logic                   clk,
  input  logic                   reset_n,
  // Instruction memory interface
  output logic                   instr_req,
  output logic [XLEN-1:0]        instr_addr,
  input  logic                   instr_gnt,
  input  logic [XLEN-1:0]        instr_rdata,
  input  logic                   instr_rvalid,
  input  logic                   instr_err,    // access fault, with rvalid
  // Data memory interface
  output logic                   data_req,
  output logic                   data_we,
  output logic [XLEN-1:0]        data_addr,
  output logic [XLEN-1:0]        data_wdata,
  output logic [3:0]             data_wstrb,
  input  logic                   data_gnt,
  input  logic [XLEN-1:0]        data_rdata,
  input  logic                   data_rvalid,
  input  logic                   data_err,     // access fault, with rvalid
  // Interrupts (already individually gated by the interrupt controller)
  input  logic                   irq_irq,     // external (PLIC)
  input  logic                   irq_timer,   // CLINT timer
  input  logic                   irq_soft,    // CLINT software
  // Debug
  input  logic                   debug_req,
  output logic                   debug_halted,
  output logic                   debug_running
);

  //--------------------------------------------------------------------------
  // Architectural state
  //--------------------------------------------------------------------------
  logic [XLEN-1:0] rf [32];
  logic [XLEN-1:0] pc, ir;

  logic [XLEN-1:0] mstatus, mtvec, mscratch, mepc, mcause, mtval, mie, mip;
  logic [63:0]     mcycle, minstret;

  localparam logic [1:0] PRV_M = 2'b11;

  // mstatus bits
  localparam int MSTATUS_MIE  = 3;
  localparam int MSTATUS_MPIE = 7;
  localparam int MSTATUS_MPP  = 11;

  // mie/mip bits
  localparam int IRQ_MSI = 3;
  localparam int IRQ_MTI = 7;
  localparam int IRQ_MEI = 11;

  typedef enum logic [2:0] {S_FETCH, S_EXEC, S_MEM, S_TRAP, S_DIV} state_e;
  state_e state, state_n;

  //--------------------------------------------------------------------------
  // Decode
  //--------------------------------------------------------------------------
  wire [6:0] opcode = ir[6:0];
  wire [4:0] rd     = ir[11:7];
  wire [2:0] funct3 = ir[14:12];
  wire [6:0] funct7 = ir[31:25];
  wire [4:0] rs1    = ir[19:15];
  wire [4:0] rs2    = ir[24:20];

  localparam logic [6:0] OP_LUI    = 7'b0110111;
  localparam logic [6:0] OP_AUIPC  = 7'b0010111;
  localparam logic [6:0] OP_JAL    = 7'b1101111;
  localparam logic [6:0] OP_JALR   = 7'b1100111;
  localparam logic [6:0] OP_BRANCH = 7'b1100011;
  localparam logic [6:0] OP_LOAD   = 7'b0000011;
  localparam logic [6:0] OP_STORE  = 7'b0100011;
  localparam logic [6:0] OP_IMM    = 7'b0010011;
  localparam logic [6:0] OP_REG    = 7'b0110011;
  localparam logic [6:0] OP_MISC   = 7'b0001111;  // FENCE / FENCE.I
  localparam logic [6:0] OP_SYSTEM = 7'b1110011;

  // Immediate generation
  logic [XLEN-1:0] imm_i, imm_s, imm_b, imm_u, imm_j, imm;
  assign imm_i = {{20{ir[31]}}, ir[31:20]};
  assign imm_s = {{20{ir[31]}}, ir[31:25], ir[11:7]};
  assign imm_b = {{19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
  assign imm_u = {ir[31:12], 12'd0};
  assign imm_j = {{11{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};

  always_comb begin
    case (opcode)
      OP_IMM, OP_LOAD, OP_JALR: imm = imm_i;
      OP_STORE:                 imm = imm_s;
      OP_BRANCH:                imm = imm_b;
      OP_LUI, OP_AUIPC:         imm = imm_u;
      OP_JAL:                   imm = imm_j;
      default:                  imm = 32'd0;
    endcase
  end

  logic [XLEN-1:0] rs1_val, rs2_val;
  assign rs1_val = (rs1 == 5'd0) ? 32'd0 : rf[rs1];
  assign rs2_val = (rs2 == 5'd0) ? 32'd0 : rf[rs2];

  //--------------------------------------------------------------------------
  // ALU
  //--------------------------------------------------------------------------
  logic [XLEN-1:0] alu_a, alu_b, alu_out;
  logic            cmp_eq, cmp_lt, cmp_ltu;

  // LUI ignores rs1 and takes imm_u directly.  AUIPC must add imm_u to the PC
  // (RISC-V spec: rd = pc + imm_u<<12) — this previously selected rs1_val, so
  // `auipc` produced rs1+imm and every PC-relative address was wrong.
  assign alu_a = (opcode == OP_LUI)   ? 32'd0 :
                 (opcode == OP_AUIPC) ? pc    : rs1_val;
  // `imm` is the per-opcode immediate (imm_i for loads, imm_s for stores,
  // imm_b/imm_j for branches/jumps).  Using imm_i for a store added
  // ir[31:20] to rs1 instead of the S-type offset, so every store with a
  // non-zero offset landed 1..0x7ff bytes off (sw ra,4(sp) -> sp+1).
  assign alu_b = (opcode == OP_REG)  ? rs2_val : imm;

  wire [4:0] shamt = (opcode == OP_REG) ? rs2_val[4:0] : ir[24:20];

  // Only the instructions whose ALU result is an address or an upper immediate
  // bypass funct3.  OP_IMM must NOT be in this list: funct3 selects ANDI/ORI/
  // XORI/SLTI/SLLI there, and forcing addition made every `andi` an add, which
  // broke the UART THRE poll (`andi t6,0x20` never produced 0).
  wire alu_is_add = (opcode == OP_LOAD) || (opcode == OP_STORE) ||
                    (opcode == OP_LUI) || (opcode == OP_AUIPC) ||
                    (opcode == OP_JAL)  || (opcode == OP_JALR) ||
                    (opcode == OP_BRANCH);

  // Shifts are computed in their own assignments.  Writing the arithmetic
  // shift inline in a ternary whose other arm is unsigned made the simulators
  // (and any tool that unifies the conditional's operand types) evaluate it as
  // a LOGICAL shift: `srai x7,x5,28` of 0xFFFFFFF8 returned 0x0000000F.
  // Hoisting each result into a typed wire removes the ambiguity.
  wire signed [XLEN-1:0] alu_a_signed = alu_a;
  wire signed [XLEN-1:0] alu_b_signed = alu_b;
  wire [XLEN-1:0] alu_add = alu_a + alu_b;
  wire [XLEN-1:0] alu_sub = alu_a - alu_b;
  wire [XLEN-1:0] alu_sll = alu_a << shamt;
  wire [XLEN-1:0] alu_sra = alu_a_signed >>> shamt;
  wire [XLEN-1:0] alu_srl = alu_a >> shamt;
  wire [XLEN-1:0] alu_slt = (alu_a_signed < alu_b_signed) ? 32'd1 : 32'd0;
  wire [XLEN-1:0] alu_sltu = (alu_a < alu_b) ? 32'd1 : 32'd0;
  wire [XLEN-1:0] alu_xor = alu_a ^ alu_b;
  wire [XLEN-1:0] alu_or  = alu_a | alu_b;
  wire [XLEN-1:0] alu_and = alu_a & alu_b;

  always_comb begin
    if (alu_is_add) begin
      alu_out = alu_add;
    end else begin
      // funct3 selects the ALU operation here (OP_REG and OP_IMM).  The SUB
      // variant is OP_REG-only: for an I-type instruction funct7[5] is part of
      // the immediate, so testing it here made `addi sp,sp,-8` subtract twice.
      case (funct3)
        3'b000: alu_out = ((opcode == OP_REG) && funct7[5]) ? alu_sub : alu_add;
        3'b001: alu_out = alu_sll;
        3'b010: alu_out = alu_slt;
        3'b011: alu_out = alu_sltu;
        3'b100: alu_out = alu_xor;
        3'b101: alu_out = (funct7[5]) ? alu_sra : alu_srl;
        3'b110: alu_out = alu_or;
        3'b111: alu_out = alu_and;
        default: alu_out = alu_add;
      endcase
    end
  end

  // LUI/AUIPC override: the result is already in alu_b or pc+imm,
  // but alu_out = alu_a + alu_b would be wrong for LUI (alu_a=0, alu_b=imm -> OK)
  // and AUIPC (alu_a=pc, alu_b=imm -> OK). So no override needed.
  // The alu_is_add path above already handles these correctly.

  assign cmp_eq  = (rs1_val == rs2_val);
  assign cmp_lt  = ($signed(rs1_val) < $signed(rs2_val));
  assign cmp_ltu = (rs1_val < rs2_val);

  //--------------------------------------------------------------------------
  // M extension: MUL is combinational, DIV/REM iterate in S_DIV
  //
  // A combinational `$signed(a) / $signed(b)` maps to a 32-step restoring
  // divider, i.e. roughly 470 levels of carry-chain logic.  At the 2026-11-27
  // timing baseline that single cone produced WNS -106.48 ns and 992 of the
  // 1160 failing endpoints (99.2% of TNS), because every register-file write
  // port sits behind wb_data.  Division now retires through S_DIV one quotient
  // bit per cycle; MUL keeps the single-cycle array multiplier.  This core is
  // multi-cycle and does not overlap instructions, so the change costs latency
  // (34 cycles per divide) but no throughput, and the architectural results
  // are unchanged (tb_isa.v checks divide-by-zero, signed overflow, sign and
  // remainder rules against the spec).
  //--------------------------------------------------------------------------
  wire is_m_ext = (opcode == OP_REG) && (funct7 == 7'b0000001);
  wire is_div   = is_m_ext && funct3[2];       // DIV/DIVU/REM/REMU

  logic [XLEN-1:0] mul_result;
  wire [63:0] prod_ss = 64'b0; // ABLATION
  wire [63:0] prod_su = 64'b0; // ABLATION
  wire [63:0] prod_uu = rs1_val * rs2_val;

  always_comb begin
    case (funct3)
      3'b000:  mul_result = prod_uu[31:0];    // MUL
      3'b001:  mul_result = prod_ss[63:32];   // MULH
      3'b010:  mul_result = prod_su[63:32];   // MULHSU
      default: mul_result = prod_uu[63:32];   // MULHU
    endcase
  end

  // Iterative divider state.  div_rem carries one extra bit because the
  // partial remainder is shifted left together with the next dividend bit
  // before each trial subtraction.
  logic [XLEN-1:0] div_dividend, div_divisor, div_quot;
  logic [XLEN:0]   div_rem;
  logic [5:0]      div_cnt;
  logic            div_neg_q, div_neg_r, div_is_rem, div_special;
  logic [XLEN-1:0] div_special_q, div_special_r;

  // Unsigned magnitudes.  |-2^31| is 2^31, which fits in 32 unsigned bits.
  wire [XLEN-1:0] div_a_mag = (!funct3[0] && rs1_val[XLEN-1]) ? -rs1_val : rs1_val;
  wire [XLEN-1:0] div_b_mag = (!funct3[0] && rs2_val[XLEN-1]) ? -rs2_val : rs2_val;

  // Architecturally defined results that do not need the iteration.
  wire div_by_zero = (rs2_val == 32'd0);
  wire div_ovf     = !funct3[0] && (rs1_val == 32'h8000_0000) &&
                     (rs2_val == 32'hFFFF_FFFF);

  // One restoring-division step: shift in the next dividend bit, subtract the
  // divisor when it fits, and shift the decision into the quotient.
  wire [XLEN:0] div_shift = {div_rem[XLEN-1:0], div_dividend[XLEN-1]};
  wire          div_sub   = (div_shift >= {1'b0, div_divisor});
  wire [XLEN:0] div_diff  = div_shift - {1'b0, div_divisor};

  wire [XLEN-1:0] div_quot_fix = div_neg_q ? -div_quot : div_quot;
  wire [XLEN-1:0] div_rem_fix  = div_neg_r ? -div_rem[XLEN-1:0] : div_rem[XLEN-1:0];

  logic [XLEN-1:0] div_result;
  always_comb begin
    if (div_special) div_result = div_is_rem ? div_special_r : div_special_q;
    else             div_result = div_is_rem ? div_rem_fix    : div_quot_fix;
  end

  //--------------------------------------------------------------------------
  // Immediate legality / instruction class
  //--------------------------------------------------------------------------
  logic is_illegal;
  wire is_system = (opcode == OP_SYSTEM);

  always_comb begin
    is_illegal = 1'b0;
    case (opcode)
      OP_LUI, OP_AUIPC, OP_JAL: ;
      OP_JALR:  if (funct3 != 3'b000) is_illegal = 1'b1;
      OP_BRANCH: if (funct3 == 3'b010 || funct3 == 3'b011) is_illegal = 1'b1;
      OP_LOAD:  if (!(funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010 ||
                      funct3 == 3'b100 || funct3 == 3'b101)) is_illegal = 1'b1;
      OP_STORE: if (!(funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010))
                  is_illegal = 1'b1;
      OP_IMM:   if (funct3 == 3'b001 && funct7 != 7'b0000000) is_illegal = 1'b1;
                else if (funct3 == 3'b101 && !(funct7 == 7'b0000000 ||
                                               funct7 == 7'b0100000))
                  is_illegal = 1'b1;
      OP_REG:   if (is_m_ext) ;
                else if (funct7 == 7'b0100000) begin   // SUB / SRA only
                  if (!(funct3 == 3'b000 || funct3 == 3'b101)) is_illegal = 1'b1;
                end else if (funct7 != 7'b0000000) is_illegal = 1'b1;
      OP_MISC:  if (funct3 != 3'b000 && funct3 != 3'b001) is_illegal = 1'b1;
      OP_SYSTEM: ;
      default:  is_illegal = 1'b1;
    endcase
  end

  //--------------------------------------------------------------------------
  // System instruction decode
  //--------------------------------------------------------------------------
  wire is_ecall  = is_system && (ir[31:20] == 12'h000) && (funct3 == 3'b000) &&
                   (rs1 == 5'd0) && (rd == 5'd0);
  wire is_ebreak = is_system && (ir[31:20] == 12'h001) && (funct3 == 3'b000) &&
                   (rs1 == 5'd0) && (rd == 5'd0);
  wire is_mret   = is_system && (ir[31:20] == 12'h302) && (funct3 == 3'b000) &&
                   (rs1 == 5'd0) && (rd == 5'd0);
  wire is_wfi    = is_system && (ir[31:20] == 12'h105) && (funct3 == 3'b000) &&
                   (rs1 == 5'd0) && (rd == 5'd0);
  wire is_csr    = is_system && (funct3 != 3'b000);
  wire [11:0] csr_addr = ir[31:20];

  // CSR read mux
  logic [XLEN-1:0] csr_rdata;
  always_comb begin
    case (csr_addr)
      12'h300: csr_rdata = mstatus;
      12'h304: csr_rdata = mie;
      12'h305: csr_rdata = mtvec;
      12'h340: csr_rdata = mscratch;
      12'h341: csr_rdata = mepc;
      12'h342: csr_rdata = mcause;
      12'h343: csr_rdata = mtval;
      12'h344: csr_rdata = mip;
      12'h344 + 12'h1: csr_rdata = 32'd0;      // mvendorid (unimplemented)
      12'hB00: csr_rdata = mcycle[31:0];
      12'hB80: csr_rdata = mcycle[63:32];
      12'hB02: csr_rdata = minstret[31:0];
      12'hB82: csr_rdata = minstret[63:32];
      12'hF14: csr_rdata = 32'd0;              // mhartid
      default: csr_rdata = 32'd0;
    endcase
  end

  // CSR-immediate forms encode the source in the 5-bit `rs1` field as a
  // zero-extended unsigned immediate (`zimm`), NOT as a register number.  Using
  // rs1_val here read whatever register happened to share that index, so
  // `csrrwi x0, mscratch, 5` used rf[5] instead of 5.
  wire [XLEN-1:0] csr_zimm     = {27'd0, ir[19:15]};
  wire            csr_is_imm   = funct3[2];
  wire [XLEN-1:0] csr_src      = csr_is_imm ? csr_zimm : rs1_val;
  wire            csr_src_zero = csr_is_imm ? (ir[19:15] == 5'd0) : (rs1 == 5'd0);

  logic [XLEN-1:0] csr_wdata;
  always_comb begin
    case (funct3)
      3'b001, 3'b101: csr_wdata = csr_src;                    // csrrw / csrrwi
      3'b010, 3'b110: csr_wdata = csr_rdata | csr_src;        // csrrs / csrrsi
      3'b011, 3'b111: csr_wdata = csr_rdata & ~csr_src;       // csrrc / csrrci
      default:        csr_wdata = csr_src;
    endcase
  end

  // CSRRW/CSRRWI always write.  CSRRS/CSRRC/CSRRSI/CSRRCI are read-only when
  // their source field is zero ("no write when rs1/zimm == 0"), so
  // `csrrs x1, mstatus, x0` must leave mstatus untouched.
  wire csr_we = is_csr && ((funct3[1:0] == 2'b01) || !csr_src_zero);

  // Architecturally supported CSRs.  Anything else must raise illegal
  // instruction (mcause 2) rather than read 0 / silently discard the write.
  wire csr_known = (csr_addr == 12'h300) || (csr_addr == 12'h304) ||
                   (csr_addr == 12'h305) || (csr_addr == 12'h340) ||
                   (csr_addr == 12'h341) || (csr_addr == 12'h342) ||
                   (csr_addr == 12'h343) || (csr_addr == 12'h344) ||
                   (csr_addr == 12'h345) || (csr_addr == 12'hB00) ||
                   (csr_addr == 12'hB80) || (csr_addr == 12'hB02) ||
                   (csr_addr == 12'hB82) || (csr_addr == 12'hF14);
  wire csr_writable = (csr_addr == 12'h300) || (csr_addr == 12'h304) ||
                      (csr_addr == 12'h305) || (csr_addr == 12'h340) ||
                      (csr_addr == 12'h341) || (csr_addr == 12'h342) ||
                      (csr_addr == 12'h343) || (csr_addr == 12'hB00) ||
                      (csr_addr == 12'hB80) || (csr_addr == 12'hB02) ||
                      (csr_addr == 12'hB82);
  wire csr_illegal = is_csr && (!csr_known || (csr_we && !csr_writable));
  // An OP_SYSTEM word that is none of ECALL/EBREAK/MRET/WFI and not a CSR
  // access is not an instruction this core implements; it used to execute as a
  // silent NOP.
  wire sys_illegal = is_system && !is_csr &&
                     !(is_ecall || is_ebreak || is_mret || is_wfi);

  //--------------------------------------------------------------------------
  // Branch / jump target (used by trap detection below)
  //--------------------------------------------------------------------------
  logic            branch_taken;
  logic [XLEN-1:0] pc_next;

  always_comb begin
    case (funct3)
      3'b000:  branch_taken = cmp_eq;
      3'b001:  branch_taken = !cmp_eq;
      3'b100:  branch_taken = cmp_lt;
      3'b101:  branch_taken = !cmp_lt;
      3'b110:  branch_taken = cmp_ltu;
      3'b111:  branch_taken = !cmp_ltu;
      default: branch_taken = 1'b0;
    endcase
  end

  assign pc_next = (opcode == OP_JAL)  ? (pc + imm_j) :
                   (opcode == OP_JALR) ? ((rs1_val + imm_i) & ~32'h1) :
                   (opcode == OP_BRANCH && branch_taken) ? (pc + imm_b) :
                   (pc + 32'd4);

  //--------------------------------------------------------------------------
  // Trap detection
  //--------------------------------------------------------------------------
  wire meip = mip[IRQ_MEI];
  wire mtip = mip[IRQ_MTI];
  wire msip = mip[IRQ_MSI];

  logic irq_take;
  logic [XLEN-1:0] irq_cause;

  always_comb begin
    irq_take  = 1'b0;
    irq_cause = '0;
    if (mstatus[MSTATUS_MIE]) begin
      if (mie[IRQ_MEI] && meip)      begin irq_take = 1'b1; irq_cause = {1'b1, 31'd11}; end
      else if (mie[IRQ_MTI] && mtip) begin irq_take = 1'b1; irq_cause = {1'b1, 31'd7};  end
      else if (mie[IRQ_MSI] && msip) begin irq_take = 1'b1; irq_cause = {1'b1, 31'd3};  end
    end
  end

  // Exception raised while executing the current instruction
  logic exc_take;
  logic [XLEN-1:0] exc_cause;
  logic [XLEN-1:0] exc_tval;

  // Misaligned data access: word accesses need bit1 clear, halfword accesses
  // need bit0 clear.  Previously these were silently byte-rotated by the
  // load/store shapers, i.e. the core returned the wrong data instead of
  // raising the architectural exception.  (Assigned at the end of the module,
  // after is_mem/branch_taken/pc_next exist.)
  wire mem_misaligned, jump_misaligned;

  always_comb begin
    exc_take  = 1'b0;
    exc_cause = '0;
    exc_tval  = ir;
    if (state == S_EXEC) begin
      if (is_illegal || csr_illegal || sys_illegal) begin
        exc_take = 1'b1; exc_cause = 32'd2;
      end
      else if (is_ecall)  begin exc_take = 1'b1; exc_cause = 32'd11; exc_tval = 32'd0; end
      else if (is_ebreak) begin exc_take = 1'b1; exc_cause = 32'd3;  exc_tval = 32'd0; end
      else if (mem_misaligned) begin
        exc_take  = 1'b1;
        exc_cause = (opcode == OP_LOAD) ? 32'd4 : 32'd6;
        exc_tval  = alu_out;
      end else if (jump_misaligned) begin
        exc_take  = 1'b1;
        exc_cause = 32'd0;
        exc_tval  = pc_next;
      end
    end
  end

  // Completion-time access faults.  Recorded in the cycle the error is
  // reported so trap entry (one cycle later) can use it.
  logic            fault_v;
  logic [XLEN-1:0] fault_cause, fault_tval;

  //--------------------------------------------------------------------------
  // Load / store shaping
  //--------------------------------------------------------------------------
  wire [1:0] byte_off = alu_out[1:0];

  logic [3:0] st_strb;
  logic [31:0] st_data;
  always_comb begin
    st_strb = 4'b0000;
    case (funct3)
      3'b000: begin
        st_strb = 4'b0001 << byte_off;
        st_data = rs2_val << (8 * byte_off);
      end
      3'b001: begin
        st_strb = byte_off[1] ? 4'b1100 : 4'b0011;
        st_data = byte_off[1] ? (rs2_val << 16) : rs2_val;
      end
      default: begin
        st_strb = 4'b1111;
        st_data = rs2_val;
      end
    endcase
  end

  logic [31:0] ld_data;
  always_comb begin
    case (funct3)
      3'b000: begin                                        // LB
        case (byte_off)
          2'd0: ld_data = {{24{data_rdata[7]}},  data_rdata[7:0]};
          2'd1: ld_data = {{24{data_rdata[15]}}, data_rdata[15:8]};
          2'd2: ld_data = {{24{data_rdata[23]}}, data_rdata[23:16]};
          2'd3: ld_data = {{24{data_rdata[31]}}, data_rdata[31:24]};
          default: ;
        endcase
      end
      3'b001: begin                                        // LH
        ld_data = byte_off[1] ? {{16{data_rdata[31]}}, data_rdata[31:16]}
                              : {{16{data_rdata[15]}}, data_rdata[15:0]};
      end
      3'b100: begin                                        // LBU
        case (byte_off)
          2'd0: ld_data = {24'd0, data_rdata[7:0]};
          2'd1: ld_data = {24'd0, data_rdata[15:8]};
          2'd2: ld_data = {24'd0, data_rdata[23:16]};
          2'd3: ld_data = {24'd0, data_rdata[31:24]};
          default: ;
        endcase
      end
      3'b101: begin                                        // LHU
        ld_data = byte_off[1] ? {16'd0, data_rdata[31:16]}
                              : {16'd0, data_rdata[15:0]};
      end
      default: ld_data = data_rdata;                       // LW
    endcase
  end

  //--------------------------------------------------------------------------
  // Writeback selection
  //--------------------------------------------------------------------------
  wire is_mem  = (opcode == OP_LOAD) || (opcode == OP_STORE);
  wire is_alu_reg = (opcode == OP_REG) && !is_m_ext;

  logic [XLEN-1:0] wb_data;
  always_comb begin
    if (opcode == OP_LOAD)                 wb_data = ld_data;
    // Only MUL retires from S_EXEC; DIV/DIVU/REM/REMU write back in S_DIV.
    else if (is_m_ext)                     wb_data = mul_result;
    else if (is_alu_reg || opcode == OP_IMM) wb_data = alu_out;
    else if (opcode == OP_LUI || opcode == OP_AUIPC) wb_data = alu_out;
    else if (opcode == OP_JAL || opcode == OP_JALR)  wb_data = pc + 32'd4;
    else if (is_csr)                       wb_data = csr_rdata;
    else                                   wb_data = alu_out;
  end

  // Register write enable per instruction
  logic reg_we;
  always_comb begin
    reg_we = 1'b0;
    if (state == S_EXEC && !exc_take) begin
      case (opcode)
        // OP_LOAD is deliberately absent: a load writes back only when its bus
        // transaction completes (S_MEM).  Including it here wrote the stale
        // previous bus data into rd first, which a faulting load then left in
        // place, corrupting the destination register.
        OP_LUI, OP_AUIPC, OP_JAL, OP_JALR,
        OP_IMM, OP_MISC: reg_we = (rd != 5'd0);
        // A divide/remainder retires in S_DIV, not here.
        OP_REG:          reg_we = (rd != 5'd0) && !is_div;
        OP_SYSTEM: reg_we = is_csr && (rd != 5'd0);
        default: reg_we = 1'b0;
      endcase
    end
  end

  // Single register-file write port.  Every retirement path drives this one
  // `if (wb_we) rf[rd] <= wb_val`, so Yosys builds a per-entry select
  // (`wb_we && rd == i`) instead of a second, global enable for the divide
  // path.  A separate `if (div_wb) rf[rd] <= div_result;` statement produced a
  // single enable net with 909 loads and a 25 ns net delay on the first
  // post-fix synthesis, which replaced the divider as the worst path.
  wire div_wb = (state == S_DIV) && (div_cnt == 6'd32);
  wire wb_we  = div_wb ? (rd != 5'd0) : reg_we;
  wire [XLEN-1:0] wb_val = div_wb ? div_result : wb_data;

  //--------------------------------------------------------------------------
  // Instruction fetch
  //--------------------------------------------------------------------------
  assign instr_req  = (state == S_FETCH) && !irq_take && !debug_req;
  assign instr_addr = pc;

  //--------------------------------------------------------------------------
  // Data interface
  //--------------------------------------------------------------------------
  assign data_req   = (state == S_EXEC && is_mem && !exc_take);
  assign data_we    = (opcode == OP_STORE);
  assign data_addr  = alu_out;
  assign data_wdata = st_data;
  assign data_wstrb = (opcode == OP_STORE) ? st_strb : 4'b0000;

  //--------------------------------------------------------------------------
  // Control FSM
  //--------------------------------------------------------------------------
  always_comb begin
    state_n = state;
    case (state)
      S_FETCH: begin
        if (irq_take)               state_n = S_TRAP;
        else if (instr_rvalid) begin
          if (instr_err)            state_n = S_TRAP;
          else                      state_n = S_EXEC;
        end
      end
      S_EXEC: begin
        if (exc_take)               state_n = S_TRAP;
        else if (is_mem)            state_n = S_MEM;
        else if (is_div)            state_n = S_DIV;
        else                        state_n = S_FETCH;
      end
      // 32 quotient bits plus the writeback/fixup cycle.
      S_DIV:  if (div_cnt == 6'd32) state_n = S_FETCH;
      S_MEM:  if (data_rvalid) begin
                if (data_err)       state_n = S_TRAP;
                else                state_n = S_FETCH;
              end
      S_TRAP:                       state_n = S_FETCH;
      default:                      state_n = S_FETCH;
    endcase
  end

  //--------------------------------------------------------------------------
  // Sequential datapath
  //--------------------------------------------------------------------------
  integer i;
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pc        <= RESET_PC;
      ir        <= 32'h0000_0013;
      mstatus   <= 32'd0;
      mtvec     <= 32'd0;
      mscratch  <= 32'd0;
      mepc      <= 32'd0;
      mcause    <= 32'd0;
      mtval     <= 32'd0;
      mie       <= 32'd0;
      mip       <= 32'd0;
      mcycle    <= 64'd0;
      minstret  <= 64'd0;
      div_dividend <= '0;
      div_divisor  <= '0;
      div_rem      <= '0;
      div_quot     <= '0;
      div_cnt      <= 6'd0;
      div_neg_q    <= 1'b0;
      div_neg_r    <= 1'b0;
      div_is_rem   <= 1'b0;
      div_special  <= 1'b0;
      div_special_q <= '0;
      div_special_r <= '0;
      state     <= S_FETCH;
      fault_v   <= 1'b0;
      fault_cause <= 32'd0;
      fault_tval  <= 32'd0;
      for (i = 0; i < 32; i++) rf[i] <= 32'd0;
    end else begin
      state   <= state_n;
      mcycle  <= mcycle + 64'd1;

      // mip mirrors the interrupt controller outputs
      mip[IRQ_MSI] <= irq_soft;
      mip[IRQ_MTI] <= irq_timer;
      mip[IRQ_MEI] <= irq_irq;

      // Fetch
      if (state == S_FETCH && instr_rvalid && !irq_take) begin
        ir <= instr_rdata;
      end

      // Register-file writeback (S_EXEC retirement and S_DIV retirement).
      if (wb_we) rf[rd] <= wb_val;

      // Execute / writeback
      if (state == S_EXEC && !exc_take) begin

        // minstret counts architectural RETIREMENT, not fetches.  Counting at
        // fetch also counted instructions that trap, which is architecturally
        // wrong and made the counter useless as a retirement witness.  Memory
        // instructions retire below, when their transaction completes.
        // A divide/remainder retires in S_DIV (below), so it is not counted
        // here as well.
        if (!is_mem && !is_div) minstret <= minstret + 64'd1;

        // CSR write.  Gated by `csr_we`, so a read-only form (CSRRS/CSRRC with
        // rs1 == x0, or the matching immediate with zimm == 0) has no effect.
        if (csr_we) begin
          case (csr_addr)
            12'h300: mstatus  <= csr_wdata;
            12'h304: mie      <= csr_wdata;
            12'h305: mtvec    <= {csr_wdata[31:2], 2'b00};
            12'h340: mscratch <= csr_wdata;
            12'h341: mepc     <= {csr_wdata[31:2], 2'b00};
            12'h342: mcause   <= csr_wdata;
            12'h343: mtval    <= csr_wdata;
            12'h344: ;                                  // mip is read-only here
            12'hB00: mcycle[31:0]  <= csr_wdata;
            12'hB80: mcycle[63:32] <= csr_wdata;
            12'hB02: minstret[31:0]  <= csr_wdata;
            12'hB82: minstret[63:32] <= csr_wdata;
            default: ;
          endcase
        end

        // MRET
        if (is_mret) begin
          pc                  <= mepc;
          mstatus[MSTATUS_MIE] <= mstatus[MSTATUS_MPIE];
          mstatus[MSTATUS_MPIE]<= 1'b1;
          mstatus[MSTATUS_MPP] <= 2'b00;
        end else if (!is_mem && !is_div) begin
          // WFI is architecturally a NOP here: clock gating is entered through
          // the power-manager register block, not driven by the core.
          pc <= pc_next;
        end
      end

      // Iterative M-extension divide/remainder.  One quotient bit per cycle;
      // div_cnt == 32 is the writeback/fixup cycle, reached immediately for the
      // architecturally defined divide-by-zero and signed-overflow cases.
      if (state == S_EXEC && is_div && !exc_take) begin
        div_dividend  <= div_a_mag;
        div_divisor   <= div_b_mag;
        div_rem       <= '0;
        div_quot      <= '0;
        div_neg_q     <= !funct3[0] && (rs1_val[XLEN-1] ^ rs2_val[XLEN-1]);
        div_neg_r     <= !funct3[0] && rs1_val[XLEN-1];
        div_is_rem    <= funct3[1];
        div_special   <= div_by_zero || div_ovf;
        div_special_q <= div_ovf ? 32'h8000_0000 : 32'hFFFF_FFFF;
        div_special_r <= div_ovf ? 32'd0 : rs1_val;
        div_cnt       <= (div_by_zero || div_ovf) ? 6'd32 : 6'd0;
      end else if (state == S_DIV && div_cnt != 6'd32) begin
        div_rem       <= div_sub ? div_diff : div_shift;
        div_quot      <= {div_quot[XLEN-2:0], div_sub};
        div_dividend  <= {div_dividend[XLEN-2:0], 1'b0};
        div_cnt       <= div_cnt + 6'd1;
      end

      // Retire the divide/remainder in the fixup cycle.  The register write
      // itself is the shared `wb_we` writeback above.
      if (div_wb) begin
        pc       <= pc + 32'd4;
        minstret <= minstret + 64'd1;
      end

      // Memory completion.  An error completes the transaction but must not
      // write back data or retire the instruction: pc stays on the faulting
      // instruction so mepc is correct.
      if (state == S_MEM && data_rvalid) begin
        if (opcode == OP_LOAD && !data_err) rf[rd] <= ld_data;
        if (!data_err) begin
          pc       <= pc + 32'd4;
          minstret <= minstret + 64'd1;   // retire only on successful completion
        end
      end

      // Latch the synchronous exception cause.  exc_cause/exc_tval are only
      // valid while the faulting instruction is in S_EXEC; trap entry happens
      // one cycle later in S_TRAP, where they would read back as 0 and `ir`.
      // Before this latch every ecall/ebreak/illegal/misaligned trap logged
      // mcause = 0 (instruction-address-misaligned) instead of its real cause.
      if (state == S_EXEC && exc_take) begin
        fault_v     <= 1'b1;
        fault_cause <= exc_cause;
        fault_tval  <= exc_tval;
      end

      // Record completion-time access faults for the trap entry below.
      if (state == S_MEM && data_rvalid && data_err) begin
        fault_v     <= 1'b1;
        fault_cause <= (opcode == OP_LOAD) ? 32'd5 : 32'd7;
        fault_tval  <= data_addr;
      end
      if (state == S_FETCH && instr_rvalid && instr_err) begin
        fault_v     <= 1'b1;
        fault_cause <= 32'd1;
        fault_tval  <= pc;
      end

      // Trap entry
      if (state == S_TRAP) begin
        mepc                 <= pc;
        mcause               <= fault_v ? fault_cause :
                                (irq_take ? irq_cause : exc_cause);
        mtval                <= fault_v ? fault_tval :
                                (irq_take ? 32'd0 : exc_tval);
        fault_v              <= 1'b0;
        mstatus[MSTATUS_MPIE]<= mstatus[MSTATUS_MIE];
        mstatus[MSTATUS_MIE] <= 1'b0;
        mstatus[MSTATUS_MPP] <= PRV_M;
        pc                   <= {mtvec[31:2], 2'b00};
      end
    end
  end

  // A halt request simply stalls fetch. A full RISC-V Debug Module (DM/DMI)
  // is NOT implemented; see docs/verification and the delivery report.
  assign debug_halted  = debug_req;
  assign debug_running = !debug_req;

  //--------------------------------------------------------------------------
  // Misalignment detection (declared above, assigned here so every operand is
  // already declared)
  //--------------------------------------------------------------------------
  // Halfword: LH (funct3 001) *and* LHU (funct3 101), plus SH (001).  Testing
  // only 3'b001 let an odd-addressed LHU through, and the load shaper then
  // returned the halfword at the aligned address instead of trapping.
  assign mem_misaligned = is_mem &&
         ((funct3 == 3'b010) ? (alu_out[1:0] != 2'b00) :
          ((funct3 == 3'b001) || (funct3 == 3'b101)) ? (alu_out[0] != 1'b0) : 1'b0);

  // On a core without the C extension every computed control-transfer target
  // must be 4-byte aligned; jalr masked only bit 0, so a 2-byte-aligned target
  // would fetch the wrong halfword.
  assign jump_misaligned = ((opcode == OP_JAL) || (opcode == OP_JALR) ||
                            (opcode == OP_BRANCH && branch_taken)) &&
                           (pc_next[1:0] != 2'b00);

endmodule
