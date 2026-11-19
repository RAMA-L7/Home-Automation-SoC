#!/usr/bin/env node
/*
 * Home-Automation-SoC — publication completeness check (task A)
 *
 * Verifies that every input the supported commands, verification entry points,
 * research reports and evidence manifests reference is present in the GIT TREE,
 * not merely on this disk.
 *
 * Why this exists: commit 418688b referenced research/**, asic/synthesis/**,
 * scripts/eda/check_structure.js, scripts/eda/audit_memory.js,
 * asic/synthesis/fullsoc_map.ys and asic/synthesis/memory_inventory.json, and
 * none of them were tracked. Every claim in that commit was unreproducible from
 * the published source, while a local run looked perfectly fine. A disk-based
 * check cannot detect that; `git ls-files` can.
 *
 * What is checked
 *   1. manifest.exact  — each path must be tracked.
 *   2. manifest.trees  — every on-disk file under the tree that Git does not
 *                        ignore must be tracked. Untracked-but-present is a
 *                        FAILURE, which is the whole point.
 *   3. deleted         — a tracked file that is missing from the working tree
 *                        is a failure too (the commit tree and the working
 *                        tree have diverged).
 *   4. evidence logs   — research/runs/<run>/logs/** must be tracked, because
 *                        the .gitignore negation is easy to get wrong and a
 *                        silently dropped log is an unreproducible run.
 *
 * Exit codes: 0 complete, 1 publication gaps, 2 the check could not run.
 *
 * Usage:
 *   node scripts/publication/check_publication.js [--verbose] [--json <file>]
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const MANIFEST = path.join(__dirname, 'required-inputs.json');
const verbose = process.argv.includes('--verbose');
const jsonArg = process.argv.indexOf('--json');

function git(args, opts = {}) {
  const r = spawnSync('git', args, { cwd: ROOT, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (r.error && r.error.code === 'ENOENT') return { missing: true };
  return { status: r.status, out: (r.stdout || ''), err: (r.stderr || '') };
}

const head = git(['rev-parse', '--verify', 'HEAD']);
if (head.missing) {
  console.error('PUBLICATION: BLOCKED — git is not available');
  process.exit(2);
}
if (head.status !== 0) {
  console.error('PUBLICATION: BLOCKED — this is not a Git repository with a commit');
  process.exit(2);
}
const headSha = head.out.trim();

let manifest;
try {
  manifest = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));
} catch (e) {
  console.error(`PUBLICATION: BLOCKED — manifest unreadable: ${e.message}`);
  process.exit(2);
}

const trackedList = git(['ls-files']);
if (trackedList.status !== 0) {
  console.error('PUBLICATION: BLOCKED — git ls-files failed');
  process.exit(2);
}
const tracked = new Set(trackedList.out.split('\n').map(s => s.trim()).filter(Boolean));

const errors = [];
const notes = [];

// 1. explicit inputs -------------------------------------------------------
const missingExact = [];
for (const p of manifest.exact || []) {
  if (!tracked.has(p)) missingExact.push(p);
}
if (missingExact.length) {
  errors.push(`${missingExact.length} required path(s) are not in the Git tree:`);
  for (const p of missingExact) {
    const onDisk = fs.existsSync(path.join(ROOT, p));
    errors.push(`  ${p}${onDisk ? '  (exists on disk, untracked)' : '  (absent)'}`);
  }
}

// 2. whole trees -----------------------------------------------------------
for (const tree of manifest.trees || []) {
  const abs = path.join(ROOT, tree);
  if (!fs.existsSync(abs)) {
    errors.push(`tree ${tree} does not exist on disk`);
    continue;
  }
  const untracked = git(['ls-files', '--others', '--exclude-standard', '--', tree]);
  if (untracked.status !== 0) {
    errors.push(`could not enumerate untracked files under ${tree}`);
    continue;
  }
  const files = untracked.out.split('\n').map(s => s.trim()).filter(Boolean);
  if (files.length) {
    errors.push(`${files.length} file(s) under ${tree} are present but untracked:`);
    for (const f of files) errors.push(`  ${f}`);
  }
  const count = [...tracked].filter(t => t === tree || t.startsWith(tree + '/')).length;
  if (count === 0) errors.push(`tree ${tree} has no tracked files`);
  else notes.push(`${tree}: ${count} tracked file(s)`);
}

// 3. the tracked tree and the working tree must agree ----------------------
const deleted = git(['ls-files', '--deleted']);
if (deleted.status === 0) {
  const gone = deleted.out.split('\n').map(s => s.trim()).filter(Boolean);
  if (gone.length) {
    errors.push(`${gone.length} tracked file(s) are missing from the working tree:`);
    for (const f of gone) errors.push(`  ${f}`);
  }
}

// 4. evidence logs must be published ---------------------------------------
const runsDir = path.join(ROOT, 'research', 'runs');
if (fs.existsSync(runsDir)) {
  const runs = fs.readdirSync(runsDir, { withFileTypes: true }).filter(d => d.isDirectory());
  let logCount = 0;
  for (const run of runs) {
    const logDir = path.join(runsDir, run.name, 'logs');
    if (!fs.existsSync(logDir)) continue;
    for (const f of fs.readdirSync(logDir)) {
      const rel = ['research', 'runs', run.name, 'logs', f].join('/');
      logCount += 1;
      if (!tracked.has(rel)) errors.push(`run log not tracked: ${rel}`);
    }
  }
  notes.push(`${runs.length} run(s), ${logCount} evidence log(s) checked for tracking`);
}

// ---------------------------------------------------------------------------
const ok = errors.length === 0;
console.log('PUBLICATION COMPLETENESS');
console.log(`  HEAD       ${headSha}`);
console.log(`  manifest   scripts/publication/required-inputs.json`);
console.log(`  exact      ${(manifest.exact || []).length} required path(s)`);
console.log(`  trees      ${(manifest.trees || []).join(', ')}`);
if (verbose) for (const n of notes) console.log(`  note       ${n}`);
console.log('');
if (ok) {
  console.log('PUBLICATION: COMPLETE');
} else {
  for (const e of errors) console.log(`  ${e}`);
  console.log('');
  console.log(`PUBLICATION: ${errors.length} gap entr${errors.length === 1 ? 'y' : 'ies'}`);
}

if (jsonArg > 0 && process.argv[jsonArg + 1]) {
  fs.writeFileSync(path.resolve(ROOT, process.argv[jsonArg + 1]),
    JSON.stringify({ head: headSha, ok, errors, notes, generated_utc: new Date().toISOString() }, null, 2));
}

process.exit(ok ? 0 : 1);
