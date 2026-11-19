#!/usr/bin/env node
/*
 * Home-Automation-SoC — toolchain discovery controls (F6).
 *
 * Proves that the one shared resolver behaves deterministically and fails
 * loudly, and that the drivers which consume it resolve the same compiler:
 *
 *   1. default resolution succeeds and reports a real RISC-V compiler
 *   2. missing toolchain (bogus RISCV_TOOLCHAIN_BIN) -> exit 2
 *   3. bogus RISCV_GCC_PREFIX -> exit 2, not silently ignored
 *   4. conflicting RISCV_GCC_PREFIX + RISCV_TOOLCHAIN_BIN -> exit 2
 *   5. a broken executable in the bin directory -> exit 2
 *   6. non-RISC-V target strings are rejected (unit control: see note)
 *   7. repeated resolution is identical (no PATH-order drift)
 *   8. PATH-based resolution returns the same compiler as installed-scan
 *   9. build_fw.js resolves the same gcc path as the resolver
 *  10. build_fw.py resolves the same gcc path as the resolver (skipped if the
 *      interpreter is unavailable — reported, never counted as a pass)
 *
 * Note on control 6: this machine has no host gcc to rename into a fake
 * "riscv" compiler, so the reject path is asserted on isRiscvMachine() directly
 * plus the real broken-executable case (5). A real wrong-target binary is not
 * available and is not simulated beyond that.
 *
 * Exit: 0 all controls pass, 1 a control failed, 2 the resolver itself is
 * unavailable (the controls cannot run).
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const TOOLCHAIN = path.join(ROOT, 'scripts', 'fw_build', 'toolchain.js');
const BUILD_JS = path.join(ROOT, 'scripts', 'fw_build', 'build_fw.js');
const BUILD_PY = path.join(ROOT, 'scripts', 'fw_build', 'build_fw.py');
const PYTHON = process.env.PYTHON || 'D:/tools/venv/Scripts/python.exe';

const results = [];
function record(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? ' — ' + detail : ''}`);
}

function baseEnv() {
  const env = { ...process.env };
  delete env.RISCV_GCC_PREFIX;
  delete env.RISCV_TOOLCHAIN_BIN;
  return env;
}

function runNode(args, env) {
  const r = spawnSync(process.execPath, args, { cwd: ROOT, env, encoding: 'utf8' });
  return { status: r.status === null ? 1 : r.status, out: (r.stdout || '') + (r.stderr || '') };
}

function resolveJson(env) {
  const r = runNode([TOOLCHAIN, '--json'], env);
  let json = null;
  try { json = JSON.parse(r.out); } catch { /* error text is not JSON */ }
  return { ...r, json };
}

// ---- 1. default resolution ------------------------------------------------
const base = baseEnv();
const def = resolveJson(base);
if (def.status !== 0 || !def.json || !def.json.ok) {
  record('default resolution', false, def.out.trim().split('\n')[0] || 'no output');
  console.log('\nTOOLCHAIN_TEST: BLOCKED');
  process.exit(2);
}
record('default resolution', true,
  `${def.json.gccPath} [${def.json.source}] ${def.json.version}`);

// ---- 2. missing toolchain -------------------------------------------------
{
  const env = { ...base, RISCV_TOOLCHAIN_BIN: path.join(os.tmpdir(), 'ha-soc-no-such-toolchain') };
  const r = resolveJson(env);
  const msg = (r.json && r.json.error) || r.out;
  record('missing bin directory fails with exit 2', r.status === 2 && /contains no usable RISC-V toolchain/.test(msg),
    `exit ${r.status}`);
}

// ---- 3. bogus prefix is not ignored --------------------------------------
{
  const env = { ...base, RISCV_GCC_PREFIX: 'bogus-riscv-' };
  const r = resolveJson(env);
  const msg = (r.json && r.json.error) || r.out;
  record('bogus RISCV_GCC_PREFIX is an error, not a fallback',
    r.status === 2 && /RISCV_GCC_PREFIX="bogus-riscv-"/.test(msg) && /not ignored/.test(msg),
    `exit ${r.status}`);
}

