#!/usr/bin/env node
/*
 * Home-Automation-SoC — single closure entry point
 *
 *   node scripts/closure.js
 *
 * Run this from the repository root of a clean checkout. Nothing here reads a
 * file that is not in the Git tree; the first stage proves that.
 *
 * Stages
 *   1. environment   — working directory, resolved tool paths and versions.
 *   2. publication   — every required input and evidence file is tracked in
 *                      the candidate commit (scripts/publication/).
 *   3. verification  — the unified gate (scripts/verify.js): syntax, lint,
 *                      functional regression, formal, CDC inventory, protocol
 *                      tests, memory contract, I2C timing, the structural and
 *                      memory design stages, docs.
 *
 * Results and per-stage logs: build/closure/.
 *
 * Exit codes
 *   0  every stage passed and ASIC readiness is cleared
 *   1  a stage failed
 *   2  a stage is BLOCKED, or the run could not start (missing tool)
 *
 * Environment overrides (all optional, none of them a hidden default):
 *   EDA_TOOLS      oss-cad-suite root      (default D:/tools/oss-cad-suite)
 *   VERIBLE_DIR    verible bin directory   (default D:/tools/verible)
 *   PYTHON         python interpreter      (default D:/tools/venv/Scripts/python.exe)
 *   RISCV_GCC_PREFIX / RISCV_TOOLCHAIN_BIN  RISC-V toolchain (see scripts/fw_build/toolchain.js)
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'build', 'closure');
fs.mkdirSync(OUT, { recursive: true });

const TOOL_DIR = process.env.EDA_TOOLS || 'D:/tools/oss-cad-suite';
const VERIBLE_DIR = process.env.VERIBLE_DIR || 'D:/tools/verible';
const PYTHON = process.env.PYTHON || 'D:/tools/venv/Scripts/python.exe';

const env = { ...process.env };
env.PATH = [path.join(TOOL_DIR, 'bin'), path.join(TOOL_DIR, 'lib'), VERIBLE_DIR, env.PATH]
  .join(path.delimiter);

const startedAt = new Date();
const lines = [];
function say(s = '') { lines.push(s); console.log(s); }

function probe(cmd, args) {
  const r = spawnSync(cmd, args, { cwd: ROOT, env, encoding: 'utf8', timeout: 60000 });
  if (r.error && r.error.code === 'ENOENT') return null;
  const text = ((r.stdout || '') + (r.stderr || '')).split('\n').map(l => l.trim()).filter(Boolean);
  return text[0] || 'present';
}

// ---------------------------------------------------------------------------
// 1. environment
// ---------------------------------------------------------------------------
say('Home-Automation-SoC — closure run');
say(`started      ${startedAt.toISOString()}`);
say(`cwd          ${process.cwd()}`);
say(`repo root    ${ROOT}`);
const cwdRelative = path.relative(ROOT, process.cwd()).split(path.sep).join('/');
if (cwdRelative !== '') {
  say(`WARNING      not run from the repository root (${cwdRelative}); stages use absolute paths so this is allowed, but the documented command is "node scripts/closure.js" at the root`);
}
say('');
say('tool inventory (first version line, or MISSING)');
let missingTool = null;
const probes = [
  ['node', process.execPath, ['--version'], process.version],
  ['python', PYTHON, ['--version'], null],
  ['iverilog', 'iverilog', ['-V'], null],
  ['vvp', 'vvp', ['-V'], null],
  ['yosys', 'yosys', ['-V'], null],
  ['sby', path.join(TOOL_DIR, 'bin', 'sby.exe'), ['--version'], null],
  ['verilator_bin', path.join(TOOL_DIR, 'bin', 'verilator_bin.exe'), ['--version'], null],
];
const requiredTools = new Set(['iverilog', 'vvp', 'yosys']);
for (const [label, cmd, args, known] of probes) {
  const v = known !== null ? known : probe(cmd, args);
  say(`  ${label.padEnd(14)} ${v || 'MISSING'}`);
  if (!v && requiredTools.has(label) && !missingTool) missingTool = label;
}
// RISC-V toolchain through the one shared resolver (F6).
try {
  const tc = require(path.join(ROOT, 'scripts', 'fw_build', 'toolchain')).findToolchain();
  if (tc.error) { say(`  riscv-toolchain MISSING — ${tc.error}`); missingTool = missingTool || 'riscv toolchain'; }
  else say(`  riscv-toolchain ${tc.gccPath} [${tc.source}] ${tc.version}`);
} catch (e) {
  say(`  riscv-toolchain resolver failed: ${e.message}`);
  missingTool = missingTool || 'riscv toolchain';
}
say('');

if (missingTool) {
  say(`CLOSURE: BLOCKED — required tool missing: ${missingTool}`);
  fs.writeFileSync(path.join(OUT, 'summary.txt'), lines.join('\n') + '\n');
  process.exit(2);
}

// ---------------------------------------------------------------------------
// stage runner
// ---------------------------------------------------------------------------
const stages = [];
function stage(name, args) {
  const log = path.join(OUT, `${name}.log`);
  if (fs.existsSync(log)) fs.unlinkSync(log);      // a stale log can never pass
  const t0 = Date.now();
  const r = spawnSync(process.execPath, args, {
    cwd: ROOT, env, encoding: 'utf8', timeout: 3600000, maxBuffer: 256 * 1024 * 1024,
  });
  const ms = Date.now() - t0;
  const text = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(log, `$ node ${args.join(' ')}\n\n${text}`);
  const timedOut = r.error && r.error.code === 'ETIMEDOUT';
  const status = timedOut ? -1 : (r.error ? 1 : (r.status === null ? 1 : r.status));
  say(`--- ${name} ---------------------------------------------------`);
  say(text.trim().split('\n').slice(-24).join('\n'));
  say(`--- ${name}: exit ${status} in ${(ms / 1000).toFixed(1)} s (log build/closure/${name}.log)`);
  say('');
  stages.push({ name, status, ms });
  return status;
}

// ---------------------------------------------------------------------------
// 2. publication completeness
// ---------------------------------------------------------------------------
const pubStatus = stage('publication', [path.join(ROOT, 'scripts', 'publication', 'check_publication.js')]);

// ---------------------------------------------------------------------------
// 3. verification gate
// ---------------------------------------------------------------------------
const verifyStatus = stage('verify', [path.join(ROOT, 'scripts', 'verify.js')]);

// ---------------------------------------------------------------------------
// summary
// ---------------------------------------------------------------------------
say('CLOSURE SUMMARY');
for (const s of stages) {
  const label = s.status === 0 ? 'PASS' : (s.name === 'verify' && s.status === 2 ? 'BLOCKED' : 'FAIL');
  say(`  ${s.name.padEnd(14)} ${label.padEnd(8)} exit ${s.status}  ${(s.ms / 1000).toFixed(1)} s`);
}
const blocked = stages.some(s => s.name === 'verify' && s.status === 2);
const failed = stages.some(s => s.status !== 0) && !blocked;
say('');
say(`finished     ${new Date().toISOString()} (${((Date.now() - startedAt) / 1000).toFixed(1)} s)`);
if (failed) say('CLOSURE: FAIL');
else if (blocked) say('CLOSURE: BLOCKED — functional verification ran; ASIC readiness has declared implementation gaps');
else say('CLOSURE: PASS');

fs.writeFileSync(path.join(OUT, 'summary.txt'), lines.join('\n') + '\n');
process.exit(failed ? 1 : blocked ? 2 : 0);
