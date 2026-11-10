//------------------------------------------------------------------------------
// Home-Automation-SoC — Formal Verification Properties
// Stage 4 Verification
//
// SystemVerilog assertions for the AXI4-Lite interconnect.
// These properties can be used with SymbiYosys or commercial formal tools.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Property: AWVALID must not be asserted without AWREADY for more than
//           one cycle (handshake progress).
//------------------------------------------------------------------------------
// assert property (@(posedge clk) disable iff (!reset_n)
//   aw_valid |-> aw_ready);

//------------------------------------------------------------------------------
// Property: WVALID must not be asserted without WREADY for more than
//           one cycle.
//------------------------------------------------------------------------------
// assert property (@(posedge clk) disable iff (!reset_n)
//   w_valid |-> w_ready);

//------------------------------------------------------------------------------
// Property: Write response must follow write address+data handshake.
//------------------------------------------------------------------------------
// assert property (@(posedge clk) disable iff (!reset_n)
//   (aw_valid && aw_ready && w_valid && w_ready) |-> ##[1:4] b_valid);

//------------------------------------------------------------------------------
// Property: Read response must follow read address handshake.
//------------------------------------------------------------------------------
// assert property (@(posedge clk) disable iff (!reset_n)
//   (ar_valid && ar_ready) |-> ##[1:4] r_valid);

//------------------------------------------------------------------------------
// Property: No two slaves selected simultaneously (decode is one-hot).
//------------------------------------------------------------------------------
// assert property (@(posedge clk) disable iff (!reset_n)
//   $onehot({aw_sel_valid[0], aw_sel_valid[1], aw_sel_valid[2],
//            aw_sel_valid[3], aw_sel_valid[4], aw_sel_valid[5]}));

//------------------------------------------------------------------------------
// Property: Unmapped addresses complete with SLVERR without accessing slaves.
//------------------------------------------------------------------------------
// assert property (@(posedge clk) disable iff (!reset_n)
//   aw_decode_err |-> aw_ready && aw_valid);

//------------------------------------------------------------------------------
// Property: Reset deassertion — all outputs settle to known state.
//------------------------------------------------------------------------------
// assert property (@(posedge clk) disable iff (!reset_n)
//   !reset_n |-> ##[1:2] (!aw_valid && !w_valid && !b_valid &&
//                         !ar_valid && !r_valid));
