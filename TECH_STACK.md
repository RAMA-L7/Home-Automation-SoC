# Home-Automation-SoC — Tech Stack

**Project:** Low-power residential home-automation RISC-V SoC
**Target:** QFN-64 package, SkyWater 130nm (sky130) ASIC / Nexys A7-100T FPGA
**Document version:** 2.1 — toolchain state re-verified 2026-11-12
**Reviewed revision:** `6ae07b1` (tag `v0.9.0-regression-17-17`)

This document separates four things that were previously mixed together:
what is **intended**, what is **actually implemented**, what is **pinned**, and
what has **evidence**. Evidence labels: VERIFIED / DOCUMENTED / MEASURED /
ESTIMATED / ASSUMED / UNKNOWN / BLOCKED.

> Nothing in this project is FPGA- or silicon-verified. Simulation evidence
> covers the RTL, a hand-written assembly smoke ROM, and (since 2026-11-12) the
> compiled C firmware running end to end on the RTL SoC in `tb_firmware.v`.
> Every EDA tool for this project lives under `D:\tools`; the full inventory is
> `D:\tools\EDA_TOOL_REGISTRY.md`.

---

## 1. Master matrix

| Component | Intended choice | Actual implementation | Pinned version / configuration | Verification evidence | Remaining gap |
|---|---|---|---|---|---|
| Processor core | Ibex RV32IMC, 2-stage (+ optional 3rd writeback), machine+user mode, PMP | **Custom `rtl/rtl_top/riscv_core.sv`**: 4-state multi-cycle, RV32IM, machine mode only | In-tree source, no upstream commit | MEASURED: `tb_isa` 24/24 directed checks; `tb_boot` 7/7 full-SoC subtests | Ibex integration not started (ADR PROPOSED). Custom core has no C ext, no user mode, no PMP, no atomics, no F/D |
| ISA | RV32IMC | **RV32IM** — compressed instructions unimplemented | `-march=rv32im -mabi=ilp32` (corrected from `rv32imc`) | MEASURED: directed test covers RV32I ALU/load-store/branch/jump + M mul/div | No rv32imc; no Zicsr/Zifencei statement against an external toolchain |
| Bus (CPU↔memory) | AXI4-Lite, 32-bit | AXI4-Lite via `req_gnt_to_axi_lite` adapter, 1 master × 6 slaves | 1 outstanding transaction | MEASURED: full-SoC boot through ROM/TCM/SRAM/QSPI/APB/INTC | No AXI assertions/protocol checker; backpressure not exercised |
| Bus (peripherals) | APB | AXI4-Lite→APB bridge, 9 × 4 KB slots | 1 slot per peripheral, one-hot select | MEASURED: per-slot `penable` gating; isolation check in `tb_boot`; unmapped → PSLVERR | Byte strobes rejected (PSLVERR) rather than supported; no APB protocol SVA |
| Boot ROM | 16 KB secure boot ROM | `boot_rom.sv` 16 KB, loaded from hex in simulation | `BOOT_ROM_FILE` parameter | MEASURED: boot executes from ROM at reset | ROM image is a diagnostic smoke image, not a production secure ROM |
| Firmware actually simulated | C firmware | **Both** images are exercised: `firmware/boot/boot.S` (ROM smoke image, assembled by `scripts/fw/as.js`) in `tb_boot.v`, and the compiled C firmware (`firmware/bare_metal/*`) in `tb_firmware.v` | boot.S: 171 UART bytes; C image: 302 UART bytes, 35.7 ms simulated | MEASURED: `tb_boot` 7/7 PASS; `tb_firmware` PASS (banner → UART command → watchdog reset → reboot → LED) | `secure_boot()` is compiled but never called by the demo, so fail-closed boot is still untested at runtime |
| C firmware build | riscv-none-elf-gcc 12.2.0 | **Built here**: `build/fw/firmware.elf`, text 3,168 B, `-march=rv32im -mabi=ilp32` | `scripts/fw_build/build_fw.js` + `gen_fw_mem.js` (Node; `build_fw.py` cannot run — no usable `python`) | MEASURED: toolchain at `D:\tools\xpack-riscv-none-elf-gcc-12.2.0-2\bin`, gcc 12.2.0; ELF loaded into TCM by the simulation | No hosted libc, no floating point, no linker-map review for stack depth |
| Secure boot | Fail-closed signature verification | Header/bounds/entry/CRC validated; **signature verification always fails** → recovery | No crypto library linked | VERIFIED by inspection; **not executed** — `main.c` never calls `secure_boot()` | No RSA/ECDSA verifier, no trust anchor, no key handling |
| OTA | A/B update with authentication | **Explicit unsupported stub** returning -1 | — | VERIFIED by inspection | No flash program/erase, no transport, no recovery policy |
| Flash controller | QSPI flash, AXI4-Lite | `qspi_flash_ctrl.sv`: single-line READ, **writes rejected** | AXI4-Lite slave | NOT SIMULATED (no pin-level model) | Erase/program/write-enable/busy/readback absent |
| Audio | Configurable I²S TX+RX | `i2s.sv`: transmitter only | — | `tb_i2s` register-level PASS | No RX path; no serialized-sample scoreboard |
| Power management | Deep sleep, retention, peripheral wake | Clock gating only; wake = external `wake_ack` handshake | 2-FF sync, wake-wins race, sticky request cleared | MEASURED: `tb_power_mgr` 16/16 checks | No retention/power gating; no peripheral wake detector; no CDC formal |
| Simulation | Verilator + Icarus | Icarus 14.0 (devel) s20260301; Verilator 5.053 | MEASURED: `node scripts/eda/run_regression.js` → **17/17 PASS** (Icarus) and `scripts/eda/verilator_build_soc.bat` → full-SoC 7/7 (Verilator) | No functional coverage, no SVA protocol checkers, no CDC run |
| Formal | SymbiYosys CDC + properties | `scripts/formal/cdc` still contains an `ERROR` file | SymbiYosys available (native SBY v0.69 + WASM build) | **FAILED tool run**, not a proof | No property has been proven; CDC config never completed |
| Synthesis | Yosys | Yosys 0.69+154 installed; core-only synthesis ran (226 cells, 0 errors) | — | MEASURED for `riscv_core.sv` only | Full-chip synthesis blocked by unpacked-array ports in `axi_lite_interconnect.sv` |
| FPGA | Vivado + Nexys A7-100T | XDC + bring-up docs only | — | **BLOCKED**: no Vivado, no board | Bitstream, timing, hardware behaviour all absent |
| ASIC | OpenLane 2 / OpenROAD, sky130A | Template scripts only | OpenLane 2 v2.0.0b16 (`D:\tools\venv-openlane2`), OpenROAD, OpenSTA 3.1.0, Magic 8.3.105, Netgen 6.2.2401, KLayout 0.30.13, volare 0.20.6 | **NOT_TESTED** — no flow has been run | PDK not volare-enabled for OpenLane 2; no synthesis, P&R, STA, DRC/LVS, power results |
| PCB | KiCad schematic + layout | Schematic *prose* + candidate BOM | KiCad 10.0.8 at `D:\tools\KiCad\10.0` (`kicad-cli --version` → 10.0.8, VERIFIED) | UNVERIFIED — no project files | No native schematic/layout, no ERC/DRC, no footprints |
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
| Verible lint/format | v0.0-4298-g085eef05 | WORKS (`D:\tools\verible\`) |
| Yosys (portable/WASM) | 0.70.0.0.post1259 | WORKS (`D:\tools\venv\`, `D:\tools\venv-wsl\`) |
| SymbiYosys (portable/WASM) | SBY v0.69 | WORKS (`D:\tools\venv\`, `D:\tools\venv-wsl\`) |
| cocotb | 2.1.0 | Installed in `D:\tools\venv\` |
| Yosys (native, Windows) | 0.69+154 | Available; full-chip synthesis blocked by SV unpacked-array ports in `axi_lite_interconnect.sv` |
| Yosys (native, WSL) | 0.33 (apt) | Available but too old for the ORFS flow — use the WASM 0.70 build instead |
| SymbiYosys (native) | SBY v0.69 | Available in OSS CAD Suite |
| Node.js | v26.7.0 | WORKS (assembler + regression runner) |
| RISC-V GCC | xPack 12.2.0 at `D:\tools\xpack-riscv-none-elf-gcc-12.2.0-2\bin` | WORKS — firmware builds reproducibly |
| KiCad | 10.0.8 at `D:\tools\KiCad\10.0\` | WORKS (`kicad-cli --version` → 10.0.8) |
| OpenLane 2 | v2.0.0b16 at `D:\tools\venv-openlane2\` | **CLI RUNNABLE** — end-to-end flow NOT_TESTED (needs volare-enabled sky130A PDK + flow-compatible OpenROAD) |
| Magic (DRC) | 8.3.105 at `D:\tools\magic\` | **RUNNABLE** (WSL) — sky130 Magic tech file not in the local PDK |
| Netgen (LVS) | 6.2.2401 at `D:\tools\netgen\` | **RUNNABLE** (WSL) |
| volare | 0.20.6 | **RUNNABLE** (WSL, `D:\tools\venv-openlane2\`) |
| KLayout | 0.30.13 | RUNNABLE (WSL) |
| OpenROAD / OpenSTA | bazel-nostamp / 3.1.0 | RUNNABLE (WSL) |

All 31 tools are verified functional (16 Windows + 15 WSL, 0 failures) by
`D:\tools\verify_tools.bat` and `D:\tools\verify_tools_wsl.sh`. The full
inventory with exact paths and known limitations lives in
`D:\tools\EDA_TOOL_REGISTRY.md`.

Re-run directly on 2026-11-12 (VERIFIED): `g++ 16.1.0`, `make 4.4.1`,
`verible-verilog-lint v0.0-4298-g085eef05`, `kicad-cli 10.0.8`, `SBY v0.69`,
`Verilator 5.053 devel`, `yowasp-yosys 0.70`, `Python 3.10.11`. Magic, Netgen,
OpenROAD, OpenSTA, KLayout and volare are WSL-only and were **not** re-run in this
check; their entries are DOCUMENTED from the registry and `verify_tools_wsl.sh`.

### 3.1 Testbenches (MEASURED by `node scripts/eda/run_regression.js`)

| Testbench | Scope | Result |
|---|---|---|
| `tb_isa.v` | Directed RV32IM + trap program against `riscv_core` | **PASS** — 24/24 directed + 47/47 trap checks |
| `tb_boot.v` | Full SoC, ROM image, UART banner, GPIO, PWM | **PASS** 7/7 subtests |
| `tb_uart.v` | UART at pin level (TX/RX timing, LSR flags, overflow) | **PASS** 153/153 checks |
| `tb_reset_ctrl.v` | Watchdog timeout → bounded `rst_sys_n` pulse | **PASS** 15/15 checks |
| `tb_power_mgr.v` | Sleep/wake FSM + registers | **PASS** 16/16 checks |
| `tb_firmware.v` | Compiled C firmware on the RTL SoC: banner, UART RX, watchdog reset, reboot, LED | **PASS** — reset at 20.005 ms, reboot, 2 LED edges |
| `tb_clint.v`, `tb_plic.v` | INTC register port | **PASS** |
| `tb_gpio/spi/i2c/pwm/timer/watchdog/i2s/sram/debug_jtag` | Peripheral register level | **PASS** |
| `sim/tb/*` (legacy duplicates) | — | STALE: superseded by `sim/sim_top/`; not used |

Suite result: **17 / 17 pass, exit status 0**. Register read-back alone is not
protocol qualification, so the UART is additionally tested at pin level and the
C-firmware demo exercises real serial traffic.

---

## 4. Scripts

| Path | Purpose |
|---|---|
| `scripts/fw/as.js` | Assembler for `firmware/boot/boot.S` (produces `build/fw/boot.hex`) |
| `scripts/fw_build/build_fw.js`, `gen_fw_mem.js` | **Working** C firmware build driver (Node) → `build/fw/firmware.elf`, `rom.hex`, `tcm.hex` |
| `scripts/fw_build/build_fw.py`, `build_fw.bat` | Same build in Python; **cannot run here** (no usable `python` — the only `python` on PATH is the Windows Store stub) |
| `scripts/fw_build/flash_fw.py`, `flash_fw.bat` | Flash programming (**not functional**) |
| `scripts/eda/run_regression.js` | Strict regression runner (build + run + marker check + exit status) |
| `scripts/eda/Makefile.*`, `run_*_sim.py` | Legacy simulator wrappers, unqualified |
| `scripts/formal/` | SymbiYosys configs; contains a failed-run `ERROR` file |
| `scripts/agents/lock.js` | Multi-agent file ownership |

---

## 5. Known environment facts

- **OpenLane 2 v2.0.0b16 is installed** at `D:\tools\venv-openlane2` and its CLI
  runs, but **no flow has been executed**: the sky130A PDK is present yet not
  volare-enabled in a form the flow can drive. "OpenLane is not pip-installable"
  is not a valid general statement — this install came from source under
  `D:\tools\src\openlane2`.
- The PDK is downloaded but not configured for any synthesis/P&R tool.
- The host C++ toolchain (MinGW-w64 g++ 16.1.0 + make 4.4.1) and the Verilator kit
  shim are installed, so Verilator C++ simulation works; build Verilator models
  with `-O2`, not `-Os`.
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
