//------------------------------------------------------------------------------
// Home-Automation-SoC — RV32IM Core (multi-cycle, machine mode)
// Stage 2 RTL (reworked)
//
// The previous core truncated every 32-bit instruction to its low halfword,
// never selected LUI/AUIPC correctly, ignored sign extension on loads, never
// took an interrupt and could not complete a load or store because it waited
// for gnt and rvalid in the same cycle.  This is a rewrite.
//
// Structure: 4-state multi-cycle machine
//   S_FETCH -> S_EXEC -> (S_MEM | S_TRAP) -> S_FETCH
//
// Memory interface contract (see req_gnt_to_axi_lite):
//   req held until gnt; gnt one cycle on accept; rvalid one cycle on
//   completion for both reads and writes (rdata valid only for reads).
//
// Supported: RV32I + M, machine-mode CSRs, synchronous traps (illegal
// instruction, ECALL, EBREAK) and asynchronous interrupts via mip/mie/mstatus.
// Not supported (documented): C extension, F/D, atomics, user mode, PMP.
//
// Formal verification properties are in reports/verification/formal_properties.sv
//------------------------------------------------------------------------------
module riscv_core #(
  parameter XLEN = 32,
  parameter RESET_PC = 32'h0000_0000
) (
  input  logic                   clk,
  input  logic                   reset_n,
  // Instruction memory interface
  output logic                   instr_req,
  output logic [XLEN-1:0]        instr_addr,
  input  logic                   instr_gnt,
  input  logic [XLEN-1:0]        instr_rdata,
  input  logic                   instr_rvalid,
  // Data memory interface
  output logic                   data_req,
  output logic                   data_we,
  output logic [XLEN-1:0]        data_addr,
  output logic [XLEN-1:0]        data_wdata,
  output logic [3:0]             data_wstrb,
  input  logic                   data_gnt,
  input  logic [XLEN-1:0]        data_rdata,
  input  logic                   data_rvalid,
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
  logic [XLEN-1:0] rf [0:31];
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

  typedef enum logic [1:0] {S_FETCH, S_EXEC, S_MEM, S_TRAP} state_e;
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

  assign alu_a = (opcode == OP_LUI) ? 32'd0 : rs1_val;
  assign alu_b = (opcode == OP_REG)  ? rs2_val :
                 (opcode == OP_LUI)  ? imm     :
                 (opcode == OP_AUIPC)? imm     : imm_i;

  wire [4:0] shamt = (opcode == OP_REG) ? rs2_val[4:0] : ir[24:20];

  // Loads and stores always use addition for the effective address,
  // regardless of funct3 (which would otherwise select SLT for LW/SW).
  wire alu_is_add = (opcode == OP_LOAD) || (opcode == OP_STORE) ||
                    (opcode == OP_LUI) || (opcode == OP_AUIPC) ||
                    (opcode == OP_IMM)  || (opcode == OP_JAL)  ||
                    (opcode == OP_JALR) || (opcode == OP_BRANCH);

  always_comb begin
    if (alu_is_add) begin
      alu_out = alu_a + alu_b;
    end else begin
      // OP_REG only: funct3 selects the ALU operation
      case (funct3)
        3'b000: alu_out = funct7[5] ? (alu_a - alu_b) : (alu_a + alu_b);
        3'b001: alu_out = alu_a << shamt;
        3'b010: alu_out = ($signed(alu_a) < $signed(alu_b)) ? 32'd1 : 32'd0;
        3'b011: alu_out = (alu_a < alu_b) ? 32'd1 : 32'd0;
        3'b100: alu_out = alu_a ^ alu_b;
        3'b101: alu_out = (funct7[5]) ? ($signed(alu_a) >>> shamt)
                                      : (alu_a >> shamt);
        3'b110: alu_out = alu_a | alu_b;
        3'b111: alu_out = alu_a & alu_b;
        default: alu_out = alu_a + alu_b;
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
  // Multiply / divide (combinational; synthesises to a mult+div unit)
  //--------------------------------------------------------------------------
  logic [XLEN-1:0] muldiv_out;
  wire [63:0] prod_ss = $signed(rs1_val) * $signed(rs2_val);
  wire [63:0] prod_su = $signed(rs1_val) * $signed({1'b0, rs2_val});
  wire [63:0] prod_uu = rs1_val * rs2_val;

  always_comb begin
    muldiv_out = 32'd0;
    if (rs2_val == 32'd0)
      muldiv_out = (funct3 == 3'b100) ? 32'hFFFF_FFFF :   // DIV  -> -1
                   (funct3 == 3'b101) ? 32'hFFFF_FFFF :   // DIVU -> max
                                       rs1_val;           // REM/REMU -> a
    else if (rs1_val == 32'h8000_0000 && rs2_val == 32'hFFFF_FFFF)
      muldiv_out = (funct3 == 3'b110) ? 32'd0 : 32'h8000_0000;
    else begin
      case (funct3)
        3'b000: muldiv_out = prod_uu[31:0];
        3'b001: muldiv_out = prod_ss[63:32];
        3'b010: muldiv_out = prod_su[63:32];
        3'b011: muldiv_out = prod_uu[63:32];
        3'b100: muldiv_out = $signed(rs1_val) / $signed(rs2_val);
        3'b101: muldiv_out = rs1_val / rs2_val;
        3'b110: muldiv_out = $signed(rs1_val) % $signed(rs2_val);
        3'b111: muldiv_out = rs1_val % rs2_val;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // Immediate legality / instruction class
  //--------------------------------------------------------------------------
  logic is_illegal;
  wire is_m_ext = (opcode == OP_REG) && (funct7 == 7'b0000001);
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

  logic [XLEN-1:0] csr_wdata;
  always_comb begin
    case (funct3)
      3'b001, 3'b101: csr_wdata = rs1_val;                    // csrrw / csrrwi
      3'b010, 3'b110: csr_wdata = csr_rdata | rs1_val;        // csrrs / csrrsi
      3'b011, 3'b111: csr_wdata = csr_rdata & ~rs1_val;       // csrrc / csrrci
      default:        csr_wdata = rs1_val;
    endcase
  end

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

  always_comb begin
    exc_take  = 1'b0;
    exc_cause = '0;
    exc_tval  = ir;
    if (state == S_EXEC) begin
      if (is_illegal)  begin exc_take = 1'b1; exc_cause = 32'd2;  end
      else if (is_ecall)  begin exc_take = 1'b1; exc_cause = 32'd11; exc_tval = 32'd0; end
      else if (is_ebreak) begin exc_take = 1'b1; exc_cause = 32'd3;  exc_tval = 32'd0; end
    end
  end

  //--------------------------------------------------------------------------
  // Branch / jump target
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
    else if (is_m_ext)                     wb_data = muldiv_out;
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
        OP_LUI, OP_AUIPC, OP_JAL, OP_JALR, OP_LOAD,
        OP_IMM, OP_REG, OP_MISC: reg_we = (rd != 5'd0);
        OP_SYSTEM: reg_we = is_csr && (rd != 5'd0);
        default: reg_we = 1'b0;
      endcase
    end
  end

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
        else if (instr_rvalid)      state_n = S_EXEC;
      end
      S_EXEC: begin
        if (exc_take)               state_n = S_TRAP;
        else if (is_mem)            state_n = S_MEM;
        else                        state_n = S_FETCH;
      end
      S_MEM:  if (data_rvalid)      state_n = S_FETCH;
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
      state     <= S_FETCH;
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
        ir        <= instr_rdata;
        minstret  <= minstret + 64'd1;
      end

      // Execute / writeback
      if (state == S_EXEC && !exc_take) begin
        if (reg_we) rf[rd] <= wb_data;

        // CSR write
        if (is_csr) begin
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
        end else if (!is_mem) begin
          // WFI is architecturally a NOP here: clock gating is entered through
          // the power-manager register block, not driven by the core.
          pc <= pc_next;
        end
      end

      // Memory completion
      if (state == S_MEM && data_rvalid) begin
        if (opcode == OP_LOAD && !exc_take) rf[rd] <= ld_data;
        pc <= pc + 32'd4;
      end

      // Trap entry
      if (state == S_TRAP) begin
        mepc                 <= pc;
        mcause               <= irq_take ? irq_cause : exc_cause;
        mtval                <= irq_take ? 32'd0 : exc_tval;
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

endmodule
