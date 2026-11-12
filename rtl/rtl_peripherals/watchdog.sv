//------------------------------------------------------------------------------
// Home-Automation-SoC — Watchdog Timer (APB)
// Stage 2 RTL (reworked)
//
// 32-bit down-counter.  Writing LOAD reloads the counter and clears the
// expired flag (this is the "pet").  Enabling starts counting; when the
// counter reaches zero the block latches EXPIRED, raises irq and deasserts
// reset_n_out until the next pet.
//
// Registers (4-byte offsets):
//   0x00 LOAD    RW  reload value / pet
//   0x04 CTRL    RW  bit0 enable, bit1 reset enable
//   0x08 STATUS  RO  bit0 expired
//   0x0C KEY     WO  0x5A5A_0001 locks CTRL until the next reset
//------------------------------------------------------------------------------
module watchdog (
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
  output logic         irq,
  output logic         reset_n_out
);

  logic [31:0] load, count;
  logic        enable, reset_en, expired, locked;

  // A write that reloads the counter: LOAD, or a CTRL write that enables it.
  // The count-down below must not run on such a cycle, otherwise the
  // nonblocking assignment from the write is overwritten by `count - 1` and
  // the reload is lost (a pet would not restart the period).
  wire reload = penable && pwrite &&
                ((paddr[11:2] == 10'd0) ||
                 ((paddr[11:2] == 10'd1) && pwdata[0]));

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      count    <= 32'd0;
      load     <= 32'd0;
      enable   <= 1'b0;
      reset_en <= 1'b0;
      expired  <= 1'b0;
      locked   <= 1'b0;
    end else begin
      if (penable && pwrite) begin
        case (paddr[11:2])
          10'd0: begin
            load    <= pwdata;
            count   <= pwdata;
            expired <= 1'b0;
          end
          10'd1: if (!locked) begin
                   enable   <= pwdata[0];
                   reset_en <= pwdata[1];
                   if (pwdata[0]) count <= load;
                 end
          10'd3: if (pwdata == 32'h5A5A_0001) locked <= 1'b1;
          default: ;
        endcase
      end

      if (enable && !expired && !reload) begin
        if (count == 32'd0) expired <= 1'b1;
        else                count   <= count - 32'd1;
      end
    end
  end

  assign irq         = expired;
  assign reset_n_out = ~(expired && reset_en);

  always_comb begin
    case (paddr[11:2])
      10'd0: prdata = load;
      10'd1: prdata = {29'd0, locked, reset_en, enable};
      10'd2: prdata = {31'd0, expired};
      10'd3: prdata = {31'd0, locked};
      default: prdata = 32'd0;
    endcase
  end

  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule
