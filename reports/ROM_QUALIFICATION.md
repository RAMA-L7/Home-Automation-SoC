# ROM and memory qualification — what is measured, at which level

**Tested commit:** `b5e0642`

This document separates four things that earlier summaries mixed together:
proxy simulation, formal abstraction, library timing, and physical
verification. Nothing here is a characterised ASIC ROM, and no area number is
claimed as a memory-compiler result.

---

## 1. The boot ROM as implemented

`rtl/rtl_top/boot_rom.sv` is a behavioural module: contents in a `mem` array
filled by `$readmemh`. Yosys infers a `$mem_v2` for it, which no standard-cell
library can implement, so the SoC could be mapped but never closed.

`scripts/fw_build/gen_rom_rtl.py` bakes the same image into a `case` statement
(decode logic) with an identical interface and read latency, so the ROM becomes
ordinary combinational logic after synthesis. That generator now also carries
the split-channel AW/W fix, so a generated ROM cannot reintroduce the bus hang
that `rtl/rtl_top/boot_rom.sv` had.

## 2. Levels of evidence, kept apart

| Level | What was done | What it proves | What it does NOT prove |
|---|---|---|---|
| **Functional simulation** | `node scripts/eda/run_rom_check.js`: 1,059 checks against `sim/sim_top/tb_boot_rom.v` for the behavioural module and 1,059 for the generated one, word-for-word identical; CPU boot from the generated ROM 7/7 | the generated ROM returns the same words, at the same latency, and rejects writes the same way | nothing about timing, area, power or silicon |
| **Bus protocol** | `sim/sim_top/tb_axi_split.v` instantiates `boot_rom` directly and drives address-first, data-first, simultaneous and backpressured writes | the ROM accepts AW and W independently and answers exactly one SLVERR instead of hanging | nothing about the memory array |
| **Structural synthesis** | `asic/synthesis/fullsoc_map_rom.ys` + `asic/synthesis/structural_policy_rom.json` | the generated ROM is in the mapped netlist and the SoC's inferred-memory count drops from 4 to 3 | not a PPA result, not routed, not timed with parasitics |
| **ROM area / gate cost** | `asic/synthesis/rom_map.ys` (own flow, because `memory_map` must be told to expand the inferred case) | the ROM maps to **262,262 sky130 standard cells** in 21 s | this is a mux tree, not a bit-cell array; see §4 |
| **Library timing** | OpenSTA 3.1.0 with the sky130 `tt_025C_1v80` Liberty and the SRAM macro Liberty | real slack on a real mapped netlist (WNS −106.48 ns; see `TIMING_AND_CDC_QUALIFICATION.md`) | not signoff: ideal clocks, one corner, no SPEF |
| **Physical verification** | none | nothing | DRC, LVS, area, power, yield — all **BLOCKED** |

## 3. Measured structural result

Command and result at `b5e0642`:

```
python3 scripts/fw_build/gen_rom_rtl.py build/fw/boot_rom.hex build/rom/boot_rom_soc.v
  -> 4096 words, image sha256 429d3189e2d0e942a145d7d14b65ca428d6b405a74aa9082a002458d4fff3c42
yosys -s asic/synthesis/fullsoc_map_rom.ys                  (37 s)
node scripts/eda/check_structure.js --script asic/synthesis/fullsoc_map_rom.ys \
     --top has_soc --json build/asic_evidence/structural_check/has_soc_rom_cells.json \
     --tag fullsoc_rom --policy asic/synthesis/structural_policy_rom.json
  -> STRUCTURAL_CHECK: BLOCKED   274757 leaf cells, 9 types
     GAP $mem_v2 x3
     GAP sky130_sram_2kbyte_1rw1r_32x512_8 x80
```

Reading that result honestly:

* **The ROM's inferred memory is gone.** The same check on the canonical
  behavioural-ROM flow declares 4 `$mem_v2`; this flow declares 3, and the
  difference is exactly the 4096×32 boot ROM.
* The three remaining are the TCM (8192×32), the SRAM (32768×32) and the 18 B
  APB decode LUT — all inventoried in `asic/synthesis/memory_inventory.json`.
* The 80 `sky130_sram_2kbyte_1rw1r_32x512_8` leaves are the 64 SRAM + 16 TCM
  banks. They are PDK assets and enter through
  `rtl/blackbox/sky130_sram_macro_blackbox.v`, so they stay unmapped leaves.
  80 is the exact `128 KiB / 2 KiB + 32 KiB / 2 KiB` count in `has_soc.sv`;
  a different number fails the check rather than being explained away.
* Verdict is **BLOCKED (exit 2)**, not PASS. That is the point of the policy:
  a design with unmapped memories cannot be called structurally complete.

## 4. Why the ROM is still BLOCKED as a memory decision

`rom_map.ys` measures the ROM alone: **262,262 sky130 cells** for 4,096 words of
32 bits (16 KiB). That is ~64 cells per byte. A mux tree is not a ROM:

* no bit-cell array, no precharge/discharge, no sense amplifiers;
* no ROM-specific timing model (access time scales with the decoder depth here,
  not with a bit line);
* no ROM-specific power model, no density advantage;
* Yosys infers the generated `case` as a memory and it must be expanded
  explicitly, so "it maps" required a dedicated flow rather than falling out of
  the canonical one.

So the ROM is **functionally qualified** and **synthesizable**, and its cost is
**measured**, but it is not an ASIC ROM. The open decision is a real mask/array
ROM (or an OTP macro), and that remains BLOCKED on a memory compiler and on a
characterisation the PDK here does not provide.

## 5. Memory macro wrapper: what it is verified against

The wrapper (`rtl/rtl_top/sram_macro_wrap.sv`, 64 banks for SRAM and 16 for TCM
via `tcm_macro_wrap.sv`) is verified at production geometry by
`sim/sim_top/tb_sram_macro_wrap.v` (81 checks) with two discriminating negative
controls (broken bank decode → 3 failures; ignored strobes → 30 failures).

Its functional contract against the macro is the vendor Liberty plus the pin
protocol: capture on the rising edge, data valid on the following falling edge,
`wmask0` per byte, no init port. The **cell** is the simulation proxy in
`sim/models/sky130_sram_sim_model.v`. Vendor Verilog models do not elaborate in
Icarus 14 (`mem[addr_reg]` is a non-constant index there), so every wrapper and
SoC result is a **proxy-model** result and is labelled as such. Macro timing
comes from the macro Liberty file in the STA run only.

## 6. Blocked, explicitly

| Requirement | State | Reason |
|---|---|---|
| Real-macro functional simulation | BLOCKED | vendor models do not elaborate in Icarus 14; no Verilator C++ model for them either |
| Macro power/area characterisation | BLOCKED | no memory compiler; only fixed pre-built macros |
| ASIC ROM (array) | BLOCKED | no compiler, no ROM characterisation; the mux tree is not a substitute |
| Physical verification of ROM or RAM | BLOCKED | no routed design, no DRC/LVS, no extracted parasitics |

None of these is reported as a pass anywhere in this repository.
