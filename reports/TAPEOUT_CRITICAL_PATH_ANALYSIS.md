# Home-Automation-SoC — Critical Path Analysis

Date: 2026-11-15
Basis: measured Stage 0 evidence (`reports/TAPEOUT_STAGE0_BASELINE_AUDIT.md`, `TAPEOUT_MASTER_TRACKER.md`).

---

## 1. Answer

**The critical path starts at Stage 1 — Architecture and requirements closure.**

The earliest incomplete stage that blocks downstream work is Stage 1, not Stage 7, not Stage 12, and not Phase 4.22. Full-SoC synthesis (Stage 7) is the first *hard tool failure*, but fixing it before the clock and memory decisions would produce a netlist with the wrong peripheral frequency, the wrong ROM/SRAM sizes and no power intent. That netlist would then force rework of SDC, floorplan, PDN, CTS and STA.

**Recommended next engineering objective:** close Stage 1 with owner-approved decisions for clocking, memory map, power intent, security scope and DFT scope.

---

## 2. Critical path chain

```
Stage 1  Architecture closure
   ↓
Stage 2  RTL closure (divider, memory params, stubs)
   ↓
Stage 3  IP/memory integration (macro wrapper)
   ↓
Stage 7  Full-SoC synthesis
   ↓
Stage 8  Approved SDC
   ↓
Stage 9  Floorplan (macros, pins)
   ↓
Stage 10 PDN
   ↓
Stage 11 Placement
   ↓
Stage 12 CTS (+ post-CTS legalization)
   ↓
Stage 13 Routing
   ↓
Stage 14 DRC/LVS/antenna
   ↓
Stage 15 Multi-corner STA / electrical signoff
   ↓
Stage 17 GDSII + final audit
   ↓
Stage 18 Tapeout package
```

Feeder paths:
- Stage 4 (functional verification) and Stage 6 (CDC/RDC) must finish before RTL freeze; Stage 5 consumes Stage 6 property definitions.
- Stage 16 (DFT) needs the Stage 7 netlist and must be decided in Stage 1 because scan insertion changes the netlist and timing.

---

## 3. Why Stage 1 is the constraint

| Question | If unresolved | Downstream rework |
|---|---|---|
| 50/25/32 kHz or single clock? | CTS builds a tree for the wrong clock; SDC has no generated clock; CDC plan is fiction | SDC, CTS, STA, power, DFT clock rules |
| ROM 16 KB or 64 KB? SRAM 128 KB or 256 KB? | Synthesis area, floorplan, macro count, PDN and firmware linker are wrong | Synthesis, floorplan, PDN, firmware |
| UPF or single domain? | PDN and signoff checks undefined; isolation/level shifters missing | PDN, STA, LVS/ERC |
| Secure boot/OTA in scope? | ROM size and boot time change; security signoff undefined | RTL, ROM, verification |
| Scan/ATPG required? | Netlist must be rebuilt with scan; timing changes | Synthesis, STA, DFT |

Each of these is a **P0/P1 blocker** in `TAPEOUT_BLOCKER_REGISTER.md` (BLK-001, BLK-002, BLK-003, BLK-006, BLK-007, BLK-008).

---

## 4. Why not the obvious alternatives

| Candidate | Why it is not the next stage |
|---|---|
| **Stage 7 full-SoC synthesis** | Tool failure is real (Yosys `TOK_IMPORT`), but synthesizing now locks in the wrong memory sizes and clock architecture. A parser workaround is a legitimate parallel spike, not stage completion. |
| **Stage 12 / Phase 4.22** | The post-CTS gate is already validated 24/24 on a timer block. Extending it cannot fix the architecture, and no full-chip database exists to apply it to. |
| **Stage 4 more simulation** | 22/22 passes; additional tests add confidence but do not resolve the architecture contradictions and cannot unblock synthesis or constraints. |
| **Stage 5 formal** | Block proofs pass; full-SoC formal needs a synthesizable/elaboratable full design and defined clock domains. |
| **Stage 8 SDC** | Cannot be approved without Stage 1 clock decisions; writing more constraints now would encode a guess. |
| **PCB / FPGA work** | Out of ASIC tapeout scope; does not gate the package. |

---

## 5. Parallel work that is legitimate now

These do not change the frozen baseline and shorten later stages:

1. **Stage 7 parser spike:** determine whether Yosys can elaborate the package import with `read_verilog -sv` plus explicit package files, or whether `has_soc` needs a package-free wrapper. Time-boxed; result informs Stage 2.
2. **Stage 3 macro wrapper design study:** define the 32-macro / 128 KB organization and mask adapter on paper; no RTL until TD-006 is approved.
3. **Stage 8 constraint inventory:** complete the I/O budget table (105 ports) as a proposal, ready for approval after Stage 1.
4. **Stage 16 DFT scoping:** identify scan tool availability and scan flop readiness so the Stage 1 decision is informed.
5. **Evidence hygiene:** reconcile `build/verify/summary.txt`, `TEST_RESULTS.md` and the runner's test count so the verification gate is trustworthy (BLK-010).

---

## 6. Schedule risks (qualitative)

| Risk | Effect | Mitigation |
|---|---|---|
| Architecture decisions stall for lack of an owner | Entire program stalls at Stage 1 | Name a single design owner with authority to approve/reject; time-box each decision |
| DFT discovered late | Netlist and timing rebuilt; 2–4 weeks of rework | Decide scan scope in Stage 1; plan scan insertion before synthesis freeze |
| Memory macro organization wrong | Floorplan/PDN redo | Approve TD-006 before Stage 9; prototype wrapper in Stage 3 |
| Yosys cannot parse full SoC | No netlist; commercial synthesis unavailable | Parser spike now; if unresolved, restructure package usage in Stage 2 |
| SDC ownership gap | Timing numbers remain conditional | Assign design owner for TD-010–TD-012 |
| Antenna repair tool crash | Routing cannot close | Choose jumper/diode strategy in TD-014; validate on block before full chip |
| Single-corner only | Signoff invalid | Add corners at Stage 15; ensure Liberty views exist (macro is TT-only) |

---

## 7. Exit condition for the immediate next stage

Stage 1 is complete when:

1. `TAPEOUT_DECISION_REGISTER.md` has **no OPEN or BLOCKED entry that blocks Stage 2**.
2. The memory table in the architecture docs equals the RTL parameters and decode.
3. Clock/reset/power architecture has one approved diagram and one SDC clock plan.
4. Requirements traceability maps every mandatory FR/NFR to a module or an explicit waiver.
5. An independent reviewer signs the closure record.

Until then, no RTL, synthesis, constraint or physical-design stage may be marked complete.
