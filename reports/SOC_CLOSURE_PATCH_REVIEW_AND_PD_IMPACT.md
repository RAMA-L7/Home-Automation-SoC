# Closure Patch Review + Synthesis / Placement / CTS Impact

Base: `main` @ `da20f87900d9a43a4691c7dbe71ffa136a724716`
Closure commit: `358939c346d3f8a477869efbe6ff34f091541485` — published to `origin/main` directly, no pull request
Status: **review passed, committed, functional gate re-verified. Full-SoC gate-level
synthesis remains BLOCKED by a pre-existing Yosys limitation. Placement and CTS
reproduce the baseline byte-identically because the patch does not touch the one
block that has a physical flow.**

Nothing here is physical signoff or tapeout qualification.

---

## 1. Review of the closure patch

### 1.1 RTL correctness

**`rtl/rtl_top/has_soc.sv`**
- APB slot decode moved from `paddr[15:12]` to `paddr[19:12]`, matching the 1 MB
  `ADDR_APB_SIZE` aperture. Slots `9'h000..9'h008` are the nine peripherals;
  everything else falls to `default` and completes with `PSLVERR`. No address
  above the aperture is newly writable.
- `pready` is now the constant `1'b1`. This is the correct APB contract: the error
  must accompany a *completed* transfer. The previous `(apb_sel != 0)` held PREADY
  low for unmapped slots, which stalled the bridge — and therefore the CPU —
  instead of reporting the error.
- `apb_write_ok = ~(pwrite && pstrb != 4'hF)` gates every peripheral's `penable`.
  A partial-strobe write therefore never reaches a register, so the `PSLVERR` it
  returns has no side effect. Reads are unaffected (`pwrite` is in the term).
  Checked all nine instantiations: each has the term, none is a read path.
- Reset-domain change: `data_adapter`, `axi_ic`, `rom_inst`, `tcm_inst`,
  `sram_inst`, `qspi_ctrl`, `apb_bridge`, `intc_inst` and the `fault_rvalid` FF
  now take `rst_sys_n` instead of `reset_n`. `reset_ctrl` and `debug_jtag`
  deliberately keep `reset_n`. Memory arrays are initialised only by `$readmemh`,
  so contents persist — the intended persistence contract.
- Reviewed for unintended coupling: `pm_sleep_req`, clock gating, the PLIC source
  map, and the `s_*` interconnect wiring are unchanged.

**`rtl/rtl_peripherals/plic.sv`**
- `claim_id` widened to 4 bits; `4'(i+1)` holds 1..8, and `claimed[claim_id-1]`
  cannot wrap.
- Priority index is `4'(wr_addr[5:2] - 4'd1)`. Range check: the guard is
  `wr_addr >= 0x004 && wr_addr < 0x004 + 4*NUM_SOURCES`, i.e. `0x004..0x020`, so
  `wr_addr[5:2]` is 1..8 and the index is 0..7 — exactly `prio[0..7]`. No
  out-of-range index, no wrap. Read path uses the identical expression.
- `{28'd0, claim_id}` is 32 bits. One driver for `claimed`, preserved.

**`rtl/rtl_top/riscv_core.sv`**
- `csr_is_imm = funct3[2]` correctly selects 101/110/111; `csr_zimm` is the
  zero-extended `ir[19:15]`, not a register read.
- `csr_we = is_csr && ((funct3[1:0] == 2'b01) || !csr_src_zero)`: CSRRW/CSRRWI
  always write, CSRRS/CSRRC and the immediate forms only when the source field is
  non-zero. Matches the ISA rule.
- `csr_known` / `csr_writable` / `csr_illegal`: unknown CSR, or a write to a
  read-only CSR, raises `mcause = 2`. `csr_known` is consistent with the read mux,
  so nothing that previously read 0 now traps except genuinely unimplemented
  addresses. Note `0x345` is in `csr_known` because the read mux already decodes
  it as a zero-read (`mvendorid` per an old comment — a cosmetic inaccuracy that
  predates this patch and was left alone).
