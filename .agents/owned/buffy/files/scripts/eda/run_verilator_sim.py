#!/usr/bin/env python3
"""
Home-Automation-SoC Verilator Simulation Runner
Stage 2/4 Verification
"""
import subprocess
import sys
import os
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent
RTL_ROOT = PROJECT_ROOT / "rtl"
SIM_ROOT = PROJECT_ROOT / "sim" / "sim_top"
SCRIPTS_ROOT = PROJECT_ROOT / "scripts" / "eda"

# Source files in dependency order
RTL_SRCS = [
    "rtl_top/has_addr_map.sv",
    "rtl_top/boot_rom.sv",
    "rtl_top/sram.sv",
    "rtl_top/axi_lite_interconnect.sv",
    "rtl_top/axi_lite_to_apb.sv",
    "rtl_top/req_gnt_to_axi_lite.sv",
    "rtl_top/riscv_core.sv",
    "rtl_top/has_soc.sv",
    "rtl_peripherals/gpio.sv",
    "rtl_peripherals/uart.sv",
    "rtl_peripherals/timer.sv",
    "rtl_peripherals/clint.sv",
    "rtl_peripherals/plic.sv",
    "rtl_peripherals/power_mgr.sv",
    "rtl_peripherals/debug_jtag.sv",
    "rtl_peripherals/watchdog.sv",
    "rtl_peripherals/pwm.sv",
    "rtl_peripherals/i2c_ctrl.sv",
    "rtl_peripherals/spi_ctrl.sv",
    "rtl_peripherals/i2s.sv",
    "rtl_peripherals/qspi_flash_ctrl.sv",
    "rtl_peripherals/power_mgr_regs.sv",
]

TB_CPP = "sim_main.cpp"
TOP_MODULE = "has_soc"
OBJ_DIR = "obj_dir"
EXE = f"{OBJ_DIR}/V{TOP_MODULE}"

def run_cmd(cmd, cwd=None, env=None):
    """Run command and return (success, output)"""
    try:
        result = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, timeout=300)
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except Exception as e:
        return False, str(e)

def build_verilator():
    """Build with Verilator"""
    print("Building with Verilator...")
    
    # Find Verilator
    verilator = "verilator"
    
    # Construct command
    src_files = [str(RTL_ROOT / f) for f in RTL_SRCS]
    cpp_file = str(SIM_ROOT / TB_CPP)
    
    cmd = [
        verilator,
        "--cc", "--exe", "--trace", "--timing", "--assert",
        "-Wno-fatal", "-Wno-WIDTH", "-Wno-UNOPTFLAT", "-Wno-UNUSED",
        f"-I{RTL_ROOT}/rtl_top", f"-I{RTL_ROOT}/rtl_peripherals",
        "-DVERILATOR_SIM", "-DVERILATOR",
        "--timescale-override", "1ns/1ps",
        f"--top-module={TOP_MODULE}",
        *src_files,
        cpp_file,
        f"-o={EXE}"
    ]
    
    print(f"Running: {' '.join(cmd)}")
    success, output = run_cmd(cmd, cwd=str(SIM_ROOT))
    print(output)
    return success

def run_simulation():
    """Run the simulation"""
    print("Running simulation...")
    exe_path = str(SIM_ROOT / EXE)
    if not os.path.exists(exe_path):
        print(f"Executable not found: {exe_path}")
        return False
    
    success, output = run_cmd([exe_path], cwd=str(SIM_ROOT))
    print(output)
    return success

def run_with_waves():
    """Run simulation with VCD waveform"""
    print("Running simulation with VCD...")
    exe_path = str(SIM_ROOT / EXE)
    if not os.path.exists(exe_path):
        print(f"Executable not found: {exe_path}")
        return False
    
    success, output = run_cmd([exe_path, "+trace"], cwd=str(SIM_ROOT))
    print(output)
    return success

def lint_only():
    """Run lint check only"""
    print("Running lint check...")
    
    verilator = "verilator"
    src_files = [str(RTL_ROOT / f) for f in RTL_SRCS]
    
    cmd = [
        verilator,
        "--lint-only", "--top-module", TOP_MODULE,
        "-I" + str(RTL_ROOT / "rtl_top"),
        "-I" + str(RTL_ROOT / "rtl_peripherals"),
        "-DVERILATOR_SIM", "-DVERILATOR",
        *src_files
    ]
    
    print(f"Running: {' '.join(cmd)}")
    success, output = run_cmd(cmd, cwd=str(RTL_ROOT))
    print(output)
    return success

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Home-Automation-SoC Verilator Simulation")
    parser.add_argument("action", choices=["build", "run", "waves", "lint", "all"],
                       help="Action to perform")
    args = parser.parse_args()
    
    if args.action == "build":
        success = build_verilator()
    elif args.action == "run":
        success = run_simulation()
    elif args.action == "waves":
        success = run_with_waves()
    elif args.action == "lint":
        success = lint_only()
    elif args.action == "all":
        success = build_verilator()
        if success:
            success = run_simulation()
    else:
        success = False
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()