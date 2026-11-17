# ASIC Synthesis Readiness Report — Home-Automation-SoC

**Date:** 2026-11-17 (correction pass)
**Yosys:** 0.69+154 (git sha1 `30d62572e-dirty`, Release)
**Icarus Verilog:** 14.0
**Technology:** SkyWater Sky130 HD, subset library `build/asic_evidence/sky130_full_subset.lib` (32 cells, TT 25 °C 1.80 V)
**Status:** mapping now **correct and complete for standard cells**. Full-SoC mapping finishes with `check` reporting **0 problems**; the only remaining unmapped leaf cells are the three `$mem_v2` memories (no Sky130 RAM macro of that size). No timing, area or physical signoff is claimed.

---

## 1. What was wrong, and what changed

An external review found that the previous mapping results could not be trusted.
Each finding is listed with the fix that was applied.

| # | Finding | Fix |
|---|---------|-----|
| 1 | `dfrtp_2` / `dfrtp_4` were treated as 2-bit / 4-bit registers. The suffix is **drive strength**; every sky130 HD flop has scalar `D`/`Q`. | `sky130_map.v` now instantiates one scalar cell per bit. The 4-bit `arith_test.y` register is 4 × `dfrtp_1`. |
| 1 | `and2_1` was wired through `.Y(...)`, but the library pin is `X`. | All combinational pins now come from the library: and/or/xor/buf/mux → `X`; nand/nor/inv → `Y`. |
| 1 | The simulation stubs declared vector ports for `dfrtp_2/4`, hiding the bug. | `sky130_stub.v` rewritten with the exact library pins, all sequential cells scalar. |
| 2 | The `$dff` template had an `R` port; Yosys `$dff` has only `CLK/D/Q`, so it never matched. | `$dff` is now `(CLK, D, Q)` and maps to `dfxtp_1`. |
| 2 | `$adff` declared `ARST_VALUE` but ignored it, forcing reset-to-0. | Reset-to-0 → `dfrtp_1` (`RESET_B`), reset-to-1 → `dfstp_1` (`SET_B`). Polarity inversion handled once per instance. |
| 2 | `$logic_and` / `$logic_or` fed wide operands into scalar pins. | Both now reduce each operand to a boolean first, then use a 2-input gate. |
| 2 | `$eq` / `$ne` / `$logic_not` / `$not` mishandled widths (bitwise-XNOR for `$eq`, bitwise-NOT for `$logic_not`). | Operands are extended to the result width and compared/reduced with explicit gate chains. |
| 3 | `tb_equiv.v` compared RTL against RTL when `USE_MAPPED` was absent, and used `$finish` on mismatch (exit status 0). | `USE_MAPPED` is mandatory (`$fatal(1)` otherwise); every mismatch calls `$fatal(1, ...)`. A `CORRUPT_MAP` build injects a single-bit error and is expected to fail. |
| 4 | The 3-module log carried 80 warnings, including undriven `$and` outputs and undriven register bits, and kept `$add`/`$sub`. | Root causes fixed (see §3); `check -assert` now reports 0 problems and no generic cells remain. |
| 4 | Scripts used absolute `D:/Home-Automation-SoC/...` paths. | All scripts are repository-relative and run from the repo root. |
| 4 | `$add`/`$sub` were declared unmappable ("no adder cells"). | Arithmetic is decomposed into ordinary gates (ripple-carry with xor2/and2/or2). No adder cell is needed. |
| 4 | `uart.sv` drove `div` from two `always_ff` blocks. | Reset of `div` moved into the APB register block that writes it; the divider block no longer touches `div`. |
| 5 | I²C never transmitted `tx_data`, and the read "NACK" drove SDA low. | Write path now sends the data byte after the address ACK; the read NACK releases SDA (high). A slave-model testbench verifies it. |

---

## 2. Environment

| Item | Version / Path |
|---|---|
| Yosys | 0.69+154, `/d/tools/oss-cad-suite/bin/yosys.exe` (needs `environment.bat`) |
| Icarus Verilog | 14.0, `/d/tools/oss-cad-suite/bin/iverilog.exe` |
| Sky130 library | `build/asic_evidence/sky130_full_subset.lib` (32 cells) |
| Map file | `build/asic_evidence/sky130_map.v` |
| Cell models (simulation) | `build/asic_evidence/arith_work/sky130_stub.v` |

`read_liberty` has to run **after** `hierarchy -top`, otherwise `hierarchy`
deletes the unused cell modules and the techmap instances then reference missing
modules — which is exactly what produced the earlier "used but has no driver"
warnings. The library is read with `-lib` so the cells are blackboxes and `stat`
reports leaf instances.

