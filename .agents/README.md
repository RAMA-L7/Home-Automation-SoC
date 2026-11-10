# Multi-agent coordination (anti-clobber)

Several agents edit this repository simultaneously. Every agent used to
read-modify-write `AGENTS.md` and the RTL files from a stale in-memory copy, so
each one silently deleted the others' work. A single shared file cannot be made
safe for concurrent whole-file writers, so coordination moved to **one small
file per claim**, created atomically.

## The three rules

1. **Never write a shared coordination file.** `AGENTS.md` and
   `.agents/STATUS.md` are generated. If they look wrong, run
   `node scripts/agents/lock.js publish`.
2. **Claim before editing, release when done.** Claims live in
   `.agents/locks/<sha1(path)>.json`, created with `O_EXCL`, so two agents can
   never both own a path.
3. **Snapshot your files.** `.agents/owned/<agent>/` holds your last known-good
   copy. If someone clobbers your file, `restore` puts it back.

## Commands

```bash
node scripts/agents/lock.js claim    <agent> <path>...   # take ownership
node scripts/agents/lock.js status                       # who owns what
node scripts/agents/lock.js who      <path>              # owner of one file
node scripts/agents/lock.js snapshot <agent> <path>...   # save known-good copy
node scripts/agents/lock.js verify   <agent>             # detect clobbering
node scripts/agents/lock.js restore  <agent>             # undo clobbering
node scripts/agents/lock.js publish                      # rebuild AGENTS.md block
node scripts/agents/lock.js release  <agent> [path]...   # give ownership up
```

`release <agent>` with no paths releases everything that agent holds;
`release <agent> --force` releases locks held by others (only after confirming
the other agent is gone).

## Repairing damage

```bash
node scripts/agents/lock.js verify buffy    # lists CHANGED / MISSING files
node scripts/agents/lock.js restore buffy   # writes the snapshot back
node scripts/agents/lock.js publish
```

## What this does and does not guarantee

- **Guarantees:** two agents cannot both believe they own the same file; a
  clobbered file is detectable (sha256) and recoverable; the status view is
  always rebuildable from the lock files.
- **Does not guarantee:** that another agent obeys the protocol. Agents that
  ignore it can still overwrite files. Snapshots are the safety net, so
  `snapshot` after every editing session.
