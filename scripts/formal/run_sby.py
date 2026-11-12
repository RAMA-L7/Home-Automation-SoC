#!/usr/bin/env python3
"""
Home-Automation-SoC SymbiYosys Formal Verification Runner
Addresses: ARC-036, ARC-065 (CDC verification)
Stage 4 Verification
"""
import subprocess
import sys
import os
from pathlib import Path

# The OSS CAD Suite is not on the default PATH on this machine.
_TOOLS = Path(os.environ.get("EDA_TOOLS", "D:/tools/oss-cad-suite"))
if _TOOLS.is_dir():
    os.environ["PATH"] = os.pathsep.join([str(_TOOLS / "bin"), str(_TOOLS / "lib"), os.environ.get("PATH", "")])

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent
RTL_ROOT = PROJECT_ROOT / "rtl"
SCRIPTS_ROOT = PROJECT_ROOT / "scripts" / "formal"

# SBY file.  The old prep-only `cdc.sby` (which asserted nothing) was removed on
# 2026-11-12; this wrapper now drives the real CDC task.  Prefer
# `node scripts/formal/run_formal.js`, which runs every task fail-closed.
SBY_FILE = "cdc_power_mgr.sby"

def run_cmd(cmd, cwd=None, env=None):
    """Run command and return (success, output)"""
    try:
        result = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, timeout=600)
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except Exception as e:
        return False, str(e)

def run_sby():
    """Run SymbiYosys formal verification"""
    print("Running SymbiYosys formal verification...")
    
    sby = "sby"
    sby_path = str(SCRIPTS_ROOT / SBY_FILE)
    
    if not os.path.exists(sby_path):
        print(f"SBY file not found: {sby_path}")
        return False
    
    cmd = [sby, "-f", SBY_FILE]
    
    print(f"Running: {' '.join(cmd)}")
    success, output = run_cmd(cmd, cwd=str(SCRIPTS_ROOT))
    print(output)
    return success

def run_sby_task(task):
    """Run specific SBY task"""
    print(f"Running SymbiYosys task: {task}...")
    
    sby = "sby"
    sby_path = str(SCRIPTS_ROOT / SBY_FILE)
    
    if not os.path.exists(sby_path):
        print(f"SBY file not found: {sby_path}")
        return False
    
    cmd = [sby, "-f", SBY_FILE, "-t", task]
    
    print(f"Running: {' '.join(cmd)}")
    success, output = run_cmd(cmd, cwd=str(SCRIPTS_ROOT))
    print(output)
    return success

def list_tasks():
    """List available SBY tasks"""
    print("Listing SBY tasks...")
    
    sby = "sby"
    sby_path = str(SCRIPTS_ROOT / SBY_FILE)
    
    if not os.path.exists(sby_path):
        print(f"SBY file not found: {sby_path}")
        return False
    
    cmd = [sby, "-f", SBY_FILE, "--list"]
    
    print(f"Running: {' '.join(cmd)}")
    success, output = run_cmd(cmd, cwd=str(SCRIPTS_ROOT))
    print(output)
    return success

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Home-Automation-SoC SymbiYosys Formal Verification")
    parser.add_argument("action", choices=["run", "task", "list"],
                       help="Action to perform")
    parser.add_argument("--task", help="Task name for 'task' action")
    args = parser.parse_args()
    
    if args.action == "run":
        success = run_sby()
    elif args.action == "task":
        if not args.task:
            print("Error: --task required for 'task' action")
            success = False
        else:
            success = run_sby_task(args.task)
    elif args.action == "list":
        success = list_tasks()
    else:
        success = False
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()