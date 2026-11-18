#!/usr/bin/env node
/* Home-Automation-SoC — end-to-end firmware demonstration runner.
 *
 *   node scripts/firmware/run_e2e.js
 *
 * Builds the C firmware, generates per-memory hex images, runs the full-SoC
 * simulation (tb_firmware.v), runs a negative (corrupted image) test, and
 * writes fresh logs under build/e2e/. Exits 0 only when every step passes.
 */
const { spawnSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'e2e');
const EDA_TOOLS = process.env.EDA_TOOLS || 'D:/tools/oss-cad-suite';
const { findToolchain } = require(path.join(ROOT, 'scripts', 'fw_build', 'toolchain'));

// One discovery path for the whole project (F6): the compiler resolved here is
// the compiler the child build/genmem drivers resolve, because the bin
// directory is exported to them rather than being re-derived or hardcoded.
const tc = findToolchain();
if (tc.error) {
  console.error('BLOCKED: ' + tc.error);
  process.exit(2);
}
const env = { ...tc.env };
const pathKey = Object.keys(env).find(k => k.toUpperCase() === 'PATH') || 'PATH';
env[pathKey] = [path.join(EDA_TOOLS, 'bin'), path.join(EDA_TOOLS, 'lib'), env[pathKey] || '']
  .join(path.delimiter);
if (tc.binDir) env.RISCV_TOOLCHAIN_BIN = tc.binDir;

console.log(`toolchain: ${tc.gccPath} [${tc.source}]`);
console.log(`  ${tc.version}`);

fs.mkdirSync(OUT, { recursive: true });

function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { cwd: ROOT, env, encoding: 'utf8', ...opts });
  return { status: r.status === null ? 1 : r.status, stdout: r.stdout || '', stderr: r.stderr || '', error: r.error };
}

function log(name, text) {
  const p = path.join(OUT, name);
  fs.writeFileSync(p, text, 'utf8');
  return p;
}

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

let failed = null;
const results = [];

// 1. tool check
{
  const checks = [];
  for (const t of ['iverilog', 'vvp']) {
    const r = run(t, []);
    const present = !r.error;
    checks.push(`${t}: ${present ? 'OK' : 'MISSING'}`);
    if (!present && !failed) failed = t + ' not found';
  }
  const gcc = run(tc.gccPath, ['--version']);
  const gccPresent = !gcc.error && gcc.status === 0;
  checks.push(`${tc.prefix}gcc: ${gccPresent ? 'OK' : 'MISSING'} (${tc.gccPath}, ${tc.source})`);
  if (!gccPresent && !failed) failed = `${tc.gccPath} did not run`;
  log('tools.log', checks.join('\n') + '\n');
  results.push({ name: 'tools', status: failed ? 'FAIL' : 'PASS' });
  console.log(checks.join('\n'));
}

if (failed) {
  console.error('BLOCKED: ' + failed);
  process.exit(2);
}

// 2. build firmware.  The previous outputs are deleted first so a failed build
//    cannot leave an artefact behind that the simulation would happily load.
{
  const startedAt = Date.now();
  for (const a of ['build/fw/firmware.elf', 'build/fw/firmware.bin']) {
    fs.rmSync(path.join(ROOT, a), { force: true });
  }
  const r = run(process.execPath, [path.join(ROOT, 'scripts', 'fw_build', 'build_fw.js')]);
  const text = r.stdout + r.stderr;
  log('build.log', text);
  const fresh = ['build/fw/firmware.elf', 'build/fw/firmware.bin'].every(a => {
    const p = path.join(ROOT, a);
    return fs.existsSync(p) && fs.statSync(p).mtimeMs >= startedAt;
  });
  const ok = r.status === 0 && text.includes('OK:') && fresh;
  if (!ok && !failed) failed = 'firmware build failed';
  results.push({ name: 'build', status: ok ? 'PASS' : 'FAIL' });
  console.log('build:', ok ? 'PASS' : 'FAIL');
}

