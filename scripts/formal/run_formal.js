#!/usr/bin/env node
/*
 * Home-Automation-SoC — formal verification runner (SymbiYosys)
 *
 * Fail-closed by design, matching scripts/eda/run_regression.js:
 *
 *   PASS  requires exit code 0 *and* the exact marker "DONE (PASS, rc=0)".
 *   Every other outcome — FAIL, UNKNOWN, TIMEOUT, a missing task, a missing
 *   tool, or any other exit code — is a failure and returns a nonzero status.
 *
 * A `prep`-only (property-free) task can never produce "DONE (PASS)" in prove
 * mode, and such scaffolds were removed from this directory; the tasks listed
 * below all contain assertions that can fail (see --self-test case 1).
 *
 * Stale evidence cannot produce a false PASS: the task work directory is
 * deleted before each run, and the verdict is taken from this run's output
 * only.  Per-task stdout is kept at build/formal/<task>/runner.log.
 *
 * Usage:
 *   node scripts/formal/run_formal.js [--verbose] [--self-test] [task ...]
 *
 * Tasks (scripts/formal/*.sby):
 *   watchdog       bounded  BMC of the watchdog APB contract   (depth 96)
 *   reset_ctrl     unbounded PDR of the reset-pulse invariants
 *   reset_ctrl_seq bounded  BMC of exact reset pulse timing    (depth 60)
 *   cdc_power_mgr  bounded  BMC of the async wake synchronizer (depth 30)
 *   plic_regs      bounded  BMC of PLIC register/claim semantics   (depth 52)
 *
 * Log: build/formal/formal.log
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const FORMAL = path.join(ROOT, 'scripts', 'formal');
const OUT = path.join(ROOT, 'build', 'formal');
const verbose = process.argv.includes('--verbose');
const selfTest = process.argv.includes('--self-test');
const requested = process.argv.slice(2).filter(a => !a.startsWith('-'));

const TASKS = [
  { name: 'watchdog',      sby: 'watchdog.sby',      what: 'pet suppresses timeout; armed timeout raises reset' },
  { name: 'reset_ctrl',    sby: 'reset_ctrl.sby',    what: 'reset pulse bounded, prompt, identical on both pins' },
  { name: 'reset_ctrl_seq', sby: 'reset_ctrl_seq.sby', what: 'reset pulse width and phase are exact (directed)' },
  { name: 'cdc_power_mgr', sby: 'cdc_power_mgr.sby', what: 'async wake is synchronized and never lost' },
  { name: 'plic_regs',     sby: 'plic_regs.sby',     what: 'PLIC register semantics, claim and arbitration (directed)' },
];

// The OSS CAD Suite is not on the default PATH on this machine.
const TOOL_DIR = process.env.EDA_TOOLS || 'D:/tools/oss-cad-suite';
const env = { ...process.env };
if (fs.existsSync(TOOL_DIR)) {
  env.PATH = [path.join(TOOL_DIR, 'bin'), path.join(TOOL_DIR, 'lib'), env.PATH].join(path.delimiter);
}

fs.mkdirSync(OUT, { recursive: true });
const log = [];
function emit(line) { log.push(line); console.log(line); }

function toolVersion(cmd, args) {
  const r = spawnSync(cmd, args, { cwd: ROOT, encoding: 'utf8', env });
  const text = ((r.stdout || '') + (r.stderr || '')).split('\n').map(l => l.trim()).filter(Boolean);
  return text[0] || 'unavailable';
}

// Proof type / depth, read from the .sby so the summary cannot drift from it.
function config(file) {
  try {
    const text = fs.readFileSync(path.join(FORMAL, file), 'utf8');
    const mode = (text.match(/^\s*mode\s+(\w+)/m) || [])[1] || '?';
    const depth = (text.match(/^\s*depth\s+(\d+)/m) || [])[1] || null;
    const engine = (text.match(/^\[engines\]\s*\n\s*([^\n]+)/m) || [])[1] || '?';
    return { mode, depth, engine: engine.trim() };
  } catch {
    return { mode: '?', depth: null, engine: '?' };
  }
}

/**
 * Run one task.  `opts.cmd` / `opts.pre` exist only for the negative-control
 * self-test, which needs a stub solver that lies about its result.
 */
