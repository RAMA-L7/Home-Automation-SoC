# RUN-0029 — MUL critical-path attribution (negative result)

Date: 2026-11-27/28 (UTC). Baseline: published `83b7e01` (RUN-0028 postfix).
Tool flow: Yosys 0.69+154, OpenSTA 3.1.0, `sky130_fd_sc_hd` tt/25 °C/1.80 V,
same `has_soc.sdc` (sha256 `6abd7b41…`), same ABC constraints.

**Verdict: the remaining 21.00 ns path is not the multiplier.** It is the
single-cycle `pc → operand mux → ALU adder → address-alignment/exception →
pc_next` loop, whose endpoint flop holds `core.pc[31]` and whose startpoint flop
holds `core.pc[2]`. Zeroing all three `prod_*` multipliers makes WNS *worse*,
and the slowest multiply variant needs only ~12.7 ns against a 19.79 ns
requirement when built standalone. **No RTL was changed in this run.**

| Experiment | WNS setup | TNS setup | Cells |
|---|---:|---:|---:|
| Baseline `83b7e01` (reproduced) | **−1.2141 ns** | **−107.66 ns** | 44,252 |
| All three multipliers zeroed | −1.8206 ns | −1110.91 ns | 32,314 |
| Only `prod_uu` kept (1 of 3) | −2.2110 ns | −2289.03 ns | 37,901 |
| ALU adder zeroed | −1.2007 ns | −1051.42 ns | 44,723 |
| MULHU standalone probe | +7.0888 ns slack | 0.00 | — |

Register count is 3,594 in every variant, so all experiments are purely
combinational and no state was added or removed.

## 1. Question

RUN-0028's §9.3 recorded a 21.0033 ns worst path with 23 `maj3`, 6 `mux2` and
no SRAM instance, and said the multiply was *consistent with* being the cause
but unproven. This run asked: is the MUL cone the limiter, and if so which of
MUL / MULH / MULHSU / MULHU?

## 2. Method

1. Re-map the current RTL with the project's own synthesis template
   (`scripts/sta/synth_has_soc.ys`, `rtl/filelist.f`) and resolve the worst path
   to RTL names.
2. Three controlled ablations, each a throwaway core variant built by that same
   template and timed by the same OpenSTA script: no multipliers
   (`nomul`), one multiplier (`uuonly`), no ALU adder (`noadd`).
3. A standalone probe that registers operands and results around one copy of
   each variant, so flop → multiplier → flop can be measured on its own.

`run_synth_sta.sh` synthesizes on Windows (Yosys is native) and hands the
netlist to `sta_only.sh` inside WSL (OpenSTA is a Linux ELF); both halves use
the same liberty set, SDC and ABC options as `node scripts/eda/run_sta.js`.

## 3. The measured critical path, resolved to RTL

Startpoint `_64744_` (holds `core.pc[2]`) → endpoint `_66077_` (holds
`core.pc[31]`), 21.0033 ns, 57 gates. Resolved by parsing the netlist Yosys
writes *with* attributes (`build/sta/has_soc_gate_srcattr.v`), whose escaped
bus names (`\core.pc [2]`, `\core.alu_a [2]`, …) survive into the timing path.

| Segment | Arrival | Cost | RTL anchor |
|---|---:|---:|---|
| Clock-to-Q, `core.pc[2]` | 0.3109 | 0.31 | `pc` flop |
| Two `clkbuf_1` on the pc net | 5.1793 | 4.87 | `pc` fanout (86-pin aggregate reported by OpenSTA) |
| `alu_a` operand mux (`pc` vs `rs1_val`) | 5.8333 | 0.65 | `assign alu_a = … ? pc : rs1_val;` |
| 23-cell `maj3` carry chain | 14.9313 | 9.10 | `wire [XLEN-1:0] alu_add = alu_a + alu_b;` |
| Address-alignment / exception muxing | 19.4129 | 4.48 | `assign mem_misaligned = … alu_out[1:0] …` → exception mux |
| `pc_next` select to the flop's D | 21.0033 | 1.59 | `assign pc_next = (opcode == OP_JAL) ? (pc + imm_j) : …` |

Cell mix on the path: 23 `maj3`, 6 `mux2`, 5 `clkbuf_1`, 1 `clkinv`, 1 `buf`,
and the rest two-input AOI/OAI glue. There is no `$mul`, and no cell in the
multiplier cone, anywhere on it.

The loop is closed at the RTL level: `mem_misaligned` is derived from
`alu_out`, the exception path feeds the state/pc update, and `pc` is written
from `pc_next` (`pc <= pc_next`). That is a complete fetch → execute →
pc-update combinational loop inside one clock period.

## 4. Ablations

Each variant differs from `rtl/rtl_top/riscv_core.sv` (sha256 `d48f839d…`) by
exactly the lines shown by `diff` in `logs/ablation_diffs.txt`; nothing else in
the tree was touched.

**No multipliers** (`ablation/riscv_core_nomul.sv`): the three `prod_*` wires
are driven with constants. Result: WNS −1.8206 ns, TNS −1110.91 ns — *worse*
than baseline, while 11,938 cells (the three array multipliers) disappear. The
new critical path starts at a different flop, so the deficit did not move into
the multiplier; it was never there.

**One multiplier** (`ablation/riscv_core_uuonly.sv`): only `prod_uu` is kept
(−6,351 cells). WNS −2.2110 ns, TNS −2289.03 ns. Removing two multipliers buys
area, not time: the three products are parallel, so their depth is the depth of
one, and it was never the maximum.

