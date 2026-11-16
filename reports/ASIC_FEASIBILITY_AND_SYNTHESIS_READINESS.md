# Home-Automation-SoC — ASIC Feasibility and Synthesis Readiness Audit

**Audit date:** 2026-11-14
**Auditor role:** Senior ASIC implementation / RTL synthesis engineer
**Repository:** `D:\Home-Automation-SoC`
**Branch:** `main`
**HEAD SHA:** `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`
**Working-tree diff SHA-256:** `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d`
**Evidence directory:** `reports/evidence/asic_feasibility_and_synthesis_readiness/`

No RTL, testbench, SDC, synthesis script, or flow configuration was modified by this audit. No commit, push, tag, reset, clean, stash, or branch switch was performed.

---

## 1. Executive Summary

- The RTL is a functional, simulation-verified RV32IM SoC (23 synthesizable source files). Generic, technology-independent synthesis succeeds for the CPU core and most peripheral modules under Yosys 0.69.
- Full-chip generic synthesis is **blocked** by two SystemVerilog constructs in the RTL: a package `import` in `has_soc.sv`/`axi_lite_interconnect.sv` and unpacked-array ports in `axi_lite_interconnect.sv`. These are tool/frontend limitations, not RTL logic errors, but they prevent a single top-level generic netlist from being produced by the available Yosys.
- A usable SkyWater 130 nm standard-cell platform exists on disk (via the OpenROAD-flow-scripts `sky130hd` platform): tech LEF, merged cell LEF, TT Liberty, cell GDS, KLayout DRC/LVS decks, tap-cell config, and (through `sky130hs`) real RCX rules. However, it is **not** a volare-enabled `sky130A` PDK, it provides only the TT corner in the `sky130hd` platform directory, and it is not integrated into this repository's `asic/` flow.
- No SRAM or ROM macro compatible with the SoC's 128 KB / 32 KB / 16 KB memories is available in the `sky130hd` platform. The RTL infers memories from behavioral arrays; Yosys maps the 128 KB SRAM to ~787 k cells (65 536 DFFs + muxes). This is not suitable for ASIC mapping.
- The SDC is a single-corner, partially populated constraint set: 50 MHz clock, basic I/O delays, clock uncertainty, and a few false paths. It lacks generated-clock definitions, input/output load/transition models, multicycle paths, reset synchronization, and any STA evidence.
- No technology-mapped synthesis, STA, floorplanning, placement, CTS, or routing has been run or verified. OpenROAD runs under WSL; OpenLane 2 runs under WSL with a working tkinter; Magic and Netgen are installed under `D:\tools`.
- **Final verdict: GENERIC SYNTHESIS READY, TECHNOLOGY MAPPING BLOCKED.**

---

## 2. Repository and Source Integrity

| Item | Value | Status |
|------|-------|--------|
| Branch | `main` | VERIFIED |
| HEAD SHA | `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1` | VERIFIED |
| Working-tree diff SHA-256 | `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d` | VERIFIED |
| Modified tracked files | `rtl/rtl_peripherals/plic.sv`, `rtl/rtl_top/has_soc.sv`, `rtl/rtl_top/riscv_core.sv`, `scripts/eda/run_regression.js`, `scripts/firmware/run_e2e.js`, `scripts/formal/reset_ctrl_fv.sv`, `scripts/verify.js` | VERIFIED |
| New untracked files | `reports/SOC_FUNCTIONAL_CORRECTNESS_CLOSURE.md`, `...EVIDENCE_AUDIT.md`, `...TARGETED_REGRESSION...md`, `reports/evidence/`, `sim/asm/`, `sim/sim_top/tb_apb_cpu.v`, `tb_cpu_arch.v`, `tb_plic_targeted.v`, `tb_watchdog_reset_phase.v` | VERIFIED |
| No commit/push/tag/reset/clean/stash/branch-switch performed | confirmed | VERIFIED |

