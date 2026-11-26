#!/usr/bin/env node
/*
 * Home-Automation-SoC — path-based static timing analysis (OpenSTA)
 *
 * This is the real replacement for the SDC-only check: it maps has_soc to
 * sky130_fd_sc_hd cells, links the netlist against the sky130 Liberty files and
 * applies constraints/timing_constraints/has_soc.sdc, then reports slack on
 * actual paths. scripts/eda/run_sdc_lint.js still runs separately to check
 * constraint-file validity and port coverage; this script answers "does the
 * design meet 20 ns?".
 *
 * Stages
 *   1. Yosys: synth -flatten -> dfflibmap -> structural mux2 map -> abc
 *      (scripts/sta/synth_has_soc.ys). Fails if any Yosys internal `$` cell
 *      survives — an unmapped netlist has no liberty timing.
 *   2. OpenSTA (WSL): read Liberty + netlist + SDC, link, report WNS/TNS and
 *      the worst setup/hold paths (scripts/sta/has_soc_sta.tcl).
 *   3. Parse the STA-WNS-* / STA-RESULT markers; exit nonzero on violation.
 *
 * Scope of the numbers: single TT corner (1.8 V, 25 C) for standard cells and
 * SRAM macros, ideal clocks with the SDC's 100 ps/50 ps uncertainty, and no
 * extracted parasitics. This is pre-layout timing on a real mapped netlist —
 * not signoff, and not a claim that the design is tapeout-ready.
 *
 * Requirements (see docs/EXTERNAL_DEPENDENCIES.md)
 *   * Yosys (OSS CAD Suite) on Windows
 *   * OpenSTA 3.1 in WSL2 (Linux binary; /d/tools/opensta/bin/sta)
 *   * SkyWater sky130A PDK with sky130_fd_sc_hd + sky130_sram_macros Liberty
 *
 * Usage: node scripts/eda/run_sta.js [--verbose]
 * Env:   SKY130A   path to the sky130A PDK root (default: volare pin below)
 *        STA      OpenSTA binary as seen inside WSL
 *        STA_LIB  directory containing libcudd (LD_LIBRARY_PATH for sta)
 *        WSL_DISTRO  WSL distribution name (default: Ubuntu-24.04)
 * Logs:  build/sta/synth.log, build/sta/sta.log, build/sta/has_soc_gate.v
 * Exit:  0 timing met, 1 timing violation or setup problem, 2 tool missing.
 */
const { spawnSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'sta');
const verbose = process.argv.includes('--verbose');

// Volare sky130 pin used by this project (docs/EXTERNAL_DEPENDENCIES.md).
const SKY130_COMMIT = process.env.SKY130_COMMIT || '0fe599b2afb6708d281543108caf8310912f54af';
const WSL_DISTRO = process.env.WSL_DISTRO || 'Ubuntu-24.04';
const DEFAULT_PDK = `//wsl$/${WSL_DISTRO}/root/.volare/volare/sky130/versions/${SKY130_COMMIT}/sky130A`;

const LIB_FILES = [
  'libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib',
  'libs.ref/sky130_sram_macros/lib/sky130_sram_2kbyte_1rw1r_32x512_8_TT_1p8V_25C.lib',
  'libs.ref/sky130_sram_macros/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib',
];

function findTool(name, envVar, candidates, probeArgs) {
  if (process.env[envVar]) {
    if (fs.existsSync(process.env[envVar])) {
      return process.env[envVar];
    }
    console.error('sta: ' + envVar + ' is set but the path does not exist: ' + process.env[envVar]);
    return null;
  }
  for (const c of candidates) if (fs.existsSync(c)) return c;
  const r = spawnSync(name, probeArgs || ['-V'], { encoding: 'utf8' });
  if (r.error) {
    if (r.error.code === 'ENOENT') {
      console.error('sta: ' + name + ' not found on PATH or any known candidate (env ' + envVar + ')');
    } else {
      console.error('sta: ' + name + ' probe failed: ' + r.error.message);
    }
    return null;
  }
  if (r.status !== 0) {
    console.error('sta: ' + name + ' probe exited with ' + r.status + ' (version string unavailable)');
    return name;
  }
  return name;
}

