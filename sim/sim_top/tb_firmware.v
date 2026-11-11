//------------------------------------------------------------------------------
// Home-Automation-SoC — C firmware full-system demonstrator
//
// Runs the *compiled* C firmware (startup.S + main.c + drivers.c + boot.c +
// host_comm.c + ota.c, built with riscv-none-elf-gcc 12.2.0 -march=rv32im)
// on the RTL SoC:
//
//   reset -> boot ROM (startup.S at 0x0)
//         -> .text executed from TCM (0x1_0000)
//         -> UART banner, GPIO LED, watchdog armed
//         -> host command 'r' received on uart_rx
//         -> firmware stops petting the watchdog
//         -> watchdog timeout -> internal reset (reset_ctrl)
//         -> CPU reboots and the banner appears again
//
// This is the *diagnostic* demonstration: no image authentication, no flash
// programming, no secure boot (see reports/ and boot.c).
//
// Images are produced by:
//   node scripts/fw_build/build_fw.js
//   node scripts/fw_build/gen_fw_mem.js build/fw/firmware.elf <toolchain-bin>
//
// Run:
//   iverilog -g2012 -o build/sim/tb_firmware.vvp -s tb_firmware \
//            sim/sim_top/tb_firmware.v $(grep -v '^//' rtl/filelist.f | tr '\n' ' ')
//   vvp build/sim/tb_firmware.vvp
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_firmware;

  localparam int  CLK_FREQ = 50_000_000;
  localparam int  BAUD     = 2_000_000;     // div = 25 clocks per bit
  localparam real CLK_NS   = 20.0;
  localparam int  BIT_NS   = 500;

  reg clk = 0;
  reg reset_n = 0;
  reg uart_rx = 1'b1;

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
    .BOOT_ROM_FILE  ("build/fw/rom.hex"),
    .TCM_INIT_FILE  ("build/fw/tcm.hex"),
    .UART_CLK_FREQ  (CLK_FREQ),
    .UART_BAUD      (BAUD)
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
    .uart_rx         (uart_rx),
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
  // UART receiver: newest character in the low byte of `line`.
  // Icarus packs a string literal with the first character in the high byte,
  // so `line[8*N-1:0] == "text"` compares correctly with N characters.
  //--------------------------------------------------------------------------
  reg [8*32-1:0] line = 0;
  integer        nchars = 0;
  reg [7:0]      rx_byte;
  integer        i;

  initial begin
    forever begin
      @(negedge uart_tx);                      // start bit
      #(BIT_NS + BIT_NS/2);                    // middle of bit 0
      for (i = 0; i < 8; i = i + 1) begin
        rx_byte[i] = uart_tx;
        #(BIT_NS);
      end
      // Newest character in the low byte, matching Icarus's literal packing.
      line   = {line[8*31-1:0], rx_byte};
      nchars = nchars + 1;
      if (rx_byte == 8'h0A) begin
        $display(" [%0d bytes]", nchars);
      end else if (rx_byte != 8'h0D) begin
        $write("%c", rx_byte);
      end
    end
  end

  //--------------------------------------------------------------------------
  // Host -> device byte
  //--------------------------------------------------------------------------
  task send_byte(input [7:0] b);
    integer k;
    begin
      uart_rx = 1'b0; #(BIT_NS);
      for (k = 0; k < 8; k = k + 1) begin
        uart_rx = b[k];
        #(BIT_NS);
      end
      uart_rx = 1'b1; #(BIT_NS);
    end
  endtask

  //--------------------------------------------------------------------------
  // Watchdog reset observations
  //--------------------------------------------------------------------------
  integer wdog_pulses = 0;
  reg     wdog_prev = 1'b1;
  integer gpio_toggles = 0;
  reg [15:0] gpio_prev = 16'h0000;

  always @(posedge clk) begin
    wdog_prev <= wdog_reset_n;
    if (!wdog_reset_n && wdog_prev) wdog_pulses = wdog_pulses + 1;
    gpio_prev <= gpio;
    if (gpio != gpio_prev) gpio_toggles = gpio_toggles + 1;
  end

  //--------------------------------------------------------------------------
  // Sequence
  //--------------------------------------------------------------------------
  initial begin
    repeat (10) @(posedge clk);
    reset_n = 1'b1;

    // 1. the C firmware announces itself (startup.S + main())
    wait (line[8*8-1:0] == "Firmware");
    $display("[fw] banner seen: 'Firmware'");
    wait (line[8*12-1:0] == "Core: RV32IM");
    $display("[fw] ISA string seen: 'Core: RV32IM'");
    wait (line[8*14-1:0] == "Boot: Complete");
    $display("[fw] 'Boot: Complete'");
    wait (line[8*19-1:0] == "Ready for commands.");
    $display("[fw] firmware reached its command loop");

    // 2. host command: 'r' = reboot (stop petting the watchdog)
    send_byte("r");
    wait (line[8*16-1:0] == "Reboot requested");
    $display("[fw] command 'r' received and echoed");
    line = 0;

    // 3. watchdog times out (1,000,000 ungated clocks) and resets the SoC;
    //    reset_ctrl releases the system and the firmware reboots.
    gpio_toggles = 16'hFFFF; // track GPIO blinks only between now and the reboot
    @(posedge wdog_reset_n);   // best-effort: ensure the active-low pulse is visible
    wait (wdog_reset_n == 1'b0);
    @ (posedge wdog_reset_n);   // release to release edge
    $display("[fw] watchdog pulse observed; waiting for the rebooted banner");
    wait (line[8*19-1:0] == "Ready for commands.");
    $display("[fw] firmware rebooted after the watchdog reset");

    if (wdog_pulses < 1) begin
      $display("[fw] RESULT: FAIL (no watchdog reset pulse: %0d)", wdog_pulses);
      $fatal(1, "watchdog did not reset the SoC");
    end
    if (gpio_toggles < 2) begin
      $display("[fw] RESULT: FAIL (GPIO never toggled)");
      $fatal(1, "GPIO LED did not blink");
    end

    $display("[fw] watchdog reset pulses: %0d", wdog_pulses);
    $display("[fw] GPIO transitions      : %0d", gpio_toggles);
    $display("[fw] characters received  : %0d", nchars);
    $display("[fw] RESULT: PASS");
    $finish;
  end

  // 120 ms: the watchdog timeout is 20.8 ms plus boot banners.
  initial begin
    #120_000_000;
    $display("[fw] RESULT: FAIL (timeout after 120 ms; %0d chars, wdog pulses %0d)",
             nchars, wdog_pulses);
    $fatal(1, "firmware demonstration timed out");
  end

endmodule
