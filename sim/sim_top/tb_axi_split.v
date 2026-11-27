`timescale 1ns/1ps
//------------------------------------------------------------------------------
// AXI4-Lite split-channel write testbench
//
// WHY THIS EXISTS
//   AXI4-Lite defines AW and W as independent channels: a slave must accept
//   either one first and remember it until the matching half arrives.  The
//   memory slaves in this tree evaluated `awvalid & wvalid` in a single cycle
//   and derived the write index from the live `awaddr`, so:
//     * address-first: `awready` was asserted and the address was "accepted",
//       then the write never happened (the master saw a handshake and a
//       response only if it also held W, which it does not have to);
//     * data-first: the data sat until an address arrived, which is correct
//       only by accident and broke as soon as two writes overlapped.
//   The SoC never exposed this because `axi_lite_interconnect` holds both
//   channels and presents them together.  A different master (a debug bridge,
//   a DMA, a third-party IP) does not.
//
// WHAT IT CHECKS, ON THREE INDEPENDENT DUTs
//   u_sram   rtl/rtl_top/sram.sv             (behavioural array)
//   u_macro  rtl/rtl_top/sram_macro_wrap.sv  (64-bank production geometry)
//   u_rom    rtl/rtl_top/boot_rom.sv         (read-only, must answer SLVERR)
//
//   S1 address-first, S2 data-first, S3 simultaneous, S4 response backpressure,
//   S5 reset with an address outstanding, S6 simultaneous read+write (write
//   priority must still make progress), S7 byte strobes over split channels,
//   S8 ROM read plus split-channel write rejected with SLVERR.
//
// Run:
//   iverilog -g2012 -o build/sim/tb_axi_split.vvp -s tb_axi_split \
//     sim/sim_top/tb_axi_split.v rtl/rtl_top/sram.sv \
//     rtl/rtl_top/sram_macro_wrap.sv rtl/rtl_top/boot_rom.sv \
//     sim/models/sky130_sram_sim_model.v
//   vvp build/sim/tb_axi_split.vvp
//------------------------------------------------------------------------------
module tb_axi_split;

  localparam int AW        = 17;   // sram / macro wrapper byte address
  localparam int MACROS    = 64;   // 64 x 2 KiB = 128 KiB
  localparam int ROM_AW    = 14;   // 16 KiB ROM

  reg clk = 0;
  reg reset_n;

  // Shared AXI stimulus, fanned out to every DUT identically.
  reg          awvalid, wvalid, bready, arvalid, rready;
  reg  [AW-1:0] awaddr, araddr;
  reg  [31:0]  wdata;
  reg  [3:0]   wstrb;

  // sram
  wire         awready_s, wready_s, bvalid_s, arready_s, rvalid_s;
  wire [31:0]  rdata_s;
  wire [1:0]   bresp_s, rresp_s;

  // sram_macro_wrap
  wire         awready_m, wready_m, bvalid_m, arready_m, rvalid_m;
  wire [31:0]  rdata_m;
  wire [1:0]   bresp_m, rresp_m;

  // boot_rom (32-bit address port, different read-port names)
  wire         awready_r, wready_r, bvalid_r, arready_r, r_rvalid;
  wire [31:0]  r_rdata;
  wire [1:0]   bresp_r, r_rresp;

  always #5 clk = ~clk;

  sram #(.ADDR_WIDTH(AW)) u_sram (
    .clk(clk), .reset_n(reset_n),
    .awvalid(awvalid), .awaddr(awaddr), .awready(awready_s),
    .wvalid(wvalid), .wdata(wdata), .wstrb(wstrb), .wready(wready_s),
    .bvalid(bvalid_s), .bready(bready), .bresp(bresp_s),
    .arvalid(arvalid), .araddr(araddr), .arready(arready_s),
    .rvalid(rvalid_s), .rdata(rdata_s), .rresp(rresp_s), .rready(rready),
    .i_req(1'b0), .i_addr({AW{1'b0}}), .i_gnt(), .i_rdata(), .i_rvalid()
  );

  sram_macro_wrap #(.ADDR_WIDTH(AW), .NUM_MACROS(MACROS)) u_macro (
    .clk(clk), .reset_n(reset_n),
    .awvalid(awvalid), .awaddr(awaddr), .awready(awready_m),
    .wvalid(wvalid), .wdata(wdata), .wstrb(wstrb), .wready(wready_m),
    .bvalid(bvalid_m), .bready(bready), .bresp(bresp_m),
    .arvalid(arvalid), .araddr(araddr), .arready(arready_m),
    .rvalid(rvalid_m), .rdata(rdata_m), .rresp(rresp_m), .rready(rready),
    .i_req(1'b0), .i_addr({AW{1'b0}}), .i_gnt(), .i_rdata(), .i_rvalid()
  );

  boot_rom #(.ADDR_WIDTH(ROM_AW)) u_rom (
    .clk(clk), .reset_n(reset_n),
    .req(1'b0), .addr({ROM_AW{1'b0}}), .gnt(), .rdata(), .rvalid(),
    // The ROM data port ignores both addresses; its aperture is not under test.
    .awvalid(awvalid), .awready(awready_r), .awaddr(32'h0000_0000),
    .wvalid(wvalid), .wready(wready_r), .wdata(wdata), .wstrb(wstrb),
    .bvalid(bvalid_r), .bready(bready), .bresp(bresp_r),
    .arvalid(arvalid), .arready(arready_r), .araddr(32'h0000_0000),
    .r_rvalid(r_rvalid), .r_rready(rready), .r_rdata(r_rdata), .r_rresp(r_rresp)
  );

  integer checks = 0;
  integer errors = 0;
  integer guard  = 0;

  task check(input cond, input [1023:0] msg);
    begin
      checks = checks + 1;
      if (!cond) begin
        $display("[split] FAIL %0s", msg);
        errors = errors + 1;
      end else begin
        $display("[split] pass %0s", msg);
      end
    end
  endtask

  //--------------------------------------------------------------------------
  // Channel helpers.  Everything is driven on the falling edge and sampled on
  // the rising edge, so there is no race between the bench and the DUT.
  //--------------------------------------------------------------------------
  task send_aw(input [AW-1:0] a, input [1023:0] tag);
    integer guard;
    begin
      @(negedge clk); awvalid = 1; awaddr = a;
      guard = 0;
      @(posedge clk);
      while (!(awready_s & awready_m & awready_r) && guard < 40) begin
        guard = guard + 1;
        @(posedge clk);
      end
      check(awready_s & awready_m & awready_r, tag);
      check(guard < 40, "AW accepted within the guard window");
      @(negedge clk); awvalid = 0;
    end
  endtask

  task send_w(input [31:0] d, input [3:0] s, input [1023:0] tag);
    integer guard;
    begin
      @(negedge clk); wvalid = 1; wdata = d; wstrb = s;
      guard = 0;
      @(posedge clk);
      while (!(wready_s & wready_m & wready_r) && guard < 40) begin
        guard = guard + 1;
        @(posedge clk);
      end
      check(wready_s & wready_m & wready_r, tag);
      check(guard < 40, "W accepted within the guard window");
      @(negedge clk); wvalid = 0;
    end
  endtask

  // Wait for the write response on both writable DUTs and release it.
  task wait_b(input [1023:0] tag);
    integer guard;
    begin
      @(negedge clk); bready = 1;
      guard = 0;
      @(posedge clk);
      while (!(bvalid_s & bvalid_m & bvalid_r) && guard < 40) begin
        guard = guard + 1;
        @(posedge clk);
      end
      check(bvalid_s & bvalid_m & bvalid_r, tag);
      check(guard < 40, "B response within the guard window");
      check(bresp_s == 2'b00, "sram BRESP OKAY");
      check(bresp_m == 2'b00, "macro wrapper BRESP OKAY");
      @(negedge clk); bready = 0;
    end
  endtask

  task axi_read(input [AW-1:0] a, output [31:0] ds, output [31:0] dm);
    integer guard;
    begin
      @(negedge clk); arvalid = 1; araddr = a; rready = 0;
      guard = 0;
      @(posedge clk);
      while (!(arready_s & arready_m) && guard < 40) begin
        guard = guard + 1;
        @(posedge clk);
      end
      check(arready_s & arready_m, "AR accepted on both writable slaves");
      @(negedge clk); arvalid = 0; rready = 1;
      guard = 0;
      @(posedge clk);
      while (!(rvalid_s & rvalid_m) && guard < 40) begin
        guard = guard + 1;
        @(posedge clk);
      end
      check(rvalid_s & rvalid_m, "R response on both writable slaves");
      ds = rdata_s; dm = rdata_m;
      @(negedge clk); rready = 0;
    end
  endtask

  reg [31:0] ds, dm;

  initial begin
    $dumpfile("build/sim/tb_axi_split.vcd");
    $dumpvars(0, tb_axi_split);

    reset_n = 0; awvalid = 0; wvalid = 0; bready = 0; arvalid = 0; rready = 0;
    awaddr = 0; araddr = 0; wdata = 0; wstrb = 0;
    repeat (4) @(posedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);

    //------------------------------------------------------------------ S0
    check(awready_s && wready_s && arready_s,  "S0 sram ready after reset");
    check(awready_m && wready_m && arready_m,  "S0 wrapper ready after reset");
    check(!bvalid_s && !bvalid_m,              "S0 no response pending");

    //------------------------------------------------------------------ S1
    // Address first, data two cycles later.  On the pre-fix RTL the address
    // handshake succeeds, the write never commits, and no B response appears.
    send_aw(17'h100, "S1 AW accepted alone (address-first)");
    repeat (2) @(posedge clk);
    check(!bvalid_s && !bvalid_m, "S1 no B before W arrives");
    send_w(32'hDEAD_BEEF, 4'hF, "S1 W accepted after AW");
    wait_b("S1 B response for address-first write");
    axi_read(17'h100, ds, dm);
    check(ds === 32'hDEAD_BEEF, "S1 sram committed the address-first write");
    check(dm === 32'hDEAD_BEEF, "S1 wrapper committed the address-first write");

    //------------------------------------------------------------------ S2
    // Data first, address two cycles later.
    send_w(32'h1234_5678, 4'hF, "S2 W accepted alone (data-first)");
    repeat (2) @(posedge clk);
    send_aw(17'h104, "S2 AW accepted after W");
    wait_b("S2 B response for data-first write");
    axi_read(17'h104, ds, dm);
    check(ds === 32'h1234_5678, "S2 sram committed the data-first write");
    check(dm === 32'h1234_5678, "S2 wrapper committed the data-first write");

    //------------------------------------------------------------------ S3
    // Simultaneous AW+W (the only case the pre-fix RTL handled) with strobes.
    @(negedge clk);
    awvalid = 1; awaddr = 17'h108; wvalid = 1; wdata = 32'hA5A5_5A5A; wstrb = 4'hF;
    @(posedge clk);
    check(awready_s && awready_m, "S3 AW accepted in the simultaneous cycle");
    @(negedge clk); awvalid = 0; wvalid = 0;
    wait_b("S3 B response for simultaneous write");
    axi_read(17'h108, ds, dm);
    check(ds === 32'hA5A5_5A5A, "S3 sram simultaneous write");
    check(dm === 32'hA5A5_5A5A, "S3 wrapper simultaneous write");

    //------------------------------------------------------------------ S4
    // Response backpressure: hold BREADY low for 8 cycles while BVALID stands.
    @(negedge clk);
    awvalid = 1; awaddr = 17'h10C; wvalid = 1; wdata = 32'hCAFE_0001; wstrb = 4'hF;
    bready = 0;
    @(posedge clk);
    @(negedge clk); awvalid = 0; wvalid = 0;
    repeat (8) begin
      @(posedge clk);
      check(bvalid_s && bvalid_m, "S4 BVALID held under backpressure");
    end
    @(negedge clk); bready = 1;
    @(posedge clk);
    @(negedge clk); bready = 0;
    axi_read(17'h10C, ds, dm);
    check(ds === 32'hCAFE_0001, "S4 sram write survived backpressure");
    check(dm === 32'hCAFE_0001, "S4 wrapper write survived backpressure");

    //------------------------------------------------------------------ S5
    // Reset with an accepted address outstanding: nothing may commit later.
    send_aw(17'h200, "S5 AW accepted before reset");
    @(negedge clk); reset_n = 0;
    repeat (2) @(posedge clk);
    @(negedge clk); reset_n = 1;
    repeat (2) @(posedge clk);
    check(awready_s && wready_s && arready_s, "S5 sram ready again after reset");
    check(awready_m && wready_m && arready_m, "S5 wrapper ready again after reset");
    // The stale address must be gone.  Present W alone (data-first): it must be
    // held with no response, and the next AW must pair with it.  That proves
    // both that the abandoned AW was dropped and that a held W survives reset
    // bookkeeping correctly (AXI: the data belongs to the address that follows).
    send_w(32'hFFFF_FFFF, 4'hF, "S5 W accepted alone after reset (stale AW dropped)");
    repeat (2) @(posedge clk);
    check(!bvalid_s && !bvalid_m, "S5 no response for a W with no address");
    axi_read(17'h200, ds, dm);
    check(ds !== 32'hFFFF_FFFF, "S5 sram did not commit the abandoned write");
    check(dm !== 32'hFFFF_FFFF, "S5 wrapper did not commit the abandoned write");
    send_aw(17'h208, "S5 post-reset AW pairs with the held W");
    wait_b("S5 post-reset B");
    axi_read(17'h208, ds, dm);
    check(ds === 32'hFFFF_FFFF, "S5 sram usable after reset (held W committed here)");
    check(dm === 32'hFFFF_FFFF, "S5 wrapper usable after reset (held W committed here)");
    axi_read(17'h200, ds, dm);
    check(ds !== 32'hFFFF_FFFF, "S5 sram left the abandoned address untouched");
    check(dm !== 32'hFFFF_FFFF, "S5 wrapper left the abandoned address untouched");

    //------------------------------------------------------------------ S6
    // Simultaneous read and write must still make progress (write priority),
    // and the deferred read must then complete rather than be lost.
    @(negedge clk);
    awvalid = 1; awaddr = 17'h300; wvalid = 1; wdata = 32'h0000_00AA; wstrb = 4'hF;
    arvalid = 1; araddr = 17'h108; rready = 1; bready = 1;
    @(posedge clk);
    check(awready_s && awready_m, "S6 write accepted when read is offered too");
    check(!arready_s && !arready_m, "S6 read deferred while the write commits");
    @(negedge clk); awvalid = 0; wvalid = 0;
    @(posedge clk);
    check(bvalid_s && bvalid_m, "S6 write response with a read outstanding");
    @(negedge clk); bready = 0;
    guard = 0;
    @(posedge clk);
    while (!(rvalid_s & rvalid_m) && guard < 40) begin
      guard = guard + 1;
      @(posedge clk);
    end
    check(rvalid_s & rvalid_m, "S6 deferred read completes after the write");
    check(rdata_s === 32'hA5A5_5A5A, "S6 read still returns the earlier value");
    check(rdata_m === 32'hA5A5_5A5A, "S6 wrapper read still returns the earlier value");
    @(negedge clk); arvalid = 0; rready = 0;
    axi_read(17'h300, ds, dm);
    check(ds === 32'h0000_00AA, "S6 write committed while the read waited");

    //------------------------------------------------------------------ S7
    // Byte strobes over split channels, on a word preloaded with zeros.
    send_aw(17'h400, "S7 AW for strobed write");
    repeat (1) @(posedge clk);
    send_w(32'h0000_0000, 4'hF, "S7 W zeroing the word");
    wait_b("S7 B for the zeroing write");
    send_w(32'h1122_3344, 4'b0001, "S7 W data-first, byte0 strobe");
    send_aw(17'h400, "S7 AW after the strobed data");
    wait_b("S7 B for the byte0 write");
    axi_read(17'h400, ds, dm);
    check(ds === 32'h0000_0044, "S7 sram strobe 0001 kept byte0 only");
    check(dm === 32'h0000_0044, "S7 wrapper strobe 0001 kept byte0 only");
    send_w(32'h5566_7788, 4'b1000, "S7 W byte3 strobe");
    send_aw(17'h400, "S7 AW for the byte3 write");
    wait_b("S7 B for the byte3 write");
    axi_read(17'h400, ds, dm);
    check(ds === 32'h5500_0044, "S7 sram strobe 1000 kept byte3 only");
    check(dm === 32'h5500_0044, "S7 wrapper strobe 1000 kept byte3 only");

    //------------------------------------------------------------------ S8
    // boot_rom: reads work, and a split-channel write is answered with SLVERR
    // instead of hanging.  (ROM AWADDR/ARADDR are 32-bit and unused here.)
    send_aw(17'h000, "S8 ROM AW accepted alone");
    repeat (2) @(posedge clk);
    check(!bvalid_r, "S8 ROM holds the write until W arrives");
    send_w(32'hFFFF_FFFF, 4'hF, "S8 ROM W accepted after AW");
    wait_b("S8 ROM B response for the read-only write");
    check(bresp_r == 2'b10, "S8 ROM answers SLVERR, not a hang");
    @(negedge clk); arvalid = 1; araddr = 0; rready = 1;
    @(posedge clk);
    check(arready_r, "S8 ROM AR accepted");
    @(negedge clk); arvalid = 0;
    @(posedge clk);
    check(r_rvalid && r_rdata === 32'h0000_0013, "S8 ROM read returns the NOP fill");
    @(negedge clk); rready = 0;

    //------------------------------------------------------------------ result
    $display("[split] checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("AXI SPLIT: ALL TESTS PASSED");
    else             $display("AXI SPLIT: FAIL (%0d errors)", errors);
    $finish;
  end

endmodule