const YOSYS = findTool('yosys', 'YOSYS', ['D:/tools/oss-cad-suite/bin/yosys.exe'], ['-V']);
const SUITE_ENV = (() => {
  const bat = 'D:/tools/oss-cad-suite/environment.bat';
  return process.platform === 'win32' && fs.existsSync(bat) ? bat : null;
})();

// OpenSTA is an ELF binary: it only runs inside WSL.
// Paths are as seen *inside* WSL (the /mnt/d view of D:\tools).
const STA_BIN = process.env.STA || '/mnt/d/tools/opensta/bin/sta';
const STA_LIB = process.env.STA_LIB || '/mnt/d/tools/opensta/lib';

function rtlFiles() {
  return fs.readFileSync(path.join(ROOT, 'rtl', 'filelist.f'), 'utf8')
    .split('\n').map(l => l.trim())
    .filter(l => l && !l.startsWith('//'));
}

/** Windows path (drive letter or \\wsl$) -> path as seen inside WSL. */
function toWsl(p) {
  if (/^\/\/wsl\$\//i.test(p)) {
    // //wsl$/Ubuntu-24.04/x/y -> /x/y  (the WSL distro mount is invisible
    // inside WSL; drop the distro prefix so WSL resolves the path itself).
    return p.replace(/^\/\/wsl\$\/[^/]+/, '/');
  }
  if (/^[A-Za-z]:/.test(p)) {
    return '/mnt/' + p[0].toLowerCase() + p.slice(2).replace(/\\/g, '/');
  }
  return p.replace(/\\/g, '/');
}

/** Windows env-var value to the path form WSL will resolve.
 * STA_LIBERTY, STA_NETLIST etc. are plaintext values (not shell-quoted) that
 * the Tcl script consumes as-is, so they must already be valid inside WSL.
 * Windows drive letters map to /mnt/<drive> (the WSL interop mount) and
 * //wsl$ prefixes map to /<rest> (the WSL distro root is visible from Linux).
 * Separator canonicalisation is applied so a value like D:\tools\opensta\lib
 * becomes /mnt/d/tools/opensta/lib consistently, and mixed separators are
 * harmless.
 */
function wslEnvValue(p) {
  if (/^\/\/wsl\$\//i.test(p)) {
    return p.replace(/^\/\/wsl\$\/[^/]+/, '/');
  }
  if (/^[A-Za-z]:/.test(p)) {
    return '/mnt/' + p[0].toLowerCase() + p.slice(2).replace(/\\/g, '/');
  }
  return p.replace(/\\/g, '/');
}

function sha256(file) {
  try {
    return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  } catch {
    return 'unreadable';
  }
}

// Yosys emits hundreds of megabytes of warnings on this design, so both tools
// write straight to their log file instead of through spawnSync's buffers.
function execYosys(script, logPath) {
  if (SUITE_ENV) {
    const cmd = `call "${SUITE_ENV}" && yosys -s "${script}" > "${logPath}" 2>&1`;
    return spawnSync(cmd, { cwd: ROOT, encoding: 'utf8', shell: 'cmd.exe', timeout: 1800000 });
  }
  const out = fs.openSync(logPath, 'w');
  try {
    return spawnSync(YOSYS, ['-s', script], { cwd: ROOT, stdio: ['ignore', out, out], timeout: 1800000 });
  } finally {
    fs.closeSync(out);
  }
}

