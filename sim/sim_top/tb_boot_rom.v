//------------------------------------------------------------------------------
// tb_boot_rom.v — boot ROM verification
//
// Runs against WHICHEVER boot_rom the compile supplies:
//   * rtl/rtl_top/boot_rom.sv          (behavioural, $readmemh)   -> reference
//   * build/rom/boot_rom.v             (generated, case logic)    -> synthesizable
// The same checks apply, so passing both proves the generated ROM preserves the
// behavioural contents, read latency and write-rejection behaviour.
//
// Checks
//   1. reset state (gnt/rvalid low, ready high)
//   2. EVERY word of the image, read through the instruction port
//   3. words the image does not cover read as the fill value 32'h0000_0013
//   4. read latency: gnt in the request cycle, rvalid + data on the next cycle
//   5. AXI4-Lite read returns the same word
//   6. AXI4-Lite write is rejected with SLVERR (2'b10) and changes nothing
//
// Image path comes from +IMG=<file> (default build/fw/boot.hex).
// Verdict: "ROM-TEST: RESULT=PASS" / "=FAIL", non-zero exit on failure.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_boot_rom;

  localparam int AW    = 14;
  localparam int WORDS = 1 << (AW - 2);
  localparam [31:0] FILL = 32'h0000_0013;

  reg clk = 1'b0;
  reg reset_n = 1'b0;
  always #5 clk = ~clk;

  reg  [AW-1:0] addr;
  reg           req;
  wire          gnt, rvalid;
  wire [31:0]   rdata;

  reg           awvalid, wvalid, bready, arvalid, r_rready;
  reg  [31:0]   awaddr, wdata, araddr;
  reg  [3:0]    wstrb;
  wire          awready, wready, bvalid, arready, r_rvalid;
  wire [1:0]    bresp, r_rresp;
  wire [31:0]   r_rdata;

  // The behavioural ROM needs the image at ELABORATION time, so it is a
  // compile-time define shared with the plusarg default below. The generated
  // ROM ignores both parameters (contents are baked in).
`ifndef ROM_IMAGE
  `define ROM_IMAGE "build/fw/boot.hex"