function runTask(t, opts = {}) {
  const sbyFile = path.join(FORMAL, t.sby);
  if (!fs.existsSync(sbyFile)) return { status: 'MISSING', detail: 'no .sby file' };

  const workdir = path.join(OUT, t.name);
  // Remove stale evidence: a previous PASS must never be able to leak through.
  fs.rmSync(workdir, { recursive: true, force: true });
  fs.mkdirSync(workdir, { recursive: true });

  const cmd = opts.cmd || 'sby';
  const args = [...(opts.pre || []), '-f', '-d', workdir, t.sby];
  const r = spawnSync(cmd, args, { cwd: FORMAL, encoding: 'utf8', env, timeout: 900000 });
  const text = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(path.join(workdir, 'runner.log'), text);
  if (verbose) emit(text);

  if (r.error && r.error.code === 'ETIMEDOUT') return { status: 'TIMEOUT', detail: 'exceeded 900 s' };
  if (r.error && r.error.code === 'ENOENT') return { status: 'UNAVAILABLE', detail: `${cmd} not on PATH` };

  const pass = /DONE \(PASS, rc=0\)/.test(text);
  const unknown = /DONE \(UNKNOWN/.test(text) || /\bUNKNOWN\b/.test(text);
  if (r.status !== 0 || !pass) {
    if (unknown && !/DONE \(FAIL/.test(text)) return { status: 'UNKNOWN', detail: 'engine could not decide' };
    const failed = text.split('\n').find(l => /failed assertion|ERROR|DONE \(/.test(l)) || '';
    return { status: 'FAIL', detail: (failed.trim() || 'no PASS marker').replace(/^.*summary:\s*/, '') };
  }
  return { status: 'PASS', detail: '' };
}

//--------------------------------------------------------------------------
// Negative controls: the runner must reject each of these.
//   1 deliberately false assertion      -> FAIL
//   2 missing configuration             -> MISSING
//   3 incomplete proof output           -> UNKNOWN/FAIL
//   4 solver that exits 0 but says nothing -> FAIL
//   5 stale PASS log left in the workdir -> must not turn a FAIL into PASS
//--------------------------------------------------------------------------
if (selfTest) {
  const dir = path.join(OUT, 'selftest');
  fs.mkdirSync(dir, { recursive: true });

  fs.writeFileSync(path.join(dir, 'bad_fv.sv'),
    'module bad_fv(input logic clk);\n' +
    '  always @(posedge clk) begin\n' +
    '    assert (1\'b0);   // deliberately false\n' +
    '  end\n' +
    'endmodule\n');
  fs.writeFileSync(path.join(dir, 'bad.sby'),
    '[options]\nmode bmc\ndepth 4\n\n[engines]\nsmtbmc boolector\n\n[script]\n' +
    'read_verilog -sv -formal bad_fv.sv\nprep -top bad_fv\n\n[files]\nbad_fv.sv\n');
  fs.copyFileSync(path.join(dir, 'bad.sby'), path.join(FORMAL, 'zz_selftest_bad.sby'));
  fs.copyFileSync(path.join(dir, 'bad_fv.sv'), path.join(FORMAL, 'zz_selftest_bad_fv.sv'));

  const results = [];
  try {
    results.push(['false assertion', runTask({ name: 'st_bad', sby: 'zz_selftest_bad.sby' }, {}), ['FAIL']]);
    results.push(['missing config', runTask({ name: 'st_missing', sby: 'does_not_exist.sby' }, {}), ['MISSING']]);
    results.push(['incomplete output (UNKNOWN)',
      runTask({ name: 'st_unknown', sby: 'watchdog.sby' },
              { cmd: 'bash', pre: ['-c', 'echo "SBY summary: engine_0 returned UNKNOWN"; echo "DONE (UNKNOWN, rc=0)"; exit 0'] }),
      ['UNKNOWN']]);
    results.push(['silent success',
      runTask({ name: 'st_silent', sby: 'watchdog.sby' },
              { cmd: 'bash', pre: ['-c', 'exit 0'] }),
      ['FAIL']]);
    // Stale evidence: leave a PASS-looking log where the next run will write.
    fs.mkdirSync(path.join(OUT, 'st_stale'), { recursive: true });
    fs.writeFileSync(path.join(OUT, 'st_stale', 'runner.log'), 'DONE (PASS, rc=0)\n');
    results.push(['stale PASS log', runTask({ name: 'st_stale', sby: 'zz_selftest_bad.sby' }, {}), ['FAIL']]);
  } finally {
    for (const f of ['zz_selftest_bad.sby', 'zz_selftest_bad_fv.sv']) {
      fs.rmSync(path.join(FORMAL, f), { force: true });
    }
  }

  let ok = true;
  for (const [name, r, expected] of results) {
    const good = expected.includes(r.status);
    ok = ok && good;
    console.log(`${good ? 'REJECTED' : 'ACCEPTED (BUG)'}  ${name.padEnd(18)} -> ${r.status}${r.detail ? ' [' + r.detail + ']' : ''}`);
  }
  console.log(ok ? 'RUNNER SELF-TEST: PASS' : 'RUNNER SELF-TEST: FAIL');
  process.exit(ok ? 0 : 1);
}

//--------------------------------------------------------------------------
const selected = requested.length ? TASKS.filter(t => requested.includes(t.name)) : TASKS;
const unknownTask = requested.filter(n => !TASKS.some(t => t.name === n));
if (unknownTask.length) {
  emit('unknown task(s): ' + unknownTask.join(', '));
  emit('known tasks: ' + TASKS.map(t => t.name).join(', '));
  process.exit(1);
}

const results = selected.map(t => ({ ...t, cfg: config(t.sby), ...runTask(t) }));

emit('');
emit('Home-Automation-SoC formal verification — SymbiYosys');
emit('revision: ' + (spawnSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: ROOT, encoding: 'utf8' }).stdout || '').trim());
emit('date    : ' + new Date().toISOString());
emit('sby     : ' + toolVersion('sby', ['--version']));
emit('yosys   : ' + toolVersion('yosys', ['-V']));
emit('');
for (const r of results) {
  const proof = r.cfg.mode === 'prove'
    ? `unbounded (${r.cfg.engine})`
    : `bounded depth ${r.cfg.depth} (${r.cfg.engine})`;
  emit(r.status.padEnd(11) + r.name.padEnd(16) + proof.padEnd(36) + r.what +
       (r.detail ? '  [' + r.detail + ']' : ''));
}
const passed = results.filter(r => r.status === 'PASS').length;
emit('');
emit(`PASS ${passed} / ${results.length}`);

fs.writeFileSync(path.join(OUT, 'formal.log'), log.join('\n') + '\n');
process.exit(passed === results.length ? 0 : 1);
