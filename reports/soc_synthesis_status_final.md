# Full-SoC Synthesis — Milestone Report (Native Windows, OpenLane 2)

**Design:** `has_soc` (Home-Automation-SoC)
**Date:** 2026-11-25
**Status:** ✅ **SYNTHESIS COMPLETE — NETLIST VERIFIED**
**Scope:** OpenLane Classic flow, `Yosys.JsonHeader` → `Yosys.Synthesis` (preparation + synthesis only)

This supersedes the earlier "synthesis blocked / environment blockers" status for this
repository. A gate-level netlist mapped to `sky130_fd_sc_hd` now exists, was produced by
the wrapper end-to-end, and passed automated structural verification. Physical
implementation (floorplan, placement, CTS, routing, STA signoff) was **not** run.

---

## 1. Executive Summary

The OpenLane execution wrapper was repaired and a real full-SoC synthesis was executed on
native Windows (no WSL, no bash-invoked Windows Python). Yosys 0.69 elaborated all 23 RTL
modules, mapped the design to `sky130_fd_sc_hd` standard cells with ABC, and emitted a
5.79 MB Verilog netlist plus a 29.7 MB JSON netlist.

| Result | Value |
|---|---|
| Top module | `has_soc` |
| Top-level ports | 28 |
| RTL modules elaborated | 23 |
| Standard-cell instances | **43,700** |
| Memory macro instances (blackboxes) | 3 (`sram` ×2, `boot_rom` ×1) |
| Total instances (OpenLane metric) | **43,703** |
| Unique standard-cell types | 136 |
| Flip-flop instances | 3,079 |
| Unmapped internal cells (`$_*`) | **0** |
| OpenLane `synthesis__check_error__count` | **0** |
| Netlist size | 5,786,347 bytes |
| Netlist SHA-256 | `b558b411b1e08e8425f9237d669ca648e45270e8b64e4fe306bb5a67ae355004` |
| Wall time | 10 min 51 s (20:01:24 → 20:12:16) |

The same netlist hash was produced by two independent runs, so the flow is deterministic
for this configuration.

---

## 2. Reproduce

From a normal `cmd.exe` (or Git Bash using `cmd //c`, not `cmd /c`):

```bat
cd /d D:\Home-Automation-SoC
cmd /c scripts\run_synth_has_soc.bat
```

Git Bash equivalent:

```bash
cmd //c "D:\Home-Automation-SoC\scripts\run_synth_has_soc.bat"
```

The launcher pins the native Python interpreter, the volare PDK root, the OSS CAD Suite
environment, and writes `logs/synth_native_last.log`. The wrapper always writes
`reports/synthesis_execution_summary.json` and exits non-zero unless the netlist passes the
verification checks.

---

## 3. Verification Performed

Automated by `scripts/openlane_synth_native.py` (`artifacts.netlist_checks`):

| Check | Result |
|---|---|
| Netlist file exists and is non-empty | ✅ 5,786,347 bytes |
| `module has_soc` present | ✅ |
| Top-level port count = expected 28 | ✅ |
| Standard-cell instances present | ✅ 43,700 |
| No unmapped internal cells (`$…`) | ✅ 0 |
| SRAM and ROM blackboxes instantiated | ✅ `sram`, `boot_rom` |
| OpenLane unmapped-instance metric | ✅ 0 |
| OpenLane synthesis check errors | ✅ 0 |
| `errors.log` | ✅ 0 bytes |

Yosys `stat` before technology mapping: **53,601 cells**, 49,422 wires, 59,574 wire bits,
28 ports. Post-mapping netlist: 43,700 cells across 136 cell types. Most frequent types:

| Cell | Count |
|---|---|
| `sky130_fd_sc_hd__nand2_2` | 5,390 |
| `sky130_fd_sc_hd__nor2_2` | 3,711 |
| `sky130_fd_sc_hd__buf_1` | 3,198 |
| `sky130_fd_sc_hd__or2_2` | 3,173 |
| `sky130_fd_sc_hd__dfrtp_2` | 2,978 |

Warnings: 7 unique messages / 13 total, none fatal. Notable ones are documented as
limitations below. One ABC message, `ABC: Error: The network is combinational.`, is emitted
for a clock domain with no sequential elements and did not abort the flow; the wrapper
filters it from the error list and `final/metrics.json` reports zero check errors.

---

## 4. Hierarchy

The written netlist is flattened (`flatten` in the synthesis script), so it defines only
`module has_soc`; submodule boundaries are intentionally removed, while the two memory
macros remain as blackbox instances. The elaborated pre-flatten hierarchy is:

