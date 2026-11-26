//------------------------------------------------------------------------------
// tb_macro_wrap_negctl.v — NEGATIVE CONTROLS for tb_sram_macro_wrap.v
//
// Each module below has the SAME port list as the real wrapper and instantiates
// the REAL rtl/rtl_top/{sram,tcm}_macro_wrap.sv. It corrupts exactly one input at
// the wrapper boundary, injecting a representative defect. The testbench is
// compiled against these instead of the real wrappers (see the `SRAM_DUT /
// `TCM_DUT selection in tb_sram_macro_wrap.v):
//
//   sram/tcm_macro_wrap_negbank     bank-select bits forced to 0  -> every bank
//                                   aliases bank 0; boundary checks must fail
//   sram/tcm_macro_wrap_negstrobe   wstrb forced to 4'hF          -> partial writes
//                                   become full-word; strobe checks must fail
//
// scripts/eda/run_macro_wrapper.js requires each control to report a non-zero
// failure count. If a control PASSES, the checker itself is broken.
//
// These modules are verification scaffolding only. Never instantiate them in
// design RTL.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

// =============================================================================
// Bank-select aliasing control
// =============================================================================
module sram_macro_wrap_negbank #(
  parameter int ADDR_WIDTH = 17,
  parameter int DATA_WIDTH = 32,
  parameter int MACRO_DW   = 32,
  parameter int MACRO_AW   = 9,
  parameter int NUM_MACROS = 64
) (
  input  logic                   clk,
  input  logic                   reset_n,
  input  logic                   awvalid,
  input  logic [ADDR_WIDTH-1:0]  awaddr,
  output logic                   awready,
  input  logic                   wvalid,
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   wready,
  output logic                   bvalid,
  input  logic                   bready,
  output logic [1:0]             bresp,
  input  logic                   arvalid,
  input  logic [ADDR_WIDTH-1:0]  araddr,
  output logic                   arready,
  output logic                   rvalid,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic [1:0]             rresp,
  input  logic                   rready,
  input  logic                   i_req,
  input  logic [ADDR_WIDTH-1:0]  i_addr,
  output logic                   i_gnt,
  output logic [DATA_WIDTH-1:0]  i_rdata,
  output logic                   i_rvalid
);
  // LOCAL_AW = 9 -> byte address bits [10:0] select the word inside a bank.
  // Clearing everything above bit 10 makes every bank alias bank 0.
  localparam logic [ADDR_WIDTH-1:0] LANE_MASK = 11'h7FF;

  sram_macro_wrap #(
    .ADDR_WIDTH (ADDR_WIDTH), .DATA_WIDTH (DATA_WIDTH),
    .MACRO_DW   (MACRO_DW),   .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (NUM_MACROS)
  ) u_real (
    .clk (clk), .reset_n (reset_n),
    .awvalid (awvalid), .awaddr (awaddr & LANE_MASK), .awready (awready),
    .wvalid  (wvalid),  .wdata  (wdata), .wready (wready), .wstrb (wstrb),
    .bvalid  (bvalid),  .bready (bready), .bresp (bresp),
    .arvalid (arvalid), .araddr (araddr & LANE_MASK), .arready (arready),
    .rvalid  (rvalid),  .rdata  (rdata), .rresp (rresp), .rready (rready),
    .i_req   (i_req),   .i_addr (i_addr & LANE_MASK), .i_gnt (i_gnt),
    .i_rdata (i_rdata), .i_rvalid (i_rvalid)
  );
endmodule

module tcm_macro_wrap_negbank #(
  parameter int ADDR_WIDTH = 15,
  parameter int DATA_WIDTH = 32,
  parameter int MACRO_DW   = 32,
  parameter int MACRO_AW   = 9,
  parameter int NUM_MACROS = 16
) (
  input  logic                   clk,
  input  logic                   reset_n,
  input  logic                   awvalid,
  input  logic [ADDR_WIDTH-1:0]  awaddr,
  output logic                   awready,
  input  logic                   wvalid,
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   wready,
  output logic                   bvalid,
  input  logic                   bready,
  output logic [1:0]             bresp,
  input  logic                   arvalid,
  input  logic [ADDR_WIDTH-1:0]  araddr,
  output logic                   arready,
  output logic                   rvalid,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic [1:0]             rresp,
  input  logic                   rready,
  input  logic                   i_req,
  input  logic [ADDR_WIDTH-1:0]  i_addr,
  output logic                   i_gnt,
  output logic [DATA_WIDTH-1:0]  i_rdata,
  output logic                   i_rvalid
);
  localparam logic [ADDR_WIDTH-1:0] LANE_MASK = 11'h7FF;

  tcm_macro_wrap #(
    .ADDR_WIDTH (ADDR_WIDTH), .DATA_WIDTH (DATA_WIDTH),
    .MACRO_DW   (MACRO_DW),   .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (NUM_MACROS)
  ) u_real (
    .clk (clk), .reset_n (reset_n),
    .awvalid (awvalid), .awaddr (awaddr & LANE_MASK), .awready (awready),
    .wvalid  (wvalid),  .wdata  (wdata), .wready (wready), .wstrb (wstrb),
    .bvalid  (bvalid),  .bready (bready), .bresp (bresp),
    .arvalid (arvalid), .araddr (araddr & LANE_MASK), .arready (arready),
    .rvalid  (rvalid),  .rdata  (rdata), .rresp (rresp), .rready (rready),
    .i_req   (i_req),   .i_addr (i_addr & LANE_MASK), .i_gnt (i_gnt),
    .i_rdata (i_rdata), .i_rvalid (i_rvalid)
  );
