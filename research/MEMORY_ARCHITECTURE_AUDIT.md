# SoC memory architecture audit — F5 / F7

- **Run:** `RUN-0009-memory-audit`
- **Date:** 2026-11-18 19:51–20:05 IST (14:21–14:35Z)
- **Agent:** `Agent: Buffy (model: DeepSeek V4.1 Flash)`
- **Base:** `025ef24` + dirty worktree
- **Reviewer:** self (same agent) — **not independent**; no subagent tool exists here
- **Verdict:** **F5 PASS** (inventory and reconciliation complete, discrepancy
  confirmed with measured numbers) · **F7 BLOCKED** (4 inferred memories, no
  macro, no usable PDK). Overall **PARTIAL**. No ASIC-readiness claim.

## 1. Method and evidence

| Source | What it gives |
|---|---|
| `asic/synthesis/memory_audit.ys` (new, tracked) | `hierarchy -check -top has_soc; proc; memory_collect; stat -json; write_rtlil` — no techmap, no flatten |
| `build/asic_evidence/memory_audit/memories.il` | every `$mem_v2` with `SIZE`, `WIDTH`, `ABITS`, `RD_PORTS`, `WR_PORTS`, `INIT` |
| `build/asic_evidence/memory_audit/memory_cells.json` | independent `stat` count per module (cross-check) |
| `rtl/rtl_top/has_addr_map.sv` | declared region base/size |
| `rtl/rtl_top/axi_lite_interconnect.sv:114-120` | the literals that actually decode the bus |
| `firmware/bare_metal/linker.ld` | firmware memory assumptions |
| `docs/requirements/system_requirements.md` (FR-MEM-001) | 128 KB SRAM requirement |
| `build/asic_evidence/structural_check/has_soc_cells.json` (RUN-0007) | earlier count, reproduced |
| `scripts/eda/audit_memory.js` (new, tracked) | drift checker + 7 controls |

Reproduce:

```bash
yosys -s asic/synthesis/memory_audit.ys            # ~15 s
node scripts/eda/audit_memory.js --verbose         # exit 2 (BLOCKED)
node scripts/eda/audit_memory.js --self-test       # 7/7 controls, exit 0
```

## 2. Inventory (verified from elaboration)

| ID | Instance / module | Depth × width | Bits | Bytes | Ports | Read latency | Address | Init |
|---|---|---|---|---|---|---|---|---|
| MEM-ROM | `rom_inst` / `boot_rom` (`ADDR_WIDTH=16`) | 16384 × 32 | 524,288 | 65,536 (64 KiB) | 2R, 0W | 1 cycle | `0x0000_0000`, 16 KiB decoded | NOP fill (`0x13`) + optional `$readmemh` |
| MEM-TCM | `tcm_inst` / `sram` (`ADDR_WIDTH=15`) | 8192 × 32 | 262,144 | 32,768 (32 KiB) | 2R, 1W ×4 byte lanes | 1 cycle | `0x0001_0000`, 32 KiB | none (undefined) |
| MEM-SRAM | `sram_inst` / `sram` (`ADDR_WIDTH=18`) | 65536 × 32 | 2,097,152 | 262,144 (256 KiB) | 2R, 1W ×4 byte lanes | 1 cycle | `0x2000_0000`, 128 KiB decoded | none (undefined) |
| MEM-DECODE-LUT | `$auto$proc_rom…` / `has_soc` | 16 × 9 | 144 | 18 | 1R, 0W | combinational | n/a (APB slot select) | constant, one-hot table |

Register-based storage (not `$mem_v2`, confirmed by Yosys replacing the arrays):

| ID | Structure | Depth × width | Bits | Access | Reset |
|---|---|---|---|---|---|
| REG-RF | `riscv_core/rf` | 32 × 32 | 1,024 | 2 async reads, 1 write | cleared by reset loop |
| REG-PLIC-PRIO | `plic/prio` | 8 × 8 (`NUM_SOURCES=8`) | 64 | bus read/write | cleared |

Memory-like structures that **do not exist** (checked, so their absence is not an
assumption): UART FIFO (`uart.sv:10,20,247` — FCR reads `0x01`), SPI/I²C/I²S/QSPI
buffers (shift registers only), no DMA buffers, no cache, no TLB, no trace buffer.

**Totals**