```
has_soc
├── riscv_core
├── axi_lite_interconnect
│   └── axi_lite_to_apb, req_gnt_to_axi_lite, intc_axi
├── clint
├── plic
├── debug_jtag
├── reset_ctrl
├── qspi_flash_ctrl
├── uart
├── spi_ctrl
├── i2c_ctrl
├── gpio
├── pwm
├── timer
├── watchdog
├── i2s
├── power_mgr
│   └── power_mgr_regs
├── sram        (blackbox, 2 instances: sram_inst, tcm_inst)
└── boot_rom    (blackbox, 1 instance: rom_inst)
```

The elaboration database is preserved as `01-yosys-jsonheader/has_soc.h.json` (4.3 MB).

---

## 5. Toolchain and Configuration

| Item | Value |
|---|---|
| Host | Windows, native `cmd.exe` (no WSL) |
| Python | `C:\Users\91846\.local\bin\python3.12.exe` |
| OpenLane | 2.0.0b16 source at `D:\tools\openlane2` |
| Flow | Classic, `frm=Yosys.JsonHeader`, `to=Yosys.Synthesis` |
| PDK root | `C:/Users/91846/.volare/volare/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af` |
| PDK / SCL | `sky130A` / `sky130_fd_sc_hd` |
| Yosys / ABC | Yosys 0.69+154, ABC 1.01 (`D:\tools\oss-cad-suite`) |
| Clock | `CLOCK_PORT=clk`, `CLOCK_PERIOD=20.0` ns (ABC delay target only) |
| Synthesis strategy | `SYNTH_STRATEGY="AREA 0"` |
| Memory handling | `sram.sv` and `boot_rom.sv` supplied via `EXTRA_VERILOG_MODELS` and read as blackboxes |

No shared OpenLane installation files were modified. Two project-local copies are used:

- `scripts/tcl/yosys_synthesize_win.tcl` — OpenLane synthesis script with `abc -fast`
  replaced by `abc` (Yosys 0.69 removed `-fast`) and an explicit `-exe` shim.
- `scripts/abc_shim.bat` — invokes `yosys-abc.exe` with `%*`; used for all 106 ABC calls.

---

## 6. Defects Found and Fixed