// ---- 4. conflicting configuration ----------------------------------------
{
  const env = {
    ...base,
    RISCV_GCC_PREFIX: 'riscv32-unknown-elf-',
    RISCV_TOOLCHAIN_BIN: def.json.binDir,
  };
  const r = resolveJson(env);
  const msg = (r.json && r.json.error) || r.out;
  record('conflicting prefix/bin configuration fails with exit 2',
    r.status === 2 && /conflicting configuration/.test(msg), `exit ${r.status}`);
}

// ---- 5. broken executable -------------------------------------------------
const fakeDir = fs.mkdtempSync(path.join(os.tmpdir(), 'ha-soc-fake-tc-'));
let fakeOk = false;
{
  // A copy of node named like the compiler: -dumpmachine is not a valid node
  // option, so the probe cannot mistake it for a working RISC-V gcc.
  fs.copyFileSync(process.execPath, path.join(fakeDir, 'riscv-none-elf-gcc.exe'));
  const env = { ...base, RISCV_TOOLCHAIN_BIN: fakeDir };
  const r = resolveJson(env);
  fakeOk = r.status === 2 && /did not run|not a RISC-V compiler|not usable/.test(r.out);
  record('broken compiler executable fails with exit 2', fakeOk, `exit ${r.status}`);
}

// ---- 6. wrong-target rejection (unit) ------------------------------------
{
  const { isRiscvMachine } = require(TOOLCHAIN);
  const bad = ['x86_64-w64-mingw32', 'arm-none-eabi', '', 'RISC-V' /* case-insensitive accept */];
  const rejected = !isRiscvMachine(bad[0]) && !isRiscvMachine(bad[1]) && !isRiscvMachine(bad[2]);
  const accepted = isRiscvMachine('riscv-none-elf') && isRiscvMachine('riscv32-unknown-elf');
  record('non-RISC-V targets are rejected', rejected && accepted,
    'x86_64/arm rejected, riscv-none-elf and riscv32 accepted');
}

// ---- 7. determinism -------------------------------------------------------
{
  const a = resolveJson(base), b = resolveJson(base);
  record('repeated resolution is identical',
    a.status === 0 && b.status === 0 && a.json.gccPath === b.json.gccPath &&
    a.json.version === b.json.version, a.json.gccPath === b.json.gccPath ? 'same gcc path' : 'paths differ');
}

// ---- 8. PATH resolution agrees with installed scan ----------------------
{
  const env = baseEnv();
  const pathKey = Object.keys(env).find(k => k.toUpperCase() === 'PATH') || 'PATH';
  env[pathKey] = def.json.binDir + path.delimiter + env[pathKey];
  const r = resolveJson(env);
  record('PATH resolution selects the same compiler',
    r.status === 0 && path.resolve(r.json.gccPath) === path.resolve(def.json.gccPath),
    r.status === 0 ? `source=${r.json.source}, ${r.json.gccPath}` : `exit ${r.status}`);
}

// ---- 9. Node build driver agrees ----------------------------------------
{
  const r = runNode([BUILD_JS], base);
  const m = r.out.match(/^toolchain: (.+?) \[/m);
  record('build_fw.js resolves the same gcc path',
    r.status === 0 && !!m && path.resolve(m[1]) === path.resolve(def.json.gccPath),
    m ? m[1] : `build exit ${r.status}`);
}

// ---- 10. Python driver agrees (skipped if no interpreter) ----------------
{
  const havePython = fs.existsSync(PYTHON);
  if (!havePython) {
    record('build_fw.py resolves the same gcc path', false,
      `SKIPPED: interpreter not found at ${PYTHON}`);
  } else {
    const r = spawnSync(PYTHON, [BUILD_PY, 'build'], { cwd: ROOT, env: base, encoding: 'utf8' });
    const out = (r.stdout || '') + (r.stderr || '');
    const m = out.match(/^toolchain: (.+?) \[/m);
    record('build_fw.py resolves the same gcc path',
      r.status === 0 && !!m && path.resolve(m[1]) === path.resolve(def.json.gccPath),
      m ? m[1] : `python exit ${r.status}`);
  }
}

fs.rmSync(fakeDir, { recursive: true, force: true });

const failed = results.filter(r => !r.ok).length;
console.log('');
console.log(`TOOLCHAIN_TEST: ${results.length - failed}/${results.length} controls passed`);
process.exit(failed === 0 ? 0 : 1);
