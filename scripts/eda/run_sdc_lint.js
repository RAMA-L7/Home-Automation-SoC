#!/usr/bin/env node
/*
 * Home-Automation-SoC — SDC validation driver
 *
 * 1. Reads the top-level port list out of rtl/rtl_top/has_soc.sv (the single
 *    source of truth) and writes build/sta/has_soc_ports.txt.
 * 2. Executes constraints/timing_constraints/has_soc.sdc under tclsh with the
 *    SDC commands stubbed (scripts/sta/sdc_check.tcl), which validates Tcl
 *    syntax, object resolution and per-port coverage.
 *
 * This is a CONSTRAINT-FILE check and never computes slack.  Path-based STA is
 * a SEPARATE target: `node scripts/eda/run_sta.js` maps has_soc with Yosys and
 * runs OpenSTA 3.1.0 (Linux build, WSL2) against the sky130 liberty files.  Do
 * not cite a PASS from this script as timing evidence; it only says the
 * constraint file parses, resolves every object and covers every port.
 *
 * Usage: node scripts/eda/run_sdc_lint.js [--verbose]
 * Logs:  build/sta/sdc_lint.log
 * Exit:  0 validated, 1 validation failure, 2 tool missing.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'sta');
const verbose = process.argv.includes('--verbose');

function findTclsh() {
  const candidates = [
    process.env.TCLSH,
    'C:/Program Files/Git/mingw64/bin/tclsh.exe',
    'D:/tools/magic/usr/bin/tclsh8.6.exe',
    'D:/tools/netgen/usr/bin/tclsh8.6.exe',
  ].filter(Boolean);
  for (const c of candidates) if (fs.existsSync(c)) return c;
  const r = spawnSync('tclsh', ['-h'], { encoding: 'utf8' });
  return r.error ? null : 'tclsh';
}

/** Port names of `has_soc`, vectors expanded to bit names. */
function topPorts() {
  const src = fs.readFileSync(path.join(ROOT, 'rtl', 'rtl_top', 'has_soc.sv'), 'utf8');
  const start = src.indexOf('module has_soc');
  if (start < 0) throw new Error('module has_soc not found');
  const body = src.slice(start);
  const end = body.indexOf('\n);');
  const header = body.slice(0, end < 0 ? body.length : end);

  const ports = [];
  const re = /^\s*(input|output|inout)\s+(?:logic|wire|reg)\s*(?:signed\s*)?(\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*([A-Za-z_]\w*)/gm;
  let m;
  while ((m = re.exec(header)) !== null) {
    const [, , , msb, lsb, name] = m;
    if (msb !== undefined) {
      const hi = Number(msb);
      const lo = Number(lsb);
      const step = hi >= lo ? -1 : 1;
      for (let i = hi; step < 0 ? i >= lo : i <= lo; i += step) ports.push(`${name}[${i}]`);
    } else {
      ports.push(name);
    }
  }
  return ports;
}

function main() {
  fs.mkdirSync(OUT, { recursive: true });
  const ports = topPorts();
  if (ports.length === 0) {
    console.error('sdc-lint: no ports parsed from has_soc.sv');
    process.exit(1);
  }
  const portsFile = path.join(OUT, 'has_soc_ports.txt');
  fs.writeFileSync(portsFile, ports.join('\n') + '\n');

  const tclsh = findTclsh();
  if (!tclsh) {
    console.error('sdc-lint: tclsh not found (set TCLSH)');
    process.exit(2);
  }

  const script = path.join(ROOT, 'scripts', 'sta', 'sdc_check.tcl');
  const sdc = path.join(ROOT, 'constraints', 'timing_constraints', 'has_soc.sdc');
  const r = spawnSync(tclsh, [script, sdc, portsFile], { cwd: ROOT, encoding: 'utf8' });
  const text = `${r.stdout || ''}${r.stderr || ''}`;
  fs.writeFileSync(path.join(OUT, 'sdc_lint.log'),
    `ports=${ports.length}\n--- tclsh exit ${r.status} ---\n${text}\n`);

  if (verbose || r.status !== 0) process.stdout.write(text);

  const ok = text.includes('SDC-RESULT=PASS') && r.status === 0;
  const missing = /SDC-MISSING-COUNT (\d+)/.exec(text);
  const errors = /SDC-ERROR-COUNT (\d+)/.exec(text);

  console.log(ok
    ? `sdc-lint: RESULT PASS  ports=${ports.length} clocks=${(/SDC-CLOCKS (.*)/.exec(text) || [, '?'])[1]} (constraint file only — this is NOT a timing result; run scripts/eda/run_sta.js for slack)`
    : `sdc-lint: RESULT FAIL  ports=${ports.length} missing=${missing ? missing[1] : '?'} errors=${errors ? errors[1] : '?'}  see build/sta/sdc_lint.log`);
  process.exit(ok ? 0 : 1);
}

main();
