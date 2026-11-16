//------------------------------------------------------------------------------
// Home-Automation-SoC — PLIC source-ID and register-boundary test
//
// Targets the boundary defects, not the happy path (tb_plic.v / tb_plic_proto.v
// already cover the common case):
//
//   B1  Source IDs are 1..8.  A 3-bit claim field cannot hold 8, so the
//       highest-numbered source used to claim as 0 ("no interrupt") and the
//       completion write addressed the wrong pending bit.
//   B2  Priorities live at 0x004 + 4*(id-1), i.e. 0x004..0x020.  Indexing the
//       array with paddr[4:2] - 1 wraps at 0x020, so source 8's priority either
//       aliased source 1 or indexed out of bounds.
//   B3  All eight priority registers must be independently read/write.
//   B4  Arbitration inputs: disabled source, threshold, tie, simultaneous
//       request, sustained level.
//
// Register map (see rtl/rtl_peripherals/plic.sv):
//   0x004 + 4*(id-1)  priority (RW)      0x100 pending (RO)
//   0x200 enable (RW)                   0x204 threshold (RW)
//   0x208 claim/complete                 (read -> claimant ID, write -> complete)
//
// Documented claim/completion semantics exercised here: a completion write
// masks the source until it deasserts, so a level held high re-presents the
// interrupt.  This is the contract the firmware relies on and the test asserts
// it explicitly rather than assuming RISC-V PLIC semantics.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_plic_bounds;

  localparam int NUM = 8;

  reg              clk = 1'b0;
  reg              reset_n = 1'b0;
  always #5 clk = ~clk;

  reg         wr_en = 1'b0;
  reg  [11:0] wr_addr = 12'd0;
  reg  [31:0] wr_data = 32'd0;
  reg  [11:0] rd_addr = 12'd0;
  wire [31:0] rd_data;
  reg  [NUM-1:0] ext_irq = '0;
  wire           irq_out;

  plic #(.NUM_SOURCES(NUM)) dut (
    .clk(clk), .reset_n(reset_n),
    .wr_en(wr_en), .wr_addr(wr_addr), .wr_data(wr_data),
    .rd_addr(rd_addr), .rd_data(rd_data),
    .ext_irq(ext_irq), .irq_out(irq_out)
  );

  integer errors = 0;
  integer checks = 0;

  task chk(input [8*44-1:0] name, input [31:0] got, input [31:0] exp);
    begin
      checks = checks + 1;
      if (got !== exp) begin
        errors = errors + 1;
        $display("[plicb] FAIL %0s: got %0d (0x%08h) expected %0d (0x%08h)",
                 name, got, got, exp, exp);
      end else begin
        $display("[plicb] pass %0s = %0d", name, got);
      end
    end
  endtask

  task chk_bit(input [8*44-1:0] name, input cond);
    begin
      checks = checks + 1;
      if (cond !== 1'b1) begin
        errors = errors + 1;
        $display("[plicb] FAIL %0s", name);
      end else begin
        $display("[plicb] pass %0s", name);
      end
    end
  endtask

  // One APB-style write pulse (the block samples wr_en on the rising edge).
  task wr(input [11:0] a, input [31:0] d);
    begin
      @(posedge clk);
      wr_en   <= 1'b1;
      wr_addr <= a;
      wr_data <= d;
      @(posedge clk);
      wr_en   <= 1'b0;
      @(posedge clk);
    end
  endtask

  // Register-port read: rd_data is combinational, so no clock edge is needed.
  // A task with an output register (a function cannot carry a delay).
  reg [31:0] rd_val = 32'd0;
  task rd(input [11:0] a);
    begin
      rd_addr = a;
      #1;
      rd_val  = rd_data;
    end
  endtask

  task clear_all;
    begin
      reset_n = 1'b0;
      ext_irq = '0;
      wr_en   = 1'b0;
      repeat (3) @(posedge clk);
      reset_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  // Wait for the 2-FF synchroniser plus the event register.
  task settle;
    begin
      repeat (5) @(posedge clk);
      #1;
    end
  endtask

  integer s;
  integer id;
  reg [31:0] prio_expect;

  initial begin
    reset_n = 1'b0;
    repeat (3) @(posedge clk);
    reset_n = 1'b1;
    repeat (2) @(posedge clk);

    //--------------------------------------------------------------------
    // B3 — all eight priority registers are independent.
    //--------------------------------------------------------------------
    for (s = 1; s <= NUM; s = s + 1) begin
      wr(12'(12'h004 + 4*(s-1)), 32'(s + 2));
    end
    for (s = 1; s <= NUM; s = s + 1) begin
      prio_expect = s + 2;
      rd(12'(12'h004 + 4*(s-1)));
      chk("B3 priority register independent", rd_val, prio_expect);
    end

    //--------------------------------------------------------------------
    // B2 — 0x020 is source 8's priority, not a wrap onto source 1.
    //--------------------------------------------------------------------
    wr(12'h004, 32'd3);       // source 1 = 3
    wr(12'h020, 32'd9);       // source 8 = 9
    rd(12'h004); chk("B2 0x004 is source 1 priority", rd_val, 32'd3);
    rd(12'h020); chk("B2 0x020 is source 8 priority", rd_val, 32'd9);

    //--------------------------------------------------------------------
    // B1 — every source is individually claimable and reports its full ID.
    //      This is the check that a 3-bit claim field cannot satisfy.
    //--------------------------------------------------------------------
    for (id = 1; id <= NUM; id = id + 1) begin
      clear_all;
      for (s = 1; s <= NUM; s = s + 1) wr(12'(12'h004 + 4*(s-1)), 32'd1);
      wr(12'h004 + 4*(id-1), 32'd7);      // give this source the top priority
      wr(12'h204, 32'd0);                 // threshold 0
      wr(12'h200, 32'(1 << (id-1)));      // enable only this source

      ext_irq = 8'(1 << (id-1));
      settle;
      chk("B1 irq_out asserted for source", irq_out, 32'd1);
      rd(12'h208); chk("B1 claim reports the full source ID", rd_val, 32'(id));

      // Completion write, then drop the level: pending must clear.
      wr(12'h208, 32'(id));
      ext_irq = '0;
      settle;
      rd(12'h100);
      chk("B1 pending clears after deassert", rd_val & (32'd1 << (id-1)), 32'd0);
    end

    //--------------------------------------------------------------------
    // B4a — a disabled source raises nothing.
    //--------------------------------------------------------------------
    clear_all;
    wr(12'h004, 32'd7);
    wr(12'h204, 32'd0);
    wr(12'h200, 32'd0);                    // all disabled
    ext_irq = 8'h01;
    settle;
    chk("B4 disabled source leaves irq_out low", irq_out, 32'd0);
    rd(12'h208); chk("B4 disabled source claims nothing", rd_val, 32'd0);

    //--------------------------------------------------------------------
    // B4b — threshold: blocked at or below, allowed above.
    //--------------------------------------------------------------------
    clear_all;
    wr(12'h004, 32'd5);
    wr(12'h200, 32'd1);
    wr(12'h204, 32'd5);                    // priority 5 is NOT above threshold 5
    ext_irq = 8'h01;
    settle;
    chk("B4b priority == threshold is masked", irq_out, 32'd0);
    wr(12'h204, 32'd4);
    settle;
    chk("B4b priority > threshold is delivered", irq_out, 32'd1);
    rd(12'h208); chk("B4b delivered source claims its ID", rd_val, 32'd1);

    //--------------------------------------------------------------------
    // B4c — tie between two enabled sources resolves to the lowest ID.
    //--------------------------------------------------------------------
    clear_all;
    wr(12'h004, 32'd5);                    // source 1
    wr(12'h008, 32'd5);                    // source 2
    wr(12'h200, 32'h3);
    wr(12'h204, 32'd0);
    ext_irq = 8'h03;
    settle;
    rd(12'h208); chk("B4c tie resolves to lowest ID", rd_val, 32'd1);

    //--------------------------------------------------------------------
    // B4d — simultaneous requests: highest priority wins, not lowest ID.
    //--------------------------------------------------------------------
    clear_all;
    wr(12'h004, 32'd3);                    // source 1
    wr(12'h008, 32'd6);                    // source 2
    wr(12'h200, 32'h3);
    wr(12'h204, 32'd0);
    ext_irq = 8'h3;
    settle;
    rd(12'h208); chk("B4d highest priority wins", rd_val, 32'd2);

    //--------------------------------------------------------------------
    // B4e — sustained level: the completion write masks the source only until
    //       it deasserts, so a held level re-presents the interrupt.  This is
    //       the documented contract; assert it so a change is visible.
    //--------------------------------------------------------------------
    clear_all;
    wr(12'h004, 32'd7);
    wr(12'h200, 32'd1);
    wr(12'h204, 32'd0);
    ext_irq = 8'h01;
    settle;
    rd(12'h208); chk("B4e first claim of sustained level", rd_val, 32'd1);
    wr(12'h208, 32'd1);                    // complete while the level is held
    settle;
    chk("B4e sustained level re-presents the interrupt", irq_out, 32'd1);
    ext_irq = '0;                          // release the source
    settle;
    chk("B4e released source clears irq_out", irq_out, 32'd0);

    //--------------------------------------------------------------------
    // B1b — completion of an out-of-range ID must not mask any real source.
    //--------------------------------------------------------------------
    clear_all;
    wr(12'h004, 32'd7);
    wr(12'h200, 32'd1);
    wr(12'h204, 32'd0);
    ext_irq = 8'h01;
    settle;
    wr(12'h208, 32'd15);                   // no such source
    settle;
    rd(12'h100);
    chk("B1b unknown completion ID leaves pending intact", rd_val & 32'd1, 32'd1);

    //--------------------------------------------------------------------
    $display("");
    $display("[plicb] checks: %0d, failures: %0d", checks, errors);
    if (errors == 0) begin
      $display("PLIC BOUNDS: ALL TESTS PASSED");
      $finish;
    end else begin
      $display("PLIC BOUNDS: %0d FAILURES", errors);
      $fatal(1, "PLIC boundary test failed");
    end
  end

  initial begin
    #2_000_000;
    $display("PLIC BOUNDS: TIMEOUT");
    $fatal(1, "plic bounds test timed out");
  end

endmodule