| Symptom | Root cause | Fix |
|---|---|---|
| `no files matched glob pattern ".../lef/*.lef"` | Tcl consumed Windows `\` as escapes in environment/paths | Normalize non-OS environment values to `/` before Tcl evaluation |
| `TypeError: environment can only contain strings` | `psutil.Popen` received `PathLike` env values from OpenLane | Convert `PathLike` values in `Step.run_subprocess`; preserve OS variable values |
| `Parameter core.RESET_PC with non-constant value!` | `ADDR_*` macros used without backticks, so they were parsed as identifiers | Backtick-qualify macro uses in `rtl/rtl_top/has_soc.sv`; values verified against `has_addr_map.vh` |
| `Command syntax error … > abc -fast` | Yosys 0.69 removed ABC's `-fast` option | Project-local synthesis Tcl uses `abc` |
| `ABC: The syntax of the command is incorrect.` inside the flow | Windows `cmd` parsing of Yosys's in-flow ABC command line | Route ABC through `abc -exe …/abc_shim.bat`; 106/106 invocations succeeded |
| Synthesis expanded to ~1.44 M flip-flops and ran >10 min | `MEMORY_MAP` tried to synthesize SRAM/ROM arrays | Keep SRAM/ROM as blackbox macro instances via `EXTRA_VERILOG_MODELS` |

Only one RTL edit was made for synthesis in this session (macro qualification in
`has_soc.sv`). Other uncommitted diffs in that file and in `axi_lite_interconnect.sv`
predate this milestone and were not introduced here. No SDC changes were required.

---

## 7. Artifacts (Run `synth_20261125_200125`)

| Path | Size |
|---|---|
| `runs/synth_20261125_200125/01-yosys-jsonheader/has_soc.h.json` | 4,299,795 B |
| `runs/synth_20261125_200125/01-yosys-jsonheader/yosys-jsonheader.log` | 140,374 B |
| `runs/synth_20261125_200125/02-yosys-synthesis/has_soc.nl.v` | 5,786,347 B |
| `runs/synth_20261125_200125/02-yosys-synthesis/has_soc.nl.v.json` | 29,655,777 B |
| `runs/synth_20261125_200125/02-yosys-synthesis/yosys-synthesis.log` | 855,134 B |
| `runs/synth_20261125_200125/02-yosys-synthesis/hierarchy.dot` | 97,620 B |
| `runs/synth_20261125_200125/02-yosys-synthesis/post_techmap.dot` | 21,469,179 B |
| `runs/synth_20261125_200125/final/nl/has_soc.nl.v` | 5,786,347 B |
| `runs/synth_20261125_200125/final/metrics.json` | 127 B |
| `runs/synth_20261125_200125/errors.log` | 0 B |
| `reports/synthesis_execution_summary.json` | 5,721 B |
| `reports/yosys_env_dump.json` | 18,088 B |
| `reports/abc_shim.log` | 106 invocations |
| `logs/synth_native_last.log` | 1,000,046 B |

`final/metrics.json`:

```json
{
  "design__instance__count": 43703,
  "design__instance_unmapped__count": 0,
  "synthesis__check_error__count": 0
}
```

---

## 8. Limitations — What This Result Does Not Prove

1. **SRAM and ROM are blackboxes, not gate-mapped.** The netlist instantiates `sram` ×2 and
   `boot_rom` ×1 as unresolved macros. Their area, timing, power, and bit-cell correctness
   are outside this netlist. Hardened macros (e.g. OpenRAM) are required before PnR/tapeout.
2. **Register file and PLIC priority array became flip-flops.** Yosys reported
   `Replacing memory \rf with list of registers` (`riscv_core.sv:596`) and
   `Replacing memory \prio with list of registers` (`plic.sv:101`). That is legal synthesis,
   but it inflates the 3,079 flip-flop count and is not a memory-macro implementation.
3. **No physical implementation or signoff.** Placement, CTS, routing, DRC, LVS, antenna,
   IR-drop, and multi-corner STA were not run. `synthesis.sdc` contains only a driving cell
   and load; `CLOCK_PERIOD=20 ns` is an ABC optimization target, not a signoff constraint.
4. **Native physical tools remain unavailable on Windows.** The `openroad` and `sta`
   binaries in the local tool tree are Linux ELF executables. Physical stages require a
   Linux/WSL2 environment or native Windows builds; they were not attempted here.
5. **No equivalence check / simulation of the netlist.** Verification is structural
   (top module, ports, mapped cells, no unmapped primitives, macro instances) plus OpenLane's
   own synthesis metrics. Gate-level simulation and formal equivalence are follow-up work.
6. `warnings.log` contains two psutil messages (`process no longer exists`) from the runner;
   they are tooling noise, not design warnings.

---

## 11. Phase 5.3B Reconciliation — Verified Real-Macro Netlist `be827aa...`

This report documents the **frozen behavioural-baseline run** `synth_20261125_200125`
(netlist SHA `b558b411b1e08e8425f9237d669ca648e45270e8b64e4fe306bb5a67ae355004`,
5,786,347 bytes, 43,703 instances, `sram` behavioural blackbox ×2 + `boot_rom` ×1).
It is preserved unchanged.

A later, separate synthesis run produced the **verified real-macro netlist**
`synth_20261125_234131` (netlist SHA `be827aa676c3a1d5e52755abc1d642a6df264d689e7e0a482128bc4dee23eddd`,
6,942,361 bytes), in which the behavioural `sram` blackbox was replaced by **80 real
`sky130_sram_2kbyte_1rw1r_32x512_8` macro instances** (64 SRAM + 16 TCM) plus 1
`boot_rom`, with 47,432 standard cells and 142 unique cell types. That run is the
current verified synthesis baseline; it is documented in
`reports/phase5_3b_report.md` and `reports/synthesis_execution_summary.json` and
preserved in `artifacts/synthesis/2026-11-25_synth_20261125_234131/`.

No RTL or synthesis configuration was changed between the two runs except the memory
macro model/instance topology (behavioural `sram` → real `sky130_sram_2kbyte_1rw1r_32x512_8`),
and the wrapper RTL that instantiates the real macros (`sram_macro_wrap.sv`,
`tcm_macro_wrap.sv`). The Phase 5.3A frozen baseline remains a valid preserved artifact;
the Phase 5.3B verified netlist supersedes it as the current synthesis state.

---

## 9. Preserved Block-Level Baseline

These metrics come from prior block-level (timer) work and were **not re-run** in this
milestone; they are recorded here so the full-SoC result does not obscure them.

| Metric | Result |
|---|---|
| Block-level DRC | 0 violations |
| Block-level antenna | 0 violations |
| Block-level STA WNS | 37.42 ns (tt_025C_1v80) |
| Block-level hold slack | 0.48 ns |
| Verilator | 0 errors, 279 warnings |
| Icarus regression | 22/22 pass |
| Formal verification | 5/5 pass |
| SDC endpoint coverage | 35/35 constrained or justified |

---

## 10. Recommended Next Steps

1. Harden `sram` and `boot_rom` as real sky130 macros (OpenRAM or foundry memory compiler)
   and replace the blackbox instances; re-run this synthesis to obtain a fully resolved netlist.
2. Run OpenLane physical implementation on Linux/WSL2 from `has_soc.nl.v` / `has_soc.nl.v.json`
   (or re-synthesize natively there), with the approved signoff SDC.
3. Add gate-level simulation and equivalence checking between RTL and `has_soc.nl.v`, and
   resolve the register-file/PLIC memory inference decision (flops vs. macro).