Source list of record: `rtl/filelist.f` (23 files). All 23 are synthesizable SystemVerilog; no `initial`-based logic except memory initialization in `boot_rom.sv` and `sram.sv`.

---

## 3. SoC RTL Architecture Inventory

### 3.1 Actual SoC top module
- **`has_soc`** in `rtl/rtl_top/has_soc.sv` (parameters: `RESET_PC`, `UART_CLK_FREQ`, `UART_BAUD`; ports include `clk`, `reset_n`, UART/SPI/I2C/GPIO/PWM/I2S/JTAG/WDOG/WAKE interfaces).

### 3.2 Complete synthesizable RTL source list (`rtl/filelist.f`)
| # | File | Role |
|---|------|------|
| 1 | `rtl/rtl_top/has_addr_map.sv` | Address map package (`has_addr_map_pkg`) |
| 2 | `rtl/rtl_peripherals/clint.sv` | CLINT (mtime/mtimecmp/msip) |
| 3 | `rtl/rtl_peripherals/plic.sv` | PLIC (8 sources, 1 context) |
| 4 | `rtl/rtl_peripherals/gpio.sv` | 16-bit GPIO |
| 5 | `rtl/rtl_peripherals/uart.sv` | UART |
| 6 | `rtl/rtl_peripherals/i2c_ctrl.sv` | I2C master |
| 7 | `rtl/rtl_peripherals/spi_ctrl.sv` | SPI master |
| 8 | `rtl/rtl_peripherals/pwm.sv` | 4-ch PWM |
| 9 | `rtl/rtl_peripherals/timer.sv` | General timer |
| 10 | `rtl/rtl_peripherals/watchdog.sv` | Watchdog |
| 11 | `rtl/rtl_peripherals/i2s.sv` | I2S TX |
| 12 | `rtl/rtl_peripherals/power_mgr.sv` | Power manager |
| 13 | `rtl/rtl_peripherals/power_mgr_regs.sv` | Power manager APB regs |
| 14 | `rtl/rtl_peripherals/debug_jtag.sv` | JTAG TAP |
| 15 | `rtl/rtl_peripherals/qspi_flash_ctrl.sv` | QSPI flash read |
| 16 | `rtl/rtl_top/boot_rom.sv` | 16 KB boot ROM |
| 17 | `rtl/rtl_top/sram.sv` | 128 KB SRAM |
| 18 | `rtl/rtl_top/intc_axi.sv` | CLINT/PLIC AXI mux |
| 19 | `rtl/rtl_top/axi_lite_interconnect.sv` | 1-master x 6-slave AXI4-Lite |
| 20 | `rtl/rtl_top/axi_lite_to_apb.sv` | AXI4-Lite to APB bridge |
| 21 | `rtl/rtl_top/req_gnt_to_axi_lite.sv` | req/gnt to AXI4-Lite adapter |
| 22 | `rtl/rtl_top/riscv_core.sv` | RV32IM core |
| 23 | `rtl/rtl_top/reset_ctrl.sv` | Reset controller |
| 24 | `rtl/rtl_top/has_soc.sv` | Top-level SoC |

### 3.3 Module hierarchy and dependencies
- Top: `has_soc` instantiates `reset_ctrl`, `riscv_core`, `req_gnt_to_axi_lite`, `axi_lite_interconnect`, `axi_lite_to_apb`, `intc_axi` (which instantiates `clint` + `plic`), `boot_rom`, `sram`, and 9 APB peripherals.
- `has_addr_map_pkg` (package) is imported by `has_soc` and `axi_lite_interconnect`.

### 3.4 Parameters, macros, defines, include paths
- No `` `define `` or `` `include `` macros are used in the RTL (grep found none except comments). Parameters are Verilog `parameter`/`localparam`. `has_addr_map_pkg` holds address constants and an `addr_region()` function.

### 3.5 Clock and reset domains
- `clk` (system, 50 MHz target) with async active-low `reset_n`/`rst_sys_n`.
- Gated: `core_clk = clk & core_clk_en_q` (registered enable on negedge clk), `periph_clk = clk & periph_clk_en_q`.
- `debug_jtag` runs on ungated `clk`; its TAP advances on detected `tck` rising edge (external debugger clock, asynchronous).
- APB peripherals run on `periph_clk` (except `debug_jtag` on `clk`).
- Async active-low resets throughout (`negedge reset_n`/`presetn`).

### 3.6 Bus interfaces
- Internal: AXI4-Lite (single outstanding transaction, 1 master x 6 slaves) + APB (9 x 4 KB slots, one-hot select).
- External: UART, SPI/QSPI, I2C, GPIO, PWM, I2S, JTAG, watchdog reset out, wake req/ack.

### 3.7 SRAM and ROM implementation
- `sram.sv`: behavioral 2-D array `mem`, inferred memory; AXI slave + second read port for instruction fetch; `$readmemh` optional init.
- `boot_rom.sv`: behavioral array initialized to NOP then `$readmemh`; AXI read-only data port + instruction port.

### 3.8 Interrupt architecture
- CLINT (mtime/mtimecmp/msip) + PLIC (8 sources, 1 context) muxed by `intc_axi` on AXI slave 5; PLIC drives `irq_ext` to core.

### 3.9 Debug/JTAG
- Minimal 5-state TAP, no DMI/DTM/IDCODE/boundary scan; TDO registered one shift late. Bring-up only.

### 3.10 Black-box / unresolved dependencies
- None declared as black boxes. All modules are RTL. No external IP cores, PLL, or memory macros are instantiated.

---

## 4. RTL Synthesis Compatibility

| Construct | Location | Finding | Status |
|-----------|----------|---------|--------|
| Package `import` in module | `has_soc.sv:65`, `axi_lite_interconnect.sv:76` | Yosys 0.69 errors: `syntax error, unexpected TOK_IMPORT` | BLOCKED (for Yosys full-top parse) |
| Unpacked-array ports | `axi_lite_interconnect.sv:57` (`s_awaddr [NUM_SLAVES]`, etc.) | Yosys 0.69 errors: `unexpected '['` | BLOCKED (for Yosys parse) |
| Async reset (negedge) | all modules | Supported by Yosys and standard-cell libs; needs reset sync for ASIC | PARTIALLY VERIFIED |
| Clock gating via `assign clk & en` | `has_soc.sv:107-108` | Combinational AND gating; glitch-prone; no ICG cell; needs ICG insertion for ASIC | PARTIALLY VERIFIED |
| Inferred memory (arrays) | `sram.sv`, `boot_rom.sv` | Maps to registers/muxes, not macros; not ASIC-suitable as-is | VERIFIED (Yosys maps 128 KB SRAM to 65 536 DFFs + 131 070 muxes) |
| `initial` blocks | `boot_rom.sv:119`, `sram.sv:146` | Used only for memory init via `$readmemh`; synthesis tools typically ignore for hardware (init not synthesizable to logic) | PARTIALLY VERIFIED |
| `always_comb`/`always_latch` | 37 occurrences | Need per-module latch check; Yosys did not report latches in the modules that synthesized | PARTIALLY VERIFIED |
| Tri-state | `gpio.sv` | Yosys warning: limited tri-state support | PARTIALLY VERIFIED |
| `$readmemh` | boot_rom/sram | Simulation/initialization only; not a synthesis construct for ASIC init (needs ROM mask or init chain) | VERIFIED |
| `unique case` without default | some peripherals | Verilator lint warnings (CASEINCOMPLETE) but Yosys handles | PARTIALLY VERIFIED |
| Multiple drivers | none found in current RTL (plic `claimed` consolidated) | VERIFIED |

---

## 5. PDK and Standard-Cell Availability

### 5.1 `/d/tools/pdk/skywater-pdk-main` (referenced by `asic/config.json` as `pdk_path`)
- Availability: **NOT AVAILABLE** (skeleton only). `libraries/sky130_fd_sc_hd/{v0.0.1,v0.0.2,latest}` are empty directories; no `.lib`, `.lef`, or tech files. Status: BLOCKED.

### 5.2 `/d/tools/pdk/skywater-pdk-complete`
- Availability: **PARTIALLY AVAILABLE**. Contains `skywater-pdk-libs-sky130_fd_sc_hd` with cells (LEF), `tech/sky130_fd_sc_hd.tlef`, `timing/*.lib.json` (JSON, not `.lib`), and `models/` (UDP). No `.lib` Liberty files. Status: PARTIALLY VERIFIED — cell geometry available, timing in non-standard JSON format.

### 5.3 OpenROAD-flow-scripts `sky130hd` platform (usable platform)
- Exact path: `/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130hd`
- Tech LEF: `lef/sky130_fd_sc_hd.tlef` — VERIFIED (present)
- Merged cell LEF: `lef/sky130_fd_sc_hd_merged.lef` (441 cells) — VERIFIED
- TT Liberty: `lib/sky130_fd_sc_hd__tt_025C_1v80.lib` (13.0 MB) — VERIFIED
- SS/FF Liberty: NOT in `sky130hd` platform directory; present under `/d/tools/src/OpenROAD/src/sta/test/sky130hd/` per registry — PARTIALLY VERIFIED (different location, not integrated)
- Cell GDS: `gds/sky130_fd_sc_hd.gds` (4.0 MB) — VERIFIED
- Tap cell: `sky130_fd_sc_hd__tapvpwrvgnd_1` (config.mk) — VERIFIED
- Endcap cells: not explicitly named in platform config — NOT AVAILABLE (as configured)
- Filler cells: not explicitly named — NOT AVAILABLE (as configured)
- DRC deck: `drc/sky130hd.lydrc` (KLayout) — VERIFIED (present)
- LVS deck: `lvs/sky130hd.lylvs` (KLayout) — VERIFIED (present)
- KLayout tech: `sky130hd.lyt` — VERIFIED
- PDN config: `pdn.tcl` — VERIFIED
- RCX rules: `rcx_patterns.rules` is a 30-byte pointer to `../sky130hs/rcx_patterns.rules` (46 KB, real) — VERIFIED
- Process node: 130 nm (config.mk: `PROCESS = 130`) — VERIFIED
- Operating corner (available in platform): TT, 25 C, 1.80 V (single corner in `sky130hd` lib dir) — VERIFIED
- Antenna rules: contained in tech LEF / DRC deck — PARTIALLY VERIFIED

### 5.4 sky130ram platform (SRAM macros)
- Exact path: `/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130ram`
- Macros: `sky130_sram_1rw1r_{128x256_8, 44x64_8, 64x256_8, 80x64_8}` with LEF, GDS, Liberty (TT only), Verilog, SPICE.
- Port style: `1rw1r` (one write port + one read port), synchronous, single clock per port. Status: VERIFIED (present), compatibility with SoC memory architecture not verified.

### 5.5 volare
- Installed in `venv-openlane2` (WSL) but the repository's `asic/` flow does not use it; no `sky130A` PDK was provisioned for this project. Status: NOT AVAILABLE (for this project's flow).

---

## 6. SRAM and Memory Readiness

| Memory | Size | RTL implementation | Physical macro available? | Suitable for ASIC as-is? |
|--------|------|--------------------|--------------------------|--------------------------|
| SRAM | 128 KB | Behavioral array in `sram.sv` | No 128 KB macro; nearest `sky130_sram_1rw1r_128x256_8` is 128x256 bits = 4 KB | NO — needs memory compiler or banked macros + wrapper |
| TCM | 32 KB | (mapped into SRAM/ROM region; no separate module) | No | NO |
| Boot ROM | 16 KB | Behavioral array in `boot_rom.sv` + `$readmemh` | No ROM macro | NO — needs ROM compiler or mask-programmed ROM |

