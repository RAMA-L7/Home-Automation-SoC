#!/usr/bin/env node
/*
 * Home-Automation-SoC — memory inventory / address-map drift checker (F5, F7)
 *
 * Compares four independent descriptions of the SoC memories and fails on any
 * disagreement:
 *   1. the elaborated design   (build/asic_evidence/memory_audit/memories.il,
 *                               plus the stat JSON from the same Yosys run)
 *   2. the declared inventory  (asic/synthesis/memory_inventory.json)
 *   3. the address map package (rtl/rtl_top/has_addr_map.sv)
 *   4. the interconnect decode (rtl/rtl_top/axi_lite_interconnect.sv)
 *
 * Why: the address map is duplicated as literals in the interconnect, and the
 * memory arrays are sized by RTL parameters. Nothing else ties those three
 * together, so a changed size, a new inferred memory or a "fix" that only edits
 * the inventory would go unnoticed. This checker makes that drift a failure.
 *
 * Exit codes:
 *   0 PASS    — every field agrees and every memory has an ASIC implementation
 *   1 FAIL    — the design, the map, the interconnect and the inventory disagree
 *   2 BLOCKED — all fields agree, but memories are still inferred (no macro)
 * Declared gaps are never reported as PASS, following check_structure.js.
 *
 * Usage:
 *   node scripts/eda/audit_memory.js
 *   node scripts/eda/audit_memory.js --self-test
 *   node scripts/eda/audit_memory.js --inventory <file> --map <file> --interconnect <file>
 *
 * Prerequisite for the default run: `yosys -s asic/synthesis/memory_audit.ys`
 * (writes memories.il and memory_cells.json).
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');

function argValue(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}
const P = {
  il: path.join(ROOT, 'build', 'asic_evidence', 'memory_audit', 'memories.il'),
  stat: path.join(ROOT, 'build', 'asic_evidence', 'memory_audit', 'memory_cells.json'),
  map: path.resolve(ROOT, argValue('--map', 'rtl/rtl_top/has_addr_map.sv')),
  ic: path.resolve(ROOT, argValue('--interconnect', 'rtl/rtl_top/axi_lite_interconnect.sv')),
  inv: path.resolve(ROOT, argValue('--inventory', 'asic/synthesis/memory_inventory.json')),
};
const verbose = process.argv.includes('--verbose');

// ---------------------------------------------------------------- parsers ---
function parseIl(text) {
  const lines = text.split(/\r?\n/);
  const cells = [];
  let mod = null;
  for (let i = 0; i < lines.length; i++) {
    const mm = lines[i].match(/^module \\?(\S+)/);
    if (mm) { mod = mm[1]; continue; }
    if (!/^\s+cell \$mem_v2/.test(lines[i])) continue;
    const c = { module: mod, name: (lines[i].trim().split(/\s+/)[2] || '').replace(/^\\/, '') };
    for (let j = i + 1; j < Math.min(i + 90, lines.length); j++) {
      const s = lines[j].trim();
      if (s.startsWith('parameter ')) {
        const parts = s.split(/\s+/);
        c[parts[1].replace(/^\\/, '')] = parts.slice(2).join(' ');
      } else if (s.startsWith('connect ') || s.startsWith('cell ')) break;
    }
    c.size = parseInt(c.SIZE, 10);
    c.width = parseInt(c.WIDTH, 10);
    c.rdPorts = parseInt(c.RD_PORTS, 10);
    c.wrPorts = parseInt(c.WR_PORTS, 10);
    c.hasInit = typeof c.INIT === 'string' && !/^[0-9]+'x$/.test(c.INIT);
    cells.push(c);
  }
  return cells;
}

function parseStat(text) {
  const j = JSON.parse(text);
  let count = 0;
  const perModule = {};
  for (const [m, v] of Object.entries(j.modules || {})) {
    const n = (v.num_cells_by_type || {})['$mem_v2'] || 0;
    if (n) { perModule[m] = n; count += n; }
  }
  return { count, perModule };
}

function parseAddrMap(text) {
  const regions = {};
  for (const key of ['BOOT_ROM', 'TCM', 'SRAM', 'QSPI_FLASH', 'APB', 'INTC']) {
    const b = text.match(new RegExp(`ADDR_${key}_BASE\\s*=\\s*32'h([0-9A-Fa-f_]+)`));
    const s = text.match(new RegExp(`ADDR_${key}_SIZE\\s*=\\s*32'h([0-9A-Fa-f_]+)`));
    if (b && s) {
      regions[key] = {
        base: parseInt(b[1].replace(/_/g, ''), 16),
        size: parseInt(s[1].replace(/_/g, ''), 16),
      };
    }
  }
  return regions;
}

function parseInterconnect(text) {
  const ranges = [];
  const re = /a\s*>=\s*32'h([0-9A-Fa-f_]+)\s*&&\s*a\s*<\s*32'h([0-9A-Fa-f_]+)/g;
  let m;
  while ((m = re.exec(text))) {
    ranges.push({ start: parseInt(m[1].replace(/_/g, ''), 16), end: parseInt(m[2].replace(/_/g, ''), 16) });
  }
  return ranges;
}

// -------------------------------------------------------------- validation --
function validate({ il, stat, map, ic, inv }) {
  const errors = [];
  const notes = [];
  const bySize = new Map();
  for (const c of il) {
    const k = `${c.size}x${c.width}`;
    bySize.set(k, (bySize.get(k) || 0) + 1);
  }

  // 1. the two Yosys outputs must agree with each other
  if (stat.count !== il.length) {
    errors.push(`stat reports ${stat.count} $mem_v2 cells, memories.il contains ${il.length}`);
  }

  // 2. every inferred memory must be declared, with matching geometry
  const declared = new Map();
  for (const m of inv.memories) {
    const k = `${m.depth_words}x${m.width_bits}`;
    declared.set(k, (declared.get(k) || 0) + 1);
  }
  for (const [k, n] of bySize) {
    const d = declared.get(k) || 0;
    if (d !== n) errors.push(`design has ${n} memor${n === 1 ? 'y' : 'ies'} of ${k}, inventory declares ${d}`);
  }
  for (const [k, n] of declared) {
    const a = bySize.get(k) || 0;
    if (a !== n) errors.push(`inventory declares ${n} memor${n === 1 ? 'y' : 'ies'} of ${k}, design has ${a}`);
  }

  // 3. address map vs interconnect decode
  const regionKeys = { 'MEM-ROM': 'BOOT_ROM', 'MEM-TCM': 'TCM', 'MEM-SRAM': 'SRAM' };
  for (const m of inv.memories) {
    const key = regionKeys[m.id];
    if (!key) continue;
    const region = map[key];
    if (!region) { errors.push(`address map has no ADDR_${key}_BASE/SIZE`); continue; }
    if (region.size !== m.decoded_bytes) {
      errors.push(`${m.id}: inventory decoded_bytes=${m.decoded_bytes}, address map ${key} size=${region.size}`);
    }
    const matches = ic.filter(r => r.start === region.base);
    if (matches.length !== 1) {
      errors.push(`${m.id}: interconnect has ${matches.length} decode ranges starting at 0x${region.base.toString(16)}`);
      continue;
    }
    const icSize = matches[0].end - matches[0].start;
    if (icSize !== region.size) {
      errors.push(`${m.id}: interconnect aperture ${icSize} B != address map ${region.size} B (${key})`);
    }
  }

  // 4. declared reconciliation must equal the computed one
  for (const m of inv.memories) {
    if (!m.decoded_bytes) continue;
    const computed = m.capacity_bytes === m.decoded_bytes ? 'match' : 'mismatch';
    if (m.reconciliation.array_vs_decoded !== computed) {
      errors.push(`${m.id}: array is ${m.capacity_bytes} B and the decoded aperture is ` +
        `${m.decoded_bytes} B (${computed}), but the inventory declares ` +
        `"${m.reconciliation.array_vs_decoded}"`);
    }
    if (m.reconciliation.declared_status === 'confirmed_mismatch' && computed === 'match') {
      errors.push(`${m.id}: inventory still records a confirmed mismatch but the sizes now match`);
    }
  }

  // 5. power-up contents must match what the elaboration shows
  const initById = { 'MEM-ROM': true, 'MEM-TCM': false, 'MEM-SRAM': false, 'MEM-DECODE-LUT': true };
  for (const m of inv.memories) {
    const cell = il.find(c => c.size === m.depth_words && c.width === m.width_bits);
    if (!cell) { errors.push(`${m.id}: no elaborated memory of ${m.depth_words}x${m.width_bits}`); continue; }
    if (initById[m.id] !== cell.hasInit) {
      errors.push(`${m.id}: elaboration INIT ${cell.hasInit ? 'constant' : 'undefined'}, ` +
        `inventory expects ${initById[m.id] ? 'constant' : 'undefined'}`);
    }
    if (cell.rdPorts !== m.read_ports) {
      errors.push(`${m.id}: elaborated RD_PORTS=${cell.rdPorts}, inventory read_ports=${m.read_ports}`);
    }
    if (cell.wrPorts !== (m.write_ports === 0 ? 0 : (m.write_lanes || 1))) {
      errors.push(`${m.id}: elaborated WR_PORTS=${cell.wrPorts}, inventory declares ` +
        `${m.write_ports} port(s) x ${m.write_lanes || 1} lane(s)`);
    }
  }

  // 6. totals
  const arrayBytes = inv.memories.reduce((s, m) => s + m.capacity_bytes, 0);
  const decodedBytes = inv.memories.reduce((s, m) => s + (m.decoded_bytes || 0), 0);
  const regBytes = (inv.register_storage || []).reduce((s, m) => s + m.capacity_bytes, 0);
  if (arrayBytes !== inv.implemented_totals.array_bytes) {
    errors.push(`implemented_totals.array_bytes=${inv.implemented_totals.array_bytes}, entries sum to ${arrayBytes}`);
  }
  if (regBytes !== inv.implemented_totals.register_storage_bytes) {
    errors.push(`implemented_totals.register_storage_bytes=${inv.implemented_totals.register_storage_bytes}, ` +
      `entries sum to ${regBytes}`);
  }
  if (decodedBytes !== inv.decoded_totals.addressable_bytes) {
    errors.push(`decoded_totals.addressable_bytes=${inv.decoded_totals.addressable_bytes}, entries sum to ${decodedBytes}`);
  }
  notes.push(`inferred arrays: ${il.length} cells, ${arrayBytes} B implemented, ${decodedBytes} B addressable`);
  notes.push(`register storage: ${inv.register_storage.length} structures, ${regBytes} B`);

  // 7. ASIC implementation blockers (declared, never silently PASS)
  const blockers = [];
  for (const m of inv.memories) {
    if (m.asic_status !== 'synthesizable') {
      blockers.push(`${m.id} (${m.kind}): ${m.capacity_bytes} B, asic_status="${m.asic_status}"`);
    }
  }
  for (const m of inv.memories) {
    if (m.reconciliation.array_vs_decoded === 'mismatch') {
      blockers.push(`${m.id}: array ${m.capacity_bytes} B vs decoded ${m.decoded_bytes} B must be reconciled`);
    }
  }

  return { errors, blockers, notes };
}

// -------------------------------------------------------------------- main --

// The elaborated artifacts live under build/, which a fresh checkout does not
// have. A clean tree therefore made `--self-test` report BLOCKED for a reason
// that had nothing to do with the checker, and made the design stage fail on a
// directory that did not exist. Elaborate on demand rather than depending on a
// leftover run, and create the output directory the .ys writes into.
function ensureElaboration(force) {
  if (!force && fs.existsSync(P.il) && fs.existsSync(P.stat)) return { status: 0, note: 'artifacts already present' };
  fs.mkdirSync(path.dirname(P.il), { recursive: true });
  const r = require('child_process').spawnSync(
    'yosys', ['-s', 'asic/synthesis/memory_audit.ys'],
    { cwd: ROOT, encoding: 'utf8', timeout: 900000, maxBuffer: 256 * 1024 * 1024 });
  const ok = r.status === 0 && fs.existsSync(P.il) && fs.existsSync(P.stat);
  return {
    status: ok ? 0 : (r.error || r.status === null ? 127 : r.status || 1),
    note: ok ? 'elaborated build/asic_evidence/memory_audit/ with yosys' :
      (r.error ? `yosys could not run: ${r.error.message}` :
        (r.stderr || r.stdout || '').trim().split('\n').slice(-3).join(' / ')),
  };
}

function load() {
  for (const f of [P.il, P.stat, P.map, P.ic, P.inv]) {
    if (!fs.existsSync(f)) {
      console.log(`FAIL  input missing: ${path.relative(ROOT, f)}`);
      if (f === P.il || f === P.stat) {
        console.log('      run: yosys -s asic/synthesis/memory_audit.ys');
      }
      console.log('MEMORY_AUDIT: BLOCKED');
      process.exit(2);
    }
  }
  return {
    il: parseIl(fs.readFileSync(P.il, 'utf8')),
    stat: parseStat(fs.readFileSync(P.stat, 'utf8')),
    map: parseAddrMap(fs.readFileSync(P.map, 'utf8')),
    ic: parseInterconnect(fs.readFileSync(P.ic, 'utf8')),
    inv: JSON.parse(fs.readFileSync(P.inv, 'utf8')),
  };
}

function report(title, r) {
  const ok = r.errors.length === 0;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${title}`);
  for (const e of r.errors) console.log(`        ${e}`);
  if (verbose) for (const n of r.notes) console.log(`        note: ${n}`);
  if (!ok) return 1;
  if (r.blockers.length) {
    console.log(`BLOCKED  ${r.blockers.length} declared ASIC gap(s):`);
    for (const b of r.blockers) console.log(`        ${b}`);
    return 2;
  }
  return 0;
}

// `--elaborate` is the documented way to run the audit from a clean checkout:
// this Yosys build has no `file mkdir`, so the .ys cannot create its own output
// directory and fails with "Can't create file" when build/ does not exist.
if (process.argv.includes('--elaborate')) {
  const el = ensureElaboration(true);
  console.log(`$ yosys -s asic/synthesis/memory_audit.ys -> ${el.note}`);
  if (el.status !== 0) {
    console.log(`FAIL  elaboration did not produce the audit inputs: ${el.note}`);
    console.log('MEMORY_AUDIT: BLOCKED');
    process.exit(2);
  }
}

if (process.argv.includes('--self-test')) {
  const el = ensureElaboration(false);
  if (el.status !== 0) {
    console.log(`FAIL  could not elaborate the fixture baseline: ${el.note}`);
    console.log('MEMORY_AUDIT: BLOCKED');
    process.exit(2);
  }
  console.log(`      fixture baseline: ${el.note}`);
  const base = load();
  const cases = [];
  const clone = o => JSON.parse(JSON.stringify(o));

  cases.push(['current design and inventory are consistent', base, 2]);
  const dropped = clone(base);
  dropped.inv.memories = dropped.inv.memories.filter(m => m.id !== 'MEM-SRAM');
  cases.push(['missing inventory entry for an inferred memory', dropped, 1]);

  // Fixtures are derived from the loaded baseline, never hardcoded: a size
  // reconciliation changes the numbers and a hardcoded mutation would silently
  // become a no-op (or throw) instead of a control.
  const sramEntry = () => base.inv.memories.find(m => m.id === 'MEM-SRAM');
  const romEntry = () => base.inv.memories.find(m => m.id === 'MEM-ROM');
  const resized = clone(base);
  resized.inv.memories.find(m => m.id === 'MEM-SRAM').depth_words = sramEntry().depth_words / 2;
  resized.inv.memories.find(m => m.id === 'MEM-SRAM').width_bits = sramEntry().width_bits;
  cases.push(['inventory depth edited away from the design', resized, 1]);

  const claimed = clone(base);
  claimed.inv.memories.find(m => m.id === 'MEM-ROM').decoded_bytes = romEntry().capacity_bytes * 2;
  cases.push(['inventory claims a decoded aperture larger than the array', claimed, 1]);

  const mapChanged = clone(base);
  mapChanged.map.BOOT_ROM.size = 0x8000;
  cases.push(['address map ROM size changed', mapChanged, 1]);

  const icChanged = clone(base);
  icChanged.ic = icChanged.ic.map(r => (r.start === 0 && r.end === 0x4000 ? { start: 0, end: 0x8000 } : r));
  cases.push(['interconnect ROM aperture changed', icChanged, 1]);

  const initChanged = clone(base);
  initChanged.il.find(c => c.size === romEntry().depth_words &&
                           c.width === romEntry().width_bits).hasInit = false;
  cases.push(['ROM no longer has initialization data', initChanged, 1]);

  let bad = 0;
  for (const [name, inputs, expect] of cases) {
    const r = validate(inputs);
    const got = r.errors.length ? 1 : (r.blockers.length ? 2 : 0);
    const ok = got === expect;
    if (!ok) bad++;
    console.log(`${ok ? 'PASS' : 'FAIL'}  control: ${name} -> exit ${got}${ok ? '' : `, expected ${expect}`}`);
    if (!ok) for (const e of r.errors) console.log(`        ${e}`);
  }
  console.log('');
  console.log(`MEMORY_AUDIT: SELF-TEST ${bad === 0 ? 'PASS' : 'FAIL'} (${cases.length - bad}/${cases.length} controls)`);
  process.exit(bad === 0 ? 0 : 1);
}

const code = report('memory inventory, address map, interconnect and elaboration agree', validate(load()));
console.log('');
console.log(`MEMORY_AUDIT: ${code === 0 ? 'PASS' : code === 2 ? 'BLOCKED' : 'FAIL'}`);
process.exit(code);
