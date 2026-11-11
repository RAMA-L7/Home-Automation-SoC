//------------------------------------------------------------------------------
// Home-Automation-SoC — Boot / full-SoC testbench (Icarus Verilog)
//
// Loads the firmware image into the boot ROM, releases reset, decodes the UART
// transmitter and asserts on the firmware result banner.
//
// Icarus is used because this machine has no C++ compiler, so Verilator can
// lint but cannot build a C++ model.
//
// Run:
//   iverilog -g2012 -o build/sim/tb_boot.vvp -s tb_boot \
//            sim/sim_top/tb_boot.v $(grep -v '^//' rtl/filelist.f | tr '\n' ' ')
//   vvp build/sim/tb_boot.vvp
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_boot;

  // The production default is 50 MHz / 115200. The test raises the baud rate so
  // a character costs 10*25 clocks instead of 10*434.
  localparam int  CLK_FREQ = 50_000_000;
  localparam int  BAUD     = 2_000_000;
  localparam real CLK_NS   = 20.0;
  localparam int  BIT_NS   = 500;

  reg clk = 0;
  reg reset_n = 0;

  wire        uart_tx;
  wire        spi_sck, spi_mosi, spi_cs_n;
  wire        i2c_scl, i2c_sda;
  wire [15:0] gpio;
  wire [3:0]  pwm_out;
  wire        i2s_bclk, i2s_lrclk, i2s_dout;
  wire        qspi_sck, qspi_cs_n;
  wire [3:0]  qspi_io;
  wire        wdog_reset_n, wake_req, jtag_tdo;

  has_soc #(
    .BOOT_ROM_FILE ("build/fw/boot.hex"),
    .UART_CLK_FREQ (CLK_FREQ),
    .UART_BAUD     (BAUD)
  ) dut (
    .clk             (clk),
    .reset_n         (reset_n),
    .jtag_tck        (1'b0),
    .jtag_tms        (1'b0),
    .jtag_tdi        (1'b0),
    .jtag_tdo        (jtag_tdo),
    .jtag_trst_n     (1'b1),
    .ext_irq         (32'd0),
    .uart_tx         (uart_tx),
    .uart_rx         (1'b1),
    .spi_sck         (spi_sck),
    .spi_mosi        (spi_mosi),
    .spi_miso        (1'b1),
    .spi_cs_n        (spi_cs_n),
    .i2c_scl         (i2c_scl),
    .i2c_sda         (i2c_sda),
    .gpio            (gpio),
    .pwm_out         (pwm_out),
    .i2s_bclk        (i2s_bclk),
    .i2s_lrclk       (i2s_lrclk),
    .i2s_dout        (i2s_dout),
    .i2s_din         (1'b0),
    .qspi_sck        (qspi_sck),
    .qspi_cs_n       (qspi_cs_n),
    .qspi_io         (qspi_io),
    .wdog_reset_n_out(wdog_reset_n),
    .core_clk_en_o   (),
    .wake_req        (wake_req),
    .wake_ack        (1'b0)
  );

  always #(CLK_NS/2) clk = ~clk;

  //--------------------------------------------------------------------------
  // Testbench UART receiver
  //--------------------------------------------------------------------------
  localparam MAXCHARS = 4096;
  reg [7:0]  rxbuf [0:4095];
  integer    nchars = 0;
  integer    i;
  reg [7:0]  rx_byte;

  initial begin
    forever begin
      @(negedge uart_tx);                      // start bit
      #(BIT_NS + BIT_NS/2);                    // middle of bit 0
      for (i = 0; i < 8; i = i + 1) begin
        rx_byte[i] = uart_tx;
        #(BIT_NS);
      end
      if (nchars < MAXCHARS) rxbuf[nchars] = rx_byte;
      nchars = nchars + 1;
      if (rx_byte == 8'h0A) $display("[uart] end of line (%0d bytes)", nchars);
      else $write("%c", rx_byte);
    end
  end

  //--------------------------------------------------------------------------
  // Checks
  //--------------------------------------------------------------------------
  reg [15:0] gpio_capture = 0;
  reg        gpio_seen = 0;
  integer    pwm_high = 0;

  always @(posedge clk) begin
    if (reset_n && (gpio == 16'hA5A5) && !gpio_seen) begin
      gpio_seen    = 1;
      gpio_capture = gpio;
      $display("\n[tb] GPIO pins observed at 0x%04h", gpio);
    end
    if (reset_n && pwm_out[0]) pwm_high = pwm_high + 1;
  end

  // Icarus right-justifies a string literal in a packed vector and stores the
  // characters in reverse byte order, so byte 0 of the literal is the LAST
  // character.  Character j of the text is therefore at byte (len-1-j);
  // indexing straight up from the LSB made this search for the reversed
  // string and it never matched.
  function integer contains(input [8*32-1:0] needle);
    integer k, m, len, hit;
    begin
      contains = 0;
      len = 0;
      for (m = 0; m < 32; m = m + 1)
        if (needle[m*8 +: 8] != 8'h00) len = m + 1;
      for (k = 0; k + len <= nchars && k < MAXCHARS - 32; k = k + 1) begin
        hit = 1;
        for (m = 0; m < len; m = m + 1)
          if (rxbuf[k + m] != needle[(len - 1 - m)*8 +: 8]) hit = 0;
        if (hit) contains = 1;
      end
    end
  endfunction

  integer pass_count, fail_count;

  initial begin
    $dumpfile("build/sim/tb_boot.vcd");
    $dumpvars(0, tb_boot);

    $display("=== HAS-SoC boot test ===");
    repeat (20) @(posedge clk);
    reset_n = 1;
    $display("[tb] reset released");

    #4_000_000;                     // 4 ms simulated

    $display("\n[tb] total UART bytes: %0d", nchars);
    if (nchars == 0) begin
      $display("[tb] RESULT: FAIL - no UART output, core did not boot");
      $fatal(1, "[tb] no UART output");
    end

    pass_count = 0;
    if (contains("PASS sram"))   pass_count = pass_count + 1;
    if (contains("PASS gpio"))   pass_count = pass_count + 1;
    if (contains("PASS muldiv")) pass_count = pass_count + 1;
    if (contains("PASS csr"))    pass_count = pass_count + 1;
    if (contains("PASS plic"))   pass_count = pass_count + 1;
    if (contains("PASS pwm"))    pass_count = pass_count + 1;
    if (contains("PASS pwr"))    pass_count = pass_count + 1;

    fail_count = 0;
    if (contains("FAIL ")) fail_count = 1;
    if (contains("TRAP ")) fail_count = 1;

    $display("[tb] firmware subtests passed: %0d / 7", pass_count);
    $display("[tb] gpio pins captured: %s", gpio_seen ? "yes" : "no");
    $display("[tb] pwm_out[0] high cycles: %0d", pwm_high);

    // A failing simulation must fail the process: $finish alone leaves vvp/
    // CI with exit status 0, which made a failed boot look like a pass.
    if (contains("RESULT: ALL TESTS PASSED") && !fail_count && gpio_seen &&
        pass_count == 7) begin
      $display("[tb] RESULT: PASS");
      $finish;
    end else begin
      $display("[tb] RESULT: FAIL");
      $fatal(1, "[tb] boot test failed (pass=%0d/7, fail_lines=%0d, gpio=%0d)",
             pass_count, fail_count, gpio_seen);
    end
  end

  // Watchdog: a hung core must end the run with a nonzero status, not sit
  // until the harness timeout.
  initial begin
    #40_000_000;
    $display("[tb] RESULT: FAIL - timeout");
    $fatal(1, "[tb] simulation timeout");
  end

endmodule
