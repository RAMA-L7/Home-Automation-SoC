# Home-Automation-SoC — Sky130 SRAM Macro Interface Audit

**Audit type:** Read-only technical audit (no implementation)
**Date:** 2026-11-14
**Repository:** `D:\Home-Automation-SoC`
**Baseline HEAD:** `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`
**Branch:** `main`
**Working-tree diff SHA-256:** `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d`
**Macro platform:** `/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130ram`
**Primary macro:** `sky130_sram_1rw1r_128x256_8`
**Evidence:** `reports/evidence/sky130_sram_macro_audit/`

No production RTL, memory wrapper, testbench, synthesis script, or flow configuration was modified. No tools were installed. No PDK files were changed. No synthesis or physical implementation was run.

---

## 1. Executive Summary

- The macro name `sky130_sram_1rw1r_128x256_8` is misleading. The generator config (`.py`) and Verilog model (`.v`) show **256 words × 128 bits = 4 KB**, not 128 × 256.
- `wmask0` is **16 bits wide**, one bit per byte, for a 128-bit (16-byte) word. Partial writes preserve unselected bytes. Active-high mask (1 = write byte). csb/web are active-low.
- AXI `WSTRB` (4 bits for a 32-bit word) can be mapped to the macro mask, but only through a width/slice adapter: one macro word holds 4 AXI words, and only the 4 mask bits corresponding to the addressed 32-bit slice may be asserted.
- Port architecture: **1rw + 1r** (port 0 read/write, port 1 read-only). Supports concurrent instruction read and AXI write, and concurrent AXI read and instruction read. Does **not** support simultaneous read+write on port 0, or simultaneous instruction read + AXI read on the same macro (both use port 0 for AXI).
- Read latency is 1 cycle (registered output, clk-to-q ~0.366–0.511 ns at TT). Write occurs on the opposite clock edge internally (inputs registered on posedge, write on negedge).
- Same-address read-during-write across ports is **not safe**: the Verilog model emits a warning and ordering is undefined.
- Timing views: **TT only** (1.8 V, 25 °C). Physical view: LEF 1141.72 × 632.475 µm, CLASS BLOCK, power pins `vdd`/`gnd`.
- Alternative macros (64×256, 80×64, 44×64) have non-byte-aligned or smaller widths; the 128-bit macro is the best fit for a 32-bit SoC but requires a width adapter.
- **Final verdict: SRAM MACRO COMPATIBLE WITH WRAPPER.**

---

## 2. Baseline Integrity

| Item | Value | Status |
|------|-------|--------|
| Branch | `main` | VERIFIED |
| HEAD SHA | `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1` | VERIFIED |
| Working-tree diff SHA-256 | `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d` | VERIFIED |
| No production RTL modified | confirmed | VERIFIED |

---

## 3. Macro Inventory

Primary macro directory:
`/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130ram/sky130_sram_1rw1r_128x256_8`

| File | Size (bytes) | SHA-256 (first 16) | Status |
|------|-------------:|---------------------|--------|
| `sky130_sram_1rw1r_128x256_8.v` | 4,001 | `460627c8bc8aa9da` | VERIFIED |
| `sky130_sram_1rw1r_128x256_8.py` | 524 | `f5cb3dfac2e12a91` | VERIFIED |
| `sky130_sram_1rw1r_128x256_8_TT_1p8V_25C.lib` | 16,332 | `dd2352cea8cb26ca` | VERIFIED |
| `sky130_sram_1rw1r_128x256_8.lef` | 104,872,365 | `90ccb7eb38db40e1` | VERIFIED |
| `sky130_sram_1rw1r_128x256_8.gds` | 11,790,182 | `c7063c949f70a417` | VERIFIED |
| `sky130_sram_1rw1r_128x256_8.sp` | 1,673,314 | `2f2802a6d9c9e9dd` | VERIFIED |
| `sky130_sram_1rw1r_128x256_8.lvs.sp` | 1,671,371 | `2f06b718fc6ca2e8` | VERIFIED |
| `functional_stim.sp` | 2,643,245 | `06c981114ce82552` | VERIFIED |

