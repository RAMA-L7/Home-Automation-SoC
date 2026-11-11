#!/usr/bin/env node
/*
 * Home-Automation-SoC — regression runner (Icarus Verilog)
 *
 * A test only counts as PASS if it compiles, runs, and prints its success
 * marker.  Everything else is FAIL, and the process exit status is nonzero.
 * This replaces the previous practice of judging a testbench by the presence
 * of a source file, and of accepting `$finish` after a FAIL line.
 *
 * Usage:  node scripts/eda/run_regression.js [--verbose]
 * Log:    build/sim/regression.log
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'sim');
const verbose = process.argv.includes('--verbose');

function filelist() {
  return fs.readFileSync(path.join(ROOT, 'rtl', 'filelist.f'), 'utf8')
    .split('\n')
    .filter(l => l.trim() && !l.trim().startsWith('//'))
    .map(l => l.trim());
}

const RTL = filelist();
const CORE = ['rtl/rtl_top/riscv_core.sv'];
const PWR = ['rtl/rtl_peripherals/power_mgr_regs.sv', 'rtl/rtl_peripherals/power_mgr.sv'];

// name, testbench, extra sources (undefined => whole SoC filelist), success marker
const TESTS = [
  { name: 'isa (directed RV32IM)', tb: 'sim/sim_top/tb_isa.v',            src: CORE, marker: 'RESULT: PASS' },
  { name: 'boot (full SoC)',       tb: 'sim/sim_top/tb_boot.v',           src: null, marker: 'RESULT: PASS' },
  { name: 'power_mgr sleep/wake',  tb: 'sim/sim_top/tb_power_mgr.v',      src: PWR,  marker: 'RESULT: PASS' },
  { name: 'clint',                 tb: 'sim/sim_top/tb_clint.v',          src: null, marker: 'ALL TESTS PASSED' },
  { name: 'plic',                  tb: 'sim/sim_top/tb_plic.v',           src: null, marker: 'ALL TESTS PASSED' },
  { name: 'gpio',                  tb: 'sim/sim_top/tb_gpio.v',           src: null, marker: 'ALL TESTS PASSED' },
  { name: 'uart (none)',           tb: null,                              src: null, marker: null },
  { name: 'spi',                   tb: 'sim/sim_top/tb_spi.v',            src: null, marker: 'ALL TESTS PASSED' },
  { name: 'i2c',                   tb: 'sim/sim_top/tb_i2c.v',            src: null, marker: 'ALL TESTS PASSED' },
  { name: 'pwm',                   tb: 'sim/sim_top/tb_pwm.v',            src: null, marker: 'ALL TESTS PASSED' },
  { name: 'timer',                 tb: 'sim/sim_top/tb_timer.v',          src: null, marker: 'ALL TESTS PASSED' },
  { name: 'watchdog',              tb: 'sim/sim_top/tb_watchdog.v',       src: null, marker: 'ALL TESTS PASSED' },
  { name: 'i2s',                   tb: 'sim/sim_top/tb_i2s.v',            src: null, marker: 'ALL TESTS PASSED' },
  { name: 'sram',                  tb: 'sim/sim_top/tb_sram_simple.v',    src: null, marker: 'ALL TESTS PASSED' },
  { name: 'debug_jtag',            tb: 'sim/sim_top/tb_debug_jtag.v',     src: null, marker: 'ALL TESTS PASSED' },
];

const FAIL_RE = /: FAIL|FAIL -|ERRORS|RESULT: FAIL|FATAL|error:/;

fs.mkdirSync(OUT, { recursive: true });
const log = [];
function emit(line) { log.push(line); console.log(line); }

const results = [];
let hardFail = 0;

for (const t of TESTS) {
  if (!t.tb) { results.push({ ...t, status: 'MISSING', detail: 'no testbench in tree' }); hardFail++; continue; }
  const out = path.join(OUT, 'regress_' + path.basename(t.tb, path.extname(t.tb)) + '.vvp');
  const srcs = t.src ? t.src : RTL;
  const build = spawnSync('iverilog', ['-g2012', '-o', out, '-s', path.basename(t.tb, path.extname(t.tb)), t.tb, ...srcs],
                          { cwd: ROOT, encoding: 'utf8', timeout: 120000 });
  if (build.status !== 0) {
    results.push({ ...t, status: 'BUILD-FAIL', detail: (build.stderr || '').split('\n').find(l => l.includes('error')) || 'compile error' });
    hardFail++;
    continue;
  }
  const run = spawnSync('vvp', [out], { cwd: ROOT, encoding: 'utf8', timeout: 300000 });
  const text = (run.stdout || '') + (run.stderr || '');
  if (verbose) emit(text);
  if (run.error && run.error.code === 'ETIMEDOUT') {
    results.push({ ...t, status: 'TIMEOUT', detail: 'exceeded 300 s' }); hardFail++; continue;
  }
  if (run.status !== 0) {
    results.push({ ...t, status: 'FAIL', detail: 'exit ' + run.status }); hardFail++; continue;
  }
  if (!text.includes(t.marker)) {
    results.push({ ...t, status: 'FAIL', detail: 'missing marker "' + t.marker + '"' }); hardFail++; continue;
  }
  if (FAIL_RE.test(text)) {
    const bad = text.split('\n').find(l => FAIL_RE.test(l)) || '';
    results.push({ ...t, status: 'FAIL', detail: bad.trim() }); hardFail++; continue;
  }
  results.push({ ...t, status: 'PASS', detail: '' });
}

emit('');
emit('Home-Automation-SoC regression — Icarus Verilog');
emit('revision: ' + spawnSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: ROOT, encoding: 'utf8' }).stdout.trim());
emit('date    : ' + new Date().toISOString());
emit('');
for (const r of results) {
  emit(r.status.padEnd(11) + r.name + (r.detail ? '  [' + r.detail + ']' : ''));
}
const passed = results.filter(r => r.status === 'PASS').length;
emit('');
emit(`PASS ${passed} / ${results.length}`);

fs.writeFileSync(path.join(OUT, 'regression.log'), log.join('\n') + '\n');
process.exit(hardFail === 0 ? 0 : 1);
