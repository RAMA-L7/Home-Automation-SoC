# Home-Automation-SoC — SoC Functional Correctness Closure (scoped)

Scope: the seven steps of the "SoC Functional Correctness Closure" instruction.
This report is about those explicitly scoped findings only. It is **not** a claim
that the SoC is correct, release-ready or tapeout-ready: simulations are
directed, most formal tasks are bounded, and no timing, power, DFT, FPGA or
physical-design sign-off was performed here.

Supersedes nothing: the earlier untracked `reports/SOC_FUNCTIONAL_CORRECTNESS_CLOSURE.md`
(which refers to commit `420f46b`) is left untouched on disk.

---

## 1. Baseline identification

| Item | Value |
|---|---|
| Branch | `main` |
| HEAD | `da20f87900d9a43a4691c7dbe71ffa136a724716` |
| Working tree at start | **dirty**: 1 pre-existing modified file (`TAPEOUT_EVIDENCE_REGISTRY.md`), 62 pre-existing untracked files |
| Working tree at end | still uncommitted; nothing staged, committed, pushed or merged |
| Source fingerprint | `sha256(build/closure_tree.patch)` = `ac913d2ce4aed3c88837c544c1b82ababa7b7a837abca116f1a189860ed2b07b` |

Every result below was produced from the **uncommitted working tree**, i.e.
`da20f87` + the patch above + the new untracked files listed in §4. It must not
be attributed to `da20f87` alone.

`TAPEOUT_EVIDENCE_REGISTRY.md` was already modified before this session began and
was not touched. The untracked draft testbenches from earlier sessions
(`tb_apb_cpu.v`, `tb_cpu_arch.v`, `tb_plic_targeted.v`,
`tb_watchdog_reset_phase.v`, `sim/asm/tb_apb_cpu.S`, `sim/asm/tb_cpu_arch.S`)
were read for ideas but **not modified**; the new tests below are separate files.

---

## 2. Findings