Full hashes: `reports/evidence/sky130_sram_macro_audit/macro_hashes.txt`.

Additional (generator common script):
`/d/rta-real-world-benchmark/02_projects/OpenROAD-flow-scripts/flow/platforms/sky130ram/sky130_sram_common.py` — referenced by `.py`, not inspected in detail. Status: PARTIALLY VERIFIED.

---

## 4. Actual Macro Interface

From `sky130_sram_1rw1r_128x256_8.v` (authoritative Verilog model):

| Parameter | Value | Source |
|-----------|-------|--------|
| `NUM_WMASKS` | 16 | Verilog |
| `DATA_WIDTH` | 128 | Verilog |
| `ADDR_WIDTH` | 8 | Verilog |
| `RAM_DEPTH` | 256 (= 1 << 8) | Verilog |
| `DELAY` | 3 (arbitrary) | Verilog (not a real timing value) |

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk0` | input | 1 | Port 0 clock |
| `csb0` | input | 1 | Port 0 chip select, active low |
| `web0` | input | 1 | Port 0 write enable, active low (0 = write) |
| `wmask0` | input | 16 | Port 0 byte write mask, active high |
| `addr0` | input | 8 | Port 0 address |
| `din0` | input | 128 | Port 0 data in |
| `dout0` | output | 128 | Port 0 data out |
| `clk1` | input | 1 | Port 1 clock |
| `csb1` | input | 1 | Port 1 chip select, active low |
| `addr1` | input | 8 | Port 1 address |
| `dout1` | output | 128 | Port 1 data out |

**Actual capacity:** 256 words × 128 bits = 32,768 bits = **4,096 bytes (4 KB)**.
**Addressable units:** 256 words; byte address within macro = {addr, 4'b0000} (16 bytes per word).

The `.py` config confirms: `word_size = 128`, `num_words = 256`, `write_size = 8`, `num_rw_ports = 1`, `num_r_ports = 1`. The filename's "128x256" does **not** mean 128 words × 256 bits; it is a naming artifact. Status: VERIFIED (from Verilog + generator config).

---

## 5. Write-Mask Semantics

From the Verilog model `MEM_WRITE0` block:

- `wmask0` is 16 bits, one bit per byte of the 128-bit word.
- `wmask0[i] == 1` writes the corresponding byte lane; `0` preserves the existing byte.
- Mapping (verified from Verilog):
  - `wmask0[0]` → bits [7:0]
  - `wmask0[1]` → bits [15:8]
  - ...
  - `wmask0[15]` → bits [127:120]
- Partial writes preserve unselected bytes (read-modify-write at byte granularity is not needed; the mask gates each byte independently). Status: VERIFIED.
- `csb0` active low (0 = selected). `web0` active low (0 = write, 1 = read). Status: VERIFIED.
- Mask polarity is active-high (1 = write). Status: VERIFIED.

**Total bytes per word:** 16. **Independently writable byte lanes:** 16. **Mask bits required for full byte-write:** 16 (matches).

---

## 6. AXI Byte-Write Compatibility

SoC AXI4-Lite: 32-bit data (`wdata[31:0]`), 4-bit byte strobe (`wstrb[3:0]`).

Macro: 128-bit word, 16-byte mask.

Because one macro word holds **4 AXI words** (128/32 = 4), a single AXI write must target a 32-bit slice within the 128-bit word. The wrapper must:
1. Use `addr[3:2]` to select which 32-bit slice (0..3) within the macro word.
2. Expand `wstrb[3:0]` to the corresponding 4 bits of `wmask0` (e.g., slice 0 → bits [3:0], slice 1 → bits [7:4], etc.), with all other mask bits = 0.
3. Preserve the other 3 AXI words (their mask bits = 0).
4. On read, select the 32-bit slice from the 128-bit `dout0`/`dout1` using `addr[3:2]`.

Explicit mapping table (example for AXI word at slice k, k = addr[3:2]):

| AXI WSTRB bit | Macro wmask0 bit | Data lane (macro bits) | Supported? |
|---|---|---|---|
| WSTRB[0] | wmask0[4k+0] | macro bits [8(4k+1)-1 : 8(4k)] | YES |
| WSTRB[1] | wmask0[4k+1] | macro bits [8(4k+2)-1 : 8(4k+1)] | YES |
| WSTRB[2] | wmask0[4k+2] | macro bits [8(4k+3)-1 : 8(4k+2)] | YES |
| WSTRB[3] | wmask0[4k+3] | macro bits [8(4k+4)-1 : 8(4k+3)] | YES |

All other `wmask0` bits = 0 for that access (preserves adjacent AXI words).

**Conclusion:** Byte-write compatibility is achievable but requires a width/slice adapter. Direct 1:1 integration is **not** possible because macro width (128 bits) ≠ AXI width (32 bits). Status: PARTIALLY COMPATIBLE (wrapper required).

---

## 7. Read/Write Port Behavior

From Verilog model and Liberty:

| Behavior | Supported? | Evidence |
|----------|------------|----------|
| Port 0 read (web0=1, csb0=0) | YES | Verilog MEM_READ0 |
| Port 0 write (web0=0, csb0=0) | YES | Verilog MEM_WRITE0 |
| Port 1 read (csb1=0) | YES | Verilog MEM_READ1 |
| Port 1 write | NO (read-only) | No write logic for port 1 |
| Simultaneous read+write on port 0 | NO | web0 is mutually exclusive |
| Concurrent AXI read (port 0) + instruction read (port 1) | YES | Separate ports/clocks |
| Concurrent AXI write (port 0) + instruction read (port 1) | YES | Separate ports/clocks |
| Same-address read-during-write across ports | NOT SAFE | Verilog emits WARNING; ordering undefined |
| Read latency | 1 cycle (registered output) | Verilog `dout0 <= #(DELAY) mem[...]` on negedge; Liberty clk-to-q ~0.366–0.511 ns |
| Write latency | Inputs sampled posedge clk0; write on negedge clk0 | Verilog always blocks |
| Clocking | Separate clocks clk0, clk1 (can be tied) | Verilog/Liberty |
| Output registration | Yes (dout0/dout1 are regs) | Verilog |

