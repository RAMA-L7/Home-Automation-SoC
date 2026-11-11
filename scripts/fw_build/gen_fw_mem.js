#!/usr/bin/env node
/*
 * Home-Automation-SoC — split a firmware ELF into per-memory word images.
 *
 * The simulation models the boot ROM and TCM as $readmemh arrays, so the
 * linked firmware has to be cut into one word file per memory region:
 *   build/fw/rom.hex   .text.reset  -> boot ROM  at 0x0000_0000
 *   build/fw/tcm.hex   .text        -> TCM        at 0x0001_0000
 *
 * Usage:
 *   node scripts/fw_build/gen_fw_mem.js <firmware.elf> [toolchain-bin-dir]
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const elf = process.argv[2] || path.join(ROOT, 'build', 'fw', 'firmware.elf');
const binDir = process.argv[3] || process.env.RISCV_TOOLCHAIN_BIN || '';

const PREFIXES = ['riscv-none-elf-', 'riscv32-unknown-elf-', 'riscv64-unknown-elf-', 'riscv32-elf-'];

function env() {
  const e = { ...process.env };
  if (binDir) e.PATH = binDir + path.delimiter + (e.PATH || '');
  return e;
}
function pick(tool) {
  for (const p of PREFIXES) {
    const r = spawnSync(p + tool, ['--version'], { env: env(), encoding: 'utf8' });
    if (r.status === 0) return p + tool;
  }
  return null;
}

const objcopy = pick('objcopy');
if (!objcopy) {
  console.error('BLOCKED: no RISC-V objcopy found (set RISCV_TOOLCHAIN_BIN)');
  process.exit(2);
}
if (!fs.existsSync(elf)) {
  console.error('missing ' + elf + ' (build the firmware first)');
  process.exit(1);
}

const OUT = path.dirname(elf);

function sectionWords(section) {
  const bin = path.join(OUT, section.replace(/[^A-Za-z0-9]/g, '_') + '.bin');
  const r = spawnSync(objcopy, ['-O', 'binary', '--only-section=' + section, elf, bin],
                      { env: env(), encoding: 'utf8' });
  if (r.status !== 0) {
    console.error(`objcopy --only-section=${section} failed: ${(r.stderr || '').trim()}`);
    process.exit(1);
  }
  const buf = fs.readFileSync(bin);
  const words = [];
  for (let i = 0; i < buf.length; i += 4) {
    const w = (buf[i] | (buf[i + 1] << 8) | (buf[i + 2] << 16) | (buf[i + 3] << 24)) >>> 0;
    words.push(w.toString(16).padStart(8, '0'));
  }
  fs.unlinkSync(bin);
  return words;
}

for (const [section, out] of [['.text.reset', 'rom.hex'], ['.text', 'tcm.hex']]) {
  const words = sectionWords(section);
  fs.writeFileSync(path.join(OUT, out), words.join('\n') + '\n');
  console.log(`${out}: ${words.length} words from ${section}`);
}