- Retirement accounting: `minstret` no longer increments in `S_FETCH`. It
  increments in `S_EXEC` when `!is_mem` (inside the existing `!exc_take` guard,
  so a faulting instruction does not retire) and in `S_MEM` only on
  `data_rvalid && !data_err`. The CSR write to `0xB02/0xB82` appears after the
  increment in program order, so an explicit `csrw minstret` still wins.
- `mem_misaligned` now covers `funct3 == 3'b101` (LHU). `is_mem` gates the
  expression, so the extra `funct3` match cannot collide with OP-IMM/OP.

No unintended behavioural change was found in the RTL beyond the documented
software-visible consequences (APB errors now complete, 1 MB aperture, PLIC IDs
1–8 addressable individually, `minstret` counts retirement, watchdog reset clears
in-flight bus state).

### 1.2 Test-infrastructure changes

The runner diffs were read looking for weakened checks. They strengthen: the
removed lines are the old "compile failure counts as rejection" branch, the
hardcoded `PASS 22 / 22` and `PASS 5 / 5` markers, and the pre-provenance image
reuse. `reset_ctrl_fv.sv` replaces a tautological assertion with one over
registered history and adds a cover; no assertion was deleted or relaxed.

### 1.3 Regression evidence, re-verified independently

```
node scripts/verify.js           exit 0   9 passed, 0 failed, 0 blocked
  regression                     exit 0   PASS 26 / 26
  formal                         exit 0   PASS 6 / 6
```

Matches the closure report. `build/review_verify.log`.

### 1.4 Task-owned files committed

9 modified + 10 added = 19 files. `TAPEOUT_EVIDENCE_REGISTRY.md` was already
modified before this work and was **not** staged; all other pre-existing untracked
files (62) remain untracked and untouched.

`sim/asm/boot_jump.S` (16 bytes, `j 0x10000`, pre-existing) was included on your
instruction, because `run_regression.js` assembles the boot image from it and the
two integrated-bus tests cannot run without it.

---

## 2. Commands, tools, exit codes

Environment: `PATH` prefixed with `/d/tools/oss-cad-suite/{lib,bin}` and
`/d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin`; physical flow under
WSL `Ubuntu 24.04.4 LTS`.

| Tool | Version |
|---|---|
| Icarus Verilog | 14.0 (devel) s20260301-500-g2e81fcccb-dirty |
| Verible | v0.0-4298-g085eef05 |
| SBY | v0.69 |
| Yosys | 0.69+154 (git sha1 30d62572-dirty) |
| OpenROAD | `bazel-nostamp`, `/mnt/d/tools/openroad/bin/openroad` |
| Node | v26.7.0 |
| riscv-none-elf-gcc | 12.2.0 (xPack) |

| Step | Command | Exit |
|---|---|---|
| Functional gate | `node scripts/verify.js` | 0 |
| Full-SoC synthesis | `yosys -q build/asic_flow/phase1/full_top/native_top.ys` | **1** |
| Same, pre-patch source | `yosys -q build/pd_review/native_top_prefix.ys` | **1** |
| Timer remap | `yosys -q build/pd_review/timer_remap.ys` | 0 |
| plic / timer mapping | `build/pd_review/synth2.ys` (per module, both revisions) | 0 |
| riscv_core (pre-map) | `build/pd_review/gen_core_gen_{old,new}.ys` | 0 |
| Placement rerun | `openroad -exit run_placement.tcl` (WSL) | 0 |
| CTS rerun | `CTS_APPROVAL_TOKEN=… openroad -exit run_cts.tcl` (WSL) | 0 |

Logs: `build/pd_review/`, `build/review_verify.log`.

---

## 3. Synthesis

### 3.1 Full-SoC gate-level synthesis — BLOCKED (pre-existing)

