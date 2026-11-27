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
import shutil
import subprocess
import sys

# Tools installed locally but not necessarily exported on PATH.
LOCAL_TOOL_DIRS = [
    "D:/tools/oss-cad-suite/bin",
    "D:/tools/oss-cad-suite/lib",
]


def win_path(p: str) -> str:
    r"""Translate an MSYS-style path (/d/tools/x) to a Windows one (D:/tools/x).

    Python on Windows reads "/d/tools/x" as D:\d\tools\x, i.e. it silently
    looks in the wrong place and reports the tool as missing.
    """
    if len(p) > 2 and p[0] == "/" and p[2] == "/" and p[1].isalpha():
        return p[1].upper() + ":" + p[2:]
    return p


def wsl_path(p: str) -> str:
    """Translate a Windows or MSYS-style path to the WSL mount form."""
    p = win_path(p)
    if len(p) > 1 and p[1] == ":":
        return "/mnt/" + p[0].lower() + p[2:]
    return p


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
    """First line of a tool's version output, or 'unavailable'.

    The OSS CAD Suite binaries need their own bin and lib directories on PATH
    (they link against DLLs that ship there), so a probe that inherits a bare
    PATH reports a present tool as missing and the manifest records a version
    that is not the one that produced the evidence.
    """
    env = dict(os.environ)
    extra = os.pathsep.join(win_path(d) for d in LOCAL_TOOL_DIRS)
    env["PATH"] = extra + os.pathsep + (env.get("PATH") or "")
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, check=False,
                             timeout=60, input=stdin, env=env)
        text = "\n".join(x for x in ((out.stdout or ""), (out.stderr or "")) if x)
        return text.strip().splitlines()[0] if text.strip() else "unavailable"
    except (OSError, subprocess.SubprocessError):
        return "unavailable"


def python_version():
    # Probe the interpreter running this script first: on Windows "python" is a
    # Store stub and "python3.12" may be a broken launcher, and recording a stub
    # message as the tool version is how this manifest used to lie.
    for exe in (sys.executable, "python3.12", "python3", "python"):
        if not exe:
            continue
        v = tool_version([exe, "--version"])
        if v != "unavailable" and "Microsoft Store" not in v:
            return f"{v} ({exe})"
    return "unavailable"


def find_tool(name: str, extra_dirs: list) -> str:
    """Return a usable path for `name`, searching PATH and known local dirs.

    A tool that exists but is not on PATH is recorded with its resolved path
    rather than reported as missing.
    """
    found = shutil.which(name)
    if found:
        return found
    for d in extra_dirs:
        for suffix in ("", ".exe", ".bat"):
            cand = pathlib.Path(win_path(d)) / (name + suffix)
            if cand.is_file():
                return str(cand)
    return name


def opensta_version() -> str:
    """Probe OpenSTA instead of assuming it is absent.

    OpenSTA here is a Linux build, so it is run through WSL. The old manifest
    hardcoded "BLOCKED - WSL1 unsupported", which was both wrong (the machine
    runs WSL2) and self-fulfilling: it made a measured timing FAIL look like a
    tool gap. A failed probe now reports why it failed.
    """
    binary = os.environ.get("OPENSTA_BIN") or "/d/tools/opensta/build/sta"
    guest = wsl_path(binary)
    try:
        r = subprocess.run(["wsl", "bash", "-c", f"{guest} -version"],
                           capture_output=True, text=True, timeout=120)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return f"probe failed: {exc.__class__.__name__}"
    out = (r.stdout or "") + (r.stderr or "")
    for line in out.splitlines():
        if line.strip():
            return f"{line.strip()} (via wsl: {guest})"
    return f"probe failed: exit {r.returncode}"

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
            "iverilog": tool_version([find_tool("iverilog", LOCAL_TOOL_DIRS), "-V"]),
            "yosys": tool_version([find_tool("yosys", LOCAL_TOOL_DIRS), "-V"]),
            "node": tool_version(["node", "--version"]),
            "python": python_version(),
            "tclsh": tool_version(["tclsh"], stdin="puts [info patchlevel]\n"),
            "opensta": opensta_version(),
        },
        "paths": {"PATH_head": [p for p in (os.environ.get("PATH") or "").split(os.pathsep) if p][:6]},
        "files": files,
    }
    out = run_dir / "manifest.json"
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"manifest: {out} ({len(files)} files, source {args.source_commit[:12]})")


if __name__ == "__main__":
    main()
