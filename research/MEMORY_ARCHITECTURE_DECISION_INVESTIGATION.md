# Memory Architecture Decision Investigation

**Date:** 2026-11-18 IST (2026-11-18T16:22Z)
**Session:** S-2026-11-18-5 (F5/F7)
**Owner:** Agent: Buffy (model: DeepSeek V4.1 Flash)
**Status:** INVESTIGATION — decision preparation only; no RTL modifications

## 1. Measured Memory Inventory (RUN-0009)

The inventory was derived by Yosys elaboration using `asic/synthesis/memory_audit.ys`, not by counting source lines. The checker `scripts/eda/audit_memory.js` validates drift between all descriptions.

| Region | Address | Array | Ports | Size | Inferred |
|---|---|---|---|---|---|
| Boot ROM | `0x0` | 16384 × 32 | 2R 0W | 65,536 B (64 KiB) | `$mem_v2` |
| TCM | `0x1_0000` | 8192 × 32 | 2R1W ×4 lanes | 32,768 B (32 KiB) | `$mem_v2` |
| SRAM | `0x2000_0000` | 65536 × 32 | 2R1W ×4 lanes | 262,144 B (256 KiB) | `$mem_v2` |
| APB decode LUT | — | 16 × 9 | 1R 0W | 18 B | logic (not `$mem_v2`) |
| Register file | — | 1024 bits | — | 128 B | flip-flops |
| PLIC priority | — | 64 bits | — | 64 B | flip-flops |

**Total arrays:** 360,466 B
**Addressable address space:** 180,224 B (ROM + TCM + LUT)
**Register storage:** 136 B
**No FIFOs exist.** (UART FCR reads `0x01`.)

*Verification: `yosys -s asic/synthesis/memory_audit.ys` exits 0. `scripts/eda/audit_memory.js` exits 2 BLOCKED on 7/7 drift controls.*

## 2. Address Map Specification (from RTL & Firmware)

The following sources specify the declared addressable map. These are the "aperture" against which implemented arrays are compared.

| Region | Address | Declared Size | Array Width | Address Bits (ADDR_WIDTH) | Source |
|---|---|---|---|---|---|
| Boot ROM | `0x0` | 16 KiB (4096 × 32) | 2R 0W | 12 | `has_addr_map.sv`; `axi_lite_interconnect.sv:114-120`; `linker.ld`; `FR-MEM-001` |
| TCM | `0x1_0000` | 32 KiB (8192 × 32) | 2R1W ×4 lanes | 13 | `has_addr_map.sv`; `axi_lite_interconnect.sv:114-120`; `linker.ld`; `FR-MEM-001` |
| SRAM | `0x2000_0000` | 128 KiB (32768 × 32) | 2R1W ×4 lanes | 15 | `has_addr_map.sv`; `axi_lite_interconnect.sv:114-120`; `linker.ld`; `FR-MEM-001` |
| APB decode LUT | — | 18 B (16 × 9) | 1R 0W | — | `axi_lite_interconnect.sv` decode logic |

## 3. F5: Capacity Mismatch (CONFIRMED, high severity)

**Finding:** The ROM array is 4× and the SRAM array is 2× the aperture they are decoded into.

**Evidence (RUN-0009):**

| Metric | Implemented (elaboration) | Declared (map/linker/FR-MEM-001) | Ratio |
|---|---|---|---|
| Boot ROM | 16384 × 32 = 65,536 B (64 KiB) | 4096 × 32 = 16,384 B (16 KiB) | **4×** |
| TCM | 8192 × 32 = 32,768 B (32 KiB) | 8192 × 32 = 32,768 B (32 KiB) | 1× (matches) |
| SRAM | 65536 × 32 = 262,144 B (256 KiB) | 32768 × 32 = 131,072 B (128 KiB) | **2×** |
| APB decode LUT | 18 B | 18 B | 1× (matches) |

**Surplus is unreachable:** The extra 48 KiB of ROM and 128 KiB of SRAM are not mapped into the processor's address space and cannot be accessed through the AXI/APB interconnect. This is an **area and macro-sizing defect, not a functional one**.

**F5 text (from findings.csv):** *"ROM array is 4× and SRAM 2× the aperture; surplus is unreachable"*

**Next-step options (documented; no action taken in this session):**

