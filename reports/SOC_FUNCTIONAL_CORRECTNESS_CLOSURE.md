# Home-Automation-SoC — SoC Functional Correctness Closure

## Final verdict

**FUNCTIONAL CORRECTNESS CLOSURE PASSED** — All scoped acceptance criteria passed with fresh evidence.

## Starting and ending Git SHAs

- Starting HEAD: `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1` (branch `main`, up to date with `origin/main`)
- Ending HEAD: `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1` (no commit, push, tag, or destructive Git operation)
- Initial working tree: clean
- Final working tree: 4 modified tracked files (no new files committed; report/evidence untracked)

## Files modified

1. `rtl/rtl_top/has_soc.sv` — APB full-address decode, unmapped completion, partial-write rejection, reset distribution
2. `rtl/rtl_peripherals/plic.sv` — claim ID width, priority indexing
3. `rtl/rtl_top/riscv_core.sv` — CSR immediate, unsupported CSR trap, minstret retirement, LHU misalignment
4. `scripts/formal/reset_ctrl_fv.sv` — non-tautological reset pulse property

## Defects closed

### APB
- Unmapped accesses now terminate (pready=1) with PSLVERR; no hang.
- Full-address decode eliminates aliases (upper 16 bits must be 0x5000).
- Partial-strobe writes rejected with PSLVERR and no peripheral write (penable gated).
- Reset distribution: transaction path now uses `rst_sys_n`.

### PLIC
- claim_id widened to `$clog2(NUM_SOURCES+1)` (4 bits for 8 sources) so ID 8 representable.
- Priority indexing uses `wr_addr[5:2]` to avoid 3-bit wrap at source 8.

### CPU
- CSR immediate uses 5-bit zimm.
- Unsupported CSR addresses trap (illegal instruction).
- minstret increments on retirement (S_EXEC non-mem, S_MEM on success), not fetch.
- LHU at odd addresses raises misaligned exception.

### Watchdog reset
- Transaction-path blocks now reset by `rst_sys_n` (watchdog pulse resets bus).
- Formal reset property R1b rewritten using prior-cycle `streak`.

## Verification results (fresh)

- Unified gate: 9/9 PASS
- Regression: 22/22 PASS
- Formal: 5/5 PASS
- E2E demo: PASS
- Verible lint: LINT_OK (0 unexpected violations)

## Tool versions

- Icarus Verilog 14.0
- Verible v0.0-4298
- SymbiYosys 0.69
- xPack RISC-V GCC 12.2.0

## Evidence paths

- `build/verify/*.log`, `build/verify/summary.txt`
- `build/e2e/*.log`
- `build/formal/*/runner.log`
- `reports/evidence/functional_closure/`
- Firmware ELF SHA-256: `e0bd4deba73cd10be79b5f0733df17b957f1b29fba04c0e73db73f16c1441373`

## Remaining limitations

- Authenticated boot / OTA / flash program-erase: not implemented (fail-closed).
- Physical sensor validation: simulation input only.
- Bus-fabric formal proof not present; JTAG/SPI subsets remain.
- No ASIC/FPGA signoff.