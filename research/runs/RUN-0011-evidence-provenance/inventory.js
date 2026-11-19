const fs = require('fs'), path = require('path'), crypto = require('crypto'), cp = require('child_process');
const ROOT = process.cwd();
const sha = f => { try { return crypto.createHash('sha256').update(fs.readFileSync(path.join(ROOT,f))).digest('hex'); } catch(e){ return null; } };
const ls = (d) => { try { return fs.readdirSync(path.join(ROOT,d)); } catch(e){ return []; } };
const files = new Set();
for (const d of ['rtl','rtl/rtl_top','rtl/rtl_peripherals','sim/sim_top','scripts','scripts/eda','scripts/formal','scripts/fw_build','scripts/firmware','asic/synthesis','firmware','firmware/bare_metal','reports/verification','build/asic_evidence']) {
  for (const f of ls(d)) { const rel = d + '/' + f; try { if (fs.statSync(path.join(ROOT,rel)).isFile()) files.add(rel); } catch(e){} }
}
const tracked = new Set(cp.execSync('git ls-files', {encoding:'utf8'}).split('\n').filter(Boolean));
const manifest = [...files].sort().map(f => ({ path:f, sha256: sha(f), tracked: tracked.has(f), mtime: fs.statSync(path.join(ROOT,f)).mtime.toISOString() }));
const head = cp.execSync('git rev-parse HEAD', {encoding:'utf8'}).trim();
const status = cp.execSync('git status --porcelain', {encoding:'utf8'}).trimEnd().split('\n');
const diff = cp.execSync('git diff --stat HEAD', {encoding:'utf8'});
const out = { generated: new Date().toISOString(), head, branch: cp.execSync('git rev-parse --abbrev-ref HEAD',{encoding:'utf8'}).trim(), dirty_tracked: status.filter(l=>l.startsWith(' M')).length, untracked: status.filter(l=>l.startsWith('??')).length, status, diffstat: diff.trim(), files: manifest,
  missing: manifest.filter(f=>!f.sha256).map(f=>f.path) };
fs.writeFileSync('research/runs/RUN-0011-evidence-provenance/source-manifest.json', JSON.stringify(out,null,2));
console.log(`head ${head.slice(0,7)} dirty_tracked=${out.dirty_tracked} untracked=${out.untracked} files=${manifest.length}`);
console.log('tracked in set:', manifest.filter(f=>f.tracked).length, 'untracked-in-set:', manifest.filter(f=>!f.tracked).length);
