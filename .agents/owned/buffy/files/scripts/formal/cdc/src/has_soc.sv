//------------------------------------------------------------------------------
// Home-Automation-SoC — Top-Level System-on-Chip
// Stage 2 RTL
//
// Integrates:
//   - RISC-V RV32IMC core (req/gnt native instruction & data interfaces)
//   - req/gnt -> AXI4-Lite adapter (data path) -> AXI4-Lite interconnect
//   - Boot ROM, TCM, SRAM, QSPI flash, APB bridge, INTC (CLINT+PLIC)
//   - Clock gating, power management, JTAG debug
//
// Memory map (has_addr_map_pkg):
//   0x0000_0000 Boot ROM (16 KB)
//   0x0001_0000 TCM      (32 KB)
//   0x2000_0000 SRAM     (128 KB)
//   0x4000_0000 QSPI Flash (64 MB)
//   0x5000_0000 APB peripherals (1 MB)
//   0x8000_0000 PLIC/CLINT (64 KB)
//------------------------------------------------------------------------------
module has_soc #(
  parameter BOOT_ROM_FILE = ""
) (
  input  logic         clk,
  input  logic         reset_n,
  input  logic         jtag_tck,
  input  logic         jtag_tms,
  input  logic         jtag_tdi,
  output logic         jtag_tdo,
  input  logic         jtag_trst_n,
  input  logic [31:0]  ext_irq,
  output logic         uart_tx,
  input  logic         uart_rx,
  output logic         spi_sck,
  output logic         spi_mosi,
  input  logic         spi_miso,
  output logic         spi_cs_n,
  inout  wire          i2c_scl,
  inout  wire          i2c_sda,
  inout  wire [15:0]   gpio,
  output logic [3:0]   pwm_out,
  output logic         i2s_bclk,
  output logic         i2s_lrclk,
  output logic         i2s_dout,
  input  logic         i2s_din,
  output logic         qspi_sck,
  output logic         qspi_cs_n,
  inout  wire [3:0]    qspi_io,
  output logic         wdog_reset_n_out,
  output logic         wake_req,
  input  logic         wake_ack
);

  import has_addr_map_pkg::*;

  //----------------------------- Clocks & resets -----------------------------
  logic core_clk, periph_clk;
  logic core_clk_en, periph_clk_en;
  assign core_clk  = clk & core_clk_en;
  assign periph_clk= clk & periph_clk_en;

  //----------------------------- Core interfaces -----------------------------
  logic         instr_req, instr_gnt, instr_rvalid;
  logic [31:0]  instr_addr, instr_rdata;
  logic         instr_to_rom;
  logic         data_req, data_we, data_gnt, data_rvalid;
  logic [31:0]  data_addr, data_wdata, data_rdata;
  logic [3:0]   data_wstrb;

  logic         core_irq_ext, core_irq_timer, core_irq_soft;
  logic         debug_running_unused;

  //----------------------------- AXI4-Lite master (data path) ----------------
  logic         m_awvalid, m_awready;
  logic [31:0]  m_awaddr;
  logic [2:0]   m_awprot;
  logic         m_wvalid, m_wready;
  logic [31:0]  m_wdata;
  logic [3:0]   m_wstrb;
  logic         m_bvalid, m_bready;
  logic [1:0]   m_bresp;
  logic         m_arvalid, m_arready;
  logic [31:0]  m_araddr;
  logic [2:0]   m_arprot;
  logic         m_rvalid, m_rready;
  logic [31:0]  m_rdata;
  logic [1:0]   m_rresp;

  //----------------------------- Interconnect slave busses -------------------
  logic [5:0]   s_awvalid, s_awready, s_wvalid, s_wready;
  logic [5:0]   s_bvalid, s_bready, s_arvalid, s_arready, s_rvalid, s_rready;
  logic [31:0]  s_awaddr  [5:0], s_araddr  [5:0];
  logic [2:0]   s_awprot  [5:0], s_arprot  [5:0];
  logic [31:0]  s_wdata   [5:0], s_rdata   [5:0];
  logic [3:0]   s_wstrb   [5:0];
  logic [1:0]   s_bresp   [5:0], s_rresp   [5:0];

  //----------------------------- Per-instance slave signals ------------------
  // 0 Boot ROM, 1 TCM, 2 SRAM, 3 QSPI, 4 APB, 5 INTC
  logic [31:0]  rom_araddr, rom_rdata;
  logic         rom_arvalid, rom_arready, rom_rvalid, rom_rready;
  logic         tcm_awvalid, tcm_awready;
  logic [31:0]  tcm_awaddr;
  logic [2:0]   tcm_awprot;
  logic         tcm_wvalid, tcm_wready;
  logic [31:0]  tcm_wdata;
  logic [3:0]   tcm_wstrb;
  logic         tcm_bvalid, tcm_bready;
  logic [1:0]   tcm_bresp;
  logic         tcm_arvalid, tcm_arready;
  logic [31:0]  tcm_araddr;
  logic [2:0]   tcm_arprot;
  logic         tcm_rvalid, tcm_rready;
  logic [31:0]  tcm_rdata;
  logic [1:0]   tcm_rresp;
  logic         sram_awvalid, sram_awready;
  logic [31:0]  sram_awaddr;
  logic [2:0]   sram_awprot;
  logic         sram_wvalid, sram_wready;
  logic [31:0]  sram_wdata;
  logic [3:0]   sram_wstrb;
  logic         sram_bvalid, sram_bready;
  logic [1:0]   sram_bresp;
  logic         sram_arvalid, sram_arready;
  logic [31:0]  sram_araddr;
  logic [2:0]   sram_arprot;
  logic         sram_rvalid, sram_rready;
  logic [31:0]  sram_rdata;
  logic [1:0]   sram_rresp;
  logic         qspi_awvalid, qspi_awready;
  logic [31:0]  qspi_awaddr;
  logic [2:0]   qspi_awprot;
  logic         qspi_wvalid, qspi_wready;
  logic [31:0]  qspi_wdata;
  logic [3:0]   qspi_wstrb;
  logic         qspi_bvalid, qspi_bready;
  logic [1:0]   qspi_bresp;
  logic         qspi_arvalid, qspi_arready;
  logic [31:0]  qspi_araddr;
  logic [2:0]   qspi_arprot;
  logic         qspi_rvalid, qspi_rready;
  logic [31:0]  qspi_rdata;
  logic [1:0]   qspi_rresp;
  logic         apb_awvalid, apb_awready;
  logic [31:0]  apb_awaddr;
  logic [2:0]   apb_awprot;
  logic         apb_wvalid, apb_wready;
  logic [31:0]  apb_wdata;
  logic [3:0]   apb_wstrb;
  logic         apb_bvalid, apb_bready;
  logic [1:0]   apb_bresp;
  logic         apb_arvalid, apb_arready;
  logic [31:0]  apb_araddr;
  logic [2:0]   apb_arprot;
  logic         apb_rvalid, apb_rready;
  logic [31:0]  apb_rdata;
  logic [1:0]   apb_rresp;
  logic         intc_awvalid, intc_awready;
  logic [31:0]  intc_awaddr;
  logic [2:0]   intc_awprot;
  logic         intc_wvalid, intc_wready;
  logic [31:0]  intc_wdata;
  logic [3:0]   intc_wstrb;
  logic         intc_bvalid, intc_bready;
  logic [1:0]   intc_bresp;
  logic         intc_arvalid, intc_arready;
  logic [31:0]  intc_araddr;
  logic [2:0]   intc_arprot;
  logic         intc_rvalid, intc_rready;
  logic [31:0]  intc_rdata;
  logic [1:0]   intc_rresp;

  //----------------------------- APB -----------------------------------------
  logic         pclk, presetn, penable, pwrite;
  logic [31:0]  paddr, pwdata;
  logic [3:0]   pstrb;
  logic         pslverr;
  logic [31:0]  prdata;
  logic         pready;

  logic [31:0]  prdata_gpio, prdata_uart, prdata_i2c, prdata_spi, prdata_pwm;
  logic [31:0]  prdata_timer, prdata_wdog, prdata_i2s, prdata_pwrmgr;
  logic         pready_gpio, pready_uart, pready_i2c, pready_spi, pready_pwm;
  logic         pready_timer, pready_wdog, pready_i2s, pready_pwrmgr;
  logic         pslverr_gpio, pslverr_uart, pslverr_i2c, pslverr_spi, pslverr_pwm;
  logic         pslverr_timer, pslverr_wdog, pslverr_i2s, pslverr_pwrmgr;
  logic         gpio_irq, uart_irq, i2c_irq, spi_irq, pwm_irq, timer_irq, wdog_irq, pwrmgr_irq, i2s_irq;

  //----------------------------- Interrupts ----------------------------------
  logic [31:0] periph_irq;
  assign periph_irq = {16'd0, uart_irq, spi_irq, i2c_irq, gpio_irq, pwm_irq, timer_irq, wdog_irq};

  //----------------------------- Power manager -------------------------------
  power_mgr pwr_mgr (
    .clk         (clk),
    .reset_n     (reset_n),
    .core_clk_en (core_clk_en),
    .periph_clk_en(periph_clk_en),
    .wake_req    (wake_req),
    .wake_ack    (wake_ack)
  );

  //----------------------------- RISC-V core ---------------------------------
  riscv_core #(.RESET_PC(32'h0000_0000)) core (
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
    .irq_irq      (core_irq_ext),
    .irq_timer    (core_irq_timer),
    .irq_soft     (core_irq_soft),
    .debug_req    (1'b0),
    .debug_halted (),
    .debug_running(debug_running_unused)
  );

  //----------------------------- req/gnt -> AXI adapter (data path) ----------
  req_gnt_to_axi_lite data_adapter (
    .clk        (core_clk),
    .reset_n    (reset_n),
    .req        (data_req),
    .addr       (data_addr),
    .we         (data_we),
    .wdata      (data_wdata),
    .wstrb      (data_wstrb),
    .gnt        (data_gnt),
    .rdata      (data_rdata),
    .rvalid     (data_rvalid),
    .m_awvalid  (m_awvalid),
    .m_awready  (m_awready),
    .m_awaddr   (m_awaddr),
    .m_awprot   (m_awprot),
    .m_wvalid   (m_wvalid),
    .m_wready   (m_wready),
    .m_wdata    (m_wdata),
    .m_wstrb    (m_wstrb),
    .m_bvalid   (m_bvalid),
    .m_bready   (m_bready),
    .m_bresp    (m_bresp),
    .m_arvalid  (m_arvalid),
    .m_arready  (m_arready),
    .m_araddr   (m_araddr),
    .m_arprot   (m_arprot),
    .m_rvalid   (m_rvalid),
    .m_rready   (m_rready),
    .m_rdata    (m_rdata),
    .m_rresp    (m_rresp)
  );

  //----------------------------- Instruction path: core -> Boot ROM ----------
  // Instruction fetches go directly to the Boot ROM (read-only), bypassing the
  // AXI interconnect. TCM and data accesses use the data_adapter + interconnect.
  assign instr_to_rom = (instr_addr >= ADDR_BOOT_ROM_BASE &&
                         instr_addr <  ADDR_BOOT_ROM_BASE + ADDR_BOOT_ROM_SIZE);

  boot_rom #(.ADDR_WIDTH(16), .DATA_WIDTH(32), .MEM_FILE(BOOT_ROM_FILE)) rom_inst (
    .clk     (core_clk),
    .reset_n (reset_n),
    .req     (instr_req && instr_to_rom),
    .addr    (instr_addr[15:0]),
    .gnt     (instr_gnt),
    .rdata   (instr_rdata),
    .rvalid  (instr_rvalid)
  );

  //----------------------------- Interconnect --------------------------------
  axi_lite_interconnect axi_ic (
    .clk        (core_clk),
    .reset_n    (reset_n),
    .m_awvalid  (m_awvalid),
    .m_awready  (m_awready),
    .m_awaddr   (m_awaddr),
    .m_awprot   (m_awprot),
    .m_wvalid   (m_wvalid),
    .m_wready   (m_wready),
    .m_wdata    (m_wdata),
    .m_wstrb    (m_wstrb),
    .m_bvalid   (m_bvalid),
    .m_bready   (m_bready),
    .m_bresp    (m_bresp),
    .m_arvalid  (m_arvalid),
    .m_arready  (m_arready),
    .m_araddr   (m_araddr),
    .m_arprot   (m_arprot),
    .m_rvalid   (m_rvalid),
    .m_rready   (m_rready),
    .m_rdata    (m_rdata),
    .m_rresp    (m_rresp),
    .s_awvalid  (s_awvalid),
    .s_awready  (s_awready),
    .s_awaddr   (s_awaddr),
    .s_awprot   (s_awprot),
    .s_wvalid   (s_wvalid),
    .s_wready   (s_wready),
    .s_wdata    (s_wdata),
    .s_wstrb    (s_wstrb),
    .s_bvalid   (s_bvalid),
    .s_bready   (s_bready),
    .s_bresp    (s_bresp),
    .s_arvalid  (s_arvalid),
    .s_arready  (s_arready),
    .s_araddr   (s_araddr),
    .s_arprot   (s_arprot),
    .s_rvalid   (s_rvalid),
    .s_rready   (s_rready),
    .s_rdata    (s_rdata),
    .s_rresp    (s_rresp)
  );

  //----------------------------- Slave 0 (unused - ROM on instr path) --------
  assign s_awready[0] = 1'b1;
  assign s_wready[0]  = 1'b1;
  assign s_bvalid[0]  = 1'b0;
  assign s_bresp[0]   = 2'b00;
  assign s_arready[0] = 1'b0;
  assign s_rvalid[0]  = 1'b0;
  assign s_rdata[0]   = 32'd0;
  assign s_rresp[0]   = 2'b00;

  //----------------------------- TCM (slave 1) -------------------------------
  sram #(.ADDR_WIDTH(15), .DATA_WIDTH(32), .MEM_FILE("")) tcm_inst (
    .clk     (core_clk),
    .reset_n (reset_n),
    .awvalid (s_awvalid[1]), .awaddr (s_awaddr[1][14:0]), .awready(s_awready[1]),
    .wvalid  (s_wvalid[1]),  .wdata  (s_wdata[1]),  .wready (s_wready[1]),
    .wstrb   (s_wstrb[1]),
    .bvalid  (s_bvalid[1]),  .bready (s_bready[1]), .bresp  (s_bresp[1]),
    .arvalid (s_arvalid[1]), .araddr (s_araddr[1][14:0]), .arready(s_arready[1]),
    .rvalid  (s_rvalid[1]),  .rdata  (s_rdata[1]),  .rresp  (s_rresp[1]),
    .rready  (s_rready[1])
  );

  //----------------------------- SRAM (slave 2) ------------------------------
  sram #(.ADDR_WIDTH(18), .DATA_WIDTH(32), .MEM_FILE("")) sram_inst (
    .clk     (core_clk),
    .reset_n (reset_n),
    .awvalid (s_awvalid[2]), .awaddr (s_awaddr[2][17:0]), .awready(s_awready[2]),
    .wvalid  (s_wvalid[2]),  .wdata  (s_wdata[2]),  .wready (s_wready[2]),
    .wstrb   (s_wstrb[2]),
    .bvalid  (s_bvalid[2]),  .bready (s_bready[2]), .bresp  (s_bresp[2]),
    .arvalid (s_arvalid[2]), .araddr (s_araddr[2][17:0]), .arready(s_arready[2]),
    .rvalid  (s_rvalid[2]),  .rdata  (s_rdata[2]),  .rresp  (s_rresp[2]),
    .rready  (s_rready[2])
  );

  //----------------------------- QSPI flash (slave 3) ------------------------
  qspi_flash_ctrl qspi_ctrl (
    .clk       (core_clk),
    .reset_n   (reset_n),
    .awvalid   (s_awvalid[3]), .awaddr (s_awaddr[3]),  .awready(s_awready[3]),
    .wvalid    (s_wvalid[3]),  .wdata  (s_wdata[3]),  .wready (s_wready[3]),
    .wstrb     (s_wstrb[3]),
    .bvalid    (s_bvalid[3]),  .bready (s_bready[3]), .bresp  (s_bresp[3]),
    .arvalid   (s_arvalid[3]), .araddr (s_araddr[3]),  .arready(s_arready[3]),
    .rvalid    (s_rvalid[3]),  .rdata  (s_rdata[3]),  .rresp  (s_rresp[3]),
    .rready    (s_rready[3]),
    .qspi_sck  (qspi_sck),
    .qspi_cs_n (qspi_cs_n),
    .qspi_io   (qspi_io)
  );

  //----------------------------- APB bridge (slave 4) ------------------------
  axi_lite_to_apb apb_bridge (
    .clk       (periph_clk),
    .reset_n   (reset_n),
    .s_awvalid (s_awvalid[4]), .s_awready(s_awready[4]), .s_awaddr(s_awaddr[4]), .s_awprot(s_awprot[4]),
    .s_wvalid  (s_wvalid[4]),  .s_wready(s_wready[4]),  .s_wdata(s_wdata[4]),  .s_wstrb(s_wstrb[4]),
    .s_bvalid  (s_bvalid[4]),  .s_bready(s_bready[4]),  .s_bresp(s_bresp[4]),
    .s_arvalid (s_arvalid[4]), .s_arready(s_arready[4]), .s_araddr(s_araddr[4]), .s_arprot(s_arprot[4]),
    .s_rvalid  (s_rvalid[4]),  .s_rready(s_rready[4]),  .s_rdata(s_rdata[4]),  .s_rresp(s_rresp[4]),
    .pclk      (pclk), .presetn(presetn),
    .penable   (penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .pslverr   (pslverr), .prdata(prdata), .pready(pready)
  );
  assign pclk   = periph_clk;
  assign presetn = reset_n;

  //----------------------------- INTC: CLINT + PLIC (slave 5) ----------------
  logic [63:0] clint_time;
  logic        clint_awvalid, clint_arvalid;
  logic        plic_awvalid, plic_arvalid;

  assign clint_awvalid = s_awvalid[5] && s_awaddr[5][12] == 1'b0;
  assign clint_arvalid = s_arvalid[5] && s_araddr[5][12] == 1'b0;
  assign plic_awvalid  = s_awvalid[5] && s_awaddr[5][12] == 1'b1;
  assign plic_arvalid  = s_arvalid[5] && s_araddr[5][12] == 1'b1;

  clint clint_inst (
    .clk        (core_clk),
    .reset_n    (reset_n),
    .awvalid    (clint_awvalid),
    .awaddr     (s_awaddr[5][11:0]),
    .awready    (s_awready[5]),
    .wvalid     (s_wvalid[5]),
    .wready     (s_wready[5]),
    .wdata      (s_wdata[5]),
    .wstrb      (s_wstrb[5]),
    .bvalid     (s_bvalid[5]),
    .bready     (s_bready[5]),
    .bresp      (s_bresp[5]),
    .arvalid    (clint_arvalid),
    .araddr     (s_araddr[5][11:0]),
    .arready    (s_arready[5]),
    .rvalid     (s_rvalid[5]),
    .rready     (s_rready[5]),
    .rdata      (s_rdata[5]),
    .rresp      (s_rresp[5]),
    .irq_soft   (core_irq_soft),
    .irq_timer  (core_irq_timer),
    .time_out   (clint_time)
  );

  plic plic_inst (
    .clk        (periph_clk),
    .reset_n    (reset_n),
    .awvalid    (plic_awvalid),
    .awaddr     (s_awaddr[5][15:0]),
    .awready    (s_awready[5]),
    .wvalid     (s_wvalid[5]),
    .wready     (s_wready[5]),
    .wdata      (s_wdata[5]),
    .wstrb      (s_wstrb[5]),
    .bvalid     (s_bvalid[5]),
    .bready     (s_bready[5]),
    .bresp      (s_bresp[5]),
    .arvalid    (plic_arvalid),
    .araddr     (s_araddr[5][15:0]),
    .arready    (s_arready[5]),
    .rvalid     (s_rvalid[5]),
    .rready     (s_rready[5]),
    .rdata      (s_rdata[5]),
    .rresp      (s_rresp[5]),
    .ext_irq    (periph_irq),
    .irq_out    (core_irq_ext)
  );

  //----------------------------- Peripherals (APB slaves) --------------------
  gpio  #(.WIDTH(16)) gpio_inst  (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_gpio), .pready(pready_gpio), .pslverr(pslverr_gpio),
    .gpio(gpio), .irq(gpio_irq));
  uart  uart_inst  (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_uart), .pready(pready_uart), .pslverr(pslverr_uart),
    .uart_tx(uart_tx), .uart_rx(uart_rx), .irq(uart_irq));
  i2c_ctrl i2c_inst (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_i2c), .pready(pready_i2c), .pslverr(pslverr_i2c),
    .i2c_scl(i2c_scl), .i2c_sda(i2c_sda), .irq(i2c_irq));
  spi_ctrl spi_inst (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_spi), .pready(pready_spi), .pslverr(pslverr_spi),
    .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_miso(spi_miso), .spi_cs_n(spi_cs_n),
    .irq(spi_irq));
  pwm   pwm_inst   (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_pwm), .pready(pready_pwm), .pslverr(pslverr_pwm),
    .pwm_out(pwm_out), .irq(pwm_irq));
  timer timer_inst (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_timer), .pready(pready_timer), .pslverr(pslverr_timer),
    .irq(timer_irq));
  watchdog wdog_inst (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_wdog), .pready(pready_wdog), .pslverr(pslverr_wdog),
    .irq(wdog_irq), .reset_n_out(wdog_reset_n_out));
  i2s   i2s_inst   (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_i2s), .pready(pready_i2s), .pslverr(pslverr_i2s),
    .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk), .i2s_dout(i2s_dout), .i2s_din(i2s_din),
    .irq(i2s_irq));
  power_mgr_regs pwrmgr_inst (
    .pclk(pclk), .presetn(presetn), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata), .pstrb(pstrb),
    .prdata(prdata_pwrmgr), .pready(pready_pwrmgr), .pslverr(pslverr_pwrmgr),
    .irq(pwrmgr_irq));

  // APB mux
  logic [9:0] apb_sel;
  always_comb begin
    apb_sel = 10'd0;
    unique case (paddr[11:2])
      10'd0:    apb_sel = 10'b00_0000_0001;  // GPIO  0x000
      10'd256:  apb_sel = 10'b00_0000_0010;  // UART  0x100
      10'd512:  apb_sel = 10'b00_0000_0100;  // I2C   0x200
      10'd768:  apb_sel = 10'b00_0000_1000;  // SPI   0x300
      10'd1024: apb_sel = 10'b00_0001_0000;  // PWM   0x400
      10'd1280: apb_sel = 10'b00_0010_0000;  // Timer 0x500
      10'd1536: apb_sel = 10'b00_0100_0000;  // Wdog  0x600
      10'd1792: apb_sel = 10'b00_1000_0000;  // I2S   0x700
      10'd2048: apb_sel = 10'b01_0000_0000;  // Pwr   0x800
      default:  apb_sel = 10'd0;
    endcase
  end
  assign prdata = apb_sel[0] ? prdata_gpio  : apb_sel[1] ? prdata_uart  :
                  apb_sel[2] ? prdata_i2c   : apb_sel[3] ? prdata_spi   :
                  apb_sel[4] ? prdata_pwm   : apb_sel[5] ? prdata_timer :
                  apb_sel[6] ? prdata_wdog  : apb_sel[7] ? prdata_i2s   :
                  apb_sel[8] ? prdata_pwrmgr : 32'd0;
  assign pready = |apb_sel;
  assign pslverr = 1'b0;

  //----------------------------- JTAG debug ----------------------------------
  debug_jtag jtag_inst (
    .clk      (clk),
    .reset_n  (reset_n),
    .tck      (jtag_tck),
    .tms      (jtag_tms),
    .tdi      (jtag_tdi),
    .tdo      (jtag_tdo),
    .trst_n   (jtag_trst_n)
  );

endmodule
