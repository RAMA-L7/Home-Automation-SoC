#!/usr/bin/env python3
"""Generate the source/input manifest for a research run.

Hashes every path in the publication manifest (exact paths plus the trees) at
the moment it is called, so a later evidence commit can point at exactly what
was executed.  Run it immediately after a closure run and before adding the
evidence files, then commit both together.

Usage:
    python scripts/publication/make_run_manifest.py research/runs/<RUN-ID>
"""
import datetime
import hashlib
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MANIFEST = os.path.join(ROOT, 'scripts', 'publication', 'required-inputs.json')


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def main(run_dir):
    with open(MANIFEST, encoding='utf-8') as fh:
        manifest = json.load(fh)

    paths = []
    for p in manifest.get('exact', []):
        if os.path.isfile(os.path.join(ROOT, p)):
            paths.append(p)
    for tree in manifest.get('trees', []):
        base = os.path.join(ROOT, tree)
        for dirpath, _dirnames, filenames in os.walk(base):
            for name in filenames:
                full = os.path.join(dirpath, name)
                paths.append(os.path.relpath(full, ROOT).replace(os.sep, '/'))

    entries = []
    for p in sorted(set(paths)):
        full = os.path.join(ROOT, p)
        entry = {'path': p}
        try:
            entry['sha256'] = sha256(full)
            entry['bytes'] = os.path.getsize(full)
        except OSError as exc:  # a missing input is itself the finding
            entry['error'] = str(exc)
        entries.append(entry)

    def git(*args):
        return subprocess.run(['git'] + list(args), cwd=ROOT, capture_output=True,
                              text=True).stdout.strip()

    status = [line for line in git('status', '--porcelain').splitlines() if line.strip()]
    dirty_tracked = [line for line in status if not line.startswith('??')]

    record = {
        'generated': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
        'head': git('rev-parse', 'HEAD'),
        'branch': git('rev-parse', '--abbrev-ref', 'HEAD'),
        'worktree': 'clean' if not dirty_tracked else 'dirty',
        'dirty_tracked_files': len(dirty_tracked),
        'note': ('"head" is the revision that was executed: the run finished on a clean '
                 'worktree (dirty_tracked_files 0) before any file in this run directory '
                 'existed. The files listed under this run directory are the evidence the '
                 'run produced, so a later evidence commit can contain both them and this '
                 'manifest while still naming the tested revision.'),
        'input_count': len(entries),
        'files': entries,
    }
    out = os.path.join(ROOT, run_dir, 'source-manifest.json')
    with open(out, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(record, fh, indent=2)
        fh.write('\n')
    print(f'{out}: head={record["head"][:7]} inputs={len(entries)} worktree={record["worktree"]}')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('usage: make_run_manifest.py research/runs/<RUN-ID>')
    main(sys.argv[1])
