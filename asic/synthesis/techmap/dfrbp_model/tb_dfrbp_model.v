// ---------------------------------------------------------------------------
// F3 — targeted test for the sky130_fd_sc_hd__dfrbp_* behavioural models.
//
// Authoritative definition (build/asic_evidence/sky130_tt.lib, liberty from the
// SKY130 HD library, hash recorded in the run evidence):
//     cell ("sky130_fd_sc_hd__dfrbp_1") {
//         ff ("IQ","IQ_N") {
//             clear       : "!RESET_B";   // asynchronous, active low
//             clocked_on  : "CLK";        // positive edge (no '!' prefix)
//             next_state  : "D";
//         }
//         timing arcs: CLK -> Q  timing_type "rising_edge";
//                      RESET_B -> Q timing_type "clear"
//     }
//
// So: capture on the RISING edge of CLK, clear asynchronously while RESET_B is
// low, Q_N is the complement. This bench drives exactly those situations and
// compares against literal expected values — it is not derived from the model it
// tests.
//
// The directed sequence contains two checks that only a wrong-edge model can
// fail while still behaving plausibly:
//   * the first rising edge must capture (a negedge model keeps the old value);
//   * a falling edge with new data must NOT capture (a negedge model does).
//
// Compile: iverilog -g2012 -o sim.vvp tb_dfrbp_model.v <stub>.v
// Run:     vvp sim.vvp   -> prints "DFRBP_MODEL: PASS checks=N fails=0", exit 0;
//                              or "DFRBP_MODEL: FAIL ..." and $fatal, exit != 0.
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module tb_dfrbp_model;

  reg clk     = 1'b0;
  reg d       = 1'b0;
  reg reset_b = 1'b1;

  wire q1, qn1, q2, qn2;

  sky130_fd_sc_hd__dfrbp_1 u_dfrbp_1 (
    .CLK(clk), .D(d), .Q(q1), .Q_N(qn1), .RESET_B(reset_b)
  );
  sky130_fd_sc_hd__dfrbp_2 u_dfrbp_2 (
    .CLK(clk), .D(d), .Q(q2), .Q_N(qn2), .RESET_B(reset_b)
  );

  integer checks = 0;
  integer fails  = 0;

  // Both drive strengths must behave identically; Q_N must track ~Q.
  task check(input [319:0] label, input expected_q);
    begin
      #0.1;
      checks = checks + 1;
      if (q1 !== expected_q || q2 !== expected_q ||
          qn1 !== !expected_q || qn2 !== !expected_q) begin
        fails = fails + 1;
        $display("FAIL %0s at t=%0t: q1=%b q2=%b qn1=%b qn2=%b, expected q=%b qn=%b",
                 label, $time, q1, q2, qn1, qn2, expected_q, !expected_q);
      end
    end
  endtask

  initial begin
    // 1. asynchronous active-low clear, asserted with no clock edge
    reset_b = 1'b1;
    #1 reset_b = 1'b0;
    check("async clear (RESET_B=0, no clock edge)", 1'b0);

    // 2. clear dominates D
    d = 1'b1;
    check("clear holds Q=0 while D=1", 1'b0);

    // 3. releasing reset is not a capture event
    reset_b = 1'b1;
    check("reset released, no clock edge yet", 1'b0);

    // 4. rising edge must capture
    #1 clk = 1'b1;
    check("rising edge captures D=1", 1'b1);

    // 5. falling edge must NOT capture (the discriminator)
    d = 1'b0;
    #1 clk = 1'b0;
    check("falling edge must not capture (D=0 ignored)", 1'b1);

    // 6. next rising edge captures the new value
    #1 clk = 1'b1;
    check("rising edge captures D=0", 1'b0);

    // 7. asynchronous clear while CLK is low, mid-period
    d = 1'b1;
    reset_b = 1'b0;
    check("async clear with CLK low, no clock edge", 1'b0);

    // 8. release without a clock edge
    reset_b = 1'b1;
    check("reset release does not capture", 1'b0);

    // 9. capture after reset — CLK is still high, so drive a real rising edge
    clk = 1'b0;
    #1 clk = 1'b1;
    check("rising edge after reset captures D=1", 1'b1);

    // 10. second falling-edge check
    d = 1'b0;
    #1 clk = 1'b0;
    check("second falling edge must not capture", 1'b1);

    // 11. second rising-edge check
    #1 clk = 1'b1;
    check("second rising edge captures D=0", 1'b0);

    if (fails == 0) begin
      $display("DFRBP_MODEL: PASS checks=%0d fails=%0d", checks, fails);
    end else begin
      $display("DFRBP_MODEL: FAIL checks=%0d fails=%0d", checks, fails);
      $fatal(1, "dfrbp behavioural model disagrees with the liberty definition");
    end
    $finish;
  end

endmodule

`default_nettype wire
