`timescale 1ns/1ps
//------------------------------------------------------------------------------
// SPI Controller Testbench (Verilog-2001, Icarus-compatible)
//------------------------------------------------------------------------------
module tb_spi;

  reg         pclk;
  reg         presetn;
  reg         penable;
  reg         pwrite;
  reg  [31:0] paddr;
  reg  [31:0] pwdata;
  reg  [3:0]  pstrb;
  wire [31:0] prdata_wire;
  reg  [31:0] prdata;
  wire        pready;
  wire        pslverr;
  wire        spi_sck;
  wire        spi_mosi;
  wire        spi_miso;
  wire        spi_cs_n;
  wire        irq;

  spi_ctrl dut (
    .pclk(pclk), .presetn(presetn),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_wire), .pready(pready), .pslverr(pslverr),
    .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso), .spi_cs_n(spi_cs_n),
    .irq(irq)
  );

  always @(*) prdata = prdata_wire;

  initial pclk = 0;
  always #5 pclk = ~pclk;

  integer errors = 0;

  task apb_write;
    input [31:0] addr;
    input [31:0] data;
    begin
      penable = 1; pwrite = 1; paddr = addr; pwdata = data; pstrb = 4'b1111;
      @(posedge pclk);
      while (!pready) @(posedge pclk);
      penable = 0; pwrite = 0;
      @(posedge pclk);
    end
  endtask

  task apb_read;
    input [31:0] addr;
    output reg [31:0] data;
    begin
      penable = 1; pwrite = 0; paddr = addr; pstrb = 4'b0000;
      @(posedge pclk);
      while (!pready) @(posedge pclk);
      data = prdata_wire;
      penable = 0;
      @(posedge pclk);
    end
  endtask

  initial begin
    $dumpfile("build/sim/tb_spi.vcd");
    $dumpvars(0, tb_spi);

    presetn = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    repeat (10) @(posedge pclk);
    presetn = 1;
    repeat (5) @(posedge pclk);

    $display("TB_SPI: Starting SPI test...");

    // Enable SPI
    apb_write(32'h50003000, 32'h00000001);

    // Write TX data
    apb_write(32'h50003004, 32'h000000A5);

    apb_read(32'h50003000, prdata);
    $display("TB_SPI: Wrote enable=1, read 0x%08X (bit0=en)", prdata);
    if ((prdata & 32'h1) != 32'h1) begin
      $display("TB_SPI: FAIL - enable mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_SPI: PASS - enable OK");
    end

    apb_read(32'h50003003, prdata);
    $display("TB_SPI: Status register = 0x%08X", prdata);

    repeat (20) @(posedge pclk);

    if (errors == 0)
      $display("TB_SPI: ALL TESTS PASSED");
    else
      $display("TB_SPI: %0d ERRORS", errors);

    $finish;
  end

endmodule
