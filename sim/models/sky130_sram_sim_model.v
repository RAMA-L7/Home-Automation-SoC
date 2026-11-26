//------------------------------------------------------------------------------
// sky130_sram_sim_model.v — SIMULATION-ONLY behavioural stand-in for the
//                           SkyWater sky130 SRAM macros
//
// NOT VENDOR IP. NOT TIMING ACCURATE. NOT FOR SYNTHESIS OR SIGNOFF.
//
// Why this file exists
//   rtl/rtl_top/{sram,tcm}_macro_wrap.sv instantiate the real macro cell names
//   (sky130_sram_2kbyte_1rw1r_32x512_8 by default). Those vendor Verilog models
//   live in the PDK (libs.ref/sky130_sram_macros/verilog/), are not redistributed
//   here, and do not elaborate in Icarus 14 (`mem[addr_reg]` is a non-constant
//   index there). Simulations therefore need a stand-in that implements the same
//   pin protocol so the RTL around it can be exercised.
//
// What it models
//   * 2-port macro: port0 = read/write (csb0/web0/wmask0/addr0/din0/dout0),
//     port1 = read only (csb1/addr1/dout1)
//   * all inputs captured on the rising clock edge
//   * dout0/dout1 driven on the following falling edge after DELAY, and HELD
//     until the next read on that port (the LIB gives a falling-edge output
//     arc; the real macro does not return the output to X between reads)
//   * byte-masked writes (wmask0 bit k -> byte k)
//   * no reset pin; contents are undefined at time 0
//   * a $display warning when port0 writes the word port1 is reading
//   * optional vccd1/vssd1 pins behind USE_POWER_PINS
//
// What it does NOT model
//   propagation delay, setup/hold, power, area, bit-cell behaviour, or any
//   silicon effect. Real-macro verification must use the vendor model and
//   extracted timing. See docs/EXTERNAL_DEPENDENCIES.md.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

// =============================================================================
// sky130_sram_2kbyte_1rw1r_32x512_8 — 512 words x 32 bits = 2 KiB
// =============================================================================
module sky130_sram_2kbyte_1rw1r_32x512_8 #(
  parameter ADDR_WIDTH = 9,
  parameter DATA_WIDTH = 32,
  parameter NUM_WMASKS = 4
)(
  input  wire                  clk0,
  input  wire                  clk1,
  `ifdef USE_POWER_PINS
  input  wire                  vccd1,
  input  wire                  vssd1,
  `endif
  input  wire                  csb0,
  input  wire                  web0,
  input  wire [NUM_WMASKS-1:0] wmask0,
  input  wire [ADDR_WIDTH-1:0] addr0,
  input  wire [DATA_WIDTH-1:0] din0,
  output reg  [DATA_WIDTH-1:0] dout0,
  input  wire                  csb1,
  input  wire                  web1,
  input  wire [ADDR_WIDTH-1:0] addr1,
  output reg  [DATA_WIDTH-1:0] dout1
);
  localparam DELAY  = 3;
  localparam int WORDS = (1 << ADDR_WIDTH);

  reg [DATA_WIDTH-1:0] mem [0:WORDS-1];

  reg                  csb0_r, web0_r;
  reg [NUM_WMASKS-1:0] wmask0_r;
  reg [ADDR_WIDTH-1:0] addr0_r;
  reg [DATA_WIDTH-1:0] din0_r;
  reg                  csb1_r;
  reg [ADDR_WIDTH-1:0] addr1_r;

  always @(posedge clk0) begin
    csb0_r   <= csb0;
    web0_r   <= web0;
    wmask0_r <= wmask0;
    addr0_r  <= addr0;
    din0_r   <= din0;
    if (!csb0 && !web0 && !csb1 && (addr0 == addr1))
      $display("[sram_sim_model] WARNING: simultaneous write+read addr=%h", addr0);
  end

  always @(posedge clk1) begin
    csb1_r  <= csb1;
    addr1_r <= addr1;
  end

  always @(negedge clk0) begin
    if (!csb0_r && !web0_r) begin
      if (wmask0_r[0]) mem[addr0_r][7:0]   = din0_r[7:0];
      if (wmask0_r[1]) mem[addr0_r][15:8]  = din0_r[15:8];
      if (wmask0_r[2]) mem[addr0_r][23:16] = din0_r[23:16];
      if (wmask0_r[3]) mem[addr0_r][31:24] = din0_r[31:24];
    end
  end

  always @(negedge clk0)
    if (!csb0_r && web0_r)
      dout0 <= #(DELAY) mem[addr0_r];

  always @(negedge clk1)
    if (!csb1_r)
      dout1 <= #(DELAY) mem[addr1_r];

endmodule

// =============================================================================
// sky130_sram_1kbyte_1rw1r_32x256_8 — 256 words x 32 bits = 1 KiB
// Alternate macro (compile the wrapper with +define+MACRO_USE_1KB).
// =============================================================================
module sky130_sram_1kbyte_1rw1r_32x256_8 #(
  parameter ADDR_WIDTH = 8,
  parameter DATA_WIDTH = 32,
  parameter NUM_WMASKS = 4
)(
  input  wire                  clk0,
  input  wire                  clk1,
  `ifdef USE_POWER_PINS
  input  wire                  vccd1,
  input  wire                  vssd1,
  `endif
  input  wire                  csb0,
  input  wire                  web0,
  input  wire [NUM_WMASKS-1:0] wmask0,
  input  wire [ADDR_WIDTH-1:0] addr0,
  input  wire [DATA_WIDTH-1:0] din0,
  output reg  [DATA_WIDTH-1:0] dout0,
  input  wire                  csb1,
  input  wire                  web1,
  input  wire [ADDR_WIDTH-1:0] addr1,
  output reg  [DATA_WIDTH-1:0] dout1
);
  localparam DELAY  = 3;
  localparam int WORDS = (1 << ADDR_WIDTH);

  reg [DATA_WIDTH-1:0] mem [0:WORDS-1];

  reg                  csb0_r, web0_r;
  reg [NUM_WMASKS-1:0] wmask0_r;
  reg [ADDR_WIDTH-1:0] addr0_r;
  reg [DATA_WIDTH-1:0] din0_r;
  reg                  csb1_r;
  reg [ADDR_WIDTH-1:0] addr1_r;

  always @(posedge clk0) begin
    csb0_r   <= csb0;
    web0_r   <= web0;
    wmask0_r <= wmask0;
    addr0_r  <= addr0;
    din0_r   <= din0;
    if (!csb0 && !web0 && !csb1 && (addr0 == addr1))
      $display("[sram_sim_model] WARNING: simultaneous write+read addr=%h", addr0);
  end

  always @(posedge clk1) begin
    csb1_r  <= csb1;
    addr1_r <= addr1;
  end

  always @(negedge clk0) begin
    if (!csb0_r && !web0_r) begin
      if (wmask0_r[0]) mem[addr0_r][7:0]   = din0_r[7:0];
      if (wmask0_r[1]) mem[addr0_r][15:8]  = din0_r[15:8];
      if (wmask0_r[2]) mem[addr0_r][23:16] = din0_r[23:16];
      if (wmask0_r[3]) mem[addr0_r][31:24] = din0_r[31:24];
    end
  end

  always @(negedge clk0)
    if (!csb0_r && web0_r)
      dout0 <= #(DELAY) mem[addr0_r];

  always @(negedge clk1)
    if (!csb1_r)
      dout1 <= #(DELAY) mem[addr1_r];

endmodule
