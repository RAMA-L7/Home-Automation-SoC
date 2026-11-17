//------------------------------------------------------------------------------
// Home-Automation-SoC — I2C Master (APB)
// Stage 2 RTL
//
// Single-byte master transaction, 100/400 kHz capable via CLKDIV.
// A "transaction" is one of:
//   WRITE : START, (ADDR<<1)|0, ACK, DATA, ACK, STOP
//   READ  : START, (ADDR<<1)|1, ACK, DATA, NACK, STOP
//
// Register map (4-byte offsets):
//   0x00 CTRL    RW  bit0 enable
//   0x04 ADDR    RW  7-bit slave address
//   0x08 DATA    RW  byte to transmit / byte received
//   0x0C CMD     WO  bit0 start, bit1 stop, bit2 read, bit3 write
//   0x10 STATUS  RO  bit0 busy, bit1 ack_error, bit2 done
//   0x14 CLKDIV  RW  quarter-bit delay in pclk cycles (default 32)
//
// SCL frequency = pclk / (4 * (CLKDIV+1))
//
// Correction notes (review findings):
//   * The write path used to jump from the address ACK straight to STOP, so
//     DATA was never transmitted.  `byte_idx` now tracks address (0) vs data
//     (1): after the address ACK the engine loads DATA into the shift register
//     and clocks out one more byte.
//   * The read termination used to drive SDA LOW while calling it a NACK.  A
//     NACK is RELEASING SDA (the bus pull-up makes it high); the acknowledge
//     phase of I_RX_ACK now drives nothing.
//   * SCL/SDA are now combinational functions of (state, quarter).  Previously
//     they were registered from the quarter branches, so every output was one
//     clock late: the first data bit was never driven (SDA stayed low from the
//     START condition) and the receive sample point was misaligned.
//------------------------------------------------------------------------------
module i2c_ctrl (
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
  inout  wire          i2c_scl,
  inout  wire          i2c_sda,
  output logic         irq
);

  logic        enable;
  logic [6:0]  slave_addr;
  logic [7:0]  tx_data, rx_data;
  logic [15:0] clkdiv;
  logic        busy, ack_error, done;

  logic        scl_drive_low, sda_drive_low;
  logic        sda_in;

  assign i2c_scl = scl_drive_low ? 1'b0 : 1'bz;
  assign i2c_sda = sda_drive_low ? 1'b0 : 1'bz;
  assign sda_in  = i2c_sda;

  typedef enum logic [3:0] {
    I_IDLE, I_START_A, I_START_B, I_TX_BIT, I_ACK_RX,
    I_RX_BIT, I_RX_ACK, I_STOP_A, I_STOP_B, I_DONE
  } ist_e;
  ist_e state, state_n;

  logic [1:0]  q;        // quarter phase 0..3
  logic [15:0] qcnt;     // quarter delay counter
  logic [2:0]  biti;
  logic [7:0]  shreg;
  logic        is_read;
  logic        do_stop;
  logic        byte_idx; // 0 = address byte, 1 = data byte

  wire q_done = (qcnt == 16'd0);

  //--------------------------------------------------------------------------
  // Next state
  //--------------------------------------------------------------------------
  always_comb begin
    state_n = state;
    case (state)
      I_IDLE:    if (busy) state_n = I_START_A;

      I_START_A: if (q_done) state_n = I_START_B;
      I_START_B: if (q_done) state_n = I_TX_BIT;

      // Transmit one byte (address or data), MSB first.
      I_TX_BIT:  if (q_done && q == 2'd3) begin
                   if (biti == 3'd7) state_n = I_ACK_RX;
                   else              state_n = I_TX_BIT;
                 end

      // Slave acknowledge.  A NACK aborts the transfer.
      I_ACK_RX:  if (q_done && q == 2'd3) begin
                   if (ack_error)      state_n = I_STOP_A;
                   else if (is_read)   state_n = I_RX_BIT;
                   else if (!byte_idx) state_n = I_TX_BIT;   // send DATA byte
                   else                state_n = I_STOP_A;
                 end

      // Receive one byte, MSB first.
      I_RX_BIT:  if (q_done && q == 2'd3) begin
                   if (biti == 3'd7) state_n = I_RX_ACK;
                   else              state_n = I_RX_BIT;
                 end

      // Master NACK (SDA released high), then terminate.
      I_RX_ACK:  if (q_done && q == 2'd3) state_n = I_STOP_A;

      I_STOP_A:  if (q_done) state_n = I_STOP_B;
      I_STOP_B:  if (q_done) state_n = I_DONE;
      I_DONE:    state_n = I_IDLE;
      default:   state_n = I_IDLE;
    endcase
  end

  //--------------------------------------------------------------------------
  // Bus outputs — combinational decode of (state, quarter).
  //   quarter 0 : SCL low, SDA set up
  //   quarter 1 : SCL low, SDA stable
  //   quarter 2 : SCL high (bit is sampled here)
  //   quarter 3 : SCL low, advance to the next bit
  //--------------------------------------------------------------------------
  always_comb begin
    scl_drive_low = 1'b0;
    sda_drive_low = 1'b0;
    case (state)
      I_IDLE, I_DONE: begin
        scl_drive_low = 1'b0;          // bus released
        sda_drive_low = 1'b0;
      end
      I_START_A: begin
        scl_drive_low = 1'b0;          // SCL high
        sda_drive_low = 1'b1;          // SDA falling while SCL high -> START
      end
      I_START_B: begin
        scl_drive_low = 1'b1;          // SCL low
        sda_drive_low = 1'b0;
      end
      I_TX_BIT: begin
        scl_drive_low = (q != 2'd2);
        sda_drive_low = ~shreg[7];     // MSB first
      end
      I_ACK_RX: begin
        scl_drive_low = (q != 2'd2);
        sda_drive_low = 1'b0;          // released: slave drives ACK
      end
      I_RX_BIT: begin
        scl_drive_low = (q != 2'd2);
        sda_drive_low = 1'b0;          // released: slave drives data
      end
      I_RX_ACK: begin
        scl_drive_low = (q != 2'd2);
        sda_drive_low = 1'b0;          // released high == NACK
      end
      I_STOP_A: begin
        scl_drive_low = 1'b1;          // SCL low, SDA low
        sda_drive_low = 1'b1;
      end
      I_STOP_B: begin
        scl_drive_low = 1'b0;          // SCL high
        sda_drive_low = 1'b0;          // SDA rising while SCL high -> STOP
      end
      default: begin
        scl_drive_low = 1'b0;
        sda_drive_low = 1'b0;
      end
    endcase
  end

  //--------------------------------------------------------------------------
  // Datapath
  //--------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      state     <= I_IDLE;
      q         <= 2'd0;
      qcnt      <= 16'd0;
      biti      <= 3'd0;
      shreg     <= 8'd0;
      rx_data   <= 8'd0;
      is_read   <= 1'b0;
      do_stop   <= 1'b0;
      byte_idx  <= 1'b0;
      busy      <= 1'b0;
      ack_error <= 1'b0;
      done      <= 1'b0;
      enable    <= 1'b0;
      slave_addr<= 7'd0;
      tx_data   <= 8'd0;
      clkdiv    <= 16'd32;
    end else begin
      state <= state_n;

      // ---------------- APB register writes ----------------
      if (penable && pwrite) begin
        case (paddr[11:2])
          10'd0: enable     <= pwdata[0];
          10'd1: slave_addr <= pwdata[6:0];
          10'd2: tx_data    <= pwdata[7:0];
          10'd3: if (pwdata[0] && enable) begin
                   busy     <= 1'b1;
                   done     <= 1'b0;
                   ack_error<= 1'b0;
                   is_read  <= pwdata[2] && !pwdata[3];
                   do_stop  <= pwdata[1];
                   shreg    <= (pwdata[2] && !pwdata[3]) ? {slave_addr, 1'b1}
                                                         : {slave_addr, 1'b0};
                   byte_idx <= 1'b0;
                   biti     <= 3'd0;
                   q        <= 2'd0;
                   qcnt     <= clkdiv;
                 end
          10'd5: clkdiv     <= pwdata[15:0];
          default: ;
        endcase
      end

      // ---------------- Quarter-phase timer ----------------
      // Reset the quarter on a state change so every state starts at phase 0.
      if (state != state_n) begin
        q    <= 2'd0;
        qcnt <= clkdiv;
      end else if (q_done) begin
        qcnt <= clkdiv;
        q    <= q + 2'd1;
      end else begin
        qcnt <= qcnt - 16'd1;
      end

      // ---------------- Bit engine ----------------
      case (state)
        // Bit completed: shift and advance, or hand over to the ACK state.
        I_TX_BIT: if (q_done && q == 2'd3) begin
          shreg <= {shreg[6:0], 1'b0};
          biti  <= biti + 3'd1;         // wraps to 0 after the 8th bit
        end

        // Sample the slave acknowledge while SCL is high.
        I_ACK_RX: begin
          if (q_done && q == 2'd2) ack_error <= sda_in;
          if (q_done && q == 2'd3) begin
            biti <= 3'd0;
            if (!is_read && !byte_idx && !ack_error) begin
              // Address acknowledged -> transmit the DATA byte next.
              shreg    <= tx_data;
              byte_idx <= 1'b1;
            end
          end
        end

        // Sample the received bit while SCL is high; advance on the last
        // quarter so the next-state test still sees the pre-increment count.
        I_RX_BIT: begin
          if (q_done && q == 2'd2) shreg <= {shreg[6:0], sda_in};
          if (q_done && q == 2'd3) biti  <= biti + 3'd1;
        end

        // Master NACK: capture the byte while SCL is high.
        I_RX_ACK: if (q_done && q == 2'd2) rx_data <= shreg;

        I_DONE: begin
          busy <= 1'b0;
          done <= 1'b1;
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
      10'd0: prdata = {31'd0, enable};
      10'd1: prdata = {25'd0, slave_addr};
      10'd2: prdata = {24'd0, rx_data};
      10'd4: prdata = {29'd0, done, ack_error, busy};
      10'd5: prdata = {16'd0, clkdiv};
      default: prdata = 32'd0;
    endcase
  end

  assign irq     = done;
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule
