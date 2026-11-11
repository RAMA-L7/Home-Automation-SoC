# Independent Review — Home-Automation-SoC

**Date:** 2026-11-11
**Reviewer:** Buffy (independent re-review)
**Repository:** https://github.com/RAMA-L7/Home-Automation-SoC
**Revision reviewed:** `2a0c42cc` (HEAD) plus an uncommitted working tree of fixes
described in §A. Where a finding cites a line number, that is the line in the
current working tree.

**Evidence labels:** VERIFIED / DOCUMENTED / MEASURED / ESTIMATED / ASSUMED /
UNKNOWN / BLOCKED. Nothing below is claimed as FPGA, silicon, timing, power or
coverage evidence.

---

## A. Revision, changes made, remaining blockers

### A.1 Revision

```
$ git rev-parse HEAD
2a0c42ccc760d043d43ce63b65abcdd9adfeeed9
$ git log --oneline -1
2a0c42c Add TECH_STACK.md — complete tech stack inventory
$ git status --porcelain   (only the files listed in A.2 are modified)
```

### A.2 Changes made in this review (all uncommitted)

| File | Change |
|---|---|
| `rtl/rtl_top/riscv_core.sv` | AUIPC now uses `pc`; `SRA` hoisted out of the mixed-signedness ternary; signed-overflow special case restricted to DIV/REM |
| `rtl/rtl_top/has_soc.sv` | Partial-strobe APB writes rejected with `PSLVERR`; power-manager `wake_clear` wired; watchdog moved to the ungated clock |
| `rtl/rtl_peripherals/power_mgr.sv` | 2-FF `wake_ack` synchronizer, wake-wins-sleep race, `wake_event` output |
| `rtl/rtl_peripherals/power_mgr_regs.sv` | `wake_clear` input clears the sticky sleep request |
| `firmware/boot/boot.S` | New isolation assertion (PM_CTRL must stay 0 and GPIO must keep its value after other slots were accessed) |
| `firmware/bare_metal/boot.c`, `boot.h` | Fail-closed secure boot: returns a result, validates range/entry/alignment/partition/signature block, never executes an unverified image |
| `firmware/bare_metal/ota.c` | Explicit unsupported result; no fake verification, no boot-flag write |
| `firmware/bare_metal/main.c` | ISA comment corrected to `rv32im` |
| `scripts/fw_build/build_fw.py`, `build_fw.bat` | `-march=rv32im` (was `rv32imc`); `.bat` source list aligned with `.py` |
| `sim/sim_top/tb_isa.v` | **New** directed RV32IM test, hand-encoded words, independent of `as.js` |
| `sim/sim_top/tb_boot.v` | `$fatal` on failure/timeout; requires 7/7 subtests |
| `sim/sim_top/tb_power_mgr.v` | **Rewritten**: sleep/wake FSM coverage (16 checks) |
| `sim/sim_top/tb_clint.v`, `tb_plic.v` | Adapted to the current register port; `$fatal` on failure |
| 9 peripheral testbenches | `$dumpfile` path fixed (they previously aborted before running) |
| `scripts/eda/run_regression.js` | **New** strict runner: build + run + marker + exit status |
| `TECH_STACK.md`, `README.md`, `reports/MASTER_PROJECT_STATUS.md`, `docs/requirements/performance_requirements.md` | Corrected to measured evidence; impossible targets reconciled |

### A.3 Remaining blockers

| Blocker | Effect |
|---|---|
| No RISC-V GCC toolchain on `PATH` (VERIFIED absent) | C firmware cannot be built or executed; all firmware evidence is the assembly image |
| No `g++`/`make` | Verilator can lint but not build a C++ model; Icarus is the only simulator |
| No SymbiYosys | No formal properties; the committed `scripts/formal/cdc/ERROR` is a failed tool run, not a counterexample |
| No Vivado, no Nexys A7 board | No FPGA implementation or hardware evidence |
| No OpenLane/OpenROAD/Magic/Netgen, PDK unconfigured | No ASIC synthesis, P&R, STA, DRC/LVS, power |
| No KiCad native files | PCB remains schematic prose + candidate BOM |