| # | Finding | Verdict | Evidence |
|---|---|---|---|
| S1-a | Lint verdict inferred from parsed diagnostics while ignoring process errors / exit status | **FIXED** | `scripts/verify.js` rewritten; self-test 10/10 rejects; deliberate violation → FAIL |
| S1-b | Diagnostic parsing fails on Windows drive-letter paths | **FIXED** | `parseLintRows()` + `path.relative`; the real lint run parses 54 diagnostics across 24 files |
| S1-c | Compile failure / missing exe / crash / timeout / silent output counted as successful image rejection | **FIXED** | `run_e2e.js` step 7 rewritten; observed live: a host timeout reported `host timeout (infrastructure, not a rejection)` → FAIL, not PASS |
| S1-d | Hardcoded expected totals that can diverge from the inventory | **FIXED** | runners derive `PASS n / m` from the executed list; `allExecutedPassed()` re-parses the child's own line |
| S1-e | Firmware images reused without provenance | **FIXED** | `prepareImages()` rebuilds every image from source, deletes stale outputs, records SHA-256; live proof: with the RISC-V toolchain off `PATH` the firmware test became `IMAGE-FAIL` (`PASS 25 / 26 (IMAGE-FAIL 1)`), never a silent pass |
| S2-a | Unmapped APB slot holds `PREADY` low forever | **FIXED** | `pready` decoupled from `apb_sel`; test R4 went from *hang* to trap-with-cause-7 |
| S2-b | Slot decode used only `paddr[15:12]` over a 1 MB aperture → aliases | **FIXED** | decode now `paddr[19:12]`; test R5 (`0x5001_0000`) no longer aliases GPIO |
| S2-c | Partial writes return `PSLVERR` **and** modify the register | **FIXED** | `apb_write_ok` gates every peripheral `penable`; test R2/R3 |
| S3-a | `claim_id` only 3 bits for IDs 1–8 | **FIXED** | widened to 4 bits; `tb_plic_bounds` |
| S3-b | Priority index wraps at offset `0x020` | **FIXED** | index is now `4'(wr_addr[5:2] - 1)`; all eight priority registers independent |
| S4-a | CSR-immediate ops used register contents instead of zero-extended `zimm` | **FIXED** | `csr_zimm`/`csr_is_imm`/`csr_src`; `tb_csr_arch` A1 |
| S4-b | Illegal / read-only CSR accesses silently accepted | **FIXED** | `csr_known`/`csr_writable`/`csr_illegal`, `sys_illegal` |
| S4-c | CSR write-suppression rules wrong (CSRRW/CSRRWI must always write) | **FIXED** | `csr_we` |
| S4-d | `minstret` incremented on fetch, not on retirement | **FIXED** | incremented in S_EXEC (`!is_mem`) and on successful S_MEM completion; faulting instructions do not retire |
| S4-e | Misaligned `LHU` escaped the alignment check | **FIXED** | `mem_misaligned` covers `funct3 == 3'b101`; `tb_csr_arch` A6 |
| S5-a | Transaction path reset only by pad `reset_n`, not by `rst_sys_n` | **FIXED** | adapter, interconnect, ROM/TCM/SRAM ports, QSPI, APB bridge, INTC, fault FF now use `rst_sys_n`; `tb_reset_recovery` |
| S5-b | Reset "between write-address and write-data acceptance" | **NOT REPRODUCED as described** | The request adapter drives `AWVALID` and `WVALID` together and the APB bridge accepts both in the same cycle, so `have_aw=1 && have_w=0` is never observable. The equivalent injection (reset on that acceptance edge) is covered by P2, and "a write is never left half-accepted" is asserted continuously. No half-completed-write state was found to fix. |
| S6 | "No premature release" property may be tautological | **CONFIRMED and FIXED** | It was: `low_run > 0` holds exactly when `rst_sys_n` is low, so the assertion restated its own antecedent. Rewritten over `streak` (registered history). Mutation control now fails it. |

No finding was classified ALREADY FIXED, and nothing was BLOCKED.

### Pre-fix / post-fix discrimination

Each new test was compiled against an isolated pre-fix snapshot (never by
resetting the working tree):

| Test | Checks | Pre-fix | Post-fix |
|---|---|---|---|
| `tb_plic_bounds.v` (`build/prefix/plic_head.sv`) | 45 | **5 failures** | 0 |
| `tb_csr_arch.v` (`build/prefix/riscv_core_head.sv`) | 19 | **13 failures** | 0 |
| `tb_apb_integrated.v` (HEAD `rtl/` from `git archive`) | 11 | **7 failures** | 0 |
| `tb_reset_recovery.v` (`build/prefix/has_soc_resetprefix.sv`: current file with only the reset-domain wiring reverted) | 49 | **6 failures** | 0 |

Representative pre-fix failures (verbatim):

```
[plicb]  FAIL B1 claim reports the full source ID: got 0 expected 8
[plicb]  FAIL B2 0x020 is source 8 priority: got X
[plicb]  FAIL B3 priority register independent: got X
[csrarch] FAIL A1 csrrwi wrote zimm, not rf[7]: got 0xffffffff
[csrarch] FAIL A6 odd LHU did not write its destination: got 0x0000beef
[apbint] FAIL R2 rejected byte write had no side effect: got 0x000000ab expected 0x00001234
[apbint] FAIL R5 1 MB aperture address did not alias GPIO: got 0x00000000 expected 0x00001234
[apbint] FAIL R2/R3/R4/R5 all rejected accesses trapped: got 0x00000002 expected 0x00000004
[reset]  FAIL P1 request outstanding: adapter not in reset state
[reset]  FAIL P2 between AW and W: interconnect not in reset state
[reset]  FAIL P2 between AW and W: a write response survived the reset
```