```
rtl/rtl_top/axi_lite_interconnect.sv:57: ERROR: syntax error, unexpected '[',
      expecting ')' or ',' or '='
```

Line 57 is `output logic [ADDR_WIDTH-1:0] s_awaddr [NUM_SLAVES],` — an unpacked
array port, which the Yosys SystemVerilog frontend does not accept. Verified:

- `git diff da20f87 -- rtl/rtl_top/axi_lite_interconnect.sv` is **empty**; the
  patch does not touch the file.
- Running the identical script against a snapshot of the pre-patch tree produces
  the **same error and the same exit code 1**.
- `AGENTS.md` has recorded this exact blocker since 2026-11-11.

The failure occurs at parse time, before any patched module is elaborated, so the
patch cannot be the cause. Making it synthesize would require rewriting the
interconnect's port list — an unrelated RTL change that this task explicitly
forbids. **No full-SoC area, timing or cell-count number exists, before or after
the patch.**

### 3.2 Modules the patch changed (Sky130 HD, `tt_025C_1v80`, `synth → dfflibmap → abc -liberty`)

| Module | Cells (before → after) | Area µm² (before → after) | Δ |
|---|---:|---:|---:|
| `plic` | 920 → 886 | 7955.13 → 7903.83 | −34 cells, −51.30 µm² (−0.64 %) |
| `timer` (control, untouched) | 306 → 306 | 3329.4432 → 3329.4432 | 0 |
| `riscv_core` (pre-mapping structural) | 666 → 714 | not obtained | +48 cells (+7.2 %) |

`plic` area fell slightly because the 4-bit claim path and the non-wrapping
priority index are simpler than the 3-bit field with a wrapped index.

`riscv_core`: the delta is entirely combinational — `$eq` 136→140, `$logic_and`
40→49, `$logic_not` 18→23, `$mux` 325→330, with the sequential cell counts
identical (`$adff` 35, `$adffe` 16 in both). That is the CSR legality and
write-enable decoder, as expected. **Mapped (area) synthesis of `riscv_core` did
not complete**: `abc -liberty` on the core exceeded ~30 minutes and was stopped,
so no µm² figure is claimed for the core.

The standard `abc` script for `timer` and `plic` completed, so those two figures
are real mapped areas. They are not comparable to the timer's CTS-stage numbers.

---

## 4. Placement and CTS

### 4.1 Applicability — stated up front

The only approved physical flow in this repository is the **isolated `timer`
block** (Context A, `approved_period_ns 40.000`, `cts_config.tcl` bound by hash to
the approval record). There is no placement or CTS configuration for `has_soc`,
`plic` or `riscv_core`, and inventing one would mean inventing a clock period and
constraints, which this task forbids. Since the patch does not modify `timer.sv`,
this flow is a **regression check on the flow itself**, not a measurement of the
patch's physical impact.

The approval gate (`checks/approval_gate.tcl`) validates the SHA-256 of the SDC,
CTS config, driver, Liberty, LEF, RC rules, platform config and the input ODB/DEF.
Redirecting outputs required editing the config or driver and would have
invalidated the approval, so the flow was rerun **unmodified** into its normal
output path after backing those two artefacts up to
`build/pd_review/baseline_backup/`.

### 4.2 Input reproducibility

Regenerating the mapped timer netlist from the **current** RTL with the existing
`timer.ys` produced `build/pd_review/timer_sky130_remap.v` with SHA-256
`42c0c3e21fde026fa7657dadbba9a576ec346fee1498db0a960f119326bafbb9` — **byte-identical**
to the baseline `02_mapping_probe/timer_sky130.v`. The patch provably does not
reach the placement/CTS inputs.

### 4.3 Placement rerun

