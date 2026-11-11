#!/usr/bin/env node
/*
 * Home-Automation-SoC — multi-agent file ownership / anti-clobber tool
 * ===================================================================
 *
 * Problem it solves: several agents edit this repo at the same time. Each one
 * reads AGENTS.md (or an RTL file), keeps a stale copy in memory, and later
 * writes the whole file back, silently discarding everyone else's changes.
 * One shared file can never be made safe for concurrent whole-file writers.
 *
 * Solution: no agent ever writes a shared file to coordinate.
 *   1. Every claim is its own small file under .agents/locks/, created with
 *      O_EXCL so two agents can never both "win" the same path.
 *   2. Every agent snapshots its owned files under .agents/owned/<agent>/.
 *      If another agent clobbers a file, `restore` puts the owner's version
 *      back and tells you exactly what was repaired.
 *   3. AGENTS.md and .agents/STATUS.md are DERIVED views, regenerated from the
 *      lock files. If someone overwrites them, run `publish` and they are
 *      rebuilt. Nothing is lost because nothing authoritative lived there.
 *
 * Usage
 *   node scripts/agents/lock.js claim    <agent> <path> [path...]
 *   node scripts/agents/lock.js release  <agent> [path...]
 *   node scripts/agents/lock.js status
 *   node scripts/agents/lock.js snapshot <agent> <path> [path...]
 *   node scripts/agents/lock.js verify   <agent>
 *   node scripts/agents/lock.js restore  <agent> [--force]
 *   node scripts/agents/lock.js publish
 *   node scripts/agents/lock.js who      <path>
 *
 * Exit codes: 0 ok, 1 conflict/verification failure, 2 usage error.
 *
 * Recommended workflow for every agent:
 *   claim -> edit -> snapshot -> verify -> publish -> release
 * Re-run `verify` right before publishing results; it reports any file that
 * was changed underneath you.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.resolve(__dirname, '..', '..');
const AGENTS_DIR = path.join(ROOT, '.agents');
const LOCKS = path.join(AGENTS_DIR, 'locks');
const OWNED = path.join(AGENTS_DIR, 'owned');
const STALE_MS = 6 * 60 * 60 * 1000;      // 6 h before a lock is "stale"

function ensureDirs() {
  for (const d of [AGENTS_DIR, LOCKS, OWNED]) fs.mkdirSync(d, { recursive: true });
}

const norm = (p) => path.relative(ROOT, path.resolve(ROOT, p)).replace(/\\/g, '/');
const key = (p) => crypto.createHash('sha1').update(norm(p)).digest('hex').slice(0, 16);
const lockFile = (p) => path.join(LOCKS, key(p) + '.json');

function readJson(f, fallback) {
  try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return fallback; }
}

function sha256(file) {
  try {
    return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  } catch { return null; }
}

function walk(target) {
  const abs = path.resolve(ROOT, target);
  let st;
  try { st = fs.statSync(abs); } catch { return []; }
  if (!st.isDirectory()) return [abs];
  const out = [];
  for (const entry of fs.readdirSync(abs, { withFileTypes: true })) {
    if (entry.name === 'node_modules' || entry.name === '.git') continue;
    out.push(...walk(path.join(abs, entry.name)));
  }
  return out;
}

// ---------------------------------------------------------------------------
// claim / release
// ---------------------------------------------------------------------------
function claim(agent, targets) {
  ensureDirs();
  let conflicts = 0;
  for (const target of targets) {
    for (const abs of walk(target)) {
      const rel = norm(abs);
      const lf = lockFile(rel);
      const rec = {
        path: rel,
        agent,
        time: new Date().toISOString(),
        host: require('os').hostname(),
        pid: process.pid
      };
      let written = false;
      try {
        fs.writeFileSync(lf, JSON.stringify(rec, null, 2), { flag: 'wx' });
        written = true;
      } catch (e) {
        if (e.code !== 'EEXIST') throw e;
        const existing = readJson(lf, {});
        if (existing.agent === agent) {
          fs.writeFileSync(lf, JSON.stringify(rec, null, 2));
          written = true;
        } else {
          const age = Date.now() - Date.parse(existing.time || 0);
          const stale = Number.isFinite(age) && age > STALE_MS;
          console.log(`CONFLICT ${rel}`);
          console.log(`         owned by "${existing.agent}" since ${existing.time}` +
                      (stale ? ' (STALE — > 6 h, use release --force)' : ''));
          conflicts++;
        }
      }
      if (written) console.log(`claimed  ${rel}`);
    }
  }
  return conflicts === 0 ? 0 : 1;
}

function release(agent, targets, force) {
  ensureDirs();
  const files = fs.readdirSync(LOCKS).filter(f => f.endsWith('.json'));
  let n = 0;
  for (const f of files) {
    const lf = path.join(LOCKS, f);
    const rec = readJson(lf, null);
    if (!rec) { fs.rmSync(lf, { force: true }); continue; }
    if (targets.length && !targets.map(norm).includes(rec.path)) continue;
    if (rec.agent !== agent && !force) continue;
    fs.rmSync(lf, { force: true });
    console.log(`released ${rec.path}`);
    n++;
  }
  console.log(`${n} lock(s) released`);
  return 0;
}

// ---------------------------------------------------------------------------
// status / who
// ---------------------------------------------------------------------------
function status() {
  ensureDirs();
  const files = fs.readdirSync(LOCKS).filter(f => f.endsWith('.json'));
  const rows = files.map(f => readJson(path.join(LOCKS, f), null)).filter(Boolean);
  rows.sort((a, b) => a.agent.localeCompare(b.agent) || a.path.localeCompare(b.path));
  if (!rows.length) {
    console.log('no active claims');
    return 0;
  }
  const byAgent = {};
  for (const r of rows) (byAgent[r.agent] ||= []).push(r);
  for (const agent of Object.keys(byAgent).sort()) {
    console.log(`\n${agent}  (${byAgent[agent].length} file(s), since ${byAgent[agent][0].time})`);
    for (const r of byAgent[agent]) console.log(`  ${r.path}`);
  }
  return 0;
}

function who(target) {
  ensureDirs();
  const rel = norm(target);
  const rec = readJson(lockFile(rel), null);
  console.log(rec ? `${rel} -> ${rec.agent} since ${rec.time}` : `${rel} -> unclaimed`);
  return rec ? 0 : 1;
}

// ---------------------------------------------------------------------------
// snapshot / verify / restore
// ---------------------------------------------------------------------------
const slug = (agent) => agent.replace(/[^\w.-]+/g, '_');
const manifestFile = (agent) => path.join(OWNED, slug(agent), 'manifest.json');
const mirrorOf = (agent, rel) => path.join(OWNED, slug(agent), 'files', rel);

// The bookkeeping tree (.agents/) is not project content: mirroring it would
// snapshot our own locks and mirrors, so verify would always report drift.
const isBookkeeping = (rel) => rel === '.agents' || rel.startsWith('.agents/');

function snapshot(agent, targets) {
  ensureDirs();
  const manifest = readJson(manifestFile(agent), { agent, files: {} });
  let n = 0;
  for (const target of targets) {
    for (const abs of walk(target)) {
      const rel = norm(abs);
      if (isBookkeeping(rel)) continue;
      const dst = mirrorOf(agent, rel);
      fs.mkdirSync(path.dirname(dst), { recursive: true });
      fs.copyFileSync(abs, dst);
      manifest.files[rel] = { sha256: sha256(dst), time: new Date().toISOString() };
      n++;
    }
  }
  manifest.agent = agent;
  manifest.updated = new Date().toISOString();
  // Drop any bookkeeping entries recorded by an older version of this tool.
  for (const rel of Object.keys(manifest.files)) {
    if (isBookkeeping(rel)) {
      delete manifest.files[rel];
      fs.rmSync(mirrorOf(agent, rel), { force: true });
      fs.rmSync(path.join(OWNED, slug(agent), 'files', '.agents'), { recursive: true, force: true });
    }
  }
  fs.writeFileSync(manifestFile(agent), JSON.stringify(manifest, null, 2));
  console.log(`${n} file(s) snapshotted for ${agent}`);
  return 0;
}

function verify(agent) {
  const manifest = readJson(manifestFile(agent), null);
  if (!manifest) { console.log(`no snapshot for ${agent}`); return 2; }
  let bad = 0;
  for (const [rel, meta] of Object.entries(manifest.files)) {
    if (isBookkeeping(rel)) continue;
    const abs = path.join(ROOT, rel);
    if (!fs.existsSync(abs)) {
      console.log(`MISSING   ${rel}`);
      bad++;
      continue;
    }
    const now = sha256(abs);
    if (now !== meta.sha256) {
      console.log(`CHANGED   ${rel}`);
      bad++;
    }
  }
  const total = Object.keys(manifest.files).length;
  console.log(bad === 0
    ? `OK: all ${total} owned file(s) match the snapshot`
    : `${bad} of ${total} owned file(s) differ from the snapshot — run restore`);
  return bad === 0 ? 0 : 1;
}

function restore(agent, force) {
  const manifest = readJson(manifestFile(agent), null);
  if (!manifest) { console.log(`no snapshot for ${agent}`); return 2; }
  let restored = 0;
  for (const [rel, meta] of Object.entries(manifest.files)) {
    const abs = path.join(ROOT, rel);
    const src = mirrorOf(agent, rel);
    if (!fs.existsSync(src)) continue;
    const now = fs.existsSync(abs) ? sha256(abs) : null;
    if (now === meta.sha256) continue;
    // Only overwrite if we still own the file, unless --force
    const rec = readJson(lockFile(rel), null);
    if (!force && rec && rec.agent !== agent) {
      console.log(`SKIP      ${rel} (owned by ${rec.agent})`);
      continue;
    }
    fs.mkdirSync(path.dirname(abs), { recursive: true });
    fs.copyFileSync(src, abs);
    console.log(`restored  ${rel}`);
    restored++;
  }
  console.log(restored === 0 ? 'nothing to restore' : `${restored} file(s) restored`);
  return 0;
}

// ---------------------------------------------------------------------------
// publish: regenerate the derived views (AGENTS.md block + .agents/STATUS.md)
// ---------------------------------------------------------------------------
function collectClaims() {
  ensureDirs();
  return fs.readdirSync(LOCKS)
    .filter(f => f.endsWith('.json'))
    .map(f => readJson(path.join(LOCKS, f), null))
    .filter(Boolean)
    .sort((a, b) => a.agent.localeCompare(b.agent) || a.path.localeCompare(b.path));
}

function publish() {
  const rows = collectClaims();
  const now = new Date().toISOString();

  const lines = [];
  lines.push('> **Generated by `scripts/agents/lock.js publish` — do not hand-edit.**');
  lines.push('> The authoritative state lives in `.agents/locks/*.json` (one file per');
  lines.push('> claim, created atomically). If this block is overwritten, re-run publish.');
  lines.push('');
  lines.push(`Updated: ${now}`);
  lines.push('');
  if (!rows.length) {
    lines.push('_No active claims._');
  } else {
    const byAgent = {};
    for (const r of rows) (byAgent[r.agent] ||= []).push(r);
    for (const agent of Object.keys(byAgent).sort()) {
      lines.push(`### ${agent}`);
      lines.push('');
      lines.push(`Claimed since ${byAgent[agent][0].time} — ` +
                 `${byAgent[agent].length} file(s):`);
      lines.push('');
      lines.push('```');
      for (const r of byAgent[agent]) lines.push(r.path);
      lines.push('```');
      lines.push('');
    }
  }
  lines.push('### Protocol (short)');
  lines.push('');
  lines.push('1. `node scripts/agents/lock.js claim <agent> <paths...>` before editing.');
  lines.push('2. Never edit a file another agent holds a live claim on.');
  lines.push('3. `snapshot` after editing, `verify` before publishing results,');
  lines.push('   `restore` if another agent overwrote your files.');
  lines.push('4. `publish` rebuilds this block and `.agents/STATUS.md`.');

  const block = [
    '<!-- AGENTS-LOCK-TABLE:BEGIN -->',
    ...lines,
    '<!-- AGENTS-LOCK-TABLE:END -->'
  ].join('\n');

  const agentsMd = path.join(ROOT, 'AGENTS.md');
  let text = fs.existsSync(agentsMd) ? fs.readFileSync(agentsMd, 'utf8') : '# AGENTS.md\n';
  const re = /<!-- AGENTS-LOCK-TABLE:BEGIN -->[\s\S]*?<!-- AGENTS-LOCK-TABLE:END -->/;
  if (re.test(text)) {
    text = text.replace(re, block);
  } else {
    // Insert near the top (right after the H1) so it is the first thing an
    // agent reads, not something buried at the end of a long file.
    const firstNl = text.indexOf('\n');
    if (text.startsWith('#') && firstNl !== -1) {
      text = text.slice(0, firstNl + 1) + '\n' + block + '\n' + text.slice(firstNl + 1);
    } else {
      text = block + '\n\n' + text;
    }
  }
  fs.writeFileSync(agentsMd, text);

  const statusMd = path.join(AGENTS_DIR, 'STATUS.md');
  fs.writeFileSync(statusMd, '# Active agent claims\n\n' + block + '\n');

  console.log(`published: AGENTS.md block + .agents/STATUS.md (${rows.length} claims)`);
  return 0;
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------
function main() {
  const [, , cmd, ...rest] = process.argv;
  ensureDirs();
  switch (cmd) {
    case 'claim':
      if (rest.length < 2) break;
      return claim(rest[0], rest.slice(1));
    case 'release':
      if (rest.length < 1) break;
      return release(rest[0], rest.slice(1).filter(a => a !== '--force'),
                     rest.includes('--force'));
    case 'status': return status();
    case 'who':
      if (rest.length < 1) break;
      return who(rest[0]);
    case 'snapshot':
      if (rest.length < 2) break;
      return snapshot(rest[0], rest.slice(1));
    case 'verify':
      if (rest.length < 1) break;
      return verify(rest[0]);
    case 'restore':
      if (rest.length < 1) break;
      return restore(rest[0], rest.includes('--force'));
    case 'publish': return publish();
    default: break;
  }
  console.error('usage: lock.js <claim|release|status|who|snapshot|verify|restore|publish> ...');
  return 2;
}

process.exit(main());
