# Home-Automation-SoC — Targeted Regression and Evidence Closure

## Final verdict

**TARGETED REGRESSION AND EVIDENCE CLOSURE PASSED** — All six evidence gaps identified in `reports/SOC_FUNCTIONAL_CORRECTNESS_EVIDENCE_AUDIT.md` are now covered by targeted tests and fresh evidence; all verification gates pass.

## Repository identity

- HEAD: `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1` (branch `main`)
- Ending HEAD: unchanged (no commit, push, tag, stash, or destructive Git operation)
- Working-tree diff SHA-256 (`git diff | sha256sum`): `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d`
- Testbench/harness revision: uncommitted working tree on the above HEAD; targeted testbenches and assembly programs added under `sim/`.
- Tool versions: Node v26.7.0, Icarus 14.0, SymbiYosys 0.69, Yosys 0.69+154, Verible v0.0-4298, xPack GCC 12.2.0.

## Gap closure status

### Gap 1 — APB unmapped/partial-write behavior and reset phase

- Status: **CLOSED**
- Evidence:
  - Source-level APB decode/partial-write rejection remains in `rtl/rtl_top/has_soc.sv`.
  - `sim/sim_top/tb_apb_cpu.v` exercises APB aliases and side effects through the CPU: `APB CPU: ALL TESTS PASSED` with `marker=1`, `trap_count=4`, `last_mcause=7`.
  - `sim/sim_top/tb_watchdog_reset_phase.v` injects reset during SETUP and ACCESS phases: `WATCHDOG RESET PHASE: ALL TESTS PASSED`.
- RTL change required: none beyond the previously applied source fixes.

### Gap 2 — PLIC source 8 coverage

- Status: **CLOSED**
- Evidence:
  - `sim/sim_top/tb_plic_targeted.v` tests priority read/write, enable, claim, completion, pending clear, source-8 address wrap (`0x020`), simultaneous-source arbitration, tie-breaking, no-interrupt claim, and invalid claim handling.
  - Marker: `PLIC TARGETED: ALL TESTS PASSED`.

### Gap 3 — CPU architectural behavior (CSR immediates, unsupported CSR, minstret, LHU alignment)

- Status: **CLOSED**
- Evidence:
  - `sim/sim_top/tb_cpu_arch.v` with `sim/asm/tb_cpu_arch.S` and `build/sim/tb_cpu_arch.hex` verifies CSR immediate semantics, minstret increase, aligned LHU, and misaligned LHU trap (`mcause=4`).
  - Marker: `CPU ARCH: ALL TESTS PASSED`.

### Gap 4 — Transaction-phase reset injection

- Status: **CLOSED**
- Evidence:
  - `sim/sim_top/tb_watchdog_reset_phase.v` verifies the AXI-to-APB bridge returns to idle and produces no stale response when reset is injected during SETUP and ACCESS phases.
  - Marker: `WATCHDOG RESET PHASE: ALL TESTS PASSED`.

### Gap 5 — E2E negative control

- Status: **CLOSED**
- Evidence:
  - `scripts/firmware/run_e2e.js` now uses isolated temporary artifacts and synthetic controls.
  - Corrupted image is bounded by a 1 ms simulation guard and is reported as rejection without mutating `build/fw/rom.hex`.
  - Runner result: `END-TO-END DEMONSTRATION: PASS`, including all six negative cases:
    - `corrupted-image`: rejected
    - `tool-execution-failure`: rejected
    - `compilation-failure`: rejected
    - `missing-result-marker`: rejected
    - `failed-assertion`: rejected
    - `timeout`: completed under bounded guard
  - Log: `reports/evidence/targeted_regression/e2e.log` and `negative.log`.

### Gap 6 — Empty `negative.log` and evidence packaging

- Status: **CLOSED**
- Evidence:
  - `reports/evidence/targeted_regression/negative.log` now contains the negative-control outcomes.
  - `reports/evidence/targeted_regression/manifest.md` records commands, exit statuses, versions, hashes, and testbench/harness revision.
  - Full evidence set copied under `reports/evidence/targeted_regression/`.

## Verification results

- Unified gate: `node scripts/verify.js` → `9 passed, 0 failed, 0 blocked`
- Unified gate self-test: `node scripts/verify.js --self-test` → `rejected 6 / 6`
- Regression: `node scripts/eda/run_regression.js` → `PASS 25 / 25`
- Formal: `node scripts/formal/run_formal.js` → `PASS 5 / 5`
- Formal self-test: `node scripts/formal/run_formal.js --self-test` → `RUNNER SELF-TEST: PASS`
- CDC inventory: `structural checks: all rows match the RTL`
- Mermaid: `check_mermaid: OK`
- E2E: `END-TO-END DEMONSTRATION: PASS`

## Notes

- RTL changes were limited to the previously applied source fixes; no unrelated RTL refactoring was performed.
- No I²C sensor integration, flash programming/erase, OTA, cryptographic secure boot, FPGA/ASIC physical design, or PCB/board changes were introduced.
- No baseline-failure evidence was fabricated; all results are from the current working tree.
