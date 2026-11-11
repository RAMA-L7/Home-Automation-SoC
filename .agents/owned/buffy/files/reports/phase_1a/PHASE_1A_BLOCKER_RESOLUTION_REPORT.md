# Phase 1A Blocker Resolution Report

The Phase 0 architecture identified three blockers that prevent an architecture freeze or RTL development.  This report analyses each blocker in detail, extracts the exact description from the current closure matrix, and assesses possible resolution pathways.

---

## ARC‑035 – Architecture‑freeze blocker
**Description (from matrix):** *Architecture‑freeze blocker – pending final processor approval.*
**Impact:**
- Prevents the architecture from being considered immutable.
- Stops any downstream RTL work because the core selection influences bus, memory map, interrupt controller, and power domains.

**Resolution Options:**
1. **Human Approval of ARC‑001 (Ibex selection).** Once the core is approved, the freeze can be lifted. No technical change required – just a sign‑off.
2. **Alternative Core Evaluation.** If stakeholders reject Ibex, a new core must be selected, which would cascade to multiple decisions (ARC‑010, ARC‑011, ARC‑012, ARC‑003, etc.). This would re‑open many decisions.

**Recommended Path:** Obtain explicit human approval for ARC‑001 (Ibex RV32IMC). No further technical work is needed.

---

## ARC‑036 – RTL verification requirement
**Description:** *RTL verification requirement – formal CDC proofs needed.*
**Impact:**
- Blocks RTL development because clock‑domain‑crossing verification is mandatory for functional correctness.
- Formal proofs are not currently part of the verification plan (see docs/architecture/CLOCK_RESET_AND_POWER_ARCHITECTURE.md).

**Resolution Options:**
1. **Add Formal CDC Proof Tasks to Verification Plan.** Define properties, select a formal tool (e.g., SymbiYosys), and allocate resources. Once defined, the blocker can be cleared.
2. **De‑risk with Extensive Simulation.** Accept a risk‑based approach using directed simulation of CDC paths, but this would keep the blocker status (still BLOCKED) because formal sign‑off is required for safety‑critical designs.

**Recommended Path:** Adopt option 1 – extend the verification plan (documented in docs/architecture/VERIFICATION – not yet created) with formal CDC proof tasks. This will move ARC‑036 from BLOCKED to PROPOSED (pending evidence).

---

## ARC‑037 – ASIC sign‑off blocker
**Description:** *ASIC sign‑off blocker – DFT/ATPG and IR‑drop analysis pending.*
**Impact:**
- Prevents tape‑out because manufacturing requires DFT coverage and power‑integrity verification.
- Does not block FPGA prototyping, but ASIC production cannot proceed.

**Resolution Options:**
1. **Acquire Commercial DFT/ATPG Tooling.** Use Synopsys DFT Compiler or Mentor Tessent to generate scan chains and ATPG patterns.
2. **Open‑Source Approximation.** Use limited open‑source DFT scripts (e.g., OpenROAD openroad -script dft.tcl) – currently not mature; would keep the blocker.
3. **Outsource Sign‑off.** Engage a foundry‑approved service provider to run DFT and IR‑drop analysis on behalf of the project.

**Recommended Path:** Pursue option 1 or 3. At minimum, a commercial DFT flow must be committed before ASIC sign‑off. Until then, ARC‑037 remains BLOCKED.

---

## Summary of Blocker Status after Review
- **ARC‑035:** Ready for human approval – status will change to PENDING APPROVAL → APPROVED after sign‑off.
- **ARC‑036:** Needs verification plan amendment – status changes to PROPOSED (pending evidence of formal proof task).
- **ARC‑037:** Requires DFT/IR‑drop tooling commitment – remains BLOCKED until a tool or service is procured.

These actions will clear the architecture‑freeze blockers and allow RTL development to commence.
