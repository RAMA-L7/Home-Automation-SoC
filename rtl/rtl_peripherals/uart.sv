//------------------------------------------------------------------------------
// Home-Automation-SoC — UART Controller (APB, 16550 subset)
// Stage 2 RTL (reworked)
//
// Registers (4-byte offsets):
//   0x00 THR/RBR  RW/RO  transmit holding / receive buffer
//   0x00 DLL      RW     divisor latch low  (DLAB=1)
//   0x04 IER      RW     interrupt enable (bit0 RDA, bit1 THRE)
//   0x04 DLM      RW     divisor latch high (DLAB=1)
//   0x08 FCR      WO     FIFO control (accepted, no FIFO implemented)
//   0x0C LCR      RW     bit7 = DLAB
//   0x10 MCR      RW     ignored
//   0x14 LSR      RO     bit0 RDA, bit1 OE (receive overrun), bit3 FE
//                        (framing error), bit5 THRE, bit6 TEMT
//                        OE/FE are sticky; cleared by reading LSR
//   0x18 MSR      RO     always 0
//   0x1C SPR      RW     scratch
//
// Deliberate limitations (reported by the testbench, not hidden):
//   * No FIFO: FCR reads 0x01, one byte of receive holding.
//   * No parity generation or checking: LCR parity bits are stored, not used.
//   * THR is one deep.  A write while a byte is still waiting to be loaded
//     into the shift register is ignored rather than silently replacing the
//     queued byte; THRE reads 0 in that state, so polled software never hits it.
//
// Bit timing: one bit per `div` clocks, where div defaults to
// CLK_FREQ/BAUD and may be overridden through DLL/DLM.
//------------------------------------------------------------------------------
module uart #(
  parameter CLK_FREQ = 50_000_000,
  parameter BAUD     = 115200
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
  output logic         uart_tx,
  input  logic         uart_rx,
  output logic         irq
);

  localparam int RESET_DIV = (CLK_FREQ / BAUD) < 1 ? 1 : (CLK_FREQ / BAUD);

  logic [15:0] div, div_cnt;
  logic [7:0]  thr, rbr, ier, lcr, mcr, spr, fcr;
  logic        dlab;
  logic        rda;
  logic        oe, fe;          // sticky receive overrun / framing error

  //--------------------------------------------------------------------------
  // Baud / bit-tick generator
  //--------------------------------------------------------------------------
  // A programmed divisor of zero would make the baud counter walk 65,536
  // clocks per bit instead of running at the configured rate.  The effective
  // divisor is therefore clamped to 1; the register still reads back what was
  // written so software can see its own invalid configuration.
  wire [15:0] div_eff = (div == 16'd0) ? 16'd1 : div;
  wire bit_tick = (div_cnt == 16'd0);

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      div     <= 16'(RESET_DIV);
      div_cnt <= 16'd0;
    end else begin
      if (div_cnt == 16'd0) div_cnt <= div_eff - 16'd1;
      else                  div_cnt <= div_cnt - 16'd1;
    end
  end

  //--------------------------------------------------------------------------
  // Transmitter
  //--------------------------------------------------------------------------
  typedef enum logic [1:0] {TX_IDLE, TX_START, TX_DATA, TX_STOP} tx_state_e;
  tx_state_e  tx_state;
  logic [7:0] tx_shift;
  logic [2:0] tx_bit;
  logic       tx_pending;   // THR written, byte waiting to start
  logic       thre, temt;

  assign thre = (tx_state == TX_IDLE) && !tx_pending;
  assign temt = (tx_state == TX_IDLE) && !tx_pending;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      tx_state   <= TX_IDLE;
      tx_shift   <= 8'hFF;
      tx_bit     <= 3'd0;
      uart_tx    <= 1'b1;
      tx_pending <= 1'b0;
      thr        <= 8'h00;
    end else begin
      // THR write.  While a byte is still queued for the shift register the
      // write is dropped: the alternative (which this block previously did)
      // replaced the queued byte with no indication, i.e. silent data loss.
      if (penable && pwrite && paddr[11:2] == 10'd0 && !dlab && !tx_pending) begin
        thr        <= pwdata[7:0];
        tx_pending <= 1'b1;
      end

      case (tx_state)
        TX_IDLE: begin
          uart_tx <= 1'b1;
          if (tx_pending && bit_tick) begin
            tx_shift   <= thr;
            tx_pending <= 1'b0;
            uart_tx    <= 1'b0;          // start bit
            tx_bit     <= 3'd0;
            tx_state   <= TX_DATA;
          end
        end
        TX_DATA: begin
          if (bit_tick) begin
            uart_tx  <= tx_shift[0];
            tx_shift <= {1'b1, tx_shift[7:1]};
            if (tx_bit == 3'd7) tx_state <= TX_STOP;
            else               tx_bit   <= tx_bit + 3'd1;
          end
        end
        TX_STOP: begin
          if (bit_tick) begin
            uart_tx  <= 1'b1;
            tx_state <= TX_IDLE;
          end
        end
        default: tx_state <= TX_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // Receiver: 16x oversampling, sample mid-bit
  //--------------------------------------------------------------------------
  typedef enum logic [1:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state_e;
  rx_state_e  rx_state;
  logic [15:0] rx_cnt;         // bit-period countdown
  logic [2:0]  rx_bit;
  logic [7:0]  rx_shift;
  logic        rx_sync1, rx_sync2;
  wire  [15:0] rx_half = (div_eff >> 1) == 16'd0 ? 16'd1 : (div_eff >> 1);

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      rx_sync1 <= 1'b1;
      rx_sync2 <= 1'b1;
    end else begin
      rx_sync1 <= uart_rx;
      rx_sync2 <= rx_sync1;
    end
  end

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      rx_state  <= RX_IDLE;
      rx_cnt    <= 16'd0;
      rx_bit    <= 3'd0;
      rx_shift  <= 8'd0;
      rbr       <= 8'd0;
      rda       <= 1'b0;
      oe        <= 1'b0;
      fe        <= 1'b0;
    end else begin
      // Reading RBR clears RDA; reading LSR clears the sticky error flags.
      if (penable && !pwrite && paddr[11:2] == 10'd0 && !dlab) rda <= 1'b0;
      if (penable && !pwrite && paddr[11:2] == 10'd5) begin oe <= 1'b0; fe <= 1'b0; end

      case (rx_state)
        RX_IDLE: begin
          if (!rx_sync2) begin
            rx_state <= RX_START;
            rx_cnt   <= rx_half - 16'd1;     // align to middle of start bit
          end
        end
        RX_START: begin
          if (rx_cnt == 16'd0) begin
            if (!rx_sync2) begin
              rx_state <= RX_DATA;
              rx_cnt   <= div_eff - 16'd1;
              rx_bit   <= 3'd0;
            end else begin
              rx_state <= RX_IDLE;           // glitch, not a start bit
            end
          end else begin
            rx_cnt <= rx_cnt - 16'd1;
          end
        end
        RX_DATA: begin
          if (rx_cnt == 16'd0) begin
            rx_shift <= {rx_sync2, rx_shift[7:1]};
            rx_cnt   <= div_eff - 16'd1;
            if (rx_bit == 3'd7) begin
              rx_bit   <= 3'd0;
              rx_state <= RX_STOP;
            end else begin
              rx_bit <= rx_bit + 3'd1;
            end
          end else begin
            rx_cnt <= rx_cnt - 16'd1;
          end
        end
        RX_STOP: begin
          if (rx_cnt == 16'd0) begin
            // A byte finishing while the previous one has not been read is an
            // overrun: the unread byte is preserved and the new one dropped,
            // with the sticky flag reporting the loss.
            if (!rda) begin
              rbr <= rx_shift;
              rda <= 1'b1;
            end else begin
              oe  <= 1'b1;
            end
            // The stop bit must be high; a low stop bit is a framing error.
            if (!rx_sync2) fe <= 1'b1;
            rx_state <= RX_IDLE;
          end else begin
            rx_cnt <= rx_cnt - 16'd1;
          end
        end
        default: rx_state <= RX_IDLE;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // Status / interrupts
  //--------------------------------------------------------------------------
  // 16550 LSR layout: bit0 DR, bit1 OE, bit2 PE, bit3 FE, bit4 BI,
  // bit5 THRE, bit6 TEMT.  The previous concatenation put DR in bit1 and left
  // bit0 always zero, so polled readers testing `LSR & 1` never saw data.
  wire [7:0] lsr = {1'b0, temt, thre, 1'b0, fe, 1'b0, oe, rda};

  assign irq = (ier[0] & rda) | (ier[1] & thre);

  //--------------------------------------------------------------------------
  // APB read
  //--------------------------------------------------------------------------
  always_comb begin
    case (paddr[11:2])
      10'd0: prdata = dlab ? {16'd0, div}      : {24'd0, rbr};
      10'd1: prdata = dlab ? {16'd0, div[15:8]} : {24'd0, ier};
      10'd2: prdata = {24'd0, 8'h01};          // no FIFO
      10'd3: prdata = {24'd0, lcr};
      10'd4: prdata = {24'd0, mcr};
      10'd5: prdata = {24'd0, lsr};
      10'd6: prdata = 32'd0;
      10'd7: prdata = {24'd0, spr};
      default: prdata = 32'd0;
    endcase
  end

  //--------------------------------------------------------------------------
  // APB write
  //--------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      ier <= 8'd0; lcr <= 8'd0; mcr <= 8'd0; spr <= 8'd0;
      fcr <= 8'd0; dlab <= 1'b0;
    end else if (penable && pwrite) begin
      case (paddr[11:2])
        10'd0: if (dlab) div[7:0]   <= pwdata[7:0];
        10'd1: if (dlab) div[15:8]  <= pwdata[7:0];
               else      ier        <= pwdata[7:0];
        10'd2: fcr <= pwdata[7:0];
        10'd3: begin lcr <= pwdata[7:0]; dlab <= pwdata[7]; end
        10'd4: mcr <= pwdata[7:0];
        10'd7: spr <= pwdata[7:0];
        default: ;
      endcase
    end
  end

  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule
