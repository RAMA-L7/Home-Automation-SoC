//------------------------------------------------------------------------------
// Home-Automation-SoC — watchdog reset: domain isolation and recovery
//
// The defect this targets is a WIRING defect in has_soc.sv, so the test has to
// run on the real SoC: the CPU and peripherals were reset by `rst_sys_n` while
// the transaction path (adapter, interconnect, APB bridge, memory ports, INTC)
// was reset by the external pad `reset_n` only.  A watchdog reset therefore
// restarted the CPU while a grant, an in-flight write or a pending B/R response
// was still live in the fabric — state the restarted CPU cannot distinguish
// from its own.
//
// A watchdog timeout is injected with `force dut.wdog_timeout`, which drives the
// real reset_ctrl and therefore the real `rst_sys_n` net, at four points:
//
//   P1  accepted by the request adapter but not yet by the slave
//   P2  in the cycle the write address and write data are accepted
//   P3  during the APB ACCESS phase
//   P4  while a write response is pending
//
// Note on P2: the originally proposed point "between write-address and
// write-data acceptance" does not exist in this design.  The request adapter
// drives AWVALID and WVALID together, and the APB bridge accepts both in the
// same cycle, so `have_aw=1 && have_w=0` is never observable.  Resetting on
// that acceptance edge is the closest reachable equivalent and is what P2 does;
// the property "a write is never left half-accepted" is asserted separately.
//
// At each point the pad reset stays HIGH, so anything that is still holding
// state afterwards is genuinely outside the system-reset domain.
//
// Also checked:
//   * no stale grant/response is presented to the restarted CPU;
//   * repeated resets recover (no deadlock) — the program completes each time;
//   * memory contents persist across a system reset (the TCM trap counter keeps
//     accumulating), which is the explicit persistence contract: memory arrays
//     keep their contents, control state does not.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_reset_recovery;

  reg clk = 1'b0;
  reg reset_n = 1'b0;
  always #10 clk = ~clk;

  wire [15:0] gpio;
  wire [3:0]  qspi_io;
  wire        i2c_scl, i2c_sda;
  wire        jtag_tdo, uart_tx, spi_sck, spi_mosi, spi_cs_n;
  wire [3:0]  pwm_out;
  wire        i2s_bclk, i2s_lrclk, i2s_dout;
  wire        qspi_sck, qspi_cs_n;
  wire        wdog_reset_n_out, core_clk_en_o, wake_req;

  assign gpio    = 16'bz;
  assign qspi_io = 4'bz;
  assign i2c_scl = 1'bz;
  assign i2c_sda = 1'bz;

  has_soc #(
    .BOOT_ROM_FILE  ("build/sim/apb_jump.hex"),
    .TCM_INIT_FILE  ("build/sim/apb_integrated.hex")
  ) dut (
    .clk(clk), .reset_n(reset_n),
    .jtag_tck(1'b0), .jtag_tms(1'b0), .jtag_tdi(1'b0), .jtag_tdo(jtag_tdo),
    .jtag_trst_n(1'b1),
    .ext_irq(32'd0),
    .uart_tx(uart_tx), .uart_rx(1'b1),
    .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(1'b1), .spi_cs_n(spi_cs_n),
    .i2c_scl(i2c_scl), .i2c_sda(i2c_sda),
    .gpio(gpio),
    .pwm_out(pwm_out),
    .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk), .i2s_dout(i2s_dout), .i2s_din(1'b0),
    .qspi_sck(qspi_sck), .qspi_cs_n(qspi_cs_n), .qspi_io(qspi_io),
    .wdog_reset_n_out(wdog_reset_n_out), .core_clk_en_o(core_clk_en_o),
    .wake_req(wake_req), .wake_ack(1'b0)
  );

  integer errors = 0;
  integer checks = 0;

  // Property: a write is never left half-accepted.  AW and W are presented and
  // accepted together, so `have_aw && !have_w` must never be observed outside
  // reset.  Checked continuously, reported at the end.
  reg half_accepted_seen = 1'b0;
  always @(posedge clk) begin
    if (dut.rst_sys_n === 1'b1 && dut.apb_bridge.have_aw === 1'b1 &&
        dut.apb_bridge.have_w === 1'b0)
      half_accepted_seen <= 1'b1;
  end

  task chk(input [8*52-1:0] name, input cond);
    begin
      checks = checks + 1;
      if (cond !== 1'b1) begin
        errors = errors + 1;
        $display("[reset] FAIL %0s", name);
      end else begin
        $display("[reset] pass %0s", name);
      end
    end
  endtask

  // Force one watchdog timeout: reset_ctrl then produces a bounded rst_sys_n
  // pulse, exactly as it does on a real timeout.  The timeout state is forced
  // on the watchdog's own registers (`wdog_timeout` is a continuous assignment
  // and cannot be forced); this is a stimulus override, not a change to the
  // logic under test — reset_ctrl, the reset tree and every consumer are real.
  task inject_timeout;
    begin
      @(posedge clk);
      force dut.wdog_inst.expired  = 1'b1;
      force dut.wdog_inst.reset_en = 1'b1;
      @(posedge clk);                       // reset_ctrl latches `active` here
      release dut.wdog_inst.expired;
      release dut.wdog_inst.reset_en;
    end
  endtask

  // Bounded wait for a phase condition.  The condition must be re-evaluated on
  // every cycle: sampling it once would either exit immediately or never.
  // A task, not a function, because it waits on clock edges.
  //   1 request outstanding   2 between AW and W   3 during APB ACCESS
  //   4 response pending      5 firmware halted
  reg     tb_cond = 1'b0;
  integer wait_cycles;
  integer wait_result;

  task wait_phase(input integer which, input integer max_cycles);
    integer done;
    begin
      wait_cycles = 0;
      wait_result = 0;
      done = 0;
      while (!done && wait_cycles < max_cycles) begin
        case (which)
          // 1: accepted by the adapter but not yet by the slave (A_WR_AW /
          // A_RD_AR) — "before acceptance" at the fabric end.
          1: tb_cond = (dut.data_adapter.state === 1) || (dut.data_adapter.state === 4);
          2: tb_cond = dut.apb_bridge.s_awvalid && dut.apb_bridge.s_awready &&
                       dut.apb_bridge.s_wvalid  && dut.apb_bridge.s_wready;
          3: tb_cond = (dut.apb_bridge.state === 2);       // B_ACCESS
          4: tb_cond = dut.m_bvalid;
          5: tb_cond = (dut.core.pc === 32'h0001_008C);    // `j halt`
          default: tb_cond = 1'b1;
        endcase
        if (tb_cond) begin
          wait_result = 1;
          done = 1;
        end else begin
          @(posedge clk);
          wait_cycles = wait_cycles + 1;
        end
      end
    end
  endtask

  // Applied at each injection point, once rst_sys_n is actually asserted.
  // `reset_n` must still be high: these blocks are only outside the system
  // reset domain if the pad reset alone cannot explain the cleared state.
  task check_domain(input [8*52-1:0] phase);
    begin
      chk("pad reset stayed high during the system reset", reset_n === 1'b1);
      chk({phase, ": adapter not in reset state"},
          dut.data_adapter.state === 0);
      chk({phase, ": interconnect not in reset state"},
          dut.axi_ic.state === 0);
      chk({phase, ": APB bridge not in reset state"},
          dut.apb_bridge.state === 0);
      chk({phase, ": APB bridge still holds a write address"},
          dut.apb_bridge.have_aw === 1'b0);
      chk({phase, ": a write response survived the reset"},
          dut.m_bvalid === 1'b0);
      chk({phase, ": a read response survived the reset"},
          dut.m_rvalid === 1'b0);
      chk({phase, ": system reset is actually asserted"},
          dut.rst_sys_n === 1'b0);
    end
  endtask

  // After the reset releases the restarted CPU must not be handed anything.
  task check_no_stale_response(input [8*52-1:0] phase);
    integer n;
    begin
      for (n = 0; n < 20; n = n + 1) begin
        @(posedge clk);
        if (dut.data_rvalid !== 1'b0 || dut.data_err !== 1'b0) begin
          chk({phase, ": no stale response reaches the CPU"}, 1'b0);
          disable check_no_stale_response;
        end
      end
      chk({phase, ": no stale response reaches the CPU"}, 1'b1);
    end
  endtask

  task run_phase(input [8*52-1:0] phase, input integer which);
    begin
      // Let the current program run finish, then restart it so the injection
      // point is looked for during live traffic rather than in the halt loop.
      wait_phase(5, 200000);
      inject_timeout;
      @(negedge dut.rst_sys_n);
      @(posedge dut.rst_sys_n);

      wait_phase(which, 60000);
      chk({phase, ": injection point reached"}, wait_result);
      inject_timeout;
      @(negedge dut.rst_sys_n);
      @(posedge clk);            // let the asynchronous reset settle
      check_domain(phase);
      @(posedge dut.rst_sys_n);
      check_no_stale_response(phase);
    end
  endtask

  // Wait for the program to reach its halt loop (pc parked on `j halt`).
  task wait_halted(input [8*52-1:0] phase);
    begin
      wait_phase(5, 200000);
      chk({phase, ": firmware reached its halt loop"}, wait_result);
    end
  endtask

  integer n1, n2;
  integer p;

  initial begin
    reset_n = 1'b0;
    repeat (10) @(posedge clk);
    reset_n = 1'b1;

    wait_halted("initial run");
    n1 = dut.tcm_inst.mem[128];
    $display("[reset] initial run produced %0d traps", n1);
    chk("initial run completed the program", n1 >= 4);

    // ---- the four injection points ------------------------------------
    run_phase("P1 request outstanding",        1);
    run_phase("P2 between AW and W",           2);
    run_phase("P3 during APB access",          3);
    run_phase("P4 write response pending",     4);

    // ---- recovery: every reset must end with a working SoC -------------
    wait_halted("after four resets");
    chk("SoC recovered after four watchdog resets",
        dut.tcm_inst.mem[128] >= 4);
    chk("GPIO result survived the resets (program reran correctly)",
        dut.tcm_inst.mem[68] === 32'h0000_5678);

    // ---- persistence contract ------------------------------------------
    // Reset while the firmware is parked in its halt loop, then let the whole
    // program run again.  The TCM is initialised only by $readmemh, so its
    // contents must persist: the trap counter must accumulate rather than
    // restart from zero.
    n1 = dut.tcm_inst.mem[128];
    inject_timeout;
    @(negedge dut.rst_sys_n);
    @(posedge dut.rst_sys_n);
    wait_halted("after the persistence reset");
    n2 = dut.tcm_inst.mem[128];
    $display("[reset] trap counter %0d -> %0d across a system reset", n1, n2);
    chk("memory contents persist across a system reset", n2 > n1);
    chk("one complete extra run added exactly its traps", (n2 - n1) === 4);
    chk("no write was ever left half-accepted", half_accepted_seen === 1'b0);

    $display("");
    $display("[reset] checks: %0d, failures: %0d", checks, errors);
    if (errors == 0) begin
      $display("RESET RECOVERY: ALL TESTS PASSED");
      $finish;
    end else begin
      $display("RESET RECOVERY: %0d FAILURES", errors);
      $fatal(1, "reset recovery test failed");
    end
  end

  initial begin
    #40_000_000;
    $display("RESET RECOVERY: TIMEOUT (pc=0x%08h rst_sys_n=%b)", dut.core.pc, dut.rst_sys_n);
    $fatal(1, "reset recovery test timed out");
  end

endmodule
