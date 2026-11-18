'use strict';
/*
 * Home-Automation-SoC — RISC-V toolchain discovery (single source of truth).
 *
 * Every driver resolves the compiler here: build_fw.js, gen_fw_mem.js,
 * run_e2e.js, scripts/verify.js, and build_fw.py (through `--json`).
 * build_fw.bat delegates to build_fw.js, so there is exactly one algorithm.
 *
 * The machine this project targets has xPack GCC under D:\tools but *not* on
 * PATH, so "not on PATH" must not mean "no toolchain".
 *
 * Resolution order, most explicit first (opts override env, env overrides PATH):
 *   1. $RISCV_GCC_PREFIX      exact "<prefix>gcc", no guessing
 *   2. $RISCV_TOOLCHAIN_BIN   exact bin directory; the compiler is addressed by
 *                             absolute path, never through PATH shadowing
 *   3. PATH                   the known RISC-V prefixes
 *   4. Installed toolchains   xpack-riscv-none-elf-gcc-* under the host tool
 *                             root (D:\tools on Windows), newest first
 *
 * Every candidate is validated, not merely found:
 *   * `<gcc> -dumpmachine` must report a riscv32/riscv64 target;
 *   * `<gcc> --version` must run;
 *   * `<gcc> -march=rv32im -mabi=ilp32 -fsyntax-only` must accept the flags the
 *     firmware is actually built with (the core has no C extension);
 *   * `<objcopy> --version` must run, because every build path needs it.
 *
 * An explicit configuration that does not work is an error. It is never
 * silently replaced by another compiler, and two explicit settings that point
 * at different toolchains are reported as a conflict.
 *
 * Usage:
 *   const { findToolchain } = require('./toolchain');
 *   const tc = findToolchain();            // -> { prefix, env, binDir, source,
 *                                          //     gccPath, version, machine }
 *   if (tc.error) { ...exit 2... }         // -> { error: 'why' }
 *
 *   node scripts/fw_build/toolchain.js           human-readable resolution
 *   node scripts/fw_build/toolchain.js --json    machine-readable (for Python)
 *   node scripts/fw_build/toolchain.js --self-check   exit 0/2 only
 *
 * Nothing here installs, downloads or modifies a toolchain.
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const PREFIXES = ['riscv-none-elf-', 'riscv32-unknown-elf-', 'riscv64-unknown-elf-', 'riscv32-elf-'];

// Where the project's tool registry keeps cross toolchains: D:\tools per
// D:\tools\EDA_TOOL_REGISTRY.md (see AGENTS.md). Other hosts use the usual
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

function exeIn(binDir, name) {
  if (!binDir) return name;
  const direct = path.join(binDir, name);
  // Windows will not append PATHEXT to an absolute path handed to CreateProcess.
  if (fs.existsSync(direct)) return direct;
  if (process.platform === 'win32' && fs.existsSync(direct + '.exe')) return direct + '.exe';
  return direct;
}

// Absolute path of an executable on PATH, so a PATH-sourced toolchain is
// reported as the file it actually is instead of a bare command name.
function whichOnPath(name) {
  const dirs = (process.env.PATH || '').split(path.delimiter).filter(Boolean);
  const exts = process.platform === 'win32'
    ? (process.env.PATHEXT || '.EXE;.CMD;.BAT').split(';').filter(Boolean)
    : [''];
  for (const dir of dirs) {
    for (const ext of exts) {
      const p = path.join(dir, name + (process.platform === 'win32' ? ext.toLowerCase() : ''));
      if (fs.existsSync(p)) return p;
    }
  }
  return null;
}

let probeSource = null;
function probeFile() {
  if (!probeSource) {
    probeSource = path.join(os.tmpdir(), `ha-soc-tc-probe-${process.pid}.c`);
    fs.writeFileSync(probeSource, 'int probe;\n');
  }
  return probeSource;
}

function firstLine(text) {
  return (text || '').split(/\r?\n/).map(s => s.trim()).filter(Boolean)[0] || '';
}

// A RISC-V target string is either "riscv32-unknown-elf", "riscv64-..." or
// xPack's "riscv-none-elf". Exported so the negative controls can assert the
// rejection of a non-RISC-V target without a host compiler to point at.
function isRiscvMachine(machine) {
  return /^riscv/i.test((machine || '').trim());
}

/*
 * Validate one candidate. Returns { ok:true, gccPath, version, machine } or
 * { ok:false, reason }. `binDir` may be null, in which case the compiler is
 * looked up on PATH.
 */
