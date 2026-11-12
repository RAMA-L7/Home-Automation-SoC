`timescale 1ns/1ps
//------------------------------------------------------------------------------
// PLIC protocol testbench — asynchronous sources, pending, claim/complete
//
// Purpose: exercise the CDC hardening of plic.sv.  `ext_irq` is driven far
// from the clk edge (as an off-chip source would be) and the test checks:
//
//   T1  reset values (pending/enable/threshold/priority all zero)
//   T2  a 3-cycle asynchronous pulse is captured and raises irq_out
//   T3  claim masks the source and drops irq_out once the source is low
//   T4  an event arriving while the source is claimed is NOT lost
//      (this is the behaviour the pre-hardening RTL lacked)
//   T5  a sustained level keeps the interrupt pending (level semantics)
//   T6  simultaneous sources: highest priority wins, lowest ID breaks ties
//   T7  reset while pending clears everything
//
// Deviation from the PLIC spec, preserved here and documented: claiming is a
// WRITE to 0x208 in this RTL (the spec uses a read).
//------------------------------------------------------------------------------
module tb_plic_proto;

  reg         clk = 0;
  reg         reset_n;
  reg         wr_en;
  reg  [11:0] wr_addr;
  reg  [31:0] wr_data;
  reg  [11:0] rd_adrr;
  wire [31:0] rd_data;
  reg  [7:0]  ext_irq;
  wire        irq_out;

  always #5 clk = ~clk;

  plic #(.NUM_SOURCES(8)) dut (
    .clk      (clk),
    .reset_n  (reset_n),
    .wr_en    (wr_en),
    .wr_addr  (wr_addr),
    .wr_data  (wr_data),
    .rd_addr  (rd_adrr),
    .rd_data  (rd_data),
    .ext_irq  (ext_irq),
    .irq_out  (irq_out)
  );

  integer errors = 0;

  task check;
    input [255:0] name;
    input [31:0]  got;
    input [31:0]  exp;
    begin
      if (got !== exp) begin
        $display("[plic] FAIL %0s: got %0d expected %0d", name, got, exp);
        errors = errors + 1;
      end else begin
        $display("[plic] pass %0s = %0d", name, got);
      end
    end
  endtask

  task wr;
    input [11:0] addr;
    input [31:0] data;
    begin
      @(posedge clk);
      wr_en   <= 1'b1;
      wr_addr <= addr;
      wr_data <= data;
      @(posedge clk);
      wr_en   <= 1'b0;
      @(posedge clk);
    end
  endtask

  task rd;
    input [11:0] addr;
    begin
      @(posedge clk);
      rd_adrr <= addr;
      @(posedge clk);
    end
  endtask

  integer i;

  initial begin
    $dumpfile("build/sim/tb_plic_proto.vcd");
    $dumpvars(0, tb_plic_proto);

    reset_n = 0; wr_en = 0; wr_addr = 0; wr_data = 0; rd_adrr = 0; ext_irq = 0;
    repeat (3) @(posedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);

    // T1 — reset values
    rd(12'h100); check("T1 pending",   rd_data, 0);
    rd(12'h200); check("T1 enable",    rd_data, 0);
    rd(12'h204); check("T1 threshold", rd_data, 0);
    rd(12'h004); check("T1 prio[0]",   rd_data, 0);

    // Configure source 1 (priority 5), enable it, threshold 2
    wr(12'h004, 32'd5);
    wr(12'h200, 32'd0);
    wr(12'h200, 32'd1);   // enable source 1 only
    wr(12'h204, 32'd2);
    check("T1b irq_out idle", irq_out, 0);

    // T2 — 3-cycle asynchronous pulse
    @(negedge clk);
    ext_irq[0] = 1'b1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    ext_irq[0] = 1'b0;
    repeat (4) @(posedge clk);
    check("T2 irq_out after pulse", irq_out, 1);
    rd(12'h100); check("T2 pending bit0", rd_data[0], 1);

    // T3 — claim (write to 0x208) and drop
    wr(12'h208, 32'd0);
    repeat (3) @(posedge clk);
    check("T3 irq_out after claim", irq_out, 0);
    rd(12'h100); check("T3 pending cleared by source low", rd_data[0], 0);

    // T4 — event while claimed must not be lost
    wr(12'h208, 32'd0);              // claim again (idempotent, source low)
    repeat (2) @(posedge clk);
    @(negedge clk);
    ext_irq[0] = 1'b1;               // new event during claimed state
    repeat (3) @(posedge clk);
    @(negedge clk);
    ext_irq[0] = 1'b0;
    repeat (4) @(posedge clk);
    rd(12'h100); check("T4 pending after claimed event", rd_data[0], 1);
    check("T4 irq_out after claimed event", irq_out, 1);

    // T5 — sustained level keeps pending
    wr(12'h208, 32'd0);
    repeat (3) @(posedge clk);
    @(negedge clk);
    ext_irq[0] = 1'b1;
    repeat (10) @(posedge clk);
    rd(12'h100); check("T5 pending while level high", rd_data[0], 1);
    @(negedge clk);
    ext_irq[0] = 1'b0;

    // T6 — arbitration from a clean state (T2..T5 left pending bits set).
    reset_n = 0;
    ext_irq = 8'b0;
    repeat (2) @(posedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);
    wr(12'h004, 32'd5);   // prio[0] = 5 (ID 1)
    wr(12'h008, 32'd5);   // prio[1] = 5 (ID 2, tie with ID 1)
    wr(12'h00C, 32'd7);   // prio[2] = 7 (ID 3, highest)
    wr(12'h200, 32'd7);   // enable sources 1..3
    wr(12'h204, 32'd0);   // threshold 0
    // Highest priority wins while both sources are still asserted.
    ext_irq = 8'b0000_0110;   // IDs 2 (prio 5) and 3 (prio 7)
    repeat (6) @(posedge clk);
    rd(12'h208); check("T6 claim id (highest priority)", rd_data[2:0], 3'd3);
    wr(12'h208, 32'd0);
    repeat (4) @(posedge clk);

    // Drop the higher-priority source: the remaining one is claimed.
    ext_irq = 8'b0000_0010;   // ID 2 only
    repeat (4) @(posedge clk);
    rd(12'h208); check("T6 claim id (remaining source)", rd_data[2:0], 3'd2);
    wr(12'h208, 32'd0);
    repeat (4) @(posedge clk);

    // Equal priorities (IDs 1 and 2 are both 5): lowest ID must win.
    ext_irq = 8'b0000_0011;
    repeat (6) @(posedge clk);
    rd(12'h208); check("T6 claim id (tie -> lowest id)", rd_data[2:0], 3'd1);
    ext_irq = 8'b0;

    // T7 — reset while pending clears state
    @(negedge clk);
    ext_irq[0] = 1'b1;
    repeat (3) @(posedge clk);
    reset_n = 0;
    repeat (2) @(posedge clk);
    reset_n = 1;
    ext_irq = 8'b0;
    repeat (2) @(posedge clk);
    rd(12'h100); check("T7 pending after reset", rd_data, 0);
    rd(12'h200); check("T7 enable after reset",  rd_data, 0);
    check("T7 irq_out after reset", irq_out, 0);

    if (errors == 0) begin
      $display("PLIC PROTOCOL: ALL TESTS PASSED");
    end else begin
      $display("PLIC PROTOCOL: %0d FAILURES", errors);
      $fatal;
    end
    $finish;
  end

  initial begin
    #200000;
    $display("PLIC PROTOCOL: TIMEOUT");
    $fatal;
  end

endmodule
