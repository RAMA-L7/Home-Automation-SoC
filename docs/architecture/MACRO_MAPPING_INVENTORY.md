# Macro Mapping Inventory — Phase 5.3B

Last updated: 2026-11-26. Companion to `docs/architecture/` and `reports/phase5_3b_report.md`.

## Real Sky130 SRAM macros available (volare PDK, read-only collateral)

| Cell | Capacity | Geometry | ADDR_WIDTH | DATA_WIDTH | wmask | Ports | Init | Reset pin | Power pins |
|---|---|---|---|---|---|---|---|---|---|
| `sky130_sram_2kbyte_1rw1r_32x512_8` | 2 KiB | 32×512 | 9 | 32 | 4-bit (wmask0[3:0]) | 2: port0 RW+R, port1 R-only | No (mem uninitialized) | No | `ifdef USE_POWER_PINS`: inout vccd1/vssd1 |
| `sky130_sram_1kbyte_1rw1r_32x256_8` | 1 KiB | 32×256 | 8 | 32 | 4-bit | 2: port0 RW+R, port1 R-only | No | No | `ifdef USE_POWER_PINS`: inout vccd1/vssd1 |

Source (read-only, do not copy):
- `C:/Users/91846/.volare/volare/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_sram_macros/verilog/sky130_sram_2kbyte_1rw1r_32x512_8.v`
- `.../sky130_sram_1kbyte_1rw1r_32x256_8.v`
- `.../lib/sky130_sram_2kbyte_1rw1r_32x512_8_TT_1p8V_25C.lib`
- `.../lef/sky130_sram_2kbyte_1rw1r_32x512_8.lef`

## Non-existent macros (on this machine)

The following were referenced historically under a `flow/platforms/sky130ram/` tree that is **absent** on this machine. They are NOT available and NOT instantiated:

- 4 KiB macros (any geometry) — absent.
- `128x256x8` (2 KiB) and `64x256x8` (2 KiB, different aspect) — the wrapper comment previously flagged these as the cells under discussion; they do not exist here.

## Wrapper geometry → macro mapping

### SRAM (128 KiB, sram_macro_wrap, default params)

- ADDR_WIDTH=17 → 2^17 = 131072 bytes = 128 KiB (32768 words of 32 bits).
- Default macro: 2 KiB (32×512), MACRO_AW=9, MACRO_DW=32.
- NUM_MACROS = 128 KiB / 2 KiB = **64 macros** (banks). BANK_AW = $clog2(64) = 6. LOCAL_AW = $clog2(512) = 9. MACRO_DW == DATA_WIDTH == 32 → LANE_AW = 0 (no lane splitting). 1 macro word == 1 SoC word.
- Check: 64 banks × 512 words = 32768 SoC words = 128 KiB. ✓
- `ifdef MACRO_USE_1KB`: would require 128 macros (1 KiB each) for 128 KiB; not used in the current config.

### TCM (32 KiB, tcm_macro_wrap, delegates to sram_macro_wrap)

- ADDR_WIDTH=15 → 2^15 = 32768 bytes = 32 KiB (8192 words of 32 bits).
- Uses the same 2 KiB macro (MACRO_AW=9, MACRO_DW=32).
- NUM_MACROS = 32 KiB / 2 KiB = **16 macros** (banks). BANK_AW = $clog2(16) = 4. LOCAL_AW = $clog2(512) = 9. LANE_AW = 0.
- Check: 16 banks × 512 words = 8192 SoC words = 32 KiB. ✓
- `tcm_macro_wrap.sv` is a thin parameterized delegate that sets ADDR_WIDTH=15, NUM_MACROS=16 and forwards to `sram_macro_wrap`.

### Scan coverage in simulation (NUM_MACROS=2, 2 banks)

The directed testbench `tb_sram_macro_wrap.v` instantiates the wrapper with NUM_MACROS=2 (BANK_AW=1, LOCAL_AW=9) to keep the bank decode small and coverage fast. This is a **simulation-only** reduced bank count; the synthesis config (64 SRAM / 16 TCM) is unchanged. Two banks are sufficient to verify the banking/decode/collision/reset/i-port contract; the remaining 62 SRAM banks and 14 TCM banks are structurally identical per-bank instances instantiated by the `generate for (b=0; b<NUM_MACROS; b++)` in the wrapper.

## Macro protocol contract (verified against the real behavioural model + LIB)

- Inputs (csb, web, wmask, addr, din) are **registered on the posedge** into `_reg` in the real model.
- `dout0`/`dout1` are **registered outputs**: driven to `32'bx` for T_HOLD=1 ns after the sampling posedge, then (if reading) `mem[addr_reg]` after DELAY=3 ns from the **negedge**. The LIB confirms falling-edge dout0/dout1 with clk0/clk1 min_period 1.956 ns and the address/data/wmask/csb/web setup+hold on the rising edge.
- **Byte-masked writes** (wmask0[3:0] == wstrb[3:0]): each byte lane written independently under the wmask; a 0 in a wmask bit leaves that byte unchanged. Verified in the TB (T3: all 16 strobe combos including 0000 no-Change).
- **2-port collision**: simultaneous port0 write + port1 read to the same address produces a `$display` collision warning in the real model; the wrapper prefers the write over the read (write priority in the FSM and in the per-bank decode). The TB (T10) smoke-tests this (no hang; specific rdata not asserted because collision data is undefined).
- **No reset pin** on the macro: the macro's `mem` is never cleared by reset. The wrapper resets only its own FSM/regs (state, raddr_q, i_req_q, i_addr_q, rd_bank_q, ir_bank_q, rdata_hold_q, rresp_stalled_q) — **NOT** the macro's memory. This is a documented gap (memory uninitialized at power-on; must be initialized by boot code for TCM/SRAM).
- **No init file path**: the real macro Verilog model and LIB have no `$readmemh`/init mechanism. `has_soc.sv` params `SRAM_INIT_FILE` and `TCM_INIT_FILE` are simulation-only and cannot flow into a real macro instance. The boot ROM (`boot_rom.sv`, 16 KiB behavioural blackbox with `$readmemh` init) is the only initialized memory in the system.