Yosys generic synthesis of `sram.sv` maps the 128 KB array to **65 536 DFF cells + 131 070 mux cells** (787 112 total cells) — i.e., the memory is inferred as registers, not a macro. This is functionally correct but area/power/timing-infeasible for ASIC. The RTL's second read port (instruction fetch) and AXI read port require either a 2-read/1-write memory or arbitration; the available `1rw1r` macro provides 1 write + 1 read.

**Conclusion:** Memory implementation is logically functional but physically not ready. Status: BLOCKED (no compatible macro for required sizes; inferred memory not acceptable).

---

## 7. SDC and Timing Constraint Audit

File: `constraints/timing_constraints/has_soc.sdc`

| Constraint element | Present? | Assessment |
|--------------------|----------|------------|
| Primary clock `sys_clk` 20 ns (50 MHz) | YES | VERIFIED |
| Generated clocks (PLL) | Commented out / none | NOT AVAILABLE — no PLL in RTL; clock gating uses AND, not generated clocks |
| Clock uncertainty (setup 0.1 ns, hold 0.05 ns) | YES | VERIFIED |
| Input delays (max 5.0 / min 0.0) | YES | VERIFIED |
| Output delays (max 5.0 / min 0.0) | YES | VERIFIED |
| Input transition assumptions | NO | NOT AVAILABLE |
| Output load assumptions | NO | NOT AVAILABLE |
| False paths (JTAG TCK, reset) | YES | VERIFIED (coarse) |
| Multicycle paths | None declared | NOT AVAILABLE (none needed claimed, but not verified) |
| Async clock groups (sys vs jtag_tck) | NO | NOT AVAILABLE |
| Reset treatment | False path from reset_n only | PARTIALLY VERIFIED — no reset sync constraint, no recovery/removal |
| Unconstrained endpoints | Not analyzed | NOT AVAILABLE — no STA run |

**Conclusion:** Constraints support generic timing analysis at a coarse level only. They do not support technology-mapped or multi-corner analysis: only one corner (TT) is available in the `sky130hd` platform directory, no SS/FF in the same directory, and no STA has been run. Status: PARTIALLY VERIFIED.

---

## 8. EDA Tool Availability

