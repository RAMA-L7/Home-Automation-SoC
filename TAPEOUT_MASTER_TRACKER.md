# Home-Automation-SoC — Tapeout Master Tracker

**Project:** Low-power residential home-automation RISC-V SoC
**Repository:** `D:\Home-Automation-SoC`
**Tracker owner:** Tapeout program (single authority; supersedes ad-hoc stage tables in `AGENTS.md`)
**Last audit:** 2026-11-15
**Baseline revision:** `3fb1f0492b0dd460bd70d1a06a36b536b3d4280e` (branch `main`)

---

## 4.1 Executive status

| Field | Value |
|---|---|
| Current stage | **Stage 1 — READY FOR APPROVAL** (analysis complete; mandatory decisions unapproved) |
| Overall project status | **NOT TAPEOUT-READY.** Functional RTL prototype verified in simulation; one block (timer) physically implemented as an experiment; no full-SoC synthesis, no approved constraints, no full-chip physical implementation, no DFT, no GDSII. |
| Completed stages | 0 |
| Active stage | 1 — Architecture and requirements closure (READY FOR APPROVAL) |
| Blocked stages | 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 (dependency chain from 7/8) |
| Next stage | **Stage 1 owner approval**, then Stage 2 (must not start before approval) |
| Critical blockers | BLK-001 clock architecture unapproved; BLK-002 memory size contradictions; BLK-003 SDC not approvable; BLK-004 full-SoC synthesis parse failure; BLK-005 memory macro not integrated; BLK-006 secure boot verifier absent; BLK-007 no DFT; BLK-008 no UPF/power intent; BLK-019 pin budget; BLK-020 macro area; BLK-021 no 3.3 V pads; BLK-023 unassigned role owners |
| Last audit date | 2026-11-15 |

### Status legend

`NOT STARTED` · `IN PROGRESS` · `BLOCKED` · `VERIFICATION FAILED` · `READY FOR AUDIT` · `READY FOR APPROVAL` · `COMPLETE`

Completion is the count of **met acceptance criteria / total acceptance criteria**, not a subjective percentage. A criterion is met only with an evidence path in `TAPEOUT_EVIDENCE_REGISTRY.md`.

---

## 4.2 Stage summary

| Stage | Name | Status | Completion | Evidence | Blockers |
|---|---|---|---:|---|---|
| 0 | Baseline and environment audit | **COMPLETE** | 8/8 | `reports/TAPEOUT_STAGE0_BASELINE_AUDIT.md`, registers | — |
| 1 | Architecture and requirements closure | **READY FOR APPROVAL** | 2/10 | `reports/ASIC_STAGE1_*`; `architecture/*.json/csv` | BLK-001/002/003/005/008/019/020/021/023 |
| 2 | RTL implementation closure | IN PROGRESS | 2/6 | 23 modules, 22/22 sim | BLK-001, BLK-002, BLK-006, BLK-015 |
| 3 | IP and memory integration | IN PROGRESS | 1/6 | inferred memories, macro audit | BLK-002, BLK-005 |
| 4 | Functional verification | IN PROGRESS | 2/5 | regression 22/22, firmware demo | BLK-010, BLK-011, BLK-015 |
| 5 | Formal verification | IN PROGRESS | 1/5 | 5/5 proofs (block-level) | BLK-013 |
| 6 | Clock/reset/CDC/RDC closure | BLOCKED | 1/5 | CDC inventory 12 rows | BLK-001, BLK-008, BLK-013 |
| 7 | Full-SoC synthesis | BLOCKED | 0/8 | Yosys parse failure logged | BLK-004 |
| 8 | SDC and timing closure | BLOCKED | 1/6 | provisional timer SDC only | BLK-003 |
| 9 | Full-chip floorplanning | NOT STARTED | 0/6 | timer block experiment only | BLK-005, BLK-008 |
| 10 | Power planning | NOT STARTED | 0/6 | timer PDN only; no UPF | BLK-008 |
| 11 | Full-chip placement | NOT STARTED | 0/5 | timer block placement only | Stage 7/9/10 |
| 12 | Full-chip CTS | NOT STARTED | 0/5 | timer CTS experiment (4.18–4.22) | Stage 7/11 |
| 13 | Full-chip routing | NOT STARTED | 0/5 | timer routing experiment | Stage 12 |
| 14 | Physical verification | NOT STARTED | 0/6 | timer DRC 0; no LVS ever | BLK-009, BLK-012 |
| 15 | Timing/electrical signoff | NOT STARTED | 0/7 | experimental timer STA only | Stage 8/13 |
| 16 | DFT and manufacturing readiness | NOT STARTED | 0/5 | none | BLK-007 |
| 17 | GDSII generation and final audit | NOT STARTED | 0/6 | none | Stages 13–16 |
| 18 | Tapeout package | NOT STARTED | 0/7 | none | Stage 17 |

