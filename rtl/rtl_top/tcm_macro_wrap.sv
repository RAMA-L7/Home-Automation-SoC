//------------------------------------------------------------------------------
// Home-Automation-SoC — TCM macro wrapper (32 KiB)
// Phase 5.3A
//
// Replaces the behavioural `sram` blackbox at `tcm_inst` with real Sky130 SRAM macros behind
// an identical external interface. The SoC sees the same AXI4-Lite W/R + instruction port
// (ADDR_WIDTH=15), with the same address trimming ([14:0]) already applied in has_soc.sv.
// Only the implementation changes.
//
// This delegates to sram_macro_wrap with the TCM geometry. The external interface is identical
// (same port names and directions), so this is a drop-in replacement for the behavioural
// sram #(.ADDR_WIDTH(15), ...) at tcm_inst.
//
// REAL MACRO (this machine, volare PDK): the DEFAULT here is the 2 KiB macro
// sky130_sram_2kbyte_1rw1r_32x512_8 (32×512, 512 words × 32 bits = 2 KiB, 2-port RW+R,
// vccd1/vssd1). TCM = 32 KiB / 2 KiB = 16 macros.
//
// TCM banking for 32 KiB with the 2 KiB macro (DEFAULT):
//   NUM_MACROS     = 16   (32 KiB / 2 KiB = 16)
//   BANK_AW        = 4    ($clog2(16))
//   LOCAL_AW       = 9    ($clog2(512))
//   SoC word address (13 bits for 32 KiB = 8192 words) splits into:
//     bank[8:5] (4 bits, 16 banks) + local[8:0] (9 bits, macro ADDR_WIDTH = 512 words)
//   Check: 16 banks × 512 words = 8192 words = 32 KiB. ✓
//
// Alternate: 1 KiB macro (32x256) for TCM: NUM_MACROS=32 (32 KiB / 1 KiB), BANK_AW=5,
// LOCAL_AW=8; requires `define MACRO_USE_1KB at elaboration.
//
// The same macro-specific gaps, reset/init gap, synthesis approach, and power-pin notes as
// sram_macro_wrap apply. See that file's header for the full documentation. This file's only
// job is to present the TCM-specific parameterization at the same external interface.
//
// IMPORTANT: the previously-documented 4 KiB macro (128x256x8) does not exist on this machine.
// The NUM_MACROS=8 default from the earlier plan was based on that non-existent macro. The
// corrected default is NUM_MACROS=16 (2 KiB macro) — reflected below.
//------------------------------------------------------------------------------

module tcm_macro_wrap #(
  // verilog_lint: waive explicit-parameter-storage-type
  parameter int ADDR_WIDTH = 15,           // bytes; 2^15 = 32 KiB (TCM aperture, FR-MEM-002)
  parameter int DATA_WIDTH = 32,
  // Macro geometry — defaults to the real 2 KiB macro (32x512) available on this machine.
  // To use the 1 KiB macro (32x256): MACRO_DW=32, MACRO_AW=8, NUM_MACROS=32, and define
  // `MACRO_USE_1KB at elaboration.
  parameter int MACRO_DW   = 32,
  parameter int MACRO_AW   = 9,
  // Number of macros for 32 KiB with 2 KiB macros = 16 (CORRECTED default).
  // Previously NUM_MACROS=8 was used, based on the non-existent 4 KiB macro.
  parameter int NUM_MACROS = 16,
  // SIMULATION ONLY, forwarded to sram_macro_wrap.INIT_FILE (see that file).
  // verilog_lint: waive explicit-parameter-storage-type
  parameter INIT_FILE = ""
) (
  input  logic                   clk,
  input  logic                   reset_n,
  // AXI4-Lite write address channel
  input  logic                   awvalid,
  input  logic [ADDR_WIDTH-1:0]  awaddr,
  output logic                   awready,
  // AXI4-Lite write data channel
  input  logic                   wvalid,
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   wready,
  // AXI4-Lite write response channel
  output logic                   bvalid,
  input  logic                   bready,
  output logic [1:0]             bresp,
  // AXI4-Lite read address channel
  input  logic                   arvalid,
  input  logic [ADDR_WIDTH-1:0]  araddr,
  output logic                   arready,
  // AXI4-Lite read data channel
  output logic                   rvalid,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic [1:0]             rresp,
  input  logic                   rready,
  // Instruction read port (execute-in-place)
  input  logic                   i_req,
  input  logic [ADDR_WIDTH-1:0]  i_addr,
  output logic                   i_gnt,
  output logic [DATA_WIDTH-1:0]  i_rdata,
  output logic                   i_rvalid
);

  // -------------------------------------------------------------------------
  // The TCM is a SRAM wrapper with ADDR_WIDTH=15 and TCM-appropriate bank count.
  // Delegate to the shared implementation. Using a direct instantiation of the shared
  // parameterized module keeps one source of truth for the FSM, address decode, lane
  // placement, mask expansion, read-hold, and same-word bypass.
  //
  // We instantiate sram_macro_wrap with the TCM geometry. The external interface is identical
  // (same port names and directions), so this is a drop-in replacement for the behavioural
  // sram #(.ADDR_WIDTH(15), ...) at tcm_inst.
  // -------------------------------------------------------------------------

  sram_macro_wrap #(
    .ADDR_WIDTH (ADDR_WIDTH),   // 15
    .DATA_WIDTH (DATA_WIDTH),
    .MACRO_DW   (MACRO_DW),
    .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (NUM_MACROS),
    .INIT_FILE  (INIT_FILE)
  ) u_tcm (
    .clk      (clk),
    .reset_n  (reset_n),
    .awvalid  (awvalid),
    .awaddr   (awaddr),
    .awready  (awready),
    .wvalid   (wvalid),
    .wdata    (wdata),
    .wstrb    (wstrb),
    .wready   (wready),
    .bvalid   (bvalid),
    .bready   (bready),
    .bresp    (bresp),
    .arvalid  (arvalid),
    .araddr   (araddr),
    .arready  (arready),
    .rvalid   (rvalid),
    .rdata    (rdata),
    .rready   (rready),
    .rresp    (rresp),
    .i_req    (i_req),
    .i_addr   (i_addr),
    .i_gnt    (i_gnt),
    .i_rdata  (i_rdata),
    .i_rvalid (i_rvalid)
  );

endmodule
