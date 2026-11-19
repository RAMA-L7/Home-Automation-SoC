`timescale 1ns/1ps
// File-scope import, as rtl/rtl_top/has_soc.sv does: this Icarus version
// rejects a module-scope wildcard import.
import has_addr_map_pkg::*;
//------------------------------------------------------------------------------
// Memory contract testbench — boundaries, aliasing and byte access (F5)
//
// The memories used to be allocated larger than the apertures the address map,
// the interconnect, the linker script and FR-MEM-001/002/003 declare
// (ROM 64 KB vs 16 KB, SRAM 256 KB vs 128 KB).  Those arrays are now sized to
// the contract, so this test checks the *contract*, not just the primitive:
//
//   A. address-map region boundaries (has_addr_map_pkg::addr_region)
//      each region's first and last byte, and the first byte after it
//   B. 16 KB boot ROM at the SoC parameterisation: first/last word, the
//      instruction port, and the port-truncation alias at 0x4000
//   C. 128 KB SoC SRAM: first/last word, byte writes in the last word,
//      read-after-write, and the port-truncation alias at 0x20000
//   D. 32 KB TCM: first/last word and the alias at 0x8000
//
// Port truncation is documented rather than "fixed": the SoC decode never
// routes an address outside a region to its memory, and audit_memory.js checks
// that the interconnect aperture equals the address-map size.
//------------------------------------------------------------------------------
module tb_mem_contract;

  reg clk = 0;
  always #5 clk = ~clk;

  integer errors = 0;
  integer checks = 0;

  task check(input cond, input [1023:0] msg);
    begin
      checks = checks + 1;
      if (!cond) begin
        $display("[mem] FAIL %0s", msg);
        errors = errors + 1;
      end else begin
        $display("[mem] pass %0s", msg);
      end
    end
  endtask

  //============================================================================
  // DUTs at the SoC parameterisation
  //============================================================================
  reg          reset_n = 0;

  reg          s_awvalid = 0, s_wvalid = 0, s_bready = 0;
  reg          s_arvalid = 0, s_rready = 0;
  reg  [16:0]  s_awaddr = 0, s_araddr = 0;
  reg  [31:0]  s_wdata = 0;
  reg  [3:0]   s_wstrb = 0;
  wire         s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
  wire [31:0]  s_rdata;
  wire [1:0]   s_bresp, s_rresp;
  reg          s_i_req = 0;
  reg  [16:0]  s_i_addr = 0;
  wire         s_i_gnt, s_i_rvalid;
  wire [31:0]  s_i_rdata;

  sram #(.ADDR_WIDTH(17)) sram_dut (
    .clk(clk), .reset_n(reset_n),
    .awvalid(s_awvalid), .awaddr(s_awaddr), .awready(s_awready),
    .wvalid(s_wvalid), .wdata(s_wdata), .wstrb(s_wstrb), .wready(s_wready),
    .bvalid(s_bvalid), .bready(s_bready), .bresp(s_bresp),
    .arvalid(s_arvalid), .araddr(s_araddr), .arready(s_arready),
    .rvalid(s_rvalid), .rdata(s_rdata), .rresp(s_rresp), .rready(s_rready),
    .i_req(s_i_req), .i_addr(s_i_addr), .i_gnt(s_i_gnt),
    .i_rdata(s_i_rdata), .i_rvalid(s_i_rvalid)
  );

  reg          t_awvalid = 0, t_wvalid = 0, t_bready = 0;
  reg          t_arvalid = 0, t_rready = 0;
  reg  [14:0]  t_awaddr = 0, t_araddr = 0;
  reg  [31:0]  t_wdata = 0;
  reg  [3:0]   t_wstrb = 0;
  wire         t_awready, t_wready, t_bvalid, t_arready, t_rvalid;
  wire [31:0]  t_rdata;
  wire [1:0]   t_bresp, t_rresp;

  sram #(.ADDR_WIDTH(15)) tcm_dut (
    .clk(clk), .reset_n(reset_n),
    .awvalid(t_awvalid), .awaddr(t_awaddr), .awready(t_awready),
    .wvalid(t_wvalid), .wdata(t_wdata), .wstrb(t_wstrb), .wready(t_wready),
    .bvalid(t_bvalid), .bready(t_bready), .bresp(t_bresp),
    .arvalid(t_arvalid), .araddr(t_araddr), .arready(t_arready),
    .rvalid(t_rvalid), .rdata(t_rdata), .rresp(t_rresp), .rready(t_rready),
    .i_req(1'b0), .i_addr(15'd0), .i_gnt(), .i_rdata(), .i_rvalid()
  );

  reg          r_req = 0;
  reg  [13:0]  r_addr = 0;
  wire         r_gnt, r_rvalid;
  wire [31:0]  r_rdata;
  reg          r_awvalid = 0, r_wvalid = 0, r_bready = 0;
  reg          r_arvalid = 0, r_rready = 0;
  reg  [31:0]  r_awaddr = 0, r_araddr = 0, r_wdata = 0;
  reg  [3:0]   r_wstrb = 0;
  wire         r_awready, r_wready, r_bvalid, r_arready, r_rval;
  wire [31:0]  r_rddata;
  wire [1:0]   r_bresp, r_rresp;

  boot_rom #(.ADDR_WIDTH(14)) rom_dut (
    .clk(clk), .reset_n(reset_n),
    .req(r_req), .addr(r_addr), .gnt(r_gnt), .rdata(r_rdata), .rvalid(r_rvalid),
    .awvalid(r_awvalid), .awready(r_awready), .awaddr(r_awaddr),
    .wvalid(r_wvalid), .wready(r_wready), .wdata(r_wdata), .wstrb(r_wstrb),
    .bvalid(r_bvalid), .bready(r_bready), .bresp(r_bresp),
    .arvalid(r_arvalid), .arready(r_arready), .araddr(r_araddr),
    .r_rvalid(r_rval), .r_rready(r_rready), .r_rdata(r_rddata), .r_rresp(r_rresp)
  );

  //============================================================================
  // AXI4-Lite helpers (same cycle-accurate sequence as tb_sram_audit.v)
  //============================================================================
  // Address arguments are one bit wider than the DUT port on purpose: the
  // top bit is what the port drops, and the TB asserts the resulting alias.
  task sram_write(input [17:0] a, input [31:0] d, input [3:0] strb);
    begin
      @(posedge clk);
      s_bready = 0;
      s_awvalid = 1; s_awaddr = a[16:0]; s_wvalid = 1; s_wdata = d; s_wstrb = strb;
      repeat (2) @(posedge clk);
      s_awvalid = 0; s_wvalid = 0;
      repeat (2) @(posedge clk);
      if (!s_bvalid) begin
        $display("[mem] FAIL sram write response missing for %h", a);
        errors = errors + 1;
      end
      s_bready = 1; @(posedge clk); s_bready = 0;
    end
  endtask

  task sram_read(input [17:0] a, output [31:0] d);
    begin
      @(posedge clk);
      s_rready = 0;
      s_arvalid = 1; s_araddr = a[16:0];
      repeat (2) @(posedge clk);
      s_arvalid = 0;
      repeat (2) @(posedge clk);
      d = s_rdata;
      if (!s_rvalid) begin
        $display("[mem] FAIL sram read response missing for %h", a);
        errors = errors + 1;
      end
      s_rready = 1; @(posedge clk); s_rready = 0;
    end
  endtask

  task tcm_write(input [15:0] a, input [31:0] d, input [3:0] strb);
    begin
      @(posedge clk);
      t_bready = 0;
      t_awvalid = 1; t_awaddr = a[14:0]; t_wvalid = 1; t_wdata = d; t_wstrb = strb;
      repeat (2) @(posedge clk);
      t_awvalid = 0; t_wvalid = 0;
      repeat (2) @(posedge clk);
      if (!t_bvalid) begin
        $display("[mem] FAIL tcm write response missing for %h", a);
        errors = errors + 1;
      end
      t_bready = 1; @(posedge clk); t_bready = 0;
    end
  endtask

  task tcm_read(input [15:0] a, output [31:0] d);
    begin
      @(posedge clk);
      t_rready = 0;
      t_arvalid = 1; t_araddr = a[14:0];
      repeat (2) @(posedge clk);
      t_arvalid = 0;
      repeat (2) @(posedge clk);
      d = t_rdata;
      if (!t_rvalid) begin
        $display("[mem] FAIL tcm read response missing for %h", a);
        errors = errors + 1;
      end
      t_rready = 1; @(posedge clk); t_rready = 0;
    end
  endtask

  // ROM instruction port: accept in IF_IDLE, data the following cycle.
  // Drive and sample on the negative edge so no blocking assignment races the
  // DUT's nonblocking update in the same time step.
  task rom_fetch(input [15:0] a, output [31:0] d);
    begin
      @(negedge clk);
      r_req = 1; r_addr = a[13:0];
      @(negedge clk);          // DUT has moved IF_IDLE -> IF_DATA
      r_req = 0;
      d = r_rdata;
      if (!r_rvalid) begin
        $display("[mem] FAIL rom fetch rvalid missing for %h", a);
        errors = errors + 1;
      end
      @(negedge clk);          // let the DUT return to IF_IDLE
    end
  endtask

  // The package function is called in a statement, not inside a task argument:
  // this Icarus version cannot parse a package-scoped call in that position.
  integer region;
  task check_region(input [31:0] a, input integer want, input [1023:0] msg);
    begin
      region = addr_region(a);
      check(region == want, msg);
    end
  endtask

  reg [31:0] d;
  reg [31:0] d2;

  //============================================================================
  // Test
  //============================================================================
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("build/sim/tb_mem_contract.vcd");
      $dumpvars(0, tb_mem_contract);
    end

    reset_n = 0;
    repeat (5) @(posedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);

    //--------------------------------------------------------------------------
    // A. Address-map region boundaries (the contract itself)
    //--------------------------------------------------------------------------
    check_region(32'h0000_0000, 0, "A0  ROM base is region 0");
    check_region(32'h0000_3FFF, 0, "A1  ROM last byte (16 KB) is region 0");
    check_region(32'h0000_4000, 6, "A2  first byte after the ROM aperture is unmapped");

    check_region(32'h0001_0000, 1, "A3  TCM base is region 1");
    check_region(32'h0001_7FFF, 1, "A4  TCM last byte (32 KB) is region 1");
    check_region(32'h0001_8000, 6, "A5  first byte after the TCM aperture is unmapped");

    check_region(32'h2000_0000, 2, "A6  SRAM base is region 2");
    check_region(32'h2001_FFFF, 2, "A7  SRAM last byte (128 KB) is region 2");
    check_region(32'h2002_0000, 6, "A8  first byte after the SRAM aperture is unmapped");

    check_region(32'h4000_0000, 3, "A9  QSPI flash base is region 3");
    check_region(32'h5000_0000, 4, "A10 APB base is region 4");
    check_region(32'h8000_0000, 5, "A11 INTC base is region 5");
    check_region(32'h9000_0000, 6, "A12 address beyond every region is unmapped");

    //--------------------------------------------------------------------------
    // B. Boot ROM: 16 KB array
    //--------------------------------------------------------------------------
    rom_fetch(14'h0000, d);
    check(d === 32'h0000_0013, "B0 ROM word 0 is the NOP filler");
    rom_fetch(14'h3FFC, d);
    check(d === 32'h0000_0013, "B1 ROM last word (0x3FFC) is inside the 16 KB array");
    rom_fetch(14'h3FFC, d);
    rom_fetch(14'h0000, d2);
    check(d === d2, "B2 ROM is stable across fetches");

    // Port truncation: 0x4000 does not fit 14 bits, so it aliases to word 0.
    // The SoC never routes it here (sel_rom stops at 0x4000), which A1/A2 prove.
    rom_fetch(16'h4000, d);
    rom_fetch(16'h0000, d2);
    check(d === d2, "B3 ROM address bit 14 is not an array bit (documented alias)");

    //--------------------------------------------------------------------------
    // C. SoC SRAM: 128 KB array, byte writes in the last word
    //--------------------------------------------------------------------------
    sram_write(17'h00000, 32'h1111_1111, 4'hF);
    sram_read(17'h00000, d);
    check(d === 32'h1111_1111, "C0 SRAM first word");

    sram_write(17'h1FFFC, 32'hA5A5_A5A5, 4'hF);
    sram_read(17'h1FFFC, d);
    check(d === 32'hA5A5_A5A5, "C1 SRAM last word (0x1FFFC) is inside the 128 KB array");

    sram_write(17'h1FFFC, 32'hA5A5_A5A5, 4'hF);
    sram_write(17'h1FFFC, 32'h0000_00C3, 4'h1);   // byte 0 only
    sram_read(17'h1FFFC, d);
    check(d === 32'hA5A5_A5C3, "C2 byte 0 write at the last word");
    sram_write(17'h1FFFC, 32'hDE00_0000, 4'h8);   // byte 3 only
    sram_read(17'h1FFFC, d);
    check(d === 32'hDEA5_A5C3, "C3 byte 3 write at the last word");

    sram_write(17'h0FFFC, 32'h5A5A_5A5A, 4'hF);
    sram_read(17'h0FFFC, d);
    check(d === 32'h5A5A_5A5A, "C4 word below the SRAM half-way boundary");

    // Port truncation: address 0x20000 does not fit 17 bits.
    sram_write(18'h20000, 32'hFFFF_FFFF, 4'hF);
    sram_read(17'h00000, d);
    check(d === 32'hFFFF_FFFF, "C5 SRAM address bit 17 is not an array bit (documented alias)");

    sram_write(17'h00000, 32'h1111_1111, 4'hF);

    //--------------------------------------------------------------------------
    // D. TCM: 32 KB array
    //--------------------------------------------------------------------------
    tcm_write(15'h0000, 32'h2222_2222, 4'hF);
    tcm_read(15'h0000, d);
    check(d === 32'h2222_2222, "D0 TCM first word");

    tcm_write(15'h7FFC, 32'h3333_3333, 4'hF);
    tcm_read(15'h7FFC, d);
    check(d === 32'h3333_3333, "D1 TCM last word (0x7FFC) is inside the 32 KB array");

    tcm_write(16'h8000, 32'h4444_4444, 4'hF);
    tcm_read(16'h0000, d);
    check(d === 32'h4444_4444, "D2 TCM address bit 15 is not an array bit (documented alias)");

    //--------------------------------------------------------------------------
    $display("[mem] checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TB_MEM_CONTRACT: ALL TESTS PASSED");
      $finish;
    end else begin
      $fatal(1, "TB_MEM_CONTRACT: %0d FAILURES", errors);
    end
  end

endmodule