function shQuote(value) {
  return "'" + String(value).replace(/'/g, `'\\''`) + "'";
}

function execSta(tclScript, logPath, env) {
  // Environment variables consumed by the Tcl script (STA_LIBERTY, STA_NETLIST,
  // STA_SDC, STA_TOP) are forwarded into the WSL session via STA_* exports.
  // All other (non-STA) env vars inherited from the Windows Node process are
  // dropped so they cannot leak; the WSL PATH stays on /mnt/d/tools/... as
  // configured for the OpenSTA binary in the WSL installation.
  // Pass the STA_* values verbatim. OpenSTA's Tcl env-reader is case-
  // sensitive, so export names use the canonical uppercase prefix the script
  // expects; the value is a filesystem path inside WSL.
  const wslEnv = {};
  for (const [k, v] of Object.entries(env)) {
    if (/^STA_/.test(k)) {
      wslEnv[k] = wslEnvValue(String(v));
    } else if (/^GATE_VENDOR_BASELINE_CRL_SETTING$/i.test(k)) {
      wslEnv[k] = String(v);
    }
  }
  if (process.env.GATE_VENDOR_BASELINE_CRL_SETTING) {
    wslEnv.GATE_VENDOR_BASELINE_CRL_SETTING = process.env.GATE_VENDOR_BASELINE_CRL_SETTING;
  }
  const exports = Object.entries(wslEnv)
    .map(([k, v]) => `export ${k}=${shQuote(v)}; `)
    .join('');
  const staLogWsl = toWsl(logPath);
  const tclWsl = toWsl(tclScript);
  const cmd = `${exports}LD_LIBRARY_PATH=${shQuote(STA_LIB)} ${shQuote(STA_BIN)}` +
    ` -no_splash -no_init -exit ${shQuote(tclWsl)} > ${shQuote(staLogWsl)} 2>&1`;
  return spawnSync('wsl.exe', ['-e', 'bash', '-lc', cmd], { encoding: 'utf8', timeout: 1800000 });
}

function main() {
  fs.mkdirSync(OUT, { recursive: true });

  const pdk = process.env.SKY130A || DEFAULT_PDK;
  // Yosys is a native Windows binary (oss-cad-suite), so the PDK path is used
  // as-is on Windows when synthesizing. OpenSTA runs inside WSL as a Linux ELF
  // and needs the WSL-side /root/.volare path; the value is converted only for
  // the STA run, not for the missing-check on Windows.
  const libs = LIB_FILES.map(f => path.join(pdk, f));
  const wslPdk = wslEnvValue(pdk);
  const wslLibs = LIB_FILES.map(f => path.join(wslPdk, f));
  const missing = libs.filter(f => !fs.existsSync(f));
  if (missing.length) {
    console.error('sta: sky130A Liberty not found:');
    for (const f of missing) console.error('  ' + f);
    console.error('Set SKY130A to a sky130A PDK root containing libs.ref/ (see docs/EXTERNAL_DEPENDENCIES.md).');
    process.exit(2);
  }
  if (!YOSYS) {
    console.error('sta: yosys not found (set YOSYS or install OSS CAD Suite)');
    process.exit(2);
  }

  const stdLib = libs[0];
  const netlist = path.join(OUT, 'has_soc_gate.v');
  const ysScript = path.join(OUT, 'synth_has_soc.ys');
  const tclScript = path.join(ROOT, 'scripts', 'sta', 'has_soc_sta.tcl');
  const sdc = path.join(ROOT, 'constraints', 'timing_constraints', 'has_soc.sdc');

  //----------------------------------------------------------------------------
  // 1. Gate-level netlist
  //----------------------------------------------------------------------------
  const template = fs.readFileSync(path.join(ROOT, 'scripts', 'sta', 'synth_has_soc.ys'), 'utf8');
  const rtl = rtlFiles();
  const readVerilog = 'read_verilog -sv -Irtl/rtl_top ' + rtl.join(' ');
  fs.writeFileSync(ysScript, template
    .replace('@RTL@', readVerilog)
    .replace(/@LIBERTY@/g, stdLib)
    .replace('@NETLIST@', netlist));

  console.log('sta: mapping has_soc to sky130_fd_sc_hd (Yosys; this takes minutes)');
  const synthLog = path.join(OUT, 'synth.log');
  const synth = execYosys(ysScript, synthLog);
  const synthOut = fs.existsSync(synthLog) ? fs.readFileSync(synthLog, 'utf8') : '';
  if (synth.error) {
    console.error('sta: yosys failed to start: ' + synth.error.message);
    process.exit(2);
  }
  if (synth.status !== 0) {
    console.error('sta: synthesis failed (exit ' + synth.status + '), see build/sta/synth.log');
    process.exit(1);
  }

  // Fail-fast on unmapped netlist so the run exits before it reaches
  // OpenSTA, where an unmapped netlist would only surface later as
  // "no timed path found" — harder to attribute.
  if (!fs.existsSync(netlist)) {
    console.error('sta: synthesis did not produce the gate-level netlist (see build/sta/synth.log)');
    process.exit(1);
  }
  const netlistSource = fs.readFileSync(netlist, 'utf8');

  // OpenSTA's Verilog reader rejects `wire signed`, which Yosys emits for any
  // RTL signal declared signed. Signedness carries no connectivity meaning in
  // a structural netlist, so the keyword is removed before analysis.
  const unsigned = netlistSource.replace(/\b(wire|reg|input|output|inout)\s+signed\b/g, '$1');
  if (unsigned !== netlistSource) fs.writeFileSync(netlist, unsigned);

  // An unmapped netlist links but has no cell timing, so reject Yosys `$` cells.
  // Check the written netlist (after the signed-fixer rewrite, if any), not the
  // log: Yosys also prints stats for the pre-mapping netlist, and those lines
  // are not about the final design. Also catches escaped forms such as `\$lut`,
  // which Yosys emits as cells.
  const finalNetlist = fs.readFileSync(netlist, 'utf8');
  const unmappedCells = (finalNetlist.match(/^\s+\\?\$[A-Za-z_]\w*\s/gm) || []);
  if (unmappedCells.length) {
    console.error('sta: netlist is not fully mapped; ' + unmappedCells.length + ' Yosys cells survive');
    for (const l of unmappedCells.slice(0, 10)) console.error('  ' + l.trim());
    process.exit(1);
  }

  //----------------------------------------------------------------------------
  // 2. Path-based timing
  //----------------------------------------------------------------------------
  console.log('sta: running OpenSTA on the mapped netlist');
  const staLogPath = path.join(OUT, 'sta.log');
  const sta = execSta(toWsl(tclScript), staLogPath, {
    STA_LIBERTY: wslLibs.map(wslEnvValue).join(';'),
    STA_NETLIST: wslEnvValue(netlist),
    STA_SDC: wslEnvValue(sdc),
    STA_TOP: 'has_soc',
  });
  const staLog = fs.existsSync(staLogPath) ? fs.readFileSync(staLogPath, 'utf8') : '';
  if (sta.error) {
    console.error('sta: OpenSTA failed to start inside WSL: ' + sta.error.message);
    console.error('sta: OpenSTA needs WSL2 and ' + STA_LIB + ' (libcudd). See docs/EXTERNAL_DEPENDENCIES.md.');
    process.exit(2);
  }
  if (verbose) console.log(staLog);
  if (/could not load program|No such file or directory|command not found/.test(staLog) &&
      !/STA-RESULT=/.test(staLog)) {
    console.error('sta: OpenSTA could not run (see build/sta/sta.log)');
    process.exit(2);
  }

  //----------------------------------------------------------------------------
  // 3. Result
  //----------------------------------------------------------------------------
  const marker = name => {
    const m = staLog.match(new RegExp('^' + name + '=(.*)$', 'm'));
    return m ? m[1].trim() : '';
  };
  const result = marker('STA-RESULT');
  const summary = {
    setup: marker('STA-WNS-SETUP'),
    hold: marker('STA-WNS-HOLD'),
    tnsSetup: marker('STA-TNS-SETUP'),
    tnsHold: marker('STA-TNS-HOLD'),
    clocks: marker('STA-CLOCKS'),
    registers: marker('STA-REGISTERS'),
  };

  console.log('');
  console.log('sta: PDK          ' + pdk);
  console.log('sta: liberty      ' + path.basename(stdLib) + ' sha256=' + sha256(stdLib).slice(0, 16));
  console.log('sta: clocks       ' + (summary.clocks || '?') + ', registers ' + (summary.registers || '?'));
  console.log('sta: WNS setup    ' + (summary.setup || 'n/a') + ' ns');
  console.log('sta: WNS hold     ' + (summary.hold || 'n/a') + ' ns');
  console.log('sta: TNS setup    ' + (summary.tnsSetup || 'n/a') + ' ns');
  console.log('sta: TNS hold     ' + (summary.tnsHold || 'n/a') + ' ns');
  console.log('sta: log          build/sta/sta.log');

  if (result === 'PASS') {
    console.log('sta: RESULT=PASS (20 ns sys_clk met on the mapped netlist, TT corner)');
    process.exit(0);
  }
  if (result === 'FAIL') {
    console.log('sta: RESULT=FAIL (see the violation lines in build/sta/sta.log)');
    process.exit(1);
  }
  console.error('sta: no STA-RESULT marker in build/sta/sta.log — analysis did not complete');
  process.exit(1);
}

main();
