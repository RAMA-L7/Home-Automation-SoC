#!/usr/bin/env node
/*
 * Home-Automation-SoC — macro-wrapper verification runner
 *
 * Runs sim/sim_top/tb_sram_macro_wrap.v three times against the same RTL:
 *
 *   1. PRODUCTION      sram_macro_wrap (64 banks, 128 KiB)
 *                      tcm_macro_wrap  (16 banks,  32 KiB)
 *                      MUST pass every check.
 *   2. NEG_BANK        bank-select bits forced to 0 at the wrapper boundary
 *                      MUST fail  (proves the bank-boundary/alias checks bite)
 *   3. NEG_STROBE      wstrb forced to 4'hF at the wrapper boundary
 *                      MUST fail  (proves the strobe checks bite)
 *
 * A run counts as PASS only if the binary was produced, vvp exited 0, the
 * RESULT=PASS marker is present and the reported check/error counts agree.
 * A negative control counts as PASS only if it produced RESULT=FAIL with a
 * non-zero error count — a control that passes means the checker is broken.
 *
 * Usage:
 *   node scripts/eda/run_macro_wrapper.js [--verbose]
 *
 * Logs: build/sim/macro_wrapper_<mode>.log
 * Exit: 0 all three behave as required, 1 otherwise, 2 tool missing.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'sim');
const verbose = process.argv.includes('--verbose');

const MIN_CHECKS = 81;

function findTool(name, envVar, candidates) {
  if (process.env[envVar] && fs.existsSync(process.env[envVar])) return process.env[envVar];
  for (const c of candidates) if (fs.existsSync(c)) return c;
  const which = spawnSync(name, ['-V'], { encoding: 'utf8' });
  return which.error ? null : name;
}

// vvp.exe on Windows resolves libvvp-1.dll relative to PATH, and a POSIX-style
// /d/tools path is not usable by the Windows loader, so the tool directory is
// prepended in native form.
function toWinPath(p) {
  if (process.platform !== 'win32') return p;
  const m = /^\/([a-zA-Z])\/(.*)$/.exec(p);
  return m ? `${m[1].toUpperCase()}:/${m[2]}` : p;
}

const IVERILOG = findTool('iverilog', 'IVERILOG', [
  'D:/tools/oss-cad-suite/bin/iverilog.exe',
  '/d/tools/oss-cad-suite/bin/iverilog.exe',
]);
const VVP = findTool('vvp', 'VVP', [
  'D:/tools/oss-cad-suite/bin/vvp.exe',
  '/d/tools/oss-cad-suite/bin/vvp.exe',
]);

const COMMON = [
  'sim/models/sky130_sram_sim_model.v',
  'sim/sim_top/tb_sram_macro_wrap.v',
  'sim/sim_top/tb_macro_wrap_negctl.v',
  'rtl/rtl_top/sram_macro_wrap.sv',
  'rtl/rtl_top/tcm_macro_wrap.sv',
];

const MODES = [
  { name: 'PROD',       defs: [],                expectPass: true  },
  { name: 'NEG_BANK',   defs: ['-DNEG_BANK'],    expectPass: false },
  { name: 'NEG_STROBE', defs: ['-DNEG_STROBE'],  expectPass: false },
];

// The oss-cad-suite executables need their suite environment (DLL search path)
// on Windows; calling environment.bat first is the supported way in. On other
// platforms the tool is invoked directly.
const SUITE_ENV = (() => {
  if (process.platform !== 'win32' || !VVP) return null;
  const suite = path.dirname(path.dirname(toWinPath(VVP)));
  const envBat = path.join(suite, 'environment.bat');
  return fs.existsSync(envBat) ? envBat : null;
})();

function execTool(tool, args) {
  if (SUITE_ENV) {
    const quoted = [tool, ...args].map(a => (/\s/.test(a) ? `"${a}"` : a)).join(' ');
    return spawnSync(`call "${SUITE_ENV}" && ${quoted}`, {
      cwd: ROOT, encoding: 'utf8', shell: 'cmd.exe',
    });
  }
  return spawnSync(tool, args, { cwd: ROOT, encoding: 'utf8' });
}

function run(mode) {
  const vvpFile = path.join(OUT, `macro_wrapper_${mode.name}.vvp`);
  const log = path.join(OUT, `macro_wrapper_${mode.name}.log`);
  const args = [
    '-g2012', '-DUSE_POWER_PINS', '-DSIM_MEM_PRELOAD', ...mode.defs,
    '-o', vvpFile, '-s', 'tb_sram_macro_wrap',
    ...COMMON,
  ];
  const compile = execTool(IVERILOG, args);
  const compileLog = `${compile.stdout || ''}${compile.stderr || ''}`;
  if (compile.status !== 0 || !fs.existsSync(vvpFile)) {
    fs.writeFileSync(log, `COMPILE FAILED (exit ${compile.status})\n${compileLog}\n`);
    return { ok: false, reason: `compile failed (exit ${compile.status})` };
  }
  const sim = execTool(VVP, [vvpFile]);
  const text = `${sim.stdout || ''}${sim.stderr || ''}`;
  fs.writeFileSync(log, `COMPILE OK\n${compileLog}\n--- SIMULATION (exit ${sim.status}) ---\n${text}\n`);

  const checks = /checks=(\d+)\s+errors=(\d+)\s+timeouts=(\d+)/.exec(text);
  if (!checks) return { ok: false, reason: 'no checks=/errors= marker in output' };

  const nChecks = Number(checks[1]);
  const nErrors = Number(checks[2]);
  const nTo = Number(checks[3]);
  const passed = text.includes('RESULT=PASS');
  const failed = text.includes('RESULT=FAIL');

  if (nChecks < MIN_CHECKS) {
    return { ok: false, reason: `only ${nChecks} checks ran (< ${MIN_CHECKS})`, nChecks, nErrors };
  }
  if (nTo > 0) {
    return { ok: false, reason: `${nTo} timeouts`, nChecks, nErrors };
  }

  if (mode.expectPass) {
    if (!passed) return { ok: false, reason: 'RESULT=PASS marker missing', nChecks, nErrors };
    if (nErrors !== 0) return { ok: false, reason: `${nErrors} errors reported`, nChecks, nErrors };
    if (sim.status !== 0) return { ok: false, reason: `vvp exit ${sim.status}`, nChecks, nErrors };
    return { ok: true, nChecks, nErrors };
  }
  // Negative control: must FAIL with at least one error.
  if (!failed) return { ok: false, reason: 'negative control PASSED — checker does not discriminate', nChecks, nErrors };
  if (nErrors < 1) return { ok: false, reason: 'negative control reported FAIL but zero errors', nChecks, nErrors };
  return { ok: true, nChecks, nErrors };
}

function main() {
  if (!IVERILOG || !VVP) {
    console.error('macro-wrapper: iverilog/vvp not found (set IVERILOG and VVP)');
    process.exit(2);
  }
  fs.mkdirSync(OUT, { recursive: true });

  let allOk = true;
  for (const mode of MODES) {
    const r = run(mode);
    const expect = mode.expectPass ? 'MUST PASS' : 'MUST FAIL';
    if (r.ok) {
      console.log(`macro-wrapper: ${mode.name.padEnd(10)} ${expect.padEnd(9)} ok   checks=${r.nChecks} errors=${r.nErrors}`);
    } else {
      allOk = false;
      console.log(`macro-wrapper: ${mode.name.padEnd(10)} ${expect.padEnd(9)} BAD  ${r.reason}`);
    }
    if (verbose) console.log(`  log: build/sim/macro_wrapper_${mode.name}.log`);
  }

  console.log(allOk
    ? 'macro-wrapper: RESULT PASS (production geometry 64-bank SRAM + 16-bank TCM, proxy macro model; 2 negative controls rejected)'
    : 'macro-wrapper: RESULT FAIL');
  process.exit(allOk ? 0 : 1);
}

main();