---

## B. Findings, ordered by severity

Status is either **FIXED (MEASURED)** (reproduced, corrected, and covered by a
test that was run) or **OPEN**.

### B.1 Critical

| # | Finding | Location | Status |
|---|---|---|---|
| C1 | `auipc` added `rs1+imm_u` instead of `pc+imm_u`; every PC-relative address was wrong | `riscv_core.sv:133` | **FIXED (MEASURED)** — `tb_isa` checks `auipc x10,1` at `0x03C` = `0x0000103C` |
| C2 | `srai` executed as a **logical** shift: the arithmetic shift was written inline in a ternary whose other arm is unsigned, so the tool unified it to unsigned. `srai(-8,28)` returned `0x0000000F` | `riscv_core.sv:161` | **FIXED (MEASURED)** — shift results hoisted into typed wires; test expects `0xFFFFFFFF` |
| C3 | Secure boot printed "Signature verified (placeholder)", warned and **continued** on a missing signature, and executed the image. Authentication was decorative | `boot.c` (pre-review) | **FIXED (VERIFIED by inspection)** — `boot_verify_signature()` returns failure unconditionally; `secure_boot()` enters recovery; nothing is copied or jumped to |
| C4 | OTA discarded every payload byte, printed "signature verified", and set the boot flag — a guaranteed-bricking "success" | `ota.c` (pre-review) | **FIXED (VERIFIED by inspection)** — returns `-1`, consumes nothing, leaves the boot flag alone |
| C5 | Header validation accepted a destination at the end of SRAM, did not check entry, did not require word-aligned size, and would copy whole words from an unchecked range | `boot.c` (pre-review) | **FIXED (VERIFIED by inspection)** — `boot_range_ok()`, entry-in-image check, partition bounds, signature-block bounds; overflow-safe by subtraction |
| C6 | The C firmware was built `-march=rv32imc` for a core with **no compressed-instruction support** | `build_fw.py:25`, `build_fw.bat:31` | **FIXED** — `rv32im`; documented in TECH_STACK |
| C7 | A failing simulation left the process exit status at 0: the boot test called `$finish` after printing FAIL | `sim/sim_top/tb_boot.v` | **FIXED (MEASURED)** — pass run exits 0; a deliberately broken run exits 1 |
| C8 | Nine peripheral testbenches never executed at all: they aborted at `$dumpfile("../waveforms/…")`, a missing directory — and still exited 0. The "13 Icarus tests PASSED" claim was therefore unsupported | `sim/sim_top/tb_*.v` | **FIXED (MEASURED)** — paths corrected, benches now run and pass |
| C9 | Partial-strobe writes silently became full-word writes: `pstrb` is an unused port in all nine peripherals | `rtl/rtl_peripherals/*.sv` | **MITIGATED (MEASURED)** — partial writes now complete with `PSLVERR` and have no side effect (`has_soc.sv`) |
| C10 | `divu`/`remu` of `0x80000000` by `0xFFFFFFFF` returned the **signed** overflow result `0x80000000` instead of `0` | `riscv_core.sv:218` | **FIXED (MEASURED)** — special case restricted to DIV/REM; test expects `0` and `0x80000000` |
| C11 | Handshake deadlock: the APB bridge required AW and W in the same cycle | `axi_lite_to_apb.sv:70,87` | **FIXED (MEASURED)** — independent latching; boot reaches the peripheral bus |
| C12 | Read data collapsed to one bit: `m_rdata = state && s_rdata[sel]` | `axi_lite_interconnect.sv` | **FIXED (MEASURED)** — every load returned `0x00000001` before this |
| C13 | All peripherals saw every APB access; a UART THR write also hit the power manager and gated the core clock | `has_soc.sv:467-495` | **FIXED (MEASURED)** — per-slot `penable`; explicit isolation assertion in `boot.S` |
| C14 | Stores used the I-type immediate and `OP_IMM` was forced through the adder | `riscv_core.sv` | **FIXED (MEASURED)** in the preceding session; covered by `tb_isa` and `tb_boot` |

### B.2 High (OPEN)

