# Home-Automation-SoC — Master Tapeout Roadmap

Date: 2026-11-15
Baseline: `3fb1f0492b0dd460bd70d1a06a36b536b3d4280e`
Authority: this roadmap and `TAPEOUT_MASTER_TRACKER.md` supersede stage tables in `AGENTS.md` and `reports/MASTER_PROJECT_STATUS.md` for tapeout planning.

---

## 1. Program definition

**Goal:** a fully verified, physically implemented, signoff-ready GDSII and foundry package for the Home-Automation-SoC.

**Process:** strict stage gates. A stage starts only when its entry criteria are evidenced; it completes only through the governance process in `reports/TAPEOUT_STAGE_COMPLETION_GOVERNANCE.md`.

**Design baseline rule:** once a stage freezes an artifact (netlist, SDC, DEF, GDS), downstream stages reference that frozen hash. Any change re-opens the affected stage.

---

## 2. Stage map

| Stage | Name | Primary deliverables | Entry gate | Exit gate |
|---|---|---|---|---|
| 0 | Baseline and environment audit | Inventory, registers, tracker, roadmap | repository access | all evidence classified; preservation verified |
| 1 | Architecture and requirements closure | Approved architecture, traceability matrix, memory map, clock/reset/power/security specs | Stage 0 | zero unresolved blocking decisions |
| 2 | RTL implementation closure | Complete synthesizable RTL, no stubs, consistent clocks/resets | Stage 1 decisions for affected blocks | independent RTL review; lint + sim green |
| 3 | IP and memory integration | CPU, bus, memories mapped to macros, interrupts, interface validation | Stage 1 memory decision, Stage 2 | macro-level sim + structural checks |
| 4 | Functional verification | Unit/integration/system regressions, firmware execution, coverage | Stage 3 | mandatory tests pass; coverage target met |
| 5 | Formal verification | Harnesses and proofs for control, bus, memory, reset | Stage 2, Stage 6 property definitions | required properties proven or exceptions approved |
| 6 | Clock/reset/CDC/RDC closure | Implemented clock architecture, CDC/RDC analysis, synchronizer proofs | Stage 1 clock decision, Stage 2 clock RTL | no unresolved critical clock/reset issue |
| 7 | Full-SoC synthesis | Mapped netlist, area/timing/latch/unmapped reports, reproducible script | Stages 2, 3 | all synthesis checks pass |
| 8 | SDC and timing closure | Approved clocks, I/O budgets, exceptions, coverage report | Stages 1, 7 | owner-approved SDC; zero unexplained unconstrained endpoints |
| 9 | Full-chip floorplanning | Die/core, utilization, macro and pin placement, blockages | Stages 3, 7, 8 | floorplan review vs requirements |
| 10 | Power planning | Domains, rings, straps, rails, macro power, tapcells, endcaps, IR estimate | Stage 9, Stage 1 power decision | structural + electrical PDN checks |
| 11 | Full-chip placement | Global/detailed placement, congestion, density, legality, timing-driven opt | Stages 9, 10 | legal placement; acceptable congestion |
| 12 | Full-chip CTS | Clock tree, buffers/inverters, skew/latency, post-CTS legalization, post-CTS STA | Stage 11, Stage 8 | clock tree validated in required scenarios |
| 13 | Full-chip routing | Global/detailed route, connectivity, DRC, antenna, congestion, via/wire reports | Stage 12 | routing complete; physical violations closed |
| 14 | Physical verification | DRC, LVS, antenna, density, ERC, macro checks | Stage 13 | required checks pass |
| 15 | Timing and electrical signoff | Extracted multi-corner/mode STA, SI, IR, EM, power, ERC | Stages 8, 13, 14 | approved signoff criteria pass |
| 16 | DFT and manufacturing readiness | Scan architecture/insertion, ATPG, coverage, BIST/JTAG if required, test-mode verification | Stages 2, 7 | manufacturing test requirements satisfied |
| 17 | GDSII generation and final audit | GDSII, netlist, DEF, SDC, SPEF, reports, manifests, reproducibility | Stages 14–16 | release checks pass |
| 18 | Tapeout package | Approved GDSII, foundry files, signoff reports, waivers, checksums, version ID, release approval | Stage 17 | package formally approved |

