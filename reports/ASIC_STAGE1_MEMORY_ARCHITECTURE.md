# ASIC Stage 1 — Memory Architecture

Date: 2026-11-15
Status: **READY FOR APPROVAL** (TD-001, TD-002, TD-003, TD-006)
Machine-readable: `architecture/memory_architecture.json`

---

## 1. Authoritative memory table (recommended)

| Memory | Intended size | RTL size | Address range | Macro mapping | Status |
|---|---:|---:|---|---|---|
| Boot ROM | 16 KB | 64 KB | `0x0000_0000–0x0000_3FFF` | 16 KB mask ROM (or 4×4 KB SRAM, not preferred) | **MISMATCH** |
| TCM | 32 KB | 32 KB | `0x0001_0000–0x0001_7FFF` | 8×4 KB 1rw+1r, or 1×32 KB 32-bit | Consistent |
| SRAM | 128 KB | 256 KB | `0x2000_0000–0x2001_FFFF` | 32×4 KB 1rw+1r, or 1×128 KB 32-bit | **MISMATCH** |
| QSPI window | 64 MB | 16 MB addressable | `0x4000_0000–0x43FF_FFFF` | External NOR, no on-chip macro | **MISMATCH** |
| APB window | 1 MB | 36 KB decoded | `0x5000_0000–0x500F_FFFF` | n/a | Partial |
| INTC window | 64 KB | 8 KB used | `0x8000_0000–0x8000_FFFF` | n/a | Partial |

The recommended sizes are **not new**: they are the sizes already used by the SRS, the address map, the linker script and the firmware stack pointer.

---

## 2. Mismatch analysis

### 2.1 Boot ROM — 64 KB array for 16 KB decode

- RTL: `parameter int ADDR_WIDTH = 16`, `WORDS = 1 << (16-2) = 16384`, 4 B/word = **64 KB**.
- Decode: `ADDR_BOOT_ROM_SIZE = 0x4000` (16 KB), `sel_rom` covers only 16 KB.
- Indexing: `mem[addr[15:2]]` can address 64 KB, but the decoder never selects addresses above `0x3FFF`, so 48 KB is unreachable, not aliased.
- Firmware: linker `bootrom 16K`; boot image fits.
- Resolution: `ADDR_WIDTH=14` or `DEPTH=4096` words; implement as mask ROM for immutability and area.

### 2.2 SRAM — 256 KB array for 128 KB decode

- RTL: `ADDR_WIDTH=18`, `WORDS=65536`, **256 KB**.
- Decode: `ADDR_SRAM_SIZE=0x20000` (128 KB); addresses above `0x2001_FFFF` are not selected by `sel_sram` and fall into the AXI decode error path.
- Firmware stack: `sp = 0x2001_0000`, exactly the top of 128 KB. If firmware used the extra 128 KB it would fault.
- Resolution: `ADDR_WIDTH=17` or `DEPTH=32768` words; keep 128 KB.

### 2.3 QSPI — 64 MB window, 16 MB addressable

- The AXI slave is selected over 64 MB.
- The controller emits `{8'h03, araddr[23:0]}` — a 24-bit flash address, so the upper 48 MB alias the lower 16 MB four times.
- No quad, DDR, XIP cache or program/erase; writes return SLVERR.
- Resolution options:
  - **M1:** reduce the window to 16 MB (matches controller and W25Q128-class parts).
  - **M2:** implement 4-byte addressing (0x13/0x0C or bank select) and keep 64 MB.
  - OTA/program/erase remains a separate decision (TD-007).

### 2.4 INTC and APB windows

- CLINT and PLIC are 4 KB each at `0x8000_0000` and `0x8000_1000`; the documented 32 KB/32 KB layout is not implemented.
- PLIC context registers are at `0x200/0x204/0x208` within its 4 KB window.
- CLINT `MTIME` is at `0x7F8`, not the architectural `0xBFF8`.
- APB uses `paddr[15:12]`, decoding nine 4 KB slots (36 KB) of the 1 MB window; unmapped slots return PSLVERR.
- These are interface issues (see interface report), not capacity issues, but they must be documented so software does not assume the SRS layout.

---

## 3. Macro analysis

### 3.1 Available macro

`sky130_sram_1rw1r_128x256_8`:

| Property | Value |
|---|---|
| Actual capacity | 256 words × 128 bit = **4 KB** |
| Ports | 1 read/write + 1 read |
| Write mask | 16 bits (one per byte) |
| LEF | 1141.72 × 632.475 µm |
| Area | **0.7221 mm² per macro** |
| Liberty | TT 1.8 V 25 °C only |
| Status | Not integrated |

