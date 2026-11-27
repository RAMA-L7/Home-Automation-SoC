//------------------------------------------------------------------------------
// tb_sram_macro_wrap.v — wrapper verification at PRODUCTION geometry
//
// WHAT IS UNDER TEST
//   sram_macro_wrap #(ADDR_WIDTH=17, NUM_MACROS=64)   — the 128 KiB SoC SRAM
//   tcm_macro_wrap  #(ADDR_WIDTH=15, NUM_MACROS=16)   — the 32 KiB SoC TCM
//   These are exactly the configurations rtl/rtl_top/has_soc.sv instantiates,
//   so the bank decode, bank-boundary behaviour and address splitting exercised
//   here are the ones the SoC uses — not an N=2 toy geometry.
//
// MODEL STATUS (read this before believing any result)
//   The leaf compiled under the name sky130_sram_2kbyte_1rw1r_32x512_8 is
//   sim/sim_top/tb_macro_leaf.v, a PROXY: it mirrors the real macro's protocol
//   (registered inputs, falling-edge registered dout with a DELAY/T_HOLD gap,
//   byte-masked writes, 2-port RW+R, no reset pin) but it is not the vendor
//   model and carries no timing/power/area meaning. Results below are
//   PROXY-MODEL results: they validate the wrapper's logic, not the macro.
//   Real-macro verification (vendor Verilog model, gate-level, extracted STA)
//   is a separate, still-BLOCKED item — the official models do not elaborate
//   in Icarus 14 (`mem[addr_reg]` non-constant index).
//
// WHAT IS CHECKED
//   * all 16 byte-strobe combinations, on both wrappers
//   * the last word before a bank boundary AND the first word of the next bank
//   * the last bank's first word and the final word of the address space
//   * response data sampled during the RVALID/BVALID handshake cycle
//   * reset asserted while BVALID / RVALID are actually outstanding
//   * genuine simultaneous AXI read+write (documented write-priority arbiter)
//   * genuine simultaneous i-fetch + AXI write (same word and different banks)
//   * every returned word must be fully known (no X); timeouts fail
//   No constant assertions: every check() consumes an observable value.
//
// NEGATIVE CONTROLS (prove the checks discriminate)
//   Compile with -DNEG_BANK or -DNEG_STROBE to swap in deliberately broken
//   wrappers (sim/sim_top/tb_macro_wrap_negctl.v). Each MUST report failures;
//   scripts/eda/run_macro_wrapper.js runs both and requires a non-zero failure
//   count, so a checker that silently passes everything is caught.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

`ifdef NEG_BANK
  `define SRAM_DUT sram_macro_wrap_negbank
  `define TCM_DUT  tcm_macro_wrap_negbank
  `define DUT_MODE_NAME "NEG_BANK(negative control, must FAIL)"
`elsif NEG_STROBE
  `define SRAM_DUT sram_macro_wrap_negstrobe
  `define TCM_DUT  tcm_macro_wrap_negstrobe
  `define DUT_MODE_NAME "NEG_STROBE(negative control, must FAIL)"
`else
  `define SRAM_DUT sram_macro_wrap
  `define TCM_DUT  tcm_macro_wrap
  `define DUT_MODE_NAME "PRODUCTION"
