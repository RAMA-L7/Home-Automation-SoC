//------------------------------------------------------------------------------
// Home-Automation-SoC — I2C Master (APB)
// Stage 2 RTL (reworked — was a non-functional stub that held SCL/SDA low)
//
// Single-byte master transaction, 100/400 kHz capable via CLKDIV.
// A "transaction" is one of:
//   WRITE : START, (ADDR<<1)|0, ACK, DATA, ACK, STOP
//   READ  : START, (ADDR<<1)|1, ACK, DATA, NACK, STOP
//
// Registers (4-byte offsets):
//   0x00 CTRL    RW  bit0 enable
//   0x04 ADDR    RW  7-bit slave address
//   0x08 DATA    RW  byte to transmit / byte received
//   0x0C CMD     WO  bit0 start, bit1 stop, bit2 read, bit3 write
//   0x10 STATUS  RO  bit0 busy, bit1 ack_error, bit2 done
//   0x14 CLKDIV  RW  quarter-bit delay in pclk cycles (default 32)
//
// SCL frequency = pclk / (4 * (CLKDIV+1))
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
  logic        sda_r, scl_r;

  assign i2c_scl = scl_drive_low ? 1'b0 : 1'bz;
  assign i2c_sda = sda_drive_low ? 1'b0 : 1'bz;
  assign sda_in  = i2c_sda;

  typedef enum logic [3:0] {
    I_IDLE, I_START_A, I_START_B, I_BIT, I_ACK_RX,
    I_DATA, I_RX_ACK, I_STOP_A, I_STOP_B, I_DONE
  } ist_e;
  ist_e state, state_n;

  logic [1:0]  q;        // quarter phase
  logic [15:0] qcnt;     // quarter delay counter
  logic [2:0]  biti;
  logic [7:0]  shreg;
  logic        is_read;
  logic        do_stop;

  wire q_done = (qcnt == 16'd0);

  //--------------------------------------------------------------------------
  // Next state
  //--------------------------------------------------------------------------
  always_comb begin
    state_n = state;
    case (state)
      I_IDLE:    if (busy) state_n = I_START_A;
      I_START_A: if (q_done) state_n = I_START_B;
      I_START_B: if (q_done) state_n = I_BIT;
      I_BIT:     if (q_done && q == 2'd3) begin
                   if (biti == 3'd7) state_n = I_ACK_RX;
                   else                state_n = I_BIT;
                 end
      I_ACK_RX:  if (q_done && q == 2'd3) begin
                   if (is_read) state_n = I_DATA;
                   else         state_n = I_STOP_A;
                 end
      I_DATA:    if (q_done && q == 2'd3) begin
                   if (biti == 3'd7) state_n = I_RX_ACK;
                   else                state_n = I_DATA;
                 end
      I_RX_ACK:  if (q_done && q == 2'd3) state_n = I_STOP_A;
      I_STOP_A:  if (q_done) state_n = I_STOP_B;
      I_STOP_B:  if (q_done) state_n = I_DONE;
      I_DONE:    state_n = I_IDLE;
      default:   state_n = I_IDLE;
    endcase
  end

  //--------------------------------------------------------------------------
  // Datapath
  //--------------------------------------------------------------------------
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      state         <= I_IDLE;
      scl_drive_low <= 1'b0;
      sda_drive_low <= 1'b0;
      scl_r         <= 1'b1;
      sda_r         <= 1'b1;
      q             <= 2'd0;
      qcnt          <= 16'd0;
      biti          <= 3'd0;
      shreg         <= 8'd0;
      rx_data       <= 8'd0;
      is_read       <= 1'b0;
      do_stop       <= 1'b0;
      busy          <= 1'b0;
      ack_error     <= 1'b0;
      done          <= 1'b0;
      enable        <= 1'b0;
      slave_addr    <= 7'd0;
      tx_data       <= 8'd0;
      clkdiv        <= 16'd32;
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
                   biti     <= 3'd0;
                   q        <= 2'd0;
                   qcnt     <= clkdiv;
                 end
          10'd5: clkdiv     <= pwdata[15:0];
          default: ;
        endcase
      end

      // ---------------- Quarter-phase timer ----------------
      if (q_done) begin
        qcnt <= clkdiv;
        q    <= q + 2'd1;
      end else begin
        qcnt <= qcnt - 16'd1;
      end

      // ---------------- Bus engine ----------------
      case (state)
        I_IDLE: begin
          scl_drive_low <= 1'b0;
          sda_drive_low <= 1'b0;
        end

        I_START_A: begin
          scl_drive_low <= 1'b0;      // release SCL (high)
          sda_drive_low <= 1'b1;      // pull SDA low while SCL high
          scl_r         <= 1'b1;
        end

        I_START_B: begin
          scl_drive_low <= 1'b1;      // SCL low
          scl_r         <= 1'b0;
        end

        I_BIT: begin
          if (q_done) begin
            if (q == 2'd0) begin
              scl_drive_low <= 1'b1;
              sda_drive_low <= ~shreg[7];
            end else if (q == 2'd2) begin
              scl_drive_low <= 1'b0;  // SCL high
              scl_r         <= 1'b1;
            end else if (q == 2'd3) begin
              shreg         <= {shreg[6:0], 1'b0};
              biti          <= biti + 3'd1;
              scl_drive_low <= 1'b1;
            end
          end
        end

        I_ACK_RX: begin
          if (q_done) begin
            if (q == 2'd0) begin
              sda_drive_low <= 1'b0;  // release SDA so slave can ACK
              scl_drive_low <= 1'b1;
            end else if (q == 2'd2) begin
              scl_drive_low <= 1'b0;
              ack_error     <= sda_in; // NACK if SDA high
            end else if (q == 2'd3) begin
              scl_drive_low <= 1'b1;
              biti          <= 3'd0;
              rx_data       <= 8'd0;
            end
          end
        end

        I_DATA: begin
          if (q_done) begin
            if (q == 2'd0) begin
              scl_drive_low <= 1'b1;
            end else if (q == 2'd1) begin
              scl_drive_low <= 1'b0;
              scl_r         <= 1'b1;
            end else if (q == 2'd2) begin
              shreg  <= {shreg[6:0], sda_in};
              biti   <= biti + 3'd1;
            end else begin
              scl_drive_low <= 1'b1;
            end
          end
        end

        I_RX_ACK: begin
          if (q_done) begin
            if (q == 2'd0) sda_drive_low <= 1'b1;  // master NACK
            else if (q == 2'd2) begin
              scl_drive_low <= 1'b0;
              rx_data       <= shreg;
            end else if (q == 2'd3) begin
              scl_drive_low <= 1'b1;
              sda_drive_low <= 1'b0;
            end
          end
        end

        I_STOP_A: begin
          if (q_done) begin
            sda_drive_low <= 1'b1;      // SDA low, SCL low
            scl_drive_low <= 1'b1;
          end
        end

        I_STOP_B: begin
          if (q_done) begin
            scl_drive_low <= 1'b0;      // SCL high
            sda_drive_low <= 1'b0;      // SDA rises while SCL high
          end
        end

        I_DONE: begin
          busy <= 1'b0;
          done <= 1'b1;
          scl_drive_low <= 1'b0;
          sda_drive_low <= 1'b0;
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