The Step 4 test words were produced by GNU `riscv-none-elf-as` 12.2.0 from
`sim/asm/csr_arch.S` and inlined into the testbench, so the encodings do not come
from `scripts/fw/as.js` (the DUT-adjacent assembler).

---

## 3. Behaviour changes visible to software / integrators

1. **APB error responses now complete.** An access to an unmapped
   `paddr[19:12]` slot, or a partial-strobe write, completes in one ACCESS cycle
   with `PSLVERR`. Previously an unmapped slot stalled the bridge and therefore
   the CPU permanently. Software that relied on the stall to "detect" a bad
   address must instead handle the store/load access fault.
2. **The APB aperture decoded is 1 MB** (`0x5000_0000`–`0x500F_FFFF`), not 4 KB.
   Addresses above the GPIO register map that used to alias GPIO now fault.
3. **PLIC priority registers 1–8 are individually addressable** at
   `base + 4*id`. Earlier, the `0x020` register aliased another source's priority
   and sources 8 could not be claimed with their full ID in a 3-bit field.
4. **`minstret` now counts retired instructions.** Cycle-counting loops that
   previously observed it advance during a stalled load will see fewer
   increments.
5. **A watchdog reset now clears in-flight bus state.** Any transaction
   interrupted by a watchdog timeout is discarded; the restarted CPU sees no
   stale grant or response. Peripheral control registers are reset by that same
   pulse; memory contents (boot ROM, TCM, SRAM arrays, initialised only by
   `$readmemh`) persist and are the explicit persistence contract.

---

## 4. Changed files

Modified (10):

```
TAPEOUT_EVIDENCE_REGISTRY.md      (pre-existing change, untouched by this work)
rtl/rtl_peripherals/plic.sv
rtl/rtl_top/has_soc.sv
rtl/rtl_top/riscv_core.sv
scripts/eda/run_regression.js
scripts/firmware/run_e2e.js
scripts/formal/reset_ctrl_fv.sv
scripts/formal/run_formal.js
scripts/verify.js
sim/sim_top/tb_firmware.v         (+maxns plusarg, for the bounded negative control)
```

New (8):

```
sim/sim_top/tb_plic_bounds.v          1681417e260f47cd994e5bf4573cb708975352f9aca96fcf4b3b05ccad634a1e
sim/sim_top/tb_csr_arch.v             e391d6835f8ad73a1bc31446e87d4d8a8fa4d135f3d70b350bd1aba88c99635a
sim/sim_top/tb_apb_integrated.v       82bbeb4966ff6c95123b3bd2c5067684423156bb581660d112bc0aac3774d9ca
sim/sim_top/tb_reset_recovery.v       edc77de8adf14560460e9967b696c9d404e478f3cd64fb6be1d80384f8712310
sim/asm/csr_arch.S                    ecfcc5c23e39e2432d2f865351fbb4d2d523f0cacd6d9ff3211d11350b62dd6f
sim/asm/apb_integrated.S              2f8bd0ff8603ab14789f9e50f0295a1c7d86c6d055d574379debeeb4706490a1
scripts/formal/reset_ctrl_short.sby   04d817f41f80741ff722cc08324cb3b2df86837cb876ee5435801ad7c017c0b2
scripts/formal/reset_ctrl_cover.sby   bc145ca92b30c07a425cfee9a698579524a51d0b8d9c35170d4c824b92025045
```

---

## 5. Commands, tool versions, exit statuses

All runs from the repository root, with

```
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:/d/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin:$PATH"
```

