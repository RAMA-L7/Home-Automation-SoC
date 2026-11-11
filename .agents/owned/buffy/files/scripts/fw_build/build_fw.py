#!/usr/bin/env python3
"""
Home-Automation-SoC Firmware Build Script
Stage 3 Firmware
"""
import subprocess
import sys
import os
import shutil
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent
FW_DIR = PROJECT_ROOT / "firmware" / "bare_metal"
BUILD_DIR = PROJECT_ROOT / "scripts" / "fw_build" / "build"

# Toolchain prefix (set via environment variable RISCV_GCC_PREFIX or auto-detect)
TOOLCHAIN_PREFIX = os.environ.get("RISCV_GCC_PREFIX", "riscv32-unknown-elf-")

# Compiler flags
CFLAGS = [
    # rv32im (NOT rv32imc): rtl/rtl_top/riscv_core.sv does not implement the
    # compressed extension, so rv32imc code would trap on its first 16-bit
    # instruction.  The core also has no user mode, PMP or F/D.
    f"-march=rv32im",
    f"-mabi=ilp32",
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

def find_toolchain():
    """Try to find RISC-V toolchain"""
    # Check environment variable
    prefix = os.environ.get("RISCV_GCC_PREFIX")
    if prefix:
        cc = shutil.which(f"{prefix}gcc")
        if cc:
            return prefix
    
    # Try common prefixes
    for prefix in ["riscv32-unknown-elf-", "riscv64-unknown-elf-", "riscv32-elf-"]:
        cc = shutil.which(f"{prefix}gcc")
        if cc:
            return prefix
    
    return None

def run_cmd(cmd, cwd=None, env=None):
    """Run command and return (success, output)"""
    try:
        result = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, timeout=120)
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except Exception as e:
        return False, str(e)

def build_firmware():
    """Build firmware with RISC-V toolchain"""
    print("=== Home-Automation-SoC Firmware Build ===")
    
    # Find toolchain
    prefix = find_toolchain()
    if not prefix:
        print("ERROR: RISC-V cross-toolchain not found!")
        print("  Install: sudo apt install gcc-riscv32-unknown-elf")
        print("  Or set RISCV_GCC_PREFIX environment variable")
        return False
    
    print(f"Using toolchain: {prefix}")
    
    cc = f"{prefix}gcc"
    objcopy = f"{prefix}objcopy"
    size_tool = f"{prefix}size"
    
    # Create build directory
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    
    # Build ELF
    print("Compiling firmware...")
    cmd = [cc] + CFLAGS + [f"-o{str(BUILD_DIR / 'firmware.elf')}"] + [str(FW_DIR / f) for f in SRC_FILES]
    print(f"  {' '.join(cmd)}")
    
    success, output = run_cmd(cmd, cwd=str(FW_DIR))
    print(output)
    if not success:
        print("ERROR: Compilation failed")
        return False
    
    # Generate binary
    print("Generating binary...")
    cmd = [objcopy, "-O", "binary", str(BUILD_DIR / "firmware.elf"), str(BUILD_DIR / "firmware.bin")]
    success, output = run_cmd(cmd)
    print(output)
    if not success:
        print("ERROR: objcopy binary failed")
        return False
    
    # Generate S-record
    print("Generating S-record...")
    cmd = [objcopy, "-O", "srec", str(BUILD_DIR / "firmware.elf"), str(BUILD_DIR / "firmware.srec")]
    success, output = run_cmd(cmd)
    print(output)
    if not success:
        print("ERROR: objcopy srec failed")
        return False
    
    # Print size
    print("Firmware size:")
    cmd = [size_tool, str(BUILD_DIR / "firmware.elf")]
    success, output = run_cmd(cmd)
    print(output)
    
    print(f"\nBuild complete: {BUILD_DIR / 'firmware.bin'}")
    return True

def clean_build():
    """Clean build directory"""
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
        print(f"Cleaned {BUILD_DIR}")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Home-Automation-SoC Firmware Build")
    parser.add_argument("action", choices=["build", "clean", "all"],
                       help="Action to perform")
    args = parser.parse_args()
    
    if args.action == "build":
        success = build_firmware()
    elif args.action == "clean":
        clean_build()
        success = True
    elif args.action == "all":
        clean_build()
        success = build_firmware()
    else:
        success = False
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()