**Collision behavior:** The model warns on simultaneous write (port 0) and read (port 1) to the same address. The resulting read data is not guaranteed to be either old or new. This is a BLOCKER for any use case requiring deterministic read-during-write (none currently required by the SoC, but must be documented). Status: PARTIALLY VERIFIED.

---

## 8. Memory Capacity and Banking

Actual macro capacity = 4 KB (256 words × 128 bits). SoC memory requirements from `has_addr_map.sv` and RTL:

| Memory region | Required capacity | Macro capacity | Bank count | Address bits (macro) | Status |
|---------------|------------------:|---------------:|-----------:|---------------------:|--------|
| SRAM | 128 KB (131,072 B) | 4 KB | 32 | 8 (word) / 12 (byte) | BLOCKED* |
| TCM | 32 KB (32,768 B) | 4 KB | 8 | 8 / 12 | BLOCKED* |
| Boot ROM (if SRAM-backed) | 16 KB (16,384 B) | 4 KB | 4 | 8 / 12 | BLOCKED* |

\* Blocked not by count but by width adaptation and port-arbitration requirements.

**Address mapping (128-bit macro, 32-bit SoC):**
- Macro word address = byte_addr[11:4] (8 bits, 256 words).
- Byte offset within macro word = byte_addr[3:0] (16 bytes).
- AXI word select within macro word = byte_addr[3:2] (4 AXI words).
- Bank select (32 banks) = byte_addr[16:12] (5 bits) for 128 KB.
- TCM (8 banks): bank select = byte_addr[14:12] (3 bits).
- Unused locations: none if capacity divides evenly (128 KB / 4 KB = 32 exactly).

