#!/usr/bin/env node
/*
 * Home-Automation-SoC — F3: `sky130_fd_sc_hd__dfrbp_*` model fidelity test
 *
 * The behavioural stub used for netlist simulation declared dfrbp as a
 * NEGEDGE flip-flop. The library says it is positive-edge with an asynchronous
 * active-low clear:
 *
 *   build/asic_evidence/sky130_tt.lib  (SKY130 HD liberty, tt 025C 1v80)
 *     ff ("IQ","IQ_N") { clear : "!RESET_B"; clocked_on : "CLK"; next_state : "D"; }
 *     timing arcs: CLK -> Q "rising_edge", RESET_B -> Q "clear"
 *
 * `clocked_on` without a leading '!' is the rising edge, so the stub was wrong.
 * This test does not trust that sentence: it parses the liberty, checks the
 * stub's event control, then simulates directed vectors that separate the two
 * edges, and finally runs the same vectors against the preserved pre-fix model
 * (the negative control), which must FAIL.
 *
 * Steps:
 *   1. liberty definition, per cell (_1 and _2): ff block + no falling_edge arc
 *   2. subset liberty ff blocks are identical to the full liberty
 *   3. stub event control matches: posedge CLK, negedge RESET_B, Q_N = ~Q
 *   4. preserved negative control really is the old negedge model
 *   5. simulation of the tested stub passes every directed check
 *   6. simulation of the negative control fails (proves the checks discriminate)
 *
 * Usage:
 *   node scripts/eda/run_dfrbp_model_test.js
 *   node scripts/eda/run_dfrbp_model_test.js --verbose
 *   node scripts/eda/run_dfrbp_model_test.js --stub <file> --tag <name>
 *
 * Exit: 0 pass, 1 fail, 2 blocked (missing tool or input).
 * Artifacts: build/asic_evidence/dfrbp_model/
 */
const { spawnSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'asic_evidence', 'dfrbp_model');
const LOGS = path.join(OUT, 'logs');
const SRC = path.join(ROOT, 'asic', 'synthesis', 'techmap', 'dfrbp_model');

const LIB = path.join(ROOT, 'build', 'asic_evidence', 'sky130_tt.lib');
const SUBSET = path.join(ROOT, 'build', 'asic_evidence', 'sky130_full_subset.lib');
const MAP = path.join(ROOT, 'build', 'asic_evidence', 'sky130_map.v');
const TB = path.join(SRC, 'tb_dfrbp_model.v');
const PREFIX = path.join(SRC, 'sky130_stub_prefix.v');

const verbose = process.argv.includes('--verbose');
function argValue(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}
const STUB = path.resolve(ROOT, argValue('--stub', 'build/asic_evidence/arith_work/sky130_stub.v'));
const TAG = argValue('--tag', 'postfix');

const CELLS = ['sky130_fd_sc_hd__dfrbp_1', 'sky130_fd_sc_hd__dfrbp_2'];

const TOOL_DIR = process.env.EDA_TOOLS || 'D:/tools/oss-cad-suite';
const env = { ...process.env };
env.PATH = [path.join(TOOL_DIR, 'bin'), path.join(TOOL_DIR, 'lib'), env.PATH].join(path.delimiter);

fs.mkdirSync(LOGS, { recursive: true });

