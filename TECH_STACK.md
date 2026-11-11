# Home-Automation-SoC — Tech Stack

**Project:** Low-power residential home automation RISC-V SoC  
**Target:** QFN-64 package, SkyWater 130nm (sky130) ASIC / Nexys A7-100T FPGA  
**Document Version:** 1.0  
**Date:** 2026-11-11

---

## 1. Overview

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| ISA | RISC-V RV32IMC | — | Base + Multiply + Compressed extensions |
| Processor Core | Ibex | — | 4-stage, machine mode + user mode, PMP |
| HDL | SystemVerilog | IEEE 1800-2017 | RTL design entry |
| Bus (CPU-to-Mem) | AXI4-Lite | — | 32-bit data, single outstanding |
| Bus (Peripheral) | APB | — | Via AXI4-Lite-to-APB bridge |
| Firmware Language | C / Assembly | C11 / GNU AS | Bare-metal + Zephyr RTOS |
| Build System | Make / Ninja | — | RTL lint, firmware, simulation |
| Simulation | Verilator / Icarus | 5.053 / 14.0 | RTL functional verification |
| Formal | SymbiYosys | — | CDC, reset, bus property checking |
| Synthesis | Yosys | 0.69+154 | RTL-to-gates synthesis |
| FPGA Toolchain | Xilinx Vivado | WebPACK | Nexys A7-100T synthesis/impl |
| ASIC Toolchain | OpenLane 2 / OpenROAD | — | sky130 P&R (not installed) |
| PDK | SkyWater 130nm | sky130A | ASIC target process |
| PCB | KiCad | 10.0.8 | Schematic + layout |
| Version Control | Git | — | Source control, GitHub |
| CI/CD | GitHub Actions | — | (planned, not configured) |

---

## 2. RTL Design (22 SystemVerilog Files)

### 2.1 Top-Level / SoC Integration (`rtl/rtl_top/`)

| File | Function | Status |
|------|----------|--------|
| `has_soc.sv` | Top-level SoC integration | DONE |
| `has_addr_map.sv` | Address map package | DONE |
| `boot_rom.sv` | 16 KB secure boot ROM (instruction + AXI ports) | DONE |
| `sram.sv` | 128 KB SRAM (AXI4-Lite slave + instruction port) | DONE |
| `riscv_core.sv` | RV32IMC multi-cycle core | DONE |
| `axi_lite_interconnect.sv` | 1-master × 6-slave AXI4-Lite interconnect | DONE |
| `axi_lite_to_apb.sv` | AXI4-Lite → APB bridge | DONE |
| `req_gnt_to_axi_lite.sv` | Ibex req/gnt → AXI4-Lite adapter | DONE |
| `intc_axi.sv` | CLINT/PLIC bus mux (single AXI slave) | DONE |

### 2.2 Peripherals (`rtl/rtl_peripherals/`)

| File | Function | Interface | Status |
|------|----------|-----------|--------|
| `gpio.sv` | 16-bit GPIO with interrupt | APB | DONE |
| `uart.sv` | UART 115200 baud (TX/RX) | APB | DONE |
| `i2c_ctrl.sv` | I²C master controller | APB | DONE |
| `spi_ctrl.sv` | SPI master controller (mode 0) | APB | DONE |
| `pwm.sv` | 4-channel PWM, 16-bit period/duty | APB | DONE |
| `timer.sv` | General-purpose timer | APB | DONE |
| `watchdog.sv` | Watchdog timer with reset | APB | DONE |
| `i2s.sv` | I²S transmitter | APB | DONE |
| `qspi_flash_ctrl.sv` | QSPI flash controller (single-line READ) | APB | DONE |
| `clint.sv` | CLINT (mtime, mtimecmp, msip) | Register port | DONE |
| `plic.sv` | PLIC (8 sources, 1 context) | Register port | DONE |
| `power_mgr.sv` | Power manager (clock gating, sleep) | Register port | DONE |
| `power_mgr_regs.sv` | Power manager APB registers | APB | DONE |
| `debug_jtag.sv` | JTAG debug TAP | JTAG | DONE (stub) |

---

## 3. Firmware Stack

### 3.1 Bare-Metal (`firmware/bare_metal/`)

| File | Function |
|------|----------|
| `startup.S` | Reset vector, .data/.bss initialization |
| `linker.ld` | Memory map sections |
| `main.c` | Blink LED + UART console example |
| `drivers.h` / `drivers.c` | GPIO, UART, timer, watchdog, PMIC drivers |
| `boot.h` / `boot.c` | Secure boot (header validation, signature, SRAM copy, jump) |
| `host_comm.c` | UART protocol to Home Assistant |
| `ota.c` | Over-the-air firmware update |

