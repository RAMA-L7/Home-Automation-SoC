#!/usr/bin/env node
/*
 * Home-Automation-SoC — I2C timing verification with negative controls (F10)
 *
 * Runs:
 *   1. tb_i2c_timing at the declared operating point (pclk 50 MHz, CLKDIV 124)
 *      and requires the standard-mode contract to be met at the pins.
 *   2. the same binary with a divider that is far too small: the timing checks
 *      MUST fail.  A bench that cannot fail is not a check.
 *   3. tb_i2c_xfer (functional payload/NACK/STOP) on the current RTL.
 *   4. tb_i2c_xfer against a mutant that releases SCL and SDA together at the
 *      STOP: the invalid-STOP control MUST fail.
 *   5. tb_i2c_timing against a mutant whose START hold time is one quarter:
 *      the tHD;STA check MUST fail.
 *
 * Mutants are generated into build/evidence/i2c_timing/mutants/ from the
 * current RTL by exact string replacement.  If a replacement does not apply,
 * the runner fails: a silently unmutated control proves nothing.
 *
 * Usage:
 *   node scripts/eda/run_i2c_timing.js
 *   node scripts/eda/run_i2c_timing.js --verbose
 *
 * Exit: 0 all expectations met, 1 a check or a control behaved incorrectly,
 *       2 required tool missing.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'evidence', 'i2c_timing');
const MUT = path.join(OUT, 'mutants');
const TB = 'sim/sim_top/tb_i2c_timing.v';
const TB_FUNC = 'sim/sim_top/tb_i2c_xfer.v';
const RTL = 'rtl/rtl_peripherals/i2c_ctrl.sv';
const verbose = process.argv.includes('--verbose');

const TOOL_DIR = process.env.EDA_TOOLS || 'D:/tools/oss-cad-suite';
const env = { ...process.env };
env.PATH = [path.join(TOOL_DIR, 'bin'), path.join(TOOL_DIR, 'lib'), env.PATH].join(path.delimiter);

fs.mkdirSync(MUT, { recursive: true });

const results = [];
function record(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}: ${detail}`);
}

function run(cmd, args, tag, timeoutMs = 600000) {
  const r = spawnSync(cmd, args, {
    cwd: ROOT, env, encoding: 'utf8', timeout: timeoutMs, maxBuffer: 64 * 1024 * 1024,
  });
  const text = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(path.join(OUT, `${tag}.log`), `$ ${cmd} ${args.join(' ')}\n\n${text}`);
  if (verbose) console.log(text);
  if (r.error && r.error.code === 'ENOENT') return { missing: true, status: -1, text };
  return { status: r.status === null ? -1 : r.status, text, timedOut: r.status === null };
}

function compile(tag, tb, rtl, top) {
  const vvp = path.join(OUT, `${tag}.vvp`);
  if (fs.existsSync(vvp)) fs.unlinkSync(vvp);
  const c = run('iverilog', ['-g2012', '-o', vvp, '-s', top, tb, rtl], `${tag}_compile`);
  if (c.missing) return { missing: true };
  if (c.status !== 0 || !fs.existsSync(vvp)) {
    return { error: `compile failed (exit ${c.status}); see build/evidence/i2c_timing/${tag}_compile.log` };
  }
  return { vvp };
}

// ---------------------------------------------------------------------------
// Mutant generation.  Each mutant must actually differ, or the control is void.
// ---------------------------------------------------------------------------
function mutate(name, replacements) {
  const src = fs.readFileSync(path.join(ROOT, RTL), 'utf8');
  let out = src;
  for (const [from, to] of replacements) {
    if (!out.includes(from)) {
      return { error: `mutation anchor not found in ${RTL}: ${JSON.stringify(from)}` };
    }
    out = out.split(from).join(to);
  }
  if (out === src) return { error: `mutation produced an identical file (${name})` };
  const file = path.join(MUT, `${name}.sv`);
  fs.writeFileSync(file, out, 'utf8');
  return { file: path.relative(ROOT, file).split(path.sep).join('/'), changed: diffLines(src, out) };
}

function diffLines(a, b) {
  const al = a.split('\n');
  const bl = b.split('\n');
  let n = 0;
  for (let i = 0; i < Math.max(al.length, bl.length); i++) if (al[i] !== bl[i]) n++;
  return n;
}

// ---------------------------------------------------------------------------
// 1. the declared operating point
// ---------------------------------------------------------------------------
let r = compile('timing', TB, RTL, 'tb_i2c_timing');
if (r.missing) {
  console.log('BLOCKED  iverilog/vvp not found (set EDA_TOOLS)');
  console.log('I2C_TIMING_RUNNER: BLOCKED');
  process.exit(2);
}
if (r.error) { record('timing compile', false, r.error); }
else {
  const v = run('vvp', [r.vvp], 'timing_run');
  const ok = v.status === 0 && v.text.includes('I2C_TIMING: ALL CHECKS PASSED');
  const m = v.text.match(/fSCL=([\d.]+) kHz[\s\S]*?tBUF=([\d.]+) ns/);
  record('timing @ 100 kHz', ok,
    `exit ${v.status}, ${m ? `fSCL=${m[1]} kHz, tBUF=${m[2]} ns` : 'summary not found'}`);

  // 2. too-short divider must be rejected
  const fast = run('vvp', [r.vvp, '+clkdiv=8'], 'timing_control_short');
  const shortOk = fast.status !== 0 && /FAIL T[1-8]/.test(fast.text);
  record('control: too-short divider rejected', shortOk,
    `exit ${fast.status} (expected non-zero), ${(fast.text.match(/FAIL T\d/g) || []).length} timing check(s) failed`);
}

// ---------------------------------------------------------------------------
// 3. functional bench on the current RTL
// ---------------------------------------------------------------------------
let f = compile('functional', TB_FUNC, RTL, 'tb_i2c_xfer');
if (f.missing) {
  console.log('BLOCKED  iverilog/vvp not found');
  console.log('I2C_TIMING_RUNNER: BLOCKED');
  process.exit(2);
}
if (f.error) record('functional compile', false, f.error);
else {
  const v = run('vvp', [f.vvp], 'functional_run');
  record('functional transactions', v.status === 0 && v.text.includes('TB_I2C_XFER: ALL TESTS PASSED'),
    `exit ${v.status}`);
}

// ---------------------------------------------------------------------------
// 4. control: STOP that releases both lines in the same quarter
// ---------------------------------------------------------------------------
const stopMutant = mutate('i2c_stop_release_both', [[
  "        // Hold SDA low for the first half of the state, then release it: the\n" +
  "        // rise happens while SCL is already high (a valid STOP, with setup).\n" +
  "        // Releasing both lines together is not a STOP condition.\n" +
  "        sda_drive_low = (q < 2'd2);",
  "        sda_drive_low = 1'b0;   // MUTANT: SCL and SDA released together",
]]);
if (stopMutant.error) record('control: simultaneous STOP release', false, stopMutant.error);
else {
  const c = compile('functional_stop_mutant', TB_FUNC, stopMutant.file, 'tb_i2c_xfer');
  if (c.error) record('control: simultaneous STOP release', false, c.error);
  else {
    const v = run('vvp', [c.vvp], 'functional_stop_mutant_run');
    const ok = v.status !== 0 &&
               (/invalid STOP/i.test(v.text) || /no STOP condition/i.test(v.text));
    record('control: simultaneous STOP release rejected', ok,
      `exit ${v.status} (expected non-zero), ${v.text.includes('invalid STOP') ? 'invalid STOP reported' : 'STOP missing'}`);
  }
}

// ---------------------------------------------------------------------------
// 5. control: START hold time reduced to one quarter
// ---------------------------------------------------------------------------
const startMutant = mutate('i2c_start_one_quarter', [[
  "      I_START_A: if (q_done && q == 2'd1) state_n = I_START_B;",
  "      I_START_A: if (q_done) state_n = I_START_B;   // MUTANT: one quarter",
]]);
if (startMutant.error) record('control: short START hold', false, startMutant.error);
else {
  const c = compile('timing_start_mutant', TB, startMutant.file, 'tb_i2c_timing');
  if (c.error) record('control: short START hold', false, c.error);
  else {
    const v = run('vvp', [c.vvp], 'timing_start_mutant_run');
    const ok = v.status !== 0 && /FAIL T6 tHD;STA/.test(v.text);
    record('control: short START hold rejected', ok,
      `exit ${v.status} (expected non-zero), ${ok ? 'tHD;STA failed as required' : 'tHD;STA did not fail'}`);
  }
}

// ---------------------------------------------------------------------------
const bad = results.filter(x => !x.ok);
console.log('');
for (const x of results) console.log(`  ${x.ok ? 'PASS' : 'FAIL'}  ${x.name}`);
console.log('');
console.log(`I2C_TIMING_RUNNER: ${bad.length === 0 ? 'PASS' : 'FAIL'} (${results.length - bad.length}/${results.length})`);
process.exit(bad.length === 0 ? 0 : 1);