---

## 4.3 Detailed stage records

### Stage 0 — Project baseline and environment audit — COMPLETE

- **Objective:** Establish reproducible inventory and evidence baseline.
- **Entry criteria:** Repository access; tool environment known.
- **Requirements:** Inventory RTL/docs/verification/PD; classify every claim; create tracker, registers, roadmap.
- **Implementation tasks:** Repository scan, module inventory, evidence hash capture, preservation audit.
- **Verification tasks:** Re-ran regression (22/22, iverilog 14.0); inspected formal status (5/5); inspected synthesis logs; inspected PD artifacts.
- **Audit tasks:** Confirmed no tracked modifications; confirmed production artifacts unchanged; cross-checked docs against RTL.
- **Acceptance criteria (8):** inventory complete; 23 modules classified; verification evidence audited; synthesis status established; PD status established; registers created; contradictions recorded; preservation verified. **All 8 met.**
- **Dependencies:** none.
- **Evidence:** `reports/TAPEOUT_STAGE0_BASELINE_AUDIT.md`, `TAPEOUT_EVIDENCE_REGISTRY.md`, `TAPEOUT_DECISION_REGISTER.md`, `TAPEOUT_BLOCKER_REGISTER.md`.
- **Known issues:** historical `AGENTS.md` status tables contradict measured state; `build/verify/summary.txt` claims 25/25 regression while the current runner executes 22 tests.
- **Blockers:** none.
- **Completion approval:** Stage 0 audit, 2026-11-15.
- **Completion date:** 2026-11-15.

### Stage 1 — Architecture and requirements closure — READY FOR APPROVAL

- **Objective:** Resolve SoC architecture and requirements so RTL implementation can proceed without rework.
- **Entry criteria:** Stage 0 complete.
- **Requirements:** Approved clock/reset/power/security architecture; memory map matching RTL; interface spec; requirements traceability; decision register closed for blocking items.
- **Implementation tasks:** Completed the Stage 1 investigation and prepared decision packages; no architecture change was implemented (per Stage 1 scope).
- **Verification tasks:** Compared every architecture document against RTL and firmware; re-ran regression evidence review; built 124-row traceability; computed memory macro area; audited 50 interfaces and 31 CDC/RDC paths.
- **Audit tasks:** Self-audit completed. Independent human architecture audit has not been performed.
- **Acceptance criteria (10):** (1) ARC-006 approved — **NO**; (2) ARC-036/065 approved — **NO**; (3) ARC-041 recorded/approved — **YES** (historical); (4) one memory architecture approved — **NO**; (5) peripheral clock strategy approved — **NO**; (6) AON/power approved or descoped — **NO**; (7) traceability complete for mandatory requirements — **YES**; (8) no unresolved decision blocking Stage 2 — **NO**; (9) role owners assigned — **NO**; (10) independent architecture audit passed — **NO**. **Met: 2/10.**
- **Dependencies:** none (Stage 0 complete).
- **Evidence:** `reports/ASIC_STAGE1_ARCHITECTURE_AUDIT.md`, `ASIC_STAGE1_CLOCK_ARCHITECTURE.md`, `ASIC_STAGE1_CDC_RDC_ARCHITECTURE.md`, `ASIC_STAGE1_MEMORY_ARCHITECTURE.md`, `ASIC_STAGE1_POWER_ARCHITECTURE.md`, `ASIC_STAGE1_SECURITY_BOOT_ARCHITECTURE.md`, `ASIC_STAGE1_REQUIREMENTS_TRACEABILITY.md`, `ASIC_STAGE1_INTERFACE_AND_ADDRESS_MAP.md`, `ASIC_STAGE1_DECISION_PACKAGE.md`; `architecture/*`.
- **Known issues:** 17 discrepancies (D-01…D-17); clock/memory/core/pin/power/security baselines are unapproved; 12 decisions await owner approval; security and OTA cannot be claimed.
- **Blockers:** BLK-001, BLK-002, BLK-003, BLK-005, BLK-008, BLK-019, BLK-020, BLK-021, BLK-023.
- **Completion approval:** pending owner decisions.
- **Completion date:** —