### 3.2 Boot Firmware (`firmware/boot/`)

| File | Function |
|------|----------|
| `boot.S` | Boot assembly: SRAM tests, GPIO, MUL/DIV, CSRs, PLIC interrupt, PWM, power-mgr, UART report |

### 3.3 Toolchain

| Component | Tool | Version | Notes |
|-----------|------|---------|-------|
| Compiler | riscv-none-elf-gcc | 12.2.0 | Not on PATH — needs installation |
| Assembler | riscv-none-elf-as | 12.2.0 | Part of GCC toolchain |
| Linker | riscv-none-elf-ld | 12.2.0 | Part of GCC toolchain |
| Objcopy | riscv-none-elf-objcopy | 12.2.0 | ELF → BIN conversion |
| RV32IM Assembler | as.js | Custom | Dependency-free JS assembler (no GCC needed) |

### 3.4 RTOS (Planned)

| Component | Tool | Version | Status |
|-----------|------|---------|--------|
| RTOS | Zephyr | 3.6+ LTS | Planned, not integrated |
| Crypto | Mbed TLS PSA | 3.5+ | Planned for secure boot/OTA |

---

## 4. Verification Stack

### 4.1 Simulation

| Tool | Version | Purpose | Status |
|------|---------|---------|--------|
| Icarus Verilog | 14.0 | RTL simulation (broken runtime) | PARTIAL — compiler works, runtime broken |
| Verilator | 5.053 | Lint + C++ model (no C++ compiler) | PARTIAL — lint works, no C++ build |
| cocotb | 2.1.0 | Python-based cosimulation | INSTALLED (needs working simulator) |
| Python | 3.10 (Windows Store) | Test scripts, cocotb | INSTALLED, SSL works |

### 4.2 Formal Verification

| Tool | Version | Purpose | Status |
|------|---------|---------|--------|
| Yosys | 0.69+154 | RTL synthesis, formal prep | WORKS |
| SymbiYosys | — | CDC, reset, property checking | NOT INSTALLED |
| Sby (SymbiYosys runner) | — | Formal flow orchestrator | NOT INSTALLED |

### 4.3 Testbenches (`sim/sim_top/`)

| File | DUT | Status |
|------|-----|--------|
| `tb_sram_simple.v` | SRAM | PASS |
| `tb_gpio.v` | GPIO | PASS |
| `tb_timer.v` | Timer | PASS |
| `tb_watchdog.v` | Watchdog | PASS |
| `tb_pwm.v` | PWM | PASS |
| `tb_i2c.v` | I²C | PASS |
| `tb_spi.v` | SPI | PASS |
| `tb_i2s.v` | I²S | PASS |
| `tb_clint.v` | CLINT | FIXED (register port) |
| `tb_plic.v` | PLIC | FIXED (register port) |
| `tb_power_mgr.v` | Power Mgr | PASS |
| `tb_debug_jtag.v` | Debug JTAG | PASS |
| `tb_boot.v` | Full SoC boot | NOT RUNNABLE (Icarus broken) |
| `tb_has_soc.v` | Top-level SoC | HANDSHAKE ISSUES |
| `tb_integration.v` | Integration | EXISTS |

---

## 5. FPGA Stack

| Component | Tool | Version | Target | Status |
|-----------|------|---------|--------|--------|
| FPGA Board | Digilent Nexys A7-100T | — | Artix-7 XC7A100TCSG324-1 | Not available |
| Synthesis | Xilinx Vivado | WebPACK | — | NOT INSTALLED |
| Constraints | XDC | — | `nexys_a7.xdc` | DONE |
| Timing | SDC | — | `has_soc.sdc` | DONE |
| Bitstream | Vivado | — | `.bit` | NOT GENERATED |
| Debug | OpenOCD | — | JTAG | Config exists |
| Bring-up | Tcl scripts | — | `fpga/projects/` | DONE (templates) |

---

## 6. ASIC Physical Design Stack

| Component | Tool | Version | Status |
|-----------|------|---------|--------|
| PDK | SkyWater 130nm | sky130A | DOWNLOADED (not installed via volare) |
| Synthesis | Yosys | 0.69+154 | WORKS (partial — SV array port issue) |
| P&R | OpenLane 2 | — | NOT INSTALLED (not pip-installable) |
| P&R | OpenROAD | — | NOT INSTALLED |
| STA | OpenSTA | — | NOT INSTALLED |
| DRC | Magic | — | NOT INSTALLED |
| LVS | Netgen | — | NOT INSTALLED |
| Flow Scripts | Tcl + JSON | — | `asic/` directory — DONE (templates) |