// 3. validate artifacts (freshness, not mere existence)
{
  const lines = [];
  let ok = true;
  for (const a of ['build/fw/firmware.elf', 'build/fw/firmware.bin']) {
    const p = path.join(ROOT, a);
    const exists = fs.existsSync(p);
    lines.push(`${a}: ${exists ? 'present' : 'MISSING'}`);
    if (!exists) ok = false;
  }
  log('artifacts.log', lines.join('\n') + '\n');
  if (!ok && !failed) failed = 'missing build artifacts';
  results.push({ name: 'artifacts', status: ok ? 'PASS' : 'FAIL' });
}

// 4. generate per-memory hex (previous hex deleted first: a stale image must not
//    be able to stand in for one this run failed to produce)
{
  for (const a of ['build/fw/rom.hex', 'build/fw/tcm.hex']) {
    fs.rmSync(path.join(ROOT, a), { force: true });
  }
  const startedAt = Date.now();
  const r = run(process.execPath, [path.join(ROOT, 'scripts', 'fw_build', 'gen_fw_mem.js'), 'build/fw/firmware.elf']);
  const text = r.stdout + r.stderr;
  log('genmem.log', text);
  const fresh = ['build/fw/rom.hex', 'build/fw/tcm.hex'].every(a => {
    const p = path.join(ROOT, a);
    return fs.existsSync(p) && fs.statSync(p).mtimeMs >= startedAt;
  });
  const ok = r.status === 0 && fresh;
  if (!ok && !failed) failed = 'gen_fw_mem failed';
  results.push({ name: 'genmem', status: ok ? 'PASS' : 'FAIL' });
  console.log('genmem:', ok ? 'PASS' : 'FAIL');
}

// 5. image provenance: record what the simulation will actually load.
{
  const lines = [];
  for (const a of ['build/fw/firmware.elf', 'build/fw/firmware.bin', 'build/fw/rom.hex', 'build/fw/tcm.hex']) {
    const p = path.join(ROOT, a);
    lines.push(`${fs.existsSync(p) ? sha256(p) : 'MISSING'.padEnd(64)}  ${a}`);
  }
  log('provenance.log', lines.join('\n') + '\n');
  console.log('image sha256:');
  for (const l of lines) console.log('  ' + l);
  results.push({ name: 'provenance', status: 'PASS' });
}

// 5. positive simulation
{
  const vvp = path.join(OUT, 'tb_firmware.vvp');
  if (fs.existsSync(vvp)) fs.unlinkSync(vvp);
  const rtl = fs.readFileSync(path.join(ROOT, 'rtl', 'filelist.f'), 'utf8')
    .split('\n').filter(l => l.trim() && !l.trim().startsWith('//')).map(l => l.trim());
  const c = run('iverilog', ['-g2012', '-o', vvp, '-s', 'tb_firmware', 'sim/sim_top/tb_firmware.v', ...rtl]);
  let text = c.stdout + c.stderr;
  if (c.status !== 0) {
    log('positive.log', text);
    if (!failed) failed = 'positive compile failed';
    results.push({ name: 'positive', status: 'FAIL' });
  } else {
    const r = run('vvp', [vvp]);
    text = r.stdout + r.stderr;
    log('positive.log', text);
    const ok = r.status === 0 && text.includes('RESULT: PASS') && !/RESULT: FAIL|FATAL/.test(text);
    if (!ok && !failed) failed = 'positive simulation did not PASS';
    results.push({ name: 'positive', status: ok ? 'PASS' : 'FAIL' });
    console.log('positive:', ok ? 'PASS' : 'FAIL');
  }
}