endmodule

// =============================================================================
// Byte-strobe ignoring control
// =============================================================================
module sram_macro_wrap_negstrobe #(
  parameter int ADDR_WIDTH = 17,
  parameter int DATA_WIDTH = 32,
  parameter int MACRO_DW   = 32,
  parameter int MACRO_AW   = 9,
  parameter int NUM_MACROS = 64
) (
  input  logic                   clk,
  input  logic                   reset_n,
  input  logic                   awvalid,
  input  logic [ADDR_WIDTH-1:0]  awaddr,
  output logic                   awready,
  input  logic                   wvalid,
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   wready,
  output logic                   bvalid,
  input  logic                   bready,
  output logic [1:0]             bresp,
  input  logic                   arvalid,
  input  logic [ADDR_WIDTH-1:0]  araddr,
  output logic                   arready,
  output logic                   rvalid,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic [1:0]             rresp,
  input  logic                   rready,
  input  logic                   i_req,
  input  logic [ADDR_WIDTH-1:0]  i_addr,
  output logic                   i_gnt,
  output logic [DATA_WIDTH-1:0]  i_rdata,
  output logic                   i_rvalid
);
  sram_macro_wrap #(
    .ADDR_WIDTH (ADDR_WIDTH), .DATA_WIDTH (DATA_WIDTH),
    .MACRO_DW   (MACRO_DW),   .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (NUM_MACROS)
  ) u_real (
    .clk (clk), .reset_n (reset_n),
    .awvalid (awvalid), .awaddr (awaddr), .awready (awready),
    .wvalid  (wvalid),  .wdata  (wdata), .wready (wready),
    .wstrb   (4'hF),                                  // DEFECT: strobes ignored
    .bvalid  (bvalid),  .bready (bready), .bresp (bresp),
    .arvalid (arvalid), .araddr (araddr), .arready (arready),
    .rvalid  (rvalid),  .rdata  (rdata), .rresp (rresp), .rready (rready),
    .i_req   (i_req),   .i_addr (i_addr), .i_gnt (i_gnt),
    .i_rdata (i_rdata), .i_rvalid (i_rvalid)
  );
endmodule

module tcm_macro_wrap_negstrobe #(
  parameter int ADDR_WIDTH = 15,
  parameter int DATA_WIDTH = 32,
  parameter int MACRO_DW   = 32,
  parameter int MACRO_AW   = 9,
  parameter int NUM_MACROS = 16
) (
  input  logic                   clk,
  input  logic                   reset_n,
  input  logic                   awvalid,
  input  logic [ADDR_WIDTH-1:0]  awaddr,
  output logic                   awready,
  input  logic                   wvalid,
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   wready,
  output logic                   bvalid,
  input  logic                   bready,
  output logic [1:0]             bresp,
  input  logic                   arvalid,
  input  logic [ADDR_WIDTH-1:0]  araddr,
  output logic                   arready,
  output logic                   rvalid,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic [1:0]             rresp,
  input  logic                   rready,
  input  logic                   i_req,
  input  logic [ADDR_WIDTH-1:0]  i_addr,
  output logic                   i_gnt,
  output logic [DATA_WIDTH-1:0]  i_rdata,
  output logic                   i_rvalid
);
  tcm_macro_wrap #(
    .ADDR_WIDTH (ADDR_WIDTH), .DATA_WIDTH (DATA_WIDTH),
    .MACRO_DW   (MACRO_DW),   .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (NUM_MACROS)
  ) u_real (
    .clk (clk), .reset_n (reset_n),
    .awvalid (awvalid), .awaddr (awaddr), .awready (awready),
    .wvalid  (wvalid),  .wdata  (wdata), .wready (wready),
    .wstrb   (4'hF),                                  // DEFECT: strobes ignored
    .bvalid  (bvalid),  .bready (bready), .bresp (bresp),
    .arvalid (arvalid), .araddr (araddr), .arready (arready),
    .rvalid  (rvalid),  .rdata  (rdata), .rresp (rresp), .rready (rready),
    .i_req   (i_req),   .i_addr (i_addr), .i_gnt (i_gnt),
    .i_rdata (i_rdata), .i_rvalid (i_rvalid)
  );
endmodule