---

## 3. Phase grouping and decision gates

### Phase A — Architecture and RTL (Stages 1–3)

**Gate A:** approved architecture; RTL implements it; memories macro-mapped. This is the highest-leverage phase: every later artifact inherits its clock period, memory sizes and port list.

### Phase B — Verification (Stages 4–6)

**Gate B:** functional and formal evidence sufficient to freeze RTL; CDC/RDC closed or explicitly descoped. RTL freeze hash recorded.

### Phase C — Synthesis and constraints (Stages 7–8)

**Gate C:** frozen netlist + approved SDC. No physical work starts before both exist, because floorplan and CTS depend on both.

### Phase D — Physical implementation (Stages 9–13)

**Gate D:** legal, routed, antenna-clean database with post-route timing reports.

### Phase E — Signoff and manufacturing (Stages 14–18)

**Gate E:** DRC/LVS/antenna/ERC clean, multi-corner timing and electrical signoff, DFT coverage, GDSII and package approved.

---

## 4. Dependency graph

```
0 → 1 → 2 → 3 → 4 → 6 → 5
        │       │
        └───────┴→ 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15
                                      │                     │
                                      └→ 16 ────────────────┴→ 17 → 18
```

Notes:
- Stage 6 depends on Stage 2 but also feeds Stage 5 (property definitions).
- Stage 16 needs the Stage 7 netlist and can start in parallel with physical implementation once scan insertion is planned.
- Stage 15 depends on Stage 8 (constraints) and Stage 13/14 (database).

---

## 5. Existing work mapped to stages

| Existing artifact | Stage | Use | Must not be used as |
|---|---|---|---|
| 23 RTL modules + 22/22 sim | 2, 4 | starting point for closure | tapeout-verified RTL |
| 5 formal proofs | 5 | block-level evidence | full-SoC proof |
| Timer block CTS/route/extract (4.18–4.22) | 12, 13, 15 | method and tool-flow validation | full-chip or signoff evidence |
| Post-CTS gate 24/24 | 12 | candidate production gate | approved production flow |
| Provisional SDC + M1–M10 | 8 | draft constraint set | approved constraints |
| SRAM macro audit | 3 | macro selection input | integrated memory |
| Firmware demo | 4 | boot-path evidence | production firmware/security |

---

## 6. Milestones and exit evidence

| Milestone | Evidence required |
|---|---|
| M-A Architecture frozen | approved decision register entries; traceability matrix; memory table matching RTL |
| M-B RTL frozen | RTL hash; 100% mandatory tests; lint; formal set; CDC report |
| M-C Netlist + SDC frozen | synthesis reports; SDC coverage report; owner approval |
| M-D Database routed | DRC 0; antenna 0; connectivity; post-route STA |
| M-E Signoff clean | LVS 0; multi-corner STA; IR/EM; DFT coverage; GDSII checksums |
| M-F Package approved | signed release checklist; waiver list; foundry file manifest |

---

## 7. Scope control

In scope for tapeout: digital SoC RTL, memories, clock/reset, constraints, synthesis, physical implementation, signoff, DFT, GDSII, package.

Explicitly out of scope unless re-approved: PCB, FPGA, mechanical, cloud/Home Assistant integration, RF. These exist in the repository but do not gate the ASIC package.

---

## 8. Change control

- Any change to frozen RTL, SDC, DEF or GDS re-opens its stage and every dependent stage.
- Waivers must name the check, the violation, the justification, the owner and the expiry stage.
- Experiments may run in parallel but cannot alter the frozen baseline; their artifacts live under `experiments/` and are classified EXPERIMENTAL.