| Command | Exit | Result |
|---|---|---|
| `node scripts/verify.js` | 0 | `9 passed, 0 failed, 0 blocked` (tools, verible-syntax, verible-lint, regression, formal, cdc-inventory, protocol-tests, mermaid, docs-sync) |
| `node scripts/eda/run_regression.js` | 0 | `PASS 26 / 26` |
| `node scripts/formal/run_formal.js` | 0 | `PASS 6 / 6` |
| `node scripts/firmware/run_e2e.js` | 0 | `7 / 7 steps passed`, `END-TO-END DEMONSTRATION: PASS` |
| `node scripts/verify.js --self-test` | 0 | `10/10` negative controls REJECTED |
| `node scripts/formal/run_formal.js --self-test` | 0 | `6/6` negative controls REJECTED (incl. the short-pulse mutation) |
| `node scripts/eda/run_regression.js --self-test` | 0 | silent / fail-marker / absent testbench all rejected |

Tool versions actually used:

```
Icarus Verilog 14.0 (devel) s20260301-500-g2e81fcccb-dirty
Verible v0.0-4298-g085eef05 (2026-10-29)
SBY v0.69
Yosys 0.69+154 (git sha1 30d62572e-dirty)
Node v26.7.0
riscv-none-elf-gcc (xPack) 12.2.0
```

Regression inventory (26 tests, totals derived from the executed list, not a
constant): isa, boot, uart, reset_ctrl, power_mgr, clint, plic, gpio, spi, i2c,
pwm, timer, watchdog, i2s, sram, debug_jtag, firmware, plic protocol, spi device,
jtag protocol, watchdog audit, sram audit, **plic bounds, cpu csr arch, apb
addressing (integrated), watchdog reset recovery**.

Formal inventory (6 tasks, mode and depth read from each `.sby`):

```
watchdog          bounded depth 96  smtbmc boolector
reset_ctrl        unbounded         abc pdr
reset_ctrl_cover  bounded depth 40  smtbmc boolector  (mode cover)
reset_ctrl_seq    bounded depth 60  smtbmc boolector
cdc_power_mgr     bounded depth 30  smtbmc boolector
plic_regs         bounded depth 52  smtbmc boolector
```

### Step 6 detail (exact assumptions)

- Reset model: `reset_ctrl_fv` contains a power-on model that holds `reset_n` low
  for `POR_LEN = 2` cycles and high afterwards; `wdog_timeout` is a **free input**
  (so the properties hold for any watchdog behaviour, including stuck-high).
- Parameters: `HOLD_EXPECT = 16` (what the properties demand),
  `HOLD_DUT = 16` (what the instance implements) — equal in `reset_ctrl.sby`,
  and `HOLD_DUT = 8` in `reset_ctrl_short.sby`.
- `reset_ctrl`: `mode prove`, `abc pdr` → **unbounded** proof of bounded width,
  prompt assertion, release timing and output consistency.
- `reset_ctrl_seq`: `mode bmc`, depth 60, `smtbmc boolector` → **directed
  bounded** proof of exact pulse width and phase on one concrete timeline.
- `reset_ctrl_cover`: `mode cover`, depth 40, `smtbmc boolector` → all four
  covers reached (mid-pulse antecedent reached at step 5, full width at step 19).
- Mutation control: `reset_ctrl_short.sby` produces
  `failed assertion reset_ctrl_fv._witness_.check_assert_reset_ctrl_fv_sv_116_25`
  at step 12 — that is the R1b line. If this ever stops failing, R1b has become
  vacuous again.
- Not asserted: "the pad reset forces both outputs low in the very first cycles
  after power-on". Yosys leaves DUT registers free in the initial state, so that
  window is not provable in this flow; `reset_ctrl_seq_fv.sv` covers it with a
  concrete timeline instead.

---

## 6. Firmware image and evidence hashes

Memory images are the meaningful provenance (identical across three independent
runs of the suite):