The macro's 128-bit width is mismatched to a 32-bit AXI/CPU. A wrapper must:

- map one 128-bit word to four 32-bit AXI words;
- assert only the 4 mask bits for the addressed 32-bit slice;
- handle the 1-cycle registered read latency;
- arbitrate the instruction read port against AXI read/write.

The 1rw+1r structure is sufficient: AXI read and instruction read can occur together (port 0 + port 1), and AXI write and instruction read can occur together. AXI read and write cannot occur together because the AXI slave serializes them.

### 3.2 Macro count and area

| Configuration | ROM | TCM | SRAM | Total macros | Area |
|---|---:|---:|---:|---:|---:|
| 4 KB 128-bit macro tiling | 4 | 8 | 32 | **44** | **31.77 mm²** |
| 32-bit wide macros (recommended) | mask ROM | 1×32 KB | 1×128 KB | 2 + ROM | ~4.3 mm² estimated |

**Finding:** tiling the available 4 KB macro for 176 KB consumes **31.8 mm²**, more than three times the 10 mm² total-die target before any logic. This is not a viable memory architecture. The SRS estimate of ~3.5 mm² for 128 KB implicitly assumes a 32-bit wide macro, which is not in the repository.

### 3.3 Macro strategy options

| Option | Description | Advantage | Disadvantage |
|---|---|---|---|
| M-A | Tile the 4 KB 128-bit macro | Available now | 31.8 mm², width adapter, TT-only |
| M-B | Generate 32-bit 128 KB/32 KB macros with OpenRAM | Area target feasible | Generation time, multi-corner characterization, yield unknown |
| M-C | Reduce memory sizes (e.g. 64 KB SRAM) | Smaller area | Violates FR-MEM-001; firmware change |
| M-D | Use external SRAM | No macro area | Pins, latency, power, package |

**Recommended: M-B.** If M-B cannot produce multi-corner views in time, the owner must choose M-C or revise NFR-AREA-001; M-A must not be carried into floorplanning.

---

## 4. Firmware dependency check

| Artifact | Assumption | Matches recommendation? |
|---|---|---|
| `firmware/bare_metal/linker.ld` | ROM 16K, TCM 32K, SRAM 128K, QSPI 64M | Yes for 16/32/128; QSPI 64M needs M2 or reduces to 16M |
| `firmware/boot/boot.S` | `sp=0x2001_0000` (top of 128 KB) | Yes |
| `firmware/boot/boot.S` | load address 0x0000_0000 | Yes |
| `firmware/bare_metal/drivers.h` | APB bases GPIO 0x5000_0000, UART 0x1000, … | Yes (RTL order) |

Conclusion: **fix the RTL, not the firmware.** The firmware already encodes the correct intended memory architecture; the RTL parameters are the outliers.

---

## 5. Arbitration, byte enables, behavior

- `sram.sv` has an independent instruction read port and an AXI read/write port. Writes take priority over AXI reads; instruction reads are independent. This maps to 1rw+1r.
- Byte writes are implemented with `wstrb`; the macro requires a 16-bit mask adapter for 128-bit words.
- `boot_rom` has an instruction port and an AXI read port; writes are ignored. A mask ROM naturally supports this.
- APB partial-strobe writes are rejected with PSLVERR at the SoC level; peripherals do not decode `pstrb`. This is safe but means byte/ halfword writes to peripheral registers fault. Document it or implement strobes.
- No ECC (FR-MEM-006 optional). SECDED would widen the macro and change the wrapper; defer.

---

## 6. Recommendation and approval

| Decision | Recommendation |
|---|---|
| TD-001 ROM size | 16 KB; change RTL `ADDR_WIDTH` to 14 |
| TD-002 TCM size | 32 KB; keep |
| TD-003 SRAM size | 128 KB; change RTL `ADDR_WIDTH` to 17 |
| QSPI window | 16 MB, or implement 4-byte addressing for 64 MB |
| TD-006 macro | 32-bit wide 128 KB + 32 KB macros; do not tile 4 KB macro |
| ECC | Defer |

**Approval required:** user/design owner for TD-001/003/006 and the QSPI window.
**Acceptance criteria:**
1. One memory table approved and copied into SRS, linker docs and `has_addr_map_pkg`.
2. RTL parameter corrections scheduled for Stage 2.
3. Macro strategy approved with area evidence (or area target re-approved).
4. QSPI window decision recorded.

**Verified:** RTL parameters, decode ranges, firmware assumptions, macro geometry.
**Recommended:** 16/32/128 KB + 32-bit macros + 16 MB QSPI (or 4-byte addressing).
**Not approved:** all TD memory decisions remain READY FOR APPROVAL.
