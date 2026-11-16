# Home-Automation-SoC — ASIC SRAM Macro Wrapper Architecture Decision Record

**Document type:** Architecture decision record (documentation and planning only)  
**Date:** 2026-11-14  
**Repository:** `D:\Home-Automation-SoC`  
**Branch:** `main`  
**HEAD:** `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`  
**Specification:** `reports/ASIC_MEMORY_WRAPPER_ARCHITECTURE_SPEC.md`  
**Specification SHA-256:** `8d7221f7e195a11ece2881f97a2d3cfeb4cb9b23677c4e9184060a01550d71b5`  

**Status:** All decisions are PROPOSED. No decision is APPROVED.

No implementation has been started. No RTL, wrapper, testbench, script, filelist, PDK, SDC, evidence, or specification file was modified to produce this record.

---

## 1. Repository integrity

- Branch: `main`
- HEAD: `420f46ba5c78ede16b9a8ab1e840f8dffcf983f1`
- Tracked working-tree diff hash: `f0245fac670fd4a4920637f3f543e22b3266e658f1cfa16f993fb63bc097990d`
- Working tree contains tracked modifications and untracked files. All existing changes were preserved.
- No mutating Git operations were performed. Repository state was inspected using read-only commands.
- Missing source documents:
  - `reports/ASIC_MEMORY_WRAPPER_IMPLEMENTATION_READINESS_REVIEW.md` does not exist in the repository. Earlier readiness findings were produced in-session and are not a repository file, so they are not claimed as independently inspected.
  - No SRAM wrapper RTL, wrapper testbench, or macro-model integration files currently exist.

---

## 2. Decision table

All decisions remain `PROPOSED`. No decision is marked `APPROVED`.

| ID | Proposed decision | Rationale | Conflicts / implications | Status |
|----|-------------------|-----------|--------------------------|--------|
| D1 | Zero `WSTRB`: skip macro access and return `OKAY` using the normal one-cycle write response | Matches spec F-09 (zero-strobe write produces no data change and an `OKAY` response) and P-07 (all 16 `WSTRB` combinations). Skipping avoids macro access, power, and collision side effects | No conflict with the specification. Implication: wrapper must not assert `csb0` for a zero-strobe write and must still return `BVALID` in the normal one-cycle response. Verification must prove no macro write occurs | PROPOSED |
| D2 | Unaligned AXI addresses: return `SLVERR` and perform no macro access | Matches spec P-06 and N-02. The core traps misaligned word/halfword accesses and does not issue them; this is defensive protocol behavior | No conflict with the core. The wrapper must check byte-address alignment before bank and word decode. The interconnect must propagate `bresp`/`rresp` | PROPOSED |
| D3 | Instruction-fetch collision: use stall-only handling for same-bank, same-macro-word collisions | Spec recommends stall-only for the first implementation; simpler and avoids forwarding bugs | No conflict. Same-macro-word fetch waits one cycle. Differing AXI slices within the same macro word still collide | PROPOSED |
| D4 | Boot ROM: retain the existing `boot_rom` module and exclude it from the first SRAM/TCM wrapper scope | Existing `has_soc.sv` uses `boot_rom`. This avoids changing the boot path and initialization flow in the first implementation | No conflict with current RTL. The existing `boot_rom` remains unchanged. No standard-cell or SRAM-backed implementation claim is made without synthesis evidence | PROPOSED |
| D5 | SRAM address width: use a 17-bit region-sized address for the 128 KB SRAM and enforce bounds | Matches the 128 KB SRAM region | Conflict: existing behavioral `sram` uses an 18-bit width for a 256 KB array, while the SRAM region is 128 KB. The wrapper is stricter and must reject out-of-region addresses. The complete incoming address must be checked before truncation; the current `has_soc` slicing to 18 bits may discard upper address bits, so this interface issue is OPEN | PROPOSED |
| D6 | TCM address width: use a 15-bit region-sized address for the 32 KB TCM and enforce bounds | Matches the 32 KB TCM region | No conflict with the existing TCM `sram` instance. Bounds and bank decode must be validated | PROPOSED |
| D7 | Forwarding: defer forwarding until stall-only behavior passes verification | Reduces first-implementation risk | No conflict. Initial fetch latency during a collision remains 2 cycles | PROPOSED |
| D8 | Macro timing: use available TT characterization for initial implementation checks only | Only TT Liberty is available for this macro | No conflict. TT-only checks do not imply multi-corner timing closure or ASIC signoff | PROPOSED |
| D9 | AXI protocol: implement independent AW/W capture, one outstanding write, stable `BVALID`/`RVALID` responses, and partial-write read backpressure | Matches spec F2 and F6 | Conflict: existing behavioral `sram` requires AW and W in the same cycle and gives writes priority over reads. The wrapper differs from the behavioral model and must be integration-tested through the existing interconnect | PROPOSED |
| D10 | Verification: require all specification test IDs to pass before declaring wrapper functional verification complete | Prevents claiming unverified wrapper functionality | No conflict. Substantial new testbench work is required before completion | PROPOSED |

