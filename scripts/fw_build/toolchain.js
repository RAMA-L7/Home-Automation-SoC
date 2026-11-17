'use strict';
/*
 * Home-Automation-SoC — RISC-V toolchain discovery.
 *
 * Shared by build_fw.js and gen_fw_mem.js so both drivers resolve the same
 * compiler, in the same order.  The machine this project targets has xPack
 * GCC installed under D:\tools but *not* on PATH, so "not on PATH" must not
 * mean "no toolchain".
 *
 * Resolution order, most explicit first:
 *   1. $RISCV_GCC_PREFIX     — an exact "<prefix>gcc" contract, no guessing
 *   2. $RISCV_TOOLCHAIN_BIN  — an exact bin directory, prepended to PATH
 *   3. PATH                  — the known RISC-V prefixes
 *   4. Installed toolchains  — xpack-riscv-none-elf-gcc-* under the host tool
 *                              root (D:\tools on Windows), newest first
 *
 * An explicit override that does not work is reported as an error rather than
 * ignored: silently building with a different compiler than the caller asked
 * for would turn a configuration mistake into a green build.  Nothing here
 * installs, downloads or modifies a toolchain; it only probes what exists.
 *
 * Usage:
 *   const { findToolchain } = require('./toolchain');
 *   const tc = findToolchain();            // -> { prefix, env, binDir, source }
 *   if (tc.error) { ...exit 2... }         // -> { error: 'why' }
 *   // tc.binDir is null when the toolchain was already on PATH.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PREFIXES = ['riscv-none-elf-', 'riscv32-unknown-elf-', 'riscv64-unknown-elf-', 'riscv32-elf-'];

// Where the project's tool registry keeps cross toolchains: D:\tools per
// D:\tools\EDA_TOOL_REGISTRY.md (see AGENTS.md).  Other hosts use the usual
// install roots, so the same driver still works elsewhere.
function toolRoots() {
  if (process.platform === 'win32') return ['D:\\tools', 'C:\\tools'];
  return ['/opt', '/usr/local', path.join(process.env.HOME || '/root', '.local')];
}

// Prepend a directory to whichever spelling of PATH the environment uses, so
// the child never sees both "Path" and "PATH".
function envWith(binDir) {
  const env = { ...process.env };
  if (!binDir) return env;
  const key = Object.keys(env).find(k => k.toUpperCase() === 'PATH') || 'PATH';
  env[key] = binDir + path.delimiter + (env[key] || '');
  return env;
}

function gccWorks(prefix, binDir) {
  const r = spawnSync(prefix + 'gcc', ['--version'], { env: envWith(binDir), encoding: 'utf8' });
  return r.status === 0;
}

function versionOf(name) {
  return (name.match(/\d+/g) || []).map(Number);
}

function newerFirst(a, b) {
  const va = versionOf(a), vb = versionOf(b);
  for (let i = 0; i < Math.max(va.length, vb.length); i++) {
    const d = (vb[i] || 0) - (va[i] || 0);
    if (d) return d;
  }
  return a < b ? 1 : -1;   // deterministic tie-break, e.g. ...-2 before ...-1
}

// Installed xPack GCC trees under the host tool root, newest version first.
function installedDirs() {
  const found = [];
  for (const root of toolRoots()) {
    let names;
    try { names = fs.readdirSync(root); } catch { continue; }
    for (const name of names) {
      if (!/^xpack-riscv-none-elf-gcc-\d/.test(name)) continue;
      const binDir = path.join(root, name, 'bin');
      if (fs.existsSync(binDir)) found.push({ name, binDir });
    }
  }
  return found.sort((a, b) => newerFirst(a.name, b.name));
}

function ok(prefix, binDir, source) {
  return { prefix, env: envWith(binDir), binDir, source };
}

/*
 * opts.binDir — an explicit bin directory supplied by the caller (argv).  It is
 * treated like RISCV_TOOLCHAIN_BIN: it must work, or it is an error.
 */
function findToolchain(opts = {}) {
  const explicitDir = opts.binDir;

  // 1. explicit prefix, optionally against the explicit bin directory
  const wantPrefix = process.env.RISCV_GCC_PREFIX;
  if (wantPrefix) {
    if (gccWorks(wantPrefix, explicitDir || process.env.RISCV_TOOLCHAIN_BIN)) {
      return ok(wantPrefix, explicitDir || process.env.RISCV_TOOLCHAIN_BIN, 'RISCV_GCC_PREFIX');
    }
    return { error: `RISCV_GCC_PREFIX="${wantPrefix}" is set but "${wantPrefix}gcc --version" did not run` +
                    (explicitDir || process.env.RISCV_TOOLCHAIN_BIN
                      ? ` (looked in ${explicitDir || process.env.RISCV_TOOLCHAIN_BIN})` : ' (looked on PATH)') };
  }

  // 2. explicit bin directory
  const wantBin = explicitDir || process.env.RISCV_TOOLCHAIN_BIN;
  if (wantBin) {
    for (const p of PREFIXES) if (gccWorks(p, wantBin)) return ok(p, wantBin, 'RISCV_TOOLCHAIN_BIN');
    return { error: `"${wantBin}" contains no working RISC-V gcc ` +
                    `(tried ${PREFIXES.map(p => p + 'gcc').join(', ')})` };
  }

  // 3. already on PATH
  for (const p of PREFIXES) if (gccWorks(p, null)) return ok(p, null, 'PATH');

  // 4. installed under the tool root but not on PATH
  const searched = [];
  for (const d of installedDirs()) {
    searched.push(d.binDir);
    for (const p of PREFIXES) if (gccWorks(p, d.binDir)) return ok(p, d.binDir, 'installed');
  }

  const roots = toolRoots().map(r => path.join(r, 'xpack-riscv-none-elf-gcc-*'));
  return { error: 'no RISC-V toolchain found: tried PATH' +
                  `, ${PREFIXES.map(p => p + 'gcc').join(', ')}` +
                  (searched.length ? `, and ${searched.join(', ')}` : ` and ${roots.join(', ')}`) };
}

module.exports = { findToolchain, PREFIXES, envWith };
