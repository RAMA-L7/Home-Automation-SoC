#!/usr/bin/env python3
"""
Home-Automation-SoC firmware build (Python driver).

Discovery is NOT re-implemented here. `scripts/fw_build/toolchain.js` is the one
algorithm in the project; this driver asks it for JSON and uses the result, so a
Python build and a Node build cannot pick different compilers. If node or a
usable toolchain is missing, this exits 2 with the resolver's message — it never
falls back to a different prefix silently.

Outputs go to build/fw/ (the directory build_fw.js, gen_fw_mem.js and the
regression runner all read), not to a private build directory.

  python scripts/fw_build/build_fw.py build|clean|all
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent
FW_DIR = PROJECT_ROOT / "firmware" / "bare_metal"
BUILD_DIR = PROJECT_ROOT / "build" / "fw"
TOOLCHAIN_JS = PROJECT_ROOT / "scripts" / "fw_build" / "toolchain.js"

# Compiler flags
CFLAGS = [
    # rv32im (NOT rv32imc): rtl/rtl_top/riscv_core.sv does not implement the
    # compressed extension, so rv32imc code would trap on its first 16-bit
    # instruction.  The core also has no user mode, PMP or F/D.
    "-march=rv32im",
    "-mabi=ilp32",
    "-nostdlib", "-nostartfiles", "-ffreestanding",
    "-Wall", "-Wextra", "-O2", "-g",
    f"-T{str(FW_DIR / 'linker.ld')}",
]

# Source files
SRC_FILES = [
    "startup.S",
    "main.c",
    "drivers.c",
    "boot.c",
    "host_comm.c",
    "ota.c",
]


def resolve_toolchain():
    """Ask the shared Node resolver. Raises RuntimeError with its message."""
    node = shutil.which("node")
    if not node:
        raise RuntimeError(
            "node was not found on PATH; scripts/fw_build/toolchain.js is the "
            "single toolchain resolver and cannot run without it"
        )
    proc = subprocess.run([node, str(TOOLCHAIN_JS), "--json"],
                          capture_output=True, text=True)
    try:
        info = json.loads(proc.stdout or "{}")
    except json.JSONDecodeError:
        raise RuntimeError(
            f"toolchain.js produced no JSON (exit {proc.returncode}): "
            f"{proc.stdout}{proc.stderr}"
        )
    if not info.get("ok"):
        raise RuntimeError(info.get("error") or
                           f"toolchain.js failed (exit {proc.returncode})")
    return info


def tool_path(tc, name):
    """Absolute path to a tool of the resolved toolchain."""
    binary = tc["prefix"] + name
    if not tc.get("binDir"):
        return binary
    p = Path(tc["binDir"]) / binary
    if not p.exists() and sys.platform == "win32":
        p = Path(str(p) + ".exe")
    return str(p)


def build_env(tc):
    env = dict(os.environ)
    if tc.get("binDir"):
        env["PATH"] = tc["binDir"] + os.pathsep + env.get("PATH", "")
        env["RISCV_TOOLCHAIN_BIN"] = tc["binDir"]
    return env


def run_cmd(cmd, cwd=None, env=None):
    """Run command and return (success, output)."""
    try:
        result = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True,
                                text=True, timeout=120)
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except Exception as exc:                     # noqa: BLE001 - reported verbatim
        return False, str(exc)


def build_firmware():
    """Build firmware with the shared toolchain. Returns a process exit code."""
    print("=== Home-Automation-SoC Firmware Build ===")

    try:
        tc = resolve_toolchain()
    except RuntimeError as exc:
        print(f"BLOCKED: {exc}")
        return 2

    env = build_env(tc)
    print(f"toolchain: {tc['gccPath']} [{tc['source']}]")
    print(f"  {tc['version']} (target {tc['machine']})")

    cc = tool_path(tc, "gcc")
    objcopy = tool_path(tc, "objcopy")
    size_tool = tool_path(tc, "size")

    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    # Build ELF
    print("Compiling firmware...")
    cmd = [cc] + CFLAGS + [f"-o{str(BUILD_DIR / 'firmware.elf')}"] + \
          [str(FW_DIR / f) for f in SRC_FILES]
    print(f"  {' '.join(cmd)}")

    success, output = run_cmd(cmd, cwd=str(FW_DIR), env=env)
    print(output)
    if not success:
        print("ERROR: Compilation failed")
        return 1

    # Generate binary
    print("Generating binary...")
    cmd = [objcopy, "-O", "binary", str(BUILD_DIR / "firmware.elf"),
           str(BUILD_DIR / "firmware.bin")]
    success, output = run_cmd(cmd, env=env)
    print(output)
    if not success:
        print("ERROR: objcopy binary failed")
        return 1

    # Generate S-record
    print("Generating S-record...")
    cmd = [objcopy, "-O", "srec", str(BUILD_DIR / "firmware.elf"),
           str(BUILD_DIR / "firmware.srec")]
    success, output = run_cmd(cmd, env=env)
    print(output)
    if not success:
        print("ERROR: objcopy srec failed")
        return 1

    # Print size
    print("Firmware size:")
    cmd = [size_tool, str(BUILD_DIR / "firmware.elf")]
    _, output = run_cmd(cmd, env=env)
    print(output)

    print(f"\nBuild complete: {BUILD_DIR / 'firmware.bin'}")
    return 0


def clean_build():
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
        print(f"Cleaned {BUILD_DIR}")


def main():
    parser = argparse.ArgumentParser(description="Home-Automation-SoC Firmware Build")
    parser.add_argument("action", choices=["build", "clean", "all"],
                        help="Action to perform")
    args = parser.parse_args()

    if args.action == "clean":
        clean_build()
        sys.exit(0)
    if args.action == "all":
        clean_build()
        sys.exit(build_firmware())
    sys.exit(build_firmware())


if __name__ == "__main__":
    main()