| # | Finding | Location | Impact |
|---|---|---|---|
| H1 | **No cryptographic verifier and no trust anchor.** Secure boot fails closed, which is safe but means no image can ever boot from the C firmware path | `boot.c:102` | Secure boot is *not implemented* as a feature; it is only fail-closed |
| H2 | **Watchdog cannot reset the SoC internally.** `wdog_reset_n_out` is an output pin only; `has_soc.reset_n` is not combined with it | `has_soc.sv` watchdog instance | The reset supervision the requirements assume exists only if the board wires it back |
| H3 | **Flash controller is read-only** (single-line READ, writes rejected) | `qspi_flash_ctrl.sv` | No update path is physically possible; OTA is blocked on this |
| H4 | **No UART protocol test.** No TX/RX timing, sustained traffic, overflow or mid-blocking-command coverage | `sim/sim_top/` | The regression runner exits 1 for this missing test |
| H5 | **BUS errors are not consumed by the core.** Unmapped APB accesses return `PSLVERR` → AXI `SLVERR`, but the core ignores `rresp`/`bresp` | `riscv_core.sv` data interface | Bad accesses return data with no fault; no load/store access fault exists |
| H6 | **Misaligned loads/stores neither trap nor fault**; `lh`/`lw` at an odd address silently byte-rotate | `riscv_core.sv` load/store shaping | Silently wrong data instead of an architectural exception |
| H7 | **No instruction-address-misaligned exception**; `jalr` masks bit 0 only | `riscv_core.sv` `pc_next` | Jumps to a 2-byte-aligned address execute the wrong halfword on a non-C core |
| H8 | **Stale duplicate testbenches** in `sim/tb/` (`tb_uart.v` does not compile; `tb_integration.v`, `tb_has_soc.v` unqualified) | `sim/tb/` | Easy to mistake for coverage |
| H9 | **No formal property is exercised.** `scripts/formal/cdc/ERROR` records a failed tool invocation, not a proof | `scripts/formal/` | None of the fixed handshakes has an assertion |
| H10 | **No synthesis has been run on the current filelist** | — | No area, no cell count, no synthesizability check |

### B.3 Medium

| # | Finding | Status |
|---|---|---|
| M1 | Power manager had no `wake_ack` synchronizer and no protection against re-entering sleep from a sticky request | **FIXED (MEASURED)** — 2-FF sync, `wake_event` clears the request; `tb_power_mgr` 16/16 |
| M2 | Watchdog ran on the gated peripheral clock, so sleep silently disabled it | **FIXED** — moved to the ungated clock |
| M3 | No peripheral wake detector; wake is the external handshake only | OPEN (documented) |
| M4 | No quiesce handshake before gating `core_clk`; gating can occur with a transaction in flight | OPEN |
| M5 | I²S is transmit-only; no receive path, no serialized-sample scoreboard | OPEN |
| M6 | No retention mode, no power gating, no measured low power | OPEN (do not claim deep sleep) |
| M7 | Requirements asserted impossible targets (50 MB/s single-bit SDR flash; 16-bit PWM at 1 MHz; LPTIM; UART FIFOs) | **FIXED** — reconciled with arithmetic in `performance_requirements.md` |
| M8 | Docs claimed 13 passing tests, gcc 12.2.0 compilation, MIT licensing and a broken Icarus runtime | **FIXED** — corrected in TECH_STACK/README/status report |
| M9 | `docs/architecture/PROCESSOR_SELECTION.md` proposes Ibex (2-stage + optional writeback), but the SoC instantiates the custom core | DOCUMENTED; decision still PROPOSED |

---

## C. Requirement → implementation → verification