`endif

module tb_sram_macro_wrap;

  // ---------------------------------------------------------------------------
  // Production geometry (identical to has_soc.sv's instantiations)
  // ---------------------------------------------------------------------------
  localparam int SRAM_AW     = 17;   // 128 KiB aperture
  localparam int SRAM_MACROS = 64;   // 64 x 2 KiB macro
  localparam int TCM_AW      = 15;   // 32 KiB aperture
  localparam int TCM_MACROS  = 16;   // 16 x 2 KiB macro
  localparam int MACRO_DW    = 32;
  localparam int MACRO_AW    = 9;    // 512 words per macro

  // Byte addresses of the boundary words. With MACRO_AW=9 and no lanes a bank
  // holds 512 SoC words = 2048 bytes, so bank b starts at byte b*2048.
  localparam [SRAM_AW-1:0] SRAM_B0_LAST  = (32'd511)  << 2;   // 0x007FC, end of bank 0
  localparam [SRAM_AW-1:0] SRAM_B1_FIRST = (32'd512)  << 2;   // 0x00800, start of bank 1
  localparam [SRAM_AW-1:0] SRAM_LASTB_F  = (32'd32256)<< 2;   // 0x1F800, bank 63 word 0
  localparam [SRAM_AW-1:0] SRAM_LASTWORD = (32'd32767)<< 2;   // 0x1FFFC, final word

  localparam [TCM_AW-1:0]  TCM_B0_LAST   = (32'd511)  << 2;   // 0x07FC
  localparam [TCM_AW-1:0]  TCM_B1_FIRST  = (32'd512)  << 2;   // 0x0800
  localparam [TCM_AW-1:0]  TCM_LASTB_F   = (32'd7680) << 2;   // 0x7800, bank 15 word 0
  localparam [TCM_AW-1:0]  TCM_LASTWORD  = (32'd8191) << 2;   // 0x7FFC

  // ---------------------------------------------------------------------------
  // Clock / reset
  // ---------------------------------------------------------------------------
  reg clk = 1'b0;
  reg reset_n = 1'b0;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // SRAM DUT (production)
  // ---------------------------------------------------------------------------
  reg  [SRAM_AW-1:0] s_awaddr, s_araddr, s_iaddr;
  reg  [31:0]        s_wdata;
  reg  [3:0]         s_wstrb;
  reg                s_awvalid, s_wvalid, s_bready, s_arvalid, s_rready, s_ireq;
  wire               s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
  wire               s_ignt, s_irvalid;
  wire [31:0]        s_rdata, s_irdata;
  wire [1:0]         s_bresp, s_rresp;

  `SRAM_DUT #(
    .ADDR_WIDTH (SRAM_AW),
    .DATA_WIDTH (32),
    .MACRO_DW   (MACRO_DW),
    .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (SRAM_MACROS)
  ) dut_sram (
    .clk (clk), .reset_n (reset_n),
    .awvalid (s_awvalid), .awaddr (s_awaddr), .awready (s_awready),
    .wvalid  (s_wvalid),  .wdata  (s_wdata),  .wready  (s_wready), .wstrb (s_wstrb),
    .bvalid  (s_bvalid),  .bready (s_bready), .bresp   (s_bresp),
    .arvalid (s_arvalid), .araddr (s_araddr), .arready (s_arready),
    .rvalid  (s_rvalid),  .rdata  (s_rdata),  .rresp   (s_rresp), .rready (s_rready),
    .i_req   (s_ireq),    .i_addr (s_iaddr),  .i_gnt   (s_ignt),
    .i_rdata (s_irdata),  .i_rvalid (s_irvalid)
  );

  // ---------------------------------------------------------------------------
  // TCM DUT (production)
  // ---------------------------------------------------------------------------
  reg  [TCM_AW-1:0] t_awaddr, t_araddr, t_iaddr;
  reg  [31:0]       t_wdata;
  reg  [3:0]        t_wstrb;
  reg               t_awvalid, t_wvalid, t_bready, t_arvalid, t_rready, t_ireq;
  wire              t_awready, t_wready, t_bvalid, t_arready, t_rvalid;
  wire              t_ignt, t_irvalid;
  wire [31:0]       t_rdata, t_irdata;
  wire [1:0]        t_bresp, t_rresp;

  `TCM_DUT #(
    .ADDR_WIDTH (TCM_AW),
    .DATA_WIDTH (32),
    .MACRO_DW   (MACRO_DW),
    .MACRO_AW   (MACRO_AW),
    .NUM_MACROS (TCM_MACROS)
  ) dut_tcm (
    .clk (clk), .reset_n (reset_n),
    .awvalid (t_awvalid), .awaddr (t_awaddr), .awready (t_awready),
    .wvalid  (t_wvalid),  .wdata  (t_wdata),  .wready  (t_wready), .wstrb (t_wstrb),
    .bvalid  (t_bvalid),  .bready (t_bready), .bresp   (t_bresp),
    .arvalid (t_arvalid), .araddr (t_araddr), .arready (t_arready),
    .rvalid  (t_rvalid),  .rdata  (t_rdata),  .rresp   (t_rresp), .rready (t_rready),
    .i_req   (t_ireq),    .i_addr (t_iaddr),  .i_gnt   (t_ignt),
    .i_rdata (t_irdata),  .i_rvalid (t_irvalid)
  );

  // ---------------------------------------------------------------------------
  // Checker infrastructure
  //   cond !== 1'b1  ->  X/Z also fails (a 2-state `if (!cond)` would pass X)
  // ---------------------------------------------------------------------------
  integer checks  = 0;
  integer errors  = 0;
  integer to_errs = 0;

  task automatic chk(input logic cond, input [1023:0] msg);
    begin
      checks = checks + 1;
      if (cond !== 1'b1) begin
        $display("[macro_wrap] FAIL %0s", msg);
        errors = errors + 1;
      end else begin
        $display("[macro_wrap] pass %0s", msg);
      end
    end
  endtask

  task automatic chk_eq32(input [31:0] act, input [31:0] exp,
                          input [1023:0] msg, input integer idx);
    begin
      checks = checks + 1;
      if ((act !== exp) || $isunknown(act)) begin
        $display("[macro_wrap] FAIL %0s[%0d] expected=%h actual=%h",
                 msg, idx, exp, act);
        errors = errors + 1;
      end else begin
        $display("[macro_wrap] pass %0s[%0d] = %h", msg, idx, act);
      end
    end
  endtask

  // Strobe mask: byte k enabled by s[k]
  function automatic [31:0] strobe_mask(input [3:0] s, input [31:0] pat);
    integer k;
    begin
      strobe_mask = 32'h0;
      for (k = 0; k < 4; k = k + 1)
        if (s[k]) strobe_mask[8*k +: 8] = pat[8*k +: 8];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // SRAM AXI tasks — stimulus on negedge, sample on posedge (race-free)
  // ---------------------------------------------------------------------------
  task automatic sram_write(input [SRAM_AW-1:0] a, input [31:0] d, input [3:0] s);
    integer n;
    logic   done;
    begin
      done = 1'b0;
      @(negedge clk);
      s_awvalid = 1'b1; s_awaddr = a;
      s_wvalid  = 1'b1; s_wdata  = d; s_wstrb = s;
      s_bready  = 1'b0;
      @(posedge clk);                       // aw/w accepted here
      @(negedge clk);
      s_awvalid = 1'b0; s_wvalid = 1'b0;
      for (n = 0; n < 24; n = n + 1) begin
        @(posedge clk);
        if (s_bvalid === 1'b1) begin
          s_bready = 1'b1;                  // close the handshake
          @(posedge clk);
          s_bready = 1'b0;
          done = 1'b1;
          n = 24;
        end
      end
      if (!done) begin
        $display("[macro_wrap] FAIL sram write timeout addr=%h", a);
        errors = errors + 1; to_errs = to_errs + 1;
        s_bready = 1'b0;
      end
    end
  endtask

  task automatic sram_read(input [SRAM_AW-1:0] a, output [31:0] d);
    integer n;
    logic   done;
    begin
      done = 1'b0;
      d = 32'hx;
      @(negedge clk);
      s_arvalid = 1'b1; s_araddr = a; s_rready = 1'b0;
      @(posedge clk);                       // ar accepted here
      @(negedge clk);
      s_arvalid = 1'b0;
      for (n = 0; n < 24; n = n + 1) begin
        @(posedge clk);
        if (s_rvalid === 1'b1) begin
          d = s_rdata;                      // same cycle RVALID is asserted
          s_rready = 1'b1;                  // complete the handshake here
          @(posedge clk);
          s_rready = 1'b0;
          done = 1'b1;
          n = 24;
        end
      end
      if (!done) begin
        $display("[macro_wrap] FAIL sram read timeout addr=%h", a);
        errors = errors + 1; to_errs = to_errs + 1;
      end
    end
  endtask

  // Instruction-port read: gnt in the request cycle, data one cycle after.
  task automatic sram_ifetch(input [SRAM_AW-1:0] a, output [31:0] d);
    begin
      @(negedge clk);
      s_iaddr = a; s_ireq = 1'b1;
      @(posedge clk);
      chk(s_ignt === 1'b1, "SRAM i-port grant in request cycle");
      @(negedge clk);
      s_ireq = 1'b0;
      @(posedge clk);
      chk(s_irvalid === 1'b1, "SRAM i-port rvalid one cycle after request");
      d = s_irdata;              // sampled in the RVALID cycle
    end
  endtask

  // ---------------------------------------------------------------------------
  // TCM AXI tasks
  // ---------------------------------------------------------------------------
  task automatic tcm_write(input [TCM_AW-1:0] a, input [31:0] d, input [3:0] s);
    integer n;
    logic   done;
    begin
      done = 1'b0;
      @(negedge clk);
      t_awvalid = 1'b1; t_awaddr = a;
      t_wvalid  = 1'b1; t_wdata  = d; t_wstrb = s;
      t_bready  = 1'b0;
      @(posedge clk);
      @(negedge clk);
      t_awvalid = 1'b0; t_wvalid = 1'b0;
      for (n = 0; n < 24; n = n + 1) begin
        @(posedge clk);
        if (t_bvalid === 1'b1) begin
          t_bready = 1'b1;
          @(posedge clk);
          t_bready = 1'b0;
          done = 1'b1;
          n = 24;
        end
      end
      if (!done) begin
        $display("[macro_wrap] FAIL tcm write timeout addr=%h", a);
        errors = errors + 1; to_errs = to_errs + 1;
        t_bready = 1'b0;
      end
    end
  endtask

  task automatic tcm_read(input [TCM_AW-1:0] a, output [31:0] d);
    integer n;
    logic   done;
    begin
      done = 1'b0;
      d = 32'hx;
      @(negedge clk);
      t_arvalid = 1'b1; t_araddr = a; t_rready = 1'b0;
      @(posedge clk);
      @(negedge clk);
      t_arvalid = 1'b0;
      for (n = 0; n < 24; n = n + 1) begin
        @(posedge clk);
        if (t_rvalid === 1'b1) begin
          d = t_rdata;
          t_rready = 1'b1;
          @(posedge clk);
          t_rready = 1'b0;
          done = 1'b1;
          n = 24;
        end
      end
      if (!done) begin
        $display("[macro_wrap] FAIL tcm read timeout addr=%h", a);
        errors = errors + 1; to_errs = to_errs + 1;
      end
    end
  endtask

  task automatic tcm_ifetch(input [TCM_AW-1:0] a, output [31:0] d);
    begin
      @(negedge clk);
      t_iaddr = a; t_ireq = 1'b1;
      @(posedge clk);
      chk(t_ignt === 1'b1, "TCM i-port grant in request cycle");
      @(negedge clk);
      t_ireq = 1'b0;
      @(posedge clk);
      chk(t_irvalid === 1'b1, "TCM i-port rvalid one cycle after request");
      d = t_irdata;              // sampled in the RVALID cycle
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test body
  // ---------------------------------------------------------------------------
  reg [31:0] d, d2;
  integer    s_i;
  integer    k;

  initial begin
    // Idle all inputs
    s_awvalid = 0; s_wvalid = 0; s_bready = 0; s_arvalid = 0; s_rready = 0; s_ireq = 0;
    s_awaddr = '0; s_araddr = '0; s_iaddr = '0; s_wdata = '0; s_wstrb = '0;
    t_awvalid = 0; t_wvalid = 0; t_bready = 0; t_arvalid = 0; t_rready = 0; t_ireq = 0;
    t_awaddr = '0; t_araddr = '0; t_iaddr = '0; t_wdata = '0; t_wstrb = '0;

    reset_n = 1'b0;
    repeat (4) @(posedge clk);
    reset_n = 1'b1;
    repeat (2) @(posedge clk);

    // -----------------------------------------------------------------------
    // S1 — reset state, both wrappers
    // -----------------------------------------------------------------------
    chk(s_awready === 1'b1 && s_wready === 1'b1 && s_arready === 1'b1,
        "S1 SRAM all channels ready after reset");
    chk(s_bvalid === 1'b0 && s_rvalid === 1'b0,
        "S1 SRAM no response pending after reset");
    chk(s_irvalid === 1'b0, "S1 SRAM i-port idle after reset");
    chk(s_bresp === 2'b00 && s_rresp === 2'b00, "S1 SRAM OKAY response codes");
    chk(t_awready === 1'b1 && t_wready === 1'b1 && t_arready === 1'b1,
        "S1 TCM all channels ready after reset");

    // -----------------------------------------------------------------------
    // S2 — full-word write/read, bank 0
    // -----------------------------------------------------------------------
    sram_write(17'h00000, 32'hA1B2_C3D4, 4'hF);
    sram_read (17'h00000, d);
    chk_eq32(d, 32'hA1B2_C3D4, "S2 SRAM full-word write/read", 0);

    // -----------------------------------------------------------------------
    // S3 — ALL 16 byte-strobe combinations (base word cleared each time)
    // -----------------------------------------------------------------------
    for (s_i = 0; s_i < 16; s_i = s_i + 1) begin
      sram_write(17'h00010, 32'h0000_0000, 4'hF);          // clear
      sram_write(17'h00010, 32'hAABB_CCDD, s_i[3:0]);      // partial
      sram_read (17'h00010, d);
      chk_eq32(d, strobe_mask(s_i[3:0], 32'hAABB_CCDD),
               "S3 SRAM strobe combination", s_i);
    end

    // -----------------------------------------------------------------------
    // S4 — read-after-write on a non-zero word offset
    // -----------------------------------------------------------------------
    sram_write(17'h00040, 32'h0123_4567, 4'hF);
    sram_read (17'h00040, d);
    chk_eq32(d, 32'h0123_4567, "S4 SRAM read-after-write", 0);

    // -----------------------------------------------------------------------
    // S5 — bank boundary: last word of bank 0 vs first word of bank 1
    //      (the defect this catches: bank bits ignored -> the two alias)
    // -----------------------------------------------------------------------
    sram_write(SRAM_B0_LAST,  32'hAAAA_BBBB, 4'hF);
    sram_write(SRAM_B1_FIRST, 32'hCCCC_DEEE, 4'hF);
    sram_read (SRAM_B0_LAST,  d);
    chk_eq32(d, 32'hAAAA_BBBB, "S5 SRAM last word before bank 1 boundary", 0);
    sram_read (SRAM_B1_FIRST, d);
    chk_eq32(d, 32'hCCCC_DEEE, "S5 SRAM first word of bank 1", 0);

    // S5b - bank 1 word 0 must NOT alias bank 0 word 0. This is the direct
    //        test for a decode that drops the bank bits: both addresses then
    //        resolve to the same macro row and the second write wins.
    sram_write(17'h00000,      32'hA5A5_1111, 4'hF);
    sram_write(SRAM_B1_FIRST,  32'h5A5A_2222, 4'hF);
    sram_read (17'h00000, d);
    chk_eq32(d, 32'hA5A5_1111, "S5 SRAM bank 1 does not alias bank 0 word 0", 0);
    // Same property across the top bank (63), whose local offset 0 would also
    // collide with bank 0 word 0 under a dropped-bank decode.
    sram_write(SRAM_LASTB_F, 32'h0BAD_CAFE, 4'hF);
    sram_read (17'h00000, d);
    chk_eq32(d, 32'hA5A5_1111, "S5 SRAM last bank does not alias bank 0 word 0", 0);

    // -----------------------------------------------------------------------
    // S6 — last bank first word, and the final word of the aperture
    // -----------------------------------------------------------------------
    sram_write(SRAM_LASTB_F,  32'h5A5A_1234, 4'hF);
    sram_write(SRAM_LASTWORD, 32'h1357_9BDF, 4'hF);
    sram_read (SRAM_LASTB_F,  d);
    chk_eq32(d, 32'h5A5A_1234, "S6 SRAM first word of last bank", 0);
    sram_read (SRAM_LASTWORD, d);
    chk_eq32(d, 32'h1357_9BDF, "S6 SRAM final word of address space", 0);

    // -----------------------------------------------------------------------
    // S7 — instruction port at production geometry, across a bank boundary
    // -----------------------------------------------------------------------
    sram_write(SRAM_B0_LAST,  32'h0BAD_F00D, 4'hF);
    sram_ifetch(SRAM_B0_LAST, d);
    chk_eq32(d, 32'h0BAD_F00D, "S7 SRAM i-fetch last word before boundary", 0);
    sram_write(SRAM_B1_FIRST, 32'hFEED_1234, 4'hF);
    sram_ifetch(SRAM_B1_FIRST, d);
    chk_eq32(d, 32'hFEED_1234, "S7 SRAM i-fetch first word of bank 1", 0);

    // -----------------------------------------------------------------------
    // S8 — reset while a WRITE RESPONSE is outstanding
    // -----------------------------------------------------------------------
    @(negedge clk);
    s_awvalid = 1'b1; s_awaddr = 17'h00200; s_wvalid = 1'b1;
    s_wdata = 32'hDEAD_BEEF; s_wstrb = 4'hF; s_bready = 1'b0;
    @(posedge clk);                        // accepted -> S_WRESP
    @(negedge clk);
    s_awvalid = 1'b0; s_wvalid = 1'b0;
    @(posedge clk);                        // now BVALID high, BREADY low
    chk(s_bvalid === 1'b1, "S8 SRAM BVALID outstanding before reset");
    reset_n = 1'b0;                        // reset mid-response
    repeat (2) @(posedge clk);
    chk(s_bvalid === 1'b0, "S8 SRAM BVALID cleared by reset mid-response");
    // AW/W/AR READY are now gated by reset_n so no transfer can be captured on
    // a reset edge and then silently dropped; the channel state is therefore
    // checked once reset is released, which is the only time a transfer can
    // legally occur.
    chk(s_awready === 1'b0 && s_wready === 1'b0 && s_arready === 1'b0,
        "S8 SRAM channels not ready while reset is asserted");
    reset_n = 1'b1;
    repeat (2) @(posedge clk);
    chk(s_awready === 1'b1 && s_wready === 1'b1 && s_arready === 1'b1,
        "S8 SRAM channels ready again after mid-response reset");
    sram_read(17'h00200, d);               // macro has no reset: data persists
    chk_eq32(d, 32'hDEAD_BEEF, "S8 SRAM committed write persists across reset", 0);

    // -----------------------------------------------------------------------
    // S9 — reset while a READ RESPONSE is outstanding
    // -----------------------------------------------------------------------
    @(negedge clk);
    s_arvalid = 1'b1; s_araddr = 17'h00200; s_rready = 1'b0;
    @(posedge clk);                        // accepted -> S_RRESP
    @(negedge clk);
    s_arvalid = 1'b0;
    @(posedge clk);                        // RVALID high, RREADY low
    chk(s_rvalid === 1'b1, "S9 SRAM RVALID outstanding before reset");
    reset_n = 1'b0;
    repeat (2) @(posedge clk);
    chk(s_rvalid === 1'b0, "S9 SRAM RVALID cleared by reset mid-response");
    reset_n = 1'b1;
    repeat (2) @(posedge clk);

    // -----------------------------------------------------------------------
    // S10 — genuine simultaneous AXI read + write.
    //       Documented arbiter contract: arready = IDLE & ~(awvalid & wvalid),
    //       so a presented write holds the read off; the write completes and the
    //       read then returns its own (pre-write) data. Observable conditions
    //       only: the read is not accepted while the write is presented.
    // -----------------------------------------------------------------------
    sram_write(17'h00300, 32'h1111_2222, 4'hF);   // read target, pre-value
    sram_write(17'h00340, 32'h0000_0000, 4'hF);   // write target
    @(negedge clk);
    s_awvalid = 1'b1; s_awaddr = 17'h00340;
    s_wvalid  = 1'b1; s_wdata  = 32'h3333_4444; s_wstrb = 4'hF;
    s_arvalid = 1'b1; s_araddr = 17'h00300; s_rready = 1'b0;
    #1;                                            // settle combinational arbiter
    chk(s_arready === 1'b0, "S10 SRAM read held off while write presented");
    chk(s_awready === 1'b1 && s_wready === 1'b1, "S10 SRAM write accepted");
    @(posedge clk);                                // write fires
    @(negedge clk);
    s_awvalid = 1'b0; s_wvalid = 1'b0;
    @(posedge clk);
    chk(s_bvalid === 1'b1, "S10 SRAM simultaneous write completes");
    s_bready = 1'b1; @(posedge clk); s_bready = 1'b0;
    // The read was never accepted; release and re-issue it cleanly.
    @(negedge clk);
    s_arvalid = 1'b1;
    @(posedge clk);
    @(negedge clk);
    s_arvalid = 1'b0;
    @(posedge clk);
    chk(s_rvalid === 1'b1, "S10 SRAM deferred read returns its response");
    d = s_rdata;
    s_rready = 1'b1; @(posedge clk); s_rready = 1'b0;
    chk_eq32(d, 32'h1111_2222, "S10 SRAM deferred read data unchanged", 0);
    sram_read(17'h00340, d);
    chk_eq32(d, 32'h3333_4444, "S10 SRAM simultaneous write data landed", 0);

    // -----------------------------------------------------------------------
    // S11 — simultaneous i-fetch + AXI write to DIFFERENT banks:
    //       no false forwarding, both operands correct.
    // -----------------------------------------------------------------------
    sram_write(SRAM_LASTWORD, 32'h0F0F_0F0F, 4'hF);   // bank 63
    sram_write(17'h00000,     32'h0000_0000, 4'hF);   // bank 0 write target
    @(negedge clk);
    s_awvalid = 1'b1; s_awaddr = 17'h00004; s_wvalid = 1'b1;
    s_wdata = 32'h7777_8888; s_wstrb = 4'hF; s_bready = 1'b0;
    s_iaddr = SRAM_LASTWORD; s_ireq = 1'b1;
    @(posedge clk);
    @(negedge clk);
    s_awvalid = 1'b0; s_wvalid = 1'b0; s_ireq = 1'b0;
    @(posedge clk);
    chk(s_irvalid === 1'b1, "S11 SRAM i-fetch rvalid during concurrent write");
    d = s_irdata;                          // sampled in the RVALID cycle
    chk_eq32(d, 32'h0F0F_0F0F,
             "S11 SRAM i-fetch unaffected by concurrent write to another bank", 0);
    // Drain the write response.
    @(posedge clk);
    if (s_bvalid === 1'b1) begin
      s_bready = 1'b1; @(posedge clk); s_bready = 1'b0;
    end else begin
      chk(1'b0, "S11 SRAM concurrent write produced a response");
      s_bready = 1'b1; @(posedge clk); s_bready = 1'b0;
    end
    sram_read(17'h00004, d);
    chk_eq32(d, 32'h7777_8888, "S11 SRAM concurrent write data landed", 0);

    // -----------------------------------------------------------------------
    // S12 — same-word write -> instruction-read forwarding (documented contract)
    // -----------------------------------------------------------------------
    sram_write(17'h00080, 32'h0000_0000, 4'hF);       // clear
    @(negedge clk);
    s_awvalid = 1'b1; s_awaddr = 17'h00080; s_wvalid = 1'b1;
    s_wdata = 32'h1234_5678; s_wstrb = 4'hF; s_bready = 1'b0;
    s_iaddr = 17'h00080; s_ireq = 1'b1;                // same word, same cycle
    @(posedge clk);
    chk(s_ignt === 1'b1, "S12 SRAM i-fetch granted in the write cycle");
    @(negedge clk);
    s_awvalid = 1'b0; s_wvalid = 1'b0; s_ireq = 1'b0;
    @(posedge clk);
    chk(s_irvalid === 1'b1, "S12 SRAM i-fetch rvalid after same-cycle write");
    d = s_irdata;                          // forward is valid only in this cycle
    chk_eq32(d, 32'h1234_5678, "S12 SRAM same-word write->i-read forward", 0);
    @(posedge clk);
    if (s_bvalid === 1'b1) begin
      s_bready = 1'b1; @(posedge clk); s_bready = 1'b0;
    end else begin
      chk(1'b0, "S12 SRAM write response present");
      s_bready = 1'b1; @(posedge clk); s_bready = 1'b0;
    end

    // -----------------------------------------------------------------------
    // T1 — TCM reset state
    // -----------------------------------------------------------------------
    chk(t_bvalid === 1'b0 && t_rvalid === 1'b0,
        "T1 TCM no response pending after reset");
    chk(t_bresp === 2'b00 && t_rresp === 2'b00, "T1 TCM OKAY response codes");

    // -----------------------------------------------------------------------
    // T2 — all 16 strobes on the TCM too
    // -----------------------------------------------------------------------
    for (s_i = 0; s_i < 16; s_i = s_i + 1) begin
      tcm_write(15'h00010, 32'h0000_0000, 4'hF);
      tcm_write(15'h00010, 32'hAABB_CCDD, s_i[3:0]);
      tcm_read (15'h00010, d);
      chk_eq32(d, strobe_mask(s_i[3:0], 32'hAABB_CCDD),
               "T2 TCM strobe combination", s_i);
    end

    // -----------------------------------------------------------------------
    // T3 — TCM bank boundary (16 banks: last word of bank 0 vs bank 1 word 0)
    // -----------------------------------------------------------------------
    tcm_write(TCM_B0_LAST,  32'h1234_AAAA, 4'hF);
    tcm_write(TCM_B1_FIRST, 32'h5678_BBBB, 4'hF);
    tcm_read (TCM_B0_LAST,  d);
    chk_eq32(d, 32'h1234_AAAA, "T3 TCM last word before bank 1 boundary", 0);
    tcm_read (TCM_B1_FIRST, d);
    chk_eq32(d, 32'h5678_BBBB, "T3 TCM first word of bank 1", 0);
    // T3b - bank 1 word 0 must not alias bank 0 word 0
    tcm_write(15'h00000,     32'h0A0A_1111, 4'hF);
    tcm_write(TCM_B1_FIRST,  32'h0B0B_2222, 4'hF);
    tcm_read (15'h00000, d);
    chk_eq32(d, 32'h0A0A_1111, "T3 TCM bank 1 does not alias bank 0 word 0", 0);

    // -----------------------------------------------------------------------
    // T4 — TCM last bank first word and final word
    // -----------------------------------------------------------------------
    tcm_write(TCM_LASTB_F,  32'h9ABC_DEF0, 4'hF);
    tcm_write(TCM_LASTWORD, 32'h0FED_CBA9, 4'hF);
    tcm_read (TCM_LASTB_F,  d);
    chk_eq32(d, 32'h9ABC_DEF0, "T4 TCM first word of last bank", 0);
    tcm_read (TCM_LASTWORD, d);
    chk_eq32(d, 32'h0FED_CBA9, "T4 TCM final word of address space", 0);

    // -----------------------------------------------------------------------
    // T5 — TCM instruction port across the bank boundary
    // -----------------------------------------------------------------------
    tcm_write(TCM_B1_FIRST, 32'hCAFE_0001, 4'hF);
    tcm_ifetch(TCM_B1_FIRST, d);
    chk_eq32(d, 32'hCAFE_0001, "T5 TCM i-fetch first word of bank 1", 0);

    // -----------------------------------------------------------------------
    // T6 — TCM reset mid read-response
    // -----------------------------------------------------------------------
    @(negedge clk);
    t_arvalid = 1'b1; t_araddr = TCM_B1_FIRST; t_rready = 1'b0;
    @(posedge clk);
    @(negedge clk);
    t_arvalid = 1'b0;
    @(posedge clk);
    chk(t_rvalid === 1'b1, "T6 TCM RVALID outstanding before reset");
    reset_n = 1'b0;
    repeat (2) @(posedge clk);
    chk(t_rvalid === 1'b0, "T6 TCM RVALID cleared by reset mid-response");
    reset_n = 1'b1;
    repeat (2) @(posedge clk);

    // -----------------------------------------------------------------------
    // Verdict — every check must pass, every word known, no timeouts
    // -----------------------------------------------------------------------
    $display("[macro_wrap] MODE=%0s", `DUT_MODE_NAME);
    $display("[macro_wrap] checks=%0d errors=%0d timeouts=%0d", checks, errors, to_errs);
    if (checks < 55) begin
      $display("[macro_wrap] FAIL too few checks ran (%0d < 55) — marker missing or aborted", checks);
      $fatal(1, "[macro_wrap] INCOMPLETE");
    end
    if ((errors == 0) && (to_errs == 0)) begin
      $display("[macro_wrap] RESULT=PASS");
      $finish;
    end else begin
      $display("[macro_wrap] RESULT=FAIL");
      $fatal(1, "[macro_wrap] TESTS FAILED");
    end
  end

  // Global watchdog: a hang is a failure, never a silent pass.
  initial begin
    #4000000;
    $display("[macro_wrap] RESULT=FAIL reason=watchdog_timeout");
    $fatal(1, "[macro_wrap] TIMEOUT");
  end

endmodule
