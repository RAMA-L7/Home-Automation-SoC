//------------------------------------------------------------------------------
// Home-Automation-SoC — General Timer (APB)
// Stage 2 RTL
//
// 32-bit free-running counter with compare match and interrupt.
// APB registers:
//   0x00 TIMER_COUNT   - RO - current counter value
//   0x04 TIMER_COMPARE - RW - compare value
//   0x08 TIMER_CTRL    - RW - bit0: enable, bit1: interrupt enable
//   0x0C TIMER_STATUS  - RW1C - bit0: compare match pending
//------------------------------------------------------------------------------
module timer #(
  parameter int WIDTH = 32
) (
  input  logic         pclk,
  input  logic         presetn,
  input  logic         penable,
  input  logic         pwrite,
  input  logic [31:0]  paddr,
  input  logic [31:0]  pwdata,
  input  logic [3:0]   pstrb,
  output logic [31:0]  prdata,
  output logic         pready,
  output logic         pslverr,
  output logic         irq
);

  logic [WIDTH-1:0] count, compare;
  logic             enable, int_en;
  logic             match_pend;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) count <= '0;
    else if (enable) count <= count + 1;
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      compare   <= '0;
      enable    <= 1'b0;
      int_en    <= 1'b0;
      match_pend<= 1'b0;
    end else begin
      if (penable && pwrite) begin
        // A `unique case` without a default aborts the simulation on any
        // unmapped or read-only offset, so every reachable offset must be
        // listed and a default must be present.
        unique case (paddr[11:2])
          10'd1: compare <= pwdata[WIDTH-1:0];
          10'd2: begin
            enable  <= pwdata[0];
            int_en  <= pwdata[1];
          end
          10'd3: match_pend <= match_pend & ~pwdata[0];   // RW1C
          default: ;   // 0x00 COUNT is read-only; reserved offsets ignored
        endcase
      end
      if (count == compare && enable) match_pend <= 1'b1;
    end
  end

  assign irq = match_pend & int_en;

  always_comb begin
    unique case (paddr[11:2])
      10'd0: prdata = count;
      10'd1: prdata = compare;
      10'd2: prdata = {30'd0, int_en, enable};
      10'd3: prdata = {31'd0, match_pend};
      default: prdata = 32'd0;
    endcase
  end

  assign pready = 1'b1;
  assign pslverr = 1'b0;

endmodule
