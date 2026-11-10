#!/usr/bin/env python3
"""
Home-Automation-SoC Firmware Flash Script
Stage 3 Firmware

Flashes firmware binary to QSPI flash via OpenOCD + JTAG.
"""
import subprocess
import sys
import os
import time
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent
BUILD_DIR = PROJECT_ROOT / "scripts" / "fw_build" / "build"
OPENOCD_SCRIPTS = PROJECT_ROOT / "fpga" / "openocd"

# OpenOCD configuration
OPENOCD_CFG = "has_soc.cfg"
OPENOCD_BIN = "openocd"

def run_cmd(cmd, cwd=None, env=None, timeout=60):
    """Run command and return (success, output)"""
    try:
        result = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, timeout=timeout)
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except Exception as e:
        return False, str(e)

def find_openocd():
    """Find OpenOCD executable"""
    # Check in tools
    tools_bin = Path("D:/tools/oss-cad-suite/bin/openocd.exe")
    if tools_bin.exists():
        return str(tools_bin)
    
    # Check in PATH
    oc = shutil.which("openocd")
    if oc:
        return oc
    
    return None

def flash_firmware(partition="A", verify=True):
    """Flash firmware to QSPI flash via JTAG"""
    print("=== Home-Automation-SoC Firmware Flash ===")
    
    # Find OpenOCD
    openocd = find_openocd()
    if not openocd:
        print("ERROR: OpenOCD not found!")
        print("  Install: D:\\tools\\oss-cad-suite should have it")
        return False
    
    print(f"Using OpenOCD: {openocd}")
    
    # Check firmware binary
    bin_file = BUILD_DIR / "firmware.bin"
    if not bin_file.exists():
        print(f"ERROR: Firmware binary not found: {bin_file}")
        print("  Run: python build_fw.py build")
        return False
    
    print(f"Flashing: {bin_file}")
    
    # Partition addresses
    if partition == "A":
        flash_addr = "0x40001000"
    elif partition == "B":
        flash_addr = "0x40201000"
    else:
        print(f"ERROR: Invalid partition: {partition}")
        return False
    
    # OpenOCD commands
    # Note: This assumes a specific OpenOCD config for the SoC
    # The config should define the flash bank for QSPI
    oc_cmds = [
        "init",
        "reset halt",
        f"flash write_image erase {bin_file} {flash_addr}",
    ]
    if verify:
        oc_cmds.append(f"flash verify_image {bin_file} {flash_addr}")
    oc_cmds.extend(["reset run", "exit"])
    
    # Build OpenOCD command
    cmd = [openocd, "-f", str(OPENOCD_SCRIPTS / OPENOCD_CFG)]
    for oc_cmd in oc_cmds:
        cmd.extend(["-c", oc_cmd])
    
    print(f"Running: {' '.join(cmd)}")
    
    success, output = run_cmd(cmd, cwd=str(OPENOCD_SCRIPTS), timeout=120)
    print(output)
    
    if success:
        print(f"\nFlash complete! Partition {partition} updated.")
    else:
        print("\nERROR: Flash failed")
    
    return success

def main():
    import argparse
    import shutil
    
    parser = argparse.ArgumentParser(description="Home-Automation-SoC Firmware Flash")
    parser.add_argument("action", choices=["flash", "verify"],
                       help="Action to perform")
    parser.add_argument("--partition", choices=["A", "B"], default="A",
                       help="Target partition (A or B)")
    parser.add_argument("--no-verify", action="store_true",
                       help="Skip verification after flash")
    
    args = parser.parse_args()
    
    if args.action == "flash":
        success = flash_firmware(args.partition, not args.no_verify)
    elif args.action == "verify":
        # Just verify
        success = flash_firmware(args.partition, True)
    else:
        success = False
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()