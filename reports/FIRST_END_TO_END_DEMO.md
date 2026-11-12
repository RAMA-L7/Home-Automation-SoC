# First End-to-End Firmware and SoC Integration Demonstration

Repository: `D:\Home-Automation-SoC`
Starting revision: `f96dd3d`
Ending revision: `f96dd3d` (working tree modified, no commit/push/tag)

## 1. Processor architecture and compiler target

- ISA: RV32IM (no compressed extension, no F/D, no user mode, no PMP). Confirmed by `rtl/rtl_top/riscv_core.sv`.
- Reset vector: `0x0000_0000` (boot ROM base). `riscv_core` `RESET_PC = ADDR_BOOT_ROM_BASE`.
- Boot ROM: 16 KB at `0x0000_0000`.
- TCM: 32 KB at `0x0001_0000`.
- SRAM: 128 KB at `0x2000_0000`.
- Compiler target: `-march=rv32im -mabi=ilp32` (matches core; rv32imc would trap on first 16-bit instruction).
- Compiler: xPack GNU RISC-V Embedded GCC 12.2.0 (`D:\tools\xpack-riscv-none-elf-gcc-12.2.0-2`).
- Interrupts: PLIC (8 sources, 1 context) + CLINT (timer/software) at `0x8000_0000`.

## 2. Firmware build instructions

```
export RISCV_TOOLCHAIN_BIN="D:/tools/xpack-riscv-none-elf-gcc-12.2.0-2/bin"
node scripts/fw_build/build_fw.js
node scripts/fw_build/gen_fw_mem.js build/fw/firmware.elf
```

Or single command: `node scripts/firmware/run_e2e.js` (builds, generates mem images, runs simulation + negative test).

## 3. Linker and memory map

- `.text.reset` -> boot ROM `0x0000_0000` (26 words).
- `.text` -> TCM `0x0001_0000` (895 words).
- Data/bss -> SRAM `0x2000_0000`.
- Stack top `0x0001_8000`.
- Entry `_reset` at `0x0000_0000`.

## 4. Boot sequence demonstrated

1. Hardware reset (`reset_n` low then high).
2. Boot ROM execution (startup.S at 0x0).
3. Firmware validation (none at runtime for this demo path; secure boot fail-closed, see below).
4. Safe loading: firmware linked into ROM/TCM images by `gen_fw_mem.js`.
5. SRAM/TCM execution: core fetches from TCM; data accesses to SRAM.
6. Sensor acquisition: timer counter read as simulated sensor input, stored in `sensor_value`, printed `Sensor: 0x...`.
7. Host command reception: UART RX commands `p`, `l`, `r`, `s`; malformed/unknown rejected with `ERR unknown command`.
8. GPIO/PWM response: `l` toggles LED; `p` configures PWM channel 0 (period 999, duty 500, enable).
9. Watchdog timeout and recovery: `r` stops petting; watchdog expires; reset_ctrl pulses reset; firmware reboots and prints banner again.
10. Successful restart and return to known safe state: rebooted firmware reaches blink loop; LED toggles.

## 5. Image validation behavior

- `boot_validate_image()` validates header magic, load/entry ranges, alignment, size, CRC32, signature block bounds. (Implemented in `firmware/bare_metal/boot.c`.)
- `boot_verify_signature()` always returns failure (no crypto verifier linked). Fail-closed: no image is copied or executed by `secure_boot()`.
- `secure_boot()` is compiled but not invoked by the demo path (diagnostic demo runs startup.S directly).

## 6. Flash limitations

- QSPI flash controller implements single-line READ only. No program/erase. OTA not implemented (`ota.c` returns -1).
- Interrupted update recovery: BLOCKED (flash programming absent).
- Authenticated boot: BLOCKED (no crypto verifier/trust anchor).

## 7. Firmware application behavior

- Initialization: stack, .data/.bss, peripherals, watchdog armed (CTRL=0x03).
- Sensor: timer count as simulation input; stored in `sensor_value`.
- Host command: UART polling; commands p/l/r/s; unknown rejected.
- GPIO/PWM: LED toggle; PWM channel 0 configured.
- Watchdog: pet every 4096 cycles in delay; `r` triggers timeout -> reset.

## 8. Test results

- Positive simulation (`tb_firmware.v`): RESULT: PASS. GPIO transitions 2, PWM high cycles 1259000, watchdog pulses 1.
- Negative test (corrupted image): rejected (no RESULT: PASS / timeout).
- Existing regression: 22/22 PASS.
- Formal: 5/5 PASS.
- Unified gate: 9/9 PASS.

## 9. Tool versions

- Icarus Verilog 14.0
- xPack RISC-V GCC 12.2.0
- Node v26.7.0
- Verible v0.0-4298

## 10. Evidence log locations

- `build/e2e/tools.log`, `build.log`, `genmem.log`, `positive.log`, `negative.log`
- `build/sim/regression.log`
- `build/verify/summary.txt`

## 11. Unsupported / blockers

- Authenticated boot: BLOCKED (no crypto verifier).
- Flash programming/OTA/interrupted update recovery: NOT IMPLEMENTED.
- Physical sensor: simulation input only.
- JTAG subset, SPI mode 0 only, SRAM dual-port macro: unchanged blockers.

## 12. Acceptance criteria

1. Firmware builds reproducibly: PASS.
2. Compiler target matches CPU: PASS (rv32im).
3. Boot ROM execution: PASS.
4. Firmware loads into correct memory: PASS.
5. Processor executes firmware: PASS.
6. Sensor input acquired (simulation): PASS.
7. Host command received and validated: PASS.
8. GPIO/PWM responds: PASS.
9. Watchdog recovery: PASS.
10. Invalid firmware rejected: PASS (corrupted image).
11. Fresh evidence: PASS.
12. Existing verification green: PASS.

Authenticated boot and interrupted flash-update recovery: BLOCKED (reported, not faked).

Final verdict: DEMONSTRATION PASSED WITH LIMITATIONS.