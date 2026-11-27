# Production boot path — qualification

**Tested commit:** `b5e0642` (see `research/runs/RUN-0026-external-review-2026-11-27/`)
**Status:** the preload-free boot path EXISTS and is verified in simulation.
Flash boot is **BLOCKED** and is not claimed.

---

## 1. What was wrong

Every boot test in this tree ran with `-DSIM_MEM_PRELOAD`, which made
`sim/models/sky130_sram_sim_model.v` (and, before it, the behavioural
`sram.sv`) `$readmemh` the firmware image straight into the TCM and SRAM arrays
at time 0. That is a testbench convenience. A real sky130 SRAM macro has **no
init port**: it powers up undefined, and the RTL had nothing that ever put code
into it.

So "the SoC boots the C demo" was, strictly, "the simulator initialised the
memories and the CPU happened to run from TCM". Counting that as hardware
initialisation was the defect.

## 2. What the design does now

`firmware/boot/loader.S` runs from the boot ROM at `0x0000_0000` and, in order:

1. sets `sp` to the top of TCM (`0x0001_8000`),
2. copies the `.text`/`.rodata` image from ROM offset `0x1000` into TCM,
3. copies the `.data` image from ROM into SRAM at `0x2000_0000`,
4. zeroes `.bss` in SRAM,
5. jumps to the payload entry at `0x0001_0000`.

The sizes and destinations are **not** assembled in. They are read from a
header at ROM offset `0x0800` that `scripts/fw_build/gen_boot_image.js` writes
from the payload it just built, so a mismatched or stale image is visible rather
than silently wrong:

| Header word | Field |
|---|---|
| `0x00` | TCM destination address |
| `0x04` | TCM image length (words) |
| `0x08` | `.data` destination address |
| `0x0C` | `.data` length (words) |
| `0x10` | `.bss` destination address |
| `0x14` | `.bss` length (words) |
| `0x18` | payload entry address |
| `0x1C` | `.data` image offset inside the ROM |

`firmware/boot/payload.S` is the RAM-resident program: it prints over UART,
checks that its `.data` word (`0xC0FFEE01`, which exists only in the ROM image)
was copied to SRAM, checks that its `.bss` word reads zero, then arms the
watchdog and stops petting it so the whole path is re-entered from reset.

## 3. What was measured

`sim/sim_top/tb_boot_loader.v` is compiled **without** `-DSIM_MEM_PRELOAD`
(`scripts/eda/run_regression.js` gives it `defines: []`). On the tested commit it
reports 11/11 checks and `BOOT LOADER: ALL TESTS PASSED`:

| Check | Result |
|---|---|
| TCM word 0 is `x` at t=0 (nothing preloaded it) | pass |
| SRAM word 0 is `x` at t=0 (nothing preloaded it) | pass |
| payload ran from TCM on every boot (≥ 2 boots) | pass |
| `.data` copied from ROM into SRAM on every boot | pass |
| `.bss` zeroed by the loader on every boot | pass |
| cold boot completed at least twice (cold reset, then watchdog recovery) | pass |
| every boot that started the payload also reached its PASS line | pass |
| no `FAIL` line from the payload | pass |
| the watchdog actually reset the SoC (`rst_sys_n` fell) | pass |
| SoC not stuck in reset | pass |
| TCM word 0 became defined after the loader copied into it | pass |

The last check is the discriminating one: the same word that read `x` at t=0 is
defined afterwards, and the only thing that writes it is the loader's copy loop.

The ROM-resident assembly demonstration is untouched and remains its own test
(`tb_boot.v`, 7/7). It exercises the SoC from ROM and is a different claim.

## 4. What is still BLOCKED

| Item | Blocker | Consequence |
|---|---|---|
| Boot from external QSPI flash | `qspi_flash_ctrl` implements a single-line **read** engine only; program and erase return SLVERR. There is no way to place an image in flash on this design. | The only boot source that exists is the on-die boot ROM. This is reported, not worked around. |
| Real SRAM/TCM power-up behaviour | The macro model is a simulation proxy (`sim/models/`, protocol-accurate, no timing/power/area). Vendor models do not elaborate in Icarus 14. | "SRAM powers up `x`" is the model's behaviour; silicon power-up is undefined but is not simulated. |
| Warm boot of the C demo from flash | Same flash gap. | The C demo still runs with a preloaded vs image and is labelled as such. |
| Boot-time watchdog window | The loader does not pet or arm the watchdog; the payload arms it. A boot loop shorter than the watchdog period is therefore not covered by this test. | Stated as a coverage gap, not a defect. |

## 5. How to reproduce

```bash
# from a clean checkout of b5e0642
node scripts/fw_build/gen_boot_image.js            # loader + payload -> boot_rom.hex
export PATH="/d/tools/oss-cad-suite/lib:/d/tools/oss-cad-suite/bin:$PATH"
iverilog -g2012 -I rtl/rtl_top -o build/sim/tb_boot_loader.vvp -s tb_boot_loader \
  sim/sim_top/tb_boot_loader.v $(grep -v '^//' rtl/filelist.f | tr '\n' ' ') \
  sim/models/sky130_sram_sim_model.v
vvp build/sim/tb_boot_loader.vvp | tail -15
```

Note the absent `-DSIM_MEM_PRELOAD`. Adding it back would defeat the test.