---

## 3. Address-width and alignment definitions

### 3.1 Complete address check before truncation

- The wrapper must validate the complete incoming address before using any truncated word/bank address.
- For SRAM, the valid region is 128 KB. For TCM, the valid region is 32 KB.
- An access outside the valid region must return `SLVERR` and must not access any macro.
- The current `has_soc` integration passes sliced addresses (`s_awaddr[2][17:0]` and `s_araddr[2][17:0]` for SRAM; `s_awaddr[1][14:0]` and `s_araddr[1][14:0]` for TCM). This may discard upper address bits before the wrapper can enforce region bounds.
- **OPEN:** The wrapper interface and `has_soc` address routing must be revised so the complete address is available for bounds checking, or an upstream region decode must reject out-of-region accesses before truncation.

### 3.2 Word alignment versus byte/halfword operations

- The AXI interface is 32 bits wide. A legal AXI word address must have `addr[1:0] == 0`.
- Byte and halfword operations are represented by `WSTRB` within an aligned 32-bit word, not by unaligned addresses.
- An AXI address with `addr[1:0] != 0` is unaligned and must return `SLVERR` with no macro access.
- The RISC-V core traps misaligned load/store addresses before issuing a request, so wrapper rejection is defensive protocol behavior.

---

## 4. Boot ROM handling

- The existing `boot_rom` module remains unchanged.
- The boot ROM is excluded from the first SRAM/TCM wrapper scope.
- No claim is made that the boot ROM is implemented as standard-cell ROM or as an SRAM-backed macro. That implementation status is not supported by synthesis evidence in the repository.

---

## 5. Behavioral differences relative to the existing behavioral SRAM

The following proposed decisions change or clarify behavior relative to the existing behavioral `sram.sv` implementation:

- D1: zero-strobe writes skip macro access while retaining the normal one-cycle AXI write response.
- D2: unaligned AXI addresses return `SLVERR` instead of indexing the behavioral array.
- D3: same-bank, same-macro-word instruction-fetch collisions stall instead of relying on undefined concurrent access behavior.
- D5: SRAM access is restricted to the 128 KB region instead of the 256 KB behavioral array range.
- D9: AW and W are captured independently, with one outstanding write, stable responses, and partial-write read backpressure.

Boot ROM exclusion is not an SRAM behavioral change and is not listed above.

The behavioral `sram.sv` module is retained unchanged in the initial implementation scope for simulation use.

---

## 6. Final implementation scope

First implementation scope is SRAM and TCM only.