**No ALU adder** (`ablation/riscv_core_noadd.sv`): `alu_add` is tied to zero,
which removes the carry chain the path spends 9.10 ns in. WNS barely moves
(−1.2007 ns) and TNS degrades 10× (−1051.42 ns). This is the important
negative control: it shows the 1.2 ns deficit is *distributed* over hundreds of
near-critical endpoints, not carried by one removable cone. ABC's global
re-partitioning moves the maximum elsewhere whatever single cone is deleted, so
an ablation alone cannot attribute a path — the named path in §3 is what does.

## 5. Standalone characterisation of the four RV32M variants

`probe/mul_probe.sv` registers operands and each product, is mapped with the
same liberty/ABC configuration, and is timed with `probe/probe.sdc`
(20 ns clock, 0.1 ns setup uncertainty). Result: **PASS**, WNS +7.0887 ns, hold
+0.5289 ns.

| Variant | Endpoint | Setup slack @ 50 MHz |
|---|---|---:|
| MULHU (`prod_uu[63:32]`) | `mulhu_uu[30]`, `[31]`, `[29]` — the three worst paths | +7.0887 / +7.1600 / +7.3242 ns |
| MUL (`prod_uu[31:0]`) | not in the worst three | > +7.32 ns |
| MULH (`prod_ss[63:32]`) | not in the worst three | > +7.32 ns |
| MULHSU (`prod_su[63:32]`) | not in the worst three | > +7.32 ns |

So the slowest variant (MULHU) needs ≈12.7 ns including clock-to-Q and setup
against a 19.79 ns requirement: about 7 ns of margin, alone. Even if MUL were
removed entirely, the core is still bounded by the §3 loop.

## 6. What the evidence shows

* The multiply is **not** on the critical path, and not close to it.
* The bottleneck is the single-cycle `pc → ALU → exception → pc_next` loop:
  9.10 ns of adder, 4.87 ns of pc-net buffering, 4.48 ns of alignment/exception
  logic, 1.59 ns of pc_next mux, 0.65 ns of operand mux.
* The 1.2 ns deficit is also spread across 574 endpoints (509 of them within
  1 ns), so no single hunk of RTL closes it.
* Consequence: a 32-cycle or pipelined MUL — the obvious next move if the
  hypothesis had been right — would have cost ISA-retirement risk for zero
  timing gain. That work is **not** justified by this evidence.

## 7. Rejected experiment, kept as a flow check

An attempt to bit-blast only the `core.pc` bus (`bitblast_bus.py`) briefly
reported WNS +0.7128 ns. It was wrong: the first version handled single-bit
selects but left `\core.pc [10:2]` part-selects pointing at a removed net, which
silently dropped real loads. With part-selects expanded
(`{pc_bit_10, …, pc_bit_2}`) the result returns to exactly −1.2141488158527418 /
−107.65510743128912, bit-for-bit identical to the baseline. Two conclusions:
the flow is sound, and the 4.87 ns spent on the pc net is what the model
actually sees, not a name-parsing artifact. A full-name-sanitised copy of the
netlist (`sanitize_names.py`, 1,014 identifiers, no collisions) also reproduces
the baseline exactly.

## 8. What this run does not change

* No RTL, constraint, script or library was modified; `git diff -- rtl/` is empty.
* RUN-0027 and RUN-0028 numbers stand.
* 50 MHz still fails: WNS −1.2141 ns, TNS −107.66 ns, 574 endpoints.
* Recommendation for the next phase (not done here): target the loop, not the
  multiplier — e.g. an explicit parallel-prefix adder for `alu_add` and a real
  buffer strategy for the 86-load pc net, each still one isolated change with
  its own equivalence bench. Anything that changes when `pc` updates is an
  architectural change and needs the retirement semantics tested explicitly.

## 9. Reproduction

```bash
# ablation netlist + STA (tag = nomul | uuonly | noadd)
bash research/runs/RUN-0029-mul-attribution-2026-11-27/run_synth_sta.sh \
     research/runs/RUN-0029-mul-attribution-2026-11-27/ablation/riscv_core_nomul.sv nomul

# standalone multiplier probe
yosys -s research/runs/RUN-0029-mul-attribution-2026-11-27/logs/probe.ys
MSYS_NO_PATHCONV=1 wsl bash /mnt/d/Home-Automation-SoC/research/runs/RUN-0029-mul-attribution-2026-11-27/probe_sta.sh
```

## 10. Artifacts

| File | What it is |
|---|---|
| `ablation/riscv_core_{nomul,uuonly,noadd}.sv` | the three core variants (full files, for reproduction) |
| `probe/mul_probe.sv`, `probe/probe.sdc` | standalone four-variant probe |
| `run_synth_sta.sh`, `sta_only.sh`, `probe_sta.sh`, `probe_net.sh` | runners |
| `sanitize_names.py`, `bitblast_bus.py` | netlist-rename experiments of §7 |
| `logs/synth_*.log.gz` | Yosys logs for every variant |
| `logs/sta_{nomul,uuonly,noadd,sanitized,pcb,pcb2x,probe}.log` | OpenSTA logs |
| `logs/path_breakdown.txt` | per-node arrival/delay table of §3 |
| `logs/fanout.txt` | highest-fanout named nets |
| `logs/ablation_diffs.txt` | exact diff of each variant vs tracked RTL |
| `logs/net_probe.tcl`, `logs/net_probe.log` | OpenSTA net/pin query used in §7 |
| `manifest.json`, `commands.jsonl` | hashes and command log |

Netlists stay in `build/sta/` (not committed); their sha256 values are in
`manifest.json` and each ablation is reproducible from the variant file plus
`run_synth_sta.sh`.