const results = [];
function record(step, ok, detail) {
  results.push({ step, ok, detail });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${step}${detail ? ' — ' + detail : ''}`);
}

function run(name, cmd, args) {
  const log = path.join(LOGS, `${name}.log`);
  const r = spawnSync(cmd, args, { cwd: ROOT, env, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const text = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(log, `$ ${cmd} ${args.join(' ')}\n\n${text}`);
  if (verbose) process.stdout.write(text);
  return { status: r.status === null ? 1 : r.status, text, log, error: r.error };
}

function sha256(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

function have(cmd) {
  const r = spawnSync(cmd, ['-V'], { cwd: ROOT, env, encoding: 'utf8' });
  return !(r.error && (r.error.code === 'ENOENT' || r.error.code === 'EACCES'));
}

// Liberty cell body: from `cell ("name")` to the next `cell ("` at cell indentation.
function cellBlock(text, name) {
  const start = text.indexOf(`cell ("${name}")`);
  if (start < 0) return null;
  const next = text.indexOf('    cell ("', start + 1);
  return text.slice(start, next < 0 ? text.length : next);
}

function ffBlock(cellText) {
  const m = cellText && cellText.match(/ff\s*\([^)]*\)\s*\{([\s\S]*?)\}/);
  return m ? m[1] : null;
}

function attr(ffText, key) {
  const m = ffText && ffText.match(new RegExp(`${key}\\s*:\\s*"([^"]*)"`));
  return m ? m[1] : null;
}

const norm = s => (s || '').replace(/\s+/g, ' ').trim();

// ---- 0. inputs and tools ---------------------------------------------------
for (const f of [LIB, SUBSET, MAP, TB, PREFIX, STUB]) {
  if (!fs.existsSync(f)) {
    console.log(`FAIL  input ${path.relative(ROOT, f)} missing`);
    console.log('DFRBP_MODEL_TEST: BLOCKED');
    process.exit(2);
  }
}
for (const tool of ['iverilog', 'vvp']) {
  if (!have(tool)) {
    console.log(`FAIL  tool ${tool} not found (EDA_TOOLS=${TOOL_DIR})`);
    console.log('DFRBP_MODEL_TEST: BLOCKED');
    process.exit(2);
  }
}

// ---- 1. liberty definition -------------------------------------------------
const libText = fs.readFileSync(LIB, 'utf8');
const libFf = {};

for (const cell of CELLS) {
  const block = cellBlock(libText, cell);
  const ff = ffBlock(block);
  libFf[cell] = ff;
  if (!ff) {
    record(`liberty ${cell}`, false, 'no ff block found');
    continue;
  }
  const clockedOn = attr(ff, 'clocked_on');
  const clear = attr(ff, 'clear');
  const nextState = attr(ff, 'next_state');
  const rising = (block.match(/timing_type\s*:\s*"rising_edge"/g) || []).length;
  const falling = (block.match(/timing_type\s*:\s*"falling_edge"/g) || []).length;
  const ok = clockedOn === 'CLK' && clear === '!RESET_B' && nextState === 'D' && rising > 0 && falling === 0;
  record(`liberty ${cell}`, ok,
    `clocked_on="${clockedOn}", clear="${clear}", next_state="${nextState}", ` +
    `rising_edge arcs=${rising}, falling_edge arcs=${falling}`);
  fs.writeFileSync(path.join(OUT, `liberty_${cell}_ff.txt`), `${ff.trim()}\n`);
}
fs.writeFileSync(path.join(OUT, 'liberty_source.txt'),
  `source: ${path.relative(ROOT, LIB)}\nsha256: ${sha256(LIB)}\n\n` +
  CELLS.map(c => `--- ${c} ff block ---\n${(libFf[c] || '<missing>').trim()}\n`).join('\n'));

// ---- 2. subset liberty parity ---------------------------------------------
const subText = fs.readFileSync(SUBSET, 'utf8');
let parity = true;
const parityDetail = [];
for (const cell of CELLS) {
  const a = norm(libFf[cell]);
  const b = norm(ffBlock(cellBlock(subText, cell)));
  const same = a !== '' && a === b;
  parity = parity && same;
  parityDetail.push(`${cell}: ${same ? 'identical' : 'DIFFERS'}${b ? '' : ' (missing)'}`);
}
record('subset ff block matches full liberty', parity, parityDetail.join('; '));

// ---- 3. stub event control -------------------------------------------------
const stubText = fs.readFileSync(STUB, 'utf8');
for (const cell of CELLS) {
  const start = stubText.indexOf(`module ${cell}`);
  const body = start < 0 ? '' : stubText.slice(start, stubText.indexOf('endmodule', start));
  const posedgeClk = /@\s*\(\s*posedge\s+CLK\s+or\s+negedge\s+RESET_B\s*\)/.test(body);
  const negedgeClk = /negedge\s+CLK|posedge\s+RESET_B/.test(body);
  const qn = /assign\s+Q_N\s*=\s*~\s*Q\s*;/.test(body);
  const clear = /if\s*\(\s*!\s*RESET_B\s*\)\s*Q\s*<=\s*1'b0\s*;/.test(body);
  record(`stub ${cell}`, body !== '' && posedgeClk && !negedgeClk && qn && clear,
    `posedge CLK + negedge RESET_B=${posedgeClk}, wrong-edge text=${negedgeClk}, ` +
    `Q_N=~Q=${qn}, clear to 0=${clear}`);
}

// ---- 3b. every sequential cell: liberty clocked_on vs stub event control ---
const SEQ = ['dfrtp_1', 'dfrtp_2', 'dfrtp_4', 'dfstp_1', 'dfstp_2', 'dfstp_4',
  'dfxtp_1', 'dfxtp_2', 'dfxtp_4', 'dfrbp_1', 'dfrbp_2'];
const seqBad = [];
for (const short of SEQ) {
  const cell = `sky130_fd_sc_hd__${short}`;
  const co = attr(ffBlock(cellBlock(libText, cell)), 'clocked_on');
  const start = stubText.indexOf(`module ${cell}`);
  const body = start < 0 ? '' : stubText.slice(start, stubText.indexOf('endmodule', start));
  if (!co) { seqBad.push(`${short}: no liberty clocked_on`); continue; }
  if (body === '') { seqBad.push(`${short}: no stub module`); continue; }
  const libertyRising = !/^[!~]/.test(co.trim());
  const stubRising = /@\s*\(\s*posedge\s+CLK/.test(body);
  const stubFalling = /@\s*\(\s*negedge\s+CLK/.test(body);
  if (libertyRising !== stubRising || libertyRising === stubFalling) {
    seqBad.push(`${short}: liberty clocked_on="${co}" vs stub ` +
      `${stubFalling ? 'negedge' : stubRising ? 'posedge' : 'no clock edge'}`);
  }
}
record('stub sequential cells match liberty clocked_on', seqBad.length === 0,
  seqBad.length ? seqBad.join('; ') : `${SEQ.length}/${SEQ.length} cells: edge polarity agrees`);

// ---- 3c. mapper comparison -------------------------------------------------
const mapText = fs.readFileSync(MAP, 'utf8');
const mapCells = [...new Set((mapText.match(/sky130_fd_sc_hd__[a-z0-9_]+\s+u_[A-Za-z0-9_]+/g) || [])
  .map(s => s.trim().split(/\s+/)[0]))].sort();
record('mapper does not emit dfrbp',
  !mapCells.some(c => /__dfrbp_/.test(c)),
  `mapper instantiates: ${mapCells.join(', ')}`);

function walk(dir, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (/\.s?v$/.test(e.name)) acc.push(p);
  }
  return acc;
}
// Exclude this test's own sources: the bench instantiates dfrbp on purpose, it
// is not a netlist that the flow produced.
const netlists = [ROOT + '/build/asic_evidence', ROOT + '/asic/synthesis', ROOT + '/rtl']
  .reduce((acc, d) => walk(d, acc), [])
  .filter(f => !f.startsWith(SRC + path.sep));
let dfrbpUses = 0;
for (const f of netlists) {
  const hits = (fs.readFileSync(f, 'utf8').match(/^[ \t]*sky130_fd_sc_hd__dfrbp_[12][ \t]+[A-Za-z_]/gm) || []).length;
  dfrbpUses += hits;
}
record('dfrbp instantiation inventory', true,
  `${dfrbpUses} instantiation(s) in ${netlists.length} netlist files (model is ` +
  `${dfrbpUses === 0 ? 'currently unreferenced' : 'LIVE'})`);

// ---- 4. negative control is the pre-fix model ------------------------------
const prefixText = fs.readFileSync(PREFIX, 'utf8');
const prefixBad = CELLS.every(cell => {
  const start = prefixText.indexOf(`module ${cell}`);
  const body = start < 0 ? '' : prefixText.slice(start, prefixText.indexOf('endmodule', start));
  return /negedge\s+CLK/.test(body);
});
record('negative control is the pre-fix model', prefixBad,
  `negedge CLK in both dfrbp modules; sha256=${sha256(PREFIX).slice(0, 16)}…`);

// ---- 5/6. simulation -------------------------------------------------------
function simulate(stubPath, tag) {
  const vvp = path.join(OUT, `sim_${tag}.vvp`);
  const compile = run(`${tag}_compile`, 'iverilog', ['-g2012', '-o', vvp, TB, stubPath]);
  if (compile.status !== 0) return { compile, sim: null };
  const sim = run(`${tag}_sim`, 'vvp', [vvp]);
  return { compile, sim };
}

const post = simulate(STUB, `${TAG}_stub`);
const postOk = post.compile.status === 0 && post.sim && post.sim.status === 0 &&
  /DFRBP_MODEL: PASS/.test(post.sim.text) && !/^FAIL /m.test(post.sim.text);
record('simulation: tested stub', !!postOk, post.sim
  ? `iverilog exit ${post.compile.status}, vvp exit ${post.sim.status}, ` +
    (post.sim.text.match(/DFRBP_MODEL: [^\n]*/) || ['no verdict line'])[0]
  : `compile failed (exit ${post.compile.status}), log ${path.relative(ROOT, post.compile.log)}`);

const neg = simulate(PREFIX, `${TAG}_prefix`);
const negOk = neg.compile.status === 0 && neg.sim && neg.sim.status !== 0 &&
  /DFRBP_MODEL: FAIL/.test(neg.sim.text);
record('simulation: negative control fails', !!negOk, neg.sim
  ? `vvp exit ${neg.sim.status} (expected non-zero), ` +
    (neg.sim.text.match(/FAIL [^\n]*/) || ['no failure line'])[0].slice(0, 120)
  : `compile failed (exit ${neg.compile.status})`);

// ---- evidence --------------------------------------------------------------
const failed = results.filter(r => !r.ok).length;
const evidence = {
  finding: 'F3',
  generated_local: new Date().toLocaleString('sv-SE', { timeZone: 'Asia/Kolkata' }) + ' IST',
  generated_utc: new Date().toISOString(),
  tested_stub: path.relative(ROOT, STUB).split(path.sep).join('/'),
  hashes: {
    [path.relative(ROOT, LIB).split(path.sep).join('/')]: sha256(LIB),
    [path.relative(ROOT, SUBSET).split(path.sep).join('/')]: sha256(SUBSET),
    [path.relative(ROOT, STUB).split(path.sep).join('/')]: sha256(STUB),
    [path.relative(ROOT, MAP).split(path.sep).join('/')]: sha256(MAP),
    [path.relative(ROOT, TB).split(path.sep).join('/')]: sha256(TB),
    [path.relative(ROOT, PREFIX).split(path.sep).join('/')]: sha256(PREFIX),
  },
  liberty_ff: libFf,
  mapper_cells: mapCells,
  dfrbp_instantiations: dfrbpUses,
  steps: results,
};
fs.writeFileSync(path.join(OUT, 'evidence.json'), JSON.stringify(evidence, null, 2) + '\n');

console.log('');
console.log(`DFRBP_MODEL_TEST: ${results.length - failed}/${results.length} steps passed ` +
  `(stub=${path.relative(ROOT, STUB).split(path.sep).join('/')}, tag=${TAG})`);
process.exit(failed === 0 ? 0 : 1);