Included:
- SRAM: 128 KB, 32 banks of 4 KB macros.
- TCM: 32 KB, 8 banks of 4 KB macros.
- AXI4-Lite slave interface.
- Instruction-fetch read port.
- 32-bit to 128-bit width adaptation.
- Byte-write mask mapping.
- Bank and macro-word collision handling.
- Independent AW/W handling.
- Asynchronous reset handling.
- Partial-write read backpressure.

Excluded from first scope:
- Boot ROM wrapper.
- Boot ROM implementation or initialization changes.
- Forwarding optimization.
- Multi-corner timing signoff.
- FPGA or ASIC flow execution.
- Any production RTL change outside approved wrapper and integration files.

---

## 7. Exact files expected to change during implementation

Likely new files:
- `rtl/rtl_top/sram_macro_wrapper.sv` or an approved equivalent name.
- Wrapper testbench files under `sim/sim_top/`.
- Macro-model simulation integration files or filelist entries.

Likely modified files:
- `rtl/rtl_top/has_soc.sv` to replace TCM and SRAM `sram` instances with the wrapper.
- `rtl/filelist.f` to add wrapper and macro model files.
- Simulation scripts or filelists as needed.

Files that should remain unchanged in the first scope:
- `rtl/rtl_top/sram.sv`
- `rtl/rtl_top/boot_rom.sv`
- `rtl/rtl_top/riscv_core.sv`
- PDK, SDC, evidence, and unrelated RTL.

---

## 8. Verification ID coverage

All listed IDs are required before wrapper functional verification can be declared complete. All are currently BLOCKED because no wrapper implementation or wrapper tests exist.

Functional:
- F-01 to F-10

Concurrency:
- C-01 to C-07
- C-02A

Protocol:
- P-01 to P-08

Negative:
- N-01 to N-05

AXI channel independence and collision:
- AXI-01 to AXI-09
- COLL-01 to COLL-05
- COLL-03A

Macro-word, reset, and partial-write:
- MACWORD-01 to MACWORD-05
- RESET-01 to RESET-03
- PARTIAL-01 to PARTIAL-04

Additional required checks:
- Bank isolation.
- Address bounds.
- Zero-strobe macro-access verification.
- Unaligned-address rejection.
- Macro integration.
- Synthesis and structural checks.
- Existing regression after TCM/SRAM integration.

---

## 9. Remaining OPEN decisions

- Exact wrapper module name and file path.
- Exact bank-address equations and bounds-check behavior.
- How the complete incoming address is preserved for bounds checking.
- Whether TCM and SRAM use one parameterized wrapper or two wrappers.
- Macro simulation model source and filelist integration.
- Memory initialization method for macro-backed TCM/SRAM in simulation.
- Whether out-of-region access is rejected before or after bank decode.
- Whether zero-strobe writes fully skip transaction state or only skip macro access.
- Whether forwarding is reconsidered after stall-only verification passes.
- Boot ROM implementation status, pending synthesis evidence.

---

## 10. Approval checklist

### Architecture decisions
- Approve D1 zero-strobe skip-access behavior.
- Approve D2 `SLVERR` for unaligned and out-of-region accesses.
- Approve D3 stall-only collision handling.
- Approve D4 retention of `boot_rom` and exclusion from first scope.
- Approve D5 17-bit SRAM address width.
- Approve D6 15-bit TCM address width.
- Approve D7 deferred forwarding.
- Approve D8 TT-only timing limitation.
- Approve D9 independent AW/W and partial-write backpressure.
- Approve D10 full specification test-ID pass requirement.

### File creation and modification permission
- Create the SRAM/TCM wrapper RTL file.
- Update the RTL file list.
- Modify `has_soc.sv` to instantiate the wrapper for TCM and SRAM.
- Create or update wrapper testbenches and simulation integration files.

### Verification and simulation permission
- Run wrapper-specific simulations.
- Run macro-model integration checks.
- Run existing regression after integration.

### Synthesis and structural-check permission
- Run lint, synthesis, and structural checks for the wrapper and macro integration.

Stop and wait for explicit approval. No implementation has been started.