### Stage 2 — RTL implementation closure — IN PROGRESS

- **Objective:** Complete all required synthesizable RTL.
- **Entry criteria:** Stage 1 decisions sufficient for the affected blocks.
- **Requirements:** No unintended stubs; consistent clocks/resets; all peripherals complete to approved spec.
- **Implementation tasks:** 23 modules exist. Missing/incomplete: 25 MHz peripheral divider, AON 32 kHz domain, QSPI program/erase, secure-boot verifier, OTA path, core `rresp/bresp` handling, JTAG DMI/IDCODE, SPI modes >0, `pstrb` support.
- **Verification tasks:** 22/22 Icarus regression passes; Verilator lint 0 errors (historical, not re-run); no lint gate in current suite.
- **Audit tasks:** Module-by-module review against Stage 1 spec; none performed yet.
- **Acceptance criteria (6):** (1) all approved modules implemented; (2) clock/reset consistent with Stage 1; (3) no undocumented stubs; (4) lint clean under pinned rules; (5) independent RTL review; (6) traceability from requirements to modules. **Met: 2/6** (modules exist; regression passes).
- **Dependencies:** Stage 1 decisions.
- **Evidence:** `rtl/**/*.sv`, `sim/sim_top/*`, `build/sim/regression.log`.
- **Known issues:** `debug_jtag` synthesized 0 cells historically (stub-like); `qspi_flash_ctrl` program/erase absent; boot verifier absent; single clock only.
- **Blockers:** BLK-001, BLK-002, BLK-006, BLK-015.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 3 — IP and memory integration — IN PROGRESS

- **Objective:** Integrate processor, memories, bus, peripherals, external IP.
- **Entry criteria:** Stage 2 modules stable.
- **Requirements:** Memory macros mapped; address decode matching sizes; interrupt wiring; interface validation.
- **Implementation tasks:** CPU is in-repo `riscv_core` (no external core IP). Memories are inferred arrays (`boot_rom`, two `sram`). Sky130 macro `sky130_sram_1rw1r_128x256_8` audited but not instantiated.
- **Verification tasks:** Full-SoC boot sim exercises ROM, TCM, SRAM, GPIO, UART, PLIC, PWM, power manager.
- **Audit tasks:** Macro interface audit complete (4 KB macro, 16-bit mask, 1rw+1r).
- **Acceptance criteria (6):** (1) CPU integrated and verified; (2) all memories macro-mapped; (3) bus/address decode verified; (4) interrupt map verified; (5) macro timing/LEF integrated; (6) no inferred multi-megabit arrays. **Met: 1/6.**
- **Dependencies:** Stage 1 memory decisions, Stage 2.
- **Evidence:** `reports/SKY130_SRAM_MACRO_INTERFACE_AUDIT.md`, `reports/ASIC_MEMORY_WRAPPER_ARCHITECTURE_SPEC.md`.
- **Known issues:** arrays are 256 KB / 64 KB / 32 KB in RTL while the map advertises 128 KB / 16 KB / 32 KB; macro is 4 KB so the SoC needs 32 macros for 128 KB; no wrapper RTL.
- **Blockers:** BLK-002, BLK-005.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 4 — Functional verification — IN PROGRESS

- **Objective:** Verify functional behavior at unit, integration and system level.
- **Entry criteria:** Stage 2/3 integration builds.
- **Requirements:** Mandatory regressions pass; firmware execution; coverage; bug closure.
- **Implementation tasks:** 22-test Icarus suite, 5 protocol/audit benches, C firmware demo, boot assembly demo.
- **Verification tasks:** Re-run 2026-11-15: **22/22 PASS, exit 0** (`iverilog 14.0`).
- **Audit tasks:** None independent; no coverage report; no mutation campaign in current gate.
- **Acceptance criteria (5):** (1) all mandatory tests pass (met); (2) firmware executes on RTL (met); (3) functional coverage targets defined and met; (4) all found bugs closed with tests; (5) independent verification review. **Met: 2/5.**
- **Dependencies:** Stages 2–3.
- **Evidence:** `build/sim/regression.log`, `reports/verification/TEST_RESULTS.md`.
- **Known issues:** legacy `TEST_RESULTS.md` still says 8 PASS / 4 BLOCKED and 13 blocks; superseded by runner but not reconciled; no coverage; no QSPI flash model.
- **Blockers:** BLK-010, BLK-011, BLK-015.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 5 — Formal verification — IN PROGRESS