function probe(prefix, binDir) {
  const env = envWith(binDir);
  const gccPath = binDir
    ? exeIn(binDir, prefix + 'gcc')
    : (whichOnPath(prefix + 'gcc') || prefix + 'gcc');

  const dm = spawnSync(gccPath, ['-dumpmachine'], { env, encoding: 'utf8' });
  if (dm.error || dm.status !== 0) {
    const why = dm.error ? dm.error.code : `exit ${dm.status}`;
    return { ok: false, reason: `"${gccPath} -dumpmachine" did not run (${why})` };
  }
  const machine = (dm.stdout || '').trim();
  // xPack reports "riscv-none-elf", GNU reports "riscv32-unknown-elf"; both are
  // RISC-V. Anything else is rejected before the flag probe runs.
  if (!isRiscvMachine(machine)) {
    return { ok: false, reason: `"${gccPath}" targets "${machine || 'nothing'}"; not a RISC-V compiler` };
  }

  const ver = spawnSync(gccPath, ['--version'], { env, encoding: 'utf8' });
  if (ver.error || ver.status !== 0) {
    return { ok: false, reason: `"${gccPath} --version" did not run` };
  }

  // The firmware is built with -march=rv32im; a compiler that rejects those
  // flags cannot build this project even if it is a RISC-V compiler.
  const compat = spawnSync(gccPath,
    ['-march=rv32im', '-mabi=ilp32', '-fsyntax-only', probeFile()],
    { env, encoding: 'utf8' });
  if (compat.error || compat.status !== 0) {
    return { ok: false, reason: `"${gccPath}" rejects -march=rv32im -mabi=ilp32` };
  }

  const objcopyPath = binDir
    ? exeIn(binDir, prefix + 'objcopy')
    : (whichOnPath(prefix + 'objcopy') || prefix + 'objcopy');
  const objcopy = spawnSync(objcopyPath, ['--version'], { env, encoding: 'utf8' });
  if (objcopy.error || objcopy.status !== 0) {
    const why = objcopy.error ? objcopy.error.code : `exit ${objcopy.status}`;
    return { ok: false, reason: `"${objcopyPath}" is not usable (${why})` };
  }

  return { ok: true, gccPath, version: firstLine(ver.stdout), machine };
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

function ok(prefix, binDir, source, p) {
  return {
    prefix,
    binDir,
    source,
    gccPath: p.gccPath,
    version: p.version,
    machine: p.machine,
    env: envWith(binDir),
  };
}

/*
 * opts.prefix — exact prefix, same contract as $RISCV_GCC_PREFIX
 * opts.binDir — exact bin directory, same contract as $RISCV_TOOLCHAIN_BIN
 * Explicit options win over the environment; if an environment variable is
 * also set, the option value must be the one that works or the call fails.
 */
function findToolchain(opts = {}) {
  const envPrefix = process.env.RISCV_GCC_PREFIX;
  const envBin = process.env.RISCV_TOOLCHAIN_BIN;
  const wantPrefix = opts.prefix || envPrefix;
  const wantBin = opts.binDir || envBin;

  // 1/2. explicit configuration — must work, or it is an error
  if (wantPrefix && wantBin) {
    const p = probe(wantPrefix, wantBin);
    if (!p.ok) {
      return {
        error: `conflicting configuration: RISCV_GCC_PREFIX="${wantPrefix}" and ` +
               `RISCV_TOOLCHAIN_BIN="${wantBin}" do not agree — ${p.reason}. ` +
               'Unset one, or point both at the same toolchain.',
      };
    }
    return ok(wantPrefix, wantBin, 'RISCV_GCC_PREFIX+RISCV_TOOLCHAIN_BIN', p);
  }
  if (wantPrefix) {
    const p = probe(wantPrefix, null);
    if (!p.ok) {
      return {
        error: `RISCV_GCC_PREFIX="${wantPrefix}" is set but does not provide a usable ` +
               `RISC-V compiler: ${p.reason}. It is not ignored, because building with a ` +
               'different compiler than requested would be a silent configuration change.',
      };
    }
    return ok(wantPrefix, null, 'RISCV_GCC_PREFIX', p);
  }
  if (wantBin) {
    const reasons = [];
    for (const prefix of PREFIXES) {
      const p = probe(prefix, wantBin);
      if (p.ok) return ok(prefix, wantBin, 'RISCV_TOOLCHAIN_BIN', p);
      reasons.push(p.reason);
    }
    return {
      error: `RISCV_TOOLCHAIN_BIN="${wantBin}" contains no usable RISC-V toolchain: ` +
             reasons.join('; '),
    };
  }

  // 3. already on PATH
  const pathReasons = [];
  for (const prefix of PREFIXES) {
    const p = probe(prefix, null);
    if (p.ok) return ok(prefix, null, 'PATH', p);
    pathReasons.push(p.reason);
  }

  // 4. installed under the tool root but not on PATH
  const searched = [];
  const installReasons = [];
  for (const d of installedDirs()) {
    searched.push(d.binDir);
    for (const prefix of PREFIXES) {
      const p = probe(prefix, d.binDir);
      if (p.ok) return ok(prefix, d.binDir, 'installed', p);
      installReasons.push(p.reason);
    }
  }

  const roots = toolRoots().map(r => path.join(r, 'xpack-riscv-none-elf-gcc-*'));
  return {
    error: 'no usable RISC-V toolchain found. Tried PATH (' +
           pathReasons.join('; ') + ')' +
           (searched.length ? `, and ${searched.join(', ')}` : `, and ${roots.join(', ')}`) +
           (installReasons.length ? ` (${installReasons.join('; ')})` : '') +
           '. Set RISCV_TOOLCHAIN_BIN to a bin directory (not to the toolchain root).',
  };
}

function format(tc) {
  if (tc.error) return `BLOCKED: ${tc.error}`;
  return `toolchain: ${tc.gccPath} [${tc.source}]\n` +
         `  version:   ${tc.version}\n` +
         `  target:    ${tc.machine}\n` +
         `  prefix:    ${tc.prefix}\n` +
         `  binDir:    ${tc.binDir || '(PATH)'}\n` +
         '  flags:     -march=rv32im -mabi=ilp32 accepted';
}

module.exports = { findToolchain, format, probe, isRiscvMachine, PREFIXES, envWith };

// ---------------------------------------------------------------- CLI ------
if (require.main === module) {
  const tc = findToolchain();
  const json = process.argv.includes('--json');
  const quiet = process.argv.includes('--self-check');
  if (json) {
    const { env, ...rest } = tc;
    console.log(JSON.stringify({ ok: !tc.error, ...rest }, null, 2));
  } else if (!quiet) {
    console.log(format(tc));
  }
  process.exit(tc.error ? 2 : 0);
}