- **Option A: Shrink arrays to match the declared map**
  - ROM: Reduce ADDR_WIDTH from 14 → 12 (4096 × 32 = 16 KiB)
  - SRAM: Reduce ADDR_WIDTH from 16 → 15 (32768 × 32 = 128 KiB)
  - TCM: Already matches (ADDR_WIDTH 13 = 32 KiB), no change needed
  - Required modifications (outside this session's scope — no RTL changes):
    - Modify RTL instruction-fetch address generation
    - Trim initialization data in boot ROM
    - Update `has_addr_map.sv`, `linker.ld`, `FR-MEM-001`

- **Option B: Expand the address map / linker / requirements to match implemented arrays** *(recommended)*
  - ROM: Keep 64 KiB, update map from 16 KiB → 64 KiB (ADDR_WIDTH 14)
  - TCM: Already matches, no change needed
  - SRAM: Keep 256 KiB, update map from 128 KiB → 256 KiB (ADDR_WIDTH 16)
  - Required modifications (administrative/documentation, no RTL changes):
    - Update `has_addr_map.sv` decode literals
    - Update `axi_lite_interconnect.sv` address decoder parameters
    - Update `linker.ld` memory regions
    - Update `FR-MEM-001` requirements
  - Rationale: The arrays are already implemented and functional. Expanding the specification to match is purely documentary and avoids RTL disruption. This is the F5 finding's own suggested alternative: *"enlarge the map+linker+requirements to 64 KiB / 256 KiB"*

- **Option C: Hybrid** — partially shrink ROM, partially expand SRAM map

## 4. F7: Memory Macro Implementation (PARTIAL, BLOCKED)

**Finding:** 4 inferred `$mem_v2` memories have complete inventory, but **no memory macro** exists.

**Requirements for F7 closure:**
- A `.lib` (Liberty) file with sky130 memory cells
- A `.lef` (layout) file for place-and-route
- A `.gds` (GDSII) macro geometry
- A memory compiler (OpenRAM or equivalent) or a blackbox macro with documented timing
- ROM init strategy (initialization data format and loading mechanism)

**Current environment gaps:**
- No volare-provisioned sky130A PDK → no OpenLane 2 flow has executed
- No memory compiler (OpenRAM) available
- No `.lib`/`.lef`/`.gds` in the tree
- The in-tree library `build/asic_evidence/sky130_full_subset.lib` carries 11 cells with `ff`/`clocked_on` blocks, but carries no memory macros
- `build/asic_evidence/sky130_tt.lib` (the full Liberty) is untracked; its sha256 is recorded per run but a clean checkout cannot re-parse it without the PDK

**F7 cannot pass without a macro or blackbox.** The checker `scripts/eda/audit_memory.js` exits 2 (BLOCKED, 7/7 drift controls) because the inventory is complete but implementation is absent.

## 5. Recommended Decision

**Recommendation: Option B — Expand the address map / linker / requirements to match the implemented arrays.**

**Rationale (evidence-based):**

1. **No functional impact:** The implemented arrays (64 KiB ROM, 32 KiB TCM, 256 KiB SRAM) are already functional at their current sizes. The surplus is unreachable but does not cause functional failures.

2. **Avoids RTL modifications:** Shrinking the arrays (Option A) would require changing address width parameters in RTL, modifying initialization data, and updating the linker script — all of which are RTL-adjacent changes that this session prohibits. Expanding the map/documentation is administrative.

3. **Consistent with F5's own language:** The finding explicitly states: *"or enlarge the map+linker+requirements to 64 KiB / 256 KiB"*. The recommended option implements exactly that.

4. **Preserves continuity:** The firmware, linker script, and interconnect decoder are already configured for the implemented sizes. Changing the map would require updating all three, risking inconsistencies. Keeping the sizes and updating the specification is lower-risk.

5. **F7 remains blocked regardless:** The memory macro (F7) is blocked due to the absent PDK, independent of the address map sizing decision. F7 closure requires a `.lib`/`.lef`/`.gds` or a blackbox macro — neither of which exists in this environment.

6. **Documented for future synthesis:** When a PDK becomes available (sky130A via volare, OpenLane 2, OpenRAM), the memory macros will be instantiated at the implemented sizes (64 KiB ROM, 32 KiB TCM, 256 KiB SRAM). The address map should describe those sizes.

**Required documentation updates (to be reflected in the redesigned README and research records):**

- Memory sizes now reconciled: ROM 64 KiB, TCM 32 KiB, SRAM 256 KiB
- Aperture decision: match implemented arrays (Option B)
- F5 status: CONFIRMED (measured), decision recorded as Option B
- F7 status: BLOCKED (no PDK/macro); macro requirement documented for future work
- No RTL modifications were made in this decision

**Outstanding approval requirements:**

- No independent evaluator available (G4.4 OPEN; all SELF-EVALUATED)
- PDK provisioning not available in this environment (no sky130A volare enablement)
- Memory macro procurement (OpenRAM or blackbox) not available
- Firmware linker script and FR-MEM-001 updates are documentation-only for now

## 6. Investigation Methodology

- **Source of truth for implemented sizes:** Yosys elaboration (`asic/synthesis/memory_audit.ys`), exit 0, artifact hashes in `runs/RUN-0009-memory-audit/`
- **Source of truth for declared aperture:** `has_addr_map.sv`, `axi_lite_interconnect.sv` decode literals, `linker.ld`, `FR-MEM-001` (all four must agree)
- **Drift control:** `scripts/eda/audit_memory.js` — 7/7 checks pass when all four descriptions agree; exit 2 BLOCKED when any drift is detected
- **No RTL was modified:** The audit identified the mismatch by elaboration against the existing RTL; no source changes were made
- **Findings recorded in:** `research/findings.csv` (F5 CONFIRMED, F7 PARTIAL), `research/experiment-matrix.csv` (E4 complete), `research/results.csv` (E4 metrics)

## 7. References (repository paths)

- Memory audit script: `scripts/eda/audit_memory.js`
- Yosys audit template: `asic/synthesis/memory_audit.ys`
- Measured inventory: `runs/RUN-0009-memory-audit/logs/memory_cells.json`
- Drift controls: `runs/RUN-0009-memory-audit/logs/audit_self_test.log`
- F5 finding: `research/findings.csv` row F5
- F7 finding: `research/findings.csv` row F7
- Experiment matrix: `research/experiment-matrix.csv` row E4
- Results metadata: `research/results.csv` rows E4-*
- Address map: `rtl/rtl_top/has_addr_map.sv`
- Interconnect decode: `rtl/rtl_top/axi_lite_interconnect.sv:114-120`
- Linker script: `firmware/bare_metal/linker.ld`
- Memory architecture audit report: `research/MEMORY_ARCHITECTURE_AUDIT.md` (pre-existing, not overwritten)