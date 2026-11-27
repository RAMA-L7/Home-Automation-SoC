# RUN-0028 — isolated SRAM read-bank select optimization (2026-11-27)

One RTL change: replace the per-bank priority comparison in
`rtl/rtl_top/sram_macro_wrap.sv` with an indexed select on the captured bank.
Nothing else in the RTL, SDC, libraries or flow changed.

* Delta: `rtl/rtl_top/sram_macro_wrap.sv`, 9 insertions / 4 deletions, one hunk
  (`git diff --stat` shows only this file).
* Divider optimization preserved untouched: `rtl/rtl_top/riscv_core.sv` is not
  in the diff.
* Baseline of this run = published `8dfb09d` (`main`), which is the post-divider
  fix state.

```
-    for (int k = 0; k < NUM_MACROS; k++) begin
-      if (rd_bank_q == k[BANK_AW-1:0]) rd_dout = dout0_bank[k];
-      if (ir_bank_q == k[BANK_AW-1:0]) ir_dout = dout1_bank[k];
-    end
+    if (rd_bank_q < NUM_MACROS) rd_dout = dout0_bank[rd_bank_q];
+    if (ir_bank_q < NUM_MACROS) ir_dout = dout1_bank[ir_bank_q];
```

## 1. Read semantics that had to be preserved

* `rd_bank_q` / `ir_bank_q` are `BANK_AW` bits wide, captured one cycle before
  the data from `rd_word[LOCAL_AW +: BANK_AW]` (`ir_word` for the i-port).
* `BANK_AW = $clog2(NUM_MACROS)`, so the captured index is always in range for a
  power-of-two bank count, and the loop form's "no match → `'0`" case could only
  be reached by an out-of-range or X value.
* The bounds test keeps exactly that behaviour: an X captured bank makes the
  comparison X, the `if` takes the false path, and the output stays `'0`, as the
  chain did. This matters for simulation before the first reset-approved read.
* The captured-bank timing (data one cycle after the access) is unchanged; only
  the selection structure changed. No pipelining, no retiming, no new state.

## 2. Discriminating test (built before the change)

`tb_bank_select.v` — 64-bank production geometry, proxy macro model, same
AXI/i-port protocol tasks as `tb_sram_macro_wrap.v`:

* Phase 1: unique 32-bit pattern `{0xA0+b, 0x5A, w, b^w}` written to words 0 and
  7 of **every** bank (128 writes).
* Phase 2: read word 0 of all banks in **bit-reversed** bank order.
* Phase 3: read word 7 of all banks in ascending order.
* Phase 4: **instruction-fetch** word 0 of all banks in a 37-step permutation
  (37 is coprime with 64, so it visits every bank exactly once).
* Phase 5: back-to-back reads of banks 0/63/1/62 — the registered bank capture,
  not the live address, must select the data.
* All comparisons are `!==` (X/Z fails), and the bench prints a rolling
  digest of every (address, data) pair so the two netlists can be compared
  beyond pass/fail.

| Run | RTL | checks | errors | digest |
|---|---|---|---|---|
| prefix | published `8dfb09d` | 324 | 0 | `0d61aa60` |
| postfix | this change | 324 | 0 | `0d61aa60` |
| mutant (`dout0_bank[k ^ 1]`, `dout1_bank[k ^ 1]`) | negative control | 324 | **196** | `xxxxxxxx` |

The mutant fails exactly the 128 AXI bank reads + 64 i-fetches + 4 b2b reads:
the test does discriminate bank identity on both ports. Identical digests
establish behavioural equivalence over the full bank set for this change.

Logs: `logs/tb_bank_select_prefix.log`, `logs/tb_bank_select_postfix.log`,
`logs/tb_bank_select_mutant.log`; mutant source at
`artifacts/sram_macro_wrap_mutant.v`.

## 3. Functional gates

| Gate | Result | Log |
|---|---|---|
| Bank-select bench, prefix | PASS 324/324, digest `0d61aa60` | `logs/tb_bank_select_prefix.log` |
| Bank-select bench, postfix | PASS 324/324, digest `0d61aa60` | `logs/tb_bank_select_postfix.log` |
| Bank-select mutant (must fail) | FAIL 196/324, as required | `logs/tb_bank_select_mutant.log` |
| `tb_sram_macro_wrap.v` PROD | PASS, 82 checks, 0 errors | `logs/macro_wrapper_postfix.txt` |
| `NEG_BANK` control | rejected (3 errors) | same |
| `NEG_STROBE` control | rejected (30 errors) | same |
| `tb_isa.v` | PASS 47/47 | `logs/tb_isa_postfix.log` |
| Full regression | **PASS 30/30, exit 0** (17:19:19Z → 17:33:28Z) | `logs/regression_postfix.txt` |

The existing wrapper suite still passes, so the strobe, boundary, last-word,
simultaneous read/write and RDATA-hold behaviour is unchanged.

