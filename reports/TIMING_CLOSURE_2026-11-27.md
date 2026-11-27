# Timing closure investigation — critical path attributed and broken

**Run:** `research/runs/RUN-0027-timing-closure-2026-11-27`
**Baseline (unchanged, still published):** `09e2eaa` — WNS setup `−106.4775 ns`
**Engine:** OpenSTA 3.1.0 (WSL2), Yosys 0.69+154, sky130_fd_sc_hd TT 1.8 V / 25 C
**Result:** WNS `−106.4775 ns` → `−8.4509 ns`; TNS `−104736.49 ns` → `−848.81 ns`.
Timing still **FAILS** at 50 MHz. One defect was fixed; the design is not closed.

**Follow-up (RUN-0028, same day, same SDC/tools):** the Rank 1 bank-read select
was replaced with an indexed select — WNS `−8.4509 ns` → `−1.2141 ns`, TNS
`−848.81 ns` → `−107.66 ns`, and every endpoint below −5 ns is gone. 50 MHz
still fails. See §9.

This report is the investigation the second external review asked for: extract
the worst paths, cluster the failing endpoints, name the dominant cause, rank
the bottlenecks, make one evidence-supported change, and measure it before and
after. It does not claim signoff, and it does not change the deadline.

---

## 1. Method

The release gate (`scripts/eda/run_sta.js`) reports three paths, which is enough
to pass or fail a build but not enough to rank bottlenecks: WNS is one path,
while TNS is a sum over every failing endpoint. A read-only analysis script
(`scripts/sta/has_soc_path_analysis.tcl`, new) now enumerates up to N paths in
one-line form, emits the top 50 as JSON with both startpoint and endpoint, and
reports design-rule violations. Clustering is read directly from the JSON and
the one-line reports; no second tool was added.

All numbers below are from the same mapped netlist the release gate measured,
with the same unmodified SDC. Nothing in the SDC was relaxed: no new exception,
no clock-group change, no multicycle. The 20 ns clock, 100 ps setup uncertainty,
2 ns JTAG CDC bound and two documented exceptions are exactly as published.

| Artifact | SHA-256 |
|---|---|
| Baseline netlist `has_soc_gate.v` (09e2eaa) | `f9cdd8338c12a22fc35b3433eb68f0c4dfeb589326d4090c8ff67d07eba7252b` |
| Post-fix netlist | `16d833870fb7fefbea6a7f54c7c0b05a6fa622618f2cf8555b54dc1c18fa45af8` |
| SDC (unchanged in both runs) | `6abd7b41c262b9d3cb32e7c6beafdf28bd4cf11bec8961e6027c0fabce21c80c` |

The baseline netlist is archived gzipped at
`research/runs/RUN-0027-timing-closure-2026-11-27/artifacts/has_soc_gate_prefix.v.gz`
so the "before" measurement can be re-analysed without re-synthesising, even
though `build/` is not tracked.

## 2. Baseline characterisation

Every violating endpoint was enumerated (3,000 paths requested; OpenSTA
returned the 1,536 endpoints that exist, of which 1,160 violate, summing to
`−104736.5 ns` — identical to the gate's TNS, so the enumeration is complete
rather than sampled).

| Slack band | Endpoints | Slack contributed |
|---|---|---|
| < −90 ns | **992** | **−103946.3 ns (99.25% of TNS)** |
| −20 … −5 ns | 96 | −753.1 ns |
| −1 … 0 ns | 72 | −37.2 ns |

The worst path was `_074266_` → {`_075354_`, `_075366_`, `_075699_` …}
(3,422 registers, 469 cells between flop pins). Composition of that one path:

* 114 `maj3` majority gates (sky130's full-adder carry cell) in a single serial
  chain, ~0.39 ns each — about 92% of the 126.24 ns arrival time;
* an `87`-fanout `clkbuf_1` at the start contributing 2.49 ns of net delay and
  a 3.13 ns slew;
* 46 `mux2` and ~150 AND-OR-INVERT cells interspersed.

`maj3` chains are carry chains. A 32-bit ripple datapath is ~32 stages; 114
stages means roughly 3–4 dependent 32-bit additions, i.e. a restoring divider's
per-iteration subtract/mux loop, flattened into one combinational cone.

## 3. Root cause

`rtl/rtl_top/riscv_core.sv` computed the whole M extension combinationally:

```systemverilog
3'b100: muldiv_out = $signed(rs1_val) / $signed(rs2_val);
3'b101: muldiv_out = rs1_val / rs2_val;
3'b110: muldiv_out = $signed(rs1_val) % $signed(rs2_val);
3'b111: muldiv_out = rs1_val % rs2_val;
```

Yosys expands `$div`/`$mod` into a 32-step restoring divider: 32 serial
conditional subtracts, each a 32-bit carry chain plus a select. `muldiv_out`
feeds `wb_data`, which is the write-data input of every register-file bit, so a
single divider cone put 1,024 register-file endpoints behind a ~470-level path.
The 992 endpoints at < −90 ns in §2 are those write ports; the whole cluster
moved together, which is why 99% of the energy sat in one place.

The multiplier was not the dominant term, and this is measured rather than
assumed: after the divider was removed the worst path is an SRAM read-data
chain, and no multiplier path appears in the remaining clusters.

Attribution is structural, not inferred from names: the cell mix (114 `maj3`
carry stages), the 469-level depth, the common startpoint shared by the three
worst endpoints, and the disappearance of the entire cluster when the operator
was removed all point at the same construct.

## 4. The change

One optimization, confined to `riscv_core.sv`:

* `S_DIV` is added as a fifth state (`logic [2:0]` state encoding).
  DIV/DIVU/REM/REMU start it from `S_EXEC` and retire from it; MUL remains
  combinational and still retires from `S_EXEC`.
* The divider keeps magnitude registers, a 33-bit partial remainder, a 32-bit
  quotient and a 6-bit counter; one quotient bit is produced per cycle.
* Architecturally defined cases bypass the iteration: divide by zero
  (quotient all-ones, remainder = dividend) and signed overflow
  (`0x80000000 / -1` → quotient `0x80000000`, remainder 0).
* Sign fixup is applied from the latched operand signs at retirement.
* `minstret` and `pc` advance once, at retirement, not at start.
* Both retirement paths drive **one** register-file write port
  (`if (wb_we) rf[rd] <= wb_val`). This matters: the first version used a
  separate `if (div_wb) rf[rd] <= div_result;` statement and synthesis turned it
  into one global enable net with **909 loads**, 3.19 pF, a 36 ns slew and
  25.15 ns of net delay — a new worst path at `−9.37 ns`. Merging both paths
  into one write port restored the per-entry select (`wb_we && rd == i`); the
  worst fanout in the final netlist is 69, against 67 in the baseline.

Cost: 32 iteration cycles plus a fixup/writeback cycle per divide. This core is
multi-cycle and does not overlap instructions, so latency rises and throughput
does not change. Cell count falls from 52,549 to 46,696 (−11.1%); register count
rises from 3,422 to 3,594 (+172) for the divider state.

## 5. Before / after

Same RTL file set, same SDC, same corner, same tool versions.

| Metric | Baseline `09e2eaa` | After | Change |
|---|---|---|---|
| WNS setup | −106.4775 ns | **−8.4509 ns** | +98.03 ns (92.1% recovered) |
| TNS setup | −104736.49 ns | **−848.81 ns** | 123× smaller |
| WNS hold | +0.2544 ns | +0.2544 ns | unchanged |
| Violating endpoints | 1,160 | 632 | −528 |
| Endpoints < −90 ns | 992 | **0** | cluster removed |
| Registers | 3,422 | 3,594 | +172 |
| Sky130 cells | 52,549 | 46,696 | −5,853 |

The worst path after the change is a different failure mode:

```
Startpoint: sram_inst.g_bank[1].u_macro (falling edge, macro clk0 → dout0[19])
Endpoint:   _54409_/D
70 cells, of which 60 are cascaded 2:1 muxes
arrival 28.2349 ns, required 19.7840 ns, slack −8.4509 ns
```

This is not the divider and it was not introduced by this change: it is the
pre-existing −20…−5 ns cluster (96 endpoints, −752 ns) that the 126 ns paths
had been hiding.

## 6. Functional evidence

The rewrite touches ISA semantics, so it was checked before timing:

| Check | Result |
|---|---|
| `tb_isa.v` (directed RV32IM, hand-encoded; includes DIVU/REM by zero, signed overflow) | **47/47 checks pass** |
| `tb_muldiv_sign.v` (new, RUN-0027): ordinary signed division sign fixup, 10 cases | **10/10 pass on both the published core and the new core** |
| Full regression (`node scripts/eda/run_regression.js`) | **30/30 PASS, exit 0** (15 min, log `logs/regression_postfix.txt`) |

`tb_muldiv_sign.v` runs the same program against `git show 09e2eaa:rtl/rtl_top/riscv_core.sv`
and against the new core; identical memory contents is the equivalence evidence
for the cases `tb_isa.v` does not cover (`-7/2`, `7/-2`, `-7/-2`, `-1000/7`,
and their remainders).

## 7. Regression and limitations

The full regression was re-run after the change: **30/30 PASS, exit 0**
(`logs/regression_postfix.txt`, started `16:44:49Z`, finished `16:59:43Z`).
That includes the directed ISA bench, the preload-free production boot bench,
the AXI split-channel bench and the CSR bench.

Limits of this result, stated so they cannot be mistaken for closure:

* **50 MHz still fails.** WNS is `−8.4509 ns`; the design does not meet the
  clock. This is progress, not closure.
* Single TT corner, ideal clocks, no SPEF, no CTS, pre-layout — unchanged from
  the baseline's stated scope.
* The divider is now a 34-cycle multi-cycle unit, but the core still has no
  pipeline: a divide blocks fetch. That is a performance choice, not a timing
  claim.
* No formal equivalence proof between the two cores; the evidence is directed
  simulation plus the recorded pre/post test outputs.
* The multiply path was not independently characterised after the RUN-0027
  change, because it was no longer the worst path. After RUN-0028 it *is* the
  worst path (21.00 ns, 23 `maj3` carry cells, no memory instance), which is the
  structural evidence that it is the next bottleneck (§9.3).

## 8. Ranked remaining bottlenecks

| Rank | Bottleneck | Evidence | Fix (not done here) |
|---|---|---|---|
| 1 | ~~SRAM bank read-data select is a 64-deep priority mux chain (`sram_macro_wrap.sv`: `for (k…) if (rd_bank_q == k) rd_dout = dout0_bank[k];`)~~ **FIXED in RUN-0028** | Worst path before: ~60 cascaded `mux2`, 28.23 ns arrival, 96 endpoints, −752 ns. After: 6 `mux2`, the cluster is empty | Indexed select, §9 |
| 1 (new) | Combinational arithmetic carry cone, WNS −1.2141 ns | §9.3: 57 cells, 23 `maj3`, no SRAM instance, 21.00 ns arrival | Characterise and pipeline/serialise the multiply (not done here) |
| 2 | Residual −1…0 ns endpoints (509) | §9.2 histogram | Local sizing/pipelining once rank 1 lands |
| 3 | No clock tree (ideal clocks in STA) | SDC scope note | CTS in a real P&R flow |

Rank 1 is a small, well-localised RTL change in a file this investigation did
not otherwise touch, and it is the natural next step. It was deliberately not
bundled here: the review asked for one evidence-supported optimization with a
clean before/after, and mixing two changes would make the attribution weaker.

## 9. RUN-0028 — SRAM bank read-data select (same day)

Run: `research/runs/RUN-0028-sram-bank-select-2026-11-27/`. One hunk in one
file, `rtl/rtl_top/sram_macro_wrap.sv` (9+/4−); `riscv_core.sv` untouched, so
the divider fix is preserved.

```systemverilog
-    for (int k = 0; k < NUM_MACROS; k++) begin
-      if (rd_bank_q == k[BANK_AW-1:0]) rd_dout = dout0_bank[k];
-      if (ir_bank_q == k[BANK_AW-1:0]) ir_dout = dout1_bank[k];
-    end
+    if (rd_bank_q < NUM_MACROS) rd_dout = dout0_bank[rd_bank_q];
+    if (ir_bank_q < NUM_MACROS) ir_dout = dout1_bank[ir_bank_q];
```

The bounds test keeps the chain's old "no match → `'0`" behaviour for an X or
out-of-range captured bank; the one-cycle bank capture and all handshakes are
unchanged.

### 9.1 Discriminating test

`tb_bank_select.v` writes a unique pattern to two words of all 64 banks, then
reads word 0 in bit-reversed bank order, word 7 ascending, instruction-fetches
word 0 in a 37-step permutation, and does back-to-back opposite-bank reads. It
prints a digest of every (address, data) pair.

| Run | checks | errors | digest |
|---|---|---|---|
| prefix (published `8dfb09d`) | 324 | 0 | `0d61aa60` |
| postfix | 324 | 0 | `0d61aa60` |
| mutant (`dout0_bank[k ^ 1]`) | 324 | 196 | `xxxxxxxx` |

The mutant fails exactly the 128 AXI bank reads, 64 i-fetches and 4 b2b reads,
so the bench does discriminate bank identity. Identical digests are the
equivalence evidence. Existing `tb_sram_macro_wrap.v` still passes (82 checks,
`NEG_BANK` and `NEG_STROBE` both rejected), `tb_isa.v` 47/47, regression 30/30.

### 9.2 Measured result (same SDC, corner, libraries, tool)

| Metric | Prefix | Postfix | Change |
|---|---|---|---|
| WNS setup | −8.4509 ns | **−1.2141 ns** | +7.2368 ns |
| TNS setup | −848.81 ns | **−107.66 ns** | 7.9× |
| Violating endpoints | 632 | 574 | −58 |
| Endpoints < −5 ns | 96 (−752.02 ns) | **0** | cluster removed |
| Endpoints −1…0 ns | 536 (−96.79 ns) | 509 (−34.11 ns) | −45 % |
| Worst-path `mux2` | 60 | 6 | −54 |
| Worst-path arrival | 28.2349 ns | 21.0033 ns | −7.23 ns |
| Cells | 46,696 | 44,252 | −5.2 % |
| Registers / hold WNS | 3,594 / +0.2544 ns | 3,594 / +0.2544 ns | unchanged |

### 9.3 What replaced it, and what is *not* claimed

The new worst path (21.0033 ns) is 57 cells of carry logic: 23 `maj3`, 6
`mux2`, no `sram_inst` instance anywhere on it, startpoint flop fanning out to
86 loads. That is an arithmetic adder cone. It is *consistent with* the
combinational multiply being the next bottleneck, but this run did not prove
that by ablation or by a MUL-only characterisation; the attribution is the
first task of the next phase. **50 MHz still fails at WNS −1.2141 ns.**

## 10. Evidence index

`research/runs/RUN-0027-timing-closure-2026-11-27/`

* `README.md` — scope, commit, tool versions, commands, exit statuses
* `commands.jsonl` — one record per command with exit status
* `logs/prefix/` — baseline endpoint enumeration (netlist hash recorded)
* `logs/postfix/` — post-fix enumeration, same script and SDC
* `logs/sta_postfix_v1_run.txt`, `logs/sta_postfix_v1_full.log` — the first
  post-fix run, where the 909-load net appeared; kept as a negative result
* `logs/sta_postfix_v2_run.txt` — the final STA gate run
* `logs/regression_postfix.txt` — full regression
* `tb_muldiv_sign.v`, `prefix_rtl/riscv_core.sv` — equivalence bench and the
  published core it was compared against
* `artifacts/has_soc_gate_prefix.v.gz` — archived baseline netlist

Follow-up run: `research/runs/RUN-0028-sram-bank-select-2026-11-27/` (bank
select, §9).