| Requirement | Implementation | Verification | Verdict |
|---|---|---|---|
| RV32IM execution | `riscv_core.sv` (custom, multi-cycle) | `tb_isa` 24/24; `tb_boot` 7/7 | PASS (simulation) |
| Compressed instructions | none | — | NOT IMPLEMENTED (ISA narrowed to RV32IM) |
| Machine-mode traps + PLIC interrupt | core CSRs, `plic.sv`, `clint.sv` | `tb_boot` PLIC subtest | PASS (simulation) |
| Peripheral address isolation | per-slot `penable` in `has_soc.sv` | `tb_isa`? no — `tb_boot` isolation assertion | PASS (simulation) |
| Unmapped access rejected without hanging | `PSLVERR` on no slot | not directly tested | PARTIAL |
| Byte-granular register access | rejected with `PSLVERR` | not tested | NOT IMPLEMENTED (safe rejection only) |
| UART serial communication | `uart.sv`, 171 bytes in boot | `tb_boot` decodes the stream | PASS (simulation) |
| SPI/I²C protocol | register block only | register read-back | NOT QUALIFIED |
| I²S audio | TX only | register read-back | NOT QUALIFIED |
| Sleep / wake | `power_mgr` + regs | `tb_power_mgr` 16/16 | PASS (simulation) |
| Watchdog resets the SoC | pin output only | — | NOT IMPLEMENTED |
| Secure boot | fail-closed validation, no verifier | inspection only | FAIL CLOSED (not qualified) |
| OTA / A-B update | explicit unsupported | inspection | NOT IMPLEMENTED |
| Flash write | rejected | — | NOT IMPLEMENTED |
| Timing / area / power | — | — | NO EVIDENCE |
| FPGA / ASIC / PCB | scripts and prose | — | NO EVIDENCE |

---

## D. Executed commands, tools, results

### D.1 Tool versions (MEASURED)

```
iverilog / vvp : Icarus Verilog 14.0 (devel) s20260301-500-g2e81fcccb-dirty
verilator      : Verilator 5.053 devel v5.052-119-g014c9820d (lint only)
yosys          : Yosys 0.69+154   (installed; not run on the filelist)
node           : v26.7.0
riscv gcc      : NOT FOUND
```

### D.2 Commands and results

```bash
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"

# Directed ISA test (hand-encoded words, independent of the custom assembler)
iverilog -g2012 -o build/sim/tb_isa.vvp -s tb_isa sim/sim_top/tb_isa.v \
         rtl/rtl_top/riscv_core.sv
vvp build/sim/tb_isa.vvp
#   [isa] checks: 24, failures: 0
#   [isa] RESULT: PASS                       exit 0

# Full-SoC boot
node scripts/fw/as.js firmware/boot/boot.S build/fw/boot.hex build/fw/boot.lst
iverilog -g2012 -o build/sim/tb_boot.vvp -s tb_boot sim/sim_top/tb_boot.v \
         $(grep -v '^//' rtl/filelist.f | tr '\n' ' ')
vvp build/sim/tb_boot.vvp
#   summary pass=00000007 fail=00000000
#   RESULT: ALL TESTS PASSED
#   [tb] firmware subtests passed: 7 / 7
#   [tb] RESULT: PASS                        exit 0

# Negative control: one expected string deliberately broken
#   NEGATIVE_CASE_EXIT=1                     (failure now fails the process)

# Whole suite
node scripts/eda/run_regression.js
#   PASS 14 / 15  (uart has no testbench)    exit 1
```

### D.3 Lint

```
verilator_bin.exe --lint-only -sv --top-module has_soc $(cat rtl/filelist.f)
%Error-*: none
warnings: 14  (CASEINCOMPLETE×5, WIDTHEXPAND×3, WIDTHTRUNC×2,
               UNSIGNED×2, BLKSEQ×1, EOFNEWLINE×1)
```

### D.4 Failures and unrun checks (explicit)

| Item | Result |
|---|---|
| C firmware build (`scripts/fw_build/build_fw.py`) | **BLOCKED** — no RISC-V toolchain |
| `firmware/build/firmware.elf` provenance | **UNKNOWN** — valid RV32 ELF (`e_machine` 243) with no compiler/version metadata; the "gcc 12.2.0" claim is not reproducible |
| Yosys synthesis | **NOT RUN** |
| SymbiYosys / formal | **BLOCKED** — not installed; committed `ERROR` is a failed run |
| Verilator C++ simulation | **BLOCKED** — no `g++`/`make` |
| UART/S PI/I²C/I²S protocol qualification | **NOT RUN** — no device models or scoreboards |
| FPGA / ASIC / PCB | **NOT RUN** — tools and hardware absent |
| `sim/tb/tb_uart.v` | **FAILS TO COMPILE** (stale duplicate) |

