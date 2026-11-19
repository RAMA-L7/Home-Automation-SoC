`timescale 1ns/1ps
//------------------------------------------------------------------------------
// I2C bus-level timing verification (F10)
//
// The functional bench (tb_i2c_xfer.v) checks sampled edge *ordering*. This one
// checks numerical timing measured at the pins against the standard-mode
// (100 kHz) contract in NXP UM10204 Table 10:
//
//   fSCL      <= 100 kHz
//   tHIGH     >= 4.0 us
//   tLOW      >= 4.7 us
//   tSU;DAT   >= 250 ns   (SDA stable before SCL rises)
//   tHD;DAT   >= 0        (SDA stable after SCL falls)
//   tHD;STA   >= 4.0 us   (SDA falls, then SCL falls)
//   tSU;STO   >= 4.0 us   (SCL rises, then SDA rises)
//   tBUF      >= 4.7 us   (bus free between STOP and the next START)
//
// The operating point is selected on the command line:
//   +pclk_ns=<ns>   pclk period (default 20 ns -> 50 MHz)
//   +clkdiv=<n>     quarter delay in pclk cycles (default 124)
// With the default point fSCL = pclk / (4*(clkdiv+1)) = 100 kHz and
// tHIGH = tLOW = 2*(clkdiv+1)/pclk = 5.0 us.
//
// The bus is modelled with a delayed pull-up (TRISE): the line rises TRISE ns
// after every driver releases it and falls immediately when a driver pulls it
// low. This is what makes tHIGH shorter than tLOW and SDA setup shorter than a
// full quarter. A `pullup` primitive (the previous model) has zero rise time
// and overstates every margin.
//
// A 400 kHz fast-mode point is NOT supported by this generator and is not
// asserted here (see rtl/rtl_peripherals/i2c_ctrl.sv). Clock stretching and
// repeated START are not implemented by the controller and are not tested.
//
// Marker: I2C_TIMING: ALL CHECKS PASSED
//------------------------------------------------------------------------------
module tb_i2c_timing;

  // ---------------------------------------------------------------- config --
  real    PCLK_NS = 20.0;
  integer CLKDIV  = 124;
  // Standard-mode 400 pF bus: tr <= 1000 ns, but 300 ns is a typical
  // short-bus value and is the one modelled here.
  real    TRISE_NS = 300.0;

  localparam real T_HIGH_MIN   = 4000.0;
  localparam real T_LOW_MIN    = 4700.0;
  localparam real T_SU_DAT_MIN = 250.0;
  localparam real T_HD_STA_MIN = 4000.0;
  localparam real T_SU_STO_MIN = 4000.0;
  localparam real T_BUF_MIN    = 4700.0;
  localparam real F_SCL_MAX    = 100000.0;

  reg pclk = 0;
  always #(PCLK_NS / 2.0) pclk = ~pclk;

  // ------------------------------------------------------------- DUT + bus --
  reg         presetn = 0;
  reg         penable = 0, pwrite = 0;
  reg  [31:0] paddr = 0, pwdata = 0;
  reg  [3:0]  pstrb = 0;
  wire [31:0] prdata;
  wire        pready, pslverr, irq;
  tri         scl, sda;

  i2c_ctrl dut (
    .pclk(pclk), .presetn(presetn),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata), .pready(pready), .pslverr(pslverr),
    .i2c_scl(scl), .i2c_sda(sda), .irq(irq)
  );

  // Electrical node: an ideal pull-up, because Icarus does not honour a delay
  // on a strength-based continuous assignment (measured: the release fires in
  // the same time step).  The *observed* bus below applies the rise delay to
  // this node, and both the slave model and the timing monitor read the
  // observed bus.  The DUT reads the ideal SDA, but it samples only near the
  // end of the SCL high phase, ~2 quarters after every edge, so the modelled
  // rise time cannot change what it samples.
  pullup (scl);
  pullup (sda);

  reg scl_bus = 1, sda_bus = 1;
  always @(scl) begin
    if (scl === 1'b0) scl_bus <= #0 1'b0;          // pull-down: immediate
    else              scl_bus <= #(TRISE_NS) 1'b1;  // release: RC rise
  end
  always @(sda) begin
    if (sda === 1'b0) sda_bus <= #0 1'b0;
    else              sda_bus <= #(TRISE_NS) 1'b1;
  end

  // ------------------------------------------------------------ slave model --
  // Same structure as tb_i2c_xfer.v (proven there), extended with a data-byte
  // NACK and driven from the delayed observation of the bus.
  reg        slave_low = 0;
  assign sda = slave_low ? 1'b0 : 1'bz;

  reg        nack_addr = 0;       // refuse the address byte
  reg        nack_data = 0;       // refuse the data byte of a write
  reg  [7:0] tx_byte   = 8'h3C;

  reg        scl_p = 1, sda_p = 1;
  wire       scl_rise = scl_bus & ~scl_p;
  wire       scl_fall = ~scl_bus & scl_p;

  reg  [7:0] rx_byte = 0;
  integer    bitcnt = 0;
  reg        ack_done = 0, in_frame = 0, addr_done = 0, is_read = 0;
  reg  [7:0] captured_addr = 0, captured_data = 0;
  integer    data_bytes = 0;
  integer    slave_starts = 0, slave_stops = 0;

  always @(posedge pclk) begin
    scl_p <= scl_bus;
    sda_p <= sda_bus;
  end

  always @(posedge pclk) begin
    if (!presetn) begin
      bitcnt <= 0; ack_done <= 0; in_frame <= 0; addr_done <= 0;
      slave_low <= 0; is_read <= 0;
    end else begin
      // START: SDA falls while SCL is high.
      if (scl_bus && sda_p && !sda_bus) begin
        in_frame  <= 1'b1;
        bitcnt    <= 0;
        ack_done  <= 1'b0;
        addr_done <= 1'b0;
        slave_low <= 1'b0;
        slave_starts <= slave_starts + 1;
      end
      // STOP: SDA rises while SCL is high (after data was transferred).
      if (scl_p && scl_bus && !sda_p && sda_bus) begin
        in_frame  <= 1'b0;
        slave_low <= 1'b0;
        slave_stops <= slave_stops + 1;
      end

      if (in_frame) begin
        if (scl_rise) begin
          if (bitcnt < 8) begin
            rx_byte <= {rx_byte[6:0], sda_bus};
            bitcnt  <= bitcnt + 1;
          end
        end

        if (scl_fall) begin
          if (bitcnt == 8) begin
            if (!ack_done) begin
              if (addr_done && is_read)                   slave_low <= 1'b0;
              else if (!addr_done && nack_addr)            slave_low <= 1'b0;
              else if (addr_done && !is_read && nack_data) slave_low <= 1'b0;
              else                                        slave_low <= 1'b1;
              ack_done <= 1'b1;
            end else begin
              bitcnt    <= 0;
              ack_done  <= 1'b0;
              slave_low <= 1'b0;
              if (!addr_done) begin
                captured_addr <= rx_byte;
                addr_done     <= 1'b1;
                is_read       <= rx_byte[0];
                // A read must drive its first data bit immediately.
                if (rx_byte[0]) slave_low <= ~tx_byte[7];
              end else if (!is_read) begin
                captured_data <= rx_byte;
                data_bytes    <= data_bytes + 1;
              end
            end
          end else if (is_read && addr_done) begin
            slave_low <= ~tx_byte[7 - bitcnt];
          end
        end
      end
    end
  end

  // ------------------------------------------------------------ APB helpers --
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

  // Poll STATUS until done.  The poll is deliberately started immediately, so
  // the next transaction can follow a STOP as early as the controller allows:
  // that is exactly the tBUF case under test.
  task wait_done(output [31:0] status);
    integer guard;
    begin
      guard = 0;
      status = 0;
      while (!status[2] && guard < 400000) begin
        apb_read(32'h5000_2010, status);
        guard = guard + 1;
      end
      if (guard >= 400000) $fatal(1, "timeout waiting for done");
    end
  endtask

  // --------------------------------------------------------- timing monitor --
  // Sampled every 0.5 ns.  A 1 ns sample point on a 5 us quarter is far finer
  // than the margins asserted below; the resolution is reported with the result.
  reg        mon_en = 0;
  reg        scl_m = 1, sda_m = 1;
  realtime   t_rise = -1, t_fall = -1, t_sda = -1, t_start = -1, t_stop = -1;
  realtime   min_high = 1.0e12, min_low = 1.0e12, min_su_dat = 1.0e12;
  realtime   min_hd_dat = 1.0e12, min_hd_sta = 1.0e12, min_su_sto = 1.0e12;
  realtime   min_buf = 1.0e12;
  realtime   first_rise = -1, last_rise = -1;
  integer    n_rise = 0, start_count = 0, stop_count = 0;
  reg        pending_start = 0;
  realtime   now_t;

  initial begin
    mon_en = 0; scl_m = 1; sda_m = 1;
    forever begin
      #0.5;
      if (mon_en) begin
        now_t = $realtime;
        if ((scl_bus === 1'b0 || scl_bus === 1'b1) && scl_bus !== scl_m) begin
          if (scl_bus === 1'b1) begin
            if (t_fall >= 0) begin
              if (now_t - t_fall < min_low) min_low = now_t - t_fall;
            end
            t_rise = now_t;
            if (n_rise == 0) first_rise = now_t;
            last_rise = now_t;
            n_rise = n_rise + 1;
            if (t_sda >= 0) begin
              if (now_t - t_sda < min_su_dat) min_su_dat = now_t - t_sda;
            end
          end else begin
            if (t_rise >= 0) begin
              if (now_t - t_rise < min_high) min_high = now_t - t_rise;
            end
            t_fall = now_t;
            if (pending_start) begin
              if (now_t - t_start < min_hd_sta) min_hd_sta = now_t - t_start;
              pending_start = 0;
            end
          end
          scl_m = scl_bus;
        end
        if ((sda_bus === 1'b0 || sda_bus === 1'b1) && sda_bus !== sda_m) begin
          if (scl_bus === 1'b1) begin
            if (sda_bus === 1'b0) begin
              // START condition
              start_count = start_count + 1;
              if (t_stop >= 0) begin
                if (now_t - t_stop < min_buf) min_buf = now_t - t_stop;
              end
              t_start = now_t;
              pending_start = 1;
              if ($test$plusargs("traces")) $display("[trace] START at %0.1f ns", now_t);
            end else begin
              // STOP condition: SDA rises while SCL is high
              stop_count = stop_count + 1;
              if (t_rise >= 0) begin
                if (now_t - t_rise < min_su_sto) min_su_sto = now_t - t_rise;
              end
              t_stop = now_t;
              if ($test$plusargs("traces")) $display("[trace] STOP  at %0.1f ns", now_t);
            end
          end else begin
            if (t_fall >= 0) begin
              if (now_t - t_fall < min_hd_dat) min_hd_dat = now_t - t_fall;
            end
            t_sda = now_t;
          end
          sda_m = sda_bus;
        end
      end
    end
  end

  // ------------------------------------------------------------------ test --
  integer errors = 0;
  integer checks = 0;
  reg [31:0] status;
  real f_scl;

  task check(input cond, input [1023:0] msg);
    begin
      checks = checks + 1;
      if (!cond) begin
        $display("[i2c-timing] FAIL %0s", msg);
        errors = errors + 1;
      end else begin
        $display("[i2c-timing] pass %0s", msg);
      end
    end
  endtask

  task write_byte(input [7:0] b);
    begin
      apb_write(32'h5000_2008, {24'd0, b});
      apb_write(32'h5000_200C, 32'h9);          // start | write
      wait_done(status);
    end
  endtask

  task read_byte;
    begin
      apb_write(32'h5000_200C, 32'h5);          // start | read
      wait_done(status);
    end
  endtask

  initial begin
    if ($test$plusargs("pclk_ns")) begin
      void'($value$plusargs("pclk_ns=%f", PCLK_NS));
    end
    if ($test$plusargs("clkdiv")) begin
      void'($value$plusargs("clkdiv=%d", CLKDIV));
    end
    if (CLKDIV < 1) CLKDIV = 1;

    if ($test$plusargs("dump")) begin
      $dumpfile("build/sim/tb_i2c_timing.vcd");
      $dumpvars(0, tb_i2c_timing);
    end

    presetn = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (20) @(posedge pclk);

    apb_write(32'h5000_2000, 32'h1);            // enable
    apb_write(32'h5000_2014, CLKDIV);           // quarter delay
    apb_write(32'h5000_2004, 32'h50);           // slave address

    // Start measuring only once the bus has settled at the idle level.
    mon_en = 1;
    scl_m = scl_bus; sda_m = sda_bus;

    // ---------------- 1. write 0x5A ----------------
    write_byte(8'h5A);
    check(captured_addr === 8'hA0, "1 address byte 0xA0 on the bus");
    check(captured_data === 8'h5A && data_bytes == 1, "1 data byte 0x5A accepted by the slave");
    check(status[1] === 1'b0, "1 no ack_error on a completed write");

    // ---------------- 2. write 0xA5 (second payload) ----------------
    write_byte(8'hA5);
    check(captured_data === 8'hA5, "2 second payload 0xA5 transmitted");

    // ---------------- 3. read 0x3C ----------------
    read_byte;
    apb_read(32'h5000_2008, status);
    check(captured_addr === 8'hA1, "3 read address byte 0xA1");
    check(status[7:0] === 8'h3C, "3 received byte 0x3C");

    // ---------------- 4. address NACK ----------------
    nack_addr = 1;
    write_byte(8'h11);
    nack_addr = 0;
    check(status[1] === 1'b1, "4 address NACK sets ack_error");
    check(data_bytes == 2, "4 no data byte after an address NACK");

    // ---------------- 5. data NACK ----------------
    nack_data = 1;
    write_byte(8'h22);
    nack_data = 0;
    check(status[1] === 1'b1, "5 data NACK sets ack_error");

    // ---------------- 6. reset during an active transfer ----------------
    // Disable the monitor for the abort itself: reset releases the lines
    // asynchronously, which is not a bus condition, and is not scored.
    mon_en = 0;
    apb_write(32'h5000_2008, 8'h33);
    apb_write(32'h5000_200C, 32'h9);
    repeat (30) @(posedge pclk);                // inside START/address phase
    presetn = 0;
    repeat (5) @(posedge pclk);
    presetn = 1;
    repeat (50) @(posedge pclk);
    check(scl === 1'b1 || scl === 1'bz, "6 SCL released by reset");
    check(sda === 1'b1 || sda === 1'bz, "6 SDA released by reset");
    mon_en = 1;
    scl_m = scl_bus; sda_m = sda_bus;
    // Restart edge bookkeeping.  t_stop is cleared as well: the aborted
    // transfer produced no STOP, so pairing the next START with the previous
    // transaction's STOP would report a fictitious bus-free time.
    t_rise = -1; t_fall = -1; t_sda = -1; t_stop = -1; t_start = -1;
    pending_start = 0;

    // ---------------- 7. clean transfer after the reset ----------------
    apb_write(32'h5000_2000, 32'h1);
    apb_write(32'h5000_2014, CLKDIV);
    apb_write(32'h5000_2004, 32'h50);
    write_byte(8'h77);
    check(captured_data === 8'h77, "7 transfer completes after reset");

    mon_en = 0;

    // ---------------- timing verdict ----------------
    // fSCL from the shortest observed SCL period (min high + min low).  An
    // average over the whole run would include inter-transaction idle time and
    // understate the clock rate; the shortest period is the real worst case.
    f_scl = (min_high < 1.0e11 && min_low < 1.0e11 && (min_high + min_low) > 0.0)
            ? 1.0e9 / (min_high + min_low) : 0.0;

    $display("");
    $display("[i2c-timing] mode=std100 pclk=%0.1f ns clkdiv=%0d trise=%0.1f ns sample=0.5 ns",
             PCLK_NS, CLKDIV, TRISE_NS);
    $display("[i2c-timing] fSCL=%0.2f kHz  SCL rises=%0d  START=%0d  STOP=%0d",
             f_scl / 1000.0, n_rise, start_count, stop_count);
    $display("[i2c-timing] min tHIGH=%0.1f  tLOW=%0.1f  tSU;DAT=%0.1f  tHD;DAT=%0.1f ns",
             min_high, min_low, min_su_dat, min_hd_dat);
    $display("[i2c-timing] min tHD;STA=%0.1f  tSU;STO=%0.1f  tBUF=%0.1f ns",
             min_hd_sta, min_su_sto, min_buf);

    check(f_scl > 0.0, "T0 SCL edges were observed");
    check(f_scl <= F_SCL_MAX, "T1 fSCL <= 100 kHz");
    check(min_high >= T_HIGH_MIN, "T2 tHIGH >= 4.0 us");
    check(min_low >= T_LOW_MIN, "T3 tLOW >= 4.7 us");
    check(min_su_dat >= T_SU_DAT_MIN, "T4 tSU;DAT >= 250 ns");
    check(min_hd_dat >= 0.0, "T5 tHD;DAT >= 0 ns");
    check(min_hd_sta >= T_HD_STA_MIN, "T6 tHD;STA >= 4.0 us");
    check(min_su_sto >= T_SU_STO_MIN, "T7 tSU;STO >= 4.0 us");
    check(min_buf >= T_BUF_MIN, "T8 tBUF >= 4.7 us");

    // Seven transfers were issued: 1,2,3,4,5,7 and the aborted 6.  Every one
    // that ran to completion must have produced exactly one START and one STOP
    // at the pins.
    check(start_count == 6, "T9 one START per completed transfer");
    check(stop_count == 6, "T10 one STOP per completed transfer");

    $display("[i2c-timing] checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("I2C_TIMING: ALL CHECKS PASSED");
      $finish;
    end else begin
      $fatal(1, "I2C_TIMING: %0d FAILURES", errors);
    end
  end

endmodule
