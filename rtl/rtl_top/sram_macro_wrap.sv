//------------------------------------------------------------------------------
// Home-Automation-SoC — SRAM macro wrapper (128 KiB)
// Phase 5.3A
//
// Replaces the behavioural `sram` blackbox at `sram_inst` with real Sky130 SRAM macros
// behind an identical external interface. The SoC sees the same AXI4-Lite W/R + instruction
// port; only the implementation changes. External interface (port names, widths, address
// trimming in has_soc.sv) is preserved exactly — no SoC-level RTL change except swapping the
// module implementation.
//
// REAL MACRO SOURCES (this machine, volare PDK, sky130A libs.ref/sky130_sram_macros/):
//   sky130_sram_2kbyte_1rw1r_32x512_8   — memory(9,32) → 512 words × 32 bits
//                                        = 16384 bits = 2 KiB per macro, 2-port (RW + R)
//                                        vccd1/vssd1 power. Verilog model:
//                                          libs.ref/sky130_sram_macros/verilog/sky130_sram_2kbyte_1rw1r_32x512_8.v
//   sky130_sram_1kbyte_1rw1r_32x256_8   — memory(8,32) → 256 words × 32 bits
//                                        = 8192 bits = 1 KiB per macro, 2-port (RW + R)
//                                        vccd1/vssd1 power. Verilog model:
//                                          libs.ref/sky130_sram_macros/verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v
//
// The previously-planned 128x256x8 (4 KiB) and 64x256x8 (2 KiB) macros referenced under
// flow/platforms/sky130ram/ do NOT exist on this machine — the flow/platforms/ tree is absent
// and no 4 KiB macro is present in the PDK. Banking below is re-derived against the real macros.
//
// Capacity math (verified from LIB memory() blocks, the authoritative source):
//   32x512 macro:  512 words × 32 bits = 2048 bytes = 2 KiB.  (ADDR_WIDTH=9)
//   32x256 macro:  256 words × 32 bits = 1024 bytes = 1 KiB.  (ADDR_WIDTH=8)
//   SoC word = 32 bits = 4 bytes.  Macro word width == SoC word width, so 1 macro word ==
//   1 SoC word (no lane splitting).  wmask width == 4 == SoC wstrb width, so byte enables map
//   one-to-one (no expansion).
//
// CRITICAL CONSTRAINT ON MACRO SELECTION:
//   This wrapper currently supports a single macro type per instantiation, parameterized by
//   MACRO_DW / MACRO_AW / NUM_MACROS, with MACRO_DW == 32 (the only width-compatible real macro).
//   The 8x1024 macro (8-bit data) is NOT width-compatible and is not supported.
//
// DEFAULT IS THE 2 KiB MACRO (32x512). The 1 KiB macro is available as an alternate by setting
// MACRO_DW=32, MACRO_AW=8 and re-deriving NUM_MACROS. The cell name instantiated is selected by
// `ifdef MACRO_USE_1KB at elaboration — see the g_bank generate.
//
// SRAM banking for 128 KiB with the DEFAULT 2 KiB macro:
//   NUM_MACROS     = 64   (128 KiB / 2 KiB = 64)
//   macro words/macro = 512  (MACRO_AW = 9)
//   SoC words/macro   = 512  (no lanes, since MACRO_DW == DATA_WIDTH == 32)
//   BANK_AW        = 6    ($clog2(64))
//   LOCAL_AW       = 9    ($clog2(512))
//   LANE_AW        = 0    (1 lane, no lane select)
//   SoC word address (15 bits for 128 KiB = 32768 words) splits into:
//     bank[8:3] (6 bits, 64 banks) + local[8:0] (9 bits, 512 words/bank = macro ADDR_WIDTH)
//   Check: 64 banks × 512 words = 32768 words = 128 KiB. ✓
//
// TCM banking for 32 KiB with the DEFAULT 2 KiB macro (delegated by tcm_macro_wrap):
//   NUM_MACROS     = 16   (32 KiB / 2 KiB = 16)
//   BANK_AW        = 4    ($clog2(16))
//   LOCAL_AW       = 9    ($clog2(512))
//   SoC word address (13 bits for 32 KiB = 8192 words) splits into:
//     bank[8:5] (4 bits, 16 banks) + local[8:0] (9 bits, macro ADDR_WIDTH)
//   Check: 16 banks × 512 words = 8192 words = 32 KiB. ✓
//
// Alternate: 1 KiB macro (32x256) for 128 KiB SRAM:
//   NUM_MACROS     = 128  (128 KiB / 1 KiB)
//   BANK_AW        = 7
//   LOCAL_AW       = 8  (256 words/bank)
//   SoC word addr (15 bits) → bank[14:8] (7 bits) + local[7:0] (8 bits = macro ADDR_WIDTH)
//   128 banks × 256 words = 32768 words = 128 KiB. ✓
//
// Semantics (identical external contract to rtl/rtl_top/sram.sv, the production behavioural
// master; the macro-specific closes below are REQUIRED because the real macro's protocol differs
// from the behavioural array):
//   - AXI4-Lite FSM: S_IDLE / S_WRESP / S_RRESP, write priority over read (arready gated by
//     awvalid&wvalid), one-cycle AXI handshake, byte-strobed writes (wstrb[3:0] → wmask[3:0]
//     one-to-one), reset resets FSM + address registers only.
//   - Instruction port: independent one-cycle synchronous read, i_gnt = i_req, i_rvalid =
//     registered i_req, i_rdata from macro port 1 read.
//   - Macro-specific closes (REQUIRED — the real macro is not a combinational array):
//       1. Registered macro output — the macro DOUT is registered (the macro Verilog model
//          issues the read on posedge and returns data after DELAY on negedge; the LIB
//          interface_timing:true gives falling-edge dout0/dout1 relative to clk0/clk1).
//          The wrapper therefore samples the access request in cycle N and the macro data
//          arrives in cycle N+1 (the AXI FSM's one-cycle response latency matches this:
//          rdata is driven from the registered macro output one cycle after arvalid was
//          accepted). This is the macro's actual timing, not a behavioural assumption.
//       2. RDATA hold under RVALID && !RREADY — when the master stalls the read response,
//          rdata is held (the macro drives dout for one cycle; without hold the master would
//          see garbage on the stalled cycles).
//       3. Same-word write → instruction-read forwarding — the macro's port 1 is an independent
//          read port with its own registered output; it cannot promise the behavioural array's
//          combinational same-word visibility when a write and instruction fetch hit the same
//          macro word in the same cycle. The wrapper forwards the written bytes to the
//          instruction port in that case (the forward is conservative: it only fires on a true
//          same-word same-cycle hit).
//
// Reset / init (REAL GAP, not a wrapper bug):
//   The real macros have NO reset pin and NO init file path. Their contents at power-on are
//   undefined (the behavioural Verilog model leaves mem uninitialized; in silicon the macro
//   powers up undefined). This matches sram.sv only in the sense that sram.sv's $readmemh
//   initialization is simulation-only and has no synthesis equivalent — but the behavioural
//   array at least has deterministic $readmemh contents in sim, whereas a real macro has NONE.
//   Consequence:
//     - SRAM_INIT_FILE (has_soc.sv) and TCM_INIT_FILE are simulation-only; they cannot flow
//       into a real macro. In a real macro implementation, SRAM/TCM contents are undefined at
//       power-on. Software/boot ROM must initialize TCM before use (TCM is used for stack/
//       data, so the boot sequence must zero/initialize it), and any pre-loaded SRAM data must
//       be loaded by boot code or is simply undefined.
//     - This is a documented gap in the macro-based memory architecture, not a wrapper defect.
//       It does not block synthesis/elaboration; it blocks confidence that the memory contents
//       are what the software expects without additional boot-time init.
//
// Synthesis (Yosys): the macroLIB is read as a liberty blackbox (read_lib), the macro Verilog
// model is read as the structural instance (read_verilog of the real macro .v from the verilog/
// subdir of the PDK), and Yosys maps only the adapter logic to sky130_fd_sc_hd. The macro
// instances remain as hierarchy leaves (dont_touch / dont_use in the LIB). This is the same
// approach as RUN-0021's synth_tcm.ys, re-targeted to the real macro.
//
// Power pins: macros use vccd1/vssd1 (PG_PIN VSSD1/VCCD1 in LIB; Verilog model gates them
// behind `ifdef USE_POWER_PINS as inout vccd1/vssd1). Yosys must define USE_POWER_PINS when
// reading the macro model so the instance declares and exposes those pins (otherwise the
// instance has no power pins and the netlist is physically incomplete). The LIB's pg_pin names
// are vccd1/vssd1, which DO NOT match the stock ORFS PDN patterns that expect VPWR/VGND — an
// explicit add_global_connection(vccd1->VPWR, vssd1->VGND) is required in the physical flow
// (RUN-0021 PDN-217 finding). This wrapper does not connect power pins; that is a physical-flow
// concern.
//------------------------------------------------------------------------------

