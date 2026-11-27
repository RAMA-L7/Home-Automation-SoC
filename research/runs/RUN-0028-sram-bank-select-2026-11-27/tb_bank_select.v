//------------------------------------------------------------------------------
// RUN-0028 — discriminating test for SRAM bank read-data selection
//
// WHAT IT DISCRIMINATES
//   The wrapper's AXI and instruction read paths select one of NUM_MACROS macro
//   DOUT buses by the bank captured one cycle earlier.  A select that is a
//   serial priority chain, a broken tree, or a swapped pair can all return
//   *some* data; only whole-bank coverage with unique per-bank patterns shows
//   that every bank returns its own word.
//
//   Phase 1 writes a unique pattern to words 0 and 7 of all 64 banks.
//   Phase 2 reads word 0 in bit-reversed bank order (each select bit exercised
//   alone and in combination).
//   Phase 3 reads word 7 in ascending order.
//   Phase 4 instruction-fetches word 0 in a 37-step permutation (37 is coprime
//   with 64, so it visits every bank exactly once and in a different order).
//   Phase 5 does back-to-back reads of opposite banks to check that the
//   registered bank capture is used, not the live address.
//
//   Every comparison is exact (!==), so X/Z fails.  The bench prints a rolling
//   digest of all (address, data) pairs so the prefix and postfix runs can be
//   compared byte for byte, not just pass/fail.
//
//   NEGATIVE CONTROL: tb_bank_select_mutant.v is the same wrapper with the
//   selected bank XORed by 1.  Compiling against it must produce failures;
//   a checker that passes everything is not discriminating.
//
// Build (same proxy macro model as tb_sram_macro_wrap.v):
//   iverilog -g2012 -DUSE_POWER_PINS -DSIM_MEM_PRELOAD -o build/sim/tb_bank_select.vvp \
//     -s tb_bank_select sim/models/sky130_sram_sim_model.v \
//     research/runs/RUN-0028-.../tb_bank_select.v rtl/rtl_top/sram_macro_wrap.sv
//   vvp build/sim/tb_bank_select.vvp
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_bank_select;

  localparam int AW      = 17;   // 128 KiB
  localparam int MACROS  = 64;
  localparam int MACRO_DW = 32;
  localparam int MACRO_AW = 9;   // 512 words per bank
  localparam int BANK_WORDS = 1 << MACRO_AW;

  reg clk = 1'b0;
  reg reset_n = 1'b0;
  always #5 clk = ~clk;

  reg  [AW-1:0] awaddr, araddr, iaddr;
  reg  [31:0]   wdata;
  reg  [3:0]    wstrb;
  reg           awvalid, wvalid, bready, arvalid, rready, ireq;
  wire          awready, wready, bvalid, arready, rvalid;
  wire          ignt, irvalid;
  wire [31:0]   rdata, irdata;
  wire [1:0]    bresp, rresp;

  sram_macro_wrap #(
    .ADDR_WIDTH (AW),
    .DATA_WIDTH (32),
    .MACRO_DW   (MACRO_DW),
    .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (MACROS)
  ) dut (
    .clk (clk), .reset_n (reset_n),
    .awvalid (awvalid), .awaddr (awaddr), .awready (awready),
    .wvalid  (wvalid),  .wdata  (wdata),  .wready  (wready), .wstrb (wstrb),
    .bvalid  (bvalid),  .bready (bready), .bresp   (bresp),
    .arvalid (arvalid), .araddr (araddr), .arready (arready),
    .rvalid  (rvalid),  .rdata  (rdata),  .rresp   (rresp), .rready (rready),
    .i_req   (ireq),    .i_addr (iaddr),  .i_gnt   (ignt),
    .i_rdata (irdata),  .i_rvalid (irvalid)
  );

  integer checks = 0, errors = 0, timeouts = 0;
  logic [31:0] digest = 32'h811C_9DC5;

  function automatic [31:0] pat(input int b, input int w);
    pat = {8'hA0 + b[7:0], 8'h5A, w[7:0], b[7:0] ^ w[7:0]};
  endfunction

  // Byte address of word `w` in bank `b`.
  function automatic [AW-1:0] addr_of(input int b, input int w);
    addr_of = ((b * BANK_WORDS + w) * 4);
  endfunction

  function automatic [5:0] rev6(input int b);
    rev6 = {b[0], b[1], b[2], b[3], b[4], b[5]};
  endfunction

  task automatic mix(input [AW-1:0] a, input [31:0] d);
    begin
      digest = {digest[30:0], digest[31]} ^ d ^ {14'd0, a[AW-1:2]};
    end
  endtask

  task automatic chk_eq32(input [AW-1:0] a, input [31:0] act, input [31:0] exp,
                          input [1023:0] name);
    begin
      checks = checks + 1;
      mix(a, act);
      if (act !== exp) begin
        errors = errors + 1;
        $display("[bank] FAIL %0s: addr=0x%05h got 0x%08h expected 0x%08h",
                 name, a, act, exp);
      end
    end
  endtask

  task automatic axi_write(input [AW-1:0] a, input [31:0] d, input [3:0] s);
    integer n;
    logic done;
    begin
      done = 1'b0;
      @(negedge clk);
      awvalid = 1'b1; awaddr = a;
      wvalid  = 1'b1; wdata  = d; wstrb = s;
      bready  = 1'b0;
      @(posedge clk);
      @(negedge clk);
      awvalid = 1'b0; wvalid = 1'b0;
      for (n = 0; n < 24; n = n + 1) begin
        @(posedge clk);
        if (bvalid === 1'b1) begin
          bready = 1'b1;
          @(posedge clk);
          bready = 1'b0;
          done = 1'b1;
          n = 24;
        end
      end
      if (!done) begin
        $display("[bank] FAIL write timeout addr=0x%05h", a);
        errors = errors + 1; timeouts = timeouts + 1;
        bready = 1'b0;
      end
    end
  endtask

  task automatic axi_read(input [AW-1:0] a, output [31:0] d);
    integer n;
    logic done;
    begin
      done = 1'b0;
      d = 32'hx;
      @(negedge clk);
      arvalid = 1'b1; araddr = a; rready = 1'b0;
      @(posedge clk);
      @(negedge clk);
      arvalid = 1'b0;
      for (n = 0; n < 24; n = n + 1) begin
        @(posedge clk);
        if (rvalid === 1'b1) begin
          d = rdata;
          rready = 1'b1;
          @(posedge clk);
          rready = 1'b0;
          done = 1'b1;
          n = 24;
        end
      end
      if (!done) begin
        $display("[bank] FAIL read timeout addr=0x%05h", a);
        errors = errors + 1; timeouts = timeouts + 1;
      end
    end
  endtask

  task automatic ifetch(input [AW-1:0] a, output [31:0] d);
    begin
      @(negedge clk);
      iaddr = a; ireq = 1'b1;
      @(posedge clk);
      checks = checks + 1;
      if (ignt !== 1'b1) begin
        errors = errors + 1;
        $display("[bank] FAIL i-port grant missing addr=0x%05h", a);
      end
      @(negedge clk);
      ireq = 1'b0;
      @(posedge clk);
      checks = checks + 1;
      if (irvalid !== 1'b1) begin
        errors = errors + 1;
        $display("[bank] FAIL i-port rvalid missing addr=0x%05h", a);
      end
      d = irdata;
    end
  endtask

  integer b, idx;
  logic [31:0] got;

  initial begin
    awvalid = 0; wvalid = 0; bready = 0; arvalid = 0; rready = 0; ireq = 0;
    awaddr = 0; araddr = 0; iaddr = 0; wdata = 0; wstrb = 0;
    repeat (5) @(posedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);

    $display("=== SRAM bank read-select discrimination (%0d banks) ===", MACROS);

    // Phase 1: unique data in every bank, two words per bank.
    for (b = 0; b < MACROS; b = b + 1) begin
      axi_write(addr_of(b, 0), pat(b, 0), 4'hF);
      axi_write(addr_of(b, 7), pat(b, 7), 4'hF);
    end

    // Phase 2: word 0, bit-reversed bank order.
    for (b = 0; b < MACROS; b = b + 1) begin
      idx = rev6(b);
      axi_read(addr_of(idx, 0), got);
      chk_eq32(addr_of(idx, 0), got, pat(idx, 0), "read word0 bitrev order");
    end

    // Phase 3: word 7, ascending.
    for (b = 0; b < MACROS; b = b + 1) begin
      axi_read(addr_of(b, 7), got);
      chk_eq32(addr_of(b, 7), got, pat(b, 7), "read word7 ascending");
    end

    // Phase 4: instruction fetch, 37-step permutation.
    for (b = 0; b < MACROS; b = b + 1) begin
      idx = (b * 37) % MACROS;
      ifetch(addr_of(idx, 0), got);
      chk_eq32(addr_of(idx, 0), got, pat(idx, 0), "ifetch permutation");
    end

    // Phase 5: back-to-back opposite banks (registered capture, not live addr).
    axi_read(addr_of(0, 0), got);
    chk_eq32(addr_of(0, 0), got, pat(0, 0), "b2b bank 0");
    axi_read(addr_of(63, 0), got);
    chk_eq32(addr_of(63, 0), got, pat(63, 0), "b2b bank 63");
    axi_read(addr_of(1, 7), got);
    chk_eq32(addr_of(1, 7), got, pat(1, 7), "b2b bank 1");
    axi_read(addr_of(62, 7), got);
    chk_eq32(addr_of(62, 7), got, pat(62, 7), "b2b bank 62");

    $display("[bank] checks=%0d errors=%0d timeouts=%0d digest=%08h",
             checks, errors, timeouts, digest);
    if (errors != 0 || timeouts != 0) begin
      $display("[bank] RESULT: FAIL");
      $fatal(1, "[bank] %0d error(s)", errors);
    end
    $display("[bank] RESULT: PASS");
    $finish;
  end

  initial begin
    #200_000;
    $display("[bank] TIMEOUT");
    $display("[bank] RESULT: FAIL");
    $fatal(1, "[bank] simulation timeout");
  end

endmodule