- **Objective:** Prove required design properties.
- **Entry criteria:** Stable RTL and property specs.
- **Requirements:** Harnesses for control, bus, memory, reset, CDC.
- **Implementation tasks:** 5 SBY tasks: watchdog, reset_ctrl (unbounded PDR), reset sequencing, async wake synchronizer, PLIC registers.
- **Verification tasks:** 5/5 PASS (2026-11-14 log).
- **Audit tasks:** Negative controls exist in runner; no independent property review.
- **Acceptance criteria (5):** (1) required property set defined; (2) all proofs pass (met); (3) bus fabric proven; (4) core control proven; (5) formal coverage reviewed. **Met: 1/5.**
- **Dependencies:** Stage 2, Stage 6 definitions.
- **Evidence:** `build/formal/formal.log`, `scripts/formal/*`.
- **Known issues:** no full-SoC or core formal; interconnect formal harness fails to parse; bounded proofs are scenario-complete only.
- **Blockers:** BLK-013.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 6 — Clock, reset, CDC and RDC closure — BLOCKED

- **Objective:** Validate clock/reset architecture including crossings.
- **Entry criteria:** Stage 1 clock architecture approved; Stage 2 clock RTL implemented.
- **Requirements:** Implemented 50/25/32k architecture or approved single-clock scope; CDC/RDC analysis; synchronizer validation; reset sequencing.
- **Implementation tasks:** RTL has one clock `clk`; `core_clk`/`periph_clk` are gated copies; no divider, no 32 kHz, no PLL. `reset_ctrl` converts watchdog level to bounded pulse.
- **Verification tasks:** CDC inventory 12 rows pass structural checks; reset_ctrl proven unbounded; async wake synchronizer proven bounded.
- **Audit tasks:** CDC plan assumes three domains that do not exist — plan must be rewritten or RTL implemented.
- **Acceptance criteria (5):** (1) approved clock architecture implemented; (2) CDC analysis matches implementation; (3) RDC analysis complete; (4) synchronizers validated; (5) reset sequencing proven. **Met: 1/5** (reset sequencing proven).
- **Dependencies:** Stages 1–2.
- **Evidence:** `docs/verification/formal_cdc_verification_plan.md`, `build/formal/formal.log`.
- **Known issues:** `spi_miso` unsynchronized (argued same-clock); `plic.ext_irq` synchronized but pulse-loss documented; JTAG TMS/TDI single-flop.
- **Blockers:** BLK-001, BLK-008, BLK-013.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 7 — Full-SoC synthesis — BLOCKED

- **Objective:** Produce technology-mapped full-SoC netlist.
- **Entry criteria:** Stage 2 complete; Stage 3 macro mapping decided.
- **Requirements:** Clean elaboration; reproducible script; timing/area/latch/unmapped reports.
- **Implementation tasks:** Yosys 0.69 full-SoC attempt fails at `has_soc.sv:65` (`unexpected TOK_IMPORT`, package import). Block-level synthesis of 13 blocks passed historically.
- **Verification tasks:** No full-SoC netlist exists.
- **Audit tasks:** none.
- **Acceptance criteria (8):** elaboration; mapping; memory mapping; area; timing; latch report; unmapped report; reproducibility. **Met: 0/8.**
- **Dependencies:** Stages 1–3.
- **Evidence:** `reports/evidence/asic_feasibility_and_synthesis_readiness/yosys_has_soc_failure.log`.
- **Known issues:** Yosys version cannot parse the package import/typedef usage; needs `read_verilog -sv` package handling or RTL restructuring; no OpenLane/ORFS full flow run.
- **Blockers:** BLK-004.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 8 — SDC and timing constraint closure — BLOCKED

