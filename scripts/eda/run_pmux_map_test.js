#!/usr/bin/env node
/*
 * Home-Automation-SoC — Sky130 `$pmux` techmap regression test
 *
 * F2: the single-select branch of the `$pmux` rule in
 * build/asic_evidence/sky130_map.v instantiated ONE scalar
 * sky130_fd_sc_hd__mux2_1 with the whole A/B/Y vectors on its pins. For
 * WIDTH > 1 that truncated the payload to bit 0 and left the upper result bits
 * undriven. Yosys `check` does not flag it (port resizing is legal), so this
 * test judges values and cell counts, never "synthesis exited 0".
 *
 * The rule is exercised directly: asic/synthesis/techmap/pmux_probe.il holds one
 * $pmux cell per module, so Verilog inference cannot rewrite $pmux into $mux
 * before techmap sees it.
 *
 * Usage:
 *   node scripts/eda/run_pmux_map_test.js
 *   node scripts/eda/run_pmux_map_test.js --map build/asic_evidence/pmux_map_test/sky130_map_prefix.v --tag prefix
 *       Negative control: the pre-fix mapper must FAIL.
 *   node scripts/eda/run_pmux_map_test.js --verbose
 *
 * Steps, all required:
 *   1. techmap the probes (check, stat, write netlist)
 *   2. structural: exactly 8 / 24 / 1 mux2_1 instances per module
 *   3. simulate the netlist against the golden models (exhaustive + directed)
 *   4. equivalence: the $pmux cell vs the mapped netlist, per module (default map only)
 *
 * Exit: 0 pass, 1 fail, 2 required tool missing.
 * Artifacts: build/asic_evidence/pmux_map_test/<tag>_*
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'asic_evidence', 'pmux_map_test');
const LOGS = path.join(OUT, 'logs');
const verbose = process.argv.includes('--verbose');

function argValue(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}

const MAP_FILE = path.resolve(ROOT, argValue('--map', 'build/asic_evidence/sky130_map.v'));
const TAG = argValue('--tag', 'postfix');
const MAP_TEMPLATE = path.join(ROOT, 'asic', 'synthesis', 'techmap', 'map_pmux.ys');
const EQUIV_SCRIPT = path.join(ROOT, 'asic', 'synthesis', 'techmap', 'equiv_pmux.ys');
const PROBE = path.join(ROOT, 'asic', 'synthesis', 'techmap', 'pmux_probe.il');
const TB = path.join(ROOT, 'asic', 'synthesis', 'techmap', 'tb_pmux_map.v');
const GOLDEN = path.join(ROOT, 'asic', 'synthesis', 'techmap', 'pmux_golden.v');
const STUB = path.join(ROOT, 'build', 'asic_evidence', 'arith_work', 'sky130_stub.v');

const NETLIST = path.join(OUT, `${TAG}_mapped.v`);
const MAP_SCRIPT = path.join(OUT, `map_${TAG}.ys`);
const VVP = path.join(OUT, `sim_${TAG}.vvp`);

const EXPECTED_CELLS = { pmux_s1_w8: 8, pmux_s3_w8: 24, pmux_s1_w1: 1 };

const TOOL_DIR = process.env.EDA_TOOLS || 'D:/tools/oss-cad-suite';
const env = { ...process.env };
// oss-cad-suite keeps its DLLs in lib/: without it, yosys.exe and vvp.exe fail
// with STATUS_DLL_NOT_FOUND (0xC0000135) instead of running.
env.PATH = [path.join(TOOL_DIR, 'bin'), path.join(TOOL_DIR, 'lib'), env.PATH].join(path.delimiter);

fs.mkdirSync(LOGS, { recursive: true });

const results = [];
function record(step, ok, detail) {
  results.push({ step, ok, detail });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${step}${detail ? ' — ' + detail : ''}`);
}

function run(name, cmd, args, opts = {}) {
  const log = path.join(LOGS, `${TAG}_${name}.log`);
  const r = spawnSync(cmd, args, { cwd: ROOT, env, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const text = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(log, `$ ${cmd} ${args.join(' ')}\n\n${text}`);
  if (verbose) process.stdout.write(text);
  return { status: r.status === null ? 1 : r.status, text, log, error: r.error };
}

// Presence only: `-V` exits nonzero for some tools (vvp), so the exit status is
// not a usable presence signal here.
function have(cmd) {
  const r = spawnSync(cmd, ['-V'], { cwd: ROOT, env, encoding: 'utf8' });
  return !(r.error && (r.error.code === 'ENOENT' || r.error.code === 'EACCES'));
}

// ---- 0. tools -------------------------------------------------------------
for (const tool of ['yosys', 'iverilog', 'vvp']) {
  if (!have(tool)) {
    record(`tool ${tool}`, false, `not found (EDA_TOOLS=${TOOL_DIR})`);
    console.log('PMUX_MAP_TEST: BLOCKED');
    process.exit(2);
  }
}

// ---- 1. techmap -----------------------------------------------------------
// The committed script is the canonical default run; --map/--tag rewrite only
// the two paths that vary, so the negative control uses the same steps.
let scriptText = fs.readFileSync(MAP_TEMPLATE, 'utf8')
  .replace('build/asic_evidence/sky130_map.v', path.relative(ROOT, MAP_FILE).split(path.sep).join('/'))
  .replace('build/asic_evidence/pmux_map_test/pmux_mapped.v', path.relative(ROOT, NETLIST).split(path.sep).join('/'));
fs.writeFileSync(MAP_SCRIPT, scriptText);

const map = run('map', 'yosys', ['-s', path.relative(ROOT, MAP_SCRIPT)]);
record('techmap probes', map.status === 0, `yosys exit ${map.status}, log ${path.relative(ROOT, map.log)}`);

// ---- 2. structure ---------------------------------------------------------
if (fs.existsSync(NETLIST)) {
  const netlist = fs.readFileSync(NETLIST, 'utf8');
  const body = name => {
    const start = netlist.indexOf(`module ${name}`);
    if (start < 0) return null;
    const end = netlist.indexOf('endmodule', start);
    return netlist.slice(start, end);
  };
  for (const [name, want] of Object.entries(EXPECTED_CELLS)) {
    const text = body(name);
    const got = text ? (text.match(/sky130_fd_sc_hd__mux2_1/g) || []).length : 0;
    record(`structure ${name}`, got === want, `${got} mux2_1 instance(s), expected ${want}`);
  }
} else {
  record('structure', false, 'no netlist written');
}

// ---- 3. simulation against the golden models ------------------------------
const compile = run('compile', 'iverilog', [
  '-g2012', '-o', VVP, TB, GOLDEN, NETLIST, STUB,
]);
record('compile mapped netlist', compile.status === 0, `iverilog exit ${compile.status}`);

let simOk = false;
if (compile.status === 0) {
  const sim = run('sim', 'vvp', [VVP]);
  const mismatches = (sim.text.match(/^FAIL /gm) || []).length;
  simOk = sim.status === 0 && sim.text.includes('PMUX_MAP_TEST: PASS') && mismatches === 0;
  const summary = (sim.text.match(/PMUX_MAP_TEST: .*vectors checked.*/) || ['no summary line'])[0].trim();
  record('simulation vs golden', simOk, `${summary}; vvp exit ${sim.status}`);
} else {
  record('simulation vs golden', false, 'not run (compile failed)');
}

// ---- 4. equivalence -------------------------------------------------------
// Only meaningful for the default mapper; the negative control is expected to
// fail here too, so it is reported for information and does not soften step 3.
let equivOk = null;
if (MAP_FILE === path.resolve(ROOT, 'build/asic_evidence/sky130_map.v')) {
  const equiv = run('equiv', 'yosys', ['-s', path.relative(ROOT, EQUIV_SCRIPT)]);
  equivOk = equiv.status === 0;
  record('equivalence ($pmux vs netlist)', equivOk, `yosys exit ${equiv.status}`);
} else {
  record('equivalence ($pmux vs netlist)', false, 'skipped: --map is not the project mapper (negative control)');
}

// ---- summary --------------------------------------------------------------
const failed = results.filter(r => !r.ok).length;
console.log('');
console.log(`PMUX_MAP_TEST: ${results.length - failed}/${results.length} steps passed (map=${path.relative(ROOT, MAP_FILE)}, tag=${TAG})`);
process.exit(failed === 0 ? 0 : 1);