module sram_macro_wrap #(
  // verilog_lint: waive explicit-parameter-storage-type
  parameter int ADDR_WIDTH = 17,           // bytes; 2^17 = 128 KiB (SoC SRAM aperture)
  parameter int DATA_WIDTH = 32,
  // Macro geometry — defaults to the real 2 KiB macro (32x512) available on this machine.
  // To use the 1 KiB macro (32x256) instead: MACRO_DW=32, MACRO_AW=8, NUM_MACROS=128 (for
  // 128 KiB SRAM) or NUM_MACROS=32 (for 32 KiB TCM), and define `MACRO_USE_1KB at
  // elaboration. The 1 KiB / 2 KiB choice is a compile-time constant so the generate-bound
  // and the banking math are both constant.
  parameter int MACRO_DW   = 32,
  parameter int MACRO_AW   = 9,
  // Number of macros (banks). Default 64 = 128 KiB / 2 KiB (32x512 macro).
  // For TCM (32 KiB) the delegate sets NUM_MACROS=16.
  parameter int NUM_MACROS = 64,
  // SIMULATION ONLY. The real Sky130 macros have no initialisation port, so
  // silicon always powers up with undefined contents. Testbenches still need to
  // run programs out of TCM/SRAM, so when SIM_MEM_PRELOAD is defined this file
  // loads INIT_FILE (one 32-bit word per line, SoC word order) into the leaf
  // models' arrays bank by bank. Without the define, and in synthesis, this is
  // dead code and INIT_FILE has no effect.
  // verilog_lint: waive explicit-parameter-storage-type
  parameter INIT_FILE = ""
) (
  input  logic                   clk,
  input  logic                   reset_n,
  // AXI4-Lite write address channel
  input  logic                   awvalid,
  input  logic [ADDR_WIDTH-1:0]  awaddr,
  output logic                   awready,
  // AXI4-Lite write data channel
  input  logic                   wvalid,
  input  logic [DATA_WIDTH-1:0]  wdata,
  input  logic [3:0]             wstrb,
  output logic                   wready,
  // AXI4-Lite write response channel
  output logic                   bvalid,
  input  logic                   bready,
  output logic [1:0]             bresp,
  // AXI4-Lite read address channel
  input  logic                   arvalid,
  input  logic [ADDR_WIDTH-1:0]  araddr,
  output logic                   arready,
  // AXI4-Lite read data channel
  output logic                   rvalid,
  output logic [DATA_WIDTH-1:0]  rdata,
  output logic [1:0]             rresp,
  input  logic                   rready,
  // Instruction read port (execute-in-place)
  input  logic                   i_req,
  input  logic [ADDR_WIDTH-1:0]  i_addr,
  output logic                   i_gnt,
  output logic [DATA_WIDTH-1:0]  i_rdata,
  output logic                   i_rvalid
);

  // -------------------------------------------------------------------------
  // Derived geometry
  // -------------------------------------------------------------------------
  localparam int WORDS       = 1 << (ADDR_WIDTH - 2);     // SoC words (32-bit)
  localparam int MACRO_WORDS = 1 << MACRO_AW;             // macro words per macro
  localparam int BANK_WORDS  = MACRO_WORDS;               // SoC words per macro (== macro
                                                           //   words because MACRO_DW ==
                                                           //   DATA_WIDTH == 32, no lanes)
  localparam int BANK_AW     = (NUM_MACROS <= 1) ? 1 : $clog2(NUM_MACROS);
  localparam int LOCAL_AW    = $clog2(BANK_WORDS);
  localparam int LANE_AW     = 0;                         // 1 lane (no lane select)


  // Sanity: the geometry must cover the SoC address space exactly.
  // NUM_MACROS * BANK_WORDS must equal WORDS. If the parameters don't satisfy this, the
  // wrapper is mis-configured for the target capacity and should not be used.
  // (Checked in the equivalence bench and the synthesis validation, not asserted in RTL to
  // avoid synthesis issues with constant expressions — documented as a configuration constraint.)

  // -------------------------------------------------------------------------
  // AXI4-Lite FSM — identical to sram.sv
  // -------------------------------------------------------------------------
  typedef enum logic [1:0] {S_IDLE, S_WRESP, S_RRESP} st_e;
  st_e state, state_n;

  logic [ADDR_WIDTH-1:0] raddr_q;

  wire wr_fire = reset_n & awvalid & wvalid & awready & wready;
  wire rd_fire = arvalid & arready;

  // Write priority is explicit: a write is accepted even when a read address is
  // presented in the same cycle, so simultaneous READ+WRITE always makes
  // progress. Without the `(awvalid & wvalid)` term both channels stall
  // (awready needs ~arvalid, arready needs ~(awvalid&wvalid)) and a master that
  // holds both requests deadlocks. sram.sv carries the same expression.
  assign awready = (state == S_IDLE) & (~arvalid | (awvalid & wvalid));
  assign wready  = (state == S_IDLE) & (~arvalid | (awvalid & wvalid));
  assign arready = (state == S_IDLE) & ~(awvalid & wvalid);

  always_comb begin
    state_n = state;
    unique case (state)
      S_IDLE:  if (wr_fire) state_n = S_WRESP;
               else if (rd_fire) state_n = S_RRESP;
      S_WRESP: if (bready)  state_n = S_IDLE;
      S_RRESP: if (rready)  state_n = S_IDLE;
      default: state_n = S_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state   <= S_IDLE;
      raddr_q <= '0;
    end else begin
      state <= state_n;
      if (rd_fire) raddr_q <= araddr;
    end
  end

  // -------------------------------------------------------------------------
  // Instruction port — same one-cycle contract as sram.sv
  // -------------------------------------------------------------------------
  logic                  i_req_q;
  logic [ADDR_WIDTH-1:0] i_addr_q;

  assign i_gnt    = i_req;
  assign i_rvalid = i_req_q;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      i_req_q  <= 1'b0;
      i_addr_q <= '0;
    end else begin
      i_req_q <= i_req;
      if (i_req) i_addr_q <= i_addr;
    end
  end

  assign bvalid = (state == S_WRESP);
  assign bresp  = 2'b00;
  assign rvalid = (state == S_RRESP);
  assign rresp  = 2'b00;

  // -------------------------------------------------------------------------
  // Address decode (no lane splitting — MACRO_DW == DATA_WIDTH == 32, so 1 macro word ==
  // 1 SoC word; bank select is the high BANK_AW bits of the word address, local is the
  // low LOCAL_AW bits, and the local bits ARE the macro row address).
  // -------------------------------------------------------------------------
  wire [ADDR_WIDTH-3:0] wr_word = awaddr[ADDR_WIDTH-1:2];
  wire [ADDR_WIDTH-3:0] rd_word = araddr[ADDR_WIDTH-1:2];
  wire [ADDR_WIDTH-3:0] ir_word = i_addr[ADDR_WIDTH-1:2];

  wire [BANK_AW-1:0]  wr_bank  = wr_word[LOCAL_AW +: BANK_AW];
  wire [LOCAL_AW-1:0] wr_local = wr_word[LOCAL_AW-1:0];
  wire [BANK_AW-1:0]  rd_bank  = rd_word[LOCAL_AW +: BANK_AW];
  wire [LOCAL_AW-1:0] rd_local = rd_word[LOCAL_AW-1:0];
  wire [BANK_AW-1:0]  ir_bank  = ir_word[LOCAL_AW +: BANK_AW];
  wire [LOCAL_AW-1:0] ir_local = ir_word[LOCAL_AW-1:0];

  // macro_row is the local word address; with no lanes, the whole local address goes to the
  // macro's addr port (which is ADDR_WIDTH == MACRO_AW bits wide).
  wire [MACRO_AW-1:0] wr_macro_row = wr_local;
  wire [MACRO_AW-1:0] rd_macro_row = rd_local;
  wire [MACRO_AW-1:0] ir_macro_row = ir_local;

  wire axi_access = wr_fire | rd_fire;

  // -------------------------------------------------------------------------
  // Per-bank DOUT arrays — driven by each macro instance's dout0/dout1, selected below.
  // Declared here, before the generate, so the generate can drive them.
  // -------------------------------------------------------------------------
  logic [MACRO_DW-1:0] dout0_bank [NUM_MACROS];
  logic [MACRO_DW-1:0] dout1_bank [NUM_MACROS];

  genvar b;
  generate
    for (b = 0; b < NUM_MACROS; b++) begin : g_bank
      // Bank address constant for this instance (compared against the decoded bank).
      wire [BANK_AW-1:0] b_addr = b[BANK_AW-1:0];

      // Port 0 chip select: asserted when an AXI access (write or read) targets this bank.
      wire port0_cs = axi_access & (wr_fire ? (wr_bank == b_addr)
                                             : (rd_bank == b_addr));
      // Port 1 chip select: asserted when an instruction fetch targets this bank.
      wire port1_cs = i_req & (ir_bank == b_addr);

      // Macro instances — REAL Sky130 macros only. The cell name is selected by
      // `ifdef MACRO_USE_1KB at elaboration:
      //   defined  -> sky130_sram_1kbyte_1rw1r_32x256_8  (1 KiB, 256×32, ADDR_WIDTH=8)
      //   undefined-> sky130_sram_2kbyte_1rw1r_32x512_8  (2 KiB, 512×32, ADDR_WIDTH=9)
      // Both have: 32-bit din0/dout0/dout1, 4-bit wmask0, 2-port (RW + R), registered I/O,
      // vccd1/vssd1 power (gated behind `ifdef USE_POWER_PINS in the Verilog model).
      //
      // CONSTRAINT: Yosys MUST define USE_POWER_PINS when reading the macro Verilog model,
      // or the instance will not declare vccd1/vssd1 and the netlist will be physically
      // incomplete (no power pins to connect to the PDN). The LIB independently defines
      // pg_pin(vccd1)/pg_pin(vssd1) regardless of the model's `ifdef.
      //
      // Note: neither the 128x256x8 (4 KiB) nor the 64x256x8 (2 KiB) macros exist on this
      // machine — they were referenced under a flow/platforms/sky130ram/ tree that is absent.
      // Those cell names are NOT instantiated here.
      `ifdef MACRO_USE_1KB
        // 1 KiB macro: sky130_sram_1kbyte_1rw1r_32x256_8
        sky130_sram_1kbyte_1rw1r_32x256_8 u_macro (
          `ifdef USE_POWER_PINS
          .vccd1 (),
          .vssd1 (),
          `endif
          .clk0  (clk),
          .csb0  (~port0_cs),
          .web0  (~wr_fire),
          .wmask0(wr_fire ? wstrb : 4'hF),
          .addr0 (wr_fire ? wr_macro_row : rd_macro_row),
          .din0  (wr_fire ? wdata : {32{1'b0}}),
          .dout0 (dout0_bank[b]),
          .clk1  (clk),
          .csb1  (~port1_cs),
          .addr1 (ir_macro_row),
          .dout1 (dout1_bank[b])
        );
      `else
        // 2 KiB macro: sky130_sram_2kbyte_1rw1r_32x512_8 (DEFAULT)
        sky130_sram_2kbyte_1rw1r_32x512_8 u_macro (
          `ifdef USE_POWER_PINS
          .vccd1 (),
          .vssd1 (),
          `endif
          .clk0  (clk),
          .csb0  (~port0_cs),
          .web0  (~wr_fire),
          .wmask0(wr_fire ? wstrb : 4'hF),
          .addr0 (wr_fire ? wr_macro_row : rd_macro_row),
          .din0  (wr_fire ? wdata : {32{1'b0}}),
          .dout0 (dout0_bank[b]),
          .clk1  (clk),
          .csb1  (~port1_cs),
          .addr1 (ir_macro_row),
          .dout1 (dout1_bank[b])
        );
      `endif
    end
  endgenerate

  // -------------------------------------------------------------------------
  // Registered access-bank capture for AXI reads and instruction reads.
  //
  // The macro's DOUT is registered (the macro model issues the read on posedge and returns
  // data after DELAY on the following negedge; the LIB gives falling-edge dout0/dout1).
  // We therefore sample the target bank+lane (here just the bank, since there are no lanes)
  // one cycle before we expect the data, then select the matching macro's DOUT one cycle later.
  //
  // NOTE: this is the macro's actual timing, not the behavioural array's combinational read.
  // The AXI FSM's one-cycle response latency (rvalid one cycle after arvalid accepted) is
  // consistent with this, but the correctness of the full timing path (macro delay + wrapper
  // selection) is a physical/STA question, not something RTL alone establishes. See the gaps
  // recorded in the Phase 5.3A spec.
  // -------------------------------------------------------------------------
  logic [BANK_AW-1:0] rd_bank_q, ir_bank_q;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_bank_q <= '0;
      ir_bank_q <= '0;
    end else begin
      if (rd_fire) rd_bank_q <= rd_bank;
      if (i_req)   ir_bank_q <= ir_bank;
    end
  end

  // Select the matching bank's DOUT one cycle after the access.
  logic [MACRO_DW-1:0] rd_dout, ir_dout;

  always_comb begin
    rd_dout = '0;
    ir_dout = '0;
    for (int k = 0; k < NUM_MACROS; k++) begin
      if (rd_bank_q == k[BANK_AW-1:0]) rd_dout = dout0_bank[k];
      if (ir_bank_q == k[BANK_AW-1:0]) ir_dout = dout1_bank[k];
    end
  end

  // RDATA hold under RVALID && !RREADY (macro drives DOUT for one cycle; a stalled master
  // must see held data). Capture the read data on the first cycle of the response; if the
  // master stalls (rready low) we hold it.
  logic [DATA_WIDTH-1:0] rdata_hold_q;
  logic                  rresp_stalled_q;

  assign rdata = rresp_stalled_q ? rdata_hold_q : rd_dout;   // no lane extract — full word

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rdata_hold_q    <= '0;
      rresp_stalled_q <= 1'b0;
    end else if (state != S_RRESP) begin
      rresp_stalled_q <= 1'b0;
    end else if (!rresp_stalled_q) begin
      rdata_hold_q    <= rd_dout;
      rresp_stalled_q <= ~rready;
    end
  end

  // -------------------------------------------------------------------------
  // Instruction read data — select the instruction port's bank DOUT, then apply the
  // same-word write→read forwarding (see below).
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] i_lane, i_merged;

  assign i_lane = ir_dout;   // no lane extract — full 32-bit word (no lanes)

  // -------------------------------------------------------------------------
  // Same-word write → instruction-read forwarding (per RUN-0021 §2.3, adapted to the real
  // macro's protocol).
  //
  // sram.sv's instruction read is a combinational array read, so a read issued in the same
  // cycle as a write to that word returns the new data. The real macro's port 1 is an
  // independent read port with its own registered output; it cannot promise that combinational
  // same-word visibility when an AXI write and an instruction fetch hit the same macro word in
  // the same cycle. The wrapper forwards the written bytes to the instruction port in that case.
  //
  // The forward is conservative: it only fires on a true same-word same-cycle hit (wr_fire &
  // same word address as the instruction fetch). The forward uses the AXI write data + wstrb,
  // applied cycle-by-cycle (the forwarded data is the data written in the same cycle, not a
  // queued value).
  // -------------------------------------------------------------------------
  logic        wr_i_hit_q;
  logic [31:0] wr_i_data_q;
  logic [3:0]  wr_i_strb_q;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_i_hit_q  <= 1'b0;
      wr_i_data_q <= '0;
      wr_i_strb_q <= '0;
    end else begin
      wr_i_hit_q  <= wr_fire & (wr_word == ir_word);
      wr_i_data_q <= wdata;
      wr_i_strb_q <= wstrb;
    end
  end

  always_comb begin
    i_merged = i_lane;
    if (wr_i_hit_q) begin
      for (int k = 0; k < 4; k++)
        if (wr_i_strb_q[k]) i_merged[8*k +: 8] = wr_i_data_q[8*k +: 8];
    end
  end

  assign i_rdata = i_merged;

  //--------------------------------------------------------------------------
  // SIMULATION-ONLY preload (see the INIT_FILE parameter). Real macros cannot
  // be initialised; this exists so an SoC testbench can fetch a program from
  // TCM/SRAM without a boot loader. Guarded by SIM_MEM_PRELOAD so synthesis and
  // real-macro simulation never see it.
  //--------------------------------------------------------------------------
  `ifdef SIM_MEM_PRELOAD
    // Staging copy of the image. Each bank copies its own slice from inside its
    // generate block (below) using the constant genvar index -- a variable index
    // into a generate scope is not elaboratable in Icarus.
    logic [DATA_WIDTH-1:0] preload_mem [0:WORDS-1];
    integer preload_b, preload_k;

    initial begin
      if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, preload_mem);
        $display("[sram_macro_wrap] SIM preload %0s: %0d banks x %0d words",
                 INIT_FILE, NUM_MACROS, BANK_WORDS);
      end
    end

    // Copy each bank's slice into its leaf model. Icarus resolves a generate
    // scope only by CONSTANT index, and only when the enclosing generate branch
    // is actually elaborated -- hence the constant indices and the
    // `NUM_MACROS > N' guards (a pruned branch is never resolved). The two
    // production geometries, 16 and 64 banks, are exact multiples of the
    // 16-bank block size, so every configured bank is covered.
    generate
    if (NUM_MACROS > 0) begin : preload_0
      initial begin
        #0;   // let the instance $readmemh land first
        for (preload_b = 0; preload_b < NUM_MACROS && preload_b <= 15; preload_b = preload_b + 1) begin
          if (preload_b == 0)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[0].u_macro.mem[preload_k] = preload_mem[0 * BANK_WORDS + preload_k];
          if (preload_b == 1)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[1].u_macro.mem[preload_k] = preload_mem[1 * BANK_WORDS + preload_k];
          if (preload_b == 2)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[2].u_macro.mem[preload_k] = preload_mem[2 * BANK_WORDS + preload_k];
          if (preload_b == 3)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[3].u_macro.mem[preload_k] = preload_mem[3 * BANK_WORDS + preload_k];
          if (preload_b == 4)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[4].u_macro.mem[preload_k] = preload_mem[4 * BANK_WORDS + preload_k];
          if (preload_b == 5)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[5].u_macro.mem[preload_k] = preload_mem[5 * BANK_WORDS + preload_k];
          if (preload_b == 6)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[6].u_macro.mem[preload_k] = preload_mem[6 * BANK_WORDS + preload_k];
          if (preload_b == 7)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[7].u_macro.mem[preload_k] = preload_mem[7 * BANK_WORDS + preload_k];
          if (preload_b == 8)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[8].u_macro.mem[preload_k] = preload_mem[8 * BANK_WORDS + preload_k];
          if (preload_b == 9)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[9].u_macro.mem[preload_k] = preload_mem[9 * BANK_WORDS + preload_k];
          if (preload_b == 10)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[10].u_macro.mem[preload_k] = preload_mem[10 * BANK_WORDS + preload_k];
          if (preload_b == 11)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[11].u_macro.mem[preload_k] = preload_mem[11 * BANK_WORDS + preload_k];
          if (preload_b == 12)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[12].u_macro.mem[preload_k] = preload_mem[12 * BANK_WORDS + preload_k];
          if (preload_b == 13)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[13].u_macro.mem[preload_k] = preload_mem[13 * BANK_WORDS + preload_k];
          if (preload_b == 14)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[14].u_macro.mem[preload_k] = preload_mem[14 * BANK_WORDS + preload_k];
          if (preload_b == 15)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[15].u_macro.mem[preload_k] = preload_mem[15 * BANK_WORDS + preload_k];
        end
      end
    end
    if (NUM_MACROS > 16) begin : preload_16
      initial begin
        #0;   // let the instance $readmemh land first
        for (preload_b = 16; preload_b < NUM_MACROS && preload_b <= 31; preload_b = preload_b + 1) begin
          if (preload_b == 16)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[16].u_macro.mem[preload_k] = preload_mem[16 * BANK_WORDS + preload_k];
          if (preload_b == 17)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[17].u_macro.mem[preload_k] = preload_mem[17 * BANK_WORDS + preload_k];
          if (preload_b == 18)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[18].u_macro.mem[preload_k] = preload_mem[18 * BANK_WORDS + preload_k];
          if (preload_b == 19)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[19].u_macro.mem[preload_k] = preload_mem[19 * BANK_WORDS + preload_k];
          if (preload_b == 20)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[20].u_macro.mem[preload_k] = preload_mem[20 * BANK_WORDS + preload_k];
          if (preload_b == 21)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[21].u_macro.mem[preload_k] = preload_mem[21 * BANK_WORDS + preload_k];
          if (preload_b == 22)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[22].u_macro.mem[preload_k] = preload_mem[22 * BANK_WORDS + preload_k];
          if (preload_b == 23)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[23].u_macro.mem[preload_k] = preload_mem[23 * BANK_WORDS + preload_k];
          if (preload_b == 24)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[24].u_macro.mem[preload_k] = preload_mem[24 * BANK_WORDS + preload_k];
          if (preload_b == 25)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[25].u_macro.mem[preload_k] = preload_mem[25 * BANK_WORDS + preload_k];
          if (preload_b == 26)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[26].u_macro.mem[preload_k] = preload_mem[26 * BANK_WORDS + preload_k];
          if (preload_b == 27)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[27].u_macro.mem[preload_k] = preload_mem[27 * BANK_WORDS + preload_k];
          if (preload_b == 28)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[28].u_macro.mem[preload_k] = preload_mem[28 * BANK_WORDS + preload_k];
          if (preload_b == 29)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[29].u_macro.mem[preload_k] = preload_mem[29 * BANK_WORDS + preload_k];
          if (preload_b == 30)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[30].u_macro.mem[preload_k] = preload_mem[30 * BANK_WORDS + preload_k];
          if (preload_b == 31)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[31].u_macro.mem[preload_k] = preload_mem[31 * BANK_WORDS + preload_k];
        end
      end
    end
    if (NUM_MACROS > 32) begin : preload_32
      initial begin
        #0;   // let the instance $readmemh land first
        for (preload_b = 32; preload_b < NUM_MACROS && preload_b <= 47; preload_b = preload_b + 1) begin
          if (preload_b == 32)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[32].u_macro.mem[preload_k] = preload_mem[32 * BANK_WORDS + preload_k];
          if (preload_b == 33)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[33].u_macro.mem[preload_k] = preload_mem[33 * BANK_WORDS + preload_k];
          if (preload_b == 34)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[34].u_macro.mem[preload_k] = preload_mem[34 * BANK_WORDS + preload_k];
          if (preload_b == 35)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[35].u_macro.mem[preload_k] = preload_mem[35 * BANK_WORDS + preload_k];
          if (preload_b == 36)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[36].u_macro.mem[preload_k] = preload_mem[36 * BANK_WORDS + preload_k];
          if (preload_b == 37)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[37].u_macro.mem[preload_k] = preload_mem[37 * BANK_WORDS + preload_k];
          if (preload_b == 38)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[38].u_macro.mem[preload_k] = preload_mem[38 * BANK_WORDS + preload_k];
          if (preload_b == 39)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[39].u_macro.mem[preload_k] = preload_mem[39 * BANK_WORDS + preload_k];
          if (preload_b == 40)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[40].u_macro.mem[preload_k] = preload_mem[40 * BANK_WORDS + preload_k];
          if (preload_b == 41)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[41].u_macro.mem[preload_k] = preload_mem[41 * BANK_WORDS + preload_k];
          if (preload_b == 42)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[42].u_macro.mem[preload_k] = preload_mem[42 * BANK_WORDS + preload_k];
          if (preload_b == 43)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[43].u_macro.mem[preload_k] = preload_mem[43 * BANK_WORDS + preload_k];
          if (preload_b == 44)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[44].u_macro.mem[preload_k] = preload_mem[44 * BANK_WORDS + preload_k];
          if (preload_b == 45)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[45].u_macro.mem[preload_k] = preload_mem[45 * BANK_WORDS + preload_k];
          if (preload_b == 46)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[46].u_macro.mem[preload_k] = preload_mem[46 * BANK_WORDS + preload_k];
          if (preload_b == 47)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[47].u_macro.mem[preload_k] = preload_mem[47 * BANK_WORDS + preload_k];
        end
      end
    end
    if (NUM_MACROS > 48) begin : preload_48
      initial begin
        #0;   // let the instance $readmemh land first
        for (preload_b = 48; preload_b < NUM_MACROS && preload_b <= 63; preload_b = preload_b + 1) begin
          if (preload_b == 48)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[48].u_macro.mem[preload_k] = preload_mem[48 * BANK_WORDS + preload_k];
          if (preload_b == 49)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[49].u_macro.mem[preload_k] = preload_mem[49 * BANK_WORDS + preload_k];
          if (preload_b == 50)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[50].u_macro.mem[preload_k] = preload_mem[50 * BANK_WORDS + preload_k];
          if (preload_b == 51)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[51].u_macro.mem[preload_k] = preload_mem[51 * BANK_WORDS + preload_k];
          if (preload_b == 52)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[52].u_macro.mem[preload_k] = preload_mem[52 * BANK_WORDS + preload_k];
          if (preload_b == 53)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[53].u_macro.mem[preload_k] = preload_mem[53 * BANK_WORDS + preload_k];
          if (preload_b == 54)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[54].u_macro.mem[preload_k] = preload_mem[54 * BANK_WORDS + preload_k];
          if (preload_b == 55)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[55].u_macro.mem[preload_k] = preload_mem[55 * BANK_WORDS + preload_k];
          if (preload_b == 56)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[56].u_macro.mem[preload_k] = preload_mem[56 * BANK_WORDS + preload_k];
          if (preload_b == 57)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[57].u_macro.mem[preload_k] = preload_mem[57 * BANK_WORDS + preload_k];
          if (preload_b == 58)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[58].u_macro.mem[preload_k] = preload_mem[58 * BANK_WORDS + preload_k];
          if (preload_b == 59)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[59].u_macro.mem[preload_k] = preload_mem[59 * BANK_WORDS + preload_k];
          if (preload_b == 60)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[60].u_macro.mem[preload_k] = preload_mem[60 * BANK_WORDS + preload_k];
          if (preload_b == 61)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[61].u_macro.mem[preload_k] = preload_mem[61 * BANK_WORDS + preload_k];
          if (preload_b == 62)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[62].u_macro.mem[preload_k] = preload_mem[62 * BANK_WORDS + preload_k];
          if (preload_b == 63)
            for (preload_k = 0; preload_k < BANK_WORDS; preload_k = preload_k + 1)
              g_bank[63].u_macro.mem[preload_k] = preload_mem[63 * BANK_WORDS + preload_k];
        end
      end
    end
    endgenerate
  `endif

endmodule
