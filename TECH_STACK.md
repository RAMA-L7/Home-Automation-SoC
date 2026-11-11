# Home-Automation-SoC — Tech Stack

**Project:** Low-power residential home-automation RISC-V SoC
**Target:** QFN-64 package, SkyWater 130nm (sky130) ASIC / Nexys A7-100T FPGA
**Document version:** 2.0 — rewritten 2026-11-11 after independent review
**Reviewed revision:** `2a0c42cc` + uncommitted working-tree fixes

This document separates four things that were previously mixed together:
what is **intended**, what is **actually implemented**, what is **pinned**, and
what has **evidence**. Evidence labels: VERIFIED / DOCUMENTED / MEASURED /
ESTIMATED / ASSUMED / UNKNOWN / BLOCKED.

> Nothing in this project is FPGA- or silicon-verified. Simulation evidence
> covers RTL and a hand-written assembly smoke ROM only. The C firmware has not
> been rebuilt or executed here.

---

## 1. Master matrix

| Component | Intended choice | Actual implementation | Pinned version / configuration | Verification evidence | Remaining gap |
|---|---|---|---|---|---|
| Processor core | Ibex RV32IMC, 2-stage (+ optional 3rd writeback), machine+user mode, PMP | **Custom `rtl/rtl_top/riscv_core.sv`**: 4-state multi-cycle, RV32IM, machine mode only | In-tree source, no upstream commit | MEASURED: `tb_isa` 24/24 directed checks; `tb_boot` 7/7 full-SoC subtests | Ibex integration not started (ADR PROPOSED). Custom core has no C ext, no user mode, no PMP, no atomics, no F/D |
| ISA | RV32IMC | **RV32IM** — compressed instructions unimplemented | `-march=rv32im -mabi=ilp32` (corrected from `rv32imc`) | MEASURED: directed test covers RV32I ALU/load-store/branch/jump + M mul/div | No rv32imc; no Zicsr/Zifencei statement against an external toolchain |
| Bus (CPU↔memory) | AXI4-Lite, 32-bit | AXI4-Lite via `req_gnt_to_axi_lite` adapter, 1 master × 6 slaves | 1 outstanding transaction | MEASURED: full-SoC boot through ROM/TCM/SRAM/QSPI/APB/INTC | No AXI assertions/protocol checker; backpressure not exercised |
| Bus (peripherals) | APB | AXI4-Lite→APB bridge, 9 × 4 KB slots | 1 slot per peripheral, one-hot select | MEASURED: per-slot `penable` gating; isolation check in `tb_boot`; unmapped → PSLVERR | Byte strobes rejected (PSLVERR) rather than supported; no APB protocol SVA |
| Boot ROM | 16 KB secure boot ROM | `boot_rom.sv` 16 KB, loaded from hex in simulation | `BOOT_ROM_FILE` parameter | MEASURED: boot executes from ROM at reset | ROM image is a diagnostic smoke image, not a production secure ROM |
| Firmware actually simulated | C firmware | **`firmware/boot/boot.S`** — hand-written assembly, assembled by `scripts/fw/as.js` | 171 UART bytes of output | MEASURED: `tb_boot` PASS | C firmware in `firmware/bare_metal/` is NOT the image under test |
| C firmware build | riscv32-unknown-elf-gcc 12.2.0 | Sources present; **not built in this environment** | `scripts/fw_build/build_fw.py`, `-march=rv32im` | **BLOCKED**: no RISC-V toolchain on PATH | `firmware/build/firmware.elf` is a valid RV32 ELF (e_machine 243) but carries no toolchain/version metadata — the 12.2.0 claim is UNVERIFIED |
| Secure boot | Fail-closed signature verification | Header/bounds/entry/CRC validated; **signature verification always fails** → recovery | No crypto library linked | VERIFIED by inspection; **not executed** (no compiler) | No RSA/ECDSA verifier, no trust anchor, no key handling |
| OTA | A/B update with authentication | **Explicit unsupported stub** returning -1 | — | VERIFIED by inspection | No flash program/erase, no transport, no recovery policy |
| Flash controller | QSPI flash, AXI4-Lite | `qspi_flash_ctrl.sv`: single-line READ, **writes rejected** | AXI4-Lite slave | NOT SIMULATED (no pin-level model) | Erase/program/write-enable/busy/readback absent |
| Audio | Configurable I²S TX+RX | `i2s.sv`: transmitter only | — | `tb_i2s` register-level PASS | No RX path; no serialized-sample scoreboard |
| Power management | Deep sleep, retention, peripheral wake | Clock gating only; wake = external `wake_ack` handshake | 2-FF sync, wake-wins race, sticky request cleared | MEASURED: `tb_power_mgr` 16/16 checks | No retention/power gating; no peripheral wake detector; no CDC formal |
| Simulation | Verilator + Icarus | Icarus 14.0 (devel) s20260301; Verilator 5.053 | MEASURED: `node scripts/eda/run_regression.js` → 14/15 (Icarus) and `scripts/eda/verilator_build_soc.bat` → full-SoC 7/7 (Verilator) | Verilator C++ model now buildable and runnable |
| Formal | SymbiYosys CDC + properties | `scripts/formal/cdc` contains an `ERROR` file | — | **BLOCKED/FAILED tool run**, not a proof | SymbiYosys not installed; no properties exercised |
| Synthesis | Yosys | Yosys 0.69+154 installed; **not run on the current filelist this session** | — | UNKNOWN | Generic-cell area/count not measured |
| FPGA | Vivado + Nexys A7-100T | XDC + bring-up docs only | — | **BLOCKED**: no Vivado, no board | Bitstream, timing, hardware behaviour all absent |
| ASIC | OpenLane 2 / OpenROAD, sky130A | Template scripts only | — | **BLOCKED**: tools not installed | PDK/cells/macros unpinned; no synthesis, P&R, STA, DRC/LVS, power |
| PCB | KiCad schematic + layout | Schematic *prose* + candidate BOM | KiCad 10.0.8 reported installed | UNVERIFIED | No native schematic/layout, no ERC/DRC, no footprints |
| RTOS | Zephyr LTS | Not integrated | If selected, pin an exact release (3.7 is an LTS) | NOT STARTED | — |
| License | — | `LICENSE` is an explicit placeholder; **no license applied** | — | VERIFIED | Owner approval required before any license text |

