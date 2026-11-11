//------------------------------------------------------------------------------
// Home-Automation-SoC — I2C Master Testbench
// Stage 4 Verification
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_i2c;

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
  
  // I2C pins (open-drain)
  wire i2c_scl;
  wire i2c_sda;
  
  // Pull-ups
  pullup (i2c_scl);
  pullup (i2c_sda);
  
  // DUT
  i2c_ctrl #(
    .CLK_FREQ(50_000_000),
    .I2C_FREQ(400_000)
  ) dut (
    .pclk   (clk),
    .presetn(reset_n),
    .penable(penable),
    .pwrite (pwrite),
    .paddr  (paddr),
    .pwdata (pwdata),
    .pstrb  (pstrb),
    .prdata (prdata),
    .pready (pready),
    .pslverr(pslverr),
    .i2c_scl(i2c_scl),
    .i2c_sda(i2c_sda)
  );
  
  // I2C slave model (simple EEPROM at 0x50)
  reg [7:0] slave_mem [0:255];
  reg [6:0] slave_addr = 7'h50;
  reg [7:0] slave_rx_byte;
  reg [7:0] slave_tx_byte;
  reg [3:0] slave_bit_cnt;
  reg [7:0] slave_state;  // 0=idle, 1=addr, 2=reg, 3=data
  reg [7:0] slave_reg_addr;
  reg       slave_rw;
  reg       scl_prev, sda_prev;
  
  initial begin
    for (int i = 0; i < 256; i++) slave_mem[i] = i[7:0];
  end
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      slave_state <= 8'd0;
      slave_bit_cnt <= 4'd0;
      scl_prev <= 1'b1;
      sda_prev <= 1'b1;
    end else begin
      scl_prev <= i2c_scl;
      sda_prev <= i2c_sda;
      
      // Detect START condition (SDA falling while SCL high)
      if (scl_prev && sda_prev && i2c_scl && !i2c_sda) begin
        slave_state <= 8'd1;
        slave_bit_cnt <= 4'd0;
      end
      
      // Detect STOP condition (SDA rising while SCL high)
      if (scl_prev && !sda_prev && i2c_scl && i2c_sda) begin
        slave_state <= 8'd0;
      end
      
      // Sample on SCL rising edge
      if (!scl_prev && i2c_scl) begin
        case (slave_state)
          8'd1: begin // Address byte
            slave_rx_byte <= {slave_rx_byte[6:0], i2c_sda};
            slave_bit_cnt <= slave_bit_cnt + 1;
            if (slave_bit_cnt == 7) begin
              slave_rw <= i2c_sda;
              slave_state <= 8'd2;
              slave_bit_cnt <= 4'd0;
            end
          end
          8'd2: begin // Register address or data
            slave_rx_byte <= {slave_rx_byte[6:0], i2c_sda};
            slave_bit_cnt <= slave_bit_cnt + 1;
            if (slave_bit_cnt == 7) begin
              if (!slave_rw) begin // Write
                if (slave_state == 8'd2) begin
                  slave_reg_addr <= slave_rx_byte;
                  slave_state <= 8'd3;
                end else begin
                  slave_mem[slave_reg_addr] <= slave_rx_byte;
                  slave_reg_addr <= slave_reg_addr + 1;
                end
              end else begin // Read
                slave_tx_byte <= slave_mem[slave_reg_addr];
                slave_reg_addr <= slave_reg_addr + 1;
              end
              slave_bit_cnt <= 4'd0;
            end
          end
        endcase
      end
      
      // Drive SDA on SCL falling edge (for read)
      if (scl_prev && !i2c_scl && slave_rw && (slave_state == 8'd2 || slave_state == 8'd3)) begin
        if (slave_bit_cnt < 8) begin
          // We'd drive SDA here but it's open-drain in the model
        end
      end
    end
  end
  
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
    $dumpfile("waveforms/tb_i2c.vcd");
    $dumpvars(0, tb_i2c);
    
    // Init
    reset_n = 0;
    penable = 0; pwrite = 0; paddr = 0; pwdata = 0; pstrb = 0;
    
    repeat (10) @(posedge clk);
    reset_n = 1;
    repeat (5) @(posedge clk);
    
    $display("TB: I2C test started");
    
    // Configure I2C: 400 kHz Fast mode
    apb_write(32'h00000000, 32'h0000001F);  // PRER = 400kHz @ 50MHz
    apb_write(32'h00000004, 32'h00000080);  // CTRL: enable
    
    // Test 1: Write to slave register
    $display("TB: Test 1 - Write register");
    apb_write(32'h00000008, 32'h000000A0);  // TXR: slave addr 0x50 + W
    apb_write(32'h0000000C, 32'h00000001);  // CR: START + WRITE
    
    // Wait for completion
    repeat (20000) @(posedge clk);
    
    apb_read(32'h00000010, rdata);
    $display("TB: SR after START+WRITE = 0x%02X", rdata & 8'hFF);
    
    apb_write(32'h00000008, 32'h00000010);  // TXR: register address 0x10
    apb_write(32'h0000000C, 32'h00000001);  // CR: WRITE
    repeat (20000) @(posedge clk);
    
    apb_write(32'h00000008, 32'h00000055);  // TXR: data 0x55
    apb_write(32'h0000000C, 32'h00000005);  // CR: WRITE + STOP
    repeat (20000) @(posedge clk);
    
    // Test 2: Read from slave register
    $display("TB: Test 2 - Read register");
    apb_write(32'h00000008, 32'h000000A0);  // TXR: slave addr 0x50 + W
    apb_write(32'h0000000C, 32'h00000001);  // CR: START + WRITE
    repeat (20000) @(posedge clk);
    
    apb_write(32'h00000008, 32'h00000010);  // TXR: register address 0x10
    apb_write(32'h0000000C, 32'h00000001);  // CR: WRITE
    repeat (20000) @(posedge clk);
    
    apb_write(32'h00000008, 32'h000000A1);  // TXR: slave addr 0x50 + R
    apb_write(32'h0000000C, 32'h00000001);  // CR: START + WRITE (repeated start)
    repeat (20000) @(posedge clk);
    
    apb_write(32'h0000000C, 32'h0000000A);  // CR: READ + NACK + STOP
    repeat (20000) @(posedge clk);
    
    apb_read(32'h00000008, rdata);
    $display("TB: RXR = 0x%02X (expected 0x55)", rdata & 8'hFF);
    
    $display("TB: I2C test complete");
    $finish;
  end
  
  reg [31:0] rdata;

endmodule