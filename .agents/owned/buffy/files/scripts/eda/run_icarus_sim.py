#!/usr/bin/env python3
"""
Home-Automation-SoC Icarus Verilog Simulation Runner
Stage 4 Verification
"""
import subprocess
import sys
import os
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent
RTL_ROOT = PROJECT_ROOT / "rtl"
SIM_ROOT = PROJECT_ROOT / "sim" / "sim_top"

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

TB_FILE = "tb_has_soc.v"
TOP_MODULE = "has_soc"
EXE = "simv"

def run_cmd(cmd, cwd=None, env=None):
    """Run command and return (success, output)"""
    try:
        result = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True, timeout=300)
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except Exception as e:
        return False, str(e)

def build_icarus():
    """Build with Icarus Verilog"""
    print("Building with Icarus Verilog...")
    
    iverilog = "iverilog"
    src_files = [str(RTL_ROOT / f) for f in RTL_SRCS]
    tb_file = str(SIM_ROOT / TB_FILE)
    
    cmd = [
        iverilog,
        "-g2012", "-Wall", "-Wno-timescale",
        f"-I{RTL_ROOT}/rtl_top", f"-I{RTL_ROOT}/rtl_peripherals",
        "-DIVERILOG_SIM", "-DIVERILOG",
        "-s", TOP_MODULE,
        "-o", EXE,
        *src_files,
        tb_file
    ]
    
    print(f"Running: {' '.join(cmd)}")
    success, output = run_cmd(cmd, cwd=str(SIM_ROOT))
    print(output)
    return success

def run_simulation():
    """Run the simulation with VVP"""
    print("Running simulation with VVP...")
    exe_path = str(SIM_ROOT / EXE)
    if not os.path.exists(exe_path):
        print(f"Executable not found: {exe_path}")
        return False
    
    success, output = run_cmd(["vvp", "-n", exe_path], cwd=str(SIM_ROOT))
    print(output)
    return success

def run_with_vcd():
    """Run simulation with VCD waveform"""
    print("Running simulation with VCD...")
    exe_path = str(SIM_ROOT / EXE)
    if not os.path.exists(exe_path):
        print(f"Executable not found: {exe_path}")
        return False
    
    success, output = run_cmd(["vvp", "-n", exe_path, "-lxt2"], cwd=str(SIM_ROOT))
    print(output)
    return success

def lint_only():
    """Run syntax/lint check only"""
    print("Running syntax check...")
    
    iverilog = "iverilog"
    src_files = [str(RTL_ROOT / f) for f in RTL_SRCS]
    tb_file = str(SIM_ROOT / TB_FILE)
    
    cmd = [
        iverilog,
        "-g2012", "-Wall", "-Wno-timescale",
        f"-I{RTL_ROOT}/rtl_top", f"-I{RTL_ROOT}/rtl_peripherals",
        "-DIVERILOG_SIM", "-DIVERILOG",
        "-t", "null",
        *src_files,
        tb_file
    ]
    
    print(f"Running: {' '.join(cmd)}")
    success, output = run_cmd(cmd, cwd=str(SIM_ROOT))
    print(output)
    return success

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Home-Automation-SoC Icarus Verilog Simulation")
    parser.add_argument("action", choices=["build", "run", "vcd", "lint", "all"],
                       help="Action to perform")
    args = parser.parse_args()
    
    if args.action == "build":
        success = build_icarus()
    elif args.action == "run":
        success = run_simulation()
    elif args.action == "vcd":
        success = run_with_vcd()
    elif args.action == "lint":
        success = lint_only()
    elif args.action == "all":
        success = build_icarus()
        if success:
            success = run_simulation()
    else:
        success = False
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()