# Home-Automation-SoC — Final Release Readiness Audit

Date: 2026-11-12
Agent: Buffy (model: DeepSeek V4.1 Flash)

## 1. Starting and ending Git revisions

- Starting HEAD: `f96dd3d7eb2d1f9cbb766caf046dd3489c326505` (branch `main`)
- Ending HEAD: `f96dd3d7eb2d1f9cbb766caf046dd3489c326505` (no commit, push, tag, or destructive Git operation performed)
- All changes remain in the working tree.

## 2. Initial and final working-tree status

Initial: 23 modified tracked files + 14 untracked (Phase 3 deliverables) + 32 deleted `scripts/formal/cdc/` artifacts.
Final: 64 changed files in diff (tracked) plus untracked deliverables; no commits. Verification evidence preserved under `build/verify/*.log` and `build/sim/*.vvp`.

## 3. Files modified in this closure pass

| File | Why |
|------|-----|
| `rtl/rtl_top/sram.sv` | Gated `wr_fire` with `reset_n` so reset reliably aborts an in-flight write |
| `rtl/rtl_peripherals/debug_jtag.sv` | Corrected clock-ratio comment (10x) and supported-subset comment |
| `sim/sim_top/tb_sram_audit.v` | T10 rewritten to assert reset during a pending (T10a) and active (T10b) write; added check counter (24 checks) |
| `sim/sim_top/tb_watchdog_audit.v` | Added check counter (19 checks) |
| `scripts/formal/cdc_inventory.js` | Reclassified `periph_irq -> PLIC` as synchronous path; updated check count (18) |
| `reports/verification/README.md` | Reconciled counts (plic 18, watchdog 19, sram 24); corrected CDC rows |
| `docs/verification/formal_cdc_verification_plan.md` | §9/§9.1 updated; revision 1.4 |
| `AGENTS.md` | §16 closure note |

## 4. Confirmed defects and corrections

1. **SRAM reset test did not interrupt a write.** Original T10 asserted reset after the write had already fired. Corrected to T10a (reset while pending) and T10b (reset during active response). Verified mem unchanged when aborted, committed when active. `wr_fire` gated by `reset_n` so reset is deterministic.
2. **CDC misclassification.** `periph_irq -> PLIC` was described as an async CDC while both ends use gated copies of `clk`. Reclassified as synchronous path; the 2-FF synchroniser is retained as defensive for the documented port contract.
3. **JTAG clock ratio overstated.** Documented minimum 4x fails in simulation (14 failures); reliable minimum is 10x. Corrected in RTL header.
4. **PAUSE state reachability.** RTL comments incorrectly claimed PAUSE_* unreachable; the transition table reaches them on TMS=0 in EXIT1. Corrected.
5. **Test counts.** Reconciled: watchdog audit 19, sram audit 24, plic protocol 18.

## 5. SRAM reset test evidence

- Command: `iverilog -g2012 -s tb_sram_audit ... && vvp ...`
- Result: `SRAM AUDIT: 24 checks run, 0 failures` then `SRAM AUDIT: ALL TESTS PASSED`.
- T10a: reset asserted in the same cycle as valids, before acceptance. FSM returns idle; address 0x700 retains preloaded `0x12345678` (write did not land).
- T10b: write fires, then reset during S_WRESP. FSM returns idle, `bvalid` cleared, address 0x700 reads `0xFFFF0000` (committed value persists; SRAM is not cleared on reset).
- RTL contract: `mem` has no reset branch; only `state`/address registers reset.

## 6. CDC classification results

`node scripts/formal/cdc_inventory.js` → 12 rows, `structural checks: all rows match the RTL`, exit 0.

| Row | Classification |
|-----|----------------|
| uart_rx, gpio[..] | async pin, 2-FF |
| ext_irq[31:0] pads | unused (PLIC fed by periph_irq) |
| periph_irq -> plic.ext_irq | synchronous path (gated clk); defensive 2-FF |
| spi_miso | protocol (SCK from pclk) |
| jtag_tms/tdi/tck | async, 2-FF |
| jtag_trst_n | unused |
| wake_ack | async, 2-FF (formally proven) |
| i2s_din | unused |
| core_clk / periph_clk | gated clock (synchronous) |

No metastability/MTBF/silicon claim made.

## 7. PLIC review results

- 2-FF synchroniser + rising-edge capture (`irq_meta/irq_sync/irq_prev`, `irq_event`) retained. Source is synchronous (periph_irq on gated clk), so the 2-FF is defensive, not a CDC. Removal would save latency but the module port contract documents async-capable input.
- Rising-edge capture is redundant for purely level-sensitive sources but enables capture of a pulse that arrives while claimed; tested by T4 of `tb_plic_proto.v` (18 checks) and formal `plic_regs` (depth 52).
- Priority, threshold, claim, completion, tie-breaking (lowest ID) verified by `tb_plic_proto.v` and `plic_regs_fv.sv`.
- Reset and simultaneous claim/assertion: T7 covers reset-while-pending.
- `plic_regs` is a directed register-semantic proof, not bus-fabric formal verification.