---

## E. Documents updated to agree with the evidence

| Document | Correction |
|---|---|
| `TECH_STACK.md` | Rewritten as intended/actual/pinned/evidence/gap; Ibex described accurately (2-stage + optional writeback); flash corrected to AXI4-Lite and read-only; MIT claim removed; Icarus "broken runtime" claim withdrawn; `scripts/fw_build/` paths; OpenLane statement replaced with the actual environment fact |
| `README.md` | Status replaced: what is measured versus what is not; core is the custom RV32IM core; firmware is an assembly smoke image |
| `reports/MASTER_PROJECT_STATUS.md` | Correction banner: test-count claim, gcc claim, warning count, security/OTA status |
| `docs/requirements/performance_requirements.md` | Impossible targets corrected with arithmetic (QSPI SDR/DDR, PWM resolution, UART FIFOs, LPTIM) |

---

## F. Prioritized remaining work

### F.1 Immediate functional corrections

1. **Watchdog reset path** — combine `wdog_reset_n_out` into the SoC reset (or make the external connection an explicit, documented board requirement).
2. **Core error handling** — consume `rresp`/`bresp` as a load/store access fault; add misaligned-address exceptions and an instruction-address-misaligned check for `jalr`/branches.
3. **UART FIFO + pin-level test** — the throughput requirement presumes FIFOs that do not exist; either implement them or lower the requirement.
4. **Flash program/erase** — required before any OTA story is real.
5. **Real signature verification** — pin a maintained crypto implementation and an immutable ROM trust anchor, then authenticate all metadata (length, destination, entry, version, board id).

### F.2 Further verification

6. Pin-level device models for SPI flash and I²C slaves; an I²S serializer scoreboard.
7. SVA for the handshakes just fixed (AW/W independence, `rdata` width, one-hot `apb_sel`, clock gating, wake/sleep).
8. Compare architectural state against an independent reference model (e.g. Spike) rather than only directed expectations.
9. Run the suite under Verilator once a C++ toolchain exists.

### F.3 FPGA demonstration

10. Confirm board/device, run Vivado synthesis and implementation, validate XDC pin/voltage/clocking, record bitstream revision and hardware evidence.

### F.4 ASIC physical implementation

11. Pin PDK, standard cells, SRAM/ROM macros, IO cells, clock gates, tools and corners; map memories to real macros; produce synthesis, P&R, STA, DRC/LVS and power evidence. No RTL-to-GDS run equals foundry approval.

### F.5 Carrier / package completion

12. Cross-check RTL ports against the QFN-64 pinout; resolve QSPI, UART count, clock in, reset/wake, boot straps and unused pins; native schematic/layout, ERC/DRC, BOM review.

### F.6 External approvals

13. CPU architecture decision (Ibex vs custom), license selection, crypto library and key-management policy, board/vendor commitments.

---

## G. Completion classification

| Area | Classification |
|---|---|
| RTL functional correctness (RV32IM core) | **Simulation-verified** for directed cases; no formal, no reference-model comparison |
| Full-SoC integration | **Simulation-verified** end to end for one hand-written assembly image |
| Peripheral blocks | **Register-level verified**; no protocol qualification |
| Power/sleep | **Simulation-verified** for the implemented clock-gating mode only; no retention, gating or measured power |
| Secure boot | **Fail-closed but unimplemented** — cannot be called a security feature |
| OTA / update / recovery | **Not implemented** (explicit unsupported) |
| Firmware (C) | **Unbuilt and unexecuted** in this environment |
| FPGA | **No evidence** |
| ASIC | **No evidence** |
| PCB | **No evidence** (prose and a candidate BOM) |

**Overall:** the project is a **functional RTL prototype with simulation evidence
for a diagnostic boot path**, not a verified home-automation controller, and not
a secure-boot implementation. The next milestone (reset → authenticated flash
image → SRAM execution → sensor acquisition → host command → GPIO/PWM response →
watchdog recovery) cannot be reached until §F.1 items 1–5 are done.