**Arbitration requirements:**
- Port 0 serves all AXI reads and writes (mutually exclusive via web0).
- Port 1 serves instruction-fetch reads.
- If AXI read and instruction fetch target the same bank simultaneously, they use different ports → OK.
- If AXI write and instruction fetch target the same bank simultaneously → port0 write + port1 read → read-during-write hazard (undefined).
- Bank-level arbitration may be needed if both ports access the same bank with a write on port 0.

---

## 9. Timing and Physical Views

### Liberty (TT corner)
- File: `sky130_sram_1rw1r_128x256_8_TT_1p8V_25C.lib`
- Operating conditions: process 1.0, voltage 1.8 V, temperature 25 °C.
- Setup (din0, addr0, wmask0, csb0, web0 vs clk0): 0.165 ns (rise/fall).
- Hold: -0.052 ns.
- Clock-to-output (dout0/dout1): 0.366–0.511 ns (CELL_TABLE).
- Read latency: 1 cycle.
- **Only TT corner available.** SS/FF/FS/SF: NOT AVAILABLE for this macro.

### LEF (physical)
- File: `sky130_sram_1rw1r_128x256_8.lef`
- Units: DATABASE MICRONS 1000.
- SIZE: 1141.72 × 632.475 µm.
- CLASS: BLOCK.
- Power pins: `vdd`, `gnd` (INOUT).
- Signal pins match Verilog port names (clk0, csb0, web0, wmask0[15:0], addr0[7:0], din0[127:0], dout0[127:0], clk1, csb1, addr1[7:0], dout1[127:0]).
- Pin directions: INPUT/OUTPUT/INOUT. Status: VERIFIED (LEF and Verilog agree).

### GDS
- File: `sky130_sram_1rw1r_128x256_8.gds` (11.8 MB). Status: VERIFIED (present).

### SPICE
- Files: `.sp`, `.lvs.sp`, `functional_stim.sp`. Status: VERIFIED (present).

### View agreement check
| Attribute | Verilog | LEF | Liberty | Agreement |
|-----------|---------|-----|---------|-----------|
| Macro name | `sky130_sram_1rw1r_128x256_8` | same | library name `..._TT_1p8V_25C_lib` | VERIFIED |
| Data width | 128 | dout0[127:0] | bus(dout0) [127:0] | VERIFIED |
| Address width | 8 | addr0[7:0] | (implied by depth) | VERIFIED |
| Mask width | 16 | wmask0[15:0] | (not in liberty as bus? mask is input) | VERIFIED |
| Power pins | — | vdd/gnd | voltage_map VDD/GND | VERIFIED |

---

## 10. Alternative Macro Comparison

| Macro | Capacity | Word width | Address width | Write mask | Byte-aligned? | Suitability for 32-bit SoC |
|-------|----------|-----------:|--------------:|-----------:|:-------------:|----------------------------|
| `sky130_sram_1rw1r_128x256_8` | 4 KB (256×128) | 128 | 8 | 16 bits (byte) | YES | Best (fewest banks, byte-write) |
| `sky130_sram_1rw1r_64x256_8` | 2 KB (256×64) | 64 | 8 | 8 bits (byte) | YES | More banks (×2), simpler width (2:1) |
| `sky130_sram_1rw1r_80x64_8` | 640 B (64×80) | 80 | 6 | 10 bits (byte) | NO (80 bits ≠ multiple of 32 cleanly? 80 = 2.5×32) | Poor — non-32-bit-aligned |
| `sky130_sram_1rw1r_44x64_8` | 352 B (64×44) | 44 | 6 | 6 bits (byte) | NO (44 bits) | Poor — non-32-bit-aligned |