| Quantity | Bytes |
|---|---|
| Addressable storage declared by the map | 180,224 (16 + 32 + 128 KiB) |
| Inferred arrays implemented | 360,466 (64 + 32 + 256 KiB + 18 B) |
| Register storage | 136 (128 + 8) |

## 3. Reconciliation

| Region | `has_addr_map.sv` | Interconnect literal | Linker | Implemented array | Result |
|---|---|---|---|---|---|
| Boot ROM `0x0000_0000` | 16,384 | `0x0000_0000–0x0000_4000` | 16K | **65,536** | **MISMATCH ×4** |
| TCM `0x0001_0000` | 32,768 | `0x0001_0000–0x0001_8000` | 32K | 32,768 | match |
| SRAM `0x2000_0000` | 131,072 | `0x2000_0000–0x2002_0000` | 128K | **262,144** | **MISMATCH ×2** |
| APB `0x5000_0000` | 1,048,576 | `0x5000_0000–0x5010_0000` | — | — | match |
| QSPI `0x4000_0000` | 67,108,864 | `0x4000_0000–0x4400_0000` | 64M | off-chip | match |
| INTC `0x8000_0000` | 65,536 | `0x8000_0000–0x8001_0000` | — | — | match |

**Finding (F5, confirmed).** Four independent descriptions — address-map package,
interconnect decode, linker script and the 128 KB requirement (FR-MEM-001) — agree
with each other. The RTL array parameters disagree: the ROM is 4× and the SRAM 2×
larger than the aperture they are decoded into. The extra capacity is **not
reachable** (the interconnect never routes those addresses), so this is not a
functional bug; it is an area, PPA and macro-sizing bug, and it means the
implemented arrays are not what the specification says.

Which side is authoritative is a **decision, not a measurement**. Two options,
neither executed here (functional RTL is frozen for this audit):

- shrink the arrays to the map (`boot_rom ADDR_WIDTH 14`, `sram ADDR_WIDTH 17`);
  or
- enlarge the map, linker and requirements to 64 KiB / 256 KiB.

Until one is chosen, a macro cannot be ordered: its capacity would be wrong
either way.

**Structural drift risk (new control).** The address map is duplicated:
`has_addr_map.sv` declares the regions, while `axi_lite_interconnect.sv:114-120`
hardcodes the same numbers. `has_soc` also decodes APB slots from `paddr[19:12]`
independently. No tool tied these together before this audit;
`scripts/eda/audit_memory.js` now fails when the package, the interconnect, the
elaboration and `asic/synthesis/memory_inventory.json` disagree.

## 4. Classification

| ID | Current implementation | ASIC suitability |
|---|---|---|
| MEM-ROM | inferred ROM (`$mem_v2`, INIT constant) | not implementable as-is: 524,288 bits of inferred ROM |
| MEM-TCM | inferred SRAM (`$mem_v2`) | not implementable as-is |
| MEM-SRAM | inferred SRAM (`$mem_v2`) | not implementable as-is |
| MEM-DECODE-LUT | inferred ROM from a `case` | fine: should stay logic, not a macro |
| REG-RF | registers (`$adff`) | fine: 1,024 flops |
| REG-PLIC-PRIO | registers | fine: 64 flops |

No existing macro exists in the repository: no `.lib`, `.lef`, `.gds` or
blackbox for any SRAM/ROM, and no memory compiler has been run.
`docs/architecture/ARCHITECTURE_DECISION_RECORDS.md` ARC-043 records "OpenRAM
SkyWater 130nm, 128 KB, 32-bit, 1-cycle" as **PROPOSED**; it is a decision record,
not an implemented or verified macro.

## 5. Sky130 macro requirements

These are requirements derived from the RTL and the map. **They are not a claim
that any of them is available.** Nothing here has been checked against a real
macro datasheet, because no macro or compiler is present.

| Requirement | ROM (target 16 KiB) | TCM (32 KiB) | SRAM (target 128 KiB) |
|---|---|---|---|
| Words × width | 4096 × 32 | 8192 × 32 | 32768 × 32 |
| Ports | 2 read, 0 write | 2 read, 1 write | 2 read, 1 write |
| Write granularity | — | 4 byte-enable lanes | 4 byte-enable lanes |
| Read latency | 1 cycle (registered address) | 1 cycle | 1 cycle |
| Read-during-write | — | must match current RTL: read port sees the pre-write word in the write cycle | same |
| Initialization | contents fixed at manufacture; NOP fill is only a placeholder | none required; contents undefined at power-up | none required |
| Wrapper | AXI4-Lite read-only slave + instruction port, `ADDR_WIDTH` narrowed to the aperture | AXI4-Lite + instruction port | AXI4-Lite + instruction port |
| Clocking | single clock, no clock gating in RTL | single | single |

