# Timing and CDC qualification — constraints versus the implemented RTL

> **Update 2026-11-27 (RUN-0027 → RUN-0028 → RUN-0029).** The `b5e0642`
> measurement below is kept as the historical record. The worst path was first
> attributed to the combinational M-extension divider in `riscv_core.sv`;
> moving DIV/REM to an iterative state took WNS to **−8.4509 ns** and TNS to
> **−848.81 ns**. The next Rank 1, the 64-deep SRAM bank read-data priority mux
> in `sram_macro_wrap.sv`, was then replaced by an indexed select: WNS
> **−1.2141 ns**, TNS **−107.66 ns**, no endpoint below −5 ns, **30/30**
> regression. RUN-0029 then attributed the remaining 21.00 ns path end to end:
> it is the single-cycle `pc → alu_a mux → ALU adder → mem_misaligned/exception
> → pc_next` loop, **not** the multiplier (zeroing all three multipliers makes
> WNS worse at −1.8206 ns, and MULHU alone needs ≈12.7 ns of a 19.79 ns
> budget). RUN-0029 changed no RTL. 50 MHz still fails. Evidence:
> `research/runs/RUN-0027-timing-closure-2026-11-27/`,
> `research/runs/RUN-0028-sram-bank-select-2026-11-27/`,
> `research/runs/RUN-0029-mul-attribution-2026-11-27/`; analysis:
> `reports/TIMING_CLOSURE_2026-11-27.md`.

**Tested commit:** `b5e0642`
**Engine:** OpenSTA 3.1.0 (Linux build, WSL2 `Ubuntu-24.04`)
**Result:** STA runs and reports **FAIL** — WNS setup `-106.4775 ns`,
TNS setup `-104736.49 ns`, WNS hold `+0.2544 ns`, 3,422 registers.
This is a measured timing failure, not a tool gap.

---

## 1. The tool gap was stale

Earlier documents (including `reports/REVIEW_INTERVENTION_2026-11-26.md` §3)
said path-based STA was BLOCKED because "the Linux binary cannot execute (WSL1
is unsupported on this machine)". That is no longer true: the machine runs WSL2,
`/mnt/d/tools/opensta/build/sta` reports `3.1.0`, and
`scripts/eda/run_sta.js` completes end to end. The BLOCKED claim is withdrawn.

What `scripts/eda/run_sdc_lint.js` does is still only a **constraint-file**
check (Tcl validity, object resolution, port coverage). It is not, and must not
be quoted as, a timing result.

## 2. JTAG was constrained against RTL that does not exist

`rtl/rtl_peripherals/debug_jtag.sv` runs its whole TAP state machine on
`sys_clk`. TCK, TMS and TDI are asynchronous debugger outputs that pass through
two flops and the TAP advances only on a detected TCK rising edge. **No register
in the SoC is clocked by TCK.**

The previous SDC did `create_clock -name jtag_tck -period 100.0 [get_ports
jtag_tck]` and constrained TMS/TDI/TDO against it. That told STA to time
`sys_clk` registers against a TCK edge that never clocks them, and it claimed
10 MHz while `debug_jtag.sv` documents `clk >= 10 x TCK` as the measured
reliable floor (4× was measured insufficient). At 50 MHz that is TCK ≤ 5 MHz,
i.e. a 200 ns period — the SDC was advertising **twice** the rate the TAP was
characterised at.

Fixed:

* `jtag_tck` is now a **virtual** clock (no source port) at 200 ns. It exists
  only as the external reference for TDO's output delay.
