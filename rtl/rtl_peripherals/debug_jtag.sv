//------------------------------------------------------------------------------
// Home-Automation-SoC — JTAG Debug TAP Controller
// Stage 2 RTL
//
// Minimal 5-state TAP (CaptureDR, ShiftDR, UpdateDR, ShiftIR, UpdateIR) with
// a 32-bit bypass/data register. Exposes TDO. No DMI/DTM implemented yet —
// this is a bring-up TAP that loops TDI to TDO through a shift register.
//
// Clock-domain architecture: the TAP itself runs on the system clock `clk`.
// TCK, TMS and TDI are asynchronous inputs from the debugger; all three pass
// through two flops before use, and the TAP advances only on a detected TCK
// rising edge (`tck_rise`).  TMS/TDI are sampled by the debugger on the TCK
// falling edge, i.e. at least half a TCK period before `tck_rise` is seen, so
// the two-flop delay (~2 clk) cannot move a sample across a TCK boundary.  Simulation shows the
// minimum reliable ratio is clk >= 10 x TCK (4x is insufficient: synchronizer latency eats the margin).
//
// Full IEEE 1149.1 TAP state table (all 16 states, including PAUSE_* and EXIT2_*).
// Data moves only in SHIFT_DR/SHIFT_IR; there is no DMI/DTM, IDCODE, boundary scan,
// or strict 1149.1 TDO timing (TDO is registered one shift edge late).
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

  // Synchronize TCK/TMS/TDI into the clk domain.  All three are TCK-domain
  // signals: two flops each, so no asynchronous input reaches the TAP logic.
  logic tck_sync1, tck_sync2;
  logic tms_meta, tms_sync, tdi_meta, tdi_sync;
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      tck_sync1 <= 1'b0; tck_sync2 <= 1'b0;
      tms_meta  <= 1'b0; tms_sync  <= 1'b0;
      tdi_meta  <= 1'b0; tdi_sync  <= 1'b0;
    end else begin
      tck_sync1 <= tck;  tck_sync2 <= tck_sync1;
      tms_meta  <= tms;  tms_sync  <= tms_meta;
      tdi_meta  <= tdi;  tdi_sync  <= tdi_meta;
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

  // IEEE 1149.1 next-state table.  The previous version only implemented the
  // TMS=1 arcs (every TMS=0 transition left the state unchanged), which made
  // SHIFT_DR and SHIFT_IR unreachable: the TAP could never shift TDI into the
  // data or instruction register.  sim/sim_top/tb_jtag_proto.v covers every
  // state and every TMS arc.
  always_comb begin
    // Icarus rejects a bare enum-valued ternary here, so each arm is an
    // explicit if/else pair.
    case (state)
      S_TEST_LOGIC_RESET:    if (tms_sync) state_n = S_TEST_LOGIC_RESET; else state_n = S_RUN_TEST_IDLE;
      S_RUN_TEST_IDLE:       if (tms_sync) state_n = S_SELECT_DR; else state_n = S_RUN_TEST_IDLE;
      S_SELECT_DR:           if (tms_sync) state_n = S_SELECT_IR; else state_n = S_CAPTURE_DR;
      S_CAPTURE_DR:          if (tms_sync) state_n = S_EXIT1_DR; else state_n = S_SHIFT_DR;
      S_SHIFT_DR:            if (tms_sync) state_n = S_EXIT1_DR; else state_n = S_SHIFT_DR;
      S_EXIT1_DR:            if (tms_sync) state_n = S_UPDATE_DR; else state_n = S_PAUSE_DR;
      S_PAUSE_DR:            if (tms_sync) state_n = S_EXIT2_DR; else state_n = S_PAUSE_DR;
      S_EXIT2_DR:            if (tms_sync) state_n = S_UPDATE_DR; else state_n = S_SHIFT_DR;
      S_UPDATE_DR:           if (tms_sync) state_n = S_SELECT_DR; else state_n = S_RUN_TEST_IDLE;
      S_SELECT_IR:           if (tms_sync) state_n = S_TEST_LOGIC_RESET; else state_n = S_CAPTURE_IR;
      S_CAPTURE_IR:          if (tms_sync) state_n = S_EXIT1_IR; else state_n = S_SHIFT_IR;
      S_SHIFT_IR:            if (tms_sync) state_n = S_EXIT1_IR; else state_n = S_SHIFT_IR;
      S_EXIT1_IR:            if (tms_sync) state_n = S_UPDATE_IR; else state_n = S_PAUSE_IR;
      S_PAUSE_IR:            if (tms_sync) state_n = S_EXIT2_IR; else state_n = S_PAUSE_IR;
      S_EXIT2_IR:            if (tms_sync) state_n = S_UPDATE_IR; else state_n = S_SHIFT_IR;
      S_UPDATE_IR:           if (tms_sync) state_n = S_SELECT_DR; else state_n = S_RUN_TEST_IDLE;
      default:            state_n = S_TEST_LOGIC_RESET;
    endcase
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
        default: ;
      endcase
    end
  end

endmodule