---

## 3. Mapping flow

```bash
# from the repository root, in a shell where `call environment.bat` has run
yosys -s build/asic_evidence/arith_work/synth_3mods.ys   # 3 flat modules
yosys -s build/asic_evidence/arith_work/synth_soc.ys     # full SoC, hierarchical
yosys -s build/asic_evidence/arith_work/synth_ops.ys     # mul/div/mod/shift/neg proof
yosys -s build/asic_evidence/arith_work/synth_cmp.ys     # comparator proof
```

Per module the flow is:

```
read_verilog -sv <rtl>
hierarchy -check -top <top>
proc; flatten; opt_clean          # (full SoC: no flatten — see §5)
read_liberty -lib build/asic_evidence/sky130_full_subset.lib
techmap -map +/techmap.v          # standard expansion (mul/div/mod/shift/neg)
techmap -map build/asic_evidence/sky130_map.v
techmap -map build/asic_evidence/sky130_map.v   # second pass for new cells
hierarchy -check; opt_clean
check -assert
stat
```

The map file now covers word-level cells (`$not`, `$and`, `$or`, `$xor`,
`$reduce_*`, `$logic_*`, `$eq`, `$ne`, `$lt`, `$le`, `$gt`, `$ge`, `$mux`,
`$pmux`, `$dff`, `$adff`, `$add`, `$sub`) **and** the gate primitives produced
by `+/techmap.v` (`$_NOT_`, `$_AND_`, `$_OR_`, `$_XOR_`, `$_NAND_`, `$_NOR_`,
`$_XNOR_`, `$_ANDNOT_`, `$_ORNOT_`, `$_MUX_`, and the `$_DFF_*` family).
Anything not covered stays visible in `stat`/`check` rather than being silently
mapped to the wrong cell.

---

## 4. Measured results

### 4.1 Flat 3-module mapping (definitive)

`check -assert` reports **0 problems** for all three; no generic cells remain.

| Module | Sky130 cells | Breakdown | Unmapped |
|---|---|---|---|
| `arith_test` | **93** | and2_1×16, dfrtp_1×4, inv_1×9, mux2_1×20, or2_1×22, xor2_1×22 | none |
| `reset_ctrl` | **93** | and2_1×15, dfrtp_1×9, inv_1×11, mux2_1×27, or2_1×15, xor2_1×16 | none |
| `watchdog` | **1036** | and2_1×69, dfrtp_1×68, inv_1×50, mux2_1×429, or2_1×244, xor2_1×176 | none |

The previous numbers (42 / 43 / 628 with `$add`/`$sub` left over) were produced by
the broken map: the `arith_test` 4-bit register was mapped onto a single scalar
`dfrtp_4`, leaving three output bits undriven, and the AND/MUX paths used wrong
pin names.

### 4.2 Equivalence (`tb_equiv.v`, 24-pattern sweep → 1028 checks)

| Build | Result | Exit |
|---|---|---|
| `-DUSE_MAPPED` | `PASS: 1028 checks, RTL and mapped netlist agree` | 0 |
| no `USE_MAPPED` | `FATAL: tb_equiv requires -DUSE_MAPPED` | 1 |
| `-DUSE_MAPPED -DCORRUPT_MAP` | `FATAL: equivalence check failed` | 1 |

The corruption control is the important line: a deliberately damaged mapped
netlist must fail, otherwise the harness is not comparing anything.

### 4.3 Arithmetic expansion proof (`ops_test`)

`$mul`, `$div`, `$mod`, `$neg`, `$shl`, `$shr`, `$sra` on 8-bit operands,
synthesized through `+/techmap.v` + the Sky130 map, simulated exhaustively:

- mapped design: 4531 cells, all Sky130, `check` 0 problems
- `PASS: 65536 arithmetic-op checks`

### 4.4 Comparator proof (`cmp_test`)

`$lt`, `$gt`, `$le`, `$ge` on signed and unsigned 4-bit operands, exhaustive:

- mapped design: 204 cells, all Sky130, `check` 0 problems
- `PASS: 256 comparator checks (signed+unsigned)`

---

## 5. Full-SoC result

`synth_soc.ys` maps the whole SoC hierarchically (no `flatten`, which is what
previously died with `std::bad_alloc` when the behavioural SRAM expanded to
~65 k flops + ~131 k muxes).

- `check`: **0 problems** (was 18, including conflicting drivers on `uart.div`)
- conflicting-driver warnings: **0** (was 16)
- unmapped leaf cells: only `$mem_v2` — the boot ROM and the two SRAMs
- top module `has_soc`: 2454 local cells + 21 submodule instances

