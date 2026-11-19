# RUN-0010 — toolchain discovery unification (F6)

- **Local / UTC:** 2026-11-18 20:39–20:52 IST (2026-11-18T15:09–15:22Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Reviewer:** self (same agent) — **not independent**
- **Base:** `025ef24` + dirty worktree; no RTL, testbench or acceptance criterion touched
- **Finding:** F6 — some build entry points bypass shared toolchain discovery

## Verdict

**F6 PASS.** There is now one resolver, `scripts/fw_build/toolchain.js`, and every
entry point either calls it or delegates to a driver that does. Resolution is
validated, deterministic, and fail-closed; the conflicting configurations that
used to disagree silently now stop the run with exit 2.

This is a script/plumbing result only. It says nothing about tapeout readiness,
and it does not close G4.4 (no independent evaluator).

## The defect, as found

| Entry point | Before | Effect |
|---|---|---|
| `scripts/firmware/run_e2e.js` | `TOOL_BIN = env \|\| 'D:/tools/xpack-...-12.2.0-2/bin'`; exported `RISCV_TOOLCHAIN_BIN`; probed `riscv-none-elf-gcc` via PATH | worked only on a machine with that exact directory |
| `scripts/fw_build/build_fw.py` | own `find_toolchain()` over `shutil.which`, default `riscv32-unknown-elf-`; output to `scripts/fw_build/build/` | ignored `RISCV_TOOLCHAIN_BIN` and the installed xPack tree; could pick a different compiler than the Node build, and produced a second, stale artefact set |
| `scripts/fw_build/build_fw.bat` | required `RISCV_GCC_PREFIX`, no discovery | failed unless the caller pre-configured it |
| `scripts/verify.js` | tools stage checked only EDA tools | the gate could not tell whether a RISC-V compiler existed at all |
| `scripts/fw_build/build_fw.js`, `gen_fw_mem.js` | already used `findToolchain()` | correct model, no target/flag validation |

## What was implemented

1. **One resolver, validated.** Candidates are probed, not merely located:
   `-dumpmachine` must start with `riscv`, `--version` must run,
   `-march=rv32im -mabi=ilp32 -fsyntax-only` must be accepted (the core has no C
   extension), and `objcopy --version` must run. A directory that exists but
   holds a broken or wrong-target compiler is rejected.
2. **Explicit precedence**, printed with every resolution:
   `findToolchain({prefix|binDir})` → `RISCV_GCC_PREFIX` → `RISCV_TOOLCHAIN_BIN`
   → known prefixes on `PATH` (absolute path reported) → installed
   `xpack-riscv-none-elf-gcc-*` under `D:\tools`, newest first.
   A bin directory is addressed by absolute path, so a different compiler earlier
   on `PATH` cannot shadow it.
3. **No silent fallback.** A bad `RISCV_GCC_PREFIX` or `RISCV_TOOLCHAIN_BIN` is an
   error, not a hint. A prefix and a bin directory that disagree is reported as a
   conflict naming both variables.
4. **Python delegates.** `build_fw.py` runs `toolchain.js --json` and uses the
   result; its private discovery is deleted. Its output directory is now
   `build/fw/`, the directory the regression runner and genmem already read.
5. **Batch wrapper delegates.** `build_fw.bat` runs `build_fw.js`; it no longer
   contains build logic or a precondition on the environment.
6. **Gate and logs record the compiler.** The `tools` stage resolves the
   toolchain and blocks the gate if it cannot; `run_regression.js` prints the
   resolved compiler so a 27/27 log identifies the compiler that built the images
   it tested.

## Evidence

| Check | Result | Log |
|---|---|---|
| Discovery controls (10, incl. 5 negative) | **10/10, exit 0** | `logs/toolchain_test.log` |
| Resolved compiler | xPack GCC **12.2.0**, target `riscv-none-elf`, `[installed]` | `logs/toolchain_resolution.log` |
| `build_fw.js` | exit 0, same gcc path, `.text` 3684 B | `logs/build_fw.log` |
| `build_fw.py` | exit 0, same gcc path | `logs/build_fw_py.log` |
| `gen_fw_mem.js` | exit 0, rom 26 / tcm 895 words | `logs/gen_fw_mem.log` |
| `run_e2e.js` | **7/7**, positive PASS, corruption control FAILs as designed | `logs/e2e.log` |
| Regression | **27/27**, log names the compiler | `logs/regression_stage.log` |
| Unified gate | **10 passed / 0 failed / 0 blocked**, exit 0 | `logs/gate.log` |
| Negative controls (driver level) | 6/6 fail closed with exit 2 | `logs/negative_controls.log` |

Negative controls exercised: missing bin directory, bogus
`RISCV_GCC_PREFIX`, prefix/bin conflict, broken `riscv-none-elf-gcc.exe`,
non-RISC-V target rejection (unit), plus the same bad override driven through
`build_fw.js`, `run_e2e.js` and the gate's `tools` stage. Positives: default
resolution and an explicit `RISCV_TOOLCHAIN_BIN` override.

## Limitations (do not overstate this result)

- Windows only. The POSIX install-root branch is implemented, not executed.
- Only one real toolchain exists here, so the conflict control pairs the
  installed bin directory with a prefix it does not contain; two valid but
  different toolchains were not available to compare.
- No host compiler exists to relabel as a fake "RISC-V" binary, so the
  wrong-target path is unit-tested (`isRiscvMachine`) plus the broken-executable
  control, not against a genuine mislabelled compiler.
- `build_fw.py` requires `node`; without it the driver exits 2 by design.
- `build_fw.py` no longer writes `scripts/fw_build/build/`; that old directory is
  neither migrated nor cleaned.
- Verification used the project's own checkers and tests. Self-reviewed; no
  independent evaluator exists in this environment, so G4.4 remains open.

## Reproduction

```bash
node scripts/fw_build/toolchain_test.js
node scripts/fw_build/build_fw.js
D:/tools/venv/Scripts/python.exe scripts/fw_build/build_fw.py build
node scripts/fw_build/gen_fw_mem.js
node scripts/firmware/run_e2e.js
node scripts/verify.js
RISCV_GCC_PREFIX=bogus-riscv- node scripts/verify.js --only=tools   # expect exit 2
```
