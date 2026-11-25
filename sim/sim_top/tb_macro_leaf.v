//------------------------------------------------------------------------------
// tb_macro_leaf.v — simulatable behavioural stand-in for
//   sky130_sram_2kbyte_1rw1r_32x512_8
//
// Used ONLY to drive sram_macro_wrap's banking / FSM / strobe / reset / i-port
// logic in Icarus, because the official PDK Verilog models (both 1KB and 2KB)
// cannot be elaborated by Icarus 14.0: they index mem[addr_reg] with a reg
// index, which Icarus tombstones as "Scope index expression is not constant".
//
// This leaf is NOT a timing-accurate model of the macro. It mirrors the macro's
// PROTOCOL contract so the wrapper's logic can be tested:
//   - all inputs are registered (posedge clk0/clk1 capture csb/web/wmask/addr/
//     din into _reg; dout0/dout1 are registered outputs driven on the
//     following negedge after DELAY+T_HOLD gap)
//   - byte-masked writes (wmask[3:0] == wstrb[3:0])
//   - 2-port: port0 = RW (csb0/web0), port1 = R only (csb1)
//   - mem uninitialized at time 0 (behavioural blackbox — no init file path)
//   - on a simultaneous write(port0) + read(port1) of the same address the
//     leaf issues a $display collision warning (mirrors the real macro)
//   - no reset pin on the macro (the wrapper resets only its own FSM/regs)
//
// This is deliberately NOT the real macro; it is a test proxy. Do not ship it.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

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
  localparam T_HOLD = 1;

  reg  csb0_reg;
  reg  web0_reg;
  reg [NUM_WMASKS-1:0] wmask0_reg;
  reg [ADDR_WIDTH-1:0] addr0_reg;
  reg [DATA_WIDTH-1:0] din0_reg;

  reg  csb1_reg;
  reg [ADDR_WIDTH-1:0] addr1_reg;

  reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

  // Registered inputs, posedge capture (mirrors real macro).
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

  // Write port 0: falling-edge, byte-masked.
  always @(negedge clk0) begin
    if (!csb0_reg && !web0_reg && addr0_reg < (1<<ADDR_WIDTH)) begin
      if (wmask0_reg[0]) mem[addr0_reg][7:0]   = din0_reg[7:0];
      if (wmask0_reg[1]) mem[addr0_reg][15:8]  = din0_reg[15:8];
      if (wmask0_reg[2]) mem[addr0_reg][23:16] = din0_reg[23:16];
      if (wmask0_reg[3]) mem[addr0_reg][31:24] = din0_reg[31:24];
    end
  end

  // Read port 0: falling-edge registered output after DELAY.
  always @(negedge clk0) begin
    if (!csb0_reg && web0_reg && addr0_reg < (1<<ADDR_WIDTH))
      dout0 <= #(DELAY) mem[addr0_reg];
  end

  // Read port 1: falling-edge registered output after DELAY (R-only).
  always @(negedge clk1) begin
    if (!csb1_reg && addr1_reg < (1<<ADDR_WIDTH))
      dout1 <= #(DELAY) mem[addr1_reg];
  end

endmodule
