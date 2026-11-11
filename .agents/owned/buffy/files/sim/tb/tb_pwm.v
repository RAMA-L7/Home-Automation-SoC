//------------------------------------------------------------------------------
// Home-Automation-SoC — PWM Testbench
// Stage 4 Verification
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_pwm;

  reg clk;
  reg reset_n;
  
  // APB interface
  reg        penable;
  reg        pwrite;
  reg [31:0] paddr;
  reg [31:0] pwdata;
  reg [3:0]  pstrb;
  wire [31:0] prdata;
  wire        pready;
  wire        pslverr;
  
  // PWM outputs
  wire [3:0] pwm_out;
  
  // DUT
  pwm #(
    .CLK_FREQ(50_000_000),
    .CHANNELS(4)
  ) dut (
    .pclk     (clk),
    .presetn  (reset_n),
    .penable  (penable),
    .pwrite   (pwrite),
    .paddr    (paddr),
    .pwdata   (pwdata),
    .pstrb    (pstrb),
    .prdata   (prdata),
    .pready   (pready),
    .pslverr  (pslverr),
    .pwm_out  (pwm_out)
  );
  
  // Clock
  initial clk = 0;
  always #10 clk = ~clk;  // 50 MHz
  
  // Tasks
  task apb_write(input [31:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      penable = 1; pwrite = 1; paddr = addr; pwdata = data; pstrb = 4'b1111;
      @(posedge clk);
      penable = 0;
      @(posedge clk);
    end
  endtask
  
  task apb_read(input [31:0] addr, output [31:0] data);
    begin
      @(posedge clk);
      penable = 1; pwrite = 0; paddr = addr; pstrb = 4'b1111;
      @(posedge clk);
      data = prdata;
      penable = 0;
      @(posedge clk);
    end
  endtask
  
  // Test sequence
  initial begin
    $dumpfile("waveforms/tb_pwm.vcd");
    $dumpvars(0, tb_pwm);
    
    // Init
    reset_n = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);
    
    $display("TB: PWM test started");
    
    // Test 1: PWM0 - 1 kHz, 50% duty
    $display("TB: Test 1 - PWM0 1kHz 50%");
    apb_write(32'h00000000, 32'h00000001);  // CTRL: enable PWM0
    apb_write(32'h00000004, 32'h00000001);  // CH0_CTRL: enable
    apb_write(32'h00000008, 32'h0000C350);  // CH0_PERIOD: 50000 cycles (1kHz @ 50MHz)
    apb_write(32'h0000000C, 32'h000061A8);  // CH0_DUTY: 25000 cycles (50%)
    repeat (100000) @(posedge clk);
    
    // Test 2: PWM1 - 10 kHz, 25% duty
    $display("TB: Test 2 - PWM1 10kHz 25%");
    apb_write(32'h00000000, 32'h00000003);  // CTRL: enable PWM0, PWM1
    apb_write(32'h00000014, 32'h00000001);  // CH1_CTRL: enable
    apb_write(32'h00000018, 32'h00001388);  // CH1_PERIOD: 5000 cycles (10kHz)
    apb_write(32'h0000001C, 32'h000004E2);  // CH1_DUTY: 1250 cycles (25%)
    repeat (100000) @(posedge clk);
    
    // Test 3: PWM2 - 100 kHz, 75% duty
    $display("TB: Test 3 - PWM2 100kHz 75%");
    apb_write(32'h00000000, 32'h00000007);  // CTRL: enable PWM0-2
    apb_write(32'h00000024, 32'h00000001);  // CH2_CTRL: enable
    apb_write(32'h00000028, 32'h000001F4);  // CH2_PERIOD: 500 cycles (100kHz)
    apb_write(32'h0000002C, 32'h00000177);  // CH2_DUTY: 375 cycles (75%)
    repeat (100000) @(posedge clk);
    
    // Test 4: PWM3 - 1 MHz, 10% duty
    $display("TB: Test 4 - PWM3 1MHz 10%");
    apb_write(32'h00000000, 32'h0000000F);  // CTRL: enable all
    apb_write(32'h00000034, 32'h00000001);  // CH3_CTRL: enable
    apb_write(32'h00000038, 32'h00000032);  // CH3_PERIOD: 50 cycles (1MHz)
    apb_write(32'h0000003C, 32'h00000005);  // CH3_DUTY: 5 cycles (10%)
    repeat (100000) @(posedge clk);
    
    // Test 5: Center-aligned mode
    $display("TB: Test 5 - Center-aligned");
    apb_write(32'h00000044, 32'h00000001);  // CH0_CTRL: center-aligned
    repeat (100000) @(posedge clk);
    
    // Test 6: Dead time insertion
    $display("TB: Test 6 - Dead time");
    apb_write(32'h00000048, 32'h00000010);  // CH0_DEAD: 16 cycles dead time
    repeat (100000) @(posedge clk);
    
    // Test 7: Synchronization
    $display("TB: Test 7 - Synchronization");
    apb_write(32'h00000000, 32'h0000000F);  // CTRL: sync enable
    repeat (100000) @(posedge clk);
    
    // Read back registers
    apb_read(32'h00000000, rdata);
    $display("TB: CTRL = 0x%08X", rdata);
    apb_read(32'h00000008, rdata);
    $display("TB: CH0_PERIOD = 0x%08X", rdata);
    apb_read(32'h0000000C, rdata);
    $display("TB: CH0_DUTY = 0x%08X", rdata);
    
    $display("TB: PWM test complete");
    $finish;
  end
  
  reg [31:0] rdata;

endmodule