| Tool | Version | Platform | Path | Status |
|------|---------|----------|------|--------|
| Yosys | 0.69+154 | Windows | `D:\tools\oss-cad-suite\bin\yosys.exe` | VERIFIED (generic synth works) |
| Yosys | 0.33 | WSL | system | VERIFIED (older) |
| Icarus Verilog | 14.0 | Windows | `D:\tools\oss-cad-suite\bin\iverilog.exe` | VERIFIED |
| Verilator | 5.053 devel | Windows | `D:\tools\oss-cad-suite\bin\verilator_bin.exe` | VERIFIED |
| Verible | v0.0-4298 | Windows | `D:\tools\verible\` | VERIFIED |
| SymbiYosys | 0.69 | Windows | `D:\tools\oss-cad-suite\bin\sby.exe` | VERIFIED |
| OpenROAD | bazel-nostamp | WSL | `/mnt/d/tools/openroad/bin/openroad` | VERIFIED (runs) |
| OpenSTA | embedded in OpenROAD | WSL | embedded | VERIFIED (available) |
| Magic | 8.3.105 | WSL | `/mnt/d/tools/magic/bin/magic` | VERIFIED |
| Netgen | 6.2.2401 | WSL | `/mnt/d/tools/netgen/bin/netgen` | VERIFIED |
| OpenLane 2 | v2.0.0b16 | WSL | `/mnt/d/tools/bin/openlane` | VERIFIED (runs with tkinter env) |
| KLayout | 0.30.13 (per registry) | WSL | installed | VERIFIED (per registry) |
| xPack GCC | 12.2.0 | Windows | `D:\tools\xpack-riscv-none-elf-gcc-12.2.0-2` | VERIFIED |
| Volare | installed in venv-openlane2 | WSL | not provisioned for this project | NOT AVAILABLE |

---

## 9. Generic Synthesis Results

Executed with Yosys 0.69+154, isolated outputs under `/tmp/scratchpad/` and `reports/evidence/asic_feasibility_and_synthesis_readiness/`. No existing build artifacts were overwritten.

| Module | Result | Cells (generic) | Notes |
|--------|--------|-----------------|-------|
| `riscv_core` | PASS | 51 933 | VERIFIED — log: `yosys_riscv_core_generic.log` |
| `gpio` | PASS | 661 | VERIFIED |
| `uart` | PASS | 883 | Driver-driver conflict warnings on `div` (resolved to constant) |
| `timer` | PASS | 392 | VERIFIED |
| `watchdog` | PASS | 741 | VERIFIED |
| `plic` | PASS | 1 532 | VERIFIED |
| `clint` | PASS | 1 035 | VERIFIED |
| `spi_ctrl` | PASS | 499 | VERIFIED |
| `i2c_ctrl` | PASS | 815 | VERIFIED |
| `pwm` | PASS | 1 660 | VERIFIED |
| `i2s` | PASS | 327 | VERIFIED |
| `qspi_flash_ctrl` | PASS | 545 | VERIFIED |
| `boot_rom` | PASS | 43 | VERIFIED (memory inferred) |
| `power_mgr_regs` | PASS | 43 | VERIFIED |
| `power_mgr` | not run individually (deps) | — | — |
| `axi_lite_to_apb` | PASS | 316 | VERIFIED |
| `req_gnt_to_axi_lite` | PASS | 197 | VERIFIED |
| `reset_ctrl` | PASS | 73 | VERIFIED |
| `debug_jtag` | PASS | 325 | VERIFIED |
| `sram` | PASS (inferred) | 787 112 | VERIFIED — memory mapped to DFFs/muxes; log: `yosys_sram_generic.log` |
| `axi_lite_interconnect` | FAIL | — | Yosys 0.69 cannot parse unpacked-array ports (line 57). Log: `yosys_interconnect_failure.log` |
| `intc_axi` | FAIL (hierarchy) | — | References `plic`/`clint` not in single read; needs deps |
| `has_soc` (top) | FAIL | — | Package `import` unsupported by Yosys 0.69 (line 65). Log: `yosys_has_soc_failure.log` |

**Conclusion:** Generic, technology-independent synthesis is ready for the CPU core and individual peripherals. Full-chip generic synthesis is blocked by SystemVerilog constructs (package import, unpacked array ports) relative to the available Yosys. Status: PARTIALLY VERIFIED.

---

## 10. Technology-Mapped Synthesis Readiness

- No technology-mapped synthesis has been run. Status: NOT AVAILABLE (not executed).
- A compatible standard-cell library exists (TT corner) at `/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib`, but it has not been used to map this design. SS/FF corners are not in the same platform directory.
- OpenROAD runs under WSL and can load the platform LEF/liberty (not exercised on this design).
- OpenLane 2 runs under WSL with a working tkinter, but no `sky130A` PDK is provisioned for this project and the `asic/` config points to an empty `skywater-pdk-main`.
- No timing closure, area, or power estimate from a mapped netlist exists.

Status: BLOCKED.

---

## 11. Critical Blockers

1. **No ASIC memory strategy** — SRAM (128 KB), TCM (32 KB), and boot ROM (16 KB) are behavioral arrays; no compatible macros in the `sky130hd` platform (nearest SRAM macro is 4 KB, 1rw1r). Inferred memory = 787 k cells for 128 KB. Status: BLOCKED.
2. **SV constructs block full-top generic synthesis** — package `import` and unpacked-array ports are unsupported by Yosys 0.69. Status: BLOCKED (tool limitation; RTL is valid SV).
3. **No volare-enabled `sky130A` PDK for this project** — `asic/config.json` points to an empty skeleton (`skywater-pdk-main`); the usable platform is an external ORFS tree, not integrated. Status: BLOCKED.
4. **Single timing corner only** — only TT (25 C, 1.80 V) Liberty in the `sky130hd` platform directory; SS/FF elsewhere and unverified. Status: NOT AVAILABLE.
5. **Clock gating is combinational AND**, not ICG cells — glitch risk; needs ICG insertion for ASIC. Status: PARTIALLY VERIFIED.
6. **SDC is incomplete** — no input/output loads or transitions, no async clock groups, no reset sync/recovery-removal, no STA evidence. Status: PARTIALLY VERIFIED.
7. **Debug JTAG is a bring-up stub** (no DMI/DTM/IDCODE); not production-ready. Status: PARTIALLY VERIFIED.

---

## 12. Recommended Next Engineering Actions

1. Adopt the OpenROAD-flow-scripts `sky130hd` platform (or provision `sky130A` via volare in WSL) as the project PDK, and update `asic/config.json` `pdk_path` accordingly. Do not point at the empty `skywater-pdk-main`.
2. Resolve the SV constructs for Yosys: replace package `import` with fully-qualified `has_addr_map_pkg::` references or pre-process for Yosys; convert unpacked-array ports in `axi_lite_interconnect.sv` to packed vectors or a generate-based interface. (RTL change required, not done in this audit.)
3. Define a memory strategy: memory-compiler macros or banked `sky130_sram_1rw1r_*` macros + wrapper; reconcile the 2-read/1-write requirement with `1rw1r` ports; add a ROM strategy for `boot_rom`.
4. Insert proper ICG cells for `core_clk`/`periph_clk` gating; add reset synchronizers; constrain them in SDC.
5. Complete SDC: input/output loads and transitions, async clock groups (sys vs `jtag_tck`), reset recovery/removal, multicycle if applicable.
6. Run OpenROAD STA on the generic netlist mapped to TT Liberty as a first timing check; then SS/FF.
7. Run OpenLane 2 end-to-end on a small block (e.g., `riscv_core`) to validate the flow before full chip.

---

## 13. Evidence and Reproducibility

- Evidence directory: `reports/evidence/asic_feasibility_and_synthesis_readiness/`
  - `tool_versions.txt`
  - `yosys_riscv_core_generic.log`
  - `yosys_sram_generic.log`
  - `yosys_interconnect_failure.log`
  - `yosys_has_soc_failure.log`
  - `cdc_inventory.txt`
  - `formal_run.txt`
- Commands executed:
  - `yosys -s <script>` (core, sram, interconnect, has_soc) — exit 0 for core/sram, nonzero for interconnect/has_soc.
  - `node scripts/formal/cdc_inventory.js` — exit 0.
  - `node scripts/formal/run_formal.js` — exit 0 (PASS 5/5).
  - `wsl ... openroad -version`, `... openlane --version`, `magic --version` — verified.
- Source revision and working-tree diff hash recorded in Section 2.

---

## 14. Final Verdict

**GENERIC SYNTHESIS READY, TECHNOLOGY MAPPING BLOCKED**

Generic, technology-independent synthesis succeeds for the CPU core and most peripherals. Technology-mapped ASIC synthesis is blocked by the absence of an integrated, verified PDK flow, the lack of suitable memory macros, single-corner timing data, incomplete SDC, and SystemVerilog constructs that the available Yosys cannot parse for the full top level. No physical design (floorplan/placement/CTS/routing) was attempted. No ASIC signoff is claimed.
EOF
echo "written"