## Macro Verilog model — tool compatibility

- **Yosys 0.69+154**: parses + elaborates the real 2 KiB model cleanly. `read_verilog -sv` → `hierarchy -check -top sky130_sram_2kbyte_1rw1r_32x512_8` → `stat` (107 wires, 1687 wire bits, 1 memories, 16384 memory bits, 5 processes, 30 cells) → `check` (only the expected 64 benign "multiple conflicting drivers for dout0/dout1" warnings from the behavioural body's double-drive of dout0/dout1 — the `32'bx` hold in the posedge block vs the `dout <= mem` in the negedge block; benign for a blackbox; exit 0). The model **must** be marked blackbox after `read_deps` before techmap/abc (already implemented in the fixed TCL), else Yosys tech-maps the internals into stdcells.
- **Icarus Verilog 14.0 (s20260301)**: the real macro model is **NOT** Icarus-elaborable. Error: `Scope index expression is not constant: addr0_reg`/`addr1_reg` — `mem[addr0_reg]` indexed access with a reg index is non-portable and Icarus tombstones it. Same failure for the 1 KiB model. This drove creation of the simulatable behavioural leaf proxies (`tb_macro_leaf.v` for 2 KiB, `tb_macro_leaf_1kb.v` for 1 KiB) that mirror the macro protocol (2-port RW+R, registered inputs, falling-edge dout with DELAY+T_HOLD, byte-masked writes, collision $display, no reset, mem uninitialized) so the **wrapper's logic** (banking/strobe/FSM/reset/i-port) can be exercised in Icarus.
- The leaf proxies are **test proxies only** — NOT timing-accurate, NOT shipped, NOT a substitute for the real macro. They exercise the wrapper's protocol contract; the macro's internal memory content and exact cycle-accurate delays are NOT verified by this approach (noted gap).

## ROM (boot_rom.sv) — no compatible real macro

- 16 KiB read-only ROM, ADDR_WIDTH=14, DATA_WIDTH=32, behavioural blackbox.
- `$readmemh`-initialized in `initial` (nop fill 0x00000013 default), `MEM_FILE`/`INIT_FILE` params.
- Instruction port (req/gnt/rvalid/rdata, 1-cycle grant, 1-cycle valid).
- AXI4-Lite slave, read-only: writes return SLVERR (bresp=2'b10), no write data path.
- **No compatible real macro exists**: all real macros are writable SRAM with no init path and uninitialized mem. A "read-only wrapper over a real SRAM macro" would preserve the init/read-only semantics only in simulation (the real macro's mem is uninitialized and writable), so it is NOT a true ROM implementation. See `reports/phase5_3b_report.md` for the ROM decision.

## Synthesis baselines and verification (Phase 5.3B)

This inventory documents the real Sky130 macro collateral used by the Phase 5.3B
integration. The macro wrapper instantiates **80 real `sky130_sram_2kbyte_1rw1r_32x512_8`
instances** (64 SRAM + 16 TCM) plus 1 behavioural `boot_rom`; see
`reports/phase5_3b_report.md` for the full integration, ROM decision, and
verification evidence. Key cross-references:

- **Verified real-macro netlist**: `be827aa676c3a1d5e52755abc1d642a6df264d689e7e0a482128bc4dee23eddd`
  (6,942,361 bytes, 47,432 stdcells, 142 unique types, 80 macros + boot_rom).
  Preserved in `artifacts/synthesis/2026-11-25_synth_20261125_234131/`; authoritative
  run result in `reports/synthesis_execution_summary.json`.
- **Frozen behavioural baseline** (preserved, unchanged): `b558b411b1e08e8425f9237d669ca648e45270e8b64e4fe306bb5a67ae355004`
  (5,786,347 bytes, behavioural `sram` ×2 + `boot_rom` ×1, 43,703 instances).
  Preserved in `artifacts/synthesis/2026-11-25_synth_20261125_200125/`.
- **Macro-wrapper verification**: 22/22 Icarus checks PASS (clean canonical run,
  0 failures, 0 DBG lines, exit 0). Testbench: `sim/sim_top/tb_sram_macro_wrap.v`
  + proxy leaf cells `tb_macro_leaf.v` / `tb_macro_leaf_1kb.v`. Canonical output:
  `build/sim/tb_sram_macro_wrap_out.txt`.
- **Macro RTL structural proof**: Yosys 0.69+154 parses + elaborates the real 2 KiB
  model cleanly (exit 0; 64 benign conflicting-driver warnings for dout0/dout1).
- **Reproducer probes** (canonical): `scripts/eda/probe3_full.bat`,
  `probe3_vvp.bat`, `probe3_clean.bat`, `probe4_isa.bat`.
- **Physical blockers (unchanged)**: WSL mount of the project absent/broken
  (OpenROAD/OpenSTA are Linux ELF); PDN mismatch RUN-0021 PDN-217
  (`vccd1`/`vssd1` vs `VPWR`/`VGND`); macro has no reset pin and no init path.
  Full-SoC physical signoff not run.
- **ROM**: behavioural `boot_rom.sv` retained — no compatible read-only/initialized
  real macro exists. Documented as a system-level gap, not a wrapper defect.
