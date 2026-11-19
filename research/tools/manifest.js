#!/usr/bin/env node
'use strict';
/*
 * Home-Automation-SoC research evidence — manifest writer.
 *
 *   node research/tools/manifest.js <run-dir> [file ...]
 *
 * Writes into <run-dir>:
 *   source-manifest.json    git state of the worktree the run used
 *   artifact-manifest.json  size + sha256 of every named file that exists
 *
 * Files are listed even when missing, marked exists:false, so an absent
 * artifact is visible rather than silently omitted.
 */
const { spawnSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const runDir = process.argv[2];
const files = process.argv.slice(3);
if (!runDir) {
  console.error('usage: node research/tools/manifest.js <run-dir> [file ...]');
  process.exit(2);
}

function git(args) {
  const r = spawnSync('git', args, { cwd: ROOT, encoding: 'utf8' });
  return (r.stdout || '').trim();
}

const status = git(['status', '--porcelain']);
const lines = status ? status.split('\n') : [];
const source = {
  generated_utc: new Date().toISOString(),
  head: git(['rev-parse', 'HEAD']),
  branch: git(['rev-parse', '--abbrev-ref', 'HEAD']),
  remote: git(['config', '--get', 'remote.origin.url']),
  worktree_dirty: lines.some(l => !l.startsWith('??')),
  modified_tracked: lines.filter(l => !l.startsWith('??')).map(l => l.slice(2).trim()),
  untracked_count: lines.filter(l => l.startsWith('??')).length,
  generated_after_run: true,
  note: 'A dirty worktree means results belong to HEAD plus these local changes, not to HEAD alone. This manifest is emitted after the run; when the worktree changed during the run, trust the state recorded at the start of the run (timing.txt / commands.jsonl), not this snapshot.',
};

const artifacts = files.map(f => {
  const abs = path.join(ROOT, f);
  if (!fs.existsSync(abs)) return { path: f, exists: false };
  const buf = fs.readFileSync(abs);
  return {
    path: f,
    exists: true,
    bytes: buf.length,
    sha256: crypto.createHash('sha256').update(buf).digest('hex'),
  };
});

fs.mkdirSync(runDir, { recursive: true });
fs.writeFileSync(path.join(runDir, 'source-manifest.json'), JSON.stringify(source, null, 2) + '\n');
fs.writeFileSync(path.join(runDir, 'artifact-manifest.json'), JSON.stringify({ generated_utc: source.generated_utc, artifacts }, null, 2) + '\n');
console.log(`wrote ${runDir}/source-manifest.json (${source.untracked_count} untracked, dirty=${source.worktree_dirty})`);
console.log(`wrote ${runDir}/artifact-manifest.json (${artifacts.filter(a => a.exists).length}/${artifacts.length} present)`);
