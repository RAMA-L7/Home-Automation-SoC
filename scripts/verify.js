#!/usr/bin/env node
/*
 * Home-Automation-SoC — unified verification gate
 *
 *   node scripts/verify.js              run every required check
 *   node scripts/verify.js --self-test  prove the gate rejects false PASSes
 *   node scripts/verify.js --verbose    echo child output
 *
 * Design rules (each one is a failure mode that produced a wrong green result
 * in an earlier phase):
 *
 *   * Every required task runs; nothing is skipped silently.
 *   * A task is PASS only if ALL of these hold:
 *       - the child process exited 0,
 *       - its log file was created by THIS run (the log is deleted first and its
 *         mtime is compared with the run start),
 *       - the task's success marker is present in the log,
 *       - the log contains no failure pattern.
 *     Anything else is FAIL, or BLOCKED when a required tool/config is absent.
 *   * Preparation-only work cannot pass: the formal runner's markers only appear
 *     when an engine finished with "DONE (PASS, rc=0)".
 *   * Exit code: 0 all pass, 1 any FAIL, 2 any BLOCKED (and 1 if both).
 *
 * Logs: build/verify/<task>.log, plus a summary at build/verify/summary.txt.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'build', 'verify');
const verbose = process.argv.includes('--verbose');
const selfTest = process.argv.includes('--self-test');

const TOOL_DIR = process.env.EDA_TOOLS || 'D:/tools/oss-cad-suite';
const VERIBLE_DIR = process.env.VERIBLE_DIR || 'D:/tools/verible';
const PYTHON = process.env.PYTHON || 'D:/tools/venv/Scripts/python.exe';

const env = { ...process.env };
env.PATH = [
  path.join(TOOL_DIR, 'bin'),
  path.join(TOOL_DIR, 'lib'),
  VERIBLE_DIR,
  env.PATH,
].join(path.delimiter);

const FAIL_RE = /\bFAIL(ED|URE|S)?\b|FATAL|ERROR:|error:|Traceback|TIMEOUT/;

function logPath(name) {
  return path.join(OUT, `${name}.log`);
}

function which(cmd) {
  const probe = spawnSync(cmd, ['--version'], { cwd: ROOT, env, encoding: 'utf8' });
  if (probe.error && probe.error.code === 'ENOENT') return null;
  const text = ((probe.stdout || '') + (probe.stderr || '')).split('\n').map(l => l.trim()).filter(Boolean);
  return text[0] || 'present';
}

function globSv(dir, acc = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) globSv(p, acc);
    else if (e.name.endsWith('.sv') || e.name.endsWith('.v')) acc.push(p);
  }
  return acc;
}

// ---------------------------------------------------------------------------
// The verdict function. Every real task goes through it, and --self-test drives
// it with synthetic inputs, so the gate and its negative controls share code.
// ---------------------------------------------------------------------------
function verdict({ name, required = true, ranAt, startedAt, exitCode, logText, marker, blockedReason }) {
  if (blockedReason) return { status: 'BLOCKED', detail: blockedReason };
  if (!required) return { status: 'SKIP', detail: 'not required on this platform' };
  if (startedAt && (!ranAt || ranAt < startedAt)) {
    return { status: 'FAIL', detail: 'log is stale (not written by this run)' };
  }
  if (exitCode !== 0) return { status: 'FAIL', detail: `exit code ${exitCode}` };
  if (!logText || !logText.trim()) return { status: 'FAIL', detail: 'empty log (incomplete result)' };
  if (marker && !logText.includes(marker)) {
    return { status: 'FAIL', detail: `success marker missing: "${marker}"` };
  }
  if (FAIL_RE.test(logText)) {
    const m = logText.match(FAIL_RE);
    return { status: 'FAIL', detail: `failure pattern in log: "${m[0]}"` };
  }
  return { status: 'PASS', detail: marker ? `marker "${marker}"` : 'exit 0' };
}

// ---------------------------------------------------------------------------
// Self-test: every case below must be REJECTED (not PASS).
// ---------------------------------------------------------------------------
if (selfTest) {
  const now = Date.now();
  const cases = [
    {
      name: 'failed simulation (nonzero exit)',
      input: { name: 'sim', startedAt: now, ranAt: now + 10, exitCode: 1,
               logText: 'PLIC PROTOCOL: ALL TESTS PASSED', marker: 'PLIC PROTOCOL: ALL TESTS PASSED' },
    },
    {
      name: 'failed assertion (exit 0, FAIL in log)',
      input: { name: 'formal', startedAt: now, ranAt: now + 10, exitCode: 0,
               logText: 'PASS 4 / 5\nFAIL plic_regs bounded depth 52\nDONE (FAIL, rc=2)',
               marker: 'PASS 5 / 5' },
    },
    {
      name: 'missing required tool',
      input: { name: 'verible-lint', blockedReason: 'verible-verilog-lint not on PATH' },
    },
    {
      name: 'missing configuration',
      input: { name: 'formal', blockedReason: 'scripts/formal/plic_regs.sby not found' },
    },
    {
      name: 'stale PASS log',
      input: { name: 'regression', startedAt: now, ranAt: now - 60000, exitCode: 0,
               logText: 'PASS 22 / 22', marker: 'PASS 22 / 22' },
    },
    {
      name: 'incomplete result (no marker)',
      input: { name: 'spi', startedAt: now, ranAt: now + 10, exitCode: 0,
               logText: '[spi] running...\n', marker: 'SPI DEVICE: ALL TESTS PASSED' },
    },
  ];

  let rejected = 0;
  console.log('verify.js negative controls\n');
  for (const c of cases) {
    const v = verdict(c.input);
    const ok = v.status !== 'PASS';
    if (ok) rejected += 1;
    console.log(`${ok ? 'REJECT' : 'ACCEPT'}  ${c.name.padEnd(42)} -> ${v.status}: ${v.detail}`);
  }
  console.log(`\nrejected ${rejected} / ${cases.length}`);
  process.exit(rejected === cases.length ? 0 : 1);
}

// ---------------------------------------------------------------------------
// Real run
// ---------------------------------------------------------------------------
fs.mkdirSync(OUT, { recursive: true });
const startedAt = Date.now();
const results = [];
const summary = [];

function record(r) {
  results.push(r);
  summary.push(`${r.status.padEnd(8)} ${r.name.padEnd(24)} ${r.detail}`);
}

function runTask(name, cmd, args, marker) {
  const log = logPath(name);
  if (fs.existsSync(log)) fs.unlinkSync(log);           // stale evidence cannot survive
  const p = spawnSync(cmd, args, { cwd: ROOT, env, encoding: 'utf8' });
  const text = (p.stdout || '') + (p.stderr || '');
  fs.writeFileSync(log, text, 'utf8');
  const ranAt = fs.existsSync(log) ? fs.statSync(log).mtimeMs : null;
  if (verbose) console.log(`\n--- ${name} ---\n${text}`);
  return verdict({
    name, startedAt, ranAt,
    exitCode: p.status === null ? 1 : p.status,
    logText: text, marker,
  });
}

// 1 — tool availability -----------------------------------------------------
function checkTools() {
  const required = ['iverilog', 'vvp', 'yosys', 'sby', 'verible-verilog-syntax', 'verible-verilog-lint'];
  const optional = ['verilator'];
  const lines = [];
  let missing = null;
  for (const t of required) {
    const v = which(t);
    lines.push(`${t.padEnd(26)} ${v || 'MISSING'}`);
    if (!v && !missing) missing = t;
  }
  for (const t of optional) {
    const v = which(t);
    lines.push(`${t.padEnd(26)} ${v || 'not installed (optional)'}`);
  }
  for (const [label, file] of [['node', process.version], ['python', PYTHON]]) {
    lines.push(`${label.padEnd(26)} ${file}`);
  }
  fs.writeFileSync(logPath('tools'), lines.join('\n') + '\n', 'utf8');
  const ranAt = fs.statSync(logPath('tools')).mtimeMs;
  return verdict({
    name: 'tools', startedAt, ranAt, exitCode: 0,
    logText: lines.join('\n'),
    marker: null,
    blockedReason: missing ? `required tool missing: ${missing}` : null,
  });
}

// 2/3 — Verible -------------------------------------------------------------
function veribleSyntax() {
  const files = [...globSv(path.join(ROOT, 'rtl')),
                 ...fs.readdirSync(path.join(ROOT, 'scripts', 'formal'))
                       .filter(f => f.endsWith('.sv'))
                       .map(f => path.join(ROOT, 'scripts', 'formal', f))];
  const log = logPath('verible-syntax');
  if (fs.existsSync(log)) fs.unlinkSync(log);
  const p = spawnSync(path.join(VERIBLE_DIR, 'verible-verilog-syntax.exe'),
    ['--printtree=false', ...files], { cwd: ROOT, env, encoding: 'utf8' });
  const out = (p.stdout || '') + (p.stderr || '');
  const syntaxErrors = (out.match(/syntax error/g) || []).length;
  // The parser prints nothing when every file parses, so write an explicit
  // counted result: an empty log must never be able to pass.
  const text = `${out.trim()}
parsed ${files.length} files, ${syntaxErrors} syntax error(s)
` +
               (p.status === 0 && syntaxErrors === 0 ? 'SYNTAX_OK' : 'SYNTAX_FAILED');
  fs.writeFileSync(log, text, 'utf8');
  if (verbose) console.log(text);
  return verdict({
    name: 'verible-syntax', startedAt, ranAt: fs.statSync(log).mtimeMs,
    exitCode: p.status === null ? 1 : p.status, logText: text, marker: 'SYNTAX_OK',
  });
}

// Lint runs with the project rules configuration.  Verible v0.0-4298 reports
// localparam names against a CamelCase regex that cannot be reconfigured, so
// those deviations are pinned per file in lint/localparam_style_baseline.txt;
// any other violation, any new file, or a changed count fails the gate.
function veribleLint() {
  const files = globSv(path.join(ROOT, 'rtl'));
  const log = logPath('verible-lint');
  if (fs.existsSync(log)) fs.unlinkSync(log);
  const p = spawnSync(path.join(VERIBLE_DIR, 'verible-verilog-lint.exe'),
    ['--rules_config=lint/verible.rules', ...files], { cwd: ROOT, env, encoding: 'utf8' });
  const out = (p.stdout || '') + (p.stderr || '');
  const rows = out.split(String.fromCharCode(10)).map(s => s.replace(String.fromCharCode(13), ''));

  const baselineFile = path.join(ROOT, 'lint', 'localparam_style_baseline.txt');
  const baseline = new Map();
  for (const row of fs.readFileSync(baselineFile, 'utf8').split(String.fromCharCode(10))) {
    const parts = row.replace(String.fromCharCode(13), '').trim().split(' ').filter(Boolean);
    if (parts.length === 2 && /^[0-9]+$/.test(parts[0])) baseline.set(parts[1], Number(parts[0]));
  }

  const localparam = new Map();
  const other = [];
  for (const row of rows) {
    const m = row.match(/^([^:]+):([0-9]+):/);
    if (!m) continue;
    if (row.indexOf('[parameter-name-style]') >= 0) {
      localparam.set(m[1], (localparam.get(m[1]) || 0) + 1);
    } else if (row.indexOf('[') >= 0 && row.indexOf(']') > 0) {
      other.push(row);
    }
  }

  const drift = [];
  for (const [file, count] of localparam) {
    if (!baseline.has(file)) drift.push('new file with localparam style deviations: ' + file);
    else if (baseline.get(file) !== count) {
      drift.push(file + ': ' + count + ' localparam style deviations, baseline pins ' + baseline.get(file));
    }
  }

  const ok = other.length === 0 && drift.length === 0;
  const lines = [
    'verible lint exit ' + p.status + ' over ' + files.length + ' files',
    'baseline-pinned localparam style deviations: ' + [...localparam.values()].reduce((a, b) => a + b, 0),
    ...(drift.length ? ['BASELINE DRIFT', ...drift.map(d => '  ' + d)] : []),
    ...(other.length ? ['UNEXPECTED VIOLATIONS', ...other.map(l => '  ' + l)] : []),
    ok ? 'LINT_OK' : 'LINT_FAILED',
  ];
  const text = lines.join(String.fromCharCode(10)) + String.fromCharCode(10);
  fs.writeFileSync(log, text, 'utf8');
  if (verbose) console.log(text);
  return verdict({
    name: 'verible-lint', startedAt, ranAt: fs.statSync(log).mtimeMs,
    exitCode: ok ? 0 : 1, logText: text, marker: 'LINT_OK',
  });
}

// 4/5/6 — project runners ---------------------------------------------------
function regression() {
  return runTask('regression', process.execPath,
    [path.join(ROOT, 'scripts', 'eda', 'run_regression.js')], 'PASS 22 / 22');
}

function formal() {
  return runTask('formal', process.execPath,
    [path.join(ROOT, 'scripts', 'formal', 'run_formal.js')], 'PASS 5 / 5');
}

function cdc() {
  return runTask('cdc-inventory', process.execPath,
    [path.join(ROOT, 'scripts', 'formal', 'cdc_inventory.js')],
    'structural checks: all rows match the RTL');
}

// 7 — peripheral protocol tests --------------------------------------------
const PROTOCOL_TESTS = [
  { name: 'plic_proto', top: 'tb_plic_proto',     tb: 'sim/sim_top/tb_plic_proto.v',     src: ['rtl/rtl_peripherals/plic.sv'],      marker: 'PLIC PROTOCOL: ALL TESTS PASSED' },
  { name: 'spi_device', top: 'tb_spi_device',     tb: 'sim/sim_top/tb_spi_device.v',     src: ['rtl/rtl_peripherals/spi_ctrl.sv'],   marker: 'SPI DEVICE: ALL TESTS PASSED' },
  { name: 'jtag_proto', top: 'tb_jtag_proto',     tb: 'sim/sim_top/tb_jtag_proto.v',     src: ['rtl/rtl_peripherals/debug_jtag.sv'], marker: 'JTAG PROTOCOL: ALL TESTS PASSED' },
  { name: 'wdog_audit', top: 'tb_watchdog_audit', tb: 'sim/sim_top/tb_watchdog_audit.v', src: ['rtl/rtl_peripherals/watchdog.sv'],   marker: 'WATCHDOG AUDIT: ALL TESTS PASSED' },
  { name: 'sram_audit', top: 'tb_sram_audit',     tb: 'sim/sim_top/tb_sram_audit.v',     src: ['rtl/rtl_top/sram.sv'],               marker: 'SRAM AUDIT: ALL TESTS PASSED' },
];

function protocolTests() {
  const lines = [];
  let failed = null;
  for (const t of PROTOCOL_TESTS) {
    const vvp = path.join(OUT, `${t.name}.vvp`);
    if (fs.existsSync(vvp)) fs.unlinkSync(vvp);
    const c = spawnSync('iverilog', ['-g2012', '-o', vvp, '-s', t.top, t.tb, ...t.src],
      { cwd: ROOT, env, encoding: 'utf8' });
    if (c.status !== 0) {
      lines.push(`COMPILE FAIL ${t.name}\n${c.stdout || ''}${c.stderr || ''}`);
      failed = failed || `${t.name} compile failed`;
      continue;
    }
    const r = spawnSync('vvp', [vvp], { cwd: ROOT, env, encoding: 'utf8' });
    const text = (r.stdout || '') + (r.stderr || '');
    lines.push(`--- ${t.name} (exit ${r.status}) ---\n${text.trim()}`);
    if (r.status !== 0) failed = failed || `${t.name} failed`;
    if (!text.includes(t.marker)) failed = failed || `${t.name} marker missing`;
    if (FAIL_RE.test(text)) failed = failed || `${t.name} reported a failure`;
  }
  const log = logPath('protocol-tests');
  if (fs.existsSync(log)) fs.unlinkSync(log);
  fs.writeFileSync(log, lines.join('\n\n'), 'utf8');
  const ranAt = fs.statSync(log).mtimeMs;
  return verdict({
    name: 'protocol-tests', startedAt, ranAt,
    exitCode: failed ? 1 : 0,
    logText: failed ? `FAIL\n${lines.join('\n')}` : lines.join('\n'),
    marker: null,
    blockedReason: null,
  });
}

// 8 — Mermaid ---------------------------------------------------------------
function mermaid() {
  return runTask('mermaid', process.execPath,
    [path.join(ROOT, 'scripts', 'docs', 'check_mermaid.mjs')], 'check_mermaid: OK');
}

// 9 — diagram generation + documentation idempotency -----------------------
function md5(file) {
  return crypto.createHash('md5').update(fs.readFileSync(file)).digest('hex');
}

function docsSync() {
  const readme = path.join(ROOT, 'README.md');
  const diagram = path.join(ROOT, 'docs', 'architecture', 'BLOCK_DIAGRAM.txt');
  const lines = [];
  const gen = spawnSync(PYTHON, [path.join(ROOT, 'scripts', 'docs', 'gen_block_diagram.py')],
    { cwd: ROOT, env, encoding: 'utf8' });
  lines.push('gen_block_diagram.py exit ' + gen.status);
  if (gen.status !== 0) lines.push(gen.stdout || '', gen.stderr || '');
  const before = { readme: md5(readme), diagram: fs.existsSync(diagram) ? md5(diagram) : 'missing' };

  // Running the synchronisers twice must not change anything the second time.
  const sync1 = spawnSync(PYTHON, [path.join(ROOT, 'scripts', 'docs', 'sync_readme_mermaid.py')],
    { cwd: ROOT, env, encoding: 'utf8' });
  const mid = { readme: md5(readme), diagram: fs.existsSync(diagram) ? md5(diagram) : 'missing' };
  const sync2 = spawnSync(PYTHON, [path.join(ROOT, 'scripts', 'docs', 'sync_readme_mermaid.py')],
    { cwd: ROOT, env, encoding: 'utf8' });
  const after = { readme: md5(readme), diagram: fs.existsSync(diagram) ? md5(diagram) : 'missing' };

  lines.push(`sync exit ${sync1.status}/${sync2.status}`);
  lines.push(`README   ${before.readme} -> ${mid.readme} -> ${after.readme}`);
  lines.push(`diagram  ${before.diagram} -> ${mid.diagram} -> ${after.diagram}`);
  const idempotent = mid.readme === after.readme && before.diagram === after.diagram;
  lines.push(idempotent ? 'docs sync is idempotent' : 'FAIL docs sync is not idempotent');

  const log = logPath('docs-sync');
  if (fs.existsSync(log)) fs.unlinkSync(log);
  fs.writeFileSync(log, lines.join('\n') + '\n', 'utf8');
  const ranAt = fs.statSync(log).mtimeMs;
  const ok = gen.status === 0 && sync1.status === 0 && sync2.status === 0 && idempotent;
  return verdict({
    name: 'docs-sync', startedAt, ranAt,
    exitCode: ok ? 0 : 1,
    logText: ok ? 'docs sync is idempotent' : 'FAIL\n' + lines.join('\n'),
    marker: 'docs sync is idempotent',
  });
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------
console.log('Home-Automation-SoC — unified verification gate\n');

record({ name: 'tools', ...checkTools() });
if (results[0].status === 'BLOCKED') {
  console.log(`BLOCKED  tools: ${results[0].detail}`);
  console.log('\nNo further task can be trusted without the required tools.');
  fs.writeFileSync(path.join(OUT, 'summary.txt'), summary.join('\n') + '\n', 'utf8');
  process.exit(2);
}

record({ name: 'verible-syntax', ...veribleSyntax() });
record({ name: 'verible-lint', ...veribleLint() });
record({ name: 'regression', ...regression() });
record({ name: 'formal', ...formal() });
record({ name: 'cdc-inventory', ...cdc() });
record({ name: 'protocol-tests', ...protocolTests() });
record({ name: 'mermaid', ...mermaid() });
record({ name: 'docs-sync', ...docsSync() });

const failed = results.filter(r => r.status === 'FAIL');
const blocked = results.filter(r => r.status === 'BLOCKED');

console.log('');
for (const line of summary) console.log(line);
console.log(`\n${results.filter(r => r.status === 'PASS').length} passed, ` +
            `${failed.length} failed, ${blocked.length} blocked`);
console.log(`logs: build/verify/*.log`);

fs.writeFileSync(path.join(OUT, 'summary.txt'),
  summary.join('\n') + `\n\n${failed.length} failed, ${blocked.length} blocked\n`, 'utf8');

process.exit(failed.length ? 1 : blocked.length ? 2 : 0);