## 8. JTAG protocol and timing results

- Full IEEE 1149.1 next-state table (all 16 states) implemented; TDI shifts in SHIFT_DR/SHIFT_IR.
- 2-FF synchronisers on TCK/TMS/TDI; TAP advances on detected `tck_rise`.
- TDO is registered one shift edge later than strict 1149.1 (documented limitation).
- `trst_n` declared but unused (TAP reset by system reset or 5x TMS high).
- No DMI/DTM/IDCODE/boundary scan.
- Minimum reliable clock ratio measured: clk >= 10x TCK (4x fails). Testbench uses 10x.
- `tb_jtag_proto.v`: PASS, 16 transitions covered.

## 9. SPI protocol results

- Mode 0 (CPOL=0, CPHA=0), MSB-first, 8-bit, programmable divider.
- MISO sampled at end of SCK high phase (fixed receive-path bug; old loopback test hid it).
- Patterns verified: 0x3C, 0xA5, 0x5A, 0x00, 0xFF, 0xC3, 0x96, back-to-back, reset mid-transfer.
- `pstrb` ignored (documented limitation).
- No synchroniser on MISO (SCK generated by pclk; no second domain).

## 10. Exact test counts

| Testbench | Checks |
|-----------|--------|
| tb_plic_proto.v | 18 |
| tb_spi_device.v | 5 transfers, both directions |
| tb_jtag_proto.v | 16 state transitions |
| tb_watchdog_audit.v | 19 |
| tb_sram_audit.v | 24 |

Regression: 22 / 22 PASS. Formal: 5 / 5 PASS.

## 11. Verible lint results and remaining baseline

- Parser: 0 syntax errors.
- Lint: project rules in `lint/verible.rules`; only `parameter-name-style` deviations remain, pinned per file in `lint/localparam_style_baseline.txt`:
  - uart.sv: 1
  - axi_lite_interconnect.sv: 1
  - has_addr_map.sv: 34
  - riscv_core.sv: 18
  - Total: 54
- `verify.js` fails on any other violation, new file, or changed count.

## 12. Unified verification results

`node scripts/verify.js` → 9 / 9 PASS, exit 0.

| Task | Result |
|------|--------|
| tools | PASS |
| verible-syntax | PASS |
| verible-lint | PASS |
| regression | PASS 22 / 22 |
| formal | PASS 5 / 5 |
| cdc-inventory | PASS |
| protocol-tests | PASS 5 / 5 |
| mermaid | PASS |
| docs-sync | PASS |

## 13. Formal results

| Task | Engine | Depth | Result |
|------|--------|-------|--------|
| watchdog | smtbmc boolector | 96 | PASS |
| reset_ctrl | abc pdr | unbounded | PASS |
| reset_ctrl_seq | smtbmc boolector | 60 | PASS |
| cdc_power_mgr | smtbmc boolector | 30 | PASS |
| plic_regs | smtbmc boolector | 52 | PASS |

## 14. Regression results

22 / 22 PASS, exit 0 (Icarus 14.0).

## 15. Negative-control results

`node scripts/verify.js --self-test` → 6 / 6 rejected (failed sim, failed assertion, missing tool, missing config, stale PASS log, incomplete result).
`node scripts/formal/run_formal.js --self-test` → 5 / 5 rejected.

## 16. Remaining technical blockers

- No ASIC signoff / FPGA qualification / silicon validation.
- JTAG: no DMI/DTM/IDCODE/boundary scan; TDO one shift edge late; trst_n unused.
- SPI: mode 0 only; pstrb ignored.
- SRAM: two read ports on one array (needs dual-port macro for ASIC).
- Level-sensitive inputs can miss pulses shorter than two clk cycles.
- Bus fabric has no formal proof.
- Secure boot / OTA / flash program-erase not implemented (fail-closed).
- No full-SoC formal; core-level formal not run.

## 17. Release verdict

**APPROVED WITH LIMITATIONS**

Core checks pass (unified gate 9/9, formal 5/5, regression 22/22, negative controls 6/6), known limitations are documented, and no unresolved critical defect remains in the scoped RTL. Non-critical limitations (JTAG subset, SPI mode 0, SRAM macro, bus-fabric formal, physical design) remain and are documented.

Not READY FOR ASIC SIGNOFF: full ASIC signoff evidence has not been established.
EOF
echo done