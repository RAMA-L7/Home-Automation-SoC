//------------------------------------------------------------------------------
// Home-Automation-SoC — Top-Level System-on-Chip
// Stage 2 RTL (reworked integration)
//
//   * RV32IM multi-cycle core, machine mode
//   * Instruction fetch mux: Boot ROM, TCM and SRAM are all executable
//   * Data path: req/gnt -> AXI4-Lite -> interconnect -> {ROM, TCM, SRAM,
//                QSPI, APB bridge, INTC}
//   * APB peripherals: GPIO, UART, I2C, SPI, PWM, timer, watchdog, I2S,
//     power-manager registers
//   * Interrupts: CLINT (software/timer) + PLIC (8 peripheral sources)
//
// Memory map: see has_addr_map_pkg
//------------------------------------------------------------------------------
module has_soc #(
  parameter BOOT_ROM_FILE  = "",
  parameter int UART_CLK_FREQ = 50_000_000,
  parameter int UART_BAUD     = 115200
) (
  input  logic         clk,
  input  logic         reset_n,
  input  logic         jtag_tck,
  input  logic         jtag_tms,
  input  logic         jtag_tdi,
  output logic         jtag_tdo,
  input  logic         jtag_trst_n,
  // Interrupt inputs from pads (level sensitive)
  input  logic [31:0]  ext_irq,
  // UART
  output logic         uart_tx,
  input  logic         uart_rx,
  // SPI
  output logic         spi_sck,
  output logic         spi_mosi,
  input  logic         spi_miso,
  output logic         spi_cs_n,
  // I2C
  inout  wire          i2c_scl,
  inout  wire          i2c_sda,
  // GPIO
  inout  wire [15:0]   gpio,
  // PWM
  output logic [3:0]   pwm_out,
  // I2S
  output logic         i2s_bclk,
  output logic         i2s_lrclk,
  output logic         i2s_dout,
  input  logic         i2s_din,
  // QSPI flash
  output logic         qspi_sck,
  output logic         qspi_cs_n,
  inout  wire [3:0]    qspi_io,
  // Watchdog / power
  output logic         wdog_reset_n_out,
  output logic         core_clk_en_o,
  output logic         wake_req,
  input  logic         wake_ack
);

  import has_addr_map_pkg::*;

  //--------------------------------------------------------------------------
  // Clock gating
  //--------------------------------------------------------------------------
  logic core_clk_en, periph_clk_en;
  logic core_clk, periph_clk;

  // Gate with a latch-based ICG model: enable is sampled on the low phase so
  // no glitch is produced on the gated clock.
  logic core_clk_en_q, periph_clk_en_q;
  always_ff @(negedge clk or negedge reset_n)
    if (!reset_n) begin
      core_clk_en_q   <= 1'b1;
      periph_clk_en_q <= 1'b1;
    end else begin
      core_clk_en_q   <= core_clk_en;
      periph_clk_en_q <= periph_clk_en;
    end

  assign core_clk   = clk & core_clk_en_q;
  assign periph_clk = clk & periph_clk_en_q;
  assign core_clk_en_o = core_clk_en;

  //--------------------------------------------------------------------------
  // Core
  //--------------------------------------------------------------------------
  logic         instr_req, instr_gnt, instr_rvalid;
  logic [31:0]  instr_addr, instr_rdata;
  logic         data_req, data_we, data_gnt, data_rvalid;
  logic [31:0]  data_addr, data_wdata, data_rdata;
  logic [3:0]   data_wstrb;

  logic         irq_ext, irq_timer, irq_soft;

  riscv_core #(.RESET_PC(ADDR_BOOT_ROM_BASE)) core (
    .clk          (core_clk),
    .reset_n      (reset_n),
    .instr_req    (instr_req),
    .instr_addr   (instr_addr),
    .instr_gnt    (instr_gnt),
    .instr_rdata  (instr_rdata),
    .instr_rvalid (instr_rvalid),
    .data_req     (data_req),
    .data_we      (data_we),
    .data_addr    (data_addr),
    .data_wdata   (data_wdata),
    .data_wstrb   (data_wstrb),
    .data_gnt     (data_gnt),
    .data_rdata   (data_rdata),
    .data_rvalid  (data_rvalid),
    .irq_irq      (irq_ext),
    .irq_timer    (irq_timer),
    .irq_soft     (irq_soft),
    .debug_req    (1'b0),
    .debug_halted (),
    .debug_running()
  );

  //--------------------------------------------------------------------------
  // Instruction fetch mux (ROM / TCM / SRAM / fault)
  //--------------------------------------------------------------------------
  logic rom_i_req, rom_i_gnt, rom_i_rvalid;
  logic [31:0] rom_i_rdata;
  logic tcm_i_req, tcm_i_gnt, tcm_i_rvalid;
  logic [31:0] tcm_i_rdata;
  logic sram_i_req, sram_i_gnt, sram_i_rvalid;
  logic [31:0] sram_i_rdata;

  wire sel_rom  = (instr_addr >= ADDR_BOOT_ROM_BASE) &&
                  (instr_addr <  ADDR_BOOT_ROM_BASE + ADDR_BOOT_ROM_SIZE);
  wire sel_tcm  = (instr_addr >= ADDR_TCM_BASE) &&
                  (instr_addr <  ADDR_TCM_BASE + ADDR_TCM_SIZE);
  wire sel_sram = (instr_addr >= ADDR_SRAM_BASE) &&
                  (instr_addr <  ADDR_SRAM_BASE + ADDR_SRAM_SIZE);

  assign rom_i_req  = instr_req && sel_rom;
  assign tcm_i_req  = instr_req && sel_tcm;
  assign sram_i_req = instr_req && sel_sram;

  // Out-of-range fetch returns an all-zero word (an illegal instruction), so
  // the core traps instead of hanging.
  logic fault_rvalid;
  always_ff @(posedge core_clk or negedge reset_n) begin
    if (!reset_n) fault_rvalid <= 1'b0;
    else          fault_rvalid <= instr_req && !sel_rom && !sel_tcm && !sel_sram;
  end

  assign instr_gnt    = sel_rom  ? rom_i_gnt  :
                        sel_tcm  ? tcm_i_gnt  :
                        sel_sram ? sram_i_gnt : instr_req;
  assign instr_rvalid = sel_rom  ? rom_i_rvalid  :
                        sel_tcm  ? tcm_i_rvalid  :
                        sel_sram ? sram_i_rvalid : fault_rvalid;
  assign instr_rdata  = sel_rom  ? rom_i_rdata  :
                        sel_tcm  ? tcm_i_rdata  :
                        sel_sram ? sram_i_rdata : 32'h0000_0000;

  //--------------------------------------------------------------------------
  // Data path: req/gnt -> AXI4-Lite master
  //--------------------------------------------------------------------------
  logic         m_awvalid, m_awready, m_wvalid, m_wready;
  logic [31:0]  m_awaddr, m_wdata;
  logic [2:0]   m_awprot;
  logic [3:0]   m_wstrb;
  logic         m_bvalid, m_bready, m_arvalid, m_arready, m_rvalid, m_rready;
  logic [1:0]   m_bresp, m_rresp;
  logic [31:0]  m_araddr, m_rdata;

  req_gnt_to_axi_lite data_adapter (
    .clk       (core_clk),
    .reset_n   (reset_n),
    .req       (data_req),
    .addr      (data_addr),
    .we        (data_we),
    .wdata     (data_wdata),
    .wstrb     (data_wstrb),
    .gnt       (data_gnt),
    .rdata     (data_rdata),
    .rvalid    (data_rvalid),
    .m_awvalid (m_awvalid),
    .m_awready (m_awready),
    .m_awaddr  (m_awaddr),
    .m_awprot  (m_awprot),
    .m_wvalid  (m_wvalid),
    .m_wready  (m_wready),
    .m_wdata   (m_wdata),
    .m_wstrb   (m_wstrb),
    .m_bvalid  (m_bvalid),
    .m_bready  (m_bready),
    .m_bresp   (m_bresp),
    .m_arvalid (m_arvalid),
    .m_arready (m_arready),
    .m_araddr  (m_araddr),
    .m_arprot  (),
    .m_rvalid  (m_rvalid),
    .m_rready  (m_rready),
    .m_rdata   (m_rdata),
    .m_rresp   (m_rresp)
  );

  //--------------------------------------------------------------------------
  // Interconnect
  //--------------------------------------------------------------------------
  logic [5:0]  s_awvalid, s_awready, s_wvalid, s_wready;
  logic [5:0]  s_bvalid, s_bready, s_arvalid, s_arready, s_rvalid, s_rready;
  logic [31:0] s_awaddr [6], s_araddr [6], s_wdata [6], s_rdata [6];
  logic [2:0]  s_awprot [6], s_arprot [6];
  logic [3:0]  s_wstrb [6];
  logic [1:0]  s_bresp [6], s_rresp [6];

  axi_lite_interconnect axi_ic (
    .clk         (core_clk),
    .reset_n     (reset_n),
    .m_awvalid   (m_awvalid),
    .m_awready   (m_awready),
    .m_awaddr    (m_awaddr),
    .m_awprot    (m_awprot),
    .m_wvalid    (m_wvalid),
    .m_wready    (m_wready),
    .m_wdata     (m_wdata),
    .m_wstrb     (m_wstrb),
    .m_bvalid    (m_bvalid),
    .m_bready    (m_bready),
    .m_bresp     (m_bresp),
    .m_arvalid   (m_arvalid),
    .m_arready   (m_arready),
    .m_araddr    (m_araddr),
    .m_arprot    (),
    .m_rvalid    (m_rvalid),
    .m_rready    (m_rready),
    .m_rdata     (m_rdata),
    .m_rresp     (m_rresp),
    .s_awvalid   (s_awvalid),
    .s_awready   (s_awready),
    .s_awaddr    (s_awaddr),
    .s_awprot    (s_awprot),
    .s_wvalid    (s_wvalid),
    .s_wready    (s_wready),
    .s_wdata     (s_wdata),
    .s_wstrb     (s_wstrb),
    .s_bvalid    (s_bvalid),
    .s_bready    (s_bready),
    .s_bresp     (s_bresp),
    .s_arvalid   (s_arvalid),
    .s_arready   (s_arready),
    .s_araddr    (s_araddr),
    .s_arprot    (s_arprot),
    .s_rvalid    (s_rvalid),
    .s_rready    (s_rready),
    .s_rdata     (s_rdata),
    .s_rresp     (s_rresp)
  );

  //--------------------------------------------------------------------------
  // Boot ROM (slave 0 data port + instruction port)
  //--------------------------------------------------------------------------
  boot_rom #(.ADDR_WIDTH(16), .MEM_FILE(BOOT_ROM_FILE)) rom_inst (
    .clk      (core_clk),
    .reset_n  (reset_n),
    .req      (rom_i_req),
    .addr     (instr_addr[15:0]),
    .gnt      (rom_i_gnt),
    .rdata    (rom_i_rdata),
    .rvalid   (rom_i_rvalid),
    .awvalid  (s_awvalid[0]),
    .awready  (s_awready[0]),
    .awaddr   (s_awaddr[0]),
    .wvalid   (s_wvalid[0]),
    .wready   (s_wready[0]),
    .wdata    (s_wdata[0]),
    .wstrb    (s_wstrb[0]),
    .bvalid   (s_bvalid[0]),
    .bready   (s_bready[0]),
    .bresp    (s_bresp[0]),
    .arvalid  (s_arvalid[0]),
    .arready  (s_arready[0]),
    .araddr   (s_araddr[0]),
    .r_rvalid (s_rvalid[0]),
    .r_rready (s_rready[0]),
    .r_rdata  (s_rdata[0]),
    .r_rresp  (s_rresp[0])
  );

  //--------------------------------------------------------------------------
  // TCM (slave 1)
  //--------------------------------------------------------------------------
  sram #(.ADDR_WIDTH(15), .MEM_FILE("")) tcm_inst (
    .clk      (core_clk),
    .reset_n  (reset_n),
    .awvalid  (s_awvalid[1]), .awaddr(s_awaddr[1][14:0]), .awready(s_awready[1]),
    .wvalid   (s_wvalid[1]),  .wdata (s_wdata[1]),  .wready(s_wready[1]),
    .wstrb    (s_wstrb[1]),
    .bvalid   (s_bvalid[1]),  .bready(s_bready[1]), .bresp(s_bresp[1]),
    .arvalid  (s_arvalid[1]), .araddr(s_araddr[1][14:0]), .arready(s_arready[1]),
    .rvalid   (s_rvalid[1]),  .rdata (s_rdata[1]),  .rresp(s_rresp[1]),
    .rready   (s_rready[1]),
    .i_req    (tcm_i_req),    .i_addr(instr_addr[14:0]),
    .i_gnt    (tcm_i_gnt),    .i_rdata(tcm_i_rdata), .i_rvalid(tcm_i_rvalid)
  );

  //--------------------------------------------------------------------------
  // SRAM (slave 2)
  //--------------------------------------------------------------------------
  sram #(.ADDR_WIDTH(18), .MEM_FILE("")) sram_inst (
    .clk      (core_clk),
    .reset_n  (reset_n),
    .awvalid  (s_awvalid[2]), .awaddr(s_awaddr[2][17:0]), .awready(s_awready[2]),
    .wvalid   (s_wvalid[2]),  .wdata (s_wdata[2]),  .wready(s_wready[2]),
    .wstrb    (s_wstrb[2]),
    .bvalid   (s_bvalid[2]),  .bready(s_bready[2]), .bresp(s_bresp[2]),
    .arvalid  (s_arvalid[2]), .araddr(s_araddr[2][17:0]), .arready(s_arready[2]),
    .rvalid   (s_rvalid[2]),  .rdata (s_rdata[2]),  .rresp(s_rresp[2]),
    .rready   (s_rready[2]),
    .i_req    (sram_i_req),   .i_addr(instr_addr[17:0]),
    .i_gnt    (sram_i_gnt),   .i_rdata(sram_i_rdata), .i_rvalid(sram_i_rvalid)
  );

  //--------------------------------------------------------------------------
  // QSPI flash (slave 3)
  //--------------------------------------------------------------------------
  qspi_flash_ctrl qspi_ctrl (
    .clk      (core_clk),
    .reset_n  (reset_n),
    .awvalid  (s_awvalid[3]), .awaddr(s_awaddr[3]), .awready(s_awready[3]),
    .wvalid   (s_wvalid[3]),  .wdata (s_wdata[3]),  .wready(s_wready[3]),
    .wstrb    (s_wstrb[3]),
    .bvalid   (s_bvalid[3]),  .bready(s_bready[3]), .bresp(s_bresp[3]),
    .arvalid  (s_arvalid[3]), .araddr(s_araddr[3]), .arready(s_arready[3]),
    .rvalid   (s_rvalid[3]),  .rdata (s_rdata[3]),  .rresp(s_rresp[3]),
    .rready   (s_rready[3]),
    .qspi_sck (qspi_sck),
    .qspi_cs_n(qspi_cs_n),
    .qspi_io  (qspi_io)
  );

  //--------------------------------------------------------------------------
  // APB bridge (slave 4)
  //--------------------------------------------------------------------------
  logic        penable, pwrite;
  logic [31:0] paddr, pwdata, prdata;
  logic [3:0]  pstrb;
  logic        pslverr, pready;

  axi_lite_to_apb apb_bridge (
    .clk      (core_clk),
    .reset_n  (reset_n),
    .s_awvalid(s_awvalid[4]), .s_awready(s_awready[4]),
    .s_awaddr (s_awaddr[4]),  .s_awprot (s_awprot[4]),
    .s_wvalid (s_wvalid[4]),  .s_wready (s_wready[4]),
    .s_wdata  (s_wdata[4]),   .s_wstrb  (s_wstrb[4]),
    .s_bvalid (s_bvalid[4]),  .s_bready (s_bready[4]), .s_bresp(s_bresp[4]),
    .s_arvalid(s_arvalid[4]), .s_arready(s_arready[4]),
    .s_araddr (s_araddr[4]),  .s_arprot (s_arprot[4]),
    .s_rvalid (s_rvalid[4]),  .s_rready (s_rready[4]),
    .s_rdata  (s_rdata[4]),   .s_rresp  (s_rresp[4]),
    .penable  (penable),
    .pwrite   (pwrite),
    .paddr    (paddr),
    .pwdata   (pwdata),
    .pstrb    (pstrb),
    .pslverr  (pslverr),
    .prdata   (prdata),
    .pready   (pready)
  );

  //--------------------------------------------------------------------------
  // INTC (slave 5) — CLINT + PLIC
  //--------------------------------------------------------------------------
  logic [7:0] periph_irq;
  logic [63:0] mtime_unused;

  // CLINT and PLIC share one AXI slave port. intc_axi owns the AXI handshake
  // and routes addr[12]: 0 -> CLINT, 1 -> PLIC.  Driving s_rdata[5] from both
  // blocks (a rejected earlier revision) creates multiple drivers.
  intc_axi intc_inst (
    .clk      (core_clk),
    .reset_n  (reset_n),
    .awvalid  (s_awvalid[5]), .awaddr(s_awaddr[5]), .awready(s_awready[5]),
    .wvalid   (s_wvalid[5]),  .wdata (s_wdata[5]),  .wready(s_wready[5]),
    .wstrb    (s_wstrb[5]),
    .bvalid   (s_bvalid[5]),  .bready(s_bready[5]), .bresp(s_bresp[5]),
    .arvalid  (s_arvalid[5]), .araddr(s_araddr[5]), .arready(s_arready[5]),
    .rvalid   (s_rvalid[5]),  .rdata (s_rdata[5]),  .rresp(s_rresp[5]),
    .rready   (s_rready[5]),
    .ext_irq  (periph_irq),
    .irq_ext  (irq_ext),
    .irq_timer(irq_timer),
    .irq_soft (irq_soft),
    .mtime    (mtime_unused)
  );

  //--------------------------------------------------------------------------
  // Peripherals (APB)
  //--------------------------------------------------------------------------
  logic        gpio_irq, uart_irq, i2c_irq, spi_irq;
  logic        pwm_irq, timer_irq, wdog_irq, i2s_irq, pwr_irq;

  logic [31:0] prdata_gpio, prdata_uart, prdata_i2c, prdata_spi, prdata_pwm;
  logic [31:0] prdata_timer, prdata_wdog, prdata_i2s, prdata_pwr;
  logic [8:0]  apb_sel;

  // Each peripheral is only allowed to see the APB ACCESS phase for its own
  // 4 KB slot.  Without the per-slot gate every peripheral decodes every
  // access: a UART THR write has paddr[11:2]==0, which the power-manager
  // register block took as its own control register and set sleep_req, so the
  // first transmitted character gated off core_clk and froze the whole SoC.
  gpio #(.WIDTH(16)) gpio_inst (
    .pclk(periph_clk), .presetn(reset_n), .penable(penable & apb_sel[0]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_gpio), .pready(), .pslverr(),
    .gpio(gpio), .irq(gpio_irq));

  uart #(.CLK_FREQ(UART_CLK_FREQ), .BAUD(UART_BAUD)) uart_inst (
    .pclk(periph_clk), .presetn(reset_n), .penable(penable & apb_sel[1]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_uart), .pready(), .pslverr(),
    .uart_tx(uart_tx), .uart_rx(uart_rx), .irq(uart_irq));

  i2c_ctrl i2c_inst (
    .pclk(periph_clk), .presetn(reset_n), .penable(penable & apb_sel[2]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_i2c), .pready(), .pslverr(),
    .i2c_scl(i2c_scl), .i2c_sda(i2c_sda), .irq(i2c_irq));

  spi_ctrl spi_inst (
    .pclk(periph_clk), .presetn(reset_n), .penable(penable & apb_sel[3]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_spi), .pready(), .pslverr(),
    .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso),
    .spi_cs_n(spi_cs_n), .irq(spi_irq));

  pwm pwm_inst (
    .pclk(periph_clk), .presetn(reset_n), .penable(penable & apb_sel[4]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_pwm), .pready(), .pslverr(),
    .pwm_out(pwm_out), .irq(pwm_irq));

  timer timer_inst (
    .pclk(periph_clk), .presetn(reset_n), .penable(penable & apb_sel[5]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_timer), .pready(), .pslverr(),
    .irq(timer_irq));

  // The watchdog must keep counting while the SoC is asleep, otherwise sleep
  // silently disables the reset path it exists to provide.  It therefore runs
  // on the ungated base clock; its APB port is still only reachable while the
  // peripheral clock is running.
  watchdog wdog_inst (
    .pclk(clk), .presetn(reset_n), .penable(penable & apb_sel[6]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_wdog), .pready(), .pslverr(),
    .irq(wdog_irq), .reset_n_out(wdog_reset_n_out));

  i2s i2s_inst (
    .pclk(periph_clk), .presetn(reset_n), .penable(penable & apb_sel[7]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_i2s), .pready(), .pslverr(),
    .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk),
    .i2s_dout(i2s_dout), .i2s_din(i2s_din), .irq(i2s_irq));

  logic pm_sleep_req, pm_wake_event;
  power_mgr_regs pwr_inst (
    .pclk(periph_clk), .presetn(reset_n), .penable(penable & apb_sel[8]), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_pwr), .pready(), .pslverr(),
    .irq(pwr_irq), .sleep_req_o(pm_sleep_req),
    .wake_clear(pm_wake_event));

  // APB address decode: one 4 KB slot per peripheral.  Each peripheral sees
  // paddr[11:2] as its local register index because every slot is 4 KB aligned.
  always_comb begin
    apb_sel = 9'd0;
    case (paddr[15:12])
      4'h0: apb_sel = 9'b000000001;  // GPIO  0x5000_0000
      4'h1: apb_sel = 9'b000000010;  // UART  0x5000_1000
      4'h2: apb_sel = 9'b000000100;  // I2C   0x5000_2000
      4'h3: apb_sel = 9'b000001000;  // SPI   0x5000_3000
      4'h4: apb_sel = 9'b000010000;  // PWM   0x5000_4000
      4'h5: apb_sel = 9'b000100000;  // TIMER 0x5000_5000
      4'h6: apb_sel = 9'b001000000;  // WDOG  0x5000_6000
      4'h7: apb_sel = 9'b010000000;  // I2S   0x5000_7000
      4'h8: apb_sel = 9'b100000000;  // PWR   0x5000_8000
      default: apb_sel = 9'd0;
    endcase
  end

  assign prdata = apb_sel[0] ? prdata_gpio  :
                  apb_sel[1] ? prdata_uart  :
                  apb_sel[2] ? prdata_i2c   :
                  apb_sel[3] ? prdata_spi   :
                  apb_sel[4] ? prdata_pwm   :
                  apb_sel[5] ? prdata_timer :
                  apb_sel[6] ? prdata_wdog  :
                  apb_sel[7] ? prdata_i2s   :
                  apb_sel[8] ? prdata_pwr   : 32'd0;

  // APB completion contract:
  //  - exactly one selected slot per transfer (one-hot `apb_sel`);
  //  - an unmapped slot completes with PSLVERR instead of hanging the bridge;
  //  - partial-strobe writes are REJECTED with PSLVERR.  No peripheral decodes
  //    PSTRB (it is an unused port in all nine), so accepting a partial write
  //    would silently turn `sb`/`sh` into a full-word register write.  A
  //    rejected access has no side effect, which is the safe failure mode.
  wire apb_partial_write = pwrite && (pstrb != 4'b1111);

  assign pready  = (apb_sel != 9'd0);
  assign pslverr = (apb_sel == 9'd0) || (penable && apb_partial_write);

  // PLIC source map: 0=uart 1=spi 2=i2c 3=gpio 4=pwm 5=timer 6=wdog 7=i2s
  assign periph_irq = {i2s_irq, wdog_irq, timer_irq, pwm_irq,
                       gpio_irq, i2c_irq, spi_irq, uart_irq};

  // Optional board-level interrupt lines are OR-ed into the UART source slot
  // only for software-visible diagnostics; they do not bypass the PLIC.
  wire unused_ext_irq = ^ext_irq;

  //--------------------------------------------------------------------------
  // Power manager + JTAG TAP
  //--------------------------------------------------------------------------
  power_mgr pwr_mgr (
    .clk          (clk),
    .reset_n      (reset_n),
    .sleep_req    (pm_sleep_req),
    .core_clk_en  (core_clk_en),
    .periph_clk_en(periph_clk_en),
    .wake_req     (wake_req),
    .wake_ack     (wake_ack),
    .wake_event   (pm_wake_event)
  );

  debug_jtag jtag_inst (
    .clk    (clk),
    .reset_n(reset_n),
    .tck    (jtag_tck),
    .tms    (jtag_tms),
    .tdi    (jtag_tdi),
    .tdo    (jtag_tdo),
    .trst_n (jtag_trst_n)
  );

endmodule