* TCK/TMS/TDI are bounded as **asynchronous inputs** with
  `set_max_delay 2.0 -from [get_ports {jtag_tck jtag_tms jtag_tdi}] -to
  [get_clocks sys_clk] -ignore_clock_latency`. (`-ignore_clock_latency` is
  OpenSTA's datapath-only bound; OpenSTA rejects `-datapath_only`.)
* No `set_clock_groups -asynchronous` on the JTAG interface any more: it would
  have deleted both the CDC bound and TDO's output delay, leaving the interface
  entirely unconstrained. The two clocks are simply unrelated, which makes
  OpenSTA analyse TDO conservatively against every TCK edge.

Measured on the mapped netlist, the CDC path is exercised and met:

```
Startpoint: jtag_tdi (input port)
Endpoint:   _069429_ (rising edge-triggered flip-flop clocked by sys_clk)
slack       1.8265   (MET)
```

That is the 2 ns bound minus the arrival, i.e. the constraint is live rather
than decorative.

## 3. Every timing exception, and why it is legitimate

There are exactly two in `constraints/timing_constraints/has_soc.sdc`.

| Exception | Object | Justification |
|---|---|---|
| `set_false_path -from [get_ports reset_n] -to [get_clocks sys_clk]` | external reset pad | `reset_n` drives asynchronous reset pins only. An asynchronous reset has no capture edge, so there is no setup/hold relationship to check; `reset_ctrl` releases `rst_sys_n` through a counter on `sys_clk`. |
| `set_max_delay 2.0 -ignore_clock_latency -from [get_ports {jtag_tck jtag_tms jtag_tdi}]` | JTAG CDC inputs | Launched by an unrelated clock and captured by a two-flop synchroniser. A setup check against `sys_clk` would be meaningless; a datapath bound is the correct constraint because it limits how much skew the first synchroniser stage can see. |

No multicycle paths, no clock-group cuts, no blanket `set_max_delay` over
`all_inputs`/`all_outputs`. The earlier file's blanket cut (and its
`foreach ... begin ... end` HDL syntax, and its `-comment` flags) are gone and
are covered by the validator's negative controls.

External I/O delays remain **ESTIMATED**: they assume a < 50 mm trace, a 5 ns
external round trip and 1 ns uncertainty. No IBIS, no transmission-line model,
no extracted parasitics. The file states that at the top and must not be
described as signoff-grade.

## 4. Measured result

```
STA-CLOCKS=2
STA-REGISTERS=3422
WNS setup   -106.4775 ns
TNS setup   -104736.49 ns
WNS hold     0.2544 ns
TNS hold     0.0 ns
```

Worst setup path (`build/sta/sta.log`):

| Field | Value |
|---|---|
| Startpoint | `_074266_` (DFF, `sys_clk`) |
| Endpoints (top 3) | `_075354_`, `_075366_`, `_075699_` |
| Path group / type | `sys_clk` / max |
| Data arrival | 126.2435 ns |
| Data required | 19.7660 ns (20 ns − 0.100 uncertainty − 0.134 setup) |
| Slack | **−106.4775 ns** |

The arrival is dominated by the `maj3` cascade itself, not by that buffer: the
second buffer on the path (`_088628_/X`) drives 87 loads, has a 3.13 ns slew and
contributes 2.49 ns, but 114 majority-gate carry stages account for ~92% of the
126.24 ns. That cascade is the combinational divider (RUN-0027 §3), so the
earlier "fanout, not logic depth" reading of this figure was incomplete. It matches the
earlier independent diagnosis (`reports/STA_CRITICAL_PATH_DIAGNOSIS.md`,
−106.23 ns at `04c3084`): same shape, same order of magnitude, different netlist
because AXI capture logic and the ROM changed.

## 5. What this does NOT establish

* **Not signoff.** Ideal clocks, one TT corner (1.8 V, 25 °C), no extracted
  parasitics, no clock tree, no OCV/AOCV, no IR drop, no crosstalk.
* **No fix is claimed.** A −106 ns violation is a design-level fanout/logic-depth
  problem, not something a constraint change may hide. No false path or
  multicycle exception was added to suppress it.
* **Hold is met only on this netlist** (+0.25 ns) with ideal clocks; a real
  clock tree will change it.
* The ROM's own timing is included only as standard-cell logic; the SRAM macro
  timing comes from the macro Liberty file at that corner, not from an
  extracted macro view.

## 6. Reproduce

```bash
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
node scripts/eda/run_sdc_lint.js        # constraint file only
node scripts/eda/run_sta.js --verbose   # Yosys map + OpenSTA; exit 1 on violation
```

`run_sta.js` exits 1 for this design and that is the correct result.
