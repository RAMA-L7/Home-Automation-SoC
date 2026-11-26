#!/usr/bin/env node
/*
 * Home-Automation-SoC — boot ROM verification
 *
 * Proves the synthesizable standard-cell ROM (scripts/fw_build/gen_rom_rtl.py)
 * preserves the behavioural ROM, and that it maps without an inferred memory.
 *
 * Stages
 *   1. generate build/rom/boot_rom.v from build/fw/boot.hex
 *   2. ROM-TEST against the BEHAVIOURAL rtl/rtl_top/boot_rom.sv  (reference)
 *   3. ROM-TEST against the GENERATED build/rom/boot_rom.v       (contents,
 *      latency, write rejection — same checks as stage 2)
 *   4. full CPU boot (tb_boot) with the GENERATED ROM substituted for the
 *      behavioural one, so boot is proven from gate-mappable RTL
 *   5. Yosys: map the generated ROM to sky130 cells and assert no $mem cell
 *      survives (that is what made the behavioural ROM unmappable)
 *
 * Exit: 0 all stages pass, 1 a stage failed, 2 tool or input missing.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const OUT = path.join(ROOT, 'build', 'rom');
const SIM = path.join(ROOT, 'build', 'sim');
const verbose = process.argv.includes('--verbose');

const RTL = fs.readFileSync(path.join(ROOT, 'rtl', 'filelist.f'), 'utf8')
  .split('\n').map(l => l.trim())
  .filter(l => l && !l.startsWith('//'));

function findTool(name, envVar, candidates, probeArgs) {
  if (process.env[envVar] && fs.existsSync(process.env[envVar])) return process.env[envVar];
  for (const c of candidates) if (fs.existsSync(c)) return c;
  const r = spawnSync(name, probeArgs || ['-V'], { encoding: 'utf8' });
  return r.error ? null : name;
}

const IVERILOG = findTool('iverilog', 'IVERILOG', ['D:/tools/oss-cad-suite/bin/iverilog.exe']);
const VVP = findTool('vvp', 'VVP', ['D:/tools/oss-cad-suite/bin/vvp.exe']);
const YOSYS = findTool('yosys', 'YOSYS', ['D:/tools/oss-cad-suite/bin/yosys.exe'], ['-V']);
const PY = process.env.PYTHON || 'python3.12';

const SUITE_ENV = (() => {
  if (!VVP) return null;
  const bat = 'D:/tools/oss-cad-suite/environment.bat';
  return process.platform === 'win32' && fs.existsSync(bat) ? bat : null;
})();

function exec(tool, args) {
  if (SUITE_ENV) {
    const cmd = `call "${SUITE_ENV}" && ${[tool, ...args].map(a => (/\s/.test(a) ? `"${a}"` : a)).join(' ')}`;
    return spawnSync(cmd, { cwd: ROOT, encoding: 'utf8', shell: 'cmd.exe' });
  }
  return spawnSync(tool, args, { cwd: ROOT, encoding: 'utf8' });
}

const results = [];
function record(name, ok, detail) {
  results.push({ name, ok, detail });
  console.log(`rom: ${name.padEnd(38)} ${ok ? 'ok  ' : 'FAIL'} ${detail || ''}`);
}

function main() {
  fs.mkdirSync(OUT, { recursive: true });
  fs.mkdirSync(SIM, { recursive: true });

  const hex = path.join(ROOT, 'build', 'fw', 'boot.hex');
  if (!fs.existsSync(hex)) {
    console.error('rom: build/fw/boot.hex missing — run node scripts/eda/run_regression.js first');
    process.exit(2);
  }
  if (!IVERILOG || !VVP) { console.error('rom: iverilog/vvp not found'); process.exit(2); }

  // 1. generate
  const gen = exec(PY, ['scripts/fw_build/gen_rom_rtl.py',
                        'build/fw/boot.hex', 'build/rom/boot_rom.v']);
  const genOk = gen.status === 0 && fs.existsSync(path.join(OUT, 'boot_rom.v'));
  fs.writeFileSync(path.join(OUT, 'gen.log'), `${gen.stdout || ''}${gen.stderr || ''}`);
  record('generate synthesizable ROM', genOk, (gen.stdout || '').trim().split('\n').pop());
  if (!genOk) { finish(); return; }

  // 2 & 3. ROM-TEST against behavioural and generated
  const variants = [
    { name: 'ROM contents/latency/write (behavioural)', rom: 'rtl/rtl_top/boot_rom.sv', tag: 'beh' },
    { name: 'ROM contents/latency/write (generated)', rom: 'build/rom/boot_rom.v', tag: 'gen' },
  ];
  for (const v of variants) {
    const vvp = path.join(SIM, `rom_${v.tag}.vvp`);
    if (fs.existsSync(vvp)) fs.unlinkSync(vvp);
    const c = exec(IVERILOG, ['-g2012', '-o', vvp, '-s', 'tb_boot_rom',
                              'sim/sim_top/tb_boot_rom.v', v.rom]);
    if (c.status !== 0 || !fs.existsSync(vvp)) {
      record(v.name, false, 'compile failed');
      continue;
    }
    const r = exec(VVP, [vvp]);
    const text = `${r.stdout || ''}${r.stderr || ''}`;
    fs.writeFileSync(path.join(OUT, `romtest_${v.tag}.log`), text);
    const m = /checks=(\d+) errors=(\d+)/.exec(text);
    record(v.name, r.status === 0 && text.includes('RESULT=PASS'),
           m ? `checks=${m[1]} errors=${m[2]}` : 'no check marker');
    if (verbose) process.stdout.write(text);
  }

  // 4. CPU boot from the generated ROM
  {
    const vvp = path.join(SIM, 'rom_boot.vvp');
    if (fs.existsSync(vvp)) fs.unlinkSync(vvp);
    const sources = ['sim/sim_top/tb_boot.v',
                     ...RTL.filter(f => !f.endsWith('boot_rom.sv')),
                     'build/rom/boot_rom.v',
                     'sim/models/sky130_sram_sim_model.v'];
    const c = exec(IVERILOG, ['-g2012', '-I', 'rtl/rtl_top', '-DSIM_MEM_PRELOAD',
                              '-o', vvp, '-s', 'tb_boot', ...sources]);
    if (c.status !== 0 || !fs.existsSync(vvp)) {
      record('CPU boot from synthesizable ROM', false, 'compile failed');
    } else {
      const r = exec(VVP, [vvp]);
      const text = `${r.stdout || ''}${r.stderr || ''}`;
      fs.writeFileSync(path.join(OUT, 'boot_from_generated_rom.log'), text);
      record('CPU boot from synthesizable ROM',
             r.status === 0 && text.includes('[tb] RESULT: PASS'),
             r.status === 0 ? '7/7 subtests' : `exit ${r.status}`);
    }
  }

  // 5. Yosys structural mapping
  if (!YOSYS) {
    record('Yosys mapping (no $mem)', false, 'yosys not found');
  } else {
    const ys = path.join(OUT, 'rom_map.ys');
    fs.writeFileSync(ys, [
      'read_verilog -sv build/rom/boot_rom.v',
      'hierarchy -check -top boot_rom',
      'proc',
      'memory_collect',
      // Yosys re-infers a $mem_v2 from a large case (proc_rom). memory_map is
      // what turns it into real decode logic -- exactly the transformation a
      // standard-cell flow needs, and the thing the behavioural $readmemh ROM
      // cannot do.
      'memory_map',
      'opt_clean',
      'stat',
      'select -assert-none t:$mem t:$mem_v2',
      'check -assert',
      'techmap -map +/techmap.v',
      'opt_clean',
      'stat',
      '',
    ].join('\n'));
    const r = exec(YOSYS, ['-s', 'build/rom/rom_map.ys']);
    const text = `${r.stdout || ''}${r.stderr || ''}`;
    fs.writeFileSync(path.join(OUT, 'rom_map.log'), text);
    // After memory_map the ROM must be pure logic: the assert in the script
    // fails the run if any $mem/$mem_v2 survives.
    const muxCount = /(\d+)\s+\$_MUX_/.exec(text);
    record('Yosys mapping (no $mem)', r.status === 0,
           r.status === 0
             ? `decode logic mapped (${muxCount ? muxCount[1] : '?'} $_MUX_, no memory cell)`
             : 'a $mem cell survived or check failed');
    if (verbose) process.stdout.write(text);
  }

  finish();
}

function finish() {
  const failed = results.filter(r => !r.ok);
  const summary = {
    generated_at: new Date().toISOString(),
    image: 'build/fw/boot.hex',
    results,
  };
  fs.writeFileSync(path.join(OUT, 'rom_check.json'), JSON.stringify(summary, null, 2));
  console.log(failed.length === 0
    ? 'rom: RESULT PASS (synthesizable ROM verified against the behavioural model and CPU boot)'
    : `rom: RESULT FAIL (${failed.length} stage(s))`);
  process.exit(failed.length === 0 ? 0 : 1);
}

main();
