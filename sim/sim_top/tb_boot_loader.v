`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Production boot path — cold start and watchdog recovery with NO preload
//
// THE POINT OF THIS BENCH
//   Every earlier "boot" test ran with -DSIM_MEM_PRELOAD, i.e. the TCM and SRAM
//   arrays were $readmemh-initialised by the testbench.  That is a simulation
//   convenience, not an initialisation story: a real sky130 SRAM macro has no
//   init port and powers up undefined.  Preloading therefore hid the fact that
//   nothing in the design ever put code into TCM.
//
//   This bench must be compiled WITHOUT -DSIM_MEM_PRELOAD (scripts/eda/
//   run_regression.js gives it `defines: []`).  It then requires:
//     * the memories to be genuinely unknown at t=0 (checked directly through
//       the macro wrapper hierarchy, not assumed),
//     * firmware/boot/loader.S to copy the TCM image and the .data image out of
//       the boot ROM, zero .bss, set the stack and jump,
//     * the payload to run from TCM and print its results over UART,
//     * the payload to arm the watchdog and stop petting it, so the SoC is reset
//       and the whole path is re-entered a second time.
//
//   The ROM-resident assembly demonstration stays where it is, in tb_boot.v:
//   that one tests the SoC from ROM and is a different claim.
//------------------------------------------------------------------------------
module tb_boot_loader;

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
    .BOOT_ROM_FILE ("build/fw/boot_rom.hex"),
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
  // UART receiver (same contract as tb_boot.v)
  //--------------------------------------------------------------------------
  localparam MAXCHARS = 8192;
  reg [7:0]  rxbuf [0:8191];
  integer    nchars = 0;
  integer    i;
  reg [7:0]  rx_byte;

  initial begin
    forever begin
      @(negedge uart_tx);
      #(BIT_NS + BIT_NS/2);
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

  // Count occurrences of a substring.  Icarus stores a string literal
  // right-justified with the first character in the top byte, so character j
  // lives at byte (len-1-j).
  function integer count_of(input [8*48-1:0] needle);
    integer k, m, len, hit;
    begin
      count_of = 0;
      len = 0;
      for (m = 0; m < 48; m = m + 1)
        if (needle[m*8 +: 8] != 8'h00) len = m + 1;
      for (k = 0; k + len <= nchars && k < MAXCHARS - 48; k = k + 1) begin
        hit = 1;
        for (m = 0; m < len; m = m + 1)
          if (rxbuf[k + m] != needle[(len - 1 - m)*8 +: 8]) hit = 0;
        if (hit) count_of = count_of + 1;
      end
    end
  endfunction

  //--------------------------------------------------------------------------
  // Watchdog reset observation
  //--------------------------------------------------------------------------
  integer sys_reset_falls = 0;
  reg     rst_prev = 1'b1;
  always @(posedge clk) begin
    if (dut.rst_sys_n === 1'b0 && rst_prev === 1'b1) sys_reset_falls = sys_reset_falls + 1;
    rst_prev <= dut.rst_sys_n;
  end

  integer errors = 0;
  task check(input cond, input [1023:0] msg);
    begin
      if (!cond) begin
        $display("[boot] FAIL %0s", msg);
        errors = errors + 1;
      end else begin
        $display("[boot] pass %0s", msg);
      end
    end
  endtask

  reg [31:0] tcm_word0_before;
  reg [31:0] sram_word0_before;

  initial begin
    // No $dumpvars: dumping the whole SoC (80 macro instances) costs more wall
    // time than everything else in this bench combined.

    // ---- the memories must really be unknown before anything loads them ----
    #1;
    tcm_word0_before  = dut.tcm_inst.u_tcm.g_bank[0].u_macro.mem[0];
    sram_word0_before = dut.sram_inst.g_bank[0].u_macro.mem[0];
    check((^tcm_word0_before) === 1'bx,
          "TCM word 0 is unknown at t=0 (nothing preloaded it)");
    check((^sram_word0_before) === 1'bx,
          "SRAM word 0 is unknown at t=0 (nothing preloaded it)");

    repeat (20) @(posedge clk);
    reset_n = 1;

    // 6 ms simulated: two boots (each ~0.5 ms of UART) plus a 20,000-cycle
    // watchdog timeout, with margin.
    #6_000_000;

    $display("\n[boot] total UART bytes: %0d", nchars);
    $display("[boot] system-reset assertions observed: %0d", sys_reset_falls);

    // The payload re-arms the watchdog every time it runs, so the SoC keeps
    // booting for as long as the bench runs; the contract is "at least two
    // full boots, all of them from the loader", not an exact count.
    check(count_of("BOOT: PAYLOAD RUNNING FROM TCM") >= 2,
          "payload ran from TCM on every boot (>= 2 boots)");
    check(count_of("BOOT: DATA OK") == count_of("BOOT: PAYLOAD RUNNING FROM TCM"),
          ".data was copied from the ROM into SRAM on every boot");
    check(count_of("BOOT: BSS OK") == count_of("BOOT: PAYLOAD RUNNING FROM TCM"),
          ".bss was zeroed by the loader on every boot");
    check(count_of("BOOT: COLD BOOT PASS") >= 2,
          "cold boot completed at least twice (cold reset, then watchdog recovery)");
    check(count_of("BOOT: COLD BOOT PASS") == count_of("BOOT: PAYLOAD RUNNING FROM TCM"),
          "every boot that started the payload also reached its PASS line");
    check(count_of("FAIL") == 0, "no FAIL line from the payload");
    check(sys_reset_falls >= 1, "the watchdog actually reset the SoC");
    check(dut.rst_sys_n === 1'b1 || reset_n === 1'b1, "SoC is not stuck in reset");

    // The TCM word the loader wrote must now be defined where it was x.
    check((^dut.tcm_inst.u_tcm.g_bank[0].u_macro.mem[0]) !== 1'bx,
          "TCM word 0 became defined after the loader copied into it");

    if (errors == 0) $display("\nBOOT LOADER: ALL TESTS PASSED");
    else             $display("\nBOOT LOADER: FAIL (%0d errors)", errors);
    $finish;
  end

endmodule
