//------------------------------------------------------------------------------
// Home-Automation-SoC — GPIO Controller (APB)
// Stage 2 RTL
//
// 16-bit GPIO with input/output enable, output data, input data, and interrupt
// on rising/falling edge of any pin.
//
// APB register map (4-byte offsets from base):
//   0x00 GPIO_DATA_OUT   - RW - output data
//   0x04 GPIO_DATA_IN    - RO - input data
//   0x04 GPIO_OE         - RW - output enable (write to same addr as IN? separate)
//   0x08 GPIO_OE         - RW - output enable (1=output)
//   0x0C GPIO_INT_EN     - RW - interrupt enable per pin
//   0x10 GPIO_INT_RISE   - RW - rising-edge detect enable
//   0x14 GPIO_INT_FALL   - RW - falling-edge detect enable
//   0x18 GPIO_INT_PEND   - RW1C - pending interrupts
//------------------------------------------------------------------------------
module gpio #(
  parameter WIDTH = 16
) (
  input  logic         pclk,
  input  logic         presetn,
  // APB
  input  logic         penable,
  input  logic         pwrite,
  input  logic [31:0]  paddr,
  input  logic [31:0]  pwdata,
  input  logic [3:0]   pstrb,
  output logic [31:0]  prdata,
  output logic         pready,
  output logic         pslverr,
  // GPIO pads
  inout  wire [WIDTH-1:0] gpio,
  // Interrupt
  output logic         irq
);

  // Registers
  logic [WIDTH-1:0] data_out, data_out_q;
  logic [WIDTH-1:0] oe;
  logic [WIDTH-1:0] int_en;
  logic [WIDTH-1:0] int_rise_en;
  logic [WIDTH-1:0] int_fall_en;
  logic [WIDTH-1:0] int_pend;

  // Input synchronizer (2-FF CDC from pad to clock domain)
  logic [WIDTH-1:0] gpio_in_sync1, gpio_in_sync2;
  logic [WIDTH-1:0] gpio_in_prev;

  // Drive outputs
  genvar i;
  generate
    for (i = 0; i < WIDTH; i++) begin : g_pad
      assign gpio[i] = oe[i] ? data_out[i] : 1'bz;
    end
  endgenerate

  // Capture input
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      gpio_in_sync1 <= '0;
      gpio_in_sync2 <= '0;
      gpio_in_prev  <= '0;
    end else begin
      gpio_in_sync1 <= gpio;
      gpio_in_sync2 <= gpio_in_sync1;
      gpio_in_prev  <= gpio_in_sync2;
    end
  end

  // Edge detect
  logic [WIDTH-1:0] rise_edge, fall_edge;
  assign rise_edge =  gpio_in_sync2 & ~gpio_in_prev;
  assign fall_edge = ~gpio_in_sync2 & gpio_in_prev;

  // Interrupt pending
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) int_pend <= '0;
    else begin
      int_pend <= int_pend | ((rise_edge & int_rise_en) | (fall_edge & int_fall_en)) & int_en;
      // RW1C: clear on write
      if (penable && pwrite && (paddr[11:2] == 10'd6)) begin  // 0x18
        int_pend <= int_pend & ~pwdata[WIDTH-1:0];
      end
    end
  end

  assign irq = |(int_pend & int_en);

  // APB read mux
  always_comb begin
    unique case (paddr[11:2])
      10'd0: prdata = {{(32-WIDTH){1'b0}}, data_out_q};              // 0x00 DATA_OUT
      10'd1: prdata = {{(32-WIDTH){1'b0}}, gpio_in_sync2};           // 0x04 DATA_IN
      10'd2: prdata = {{(32-WIDTH){1'b0}}, oe};                      // 0x08 OE
      10'd3: prdata = {{(32-WIDTH){1'b0}}, int_en};                  // 0x0C INT_EN
      10'd4: prdata = {{(32-WIDTH){1'b0}}, int_rise_en};             // 0x10 INT_RISE
      10'd5: prdata = {{(32-WIDTH){1'b0}}, int_fall_en};             // 0x14 INT_FALL
      10'd6: prdata = {{(32-WIDTH){1'b0}}, int_pend};                // 0x18 INT_PEND
      default: prdata = 32'd0;
    endcase
  end

  // APB write
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      data_out_q   <= '0;
      oe           <= '0;
      int_en       <= '0;
      int_rise_en  <= '0;
      int_fall_en  <= '0;
    end else if (penable && pwrite) begin
      // A `unique case` without a default aborts the simulation on any
      // unmapped or read-only offset, so every reachable offset must be
      // listed and a default must be present.
      unique case (paddr[11:2])
        10'd0: data_out_q <= pwdata[WIDTH-1:0];
        10'd2: oe         <= pwdata[WIDTH-1:0];
        10'd3: int_en     <= pwdata[WIDTH-1:0];
        10'd4: int_rise_en<= pwdata[WIDTH-1:0];
        10'd5: int_fall_en<= pwdata[WIDTH-1:0];
        default: ;   // DATA_IN / INT_PEND are read-only; reserved ignored
      endcase
    end
  end

  assign data_out = data_out_q;
  assign pready   = 1'b1;
  assign pslverr  = 1'b0;

endmodule