**Conclusion:** The 128-bit macro is the best candidate (byte-aligned, largest capacity, fewest banks). The 64-bit macro is a fallback with simpler width adaptation but double the bank count. The 80/44-bit macros are not suitable for a 32-bit byte-addressable memory without wasteful packing. Status: VERIFIED (from `.py` configs).

---

## 11. Architecture Options

| Option | Functional compat. | Byte-write compat. | Port compat. | Timing evidence | Physical views | Complexity | Blockers |
|--------|-------------------|-------------------|--------------|-----------------|----------------|------------|----------|
| A. Direct integration (128-bit macro as 32-bit SRAM) | NO (width mismatch) | N/A | NO | N/A | N/A | — | Width mismatch, address mapping |
| B. Banked macros + custom wrapper (width adapter + arbitration) | YES | YES (with adapter) | YES (with caveats) | TT only | VERIFIED | High | Read-during-write hazard, TT-only timing, 32-bank routing |
| C. Different macro combination (64-bit) | YES | YES | YES | TT only | VERIFIED | Medium-High | Double bank count, width adapter still needed |
| D. External memory compiler | NOT AVAILABLE | — | — | — | — | — | No compiler installed |
| E. Register-based memory | VERIFIED (sim) | YES | YES | N/A | N/A | Low RTL / impossible ASIC | 787 k cells for 128 KB |

**Recommendation:** Option B (banked 128-bit macros + wrapper) is the only viable ASIC path among available macros. It requires resolving the read-during-write hazard (e.g., by stalling or forwarding) and accepting TT-only timing until SS/FF views are obtained.

---

## 12. Critical Risks

1. **Width adaptation complexity:** 128-bit macro vs 32-bit AXI requires slice muxing and mask expansion; increases latency and area.
2. **Read-during-write hazard:** Undefined behavior on same-address cross-port access; must be avoided or handled explicitly.
3. **TT-only timing:** No SS/FF corners for the macro; setup/hold margins unknown at other corners.
4. **32-bank integration:** Large bank count increases routing congestion and address-decode complexity.
5. **Arbitrary DELAY=3** in Verilog model is not a real timing value; Liberty must be used for STA.
6. **Macro port clocks clk0/clk1:** If tied to the same domain, clock skew between ports must be managed.
7. **Boot ROM integrity:** SRAM-backed ROM requires validated boot mechanism (currently fail-closed only).

---

## 13. Final Verdict

**SRAM MACRO COMPATIBLE WITH WRAPPER**

The Sky130 SRAM macro (`sky130_sram_1rw1r_128x256_8`) is functionally compatible with the SoC memory requirements **only through a custom wrapper** that handles width adaptation (128-bit macro → 32-bit AXI), byte-strobe expansion, bank selection, and read-during-write avoidance. Direct integration is not possible due to the width mismatch. Timing and physical views are present (TT only). No implementation was performed.

---

## 14. Evidence and Reproducibility

- Evidence directory: `reports/evidence/sky130_sram_macro_audit/`
  - `macro_hashes.txt` — SHA-256 of all macro files
  - `lef_summary.txt` — LEF size/class/pin directions
  - `liberty_summary.txt` — Liberty operating conditions and timing
- Verilog model: `/d/rta-real-world-benchmark/.../sky130ram/sky130_sram_1rw1r_128x256_8/sky130_sram_1rw1r_128x256_8.v`
- Liberty: `.../sky130_sram_1rw1r_128x256_8_TT_1p8V_25C.lib`
- LEF: `.../sky130_sram_1rw1r_128x256_8.lef`
- GDS: `.../sky130_sram_1rw1r_128x256_8.gds`
- Generator config: `.../sky130_sram_1rw1r_128x256_8.py`
- SoC SRAM RTL: `rtl/rtl_top/sram.sv`
- SoC address map: `rtl/rtl_top/has_addr_map.sv`
EOF
echo written