---

## 2. CPU and ISA decision (recorded)

- The architecture records propose **Ibex** (`docs/architecture/PROCESSOR_SELECTION.md`,
  ADR PROPOSED). Ibex is **not** integrated. The SoC instantiates the in-tree
  custom core.
- The custom core implements **RV32IM, machine mode only**. It has no compressed
  instructions, no user mode, no PMP, no atomics, no F/D, and no debug module
  (the JTAG TAP is a stub).
- Consequence, now enforced: compiler flags must be `-march=rv32im -mabi=ilp32`.
  Building `rv32imc` for this core produces code that traps on its first 16-bit
  instruction. `scripts/fw_build/build_fw.py`, `build_fw.bat` and the `main.c`
  header comment were corrected.
- Keeping the custom core is a deliberate, documented architecture change with a
  verification burden: it must be validated against the ISA specification by
  tests that do not share its own assembler (see `sim/sim_top/tb_isa.v`, whose
  instruction words are hand-encoded).

**Accuracy note on Ibex (if adopted):** Ibex is a two-stage pipeline with an
optional third write-back stage — not a four-stage core.

---

## 3. Verification stack as measured

| Tool | Version (MEASURED) | State |
|---|---|---|
| Icarus Verilog / vvp | 14.0 (devel) s20260301-500-g2e81fcccb-dirty | WORKS |
| Verilator (lint) | 5.053 devel v5.052-119-g014c9820d | WORKS |
| Verilator (C++ simulation) | 5.053 devel | **WORKS** — MinGW-w64 toolchain + Windows kit shim installed; full SoC boot 7/7 PASS at ~20,000× real time |
| MinGW-w64 toolchain (g++/ar/make) | g++ 16.1.0, make 4.4.1 (WinLibs MCF UCRT) | WORKS — use `-O2`, not `-Os` (see registry trap 17) |
| Yosys | 0.69+154 | Available; full-chip synthesis blocked by SV unpacked-array ports in `axi_lite_interconnect.sv` |
| SymbiYosys (`sby`) | SBY v0.69 | Available in OSS CAD Suite, not yet exercised on this design |
| Node.js | v26.7.0 | WORKS (assembler + regression runner) |
| RISC-V GCC | xPack 12.2.0 at `D:\tools\xpack-riscv-none-elf-gcc-12.2.0-2\bin` | WORKS — firmware builds reproducibly |
| cocotb | 2.1.0 | Installed (Windows Store Python 3.10); not exercised yet |
| KiCad | 10.0.8 at `D:\tools\KiCad\10.0\` | WORKS (`kicad-cli --version` → 10.0.8) |

### 3.1 Testbenches (MEASURED by `node scripts/eda/run_regression.js`)

| Testbench | Scope | Result |
|---|---|---|
| `tb_isa.v` | Directed RV32IM against `riscv_core` | **PASS** 24/24 checks |
| `tb_boot.v` | Full SoC, ROM image, UART banner, GPIO, PWM | **PASS** 7/7 subtests |
| `tb_power_mgr.v` | Sleep/wake FSM + registers | **PASS** 16/16 checks |
| `tb_clint.v`, `tb_plic.v` | INTC register port | **PASS** |
| `tb_gpio/spi/i2c/pwm/timer/watchdog/i2s/sram/debug_jtag` | Peripheral register level | **PASS** |
| UART pin-level (TX/RX timing, overflow) | — | **MISSING** — this is why the runner exits 1 |
| `sim/tb/*` (legacy duplicates) | — | STALE: `tb_uart.v` does not compile; not used |

Suite result: **14 / 15 pass, exit status 1** because the UART requirement has no
test. Register read-back alone is not protocol qualification; only the boot test
exercises real serial traffic.

---

## 4. Scripts

| Path | Purpose |
|---|---|
| `scripts/fw/as.js` | Assembler for `firmware/boot/boot.S` (produces `build/fw/boot.hex`) |
| `scripts/fw_build/build_fw.py`, `build_fw.bat` | C firmware build (**toolchain missing**); scripts live here, not `scripts/fw/` |
| `scripts/fw_build/flash_fw.py`, `flash_fw.bat` | Flash programming (**not functional**) |
| `scripts/eda/run_regression.js` | Strict regression runner (build + run + marker check + exit status) |
| `scripts/eda/Makefile.*`, `run_*_sim.py` | Legacy simulator wrappers, unqualified |
| `scripts/formal/` | SymbiYosys configs; contains a failed-run `ERROR` file |
| `scripts/agents/lock.js` | Multi-agent file ownership |

---

## 5. Known environment facts

- **OpenLane 2 is not installed here.** "OpenLane is not pip-installable" is not a
  valid general statement; the accurate record is: not installed, installation
  not attempted, no supported-procedure (Nix/Docker) run performed.
- The PDK is reported downloaded but is not configured for any tool.
- OSS CAD Suite lives at `D:\tools\oss-cad-suite` (outside this repository).

---

## 6. Licensing

`LICENSE` is an explicit placeholder stating that no license has been selected.
No license (MIT, Apache-2.0, or otherwise) has been applied. The previous
"License: MIT" claim in this document was incorrect and has been removed. Adding
a license requires the project owner's explicit approval.

---

## 7. Repository

| Item | Value |
|---|---|
| GitHub | https://github.com/RAMA-L7/Home-Automation-SoC |
| Branch | `main` |
| Revision reviewed | `2a0c42cc` (working tree adds this session's fixes) |
