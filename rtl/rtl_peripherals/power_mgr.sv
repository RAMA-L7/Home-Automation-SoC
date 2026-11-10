//------------------------------------------------------------------------------
// Home-Automation-SoC — Power Manager
// Stage 2 RTL (reworked)
//
// ACTIVE -> SLEEP (on software sleep request) -> WAKE (on wake_ack) -> ACTIVE.
// The manager itself runs on the ungated base clock, so it can turn the gated
// domains back on.  Wake sources in this implementation are the external
// wake_ack handshake only; peripheral wake (GPIO/UART activity) requires an
// always-on detector and is NOT implemented (documented gap).
//------------------------------------------------------------------------------
module power_mgr (
  input  logic         clk,
  input  logic         reset_n,
  input  logic         sleep_req,
  output logic         core_clk_en,
  output logic         periph_clk_en,
  output logic         wake_req,
  input  logic         wake_ack
);

  typedef enum logic [1:0] {P_ACTIVE, P_SLEEP, P_WAKE} state_e;
  state_e state, state_n;

  always_comb begin
    state_n = state;
    case (state)
      P_ACTIVE: if (sleep_req)  state_n = P_SLEEP;
      P_SLEEP:  if (wake_ack)   state_n = P_WAKE;
      P_WAKE:                   state_n = P_ACTIVE;
      default:                  state_n = P_ACTIVE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) state <= P_ACTIVE;
    else          state <= state_n;
  end

  assign core_clk_en   = (state == P_ACTIVE) || (state == P_WAKE);
  assign periph_clk_en = (state == P_ACTIVE) || (state == P_WAKE);
  assign wake_req      = (state == P_SLEEP);

endmodule