## 4. STA — identical constraints, libraries and tool

Same flow as RUN-0027: `node scripts/eda/run_sta.js --verbose`, SDC
`constraints/timing_constraints/has_soc.sdc` (sha256 `6abd7b41…`), OpenSTA
3.1.0, sky130_fd_sc_hd TT 025C 1.80 V liberty (sha256 prefix `8e78e144…`) plus
the two SRAM macro libs, ABC `-D 20000 -dff -constr scripts/sta/abc.constr`.

| Metric | Prefix (`16d83387…`) | Postfix (`e2bc0a2f…`) | Change |
|---|---|---|---|
| Setup WNS | **−8.4509 ns** | **−1.2141 ns** | +7.2368 ns |
| Setup TNS | −848.81 ns | −107.66 ns | 7.9× smaller |
| Violating endpoints | 632 | 574 | −58 |
| Endpoints < −5 ns | 96 (−752.02 ns) | **0** | eliminated |
| Endpoints −5…−1 ns | 0 | 65 (−73.55 ns) | new cluster |
| Endpoints −1…0 ns | 536 (−96.79 ns) | 509 (−34.11 ns) | −45 % slack |
| Worst-path arrival | 28.2349 ns | 21.0033 ns | −7.23 ns |
| Worst-path cells | 68 | 57 | −11 |
| Worst-path `mux2` | **60** | 6 | −54 |
| Worst-path carry cells (`maj3`) | 0 | 23 | new cone |
| Hold WNS | +0.2544 ns | +0.2544 ns | unchanged |
| Registers | 3,594 | 3,594 | unchanged |
| Cells | 46,696 | 44,252 | −2,444 (−5.2 %) |
| Max fanout | 69 | 67 | −2 |

The 96-endpoint / −752 ns SRAM cluster is gone, and the 60-mux chain that
started at `sram_inst.g_bank[1].u_macro` no longer exists in the worst path.

Cell count fell because the 64-bank, two-port select previously carried 128
six-bit equality comparators; indexing removes them while the select still
needs 63 muxes per 32-bit port.

### 4.1 What the new worst path is

`build/sta/sta.log`, first path: 57 cells, of which 23 are `maj3` carry cells
and 6 `mux2`, no SRAM instance anywhere on it; startpoint flop fans out to 86
loads through buffering. That is an arithmetic carry/adder cone, not memory
selection. It is consistent with the limitation recorded in
`reports/TIMING_CLOSURE_2026-11-27.md` §7 ("the multiply path was not
independently characterised after the change"); the combinational multiply is
the only remaining structure in the core of that shape. Confirming it by
ablation or by a MUL-only characterisation is the next step, not a claim made
here.

## 5. Verdict

* Functional: PASS (equivalence digest identical, negative control rejected,
  wrapper suite, ISA, regression).
* Timing: improved by 7.24 ns at WNS and 7.9× at TNS, 96 worst endpoints
  removed; **50 MHz still fails at WNS −1.2141 ns**, so this is a step, not
  closure.
* Change is isolated to one hunk in one file; the divider fix is preserved.

## 6. Reproduction

```bash
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"

# bank-select bench (prefix uses prefix_rtl/sram_macro_wrap.sv)
iverilog -g2012 -DUSE_POWER_PINS -DSIM_MEM_PRELOAD -o build/sim/tb_bank_select.vvp \
  -s tb_bank_select sim/models/sky130_sram_sim_model.v \
  research/runs/RUN-0028-sram-bank-select-2026-11-27/tb_bank_select.v \
  rtl/rtl_top/sram_macro_wrap.sv
vvp build/sim/tb_bank_select.vvp

node scripts/eda/run_macro_wrapper.js
node scripts/eda/run_sta.js --verbose
MSYS_NO_PATHCONV=1 wsl bash /mnt/d/Home-Automation-SoC/research/runs/RUN-0028-sram-bank-select-2026-11-27/run_analysis.sh \
  /mnt/d/Home-Automation-SoC/build/sta/has_soc_gate.v postfix 3000
```

## 7. Evidence index

* `tb_bank_select.v`, `prefix_rtl/sram_macro_wrap.sv` — bench and the exact
  pre-change wrapper it was developed against
* `logs/tb_bank_select_{prefix,postfix,mutant}.log`
* `artifacts/sram_macro_wrap_mutant.v` — XOR-1 negative control
* `artifacts/has_soc_gate_prefix_bank.v.gz` — pre-change netlist, sha256
  `16d83387…`
* `logs/sta_postfix_run.txt` — full STA gate run with versions and hashes
* `logs/{prefix,postfix}/` — endpoint enumeration, same script and SDC
* `logs/cluster_summary.txt` — endpoint histogram and path composition
* `logs/macro_wrapper_postfix.txt`, `logs/tb_isa_postfix.log`,
  `logs/regression_postfix.txt`
* `logs/inputs_{before,after}.sha256` — RTL and netlist hashes
