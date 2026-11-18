`timescale 1ns/1ps
//------------------------------------------------------------------------------
// I2C master transaction testbench with a reactive slave model.
//
// Verifies the complete transfers that the previous RTL did not implement:
//   1. WRITE : START, 0xA0 (addr<<1|W), ACK, 0x5A (DATA), ACK, STOP
//   2. READ  : START, 0xA1 (addr<<1|R), ACK, 0x3C (slave data), NACK, STOP
//   3. NACK  : slave refuses the address -> ack_error set, no DATA byte sent
//
// The slave model ACKs each byte, returns a fixed byte on reads, and records
// the bytes the master actually put on the bus.  A NACK is only correct if the
// master RELEASES SDA (it is pulled high); the model samples that bit.
//------------------------------------------------------------------------------
module tb_i2c_xfer;

  reg         pclk = 0;
  reg         presetn = 0;
  reg         penable = 0, pwrite = 0;
  reg  [31:0] paddr = 0, pwdata = 0;
  reg  [3:0]  pstrb = 0;
  wire [31:0] prdata;
  wire        pready, pslverr, irq;
  wire        scl, sda;

  i2c_ctrl dut (
    .pclk(pclk), .presetn(presetn),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata), .pready(pready), .pslverr(pslverr),
    .i2c_scl(scl), .i2c_sda(sda), .irq(irq)
  );

  pullup (scl);
  pullup (sda);

  always #5 pclk = ~pclk;

  //--------------------------- slave model --------------------------------
  reg        slave_low = 0;
  assign sda = slave_low ? 1'b0 : 1'bz;

  reg  scl_p = 1, sda_p = 1;
  wire scl_rise = scl & ~scl_p;
  wire scl_fall = ~scl & scl_p;

  reg  [7:0] rx_byte = 0;
  reg  [7:0] tx_byte = 8'h3C;
  integer    bitcnt = 0;
  reg        ack_done = 0;
  reg        in_frame = 0, addr_done = 0, is_read = 0;
  reg        nack_addr = 0;          // model refuses the address when set

  reg  [7:0] captured_addr = 0;
  reg  [7:0] captured_data = 0;
  integer    data_bytes = 0;
  integer    start_count = 0, stop_count = 0;
  integer    invalid_stop = 0;   // SDA rose while SCL was still low (not a STOP)
  reg        nack_seen = 0;

  always @(posedge pclk) begin
    scl_p <= scl;
    sda_p <= sda;
  end

  always @(posedge pclk) begin
    if (!presetn) begin
      bitcnt <= 0; ack_done <= 0; in_frame <= 0; addr_done <= 0;
      slave_low <= 0; is_read <= 0;
    end else begin
      // START: SDA falls while SCL is high.  STOP: SDA rises while SCL high.
      if (scl && sda_p && !sda) begin
        in_frame  <= 1'b1;
        bitcnt    <= 0;
        ack_done  <= 1'b0;
        addr_done <= 1'b0;
        slave_low <= 1'b0;
        start_count <= start_count + 1;
      end
      // STOP: SDA rises while SCL is high.  SCL must already have been high at
      // the previous sample, i.e. there has to be a real SCL-high/SDA-low
      // interval first.  Releasing both lines in the same cycle is not a STOP
      // (I2C requires a setup time from SCL high to the SDA rising edge), so
      // that case is counted separately and fails the test.
      if (scl_p && scl && !sda_p && sda) begin
        in_frame  <= 1'b0;
        slave_low <= 1'b0;
        stop_count <= stop_count + 1;
      end
      if (!scl_p && scl && !sda_p && sda) invalid_stop <= invalid_stop + 1;

      if (in_frame) begin
        if (scl_rise) begin
          if (bitcnt < 8) begin
            rx_byte <= {rx_byte[6:0], sda};
            bitcnt  <= bitcnt + 1;
          end else if (addr_done && is_read) begin
            nack_seen <= sda;          // master must release SDA for NACK
          end
        end

        if (scl_fall) begin
          if (bitcnt == 8) begin
            if (!ack_done) begin
              // Acknowledge slot.  Read data is terminated by a master NACK,
              // so the model releases SDA there; otherwise it ACKs.
              if (addr_done && is_read) slave_low <= 1'b0;
              else if (!addr_done && nack_addr) slave_low <= 1'b0; // refuse addr
              else slave_low <= 1'b1;
              ack_done <= 1'b1;
            end else begin
              // Byte complete.
              bitcnt    <= 0;
              ack_done  <= 1'b0;
              slave_low <= 1'b0;
              if (!addr_done) begin
                captured_addr <= rx_byte;
                addr_done     <= 1'b1;
                is_read       <= rx_byte[0];
                // A read must start driving its first data bit immediately;
                // otherwise the master samples a floating (high) bit.
                if (rx_byte[0]) slave_low <= ~tx_byte[7];
              end else if (!is_read) begin
                captured_data <= rx_byte;
                data_bytes    <= data_bytes + 1;
              end
            end
          end else if (is_read && addr_done) begin
            slave_low <= ~tx_byte[7 - bitcnt];   // drive read data MSB first
          end
        end
      end
    end
  end

  //--------------------------- APB helpers --------------------------------
  task apb_write(input [31:0] addr, input [31:0] data);
    begin
      penable = 1; pwrite = 1; paddr = addr; pwdata = data; pstrb = 4'hF;
      @(posedge pclk);
      while (!pready) @(posedge pclk);
      @(posedge pclk);
      penable = 0; pwrite = 0;
      @(posedge pclk);
    end
  endtask

  task apb_read(input [31:0] addr, output [31:0] data);
    begin
      penable = 1; pwrite = 0; paddr = addr; pstrb = 4'h0;
      @(posedge pclk);
      while (!pready) @(posedge pclk);
      data = prdata;
      @(posedge pclk);
      penable = 0;
      @(posedge pclk);
    end
  endtask

  task wait_done;
    output [31:0] status;
    integer guard;
    begin
      guard = 0;
      status = 0;
      while (!status[2] && guard < 200000) begin
        apb_read(32'h5000_2010, status);
        guard = guard + 1;
      end
      if (guard >= 200000) $fatal(1, "timeout waiting for done");
    end
  endtask

  task clear_monitor;
    begin
      captured_addr = 0; captured_data = 0; data_bytes = 0;
      nack_seen = 0; start_count = 0; stop_count = 0; invalid_stop = 0; rx_byte = 0;
      bitcnt = 0; ack_done = 0; in_frame = 0; addr_done = 0; is_read = 0;
      slave_low = 0;
    end
  endtask

  //--------------------------- test ---------------------------------------
  integer errors = 0;
  reg [31:0] status;

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("build/sim/tb_i2c_xfer.vcd");
      $dumpvars(0, tb_i2c_xfer);
    end

    presetn = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (5) @(posedge pclk);

    apb_write(32'h5000_2000, 32'h1);          // CTRL.enable = 1
    apb_write(32'h5000_2014, 32'h2);          // CLKDIV = 2 (fast sim)
    apb_write(32'h5000_2004, 32'h50);         // slave address 0x50

    // ---------------- 1. WRITE: addr, data, ACK, STOP ----------------
    clear_monitor();
    apb_write(32'h5000_2008, 32'h5A);         // DATA = 0x5A
    apb_write(32'h5000_200C, 32'h9);          // CMD = start | write
    wait_done(status);
    #100;

    $display("WRITE: addr=%02X data=%02X bytes=%0d ack_error=%b stops=%0d",
             captured_addr, captured_data, data_bytes, status[1], stop_count);
    if (captured_addr !== 8'hA0) begin
      $display("  FAIL: expected address byte 0xA0"); errors = errors + 1;
    end
    if (captured_data !== 8'h5A || data_bytes != 1) begin
      $display("  FAIL: DATA byte was not transmitted"); errors = errors + 1;
    end
    if (status[1] !== 1'b0) begin
      $display("  FAIL: unexpected ack_error"); errors = errors + 1;
    end
    if (stop_count < 1) begin
      $display("  FAIL: no STOP condition"); errors = errors + 1;
    end
    if (invalid_stop != 0) begin
      $display("  FAIL: invalid STOP (SCL and SDA released in the same cycle)");
      errors = errors + 1;
    end
    if (errors == 0) $display("  PASS: write transaction");

    // ---------------- 2. READ: addr|R, data, NACK, STOP --------------
    clear_monitor();
    apb_write(32'h5000_200C, 32'h5);          // CMD = start | read
    wait_done(status);
    #100;

    $display("READ : addr=%02X rx=%02X nack_seen=%b stops=%0d",
             captured_addr, prdata, nack_seen, stop_count);
    apb_read(32'h5000_2008, status);
    $display("       DATA register = %02X", status[7:0]);
    if (captured_addr !== 8'hA1) begin
      $display("  FAIL: expected address byte 0xA1"); errors = errors + 1;
    end
    if (status[7:0] !== 8'h3C) begin
      $display("  FAIL: received byte mismatch (want 0x3C)"); errors = errors + 1;
    end
    if (nack_seen !== 1'b1) begin
      $display("  FAIL: master did not release SDA for NACK"); errors = errors + 1;
    end
    if (stop_count < 1) begin
      $display("  FAIL: no STOP condition"); errors = errors + 1;
    end
    if (invalid_stop != 0) begin
      $display("  FAIL: invalid STOP (SCL and SDA released in the same cycle)");
      errors = errors + 1;
    end

    // ---------------- 3. NACK address: abort, no data ---------------
    clear_monitor();
    nack_addr = 1;
    apb_write(32'h5000_200C, 32'h9);          // CMD = start | write
    wait_done(status);
    #100;
    nack_addr = 0;

    $display("NACK : addr=%02X data_bytes=%0d ack_error=%b", captured_addr, data_bytes, status[1]);
    if (status[1] !== 1'b1) begin
      $display("  FAIL: ack_error not set on address NACK"); errors = errors + 1;
    end
    if (data_bytes != 0) begin
      $display("  FAIL: DATA byte transmitted after address NACK"); errors = errors + 1;
    end
    if (stop_count < 1) begin
      $display("  FAIL: no STOP after NACK abort"); errors = errors + 1;
    end

    if (errors == 0) begin
      $display("TB_I2C_XFER: ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "TB_I2C_XFER: %0d FAILURES", errors);
    end
  end

endmodule
