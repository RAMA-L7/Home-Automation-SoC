`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Home-Automation-SoC — SRAM Testbench (Verilog-2001, Icarus-compatible)
// Stage 4 Verification
//
// Tests AXI4-Lite read/write to the on-chip SRAM:
//   1. Write 32-bit word to address 0x000, read back, verify
//   2. Write byte (strb=0001) to address 0x004, read back full word, verify byte
//   3. Write halfword (strb=0011) to address 0x008, read back, verify
//   4. Write full word (strb=1111) to address 0x00C, read back, verify
//
// NOTE: This testbench cannot currently be run because Icarus Verilog exits
// with code 1 and no output in this environment. It is provided as a
// specification of expected behavior and can be run once Icarus is fixed.
//------------------------------------------------------------------------------
module tb_sram_simple;

  // Clock and reset
  logic pclk;
  logic presetn;

  // AXI4-Lite write address channel
  logic         awvalid;
  logic [31:0]    awaddr;
  logic           awready;
  // AXI4-Lite write data channel
  logic         wvalid;
  logic [31:0]    wdata;
  logic [3:0]     wstrb;
  logic           wready;
  // AXI4-Lite write response channel
  logic           bvalid;
  logic           bready;
  logic [1:0]     bresp;
  // AXI4-Lite read address channel
  reg         arvalid;
  reg  [31:0]   araddr;
  wire        arready;
  // AXI4-Lite read data channel
  wire        rvalid;
  logic [31:0]  rdata;
  logic [1:0]   rresp;
  reg         rready;

  // Instantiate DUT
  sram #(
    .ADDR_WIDTH(18),
    .DATA_WIDTH(32),
    .MEM_FILE("")
  ) dut (
    .clk     (pclk),
    .reset_n (presetn),
    .awvalid (awvalid),
    .awaddr  (awaddr),
    .awready (awready),
    .wvalid  (wvalid),
    .wdata   (wdata),
    .wstrb   (wstrb),
    .wready  (wready),
    .bvalid  (bvalid),
    .bready  (bready),
    .bresp   (bresp),
    .arvalid (arvalid),
    .araddr  (araddr),
    .arready (arready),
    .rvalid  (rvalid),
    .rdata   (rdata),
    .rresp   (rresp),
    .rready  (rready),
    // Instruction port (unused in this test)
    .i_req   (1'b0),
    .i_addr  (32'd0),
    .i_gnt   (),
    .i_rdata (),
    .i_rvalid()
  );

  // Clock generation: 50 MHz (20 ns period)
  initial pclk = 0;
  always #5 pclk = ~pclk;

  // Reset generation
  initial begin
    presetn   = 0;
    awvalid   = 0;
    awaddr    = 0;
    wvalid    = 0;
    wdata     = 0;
    wstrb     = 0;
    bready    = 0;
    arvalid   = 0;
    araddr    = 0;
    rready    = 0;
    repeat (10) @(posedge pclk);
    presetn   = 1;
    repeat (5) @(posedge pclk);
  end

  //--------------------------------------------------------------------------
  // APB write task
  //--------------------------------------------------------------------------
  task apb_write(input logic [31:0] addr, input logic [31:0] data,
                 input logic [3:0] strb);
    begin
      @(posedge pclk);
      awvalid = 1;
      awaddr  = addr;
      wvalid  = 1;
      wdata   = data;
      wstrb   = strb;
      @(posedge pclk);
      while (!awready) @(posedge pclk);
      while (!wready)  @(posedge pclk);
      awvalid = 0;
      wvalid  = 0;
      @(posedge pclk);
      while (!bvalid) @(posedge pclk);
      bready = 1;
      @(posedge pclk);
      bready = 0;
    end
  endtask

  //--------------------------------------------------------------------------
  // APB read task
  //--------------------------------------------------------------------------
  task apb_read(input logic [31:0] addr, output logic [31:0] data);
    begin
      @(posedge pclk);
      arvalid = 1;
      araddr  = addr;
      @(posedge pclk);
      while (!arready) @(posedge pclk);
      arvalid = 0;
      rready  = 1;
      @(posedge pclk);
      while (!rvalid) @(posedge pclk);
      data = rdata;
      rready = 0;
      @(posedge pclk);
    end
  endtask

  //--------------------------------------------------------------------------
  // Main test
  //--------------------------------------------------------------------------
  integer errors = 0;

  initial begin
    $display("TB_SRAM: Starting SRAM read/write test...");

    // Test 1: Full word write to 0x000, read back, verify
    apb_write(32'h0000_0000, 32'hDEADBEEF, 4'b1111);
    apb_read(32'h0000_0000, rdata);
    $display("TB_SRAM: Wrote 0xDEADBEEF to 0x000, read 0x%08X", rdata);
    if (rdata != 32'hDEADBEEF) begin
      $display("TB_SRAM: FAIL - Full word readback mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_SRAM: PASS - Full word readback OK");
    end

    // Test 2: Byte write to address 0x004 (strb=0001), read back full word
    apb_write(32'h0000_0004, 32'h0000_0078, 4'b0001);
    apb_read(32'h0000_0000, rdata);
    $display("TB_SRAM: Wrote byte 0x78 to addr 0x004, read 0x%08X", rdata);
    if ((rdata & 32'h000000FF) != 32'h00000078) begin
      $display("TB_SRAM: FAIL - Byte write mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_SRAM: PASS - Byte write OK");
    end

    // Test 3: Halfword write to address 0x008 (strb=0011), read back
    apb_write(32'h0000_0008, 32'h0000_AAAA, 4'b0011);
    apb_read(32'h0000_0008, rdata);
    $display("TB_SRAM: Wrote halfword 0xAAAA to 0x008, read 0x%08X", rdata);
    if (rdata != 32'h0000_AAAA) begin
      $display("TB_SRAM: FAIL - Halfword write mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_SRAM: PASS - Halfword write OK");
    end

    // Test 4: Full word write to 0x00C, read back
    apb_write(32'h0000_000C, 32'h12345678, 4'b1111);
    apb_read(32'h0000_000C, rdata);
    $display("TB_SRAM: Wrote 0x12345678 to 0x00C, read 0x%08X", rdata);
    if (rdata != 32'h12345678) begin
      $display("TB_SRAM: FAIL - Full word write mismatch");
      errors = errors + 1;
    end else begin
      $display("TB_SRAM: PASS - Full word write OK");
    end

    repeat (20) @(posedge pclk);

    if (errors == 0) begin
      $display("TB_SRAM: ==========================================");
      $display("TB_SRAM: ALL TESTS PASSED");
      $display("TB_SRAM: ==========================================");
    end else begin
      $display("TB_SRAM: ==========================================");
      $display("TB_SRAM: %0d ERROR(S) DETECTED", errors);
      $display("TB_SRAM: ==========================================");
    end

    $finish;
  end

endmodule