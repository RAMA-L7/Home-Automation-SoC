#!/usr/bin/env node
/*
 * Home-Automation-SoC — firmware build driver (Node)
 *
 * Same sources, flags and linker script as build_fw.py, but runnable in
 * environments where `python` is unavailable (it is a Windows Store stub on
 * the machine this was developed on).  Kept as a second driver rather than a
 * replacement so either environment works.
 *
 * Toolchain discovery:
 *   1. $RISCV_GCC_PREFIX + gcc in PATH
 *   2. $RISCV_TOOLCHAIN_BIN (a directory to prepend to PATH)
 *   3. riscv-none-elf-, riscv32-unknown-elf-, riscv64-unknown-elf-, riscv32-elf-
 *      looked up in PATH
 *
 * Usage:
 *   node scripts/fw_build/build_fw.js [--verbose]
 * Output: build/fw/firmware.elf, .bin, .srec, plus readelf/size evidence.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const FW = path.join(ROOT, 'firmware', 'bare_metal');
const OUT = path.join(ROOT, 'build', 'fw');
const verbose = process.argv.includes('--verbose');

const CFLAGS = [
  // rv32im (NOT rv32imc): the core does not implement the compressed
  // extension, so rv32imc code would trap on its first 16-bit instruction.
  '-march=rv32im', '-mabi=ilp32',
  '-nostdlib', '-nostartfiles', '-ffreestanding',
  '-Wall', '-Wextra', '-O2', '-g',
  `-T${path.join(FW, 'linker.ld')}`,
];

const SRC = ['startup.S', 'main.c', 'drivers.c', 'boot.c', 'host_comm.c', 'ota.c'];
const PREFIXES = ['riscv-none-elf-', 'riscv32-unknown-elf-', 'riscv64-unknown-elf-', 'riscv32-elf-'];

function envWith(prefix) {
  const env = { ...process.env };
  const bin = process.env.RISCV_TOOLCHAIN_BIN;
  if (bin) env.PATH = bin + path.delimiter + (env.PATH || env.Path || '');
  return env;
}

function which(cmd, env) {
  const r = spawnSync(cmd, ['--version'], { env, encoding: 'utf8' });
  return r.status === 0 ? cmd : null;
}

function findToolchain() {
  const env = envWith();
  if (process.env.RISCV_GCC_PREFIX) {
    if (which(process.env.RISCV_GCC_PREFIX + 'gcc', env)) return { prefix: process.env.RISCV_GCC_PREFIX, env };
  }
  for (const p of PREFIXES) {
    if (which(p + 'gcc', env)) return { prefix: p, env };
  }
  return null;
}

function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { encoding: 'utf8', ...opts });
  const text = (r.stdout || '') + (r.stderr || '');
  if (verbose || r.status !== 0) process.stdout.write(text);
  return { ok: r.status === 0, text, status: r.status };
}

const tc = findToolchain();
if (!tc) {
  console.error('BLOCKED: no RISC-V toolchain found.');
  console.error('  Set RISCV_GCC_PREFIX (e.g. riscv-none-elf-) or RISCV_TOOLCHAIN_BIN.');
  process.exit(2);
}
const { prefix, env } = tc;
console.log(`toolchain: ${prefix}gcc`);
run(`${prefix}gcc`, ['--version'], { env });
for (const s of ['startup.S', 'main.c', 'drivers.c', 'boot.c', 'host_comm.c', 'ota.c']) {
  if (!fs.existsSync(path.join(FW, s))) { console.error(`missing source ${s}`); process.exit(1); }
}

fs.mkdirSync(OUT, { recursive: true });
const elf = path.join(OUT, 'firmware.elf');
const args = [...CFLAGS, '-o', elf, ...SRC.map(s => path.join(FW, s))];
console.log('compiling ' + SRC.join(' '));
const cc = run(`${prefix}gcc`, args, { env, cwd: FW });
if (!cc.ok) { console.error('BUILD FAILED'); process.exit(1); }

for (const [name, a] of [
  ['readelf -h', ['-h', elf]],
  ['readelf -S', ['-S', elf]],
  ['readelf -l', ['-l', elf]],
  ['size', [elf]],
]) {
  const r = spawnSync(`${prefix}${name.split(' ')[0]}`, name === 'size' ? a : a, { env, encoding: 'utf8' });
  console.log(`\n=== ${name} ===`);
  console.log((r.stdout || '') + (r.stderr || ''));
}

for (const [fmt, ext] of [['binary', 'bin'], ['srec', 'srec']]) {
  const r = run(`${prefix}objcopy`, ['-O', fmt, elf, path.join(OUT, `firmware.${ext}`)], { env });
  if (!r.ok) { console.error(`objcopy ${fmt} failed`); process.exit(1); }
}

const st = fs.statSync(elf);
console.log(`\nOK: ${path.relative(ROOT, elf)} (${st.size} bytes), firmware.bin, firmware.srec`);
