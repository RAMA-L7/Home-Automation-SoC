#!/usr/bin/env python3
"""Write a run manifest for published evidence.

Records, for one run directory: the tested source commit, whether the tree was
dirty, the tool versions, the files included as evidence with their SHA-256 and
size, and the command lines that produced them.

Usage:
    python3 scripts/evidence/make_manifest.py \
        --run research/runs/RUN-0025-external-review-2026-11-26 \
        --source-commit <sha> \
        --command "node scripts/eda/run_macro_wrapper.js => exit 0" \
        --note "..."

Hashes are computed over the raw bytes of each file, never over a decoded text
form, so they match `sha256sum`/`certutil -hashfile`.
"""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import subprocess


def sha256(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def git(*args: str) -> str:
    try:
        out = subprocess.run(["git", *args], capture_output=True, text=True, check=False)
        return out.stdout.strip()
    except OSError:
        return "unavailable"


def tool_version(cmd, stdin=None):
    """First line of a tool's version output, or 'unavailable'."""
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, check=False,
                             timeout=60, input=stdin)
        text = "\n".join(x for x in ((out.stdout or ""), (out.stderr or "")) if x)
        return text.strip().splitlines()[0] if text.strip() else "unavailable"
    except (OSError, subprocess.SubprocessError):
        return "unavailable"


def python_version():
    for exe in ("python3.12", "python3", "python"):
        v = tool_version([exe, "--version"])
        if v != "unavailable":
            return f"{v} ({exe})"
    return "unavailable"

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", required=True)
    ap.add_argument("--source-commit", required=True)
    ap.add_argument("--command", action="append", default=[])
    ap.add_argument("--note", default="")
    args = ap.parse_args()

    run_dir = pathlib.Path(args.run)
    if not run_dir.is_dir():
        raise SystemExit(f"{run_dir}: not a directory")

    files = []
    for f in sorted(run_dir.rglob("*")):
        if f.is_dir() or f.name == "manifest.json":
            continue
        files.append({
            "path": f.relative_to(run_dir).as_posix(),
            "bytes": f.stat().st_size,
            "sha256": sha256(f),
        })

    manifest = {
        "run": run_dir.name,
        "created_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source_commit": args.source_commit,
        "head_at_manifest": git("rev-parse", "HEAD"),
        "worktree_dirty": bool(git("status", "--porcelain")),
        "notes": args.note,
        "commands": args.command,
        "tools": {
            "iverilog": tool_version(["iverilog", "-V"]),
            "yosys": tool_version(["yosys", "-V"]),
            "node": tool_version(["node", "--version"]),
            "python": python_version(),
            "tclsh": tool_version(["tclsh"], stdin="puts [info patchlevel]\n"),
            "opensta": "BLOCKED — no runnable binary (Linux build; WSL1 unsupported)",
        },
        "paths": {"PATH_head": [p for p in (os.environ.get("PATH") or "").split(os.pathsep) if p][:6]},
        "files": files,
    }
    out = run_dir / "manifest.json"
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"manifest: {out} ({len(files)} files, source {args.source_commit[:12]})")


if __name__ == "__main__":
    main()
