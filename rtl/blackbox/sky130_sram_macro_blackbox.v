//------------------------------------------------------------------------------
// sky130_sram_macro_blackbox.v — SYNTHESIS-ONLY blackbox declarations
//
// The real SkyWater SRAM macros are PDK assets that are NOT redistributed in
// this repository (see docs/EXTERNAL_DEPENDENCIES.md). Synthesis and structural
// checks still have to elaborate has_soc, which instantiates them through
// rtl/rtl_top/{sram,tcm}_macro_wrap.sv, so this file declares the cells with
// their exact pin lists and marks them `blackbox`: no behaviour is described,
// nothing is mapped, and the cell stays a hierarchy leaf that the physical flow
// must supply from the PDK.
//
// Do NOT compile this alongside sim/models/sky130_sram_sim_model.v (duplicate
// module names) and do NOT use it for simulation: it has no behaviour.
//
// Pin lists and geometry are taken from the PDK LIB memory() blocks:
//   sky130_sram_2kbyte_1rw1r_32x512_8   512 words x 32 bit, 2-port (RW + R)
//   sky130_sram_1kbyte_1rw1r_32x256_8   256 words x 32 bit, 2-port (RW + R)
//------------------------------------------------------------------------------

(* blackbox *)
module sky130_sram_2kbyte_1rw1r_32x512_8 (
  input  wire        clk0,
  input  wire        csb0,
  input  wire        web0,
  input  wire [3:0]  wmask0,
  input  wire [8:0]  addr0,
  input  wire [31:0] din0,
  output wire [31:0] dout0,
  input  wire        clk1,
  input  wire        csb1,
  input  wire [8:0]  addr1,
  output wire [31:0] dout1,
  input  wire        vccd1,
  input  wire        vssd1
);
endmodule

(* blackbox *)
module sky130_sram_1kbyte_1rw1r_32x256_8 (
  input  wire        clk0,
  input  wire        csb0,
  input  wire        web0,
  input  wire [3:0]  wmask0,
  input  wire [7:0]  addr0,
  input  wire [31:0] din0,
  output wire [31:0] dout0,
  input  wire        clk1,
  input  wire        csb1,
  input  wire [7:0]  addr1,
  output wire [31:0] dout1,
  input  wire        vccd1,
  input  wire        vssd1
);
endmodule
