//------------------------------------------------------------------------------
// tb_macro_leaf_1kb.v — simulatable behavioural stand-in for
//   sky130_sram_1kbyte_1rw1r_32x256_8
//
// Test proxy only. Mirrors the macro protocol (2-port RW+R, registered inputs,
// falling-edge registered dout with DELAY+T_HOLD gap, byte-masked writes,
// collision warning, no reset). ADDR_WIDTH=8, DATA_WIDTH=32, depth=256.
//
// The 1KB PDK model is NOT Icarus-compatible (mem[reg_index] indexing), so
// this proxy is used when testing the wrapper's `ifdef MACRO_USE_1KB branch.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

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
  localparam T_HOLD = 1;

  reg  csb0_reg;
  reg  web0_reg;
  reg [NUM_WMASKS-1:0] wmask0_reg;
  reg [ADDR_WIDTH-1:0] addr0_reg;
  reg [DATA_WIDTH-1:0] din0_reg;

  reg  csb1_reg;
  reg [ADDR_WIDTH-1:0] addr1_reg;

  reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

  always @(posedge clk0) begin
    csb0_reg   = csb0;
    web0_reg   = web0;
    wmask0_reg = wmask0;
    addr0_reg  = addr0;
    din0_reg   = din0;
    #(T_HOLD) dout0 = 32'bx;
    if (!csb0_reg && web0_reg && addr0_reg < (1<<ADDR_WIDTH))
      $display("%m addr0=%h dout0=%h (read)", addr0_reg, mem[addr0_reg]);
    if (!csb0_reg && !web0_reg && addr0_reg < (1<<ADDR_WIDTH))
      $display("%m addr0=%h din0=%h wmask0=%b (write)", addr0_reg, din0_reg, wmask0_reg);
  end

  always @(posedge clk1) begin
    csb1_reg  = csb1;
    addr1_reg = addr1;
    if (!csb0 && !web0 && !csb1 && (addr0 == addr1))
      $display("%m WARNING: simultaneous write+read addr=%h", addr0);
    #(T_HOLD) dout1 = 32'bx;
    if (!csb1_reg && addr1_reg < (1<<ADDR_WIDTH))
      $display("%m addr1=%h dout1=%h (read)", addr1_reg, mem[addr1_reg]);
  end

  always @(negedge clk0) begin
    if (!csb0_reg && !web0_reg && addr0_reg < (1<<ADDR_WIDTH)) begin
      if (wmask0_reg[0]) mem[addr0_reg][7:0]   = din0_reg[7:0];
      if (wmask0_reg[1]) mem[addr0_reg][15:8]  = din0_reg[15:8];
      if (wmask0_reg[2]) mem[addr0_reg][23:16] = din0_reg[23:16];
      if (wmask0_reg[3]) mem[addr0_reg][31:24] = din0_reg[31:24];
    end
  end

  always @(negedge clk0) begin
    if (!csb0_reg && web0_reg && addr0_reg < (1<<ADDR_WIDTH))
      dout0 <= #(DELAY) mem[addr0_reg];
  end

  always @(negedge clk1) begin
    if (!csb1_reg && addr1_reg < (1<<ADDR_WIDTH))
      dout1 <= #(DELAY) mem[addr1_reg];
  end

endmodule