// 7. Negative control: corrupted ROM image.
//
// This is a **corruption sensitivity** check, not an authenticated-rejection
// check: this firmware has no signature verifier linked, so nothing in the DUT
// validates an image.  What the test can honestly assert is one specific
// supported outcome — the corrupted image does not produce the clean-pass
// marker.  Anything that prevents the simulation from running (compile failure,
// missing simulator, crash, host timeout, silent output) is an infrastructure
// result and must NOT be recorded as "corruption rejected", which is what the
// previous version did.
{
  const romPath = path.join(ROOT, 'build', 'fw', 'rom.hex');
  const original = fs.readFileSync(romPath, 'utf8');
  const originalSha = sha256(romPath);
  const lines = original.split('\n');
  const corruptible = lines.length > 0 && /^[0-9a-fA-F]{8}$/.test(lines[0].trim());
  if (corruptible) lines[0] = 'deadbeef';
  fs.writeFileSync(romPath, lines.join('\n'), 'utf8');
  const corruptSha = sha256(romPath);

  const vvp = path.join(OUT, 'tb_firmware_neg.vvp');
  if (fs.existsSync(vvp)) fs.unlinkSync(vvp);
  const rtl = fs.readFileSync(path.join(ROOT, 'rtl', 'filelist.f'), 'utf8')
    .split('\n').filter(l => l.trim() && !l.trim().startsWith('//')).map(l => l.trim());

  const c = run('iverilog', ['-g2012', '-o', vvp, '-s', 'tb_firmware', 'sim/sim_top/tb_firmware.v', ...rtl]);
  const text0 = c.stdout + c.stderr;

  let verdictDetail;
  let ok;
  if (!corruptible) {
    ok = false;
    verdictDetail = 'rom.hex is not a word image; corruption was not applied';
  } else if (corruptSha === originalSha) {
    ok = false;
    verdictDetail = 'corruption did not change the image';
  } else if (c.error || c.status !== 0) {
    ok = false;
    verdictDetail = `compile failed (infrastructure): ${c.error ? c.error.code : 'exit ' + c.status}`;
  } else {
    // `+maxns` bounds the simulation itself, just past the point where the good
    // image prints RESULT: PASS (it finishes at ~67 ms of sim time).  The
    // corrupted image therefore terminates on its own with its own timeout
    // marker and can never be mistaken for a host timeout.
    const r = run('vvp', [vvp, '+maxns=70000000'], { timeout: 600000 });
    const text = r.stdout + r.stderr;
    const timedOut = r.error && r.error.code === 'ETIMEDOUT';
    if (timedOut) {
      ok = false;
      verdictDetail = 'host timeout (infrastructure, not a rejection)';
    } else if (r.error && r.error.code === 'ENOENT') {
      ok = false;
      verdictDetail = 'simulator not found (infrastructure)';
    } else if (r.error || r.status === null) {
      ok = false;
      verdictDetail = 'simulator did not complete (infrastructure)';
    } else if (!text.trim()) {
      ok = false;
      verdictDetail = 'silent simulator output (infrastructure)';
    } else if (r.status === 0 && text.includes('RESULT: PASS')) {
      ok = false;
      verdictDetail = 'corrupted image still produced RESULT: PASS';
    } else {
      // Specific supported outcome: the run completed and did not report a pass.
      ok = true;
      const observed = /RESULT: FAIL/.test(text) ? 'RESULT: FAIL'
                     : /FATAL/.test(text) ? 'FATAL'
                     : `no pass marker (exit ${r.status})`;
      verdictDetail = 'observed ' + observed;
    }
    log('negative.log', text);
  }
  if (!fs.existsSync(path.join(OUT, 'negative.log'))) log('negative.log', text0);

  fs.writeFileSync(romPath, original, 'utf8');
  const restored = sha256(romPath) === originalSha;
  if (!restored && !failed) failed = 'rom.hex was not restored after the negative control';

  if (!ok && !failed) failed = `corrupted-image control inconclusive: ${verdictDetail}`;
  results.push({ name: 'negative (corruption sensitivity)', status: ok && restored ? 'PASS' : 'FAIL' });
  console.log('negative (corruption sensitivity):', ok && restored ? 'PASS' : 'FAIL', '-', verdictDetail);
}

// summary
console.log('\n--- e2e summary ---');
for (const r of results) console.log(`${r.status.padEnd(6)} ${r.name}`);
// Counts come from this run's executed step list, never from a constant.
const passed = results.filter(r => r.status === 'PASS').length;
console.log(`\n${passed} / ${results.length} steps passed`);
const allPass = passed === results.length && !failed;
console.log(allPass ? '\nEND-TO-END DEMONSTRATION: PASS' : '\nEND-TO-END DEMONSTRATION: FAIL');
process.exit(allPass ? 0 : 1);
