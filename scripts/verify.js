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
// --only=<task,task> runs a subset (used by the negative-control checks so a
// deliberate violation can be demonstrated without a full suite run).
const onlyArg = process.argv.find(a => a.startsWith('--only='));
const only = onlyArg ? onlyArg.slice('--only='.length).split(',').map(s => s.trim()).filter(Boolean) : null;
const want = name => !only || only.includes(name);

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
function verdict({ name, required = true, ranAt, startedAt, exitCode, logText, marker, markerRe, check, blockedReason }) {
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
  if (markerRe && !markerRe.test(logText)) {
    return { status: 'FAIL', detail: `success pattern missing: ${markerRe}` };
  }
  if (check) {
    const detail = check(logText);
    if (detail) return { status: 'FAIL', detail };
  }
  if (FAIL_RE.test(logText)) {
    const m = logText.match(FAIL_RE);
    return { status: 'FAIL', detail: `failure pattern in log: "${m[0]}"` };
  }
  return { status: 'PASS', detail: marker ? `marker "${marker}"` : 'exit 0' };
}

// A child runner reports its own inventory as "PASS <n> / <m>".  The gate must
// never pin an absolute total: adding or removing a test would then either
// break a correct suite or, worse, let a shrunk inventory satisfy a hardcoded
// number.  Require only that every executed test passed.
function allExecutedPassed(logText) {
  const m = logText.match(/^PASS (\d+) \/ (\d+)/m);
  if (!m) return 'no "PASS <n> / <n>" line in log (result not derived from an inventory)';
  const passed = Number(m[1]);
  const total = Number(m[2]);
  if (total === 0) return 'test inventory is empty';
  if (passed !== total) return `${passed} of ${total} executed tests passed`;
  return null;
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
    {
      // A lint tool that exits on a usage error prints no rule diagnostics; the
      // old gate read "no parsed violations" as success.
      name: 'lint tool error, no diagnostics',
      input: { name: 'verible-lint', startedAt: now, ranAt: now + 10, exitCode: 2,
               logText: 'LINT_OK\nverible lint exit 2 over 22 files\n', marker: 'LINT_OK' },
    },
    {
      // Correct diagnostic, absolute Windows path: an anchored `^([^:]+):`
      // parser drops this row entirely and reports a clean lint.
      name: 'lint violation on a drive-letter path',
      input: { name: 'verible-lint', startedAt: now, ranAt: now + 10, exitCode: 0,
               logText: 'LINT_OK\n', marker: 'LINT_OK',
               check: () => lintDriftFromText(
                 'D:/proj/rtl/bad.sv:12:5-9: Unexpected token [syntax]\n') },
    },
    {
      name: 'regression with a shrunk inventory',
      input: { name: 'regression', startedAt: now, ranAt: now + 10, exitCode: 0,
               logText: 'PASS 3 / 22\n', check: allExecutedPassed },
    },
    {
      name: 'regression with no inventory line',
      input: { name: 'regression', startedAt: now, ranAt: now + 10, exitCode: 0,
               logText: 'everything looks fine\n', check: allExecutedPassed },
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

function runTask(name, cmd, args, marker, check, opts = {}) {
  const log = logPath(name);
  if (fs.existsSync(log)) fs.unlinkSync(log);           // stale evidence cannot survive
  const p = spawnSync(cmd, args, {
    cwd: ROOT, env, encoding: 'utf8',
    timeout: opts.timeout || 900000,                    // bounded, with a diagnostic
    maxBuffer: 256 * 1024 * 1024,
  });
  const text = (p.stdout || '') + (p.stderr || '');
  fs.writeFileSync(log, text, 'utf8');
  const ranAt = fs.existsSync(log) ? fs.statSync(log).mtimeMs : null;
  if (verbose) console.log(`\n--- ${name} ---\n${text}`);
  if (p.error && p.error.code === 'ETIMEDOUT') {
    return { status: 'FAIL', name, detail: `timed out after ${opts.timeout || 900000} ms` };
  }
  return verdict({
    name, startedAt, ranAt,
    exitCode: p.error ? 1 : (p.status === null ? 1 : p.status),
    logText: text, marker, check,
  });
}

// 1 — tool availability -----------------------------------------------------
function checkTools() {
  const required = ['iverilog', 'vvp', 'yosys', 'sby', 'verible-verilog-syntax', 'verible-verilog-lint'];
  // verilator_bin is the binary that actually runs here; the Perl wrapper is
  // broken in this environment. Reporting only 'verilator' as absent hid a
  // working simulator from the inventory (RUN-0011).
  const optional = [['verilator', 'verilator_bin']];
  const lines = [];
  let missing = null;
  for (const t of required) {
    const v = which(t);
    lines.push(`${t.padEnd(26)} ${v || 'MISSING'}`);
    if (!v && !missing) missing = t;
  }
  for (const names of optional) {
    const hit = names.map(n => [n, which(n)]).find(([, p]) => p);
    const via = hit && hit[0] !== names[0] ? ` (via ${hit[0]}; the wrapper is unavailable)` : '';
    lines.push(`${names[0].padEnd(26)} ${hit ? hit[1] + via : 'not installed (optional)'}`);
  }
  // RISC-V toolchain: resolved by the one shared implementation (F6), not by a
  // path lookup here. A broken override must block the gate, not be ignored.
  let tc = null;
  try {
    tc = require(path.join(ROOT, 'scripts', 'fw_build', 'toolchain')).findToolchain();
  } catch (e) {
    tc = { error: `toolchain resolver did not load: ${e.message}` };
  }
  if (tc.error) {
    lines.push(`${'riscv toolchain'.padEnd(26)} MISSING — ${tc.error}`);
    if (!missing) missing = 'RISC-V toolchain';
  } else {
    lines.push(`${'riscv toolchain'.padEnd(26)} ${tc.gccPath} [${tc.source}] ${tc.version}`);
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

// Verible prints `<path>:<line>:<col>[-<endcol>]: <text> [rule]`.  `path` is
// whatever was passed on the command line, so it is absolute here and starts
// with a Windows drive letter (`D:/proj/rtl/x.sv:12:5-9: ...`).  An anchored
// `^([^:]+):` cannot match that (the first colon belongs to the drive), which
// silently dropped every diagnostic and turned the lint gate into a no-op.
// The separator is therefore located by finding the first `:digits:digits:`
// group, whenever it occurs.
function parseLintRows(text, root) {
  // Declared here (not at module scope) so the negative-control block above,
  // which runs before this point in the file, can call it without hitting the
  // temporal dead zone of a module-level const.
  const rowRe = /^(.+?):(\d+):(\d+)(?:-\d+)?:\s?(.*)$/;
  const rows = [];
  for (const raw of String(text).split('\n')) {
    const m = raw.replace(/\r$/, '').match(rowRe);
    if (!m) continue;
    const abs = path.isAbsolute(m[1]) ? m[1] : path.join(root, m[1]);
    rows.push({
      file: path.relative(root, abs).split(path.sep).join('/'),
      line: Number(m[2]),
      text: m[4],
    });
  }
  return rows;
}

function classifyLint(rows, baseline) {
  const localparam = new Map();
  const other = [];
  let classified = 0;
  for (const r of rows) {
    const tag = (r.text.match(/\[([A-Za-z0-9_-]+)\]\s*$/) || [])[1];
    if (!tag) continue;
    classified += 1;
    if (tag === 'parameter-name-style') {
      localparam.set(r.file, (localparam.get(r.file) || 0) + 1);
    } else {
      other.push(`${r.file}:${r.line}: ${r.text}`);
    }
  }

  const drift = [];
  for (const [file, count] of localparam) {
    if (!baseline.has(file)) drift.push('new file with localparam style deviations: ' + file);
    else if (baseline.get(file) !== count) {
      drift.push(file + ': ' + count + ' localparam style deviations, baseline pins ' + baseline.get(file));
    }
  }
  // A pinned file that stops reporting is drift too: renaming a parameter must
  // force a baseline edit rather than silently shrinking the pinned set.
  for (const [file, count] of baseline) {
    if (!localparam.has(file)) {
      drift.push(file + ': baseline pins ' + count + ' but 0 reported (renamed or removed?)');
    }
  }
  if (classified !== rows.length) {
    drift.push((rows.length - classified) + ' diagnostic(s) carried no recognisable rule tag');
  }
  return { localparam, other, drift, reported: rows.length };
}

// Shared by the gate and its negative control, so the control exercises the
// real parser rather than a lookalike.
function lintDriftFromText(text, baseline = new Map()) {
  const { other, drift, reported } = classifyLint(parseLintRows(text, ROOT), baseline);
  if (reported === 0) return 'no diagnostics parsed (path parser cannot see the report)';
  if (other.length) return 'unexpected lint violation: ' + other[0];
  if (drift.length) return 'baseline drift: ' + drift[0];
  return null;
}

// Lint runs with the project rules configuration.  Verible v0.0-4298 reports
// localparam names against a CamelCase regex that cannot be reconfigured, so
// those deviations are pinned per file in lint/localparam_style_baseline.txt;
// any other violation, any new file, or a changed count fails the gate.
//
// Success is NOT inferred from "no parsed violations": the process outcome is
// checked first (spawn error, unacceptable exit status, diagnostics that could
// not be parsed), so a broken invocation cannot look like a clean tree.
function veribleLint() {
  const files = globSv(path.join(ROOT, 'rtl'));
  const log = logPath('verible-lint');
  if (fs.existsSync(log)) fs.unlinkSync(log);

  const baselineFile = path.join(ROOT, 'lint', 'localparam_style_baseline.txt');
  const baseline = new Map();
  for (const row of fs.readFileSync(baselineFile, 'utf8').split('\n')) {
    const parts = row.replace(/\r$/, '').trim().split(/\s+/).filter(Boolean);
    if (parts.length === 2 && /^[0-9]+$/.test(parts[0])) baseline.set(parts[1], Number(parts[0]));
  }

  const p = spawnSync(path.join(VERIBLE_DIR, 'verible-verilog-lint.exe'),
    ['--rules_config=lint/verible.rules', ...files], { cwd: ROOT, env, encoding: 'utf8' });
  const out = (p.stdout || '') + (p.stderr || '');
  const rows = parseLintRows(out, ROOT);
  const { localparam, other, drift, reported } = classifyLint(rows, baseline);

  const status = p.status === null ? -1 : p.status;
  const infra = [];
  if (p.error) infra.push('could not run verible-verilog-lint (' + (p.error.code || p.error.message) + ')');
  if (!p.error && status !== 0 && status !== 1) infra.push('unacceptable exit status ' + status);
  if (out.trim() && reported === 0) infra.push('diagnostics were produced but none could be parsed');
  if (status === 1 && reported === 0) infra.push('exit 1 without any parseable diagnostic');

  const pinned = [...localparam.values()].reduce((a, b) => a + b, 0);
  const ok = infra.length === 0 && other.length === 0 && drift.length === 0 &&
             (status === 0 || (status === 1 && reported > 0));
  const lines = [
    'verible lint exit ' + status + ' over ' + files.length + ' files (' + reported + ' diagnostics parsed)',
    'baseline-pinned localparam style deviations: ' + pinned,
    ...(infra.length ? ['INFRASTRUCTURE', ...infra.map(d => '  ' + d)] : []),
    ...(drift.length ? ['BASELINE DRIFT', ...drift.map(d => '  ' + d)] : []),
    ...(other.length ? ['UNEXPECTED VIOLATIONS', ...other.map(l => '  ' + l)] : []),
    ok ? 'LINT_OK' : 'LINT_FAILED',
  ];
  const text = lines.join('\n') + '\n';
  fs.writeFileSync(log, text, 'utf8');
  if (verbose) console.log(text);
  return verdict({
    name: 'verible-lint', startedAt, ranAt: fs.statSync(log).mtimeMs,
    exitCode: ok ? 0 : 1, logText: text, marker: 'LINT_OK',
  });
}

// 4/5/6 — project runners ---------------------------------------------------
// Counts come from the child's own executed inventory ("PASS <n> / <m>"), not
// from a total embedded here, so adding a test cannot make a correct suite fail
// and removing one cannot satisfy a hardcoded number.
function regression() {
  return runTask('regression', process.execPath,
    [path.join(ROOT, 'scripts', 'eda', 'run_regression.js')], null, allExecutedPassed);
}

function formal() {
  return runTask('formal', process.execPath,
    [path.join(ROOT, 'scripts', 'formal', 'run_formal.js')], null, allExecutedPassed);
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
  { name: 'i2c_xfer',   top: 'tb_i2c_xfer',       tb: 'sim/sim_top/tb_i2c_xfer.v',       src: ['rtl/rtl_peripherals/i2c_ctrl.sv'],   marker: 'TB_I2C_XFER: ALL TESTS PASSED' },
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

// 8b — structural checks must be able to fail (F8) --------------------------
// The full-SoC flow used to end in a bare `check`, which prints its problems
// and exits 0. This runs the checker's control matrix: the pre-fix silent pass,
// undriven output, multiple drivers, an undeclared inferred memory, a stale
// declared inventory, an unchecked internal cell, and a clean baseline.
//
// IMPORTANT: this only proves the *checker* works. It says nothing about the
// current design, and a green result here must never be read as "the SoC is
// structurally qualified". That is what structuralDesign() below decides.
function structuralSelfTest() {
  return runTask('structural-self-test', process.execPath,
    [path.join(ROOT, 'scripts', 'eda', 'check_structure.js'), '--self-test'],
    'STRUCTURAL_CHECK: SELF-TEST PASS');
}

// Three-valued classification for the design stages: PASS, BLOCKED and FAIL are
// different outcomes and a declared gap is never promoted to PASS.
function triVerdict(name, text, exit, opts) {
  if (!text || !text.trim()) {
    return { status: 'FAIL', name, detail: 'empty log (incomplete result)' };
  }
  if (exit === 2 && text.includes(opts.blockedMarker)) {
    const m = text.match(opts.blockedDetailRe || /^\s*GAP .*$/m);
    return { status: 'BLOCKED', name, detail: m ? m[0].trim().replace(/^GAP\s+/, 'gap: ') : 'declared implementation gap' };
  }
  if (exit === 0 && text.includes(opts.passMarker)) {
    return { status: 'PASS', name, detail: opts.passDetail || 'checked design is clean' };
  }
  return {
    status: 'FAIL', name,
    detail: `exit ${exit} without the expected "${opts.passMarker}" or "${opts.blockedMarker}" verdict`,
  };
}

// 8c — the ACTUAL current design, synthesised and structurally validated -----
// Yosys reads the tracked RTL, maps it through the project Sky130 map, and
// check -assert rejects undriven/multiply-driven nets. check_structure.js then
// applies the versioned cell policy and the declared-gap accounting.
function structuralDesign() {
  const name = 'structural-design';
  const log = logPath(name);
  if (fs.existsSync(log)) fs.unlinkSync(log);
  const timeout = 1800000;
  const p = spawnSync(process.execPath, [
    path.join(ROOT, 'scripts', 'eda', 'check_structure.js'),
    '--script', 'asic/synthesis/fullsoc_map.ys',
    '--top', 'has_soc',
    '--json', 'build/asic_evidence/structural_check/has_soc_cells.json',
    '--tag', 'fullsoc',
  ], { cwd: ROOT, env, encoding: 'utf8', timeout, maxBuffer: 256 * 1024 * 1024 });
  const text = (p.stdout || '') + (p.stderr || '');
  fs.writeFileSync(log, text, 'utf8');
  if (verbose) console.log(`\n--- ${name} ---\n${text}`);
  if (p.error && p.error.code === 'ETIMEDOUT') {
    return { status: 'FAIL', name, detail: `timed out after ${timeout} ms` };
  }
  const exit = p.error ? 1 : (p.status === null ? 1 : p.status);
  return triVerdict(name, text, exit, {
    passMarker: 'STRUCTURAL_CHECK: PASS',
    blockedMarker: 'STRUCTURAL_CHECK: BLOCKED',
    passDetail: 'full SoC fully mapped, no structural problems',
  });
}

// 8d/8e — memory inventory self-test, then the real elaborated design -------
function memorySelfTest() {
  return runTask('memory-self-test', process.execPath,
    [path.join(ROOT, 'scripts', 'eda', 'audit_memory.js'), '--self-test'],
    'MEMORY_AUDIT: SELF-TEST PASS');
}

function memoryDesign() {
  const name = 'memory-design';
  const log = logPath(name);
  if (fs.existsSync(log)) fs.unlinkSync(log);
  const timeout = 900000;
  const parts = [];

  const y = spawnSync('yosys', ['-s', 'asic/synthesis/memory_audit.ys'], {
    cwd: ROOT, env, encoding: 'utf8', timeout, maxBuffer: 256 * 1024 * 1024,
  });
  parts.push('$ yosys -s asic/synthesis/memory_audit.ys');
  parts.push((y.stdout || '') + (y.stderr || ''));
  parts.push(`exit ${y.status}`);

  let exit = y.status === 0 ? 0 : 1;
  if (exit === 0) {
    const a = spawnSync(process.execPath, [path.join(ROOT, 'scripts', 'eda', 'audit_memory.js')], {
      cwd: ROOT, env, encoding: 'utf8', timeout, maxBuffer: 256 * 1024 * 1024,
    });
    parts.push('$ node scripts/eda/audit_memory.js');
    parts.push((a.stdout || '') + (a.stderr || ''));
    parts.push(`exit ${a.status}`);
    exit = a.status === null ? 1 : a.status;
  }

  const text = parts.join('\n');
  fs.writeFileSync(log, text, 'utf8');
  if (verbose) console.log(`\n--- ${name} ---\n${text}`);
  return triVerdict(name, text, exit, {
    passMarker: 'MEMORY_AUDIT: PASS',
    blockedMarker: 'MEMORY_AUDIT: BLOCKED',
    blockedDetailRe: /^\s*\S+ \(\w+\): \d+ B, asic_status=.*$/m,
    passDetail: 'every memory has an implemented ASIC alternative',
  });
}

// 8f — memory contract boundary/alias/byte tests at the reconciled sizes -----
function memoryContract() {
  const name = 'memory-contract';
  const log = logPath(name);
  if (fs.existsSync(log)) fs.unlinkSync(log);
  const vvp = path.join(OUT, 'tb_mem_contract.vvp');
  if (fs.existsSync(vvp)) fs.unlinkSync(vvp);
  // has_addr_map.sv is listed first: Icarus is single-pass and the testbench
  // imports the package at file scope.
  const srcs = ['rtl/rtl_top/has_addr_map.sv', 'rtl/rtl_top/boot_rom.sv', 'rtl/rtl_top/sram.sv',
                'sim/sim_top/tb_mem_contract.v'];
  const c = spawnSync('iverilog', ['-g2012', '-o', vvp, '-s', 'tb_mem_contract', ...srcs],
    { cwd: ROOT, env, encoding: 'utf8', timeout: 300000 });
  const lines = [`$ iverilog -g2012 -o ${path.relative(ROOT, vvp)} -s tb_mem_contract ${srcs.join(' ')}`,
                 (c.stdout || '') + (c.stderr || ''), `exit ${c.status}`];
  let exit = c.status === 0 ? 0 : 1;
  if (exit === 0) {
    const r = spawnSync('vvp', [vvp], { cwd: ROOT, env, encoding: 'utf8', timeout: 300000 });
    lines.push('$ vvp ' + path.relative(ROOT, vvp), (r.stdout || '') + (r.stderr || ''), `exit ${r.status}`);
    exit = r.status === null ? 1 : r.status;
  }
  const text = lines.join('\n');
  fs.writeFileSync(log, text, 'utf8');
  if (verbose) console.log(`\n--- ${name} ---\n${text}`);
  return triVerdict(name, text, exit, {
    passMarker: 'TB_MEM_CONTRACT: ALL TESTS PASSED',
    blockedMarker: 'TB_MEM_CONTRACT: (never blocked)',
    passDetail: 'apertures, boundaries, aliases and byte writes match the contract',
  });
}

// 8g — I2C standard-mode timing at the pins, with its negative controls -----
function i2cTiming() {
  return runTask('i2c-timing', process.execPath,
    [path.join(ROOT, 'scripts', 'eda', 'run_i2c_timing.js')],
    'I2C_TIMING_RUNNER: PASS', null, { timeout: 1200000 });
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

  // Child output is part of the evidence: without it a failing sync left no
  // diagnostic at all (the script's SystemExit message went unrecorded).
  lines.push(`sync exit ${sync1.status}/${sync2.status}`);
  if (sync1.status !== 0) lines.push('[sync1 stdout]', sync1.stdout || '', '[sync1 stderr]', sync1.stderr || '');
  if (sync2.status !== 0) lines.push('[sync2 stdout]', sync2.stdout || '', '[sync2 stderr]', sync2.stderr || '');
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
console.log('Home-Automation-SoC — unified verification gate' + (only ? ` (only: ${only.join(',')})` : '') + '\n');

if (want('tools')) {
  record({ name: 'tools', ...checkTools() });
  if (results[0].status === 'BLOCKED') {
    console.log(`BLOCKED  tools: ${results[0].detail}`);
    console.log('\nNo further task can be trusted without the required tools.');
    fs.writeFileSync(path.join(OUT, 'summary.txt'), summary.join('\n') + '\n', 'utf8');
    process.exit(2);
  }
}

const TASK_ORDER = [
  ['verible-syntax', veribleSyntax],
  ['verible-lint', veribleLint],
  ['regression', regression],
  ['formal', formal],
  ['cdc-inventory', cdc],
  ['protocol-tests', protocolTests],
  ['memory-contract', memoryContract],
  ['i2c-timing', i2cTiming],
  ['structural-self-test', structuralSelfTest],
  ['structural-design', structuralDesign],
  ['memory-self-test', memorySelfTest],
  ['memory-design', memoryDesign],
  ['mermaid', mermaid],
  ['docs-sync', docsSync],
];
for (const [name, fn] of TASK_ORDER) {
  if (want(name)) record({ name, ...fn() });
}

const failed = results.filter(r => r.status === 'FAIL');
const blocked = results.filter(r => r.status === 'BLOCKED');

// Functional verification and ASIC readiness are reported separately. A green
// checker self-test used to stand in for "the design is structurally
// qualified"; these two lines make it impossible to read the first as the
// second. Readiness stays BLOCKED while any required implementation gap exists.
const READINESS_STAGES = ['structural-design', 'memory-design'];
const functional = results.filter(r => !READINESS_STAGES.includes(r.name));
const readiness = results.filter(r => READINESS_STAGES.includes(r.name));
const fnPass = functional.filter(r => r.status === 'PASS').length;
const fnFail = functional.filter(r => r.status === 'FAIL').length;
const fnBlocked = functional.filter(r => r.status === 'BLOCKED').length;
const rdPass = readiness.filter(r => r.status === 'PASS').length;
const rdBad = readiness.filter(r => r.status !== 'PASS');

console.log('');
for (const line of summary) console.log(line);
console.log('');
console.log(`functional suite: ${fnPass} passed, ${fnFail} failed, ${fnBlocked} blocked ` +
            `(${functional.length} stages); design stages: ${rdPass} passed, ${rdBad.length} blocked ` +
            `of ${readiness.length} (${results.length} stages in total)`);
for (const r of readiness) {
  console.log(`ASIC readiness   ${r.name.padEnd(20)} ${r.status}  ${r.detail}`);
}
if (readiness.length === 0) {
  console.log('ASIC readiness: not evaluated in this run (design stages were not selected)');
} else {
  console.log(`ASIC readiness: ${rdBad.length ? 'BLOCKED' : 'cleared'} ` +
              `(${rdPass}/${readiness.length} design stages pass) — ` +
              (rdBad.length
                ? 'required memory implementations are still inferred; this is not tapeout readiness'
                : 'no declared gaps remain'));
}
console.log(`logs: build/verify/*.log`);

fs.writeFileSync(path.join(OUT, 'summary.txt'),
  summary.join('\n') +
  `\n\nfunctional: ${fnPass} passed, ${fnFail} failed, ${fnBlocked} blocked` +
  `\nASIC readiness: ${rdBad.length ? 'BLOCKED' : 'cleared'} (${rdPass}/${readiness.length} design stages pass)` +
  `\n${failed.length} failed, ${blocked.length} blocked\n`, 'utf8');

process.exit(failed.length ? 1 : blocked.length ? 2 : 0);
