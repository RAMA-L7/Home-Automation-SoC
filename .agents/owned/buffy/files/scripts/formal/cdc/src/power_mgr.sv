//------------------------------------------------------------------------------
// Home-Automation-SoC — Power Manager
// Stage 2 RTL
//
// Controls clock gating enables for core and peripheral domains, and wake-up
// from sleep. Simple FSM: ACTIVE -> SLEEP -> WAKE -> ACTIVE.
//
// Registers (via power_mgr_regs, APB):
//   CTRL: bit0 = sleep_enable, bit1 = wake_enable
//   STATUS: bit0 = in_sleep
//------------------------------------------------------------------------------
module power_mgr (
  input  logic         clk,
  input  logic         reset_n,
  output logic         core_clk_en,
  output logic         periph_clk_en,
  output logic         wake_req,
  input  logic         wake_ack
);

  typedef enum logic [1:0] {P_ACTIVE, P_SLEEP, P_WAKE} state_e;
  state_e state, state_n;

  logic sleep_req, wake_req_reg;

  // Sleep request comes from power_mgr_regs via APB (wired here directly for now)
  assign sleep_req = 1'b0;   // driven by firmware via regs (stubbed)
  assign wake_req  = wake_req_reg;

  always_comb begin
    state_n = state;
    wake_req_reg = 1'b0;
    unique case (state)
      P_ACTIVE:  if (sleep_req) state_n = P_SLEEP;
      P_SLEEP:   if (wake_ack) begin state_n = P_WAKE; wake_req_reg = 1'b1; end
      P_WAKE:    state_n = P_ACTIVE;
      default:   state_n = P_ACTIVE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) state <= P_ACTIVE;
    else          state <= state_n;
  end

  assign core_clk_en   = (state != P_SLEEP);
  assign periph_clk_en = (state != P_SLEEP);

endmodule
