//------------------------------------------------------------------------------
// Home-Automation-SoC — Formal Verification Properties
// Stage 4 Verification
//
// SystemVerilog assertions for the SoC. These properties can be used with
// SymbiYosys or commercial formal tools.
//
// To run with SymbiYosys:
//   sby -f formal_sram.sby
//   sby -f formal_interconnect.sby
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// RISC-V Core properties
//------------------------------------------------------------------------------

// Reset: after reset deassertion, pc == RESET_PC and state == S_FETCH
// assert property (@(posedge clk) disable iff (!reset_n)
//   !reset_n |-> ##[1:2] (pc == RESET_PC && state == S_FETCH));

// State machine: exactly one state active at a time (one-hot)
// assert property (@(posedge clk) disable iff (!reset_n)
//   $onehot({state == S_FETCH, state == S_EXEC, state == S_MEM, state == S_TRAP}));

// PC alignment: pc[1:0] always zero (RV32I requires 4-byte alignment)
// assert property (@(posedge clk) disable iff (!reset_n)
//   (pc[1:0] == 2'b00));

// Fetch handshake: instr_req only asserted in S_FETCH state
// assert property (@(posedge clk) disable iff (!reset_n)
//   instr_req |-> (state == S_FETCH));

// Data request: data_req only asserted in S_EXEC state for mem ops
// assert property (@(posedge clk) disable iff (!reset_n)
//   data_req |-> (state == S_EXEC && is_mem));

// Load/store address is always rs1 + imm_s/imm_i (dedicated adder)
// assert property (@(posedge clk) disable iff (!reset_n)
//   (opcode == OP_LOAD || opcode == OP_STORE) |-> (data_addr == rs1_val + imm));

//------------------------------------------------------------------------------
// AXI4-Lite Interconnect properties
//------------------------------------------------------------------------------

// One outstanding transaction at a time: only one of AW/AR active
// assert property (@(posedge clk) disable iff (!reset_n)
//   !(m_awvalid && m_arvalid));

// State machine: exactly one state active at a time (one-hot)
// assert property (@(posedge clk) disable iff (!reset_n)
//   $onehot({state == IC_IDLE, state == IC_WR_LAUNCH, state == IC_WR_RESP,
//            state == IC_RD_LAUNCH, state == IC_RD_RESP}));

// Master write address ready only in IDLE
// assert property (@(posedge clk) disable iff (!reset_n)
//   m_awready |-> (state == IC_IDLE));

// Master write data ready only in IDLE
// assert property (@(posedge clk) disable iff (!reset_n)
//   m_wready |-> (state == IC_IDLE));

// Master read address ready only in IDLE
// assert property (@(posedge clk) disable iff (!reset_n)
//   m_arready |-> (state == IC_IDLE));

// No two slaves selected simultaneously (write address)
// assert property (@(posedge clk) disable iff (!reset_n)
//   $countones(s_awvalid) <= 1);

// No two slaves selected simultaneously (write data)
// assert property (@(posedge clk) disable iff (!reset_n)
//   $countones(s_wvalid) <= 1));

// No two slaves selected simultaneously (read address)
// assert property (@(posedge clk) disable iff (!reset_n)
//   $countones(s_arvalid) <= 1));

// Write response follows write address+data handshake
// assert property (@(posedge clk) disable iff (!reset_n)
//   ((m_awvalid && m_awready) && (m_wvalid && m_wready)) |-> ##[1:4] m_bvalid);

// Read response follows read address handshake
// assert property (@(posedge clk) disable iff (!reset_n)
//   (m_arvalid && m_arready) |-> ##[1:4] m_rvalid);

//------------------------------------------------------------------------------
// Boot ROM properties
//------------------------------------------------------------------------------

// Write handshake: awready asserts when IDLE and no read in progress
// assert property (@(posedge clk) disable iff (!reset_n)
//   awready |-> (ax_state == AX_IDLE));

// Write handshake: wready asserts when IDLE and no read in progress
// assert property (@(posedge clk) disable iff (!reset_n)
//   wready |-> (ax_state == AX_IDLE));

// Read handshake: arready asserts when IDLE and no write in progress
// assert property (@(posedge clk) disable iff (!reset_n)
//   arready |-> (ax_state == AX_IDLE));

//------------------------------------------------------------------------------
// SRAM properties
//------------------------------------------------------------------------------

// Byte strobe correctness: only enabled bytes are written
// assert property (@(posedge clk) disable iff (!reset_n)
//   (wvalid && wready) |-> (wstrb != 4'b0000));

//------------------------------------------------------------------------------
// Clock gating (power manager) properties
//------------------------------------------------------------------------------

// No glitch on gated clock: enable sampled on low phase
// assert property (@(posedge clk) disable iff (!reset_n)
//   clk_en_stable |-> $stable(clk_gated));
//------------------------------------------------------------------------------