---

## 7. PCB Stack

| Component | Tool | Version | Status |
|-----------|------|---------|--------|
| Schematic | KiCad | 10.0.8 | INSTALLED (winget) |
| Layout | KiCad | 10.0.8 | INSTALLED |
| Schematic Doc | Markdown | — | `board/schematics/has_soc_sch.md` |
| BOM | CSV | — | `board/bom/bom.csv` |
| Gerbers | — | — | NOT GENERATED |

---

## 8. Development Tooling

| Component | Tool | Version | Location | Status |
|-----------|------|---------|----------|--------|
| Git | Git | — | Source control | WORKS |
| GitHub | GitHub CLI | `gh` | Repo management | WORKS (authenticated as RAMA-L7) |
| Python | Python 3.10 | Windows Store | Test scripts | WORKS (SSL OK) |
| pip | pip 26.0.1 | — | Package manager | WORKS |
| cocotb | cocotb | 2.1.0 | Cosimulation | INSTALLED |
| Node.js | Node | — | JS assembler (`as.js`) | NOT CONFIRMED |
| Make | GNU Make | — | Build system | NOT INSTALLED |
| g++/gcc | GNU Compiler | — | Verilator C++ model | NOT INSTALLED |
| CMake | CMake | — | Build system | NOT INSTALLED |
| Ninja | Ninja | — | Build system | NOT INSTALLED |

---

## 9. Scripts (`scripts/`)

| Directory | Purpose |
|-----------|---------|
| `scripts/eda/` | EDA tool scripts (Makefile.icarus, Makefile.verilator, run scripts) |
| `scripts/formal/` | SymbiYosys formal verification configs |
| `scripts/fw/` | Firmware build/flash scripts (`as.js`, `build_fw.py`, `flash_fw.py`) |
| `scripts/agents/` | Agent coordination (lock.js, snapshots) |

---

## 10. Constraints (`constraints/`)

| File | Purpose |
|------|---------|
| `constraints/timing_constraints/has_soc.sdc` | SDC timing constraints |
| `constraints/pin_constraints/` | Pin constraints |
| `constraints/pin_assignment_qfn64.csv` | QFN-64 pin assignment |

---

## 11. Reports (`reports/`)

| Directory | Purpose |
|-----------|---------|
| `reports/verification/` | Verification results, formal specs, SVA properties |
| `reports/MASTER_PROJECT_STATUS.md` | Project stage tracking |
| `reports/FINAL_PROJECT_DELIVERY_REPORT.md` | Delivery classification |

---

## 12. Toolchain Installation Summary

### Already Working
| Tool | How Installed | Location |
|------|--------------|----------|
| Git | System | PATH |
| GitHub CLI (`gh`) | System | PATH, authenticated as RAMA-L7 |
| Python 3.10 | Windows Store | `C:\Users\...\PythonSoftwareFoundation...` |
| pip | Bundled with Python | WORKS |
| cocotb | `pip install cocotb` | 2.1.0 |
| Yosys | OSS CAD Suite | `D:\tools\oss-cad-suite\bin\yosys.exe` |
| Icarus Verilog | OSS CAD Suite | `D:\tools\oss-cad-suite\bin\iverilog.exe` |
| KiCad | winget | 10.0.8 |
| Verilator | OSS CAD Suite | `D:\tools\oss-cad-suite\bin\verilator_bin.exe` |

### Missing / Blocked
| Tool | Blocker | Needed For |
|------|---------|------------|
| riscv-none-elf-gcc | Not on PATH, not installed | Firmware compilation |
| g++ / make | Not installed | Verilator C++ model build |
| OpenLane 2 | Not pip-installable | ASIC P&R flow |
| OpenROAD | Not installed | ASIC P&R flow |
| OpenSTA | Not installed | STA sign-off |
| Vivado | Proprietary, not installed | FPGA synthesis/impl |
| SymbiYosys | Not installed | Formal verification |
| volare | Not installed | PDK version management |

---

## 13. Repository

| Item | Value |
|------|-------|
| GitHub URL | https://github.com/RAMA-L7/Home-Automation-SoC |
| Visibility | Public |
| Branch | `main` |
| Latest Tag | `v0.3.0-build-scripts` |
| License | MIT (LICENSE file) |
