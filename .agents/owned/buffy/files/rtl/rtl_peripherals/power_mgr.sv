//------------------------------------------------------------------------------
// Home-Automation-SoC — Power Manager
// Stage 2 RTL (reworked)
//
// ACTIVE -> SLEEP (on software sleep request) -> WAKE (on wake_ack) -> ACTIVE.
// The manager runs on the ungated base clock, so it can turn the gated domains
// back on.  Wake sources in this implementation are the external wake_ack
// handshake only; peripheral wake (GPIO/UART activity) requires an always-on
// detector and is NOT implemented (documented gap).
//
// Review fixes:
//   - wake_ack is asynchronous: it is now synchronized (2 FF) before use.
//   - wake beats sleep entry: if a wake is already pending, a simultaneous
//     sleep request does not put the SoC to sleep.
//   - a wake clears the sticky software sleep request (`wake_event`), otherwise
//     a still-set request would re-enter sleep immediately after P_WAKE.
//------------------------------------------------------------------------------
module power_mgr (
  input  logic         clk,
  input  logic         reset_n,
  input  logic         sleep_req,
  output logic         core_clk_en,
  output logic         periph_clk_en,
  output logic         wake_req,
  input  logic         wake_ack,
  output logic         wake_event
);

  typedef enum logic [1:0] {P_ACTIVE, P_SLEEP, P_WAKE} state_e;
  state_e state, state_n;

  // Asynchronous wake input -> clk domain.
  logic [1:0] wake_sync;
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) wake_sync <= 2'b00;
    else          wake_sync <= {wake_sync[0], wake_ack};
  end
  wire wake_seen = wake_sync[1];

  always_comb begin
    state_n = state;
    case (state)
      // Wake wins the sleep-entry race.
      P_ACTIVE: if (sleep_req && !wake_seen) state_n = P_SLEEP;
      P_SLEEP:  if (wake_seen)              state_n = P_WAKE;
      P_WAKE:                               state_n = P_ACTIVE;
      default:                              state_n = P_ACTIVE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) state <= P_ACTIVE;
    else          state <= state_n;
  end

  // One-cycle pulse that clears the sticky sleep request on wake.
  assign wake_event = (state == P_SLEEP) && wake_seen;

  assign core_clk_en   = (state == P_ACTIVE) || (state == P_WAKE);
  assign periph_clk_en = (state == P_ACTIVE) || (state == P_WAKE);
  assign wake_req      = (state == P_SLEEP);

endmodule