| Metric | Baseline | Rerun |
|---|---|---|
| DEF SHA-256 | `32f3daf76f7c49c111b5ff15bfe9a1200bc399cbcd31cf2c5ac0011946aeaa29` | **identical** |
| Mapped instances | 301 | 301 |
| Tap cells | 105 | 105 |
| Total instances | 406 | 406 |
| Original / legalized HPWL | 8342.5 µm / 8743.4 µm (+5 %) | identical |
| Design area | 3480 µm², 43 % utilization | identical |
| Detailed placement | PASS, 0 unplaced | PASS, 0 unplaced |

### 4.4 CTS rerun

`GATE_STATUS : APPROVED` (the approval gate accepted the unmodified inputs).

| Metric | Baseline | Rerun |
|---|---|---|
| ODB SHA-256 | `62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974` | **identical** |
| DEF SHA-256 | `ca9d99de2d417736b6fc5d1030f6f2be2669ee6f6ff2a2f288faeda2f2dc6e44` | **identical** |
| Clock sinks | 67 (`dfrtp_1`) | 67 |
| Buffers created | 9 (10 `clkbuf` instances in design) | 9 / 10 |
| Buffers in clock path | min 2 / max 2 | 2 / 2 |
| Setup skew | 0.11 ns (source latency 0.31, target −0.31, uncertainty 0.10, CRPR 0) | identical |
| Worst hold slack | +0.459 ns (MET) | identical |
| Worst setup slack | +37.770 ns (MET) | identical |
| Violations | 0 | 0 |

Routing was not run and no signoff STA exists — the SDC is provisional (40 ns
period, 0.100/0.050 ns uncertainty carried from `has_soc.sdc`), 105 ports lack
timing budgets and 35 endpoints are unconstrained.

### 4.5 Difference from the previous physical baseline

**Zero on every reported metric**, because the rerun reproduces the baseline ODB
and DEF byte-for-byte. That is the correct outcome: the patch changes no logic in
the timer block. It is also why these numbers say nothing about the patch's
physical cost on the blocks that did change.

---

## 5. Remaining blockers

1. **Full-SoC synthesis is impossible with the current toolchain** until
   `axi_lite_interconnect.sv`'s unpacked array ports are rewritten (packed 2-D
   arrays, or a flattened port list). Pre-existing, unchanged by the patch,
   recorded in `AGENTS.md`. This blocks every full-SoC area/timing/cell-count
   number.
2. **No physical flow exists for `has_soc`, `plic` or `riscv_core`.** There is no
   floorplan, SDC or CTS config for them, and no approved clock period for the
   full SoC. Their real placement/CTS impact is therefore unmeasured; the only
   quantitative result available is the `plic` mapped area (−0.64 %) and the
   `riscv_core` combinational cell delta (+48 pre-mapping cells).
3. **`riscv_core` mapped area not obtained** — `abc -liberty` did not finish in
   the run budget.
4. **The pre-existing timing baseline is provisional**: 40 ns on the timer block
   only, uncertainty borrowed from an unrelated clock, no approved thresholds.
5. **A pre-existing full-SoC run was never possible**, so "differs from baseline"
   can only be answered for the timer block — where the answer is "identical".

Not claimed: physical signoff, timing closure, DRC/LVS, tapeout readiness.

---

## 6. Artefacts

- Commit `358939c` (19 files) — published to `origin/main` by fast-forward, no pull request.
- `README.md` and `AGENTS.md` updated with the closure outcome, the measured gate
  counts (9/9, 26/26, 6/6) and the full-chip synthesis blocker.
- `reports/SOC_FUNCTIONAL_CORRECTNESS_CLOSURE_da20f87.md` — the closure report,
  included in the commit.
- `build/pd_review/` — synthesis stats and logs, full-SoC failure logs (current and
  pre-patch), placement rerun (`placement_rerun/`), CTS rerun log, baseline backup.
- `build/review_verify.log`, `build/verify/*.log` — functional gate evidence.
- This report was kept out of the closure commit so that commit stayed limited to
  the approved closure changes, and was published in a separate documentation
  commit.