Hierarchical, **unoptimized** gate-level counts (sum over module bodies, before
any ABC/area optimisation):

| Cell | Count |
|---|---|
| and2_1 | 191,602 |
| xor2_1 | 111,932 |
| or2_1 | 100,166 |
| mux2_1 | 84,276 |
| inv_1 | 29,280 |
| dfrtp_1 | 6,484 |
| dfstp_1 | 180 |

**These are not PPA figures.** They are a correctness/mapping-coverage result.
`riscv_core` alone is ~218 k cells because `+/techmap.v` expands 64-bit
`$mul`/`$div` into gates; a real implementation would use ABC plus dedicated
multiply/divide IP and would be far smaller. No timing or area optimisation has
been run.

---

## 6. Remaining blockers

| Blocker | Impact | What is needed |
|---|---|---|
| No Sky130 RAM macro ≥ 64 KB | TD-006 (TCM/SRAM) stays as `$mem_v2` | A memory compiler / banked macros plus wrapper RTL |
| No SR-latch cell in the subset | `$sr` cells stay unmapped | Add an SR-latch cell to the library subset, or rewrite the sticky-bit logic |
| ABC `-liberty` broken in this Yosys build | no technology-mapped area/timing | fix/replace ABC, or run a full OpenLane/OpenROAD flow |
| Back-end tools not runnable on this shell | no place/route, DRC/LVS, GDS | run OpenROAD/Magic/Netgen inside WSL |

Cell counts in §5 exist only because the memory macros are treated as black
boxes; a placed-and-routed design also needs the memory substitution above.

---

## 7. Functional fixes verified in simulation

### 7.1 I²C master (`rtl/rtl_peripherals/i2c_ctrl.sv`)

`sim/sim_top/tb_i2c_xfer.v` drives a reactive slave model (ACK, read data, NACK)
and checks the actual bus bytes.

| Case | New RTL | Old RTL |
|---|---|---|
| WRITE: `0xA0`, `0x5A`, ACK, STOP | pass | fails ("DATA byte was not transmitted") |
| READ: `0xA1`, `0x3C`, NACK released, STOP | pass | fails (received byte wrong) |
| Address NACK: `ack_error=1`, no data byte, STOP | pass | fails |
| Overall | `ALL TESTS PASSED` | 4 failures |

Two further defects were found while fixing this and are also corrected:

- the bus outputs were registered from the phase branches, so every SCL/SDA
  change was one clock late — the first data bit was never driven and the
  receive sample point was misaligned. SCL/SDA are now combinational functions
  of `(state, quarter)`.
- the receive bit counter advanced at the sampling phase, so the last-bit test
  never fired. It now advances on the closing phase.

### 7.2 UART (`rtl/rtl_peripherals/uart.sv`)

`div` was assigned by two `always_ff` blocks (the divider's reset branch and the
APB write block). Synthesis reported conflicting drivers for every `uart.div`
bit. The reset assignment moved into the APB block; conflicting drivers are now
zero.

---

## 8. Reproduction

```bash
# mapping + counts
yosys -s build/asic_evidence/arith_work/synth_3mods.ys
yosys -s build/asic_evidence/arith_work/synth_soc.ys

# equivalence (three outcomes)
cd build/asic_evidence/arith_work
iverilog -g2012 -s tb_equiv -DUSE_MAPPED -o tb_eq_pass.vvp \
         tb_equiv.v ../arith_test.v arith_test_mapped.v sky130_stub.v
vvp tb_eq_pass.vvp                      # exit 0, PASS
# omit -DUSE_MAPPED  -> exit 1
# add -DCORRUPT_MAP  -> exit 1

# arithmetic and comparator proofs
yosys -s synth_ops.ys ; yosys -s synth_cmp.ys
iverilog -g2012 -s tb_ops -o tb_ops.vvp tb_ops.v ops_test_mapped.v sky130_stub.v && vvp tb_ops.vvp
iverilog -g2012 -s tb_cmp -o tb_cmp.vvp tb_cmp.v cmp_test_mapped.v sky130_stub.v && vvp tb_cmp.vvp

# I2C transactions
cd ../../..
iverilog -g2012 -s tb_i2c_xfer -o sim/sim_top/tb_i2c_xfer.vvp \
         sim/sim_top/tb_i2c_xfer.v rtl/rtl_peripherals/i2c_ctrl.sv
vvp sim/sim_top/tb_i2c_xfer.vvp
```

Logs: `build/asic_evidence/arith_work/synths3_fixed.txt`,
`synth_soc_fixed.txt`, `synth_ops.log`, `synth_cmp.log`,
`tb_eq_{pass,nouse,corrupt}.log`.