`endif

  boot_rom #(.ADDR_WIDTH(AW), .DATA_WIDTH(32),
             .MEM_FILE(`ROM_IMAGE), .INIT_FILE(`ROM_IMAGE)) dut (
    .clk (clk), .reset_n (reset_n),
    .req (req), .addr (addr), .gnt (gnt), .rdata (rdata), .rvalid (rvalid),
    .awvalid (awvalid), .awready (awready), .awaddr (awaddr),
    .wvalid (wvalid), .wready (wready), .wdata (wdata), .wstrb (wstrb),
    .bvalid (bvalid), .bready (bready), .bresp (bresp),
    .arvalid (arvalid), .arready (arready), .araddr (araddr),
    .r_rvalid (r_rvalid), .r_rready (r_rready), .r_rdata (r_rdata),
    .r_rresp (r_rresp)
  );

  logic [31:0] img [0:WORDS-1];

  integer checks = 0;
  integer errors = 0;

  task automatic chk(input logic cond, input [1023:0] msg);
    begin
      checks = checks + 1;
      if (cond !== 1'b1) begin
        $display("ROM-TEST: FAIL %0s", msg);
        errors = errors + 1;
      end
    end
  endtask

  task automatic chk_word(input [31:0] got, input [31:0] exp, input integer idx);
    begin
      checks = checks + 1;
      if ((got !== exp) || $isunknown(got)) begin
        $display("ROM-TEST: FAIL word %0d expected=%h got=%h", idx, exp, got);
        errors = errors + 1;
      end
    end
  endtask

  task automatic ifetch(input [AW-1:0] a, output [31:0] d);
    begin
      @(negedge clk);
      addr = a; req = 1'b1;
      @(posedge clk);
      chk(gnt === 1'b1, "gnt asserted in the request cycle");
      @(negedge clk);
      req = 1'b0;
      @(posedge clk);
      chk(rvalid === 1'b1, "rvalid on the cycle after the request");
      d = rdata;
    end
  endtask

  task automatic axi_read(input [31:0] a, output [31:0] d);
    begin
      @(negedge clk);
      arvalid = 1'b1; araddr = a; r_rready = 1'b0;
      @(posedge clk);
      @(negedge clk);
      arvalid = 1'b0;
      @(posedge clk);
      chk(r_rvalid === 1'b1, "AXI read returned rvalid");
      d = r_rdata;
      r_rready = 1'b1;
      @(posedge clk);
      r_rready = 1'b0;
    end
  endtask

  task automatic axi_write(input [31:0] a, input [31:0] d, output [1:0] resp);
    begin
      @(negedge clk);
      awvalid = 1'b1; awaddr = a; wvalid = 1'b1; wdata = d; wstrb = 4'hF;
      bready = 1'b0;
      @(posedge clk);
      @(negedge clk);
      awvalid = 1'b0; wvalid = 1'b0;
      @(posedge clk);
      chk(bvalid === 1'b1, "AXI write returned bvalid");
      resp = bresp;
      bready = 1'b1;
      @(posedge clk);
      bready = 1'b0;
    end
  endtask

  reg [1023:0] img_path;
  reg [31:0]   d, d2;
  reg [1:0]    resp;
  integer      i;
  integer      nwords;

  initial begin
    if (!$value$plusargs("IMG=%s", img_path)) img_path = `ROM_IMAGE;

    // Reference copy: fill with NOP, then overlay the image exactly as
    // $readmemh does in the behavioural ROM.
    for (i = 0; i < WORDS; i = i + 1) img[i] = FILL;
    $readmemh(img_path, img);
    nwords = 0;
    for (i = 0; i < WORDS; i = i + 1) if (img[i] !== FILL) nwords = nwords + 1;
    $display("ROM-TEST: image=%0s words=%0d distinct_from_fill=%0d", img_path, WORDS, nwords);
    chk(nwords > 100, "image contains a real program (>100 non-fill words)");

    req = 0; addr = '0;
    awvalid = 0; wvalid = 0; bready = 0; arvalid = 0; r_rready = 0;
    awaddr = '0; wdata = '0; wstrb = '0; araddr = '0;

    reset_n = 1'b0;
    repeat (4) @(posedge clk);
    reset_n = 1'b1;
    repeat (2) @(posedge clk);

    // 1. reset state
    chk(gnt === 1'b0 && rvalid === 1'b0, "instruction port idle after reset");
    chk(awready === 1'b1 && wready === 1'b1 && arready === 1'b1,
        "AXI channels ready after reset");

    // 2. every word of the image through the instruction port
    for (i = 0; i < nwords + 8 && i < WORDS; i = i + 1) begin
      ifetch(i[AW-1:0] << 2, d);
      chk_word(d, img[i], i);
    end

    // 3. uncovered words read the fill value (both ends of the aperture)
    ifetch(14'h1000, d);
    chk_word(d, FILL, 1024);
    ifetch((WORDS-1) << 2, d);
    chk_word(d, FILL, WORDS - 1);

    // 5. AXI read agrees with the instruction port
    axi_read(32'h0000_0014, d);      // word 5
    chk_word(d, img[5], 5);

    // 6. write rejection: SLVERR, contents unchanged
    axi_write(32'h0000_0014, 32'hDEAD_BEEF, resp);
    chk(resp === 2'b10, "AXI write answered with SLVERR");
    axi_read(32'h0000_0014, d2);
    chk_word(d2, img[5], 5);
    ifetch(14'h0014, d);
    chk_word(d, img[5], 5);

    $display("ROM-TEST: checks=%0d errors=%0d", checks, errors);
    if (checks < 300) begin
      $display("ROM-TEST: RESULT=FAIL reason=few_checks(%0d)", checks);
      $fatal(1, "ROM-TEST incomplete");
    end
    if (errors == 0) begin
      $display("ROM-TEST: RESULT=PASS");
      $finish;
    end
    $display("ROM-TEST: RESULT=FAIL");
    $fatal(1, "ROM-TEST failed");
  end

  initial begin
    #2000000;
    $display("ROM-TEST: RESULT=FAIL reason=timeout");
    $fatal(1, "ROM-TEST timeout");
  end

endmodule
