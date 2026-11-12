#!/usr/bin/env node
/*
 * Home-Automation-SoC — regression runner (Icarus Verilog)
 *
 * A test only counts as PASS if it compiles, runs, and prints its success
 * marker.  Everything else is FAIL, and the process exit status is nonzero.
 * This replaces the previous practice of judging a testbench by the presence
 * of a source file, and of accepting `$finish` after a FAIL line.
 *
 * Usage:
 *   node scripts/eda/run_regression.js [--verbose]
 *   node scripts/eda/run_regression.js --self-test
 *       Verifies that the harness itself rejects a silent testbench and a
 *       testbench that prints a failure marker but exits 0.  Exits 0 only if
 *       both are correctly rejected.
 *
 * Log: build/sim/regression.log
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'sim');
const verbose = process.argv.includes('--verbose');
const selfTest = process.argv.includes('--self-test');

function filelist() {
  return fs.readFileSync(path.join(ROOT, 'rtl', 'filelist.f'), 'utf8')
    .split('\n')
    .filter(l => l.trim() && !l.trim().startsWith('//'))
    .map(l => l.trim());
}

const RTL = filelist();
const CORE = ['rtl/rtl_top/riscv_core.sv'];
const PWR = ['rtl/rtl_peripherals/power_mgr_regs.sv', 'rtl/rtl_peripherals/power_mgr.sv'];
const UART = ['rtl/rtl_peripherals/uart.sv'];
const RST = ['rtl/rtl_top/reset_ctrl.sv'];
const PLIC = ['rtl/rtl_peripherals/plic.sv'];
const SPI  = ['rtl/rtl_peripherals/spi_ctrl.sv'];
const JTAG = ['rtl/rtl_peripherals/debug_jtag.sv'];
const WDOG = ['rtl/rtl_peripherals/watchdog.sv'];
const SRAM = ['rtl/rtl_top/sram.sv'];

// name, testbench, extra sources (undefined => whole SoC filelist), success marker
const TESTS = [
  { name: 'isa (directed RV32IM + traps)', tb: 'sim/sim_top/tb_isa.v',   src: CORE, marker: 'RESULT: PASS' },
  { name: 'boot (full SoC)',               tb: 'sim/sim_top/tb_boot.v',  src: null, marker: 'RESULT: PASS' },
  { name: 'uart (pin level)',              tb: 'sim/sim_top/tb_uart.v',  src: UART, marker: 'RESULT: PASS' },
  { name: 'reset_ctrl (watchdog reset)',   tb: 'sim/sim_top/tb_reset_ctrl.v', src: RST, marker: 'RESULT: PASS' },
  { name: 'power_mgr sleep/wake',          tb: 'sim/sim_top/tb_power_mgr.v', src: PWR, marker: 'RESULT: PASS' },
  { name: 'clint',                         tb: 'sim/sim_top/tb_clint.v', src: null, marker: 'ALL TESTS PASSED' },
  { name: 'plic',                          tb: 'sim/sim_top/tb_plic.v',  src: null, marker: 'ALL TESTS PASSED' },
  { name: 'gpio',                          tb: 'sim/sim_top/tb_gpio.v',  src: null, marker: 'ALL TESTS PASSED' },
  { name: 'spi',                           tb: 'sim/sim_top/tb_spi.v',   src: null, marker: 'ALL TESTS PASSED' },
  { name: 'i2c',                           tb: 'sim/sim_top/tb_i2c.v',   src: null, marker: 'ALL TESTS PASSED' },
  { name: 'pwm',                           tb: 'sim/sim_top/tb_pwm.v',   src: null, marker: 'ALL TESTS PASSED' },
  { name: 'timer',                         tb: 'sim/sim_top/tb_timer.v', src: null, marker: 'ALL TESTS PASSED' },
  { name: 'watchdog',                      tb: 'sim/sim_top/tb_watchdog.v', src: null, marker: 'ALL TESTS PASSED' },
  { name: 'i2s',                           tb: 'sim/sim_top/tb_i2s.v',   src: null, marker: 'ALL TESTS PASSED' },
  { name: 'sram',                          tb: 'sim/sim_top/tb_sram_simple.v', src: null, marker: 'ALL TESTS PASSED' },
  { name: 'debug_jtag',                    tb: 'sim/sim_top/tb_debug_jtag.v', src: null, marker: 'ALL TESTS PASSED' },
  { name: 'firmware (C demo)',              tb: 'sim/sim_top/tb_firmware.v', src: null, marker: 'RESULT: PASS' },
  // Phase-3 protocol and audit testbenches
  { name: 'plic protocol (sync + claim)',   tb: 'sim/sim_top/tb_plic_proto.v', src: PLIC, marker: 'PLIC PROTOCOL: ALL TESTS PASSED' },
  { name: 'spi device model (mode 0)',      tb: 'sim/sim_top/tb_spi_device.v', src: SPI, marker: 'SPI DEVICE: ALL TESTS PASSED' },
  { name: 'jtag protocol (TAP subset)',     tb: 'sim/sim_top/tb_jtag_proto.v', src: JTAG, marker: 'JTAG PROTOCOL: ALL TESTS PASSED' },
  { name: 'watchdog audit (reload)',        tb: 'sim/sim_top/tb_watchdog_audit.v', src: WDOG, marker: 'WATCHDOG AUDIT: ALL TESTS PASSED' },
  { name: 'sram audit (strobes/RAW)',       tb: 'sim/sim_top/tb_sram_audit.v', src: SRAM, marker: 'SRAM AUDIT: ALL TESTS PASSED' },
];

const FAIL_RE = /: FAIL|FAIL -|ERRORS|RESULT: FAIL|FATAL|error:/;

fs.mkdirSync(OUT, { recursive: true });
const log = [];
function emit(line) { log.push(line); console.log(line); }

function toolVersion(cmd, args) {
  const r = spawnSync(cmd, args, { cwd: ROOT, encoding: 'utf8' });
  const text = ((r.stdout || '') + (r.stderr || '')).split('\n').map(l => l.trim()).filter(Boolean);
  return text[0] || 'unavailable';
}

// Run one test definition; returns {status, detail}.
function runOne(t) {
  if (!t.tb) return { status: 'MISSING', detail: 'no testbench in tree' };
  if (!fs.existsSync(path.join(ROOT, t.tb))) return { status: 'MISSING', detail: 'source file not found' };
  const out = path.join(OUT, 'regress_' + path.basename(t.tb, path.extname(t.tb)) + '.vvp');
  const srcs = t.src ? t.src : RTL;
  // Remove any stale binary: a failed compile must never leave a runnable
  // artefact behind that a later run could quietly execute.
  if (fs.existsSync(out)) fs.unlinkSync(out);
  const build = spawnSync('iverilog', ['-g2012', '-o', out, '-s', path.basename(t.tb, path.extname(t.tb)), t.tb, ...srcs],
                          { cwd: ROOT, encoding: 'utf8', timeout: 120000 });
  if (build.status !== 0 || !fs.existsSync(out)) {
    const err = (build.stderr || '').split('\n').find(l => l.includes('error')) ||
                (build.stderr || '').split('\n')[0] || 'compile error';
    return { status: 'BUILD-FAIL', detail: err.trim() };
  }
  const run = spawnSync('vvp', [out], { cwd: ROOT, encoding: 'utf8', timeout: 300000 });
  const text = (run.stdout || '') + (run.stderr || '');
  if (verbose) emit(text);
  if (run.error && run.error.code === 'ETIMEDOUT') return { status: 'TIMEOUT', detail: 'exceeded 300 s' };
  if (run.status !== 0) return { status: 'FAIL', detail: 'exit ' + run.status };
  if (!text.includes(t.marker)) return { status: 'FAIL', detail: 'missing marker "' + t.marker + '"' };
  if (FAIL_RE.test(text)) {
    const bad = text.split('\n').find(l => FAIL_RE.test(l)) || '';
    return { status: 'FAIL', detail: bad.trim() };
  }
  return { status: 'PASS', detail: '' };
}

//--------------------------------------------------------------------------
// Harness self-test: a test that says nothing, and one that prints a failure
// but exits 0, must both be rejected.
//--------------------------------------------------------------------------
if (selfTest) {
  const dir = path.join(OUT, 'selfcheck');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'tb_silent.v'),
    'module tb_silent;\n  initial begin\n    $display("no marker here");\n    $finish;\n  end\nendmodule\n');
  fs.writeFileSync(path.join(dir, 'tb_failmark.v'),
    'module tb_failmark;\n  initial begin\n    $display("[self] FAIL: deliberate failure marker");\n    $finish;\n  end\nendmodule\n');

  const a = runOne({ name: 'silent', tb: 'build/sim/selfcheck/tb_silent.v', src: [], marker: 'RESULT: PASS' });
  const b = runOne({ name: 'fail-marker', tb: 'build/sim/selfcheck/tb_failmark.v', src: [], marker: 'RESULT: PASS' });
  const c = runOne({ name: 'absent', tb: null, src: [], marker: 'RESULT: PASS' });
  console.log('silent       -> ' + a.status + ' (' + a.detail + ')');
  console.log('fail-marker  -> ' + b.status + ' (' + b.detail + ')');
  console.log('no testbench -> ' + c.status + ' (' + c.detail + ')');
  const ok = a.status === 'FAIL' && b.status === 'FAIL' && c.status === 'MISSING';
  console.log(ok ? 'HARNESS SELF-TEST: PASS' : 'HARNESS SELF-TEST: FAIL');
  process.exit(ok ? 0 : 1);
}

//--------------------------------------------------------------------------
// Regression
//--------------------------------------------------------------------------
const results = [];

for (const t of TESTS) {
  const r = runOne(t);
  results.push({ ...t, ...r });
}

emit('');
emit('Home-Automation-SoC regression — Icarus Verilog');
emit('revision: ' + spawnSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: ROOT, encoding: 'utf8' }).stdout.trim());
emit('date    : ' + new Date().toISOString());
emit('iverilog: ' + toolVersion('iverilog', ['-V']));
emit('node    : ' + process.version);
emit('');
for (const r of results) {
  emit(r.status.padEnd(11) + r.name + (r.detail ? '  [' + r.detail + ']' : ''));
}
const passed = results.filter(r => r.status === 'PASS').length;
const missing = results.filter(r => r.status === 'MISSING').length;
emit('');
emit(`PASS ${passed} / ${results.length}` + (missing ? `  (MISSING ${missing})` : ''));

fs.writeFileSync(path.join(OUT, 'regression.log'), log.join('\n') + '\n');
process.exit(passed === results.length ? 0 : 1);
