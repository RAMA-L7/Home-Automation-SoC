# External dependencies

This repository is self-contained for **simulation** and for **elaboration /
structural synthesis**. Two categories of things are deliberately *not* in the
tree: the SkyWater PDK (including its SRAM macro models) and the EDA tool
binaries. Neither is redistributable, and no secrets are stored here.

Everything below is required only for the flows named. `rtl/filelist.f` plus
`sim/models/sky130_sram_sim_model.v` are enough for every simulation target.

---

## 1. SRAM macro cells (required for synthesis; optional for simulation)

`rtl/rtl_top/sram_macro_wrap.sv` and `rtl/rtl_top/tcm_macro_wrap.sv` instantiate
the real SkyWater SRAM macros by cell name:

| Cell | Geometry | Instances (SRAM) | Instances (TCM) |
|---|---|---|---|
| `sky130_sram_2kbyte_1rw1r_32x512_8` | 512 x 32 bit = 2 KiB, 2-port RW+R | 64 | 16 |
| `sky130_sram_1kbyte_1rw1r_32x256_8` | 256 x 32 bit = 1 KiB, 2-port RW+R | 128 (alternate) | 32 (alternate) |

The alternate cell is selected with `+define+MACRO_USE_1KB` and a matching
`NUM_MACROS`; the default build uses the 2 KiB cell.

**Where they come from.** The SkyWater sky130 PDK, `sky130A`
(`libs.ref/sky130_sram_macros/`, `libs.tech/`). Obtain it with
[volare](https://github.com/efabless/volare):

```sh
volare enable --pdk sky130 --pdk-root <PDK_ROOT> <version>
```

Pin the version you use and record it next to any synthesis result. The macro
Liberty files carry the authoritative capacity (`memory(...)` blocks) and the
`interface_timing: true` falling-edge output arcs the wrappers are written
against.

**Hashes.** This repository does not pin a PDK hash because the PDK is not
needed to reproduce any result currently claimed. Any future synthesis claim
must record the `volare` version string and the SHA-256 of every `.lib` and
`.v` file it consumed, in the run manifest.

**Licence.** The sky130 PDK is published by SkyWater Technology under the
Apache-2.0 licence (digital standard cells, SRAM macros) with the
`sky130_fd_pr` analogue models under Apache-2.0 as well. Read the licence file
shipped with your PDK copy; it governs redistribution.

### What the tree provides instead

| File | Purpose | Synthesis? |
|---|---|---|
| `sim/models/sky130_sram_sim_model.v` | Behavioural stand-in implementing the macro pin protocol (registered inputs, falling-edge registered outputs, byte-masked writes, 2-port). **Simulation only** — no timing, power or area meaning. | No |
| `rtl/blackbox/sky130_sram_macro_blackbox.v` | `(* blackbox *)` declarations with exact pin lists so Yosys can elaborate `has_soc` and keep the cells as unmapped leaves. | Yes (as leaves) |

Do not compile the sim model and the blackbox file together: they declare the
same module names.

---

## 2. EDA tools

| Tool | Version used | Needed for |
|---|---|---|
| Icarus Verilog | OSS CAD Suite build, Icarus 14 | every simulation target |
| Yosys | 0.69+154 (OSS CAD Suite) | elaboration, structural checks, ROM mapping |
| tclsh | 8.6 | `scripts/eda/run_sdc_lint.js` (SDC validation) |
| Node.js | 18+ | runner scripts |
| Python | 3.12 | `scripts/fw_build/gen_rom_rtl.py` |
| OpenSTA | not runnable here | path-based STA — **BLOCKED**, see below |

The Linux `opensta` binary in `D:\tools\opensta` cannot run on this machine
(WSL1 is not supported), and no Windows build exists, so **no timing result is
claimed**. `scripts/eda/run_sdc_lint.js` validates the SDC file itself (Tcl
syntax, object resolution, per-port coverage) with `tclsh`, and reports the STA
gap as BLOCKED rather than substituting a weaker claim.

---

## 3. Reproducing a clean build

```sh
# firmware images (boot.hex, rom.hex, tcm.hex)
node scripts/eda/run_regression.js

# macro-wrapper verification + 2 negative controls
node scripts/eda/run_macro_wrapper.js

# boot ROM: behavioural vs synthesizable, CPU boot, Yosys mapping
node scripts/eda/run_rom_check.js

# SDC validity + port coverage (STA itself is BLOCKED)
node scripts/eda/run_sdc_lint.js
```

None of these need the PDK or any file that is not tracked in Git.
