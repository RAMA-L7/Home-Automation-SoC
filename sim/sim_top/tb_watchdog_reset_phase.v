`timescale 1ns/1ps
module tb_watchdog_reset_phase;
  reg clk = 0;
  reg reset_n = 1;
  always #5 clk = ~clk;

  // AXI side
  reg  [31:0] s_awaddr, s_wdata, s_araddr;
  reg         s_awvalid, s_wvalid, s_arvalid, s_bready, s_rready;
  reg  [3:0]  s_wstrb;
  wire        s_awready, s_wready, s_arready, s_bvalid, s_rvalid;
  wire [1:0]  s_bresp, s_rresp;
  wire [31:0] s_rdata;

  // APB side
  wire        penable, pwrite;
  wire [31:0] paddr, pwdata;
  wire [3:0]  pstrb;
  reg  [31:0] prdata;
  reg         pready;
  reg         pslverr;

  axi_lite_to_apb dut (
    .clk(clk), .reset_n(reset_n),
    .s_awvalid(s_awvalid), .s_awready(s_awready), .s_awaddr(s_awaddr), .s_awprot(3'd0),
    .s_wvalid(s_wvalid), .s_wready(s_wready), .s_wdata(s_wdata), .s_wstrb(s_wstrb),
    .s_bvalid(s_bvalid), .s_bready(s_bready), .s_bresp(s_bresp),
    .s_arvalid(s_arvalid), .s_arready(s_arready), .s_araddr(s_araddr), .s_arprot(3'd0),
    .s_rvalid(s_rvalid), .s_rready(s_rready), .s_rdata(s_rdata), .s_rresp(s_rresp),
    .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .pslverr(pslverr), .prdata(prdata), .pready(pready)
  );

  // APB slave: a simple register; pready held low for two access cycles so
  // reset can be injected while the bridge is in B_ACCESS.
  reg [31:0] slave_reg;
  reg [1:0]  access_delay;
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      slave_reg <= 32'd0;
      access_delay <= 2'd0;
      pready <= 1'b0;
    end else begin
      pready <= 1'b0;
      if (penable) begin
        if (access_delay == 2'd0) begin
          access_delay <= 2'd1;
        end else if (access_delay == 2'd1) begin
          access_delay <= 2'd2;
        end else begin
          pready <= 1'b1;
          if (pwrite) slave_reg <= pwdata;
          else prdata <= slave_reg;
          access_delay <= 2'd0;
        end
      end else begin
        access_delay <= 2'd0;
      end
    end
  end
  assign pslverr = 1'b0;

  integer errors = 0;
  task chk(input [255:0] name, input cond);
    begin
      if (!cond) begin
        $display("[wdreset] FAIL %0s", name);
        errors = errors + 1;
      end else begin
        $display("[wdreset] pass %0s", name);
      end
    end
  endtask

  reg inject_setup = 0;
  reg inject_access = 0;
  reg reset_pending = 0;

  // Inject a one-cycle system reset when the bridge reaches the requested phase.
  always @(posedge clk) begin
    if (inject_setup && dut.state == 1) begin
      reset_n <= 1'b0;
      inject_setup <= 1'b0;
      reset_pending <= 1'b1;
    end else if (inject_access && dut.state == 2) begin
      reset_n <= 1'b0;
      inject_access <= 1'b0;
      reset_pending <= 1'b1;
    end else if (reset_pending) begin
      reset_n <= 1'b1;
      reset_pending <= 1'b0;
    end
  end

  // Enum access workaround: compare numeric state encoding instead.
  // axi_lite_to_apb states: B_IDLE=0, B_SETUP=1, B_ACCESS=2, B_WRESP=3, B_RRESP=4
  // The enum cast above may not be available in all tools, so redefine checks
  // using the dut.state integer value via a helper.

  initial begin
    s_awvalid = 0; s_wvalid = 0; s_arvalid = 0; s_bready = 1; s_rready = 1;
    s_awaddr = 0; s_wdata = 0; s_araddr = 0; s_wstrb = 4'hF;
    prdata = 0;
    reset_n = 0;
    repeat (5) @(posedge clk);
    reset_n = 1;
    repeat (2) @(posedge clk);

    // Test 1: reset during SETUP phase returns to idle, no stale response.
    inject_setup = 1;
    @(posedge clk);
    s_awvalid = 1; s_wvalid = 1; s_awaddr = 32'h50000000; s_wdata = 32'h12345678; s_wstrb = 4'hF;
    @(posedge clk);
    s_awvalid = 0; s_wvalid = 0;
    repeat (10) @(posedge clk);
    chk("setup reset returns idle", dut.state == 0);
    chk("setup reset clears bvalid", s_bvalid == 1'b0);

    // Test 2: reset during ACCESS phase returns to idle, no stale response.
    inject_access = 1;
    @(posedge clk);
    s_awvalid = 1; s_wvalid = 1; s_awaddr = 32'h50000000; s_wdata = 32'hABCDEF01; s_wstrb = 4'hF;
    @(posedge clk);
    s_awvalid = 0; s_wvalid = 0;
    repeat (10) @(posedge clk);
    chk("access reset returns idle", dut.state == 0);
    chk("access reset clears bvalid", s_bvalid == 1'b0);

    // Test 3: a normal transaction still works after reset injection.
    @(posedge clk);
    s_awvalid = 1; s_wvalid = 1; s_awaddr = 32'h50000000; s_wdata = 32'h55AA55AA; s_wstrb = 4'hF;
    @(posedge clk);
    s_awvalid = 0; s_wvalid = 0;
    // wait for completion
    begin : wait_done
      integer n;
      for (n = 0; n < 100; n = n + 1) begin
        if (s_bvalid) disable wait_done;
        @(posedge clk);
      end
    end
    chk("post-reset transaction completes", s_bvalid == 1'b1);
    if (s_bvalid) s_bready = 1;
    @(posedge clk);
    s_bready = 1;

    if (errors == 0) begin
      $display("WATCHDOG RESET PHASE: ALL TESTS PASSED");
    end else begin
      $display("WATCHDOG RESET PHASE: %0d FAILURES", errors);
      $fatal;
    end
    $finish;
  end

  initial begin #100000; $display("WATCHDOG RESET PHASE: TIMEOUT"); $fatal; end
endmodule