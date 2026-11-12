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
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'e2e');
const TOOL_BIN = process.env.RISCV_TOOLCHAIN_BIN || 'D:/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin';
const IVERILOG = process.env.IVERILOG || 'iverilog';
const VVP = process.env.VVP || 'vvp';

const env = { ...process.env };
env.RISCV_TOOLCHAIN_BIN = TOOL_BIN;
env.PATH = ['D:\\tools\\oss-cad-suite\\bin', 'D:\\tools\\oss-cad-suite\\lib', TOOL_BIN, env.PATH || ''].join(path.delimiter);

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
  const gcc = run('riscv-none-elf-gcc', ['--version']);
  const gccPresent = !gcc.error;
  checks.push(`riscv-none-elf-gcc: ${gccPresent ? 'OK' : 'MISSING'}`);
  if (!gccPresent && !failed) failed = 'riscv-none-elf-gcc not found';
  log('tools.log', checks.join('\n') + '\n');
  results.push({ name: 'tools', status: failed ? 'FAIL' : 'PASS' });
  console.log(checks.join('\n'));
}

if (failed) {
  console.error('BLOCKED: ' + failed);
  process.exit(2);
}

// 2. build firmware
{
  const r = run(process.execPath, [path.join(ROOT, 'scripts', 'fw_build', 'build_fw.js')]);
  const text = r.stdout + r.stderr;
  log('build.log', text);
  const ok = r.status === 0 && text.includes('OK:');
  if (!ok && !failed) failed = 'firmware build failed';
  results.push({ name: 'build', status: ok ? 'PASS' : 'FAIL' });
  console.log('build:', ok ? 'PASS' : 'FAIL');
}

// 3. validate artifacts
{
  const arts = ['build/fw/firmware.elf', 'build/fw/firmware.bin', 'build/fw/rom.hex', 'build/fw/tcm.hex'];
  // rom.hex/tcm.hex generated next; check elf/bin now
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

// 4. generate per-memory hex
{
  const r = run(process.execPath, [path.join(ROOT, 'scripts', 'fw_build', 'gen_fw_mem.js'), 'build/fw/firmware.elf']);
  const text = r.stdout + r.stderr;
  log('genmem.log', text);
  const ok = r.status === 0 && fs.existsSync(path.join(ROOT, 'build/fw/rom.hex')) && fs.existsSync(path.join(ROOT, 'build/fw/tcm.hex'));
  if (!ok && !failed) failed = 'gen_fw_mem failed';
  results.push({ name: 'genmem', status: ok ? 'PASS' : 'FAIL' });
  console.log('genmem:', ok ? 'PASS' : 'FAIL');
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

// 6. negative test: corrupted image (expect failure)
{
  const romPath = path.join(ROOT, 'build', 'fw', 'rom.hex');
  const backup = fs.readFileSync(romPath, 'utf8');
  // corrupt first word
  const lines = backup.split('\n');
  if (lines.length > 0 && lines[0].length === 8) {
    lines[0] = 'deadbeef';
  }
  fs.writeFileSync(romPath, lines.join('\n'), 'utf8');

  const vvp = path.join(OUT, 'tb_firmware_neg.vvp');
  if (fs.existsSync(vvp)) fs.unlinkSync(vvp);
  const rtl = fs.readFileSync(path.join(ROOT, 'rtl', 'filelist.f'), 'utf8')
    .split('\n').filter(l => l.trim() && !l.trim().startsWith('//')).map(l => l.trim());
  const c = run('iverilog', ['-g2012', '-o', vvp, '-s', 'tb_firmware', 'sim/sim_top/tb_firmware.v', ...rtl]);
  let text = c.stdout + c.stderr;
  let negPassed = false;
  if (c.status !== 0) {
    negPassed = true; // compile fail counts as rejection
  } else {
    const r = run('vvp', [vvp], { timeout: 120000 });
    text = r.stdout + r.stderr;
    // Expected: no RESULT: PASS, or nonzero exit, or timeout
    negPassed = !(r.status === 0 && text.includes('RESULT: PASS'));
  }
  log('negative.log', text);
  // restore rom.hex
  fs.writeFileSync(romPath, backup, 'utf8');

  if (!negPassed && !failed) failed = 'negative test did not reject corrupted image';
  results.push({ name: 'negative', status: negPassed ? 'PASS' : 'FAIL' });
  console.log('negative (corrupted image rejected):', negPassed ? 'PASS' : 'FAIL');
}

// summary
console.log('\n--- e2e summary ---');
for (const r of results) console.log(`${r.status.padEnd(6)} ${r.name}`);
const allPass = results.every(r => r.status === 'PASS') && !failed;
console.log(allPass ? '\nEND-TO-END DEMONSTRATION: PASS' : '\nEND-TO-END DEMONSTRATION: FAIL');
process.exit(allPass ? 0 : 1);
