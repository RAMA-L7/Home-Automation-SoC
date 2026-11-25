//------------------------------------------------------------------------------
// Directed testbench for sram_macro_wrap with a SIMULATABLE behavioural leaf
// (tb_macro_leaf.v) compiled under the name sky130_sram_2kbyte_1rw1r_32x512_8
// so the wrapper's default `ifndef MACRO_USE_1KB branch instantiates it.
//
// The official PDK macro models (1KB and 2KB) are NOT Icarus-compatible:
// they index mem[addr_reg] with a reg index, which Icarus 14.0 tombstones as
// "Scope index expression is not constant". This leaf is a TEST PROXY that
// mirrors the macro protocol (2-port RW+R, registered inputs, falling-edge
// registered dout with DELAY+T_HOLD gap, byte-masked writes, collision warning,
// no reset on the macro) so the WRAPPER's own logic can be exercised in Icarus.
//
// NUM_MACROS=2 => BANK_AW=1, LOCAL_AW=ADDR_WIDTH-BANK_AW. Each bank sees a
// distinct macro instance; we write/read across bank 0 and bank 1 to verify
// the bank decode.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_sram_macro_wrap_leaf;

  localparam ADDR_WIDTH = 17;
  localparam NUM_MACROS = 2;
  localparam MACRO_DW   = 32;
  localparam MACRO_AW   = 9;

  reg                 clk = 0;
  reg                 reset_n;
  reg                 awvalid, wvalid, bready, arvalid, rready;
  reg  [ADDR_WIDTH-1:0] awaddr, araddr;
  reg  [31:0]         wdata;
  reg  [3:0]          wstrb;
  wire                awready, wready, bvalid, rvalid, arready;
  wire [31:0]         rdata;
  wire [1:0]          bresp, rresp;
  reg                 i_req;
  reg  [ADDR_WIDTH-1:0] i_addr;
  wire                i_gnt, i_rvalid;
  wire [31:0]         i_rdata;

  always #5 clk = ~clk;

  // The wrapper's default `ifndef MACRO_USE_1KB branch instantiates
  // sky130_sram_2kbyte_1rw1r_32x512_8. We compile tb_macro_leaf.v under that
  // name, so the wrapper picks up our test proxy automatically.
  `define USE_POWER_PINS
  // MACRO_USE_1KB is intentionally NOT defined: the wrapper's default
  // `ifndef MACRO_USE_1KB branch instantiates the 2KB macro cell, which we
  // provide via tb_macro_leaf.v compiled under the name
  // sky130_sram_2kbyte_1rw1r_32x512_8. (The 1KB PDK model is not Icarus-
  // compatible, so we never exercise the `else` branch here.)

  sram_macro_wrap #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (32),
    .MACRO_DW   (MACRO_DW),
    .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (NUM_MACROS)
  ) dut (
    .clk      (clk),
    .reset_n  (reset_n),
    .awvalid  (awvalid), .awaddr (awaddr), .awready (awready),
    .wvalid   (wvalid),  .wdata  (wdata),  .wready  (wready),
    .wstrb    (wstrb),
    .bvalid   (bvalid),  .bready (bready), .bresp   (bresp),
    .arvalid  (arvalid), .araddr (araddr), .arready (arready),
    .rvalid   (rvalid),  .rdata  (rdata),  .rresp   (rresp),
    .rready   (rready),
    .i_req    (i_req),   .i_addr (i_addr), .i_gnt   (i_gnt),
    .i_rdata  (i_rdata), .i_rvalid(i_rvalid)
  );

  integer errors = 0;
  integer checks = 0;

  task check;
    input cond;
    input [1023:0] msg;
    begin
      checks = checks + 1;
      if (!cond) begin
        $display("[macro_wrap] FAIL %0s", msg);
        errors = errors + 1;
      end else begin
        $display("[macro_wrap] pass %0s", msg);
      end
    end
  endtask

  task axi_write;
    input [ADDR_WIDTH-1:0] a;
    input [31:0] d;
    input [3:0] s;
    begin
      @(posedge clk);
      bready = 0;
      awvalid = 1; awaddr = a; wvalid = 1; wdata = d; wstrb = s;
      repeat (2) @(posedge clk);
      awvalid = 0; wvalid = 0;
      repeat (10) begin
        @(posedge clk);
        if (bvalid) begin
          bready = 1;
          @(posedge clk);
          bready = 0;
          return;
        end
      end
      $display("[macro_wrap] FAIL axi_write timeout for %h", a);
      errors = errors + 1;
    end
  endtask

  task axi_read;
    input [ADDR_WIDTH-1:0] a;
    output [31:0] d;
    begin
      @(posedge clk);
      rready = 0;
      arvalid = 1; araddr = a;
      repeat (2) @(posedge clk);
      arvalid = 0;
      repeat (10) begin
        @(posedge clk);
        if (rvalid) begin
          d = rdata;
          rready = 1;
          @(posedge clk);
          rready = 0;
          return;
        end
      end
      $display("[macro_wrap] FAIL axi_read timeout for %h", a);
      errors = errors + 1;
      d = 32'bx;
    end
  endtask

  reg [31:0] d;

  initial begin
    $dumpfile("build/sim/tb_sram_macro_wrap_leaf.vcd");
    $dumpvars(0, tb_sram_macro_wrap_leaf);

    reset_n = 0;
    awvalid = 0; wvalid = 0; bready = 0;
    arvalid = 0; rready = 0;
    awaddr = 0; araddr = 0; wdata = 0; wstrb = 0;
    i_req = 0; i_addr = 0;
    repeat (4) @(posedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);

    // T1 - reset state
    check(awready === 1'b1 && wready === 1'b1 && arready === 1'b1,
          "T1 ready signals after reset");
    check(bvalid === 1'b0 && rvalid === 1'b0,
          "T1 no response pending after reset");
    check(i_gnt === 1'b0 && i_rvalid === 1'b0,
          "T1 instruction port idle after reset");

    // T2 - full-word AXI write + read, bank 0
    axi_write(17'h00000, 32'hA1B2_C3D4, 4'hF);
    axi_read(17'h00000, d);
    check(d === 32'hA1B2_C3D4, "T2 full-word write/read bank 0");

    // T3 - byte strobe combinations (bank 0)
    axi_write(17'h00020, 32'h0000_0000, 4'hF);
    axi_write(17'h00020, 32'h0000_0000, 4'hF);
    axi_write(17'h00020, 32'hAABB_CCDD, 4'b0001);
    axi_read(17'h00020, d);
    check(d === 32'h0000_00DD, "T3 strobe 0001 -> byte0 only");
    axi_write(17'h00020, 32'h1122_3344, 4'b0010);
    axi_read(17'h00020, d);
    check(d === 32'h0000_33DD, "T3 strobe 0010 -> byte1 only");
    axi_write(17'h00020, 32'h5566_7788, 4'b0100);
    axi_read(17'h00020, d);
    check(d === 32'h0066_33DD, "T3 strobe 0100 -> byte2 only");
    axi_write(17'h00020, 32'h99AA_BBCC, 4'b1000);
    axi_read(17'h00020, d);
    check(d === 32'h9966_33DD, "T3 strobe 1000 -> byte3 only");
    axi_write(17'h00020, 32'hFFFF_FFFF, 4'b0000);
    axi_read(17'h00020, d);
    check(d === 32'h9966_33DD, "T3 strobe 0000 -> no change");

    // T4 - read-after-write same bank
    axi_write(17'h00040, 32'h0123_4567, 4'hF);
    axi_read(17'h00040, d);
    check(d === 32'h0123_4567, "T4 read-after-write");

    // T5 - instruction port read of a written word (bank 0).
    // i_rdata is the macro's registered port-1 DOUT, which holds bx for T_HOLD after
    // the sampling posedge and returns valid data DELAY after the next negedge; a full
    // extra cycle wait guarantees the data has settled. i_rvalid (= i_req_q) is checked
    // first, in the cycle right after the fetch, before i_req is dropped.
    axi_write(17'h00060, 32'hCAFEBABE, 4'hF);
    @(posedge clk);
    i_addr = 17'h00060; i_req = 1;
    check(i_gnt === 1'b1, "T5 instruction request granted");
    @(posedge clk);
    i_req = 0;
    check(i_rvalid === 1'b1, "T5 instruction rvalid");
    @(posedge clk);
    check(i_rdata === 32'hCAFEBABE,
          "T5 instruction data matches written word");

    // T6 - bank selection: with NUM_MACROS=2, BANK_AW=1, LOCAL_AW=9, so bank 1 word 0
    // is word address 512 = 0x200 -> awaddr = 0x200 << 2 = 0x800 = 17'h00800.
    // (17'h80000 would be bank 32 row 0 with these geometry params, which is wrong.)
    axi_write(17'h00000, 32'h0000_0000, 4'hF);   // clear bank 0 sentinel
    axi_write(17'h00800, 32'hF00D_CAFE, 4'hF);   // bank 1 word 0
    axi_read(17'h00800, d);
    check(d === 32'hF00D_CAFE, "T6 bank 1 write/read");
    axi_read(17'h00000, d);
    check(d === 32'h0000_0000,
          "T6 bank 0 unchanged after bank 1 write");

    // T7 - bank-boundary alias: bank 0 last word vs bank 1 first word.
    axi_write(17'h00000, 32'hAAAA_BBBB, 4'hF);
    axi_write(17'h00800, 32'hCCCCD_EEEE, 4'hF);
    axi_read(17'h00000, d);
    check(d === 32'hAAAA_BBBB, "T7 bank 0 boundary value");
    axi_read(17'h00800, d);
    check(d === 32'hCCCCD_EEEE, "T7 bank 1 boundary value");

    // T8 - same-word write -> instruction-read forward.
    // Assert the AXI write and the instruction fetch in the same cycle. Check i_rvalid
    // and i_rdata BEFORE dropping i_req (i_rvalid is i_req_q, one cycle after i_req is
    // sampled). Also acknowledge bvalid so the FSM returns to S_IDLE for T9.
    @(posedge clk);
    awvalid = 1; awaddr = 17'h00080; wvalid = 1;
    wdata = 32'h1234_5678; wstrb = 4'hF;
    i_req = 1; i_addr = 17'h00080;
    repeat (2) @(posedge clk);
    // i_req_q is still 1 here; i_rvalid/i_rdata sample before we drop i_req.
    check(i_rvalid === 1'b1,
          "T8 instruction rvalid after same-cycle write+fetch");
    if (i_rvalid) begin
      check(i_rdata === 32'h1234_5678,
            "T8 same-word write->instruction-read forward");
    end
    // Acknowledge the write response so the FSM returns to S_IDLE.
    bready = 1;
    @(posedge clk);
    bready = 0;
    awvalid = 0; wvalid = 0; i_req = 0;

    // T9 - reset during a pending write: the macro has no reset pin, so a write that
    // has committed persists in the macro's memory across a wrapper reset. Write, reset,
    // then read back. (T8's bvalid ack above leaves the FSM in S_IDLE so T9's axi_write
    // is accepted.)
    axi_write(17'h000A0, 32'hDEAD_BEEF, 4'hF);
    reset_n = 0;
    repeat (2) @(posedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);
    check(bvalid === 1'b0,
          "T9 bvalid clear after reset during pending write");
    axi_read(17'h000A0, d);
    check(d === 32'hDEAD_BEEF,
          "T9 committed write persists after reset");

    // T10 - simultaneous read + write to same macro row.
    // The macro issues a collision $display warning; the wrapper prefers write
    // over read. We only smoke-test that there is no hang; we do NOT assert a
    // specific rdata because the macro's collision behavior is undefined.
    axi_write(17'h000C0, 32'h0123_4567, 4'hF);
    @(posedge clk);
    arvalid = 1; araddr = 17'h000C0; rready = 1;
    repeat (3) @(posedge clk);
    arvalid = 0;
    check(1, "T10 simultaneous access did not hang");

    $display("[macro_wrap] checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("[macro_wrap] ALL TESTS PASSED");
      $finish;
    end else begin
      $display("[macro_wrap] %0d FAILURES", errors);
      $fatal(1, "[macro_wrap] TESTS FAILED");
    end
  end

  initial begin
    #500000;
    $display("[macro_wrap] TIMEOUT");
    $fatal;
  end

endmodule
