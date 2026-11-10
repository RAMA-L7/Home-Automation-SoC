//------------------------------------------------------------------------------
// Home-Automation-SoC — SPI Master (APB)
// Stage 2 RTL (reworked — was a non-functional stub)
//
// Mode 0 (CPOL=0, CPHA=0) 8-bit master, MSB first, programmable clock divider.
//
// Registers (4-byte offsets):
//   0x00 CTRL    RW  bit0 enable, bit1 CS hold (keep CS asserted), bit2 loopback
//   0x04 DATA    RW  TX byte (write) / RX byte (read)
//   0x08 CMD     WO  bit0 start transfer (clears status done)
//   0x0C STATUS  RO  bit0 busy, bit1 done
//   0x10 CLKDIV  RW  half-period in pclk cycles (default 8)
//
// sck = pclk / (2 * (CLKDIV+1))
//------------------------------------------------------------------------------
module spi_ctrl (
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
  output logic         spi_sck,
  output logic         spi_mosi,
  input  logic         spi_miso,
  output logic         spi_cs_n,
  output logic         irq
);

  logic        enable, cs_hold, loopback;
  logic [7:0]  tx_data, rx_data, shift;
  logic [15:0] clkdiv;
  logic        busy, done;
  logic [2:0]  bit_cnt;
  logic [15:0] half_cnt;

  typedef enum logic [2:0] {SPI_IDLE, SPI_ASSERT, SPI_RISE, SPI_FALL, SPI_DONE} st_e;
  st_e state, state_n;

  logic sck_r, cs_n_r, mosi_r;

  assign spi_sck  = sck_r;
  assign spi_cs_n = cs_n_r;
  assign spi_mosi = mosi_r;

  wire mosi_sample = loopback ? mosi_r : spi_miso;

  //--------------------------------------------------------------------------
  // Next state
  //--------------------------------------------------------------------------
  always_comb begin
    state_n = state;
    case (state)
      SPI_IDLE:   if (busy) state_n = SPI_ASSERT;
      SPI_ASSERT: state_n = SPI_RISE;
      SPI_RISE:   if (half_cnt == 16'd0) state_n = SPI_FALL;
      SPI_FALL:   if (half_cnt == 16'd0) begin
                    if (bit_cnt == 3'd7) state_n = SPI_DONE;
                    else                   state_n = SPI_RISE;
                  end
      SPI_DONE:   state_n = SPI_IDLE;
      default:    state_n = SPI_IDLE;
    endcase
  end

  //--------------------------------------------------------------------------
  // Datapath
  //--------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      state    <= SPI_IDLE;
      sck_r    <= 1'b0;
      cs_n_r   <= 1'b1;
      mosi_r   <= 1'b0;
      shift    <= 8'd0;
      rx_data  <= 8'd0;
      bit_cnt  <= 3'd0;
      half_cnt <= 16'd0;
      busy     <= 1'b0;
      done     <= 1'b0;
      enable   <= 1'b0;
      cs_hold  <= 1'b0;
      loopback <= 1'b0;
      tx_data  <= 8'd0;
      clkdiv   <= 16'd8;
    end else begin
      state <= state_n;

      if (penable && pwrite) begin
        case (paddr[11:2])
          10'd0: begin enable <= pwdata[0]; cs_hold <= pwdata[1]; loopback <= pwdata[2]; end
          10'd1: tx_data <= pwdata[7:0];
          10'd2: if (pwdata[0] && enable) begin
                   busy    <= 1'b1;
                   done    <= 1'b0;
                   shift   <= tx_data;
                   bit_cnt <= 3'd0;
                 end
          10'd4: clkdiv <= pwdata[15:0];
          default: ;
        endcase
      end

      case (state)
        SPI_IDLE: begin
          sck_r <= 1'b0;
          if (cs_hold) cs_n_r <= 1'b0; else cs_n_r <= 1'b1;
        end
        SPI_ASSERT: begin
          cs_n_r   <= 1'b0;
          sck_r    <= 1'b0;
          mosi_r   <= shift[7];
          half_cnt <= clkdiv;
        end
        SPI_RISE: begin
          sck_r <= 1'b1;
          if (half_cnt == 16'd0) half_cnt <= clkdiv;
          else                   half_cnt <= half_cnt - 16'd1;
        end
        SPI_FALL: begin
          sck_r <= 1'b0;
          if (half_cnt == 16'd0) begin
            shift   <= {shift[6:0], mosi_sample};
            mosi_r  <= shift[6];
            half_cnt<= clkdiv;
            if (bit_cnt == 3'd7) begin
              rx_data <= {shift[6:0], mosi_sample};
              busy    <= 1'b0;
              done    <= 1'b1;
            end else begin
              bit_cnt <= bit_cnt + 3'd1;
            end
          end else begin
            half_cnt <= half_cnt - 16'd1;
          end
        end
        SPI_DONE: begin
          sck_r <= 1'b0;
          if (!cs_hold) cs_n_r <= 1'b1;
        end
        default: ;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // APB read
  //--------------------------------------------------------------------------
  always_comb begin
    case (paddr[11:2])
      10'd0: prdata = {29'd0, loopback, cs_hold, enable};
      10'd1: prdata = {24'd0, rx_data};
      10'd3: prdata = {30'd0, done, busy};
      10'd4: prdata = {16'd0, clkdiv};
      default: prdata = 32'd0;
    endcase
  end

  assign irq     = done;
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule
