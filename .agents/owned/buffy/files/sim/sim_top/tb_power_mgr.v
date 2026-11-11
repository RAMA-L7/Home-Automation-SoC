`timescale 1ns/1ps
//------------------------------------------------------------------------------
// Power manager testbench — registers + sleep/wake FSM
//
// Covers the review items that were previously untested:
//   - APB register read/write of PM_CTRL / PM_STATUS / PM_WAKE_EN
//   - sleep request gates core/peripheral clocks and asserts wake_req
//   - an asynchronous wake_ack (asserted off-clock) resumes the clocks
//   - wake_event clears the sticky sleep request
//   - a pending wake blocks sleep entry (wake wins the race)
//
// Run:
//   iverilog -g2012 -o build/sim/tb_power_mgr.vvp -s tb_power_mgr \
//       sim/sim_top/tb_power_mgr.v rtl/rtl_peripherals/power_mgr_regs.sv \
//       rtl/rtl_peripherals/power_mgr.sv
//   vvp build/sim/tb_power_mgr.vvp        # exits nonzero on failure
//------------------------------------------------------------------------------
module tb_power_mgr;

  reg         clk = 0;
  reg         reset_n = 0;
  always #5 clk = ~clk;

  integer errors = 0;
  integer checks = 0;

  task check(input cond, input [8*48-1:0] name);
    begin
      checks = checks + 1;
      if (!cond) begin
        errors = errors + 1;
        $display("[pwr] FAIL: %0s", name);
      end
    end
  endtask

  //==========================================================================
  // 1. Register block
  //==========================================================================
  reg         penable = 0, pwrite = 0;
  reg  [31:0] paddr = 0, pwdata = 0;
  reg  [3:0]  pstrb = 0;
  wire [31:0] prdata;
  wire        pready, pslverr, irq;
  wire        sleep_req_w;
  reg         wake_clear = 0;

  power_mgr_regs regs (
    .pclk(clk), .presetn(reset_n),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata),
    .pstrb(pstrb),
    .prdata(prdata), .pready(pready), .pslverr(pslverr),
    .irq(irq), .sleep_req_o(sleep_req_w),
    .wake_clear(wake_clear)
  );

  task apb_write(input [31:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      penable = 1; pwrite = 1; paddr = addr; pwdata = data; pstrb = 4'b1111;
      @(posedge clk);
      penable = 0; pwrite = 0; pstrb = 0;
    end
  endtask

  task apb_read(input [31:0] addr, output reg [31:0] data);
    begin
      @(posedge clk);
      penable = 1; pwrite = 0; paddr = addr;
      @(posedge clk);
      data = prdata;
      penable = 0;
    end
  endtask

  //==========================================================================
  // 2. Sleep/wake FSM
  //==========================================================================
  reg         fs_sleep_req = 0;
  reg         fs_wake_ack = 0;
  wire        core_clk_en, periph_clk_en, wake_req, wake_event;

  power_mgr fsm (
    .clk(clk), .reset_n(reset_n),
    .sleep_req(fs_sleep_req),
    .core_clk_en(core_clk_en), .periph_clk_en(periph_clk_en),
    .wake_req(wake_req), .wake_ack(fs_wake_ack), .wake_event(wake_event)
  );

  integer wake_pulses = 0;
  always @(posedge clk) if (wake_event) wake_pulses = wake_pulses + 1;

  reg [31:0] rd;

  initial begin
    repeat (6) @(posedge clk);
    reset_n = 1;
    repeat (4) @(posedge clk);

    //--- registers -----------------------------------------------------
    apb_write(32'h0000_0000, 32'h1);            // PM_CTRL.sleep_request = 1
    check(sleep_req_w == 1'b1, "PM_CTRL write drives sleep_req_o");
    apb_read (32'h0000_0000, rd);
    check(rd[0] == 1'b1, "PM_CTRL read-back");

    apb_write(32'h0000_0008, 32'h1);            // PM_WAKE_EN
    apb_read (32'h0000_0008, rd);
    check(rd[0] == 1'b1, "PM_WAKE_EN read-back");

    // wake_clear must clear the sticky request
    @(posedge clk); wake_clear = 1; @(posedge clk); wake_clear = 0;
    @(posedge clk);
    check(sleep_req_w == 1'b0, "wake_clear clears sticky sleep request");
    apb_read(32'h0000_0000, rd);
    check(rd[0] == 1'b0, "PM_CTRL reads 0 after wake_clear");

    //--- sleep entry ---------------------------------------------------
    check(core_clk_en == 1'b1 && periph_clk_en == 1'b1, "awake after reset");
    fs_sleep_req = 1;
    repeat (4) @(posedge clk);
    check(core_clk_en == 1'b0, "sleep request gates core clock");
    check(periph_clk_en == 1'b0, "sleep request gates peripheral clock");
    check(wake_req == 1'b1, "sleep asserts wake_req");

    //--- asynchronous wake ---------------------------------------------
    // Assert wake_ack between clock edges, as an external pin would.
    #2 fs_wake_ack = 1;
    repeat (6) @(posedge clk);
    check(core_clk_en == 1'b1, "wake_ack resumes core clock");
    check(periph_clk_en == 1'b1, "wake_ack resumes peripheral clock");
    check(wake_pulses >= 1, "wake_event pulsed on wake");
    check(wake_req == 1'b0, "wake_req deasserts after wake");

    //--- wake wins the race --------------------------------------------
    // Hold wake pending (synchronized), then request sleep: must stay awake.
    fs_wake_ack = 1;
    repeat (4) @(posedge clk);
    fs_sleep_req = 1;
    repeat (4) @(posedge clk);
    check(core_clk_en == 1'b1, "pending wake blocks sleep entry");
    fs_wake_ack = 0;
    fs_sleep_req = 0;
    repeat (3) @(posedge clk);

    //--- sleep again after the wake clears ------------------------------
    fs_sleep_req = 1;
    repeat (4) @(posedge clk);
    check(core_clk_en == 1'b0, "second sleep entry works");
    #2 fs_wake_ack = 1;
    repeat (6) @(posedge clk);
    check(core_clk_en == 1'b1, "second wake works");
    fs_wake_ack = 0;
    fs_sleep_req = 0;

    $display("[pwr] checks: %0d, failures: %0d", checks, errors);
    if (errors != 0) begin
      $display("[pwr] RESULT: FAIL");
      $fatal(1, "[pwr] %0d check(s) failed", errors);
    end
    $display("[pwr] RESULT: PASS");
    $finish;
  end

  initial begin
    #100_000;
    $fatal(1, "[pwr] simulation timeout");
  end

endmodule