Unsupported or unverified configurations that block ordering:

1. **2R + byte-write SRAM**: the RTL needs two independent read ports plus a
   byte-enabled write port. Whether a sky130 macro supports 2R1W with byte
   enables has not been verified; a 1RW macro would need banking or duplication.
2. **Dual-read ROM**: the ROM is read from both the instruction path and the AXI
   path. A single-port ROM requires arbitration or duplication.
3. **256 KiB single instance at 1 cycle**: feasibility on sky130 is unverified;
   banking may be required (and would change the address decode).
4. **ROM initialization**: `$readmemh` has no direct ASIC equivalent. A mask ROM
   (programming step) or a preloaded SRAM (boot loader) must be chosen; today the
   default elaboration bakes only NOPs, so no boot image is in the netlist.
5. **No DFT/BIST**: no MBIST hooks, no test collar, no repair.

## 6. Exact blockers for ASIC implementation

1. **No memory macro exists** for ROM, TCM or SRAM (F7). They are inferred
   `$mem_v2` arrays that would synthesize to roughly 2.9 M flip-flop bits.
2. **No usable PDK**: sky130A is not volare-provisioned, so no OpenRAM/memory
   compiler can be run here to generate a macro, and no macro timing model exists.
3. **Capacity decision outstanding** (F5): ROM 64 KiB vs 16 KiB, SRAM 256 KiB vs
   128 KiB. A macro ordered before this decision is wrong by construction.
4. **Port/initialization strategy undecided**: 2R1W byte-enable support, dual-read
   ROM, and mask-ROM vs preloaded-SRAM boot are open choices.
5. **Read-during-write semantics** of any replacement macro must be checked
   against the RTL, which currently reads the pre-write word in the write cycle.

## 7. Controls

`scripts/eda/audit_memory.js` compares the four descriptions and exits
`0 PASS / 1 FAIL / 2 BLOCKED`. It never reports a declared gap as PASS.

| Control | Expected | Result |
|---|---|---|
| current design + inventory | exit 2 (consistent but unimplemented) | PASS |
| inventory entry removed | exit 1 | PASS |
| inventory depth edited | exit 1 | PASS |
| inventory claims the ROM mismatch is fixed | exit 1 | PASS |
| address-map ROM size changed | exit 1 | PASS |
| interconnect ROM aperture changed | exit 1 | PASS |
| ROM loses its initialization data | exit 1 | PASS |

Current verdict: **BLOCKED (exit 2)** — all consistency checks pass, six declared
gaps remain (four unimplemented memories, two size mismatches).

## 8. Automatically verified vs manually maintained

| Field | Verified by |
|---|---|
| depth, width, bits, `RD_PORTS`, `WR_PORTS`, `INIT` | elaboration (`memories.il` + `stat`) |
| address base/size, interconnect aperture | RTL parse of the two source files |
| array-vs-aperture match/mismatch | computed from the two rows above |
| totals | computed from the entries |
| register file / PLIC array sizes | RTL + Yosys "replacing memory with registers" log |
| UART has no FIFO | RTL comment and read path |
| which side of the F5 mismatch is authoritative | **manual decision, not proven** |
| macro requirements and unsupported configurations | **manual analysis, not verified against a macro** |

`asic/synthesis/memory_inventory.json` marks each row with `verified_by` so the
manual assumptions cannot be mistaken for measurements.

## 9. Limitations

- No macro, no PDK, no compiler: the requirements table is a specification, not a
  compatibility statement, and no capacity/area/timing figure is claimed.
- The audit runs at `025ef24` + dirty worktree; `memories.il` and the stat JSON
  are generated artifacts (gitignored), recorded with hashes in RUN-0009.
- Functional RTL was deliberately not modified; the F5 discrepancy is reported,
  not fixed.
- Self-reviewed only. No independent evaluator exists in this environment.