- **Objective:** Produce approved timing constraints.
- **Entry criteria:** Stage 1 clock architecture; Stage 7 netlist.
- **Requirements:** Clocks, generated clocks, I/O delays, uncertainty, latency, loads, exceptions, coverage.
- **Implementation tasks:** `constraints/timing_constraints/has_soc.sdc` defines a 20 ns clock (50 MHz) with blanket I/O delays; block-level `timer_pclk_provisional.sdc` defines 40 ns (25 MHz).
- **Verification tasks:** Timer STA runs; no full-SoC STA.
- **Audit tasks:** Phase 4.21 audit found 71 inputs / 35 outputs without budgets and 35 unconstrained endpoints.
- **Acceptance criteria (6):** (1) approved clocks (met? no — 50 vs 25 conflict); (2) generated clocks defined; (3) I/O budgets complete; (4) exceptions justified; (5) constraint coverage 100%; (6) owner approval. **Met: 1/6** (a provisional file exists).
- **Dependencies:** Stages 1, 7.
- **Evidence:** `constraints/timing_constraints/has_soc.sdc`, `build/asic_flow/phase3_2_cts/constraints/timer_pclk_provisional.sdc`, `reports/ASIC_PHASE4_21_SDC_CLOSURE_AND_POST_CTS_GATE_PROTOTYPE.md`.
- **Known issues:** two different periods; no generated clock for a peripheral divider; no full-SoC clock groups.
- **Blockers:** BLK-003.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 9 — Full-chip floorplanning — NOT STARTED

- **Objective:** Establish complete chip floorplan.
- **Entry criteria:** Stages 7–8.
- **Requirements:** Die/core size, utilization, macro placement, pins, blockages, PDN interfaces.
- **Implementation tasks:** Only a 95.49 × 95.49 µm timer block experiment exists.
- **Verification tasks:** None at full chip.
- **Audit tasks:** None.
- **Acceptance criteria (6):** die; core; utilization; macro placement; pin placement; blockage validation. **Met: 0/6.**
- **Dependencies:** Stages 3, 7, 8.
- **Evidence:** `build/asic_flow/phase3_2_cts/output/timer_cts.def`.
- **Known issues:** none at full chip because it does not exist.
- **Blockers:** BLK-005, BLK-008.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 10 — Power planning — NOT STARTED

- **Objective:** Implement and validate PDN.
- **Entry criteria:** Stage 9.
- **Requirements:** Power domains, rings, straps, rails, macro connections, tapcells, endcaps, connectivity, IR.
- **Implementation tasks:** Timer-block tapcells and simple PDN only; no UPF/CPF anywhere in repository.
- **Verification tasks:** None.
- **Audit tasks:** None.
- **Acceptance criteria (6):** domains; rings/straps; rails; macro power; tapcells/endcaps; IR analysis. **Met: 0/6.**
- **Dependencies:** Stage 9, Stage 1 power architecture.
- **Evidence:** `reports/evidence/asic_phase3_visual/POWER_DISTRIBUTION.png`.
- **Known issues:** power intent is prose only; PMIC/voltage domains are board-level, not SoC-level.
- **Blockers:** BLK-008.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 11 — Full-chip placement — NOT STARTED

- **Objective:** Complete standard-cell placement.
- **Entry criteria:** Stages 7, 9, 10.
- **Implementation tasks:** Timer block: 421 instances, legal placement.
- **Verification tasks:** `check_placement` clean on timer block.
- **Audit tasks:** none.
- **Acceptance criteria (5):** global; detailed; congestion; density; legality. **Met: 0/5** at full chip.
- **Dependencies:** Stages 9–10.
- **Evidence:** Phase 4.22 isolated flow.
- **Known issues:** full-chip congestion unknown.
- **Blockers:** Stage 7.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 12 — Full-chip CTS — NOT STARTED

- **Objective:** Implement complete clock tree.
- **Entry criteria:** Stage 11.
- **Implementation tasks:** Timer-block CTS with 10 clkbufs, 67 sinks, skew 0.105 ns, latency 0.31 ns.
- **Verification tasks:** Post-CTS placement legalization gate validated 24/24 scenarios (Phase 4.22).
- **Audit tasks:** Independent gate audit found 4 defects, fixed in experiment copy.
- **Acceptance criteria (5):** config; tree; connectivity; skew/latency; post-CTS STA. **Met: 0/5** at full chip (1/5 block-level, not counted).
- **Dependencies:** Stage 11, Stage 8.
- **Evidence:** `experiments/asic_phase4_18_cts_repair` … `asic_phase4_22`.
- **Known issues:** gate is experimental, not in production; no multi-corner CTS.
- **Blockers:** Stage 8, Stage 11.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 13 — Full-chip routing — NOT STARTED

