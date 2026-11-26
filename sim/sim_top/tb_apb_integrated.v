//------------------------------------------------------------------------------
// Home-Automation-SoC — integrated APB address/response test
//
// Runs on the real SoC (has_soc), so every access traverses the req/gnt
// adapter, the AXI4-Lite interconnect, the AXI-to-APB bridge and the APB decode
// in has_soc.sv.  That is the only place the address and response defects can
// be observed together; a block-level testbench would wire its own decode.
//
//   sim/asm/apb_integrated.S  the program (result slots in the TCM)
//   sim/asm/boot_jump.S       two-instruction boot ROM: `j 0x10000`
//
// Both images are regenerated from source before the suite runs by
// scripts/eda/run_regression.js, which records their SHA-256.
//
// Checks (TCM word index = byte address / 4):
//   64   GPIO DATA_OUT after a supported word write       0x1234
//   65   ... after a rejected byte write                  0x1234 (no side effect)
//   66   ... after a rejected halfword write               0x1234 (no side effect)
//   67   ... after a write to 0x5001_0000 (1 MB aperture)  0x1234 (no aliasing)
//   68   ... after a post-fault supported word write       0x5678
//   128  trap count                                        4
//   136..139  mcause of each trap                          7 (store access fault)
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_apb_integrated;

  reg clk = 1'b0;
  reg reset_n = 1'b0;
  always #10 clk = ~clk;

  wire [15:0] gpio;
  wire [3:0]  qspi_io;
  wire        i2c_scl, i2c_sda;
  wire        jtag_tdo, uart_tx, spi_sck, spi_mosi, spi_cs_n;
  wire [3:0]  pwm_out;
  wire        i2s_bclk, i2s_lrclk, i2s_dout;
  wire        qspi_sck, qspi_cs_n;
  wire        wdog_reset_n_out, core_clk_en_o, wake_req;

  // Nothing drives these pads in simulation.
  assign gpio    = 16'bz;
  assign qspi_io = 4'bz;
  assign i2c_scl = 1'bz;
  assign i2c_sda = 1'bz;

  has_soc #(
    .BOOT_ROM_FILE  ("build/sim/apb_jump.hex"),
    .TCM_INIT_FILE  ("build/sim/apb_integrated.hex")
  ) dut (
    .clk(clk), .reset_n(reset_n),
    .jtag_tck(1'b0), .jtag_tms(1'b0), .jtag_tdi(1'b0), .jtag_tdo(jtag_tdo),
    .jtag_trst_n(1'b1),
    .uart_tx(uart_tx), .uart_rx(1'b1),
    .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(1'b1), .spi_cs_n(spi_cs_n),
    .i2c_scl(i2c_scl), .i2c_sda(i2c_sda),
    .gpio(gpio),
    .pwm_out(pwm_out),
    .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk), .i2s_dout(i2s_dout), .i2s_din(1'b0),
    .qspi_sck(qspi_sck), .qspi_cs_n(qspi_cs_n), .qspi_io(qspi_io),
    .wdog_reset_n_out(wdog_reset_n_out), .core_clk_en_o(core_clk_en_o),
    .wake_req(wake_req), .wake_ack(1'b0)
  );

  integer errors = 0;
  integer checks = 0;

  task chk(input [8*46-1:0] name, input [31:0] got, input [31:0] exp);
    begin
      checks = checks + 1;
      if (got !== exp) begin
        errors = errors + 1;
        $display("[apbint] FAIL %0s: got 0x%08h expected 0x%08h", name, got, exp);
      end else begin
        $display("[apbint] pass %0s = 0x%08h", name, got);
      end
    end
  endtask

  // TCM is a macro wrapper now, so a flat `mem[]` no longer exists. Word `idx`
  // lives in bank idx/512 at local row idx%512 (128 KiB-style banking with the
  // 2 KiB macro: 512 words per bank). Read it through the leaf model the
  // SIM_MEM_PRELOAD hook writes into.
  function [31:0] tcm_word(input integer idx);
    // Constant generate-scope indices only: Icarus cannot index a generate
    // block with a variable, so the bank is selected with a case.
    case (idx / 512)
      0: tcm_word = dut.tcm_inst.u_tcm.g_bank[0].u_macro.mem[idx % 512];
      1: tcm_word = dut.tcm_inst.u_tcm.g_bank[1].u_macro.mem[idx % 512];
      2: tcm_word = dut.tcm_inst.u_tcm.g_bank[2].u_macro.mem[idx % 512];
      3: tcm_word = dut.tcm_inst.u_tcm.g_bank[3].u_macro.mem[idx % 512];
      4: tcm_word = dut.tcm_inst.u_tcm.g_bank[4].u_macro.mem[idx % 512];
      5: tcm_word = dut.tcm_inst.u_tcm.g_bank[5].u_macro.mem[idx % 512];
      6: tcm_word = dut.tcm_inst.u_tcm.g_bank[6].u_macro.mem[idx % 512];
      7: tcm_word = dut.tcm_inst.u_tcm.g_bank[7].u_macro.mem[idx % 512];
      8: tcm_word = dut.tcm_inst.u_tcm.g_bank[8].u_macro.mem[idx % 512];
      9: tcm_word = dut.tcm_inst.u_tcm.g_bank[9].u_macro.mem[idx % 512];
      10: tcm_word = dut.tcm_inst.u_tcm.g_bank[10].u_macro.mem[idx % 512];
      11: tcm_word = dut.tcm_inst.u_tcm.g_bank[11].u_macro.mem[idx % 512];
      12: tcm_word = dut.tcm_inst.u_tcm.g_bank[12].u_macro.mem[idx % 512];
      13: tcm_word = dut.tcm_inst.u_tcm.g_bank[13].u_macro.mem[idx % 512];
      14: tcm_word = dut.tcm_inst.u_tcm.g_bank[14].u_macro.mem[idx % 512];
      15: tcm_word = dut.tcm_inst.u_tcm.g_bank[15].u_macro.mem[idx % 512];
      default: tcm_word = 32'hx;
    endcase
  endfunction

  integer i;
  initial begin
    reset_n = 1'b0;
    repeat (10) @(posedge clk);
    reset_n = 1'b1;

    // The program is ~34 instructions plus four traps on a multi-cycle core;
    // 40,000 cycles is ~8,000 instructions of headroom.
    repeat (40000) @(posedge clk);

    $display("[apbint] trap count = %0d", tcm_word(128));

    chk("R1 supported word write reaches the register",
        tcm_word(64), 32'h0000_1234);
    chk("R2 rejected byte write had no side effect",
        tcm_word(65), 32'h0000_1234);
    chk("R3 rejected halfword write had no side effect",
        tcm_word(66), 32'h0000_1234);
    chk("R5 1 MB aperture address did not alias GPIO",
        tcm_word(67), 32'h0000_1234);
    chk("R6 supported word write still works after the faults",
        tcm_word(68), 32'h0000_5678);

    chk("R2/R3/R4/R5 all rejected accesses trapped", tcm_word(128), 32'd4);
    for (i = 0; i < 4; i = i + 1) begin
      chk("trap cause is store access fault (7)", tcm_word(136 + i), 32'd7);
    end

    // The faulting accesses must not have left the APB bridge busy: a further
    // transaction (R6) completed, and the SoC is not in reset.
    chk("SoC left system reset", {31'd0, dut.rst_sys_n}, 32'd1);

    $display("");
    $display("[apbint] checks: %0d, failures: %0d", checks, errors);
    if (errors == 0) begin
      $display("APB INTEGRATED: ALL TESTS PASSED");
      $finish;
    end else begin
      $display("APB INTEGRATED: %0d FAILURES", errors);
      $fatal(1, "integrated APB test failed");
    end
  end

  initial begin
    #4_000_000;
    $display("APB INTEGRATED: TIMEOUT (pc=0x%08h)", dut.core.pc);
    $fatal(1, "integrated APB test timed out");
  end

endmodule
