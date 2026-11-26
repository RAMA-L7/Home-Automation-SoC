`timescale 1ns/1ps
module tb_apb_cpu;
  reg clk=0; reg reset_n=0;
  always #10 clk=~clk;
  reg [31:0] boot_rom [0:16383];
  reg [31:0] tcm [0:8191];
  integer i; reg [31:0] marker, trap_count, last_mcause;
  has_soc #(.BOOT_ROM_FILE("build/sim/boot_jump.hex"), .TCM_INIT_FILE("build/sim/tb_apb_cpu.hex")) dut(
    .clk(clk), .reset_n(reset_n), .jtag_tck(1'b0), .jtag_tms(1'b0), .jtag_tdi(1'b0),
    .jtag_tdo(), .jtag_trst_n(1'b1), .uart_tx(), .uart_rx(1'b1),
    .spi_sck(), .spi_mosi(), .spi_miso(1'b1), .spi_cs_n(), .i2c_scl(), .i2c_sda(),
    .gpio(), .pwm_out(), .i2s_bclk(), .i2s_lrclk(), .i2s_dout(), .i2s_din(1'b0),
    .qspi_sck(), .qspi_cs_n(), .qspi_io(), .wdog_reset_n_out(), .core_clk_en_o(),
    .wake_req(), .wake_ack(1'b0));
  initial begin
    reset_n=0;
    repeat(10) @(posedge clk);
    reset_n=1;
    for(i=0;i<20;i=i+1) begin @(posedge clk); $display("[apb_cpu] cyc=%0d pc=%08h rvalid=%b", i, dut.core.pc, dut.core.instr_rvalid); end
    for(i=0;i<100000;i=i+1) @(posedge clk);
    $display("[apb_cpu] rst_sys_n=%b core_clk_en=%b pc=%08h boot0=%08h", dut.rst_sys_n, dut.core_clk_en_q, dut.core.pc, dut.rom_inst.mem[0]);
    marker=dut.tcm_inst.mem[128];
    trap_count=dut.tcm_inst.mem[129];
    last_mcause=dut.tcm_inst.mem[130];
    $display("[apb_cpu] marker=%0d trap_count=%0d last_mcause=%0d", marker, trap_count, last_mcause);
    if(marker==32'd1 && trap_count==32'd4 && last_mcause==32'd7) begin
      $display("APB CPU: ALL TESTS PASSED");
      $finish;
    end else begin
      $display("APB CPU: FAIL");
      $fatal;
    end
  end
  initial begin #10000000; $display("APB CPU: TIMEOUT"); $fatal; end
endmodule