```
d948ee8ff94d0c87e5339afd04368f0d44eb4e9aaf52fb02005dc1b82926223a  build/fw/firmware.bin
c1fbc10cf3f035d123d9f5f7e86e4e47eba8f307dff54d36392585c015f1eb6f  build/fw/rom.hex
625cda23b1d18b90a790a18d308869c628a2bc006690340f216ed866d42c18da  build/fw/tcm.hex
d9a6be2a3e06484575501042786f90af4978658fad076b802f36053796aeb096  build/fw/boot.hex
8bcb3384c76c4175c113a9bfaa2adb8a131603df0169f6281986397add160b9b  build/sim/apb_jump.hex
66a4cf1564a339c7adb9d019836ed6176bcb899a05140ad14ae5ef933467b1f0  build/sim/apb_integrated.hex
```

`build/fw/firmware.elf` is **not** reproducible run to run — `90d7cee5…`,
`3f2ed186…` and `3a007944…` across three runs whose `.bin`/`.hex` outputs were
byte-identical — i.e. the ELF build metadata carries run-varying content. Hash
the `.bin`/`.hex` images, not the ELF, when recording provenance.

Evidence files: `build/verify/*.log`, `build/formal/*/logfile.txt`,
`build/e2e/*.log`, `build/closure_tree.patch`. These are locally available only —
**nothing was published to GitHub** and no branch was pushed.

---

## 7. Known limitations and remaining work

- **Directed simulation only.** The new tests are directed and bounded; no
  functional-coverage metric was collected, so "the tested behaviours pass" is
  what is shown, not "every behaviour is covered".
- **Formal scope is narrow.** Only `reset_ctrl` has an unbounded proof (and only
  for the pulse invariants). `watchdog`, `cdc_power_mgr`, `plic_regs`,
  `reset_ctrl_seq` and `reset_ctrl_cover` are bounded BMC at the depths listed
  above. No end-to-end SoC property was proven.
- **The image negative control is corruption sensitivity, not
  authenticated rejection.** The firmware contains no signature verifier, so no
  image authentication exists to test. What is asserted is one specific outcome:
  a corrupted `rom.hex` terminates on its own (bounded by `+maxns`) with zero
  UART characters and no `RESULT: PASS` marker, and infrastructure failures are
  never recorded as a rejection.
- **`tb_reset_recovery` forces watchdog internals** (`wdog_inst.expired`,
  `wdog_inst.reset_en`) to inject the timeout, because `wdog_timeout` is a
  continuous assignment and cannot be forced. Everything downstream —
  `reset_ctrl`, the reset tree and every consumer — is the real logic.
- **The Step 5 "between AW and W" window does not exist** in this
  implementation (see finding S5-b). It was replaced by an injection on the
  acceptance edge plus a continuous "never half-accepted" property, not silently
  dropped.
- `verilator --version` could not be obtained on this host (missing Perl
  `Pod::Usage`); the verification gate does not call it, so this affects nothing
  reported above.
- Clock architecture was deliberately left unchanged (no new clock domains),
  per scope.

### Follow-up findings (recorded, out of scope, not addressed here)

I²C write payload and read-NACK defects; flash address aliasing; incorrect DEF
units / row-grid interpretation in the placement report; missing published
evidence artifacts; incomplete package-pin budget; power sequencing and AON/PMIC
boot dependencies; unsupported pad-library claims. Also out of scope: 25 MHz /
AON clock domains, power gating/retention/UPF, extra UARTs, crypto accelerators,
full JTAG debug, I²C/flash feature work, and FPGA/board/physical design.

---

## 8. Next dependency-ordered task

The correctness items in this scope are closed, so the next dependency is
**integrating these RTL changes into the pending physical-design baseline**, not
another functional audit:

1. Re-run `node scripts/verify.js` on the committed version of this patch once it
   is reviewed and committed (the numbers above are for the uncommitted tree).
2. Re-run synthesis and the CTS/placement gate, because `has_soc.sv`
   (`paddr[19:12]` decode plus the `apb_write_ok` enable path) and `plic.sv`
   (4-bit claim path) changed combinational control that the existing reports
   were generated against.
3. Only then address the out-of-scope defects in §7, starting with I²C payload
   and flash aliasing, which are functional bugs of the same class as those fixed
   here.
