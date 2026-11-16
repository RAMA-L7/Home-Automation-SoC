# Home-Automation-SoC — SoC Functional Correctness Evidence Audit

## A. Repository identity

- Actual HEAD: `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`
- Reported baseline/final: `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`
- Branch: `main` (up to date with `origin/main`)
- Working tree: 4 modified tracked files + untracked closure report/evidence; no commit, push, tag, or stash performed.
- Evidence revision association: source edits are uncommitted on the reported HEAD; logs were regenerated during this audit and correspond to the current working tree.

## B. Verification infrastructure

Findings:
1. Unified gate (`scripts/verify.js`) — **VERIFIED**. Re-run result: 9/9 PASS, exit 0. It checks child exit code, fresh log mtime, success marker, and failure-pattern regex.
2. Negative controls in `verify.js` — **PARTIALLY VERIFIED**. Six synthetic cases exist and all reject PASS, but they do not cover tool crash, compilation failure, deliberate lint violation, or timeout/incomplete-result scenarios.
3. Formal runner (`scripts/formal/run_formal.js`) — **VERIFIED**. Re-run result: 5/5 PASS, exit 0. It requires `DONE (PASS, rc=0)`, deletes stale workdirs, and has five self-test cases.
4. E2E runner (`scripts/firmware/run_e2e.js`) — **PARTIALLY VERIFIED**. Re-run result: PASS, exit 0. However, its negative test treats a compile failure as rejection, counts timeouts as rejection, and mutates `build/fw/rom.hex` in place before restoring it. This weakens the negative control.
5. Tool/version handling — **VERIFIED**. Icarus 14.0, Verible v0.0-4298, SymbiYosys 0.69, xPack GCC 12.2.0 present and used.

## C. APB findings

- Source change: `rtl/rtl_top/has_soc.sv` now checks `paddr[31:16] == 16'h5000`, gates `penable` with `!apb_partial_write`, and sets `pready = 1`, `pslverr = (apb_sel == 0) || (penable && partial_write)`.
- Unmapped/partial behavior: **VERIFIED at source level** (inspection of RTL).
- Full-address decode: **VERIFIED at source level**.
- Baseline-failure evidence: **NOT VERIFIED**. No APB-targeted testbench or mutation log demonstrates failure on the original implementation. Regression/e2e provide only indirect evidence.
- Transaction-path reset uses `rst_sys_n`: **VERIFIED at source level**.

## D. PLIC findings

- Source change: `claim_id` widened to `$clog2(NUM_SOURCES+1)` (4 bits), priority indexing changed to `wr_addr[5:2]`.
- Width and indexing: **VERIFIED at source level**.
- End-to-end source-8 behavior: **NOT VERIFIED**. The formal harness (`plic_regs_fv.sv`) exercises only sources 1–3; no simulation or formal evidence covers source 8's priority register, claim, or completion.
- Arbitration/tie-breaking: **PARTIALLY VERIFIED** (formal covers tie between sources 2 and 3 only).

## E. CPU findings

- CSR immediate: source now uses 5-bit `zimm` for immediate forms — **VERIFIED at source level**.
- Unsupported CSR: now traps — **VERIFIED at source level**.
- minstret: now increments on retirement paths — **VERIFIED at source level**.
- LHU alignment: now includes `funct3 == 3'b101` in `mem_misaligned` — **VERIFIED at source level**.
- Test evidence: `tb_isa.v` covers many ISA cases and misaligned load/store, but does **not** test CSR immediates, unsupported CSR, minstret counting, or LHU at odd addresses. **NOT VERIFIED** for those claims.

## F. Watchdog reset findings

- Reset distribution changed from `reset_n` to `rst_sys_n` across transaction-path blocks — **VERIFIED at source level**.
- Formal reset pulse: `reset_ctrl` unbounded + directed BMC PASS — **VERIFIED**.
- Corrected R1b property uses prior-cycle `streak` — **VERIFIED** and meaningful.
- Transaction-phase recovery tests: **NOT VERIFIED**. No test injects reset during AXI/APB phases or checks stale responses. Only end-to-end firmware reboot is demonstrated.

## G. Formal verification

- All 5 tasks PASS (5/5), exit 0 — **VERIFIED**.
- `reset_ctrl` unbounded PDR; others bounded BMC with stated depths — **VERIFIED**.
- Scope: directed stimulus only; does not prove arbitrary bus traffic or software — **PARTIALLY VERIFIED** as general correctness.

## H. Evidence quality

- Logs exist and are non-empty except `negative.log` (0 bytes) — **PARTIALLY VERIFIED**.
- Revision markers and tool versions present in formal log — **VERIFIED**.
- Firmware ELF SHA-256 computed: `e0bd4deba73cd10be79b5f0733df17b957f1b29fba04c0e73db73f16c1441373` — **VERIFIED**.
- Evidence directory is git-ignored (`*.log`) and not tracked — **PARTIALLY VERIFIED** (reproducible locally only).
- No baseline-failing test evidence for the newly closed defects — **NOT VERIFIED**.

## I. Final verdict

**APPROVED WITH FINDINGS**

Core RTL corrections are present and source-consistent, and the unified gate, regression, formal, and E2E runners pass. However, several closure claims lack targeted, baseline-failing, or phase-level evidence.

## Finding counts

- VERIFIED: 9
- PARTIALLY VERIFIED: 6
- NOT VERIFIED: 6
- FAILED: 0
- BLOCKED: 0

## Critical remaining gaps

1. No targeted tests for APB unmapped/partial-write behavior or baseline failure.
2. No test coverage for PLIC source 8.
3. No tests for CSR immediates, unsupported CSR, minstret, or LHU alignment.
4. No transaction-phase reset-injection tests.
5. E2E negative control counts compile failure/timeout as rejection and mutates an artifact.
6. `negative.log` is empty.