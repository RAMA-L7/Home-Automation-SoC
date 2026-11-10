//------------------------------------------------------------------------------
// Home-Automation-SoC — JTAG Debug TAP Controller
// Stage 2 RTL
//
// Minimal 5-state TAP (CaptureDR, ShiftDR, UpdateDR, ShiftIR, UpdateIR) with
// a 32-bit bypass/data register. Exposes TDO. No DMI/DTM implemented yet —
// this is a bring-up TAP that loops TDI to TDO through a shift register.
//
//------------------------------------------------------------------------------
module debug_jtag (
  input  logic         clk,
  input  logic         reset_n,
  input  logic         tck,
  input  logic         tms,
  input  logic         tdi,
  output logic         tdo,
  input  logic         trst_n
);

  // Synchronize TMS/TDI to clk domain (simple 2-FF)
  logic tck_sync1, tck_sync2;
  logic tms_sync, tdi_sync;
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      tck_sync1 <= 1'b0; tck_sync2 <= 1'b0;
      tms_sync  <= 1'b0; tdi_sync  <= 1'b0;
    end else begin
      tck_sync1 <= tck; tck_sync2 <= tck_sync1;
      tms_sync  <= tms; tdi_sync  <= tdi;
    end
  end
  wire tck_rise = tck_sync1 & ~tck_sync2;

  // TAP state machine
  typedef enum logic [3:0] {
    S_TEST_LOGIC_RESET, S_RUN_TEST_IDLE, S_SELECT_DR, S_CAPTURE_DR,
    S_SHIFT_DR, S_EXIT1_DR, S_PAUSE_DR, S_EXIT2_DR, S_UPDATE_DR,
    S_SELECT_IR, S_CAPTURE_IR, S_SHIFT_IR, S_EXIT1_IR,
    S_PAUSE_IR, S_EXIT2_IR, S_UPDATE_IR
  } tap_state_e;

  tap_state_e state, state_n;

  always_comb begin
    state_n = state;
    if (tms_sync) begin
      unique case (state)
        S_TEST_LOGIC_RESET: state_n = S_TEST_LOGIC_RESET;
        S_RUN_TEST_IDLE:    state_n = S_SELECT_DR;
        S_SELECT_DR:        state_n = S_SELECT_IR;
        S_CAPTURE_DR:       state_n = S_EXIT1_DR;
        S_SHIFT_DR:         state_n = S_EXIT1_DR;
        S_EXIT1_DR:         if (tms_sync) state_n = S_UPDATE_DR; else state_n = S_PAUSE_DR;
        S_PAUSE_DR:         if (tms_sync) state_n = S_EXIT2_DR; else state_n = S_PAUSE_DR;
        S_EXIT2_DR:         state_n = S_UPDATE_DR;
        S_UPDATE_DR:        state_n = S_RUN_TEST_IDLE;
        S_SELECT_IR:        state_n = S_CAPTURE_IR;
        S_CAPTURE_IR:       state_n = S_EXIT1_IR;
        S_SHIFT_IR:         state_n = S_EXIT1_IR;
        S_EXIT1_IR:         if (tms_sync) state_n = S_UPDATE_IR; else state_n = S_PAUSE_IR;
        S_PAUSE_IR:         if (tms_sync) state_n = S_EXIT2_IR; else state_n = S_PAUSE_IR;
        S_EXIT2_IR:         state_n = S_UPDATE_IR;
        S_UPDATE_IR:        state_n = S_RUN_TEST_IDLE;
        default:            state_n = S_TEST_LOGIC_RESET;
      endcase
    end else begin
      unique case (state)
        S_TEST_LOGIC_RESET: state_n = S_RUN_TEST_IDLE;
        default:            state_n = state;
      endcase
    end
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) state <= S_TEST_LOGIC_RESET;
    else if (tck_rise) state <= state_n;
  end

  // Shift registers
  logic [31:0] dr, ir;
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      dr <= 32'd0; ir <= 32'd0; tdo <= 1'b0;
    end else if (tck_rise) begin
      case (state)
        S_CAPTURE_DR: dr <= {31'd0, 1'b1};
        S_SHIFT_DR:   begin tdo <= dr[0]; dr <= {tdi_sync, dr[31:1]}; end
        S_UPDATE_DR:  /* capture */ ;
        S_CAPTURE_IR: ir <= 32'h0000_0001;
        S_SHIFT_IR:   begin tdo <= ir[0]; ir <= {tdi_sync, ir[31:1]}; end
        S_UPDATE_IR:  /* capture */ ;
      endcase
    end
  end

endmodule