- **Objective:** Complete signal routing.
- **Entry criteria:** Stage 12.
- **Implementation tasks:** Timer block: DRT complete, DRC 0, 1 antenna violation residual.
- **Verification tasks:** DRC 0; antenna 1 net / 1 pin; no LVS.
- **Audit tasks:** none.
- **Acceptance criteria (5):** global; detailed; connectivity; DRC; antenna. **Met: 0/5** at full chip.
- **Dependencies:** Stage 12.
- **Evidence:** `experiments/asic_phase4_22/physical_validation/`.
- **Known issues:** post-route `repair_antennas` SIGSEGVs in this build.
- **Blockers:** BLK-009.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 14 — Physical verification — NOT STARTED

- **Objective:** DRC, LVS, antenna, density, ERC.
- **Entry criteria:** Stage 13.
- **Implementation tasks:** Timer block DRC 0; no LVS run anywhere.
- **Verification tasks:** DRC report exists for timer.
- **Audit tasks:** none.
- **Acceptance criteria (6):** DRC; LVS; antenna; density; ERC; macro checks. **Met: 0/6** at full chip.
- **Dependencies:** Stage 13, PDK/rule decks.
- **Evidence:** `experiments/asic_phase4_22/physical_validation/isolated_drc.rpt`.
- **Known issues:** Magic/Netgen installed but no LVS flow configured; no density check.
- **Blockers:** BLK-009, BLK-012.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 15 — Timing and electrical signoff — NOT STARTED

- **Objective:** Extracted multi-corner timing and electrical signoff.
- **Entry criteria:** Stages 8, 13, 14.
- **Implementation tasks:** Timer block single-corner extracted STA: setup 38.01 ns, hold 0.43 ns, TNS 0 (experimental).
- **Verification tasks:** none accepted.
- **Audit tasks:** none.
- **Acceptance criteria (7):** extraction; setup; hold; multi-corner; multi-mode; SI; IR/EM. **Met: 0/7.**
- **Dependencies:** Stage 8, 13.
- **Evidence:** `experiments/asic_phase4_22/results/timing_comparison.json`.
- **Known issues:** one corner (`tt_025C_1v80`); provisional SDC; 35 unconstrained endpoints.
- **Blockers:** BLK-003, BLK-014.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 16 — DFT and manufacturing readiness — NOT STARTED

- **Objective:** Scan, ATPG, test coverage, BIST, JTAG boundary scan.
- **Entry criteria:** Stage 7 netlist, Stage 2 RTL.
- **Implementation tasks:** None. `debug_jtag` is a TAP subset without DMI/IDCODE.
- **Verification tasks:** None.
- **Acceptance criteria (5):** scan architecture; insertion; ATPG; coverage target; test-mode verification. **Met: 0/5.**
- **Dependencies:** Stages 2, 7.
- **Evidence:** none.
- **Known issues:** no scan flops, no test protocol, no ATPG tool in environment.
- **Blockers:** BLK-007.
- **Completion approval:** pending.
- **Completion date:** —

### Stage 17 — GDSII generation and final audit — NOT STARTED

- **Objective:** Final GDSII/netlist/DEF/SDC/SPEF and release audit.
- **Entry criteria:** Stages 14–16.
- **Acceptance criteria (6):** GDSII; netlist; DEF; SDC; SPEF; release audit. **Met: 0/6.**
- **Dependencies:** all prior.
- **Evidence:** none.
- **Blockers:** Stages 13–16.

### Stage 18 — Tapeout package — NOT STARTED

- **Objective:** Foundry submission package.
- **Entry criteria:** Stage 17.
- **Acceptance criteria (7):** approved GDSII; foundry files; signoff reports; waivers; checksums; version ID; formal approval. **Met: 0/7.**
- **Dependencies:** Stage 17.
- **Evidence:** none.
- **Blockers:** Stage 17.

---

## 4.4 Stage-completion gate (summary)

A stage may be marked COMPLETE only when: all acceptance criteria have evidence; mandatory checks have run in the current revision; no P0/P1 blocker remains; an independent audit has passed; evidence is hashed in the registry. See `reports/TAPEOUT_STAGE_COMPLETION_GOVERNANCE.md`.

## 4.5 Tracker change log

| Date | Change |
|---|---|
| 2026-11-15 | Initial tracker created from Stage 0 audit; Stage 0 marked COMPLETE; all other stages recorded from measured evidence. |
| 2026-11-15 | Stage 1 investigation completed; status set READY FOR APPROVAL (2/10 criteria). All architecture decisions remain unapproved; Stage 2 not started. |
