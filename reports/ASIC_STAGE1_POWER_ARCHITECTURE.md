# ASIC Stage 1 — Power Architecture

Date: 2026-11-15
Status: **READY FOR APPROVAL** (TD-005)
Related: clock report (AON), memory report (retention), security report (key storage)

---

## 1. Verified current state

| Item | Reality | Evidence |
|---|---|---|
| Power domains in RTL | **one**; no UPF/CPF anywhere | repository-wide search |
| Power management | software `PM_CTRL.sleep_req` gates `core_clk` and `periph_clk` | `power_mgr.sv` |
| Wake sources | external `wake_ack` handshake only | `power_mgr.sv:4-10` |
| State retention | none; registers are clock-gated, not power-gated | `power_mgr.sv` |
| Isolation / level shifters | none | no UPF, no isolation cells |
| Reset during power transition | no sequencing; `reset_n` only | `reset_ctrl.sv` |
| PDN | timer-block experiment only (tapcells + simple rails) | `reports/evidence/asic_phase3_visual/` |
| Process supply | sky130hd is **1.8 V nominal** | PDK flow |
| 3.3 V tolerant pads | **not available** in sky130hd | PDK / pad inventory |
| PMIC | TPS65217 is board-level prose; no SoC interface | `CLOCK_RESET_AND_POWER_ARCHITECTURE.md` |

The documented four domains (AON 3.3 V, core 1.0 V, IO 1.8 V, periph 3.3 V) are a **board power tree**, not an SoC power intent. The SoC itself has one supply and one reset.

---

## 2. Requirements

| Requirement | Target | Feasibility in this project |
|---|---|---|
| FR-PWR-001 | Core 1.0 V / IO 1.8 V / periph 3.3 V / AON 3.3 V | Only 1.8 V digital core available; 1.0 V/3.3 V are board rails or require level shifters/pads not in the PDK |
| FR-PWR-002 | TPS65217 PMIC, I²C sequencing | Board-level; SoC needs I²C master (exists) and alert input (absent) |
| FR-PWR-003 | Deep sleep <1 mW, AON active | Requires AON domain + power gating; not achievable with clock gating only |
| FR-PWR-004 | Wake from LPTIM/GPIO/PMIC | Only `wake_ack` exists; LPTIM/PMIC/GPIO wake absent |
| FR-PWR-005 | Wake <10 ms | Unverified; no PLL, so no re-lock; boot from retention unknown |
| FR-PWR-006 | Brown-out/power-loss detect | No comparator/PMIC alert input |
| NFR-PWR-001..007 | Active <500 mW; AON <1 mA; sleep <1 mW | No measurement, no power intent |

**Separation:** FR-PWR-001/002/006 are board/system requirements. FR-PWR-003/004/005 are SoC requirements and drive the AON domain.

---

## 3. Architecture options

| Option | Domains | Description | Meets deep sleep | Complexity | Verdict |
|---|---|---|---|---|---|
| P-A | 1 | Single 1.8 V, clock gating only; board PMIC cuts rail | No (no AON timer/wake) | Lowest | Current state; not compliant |
| P-B | 2 | AON 1.8 V always-on + switchable core/periph 1.8 V; external PMIC switches core rail | Yes, with AON LPTIM/wake | Moderate | **Recommended** |
| P-C | 3 | AON + core + periph separately switchable | Yes | High; more isolation/sequencing | Overkill for first silicon |
| P-D | 4 | Documented 1.0/1.8/3.3 domains on-chip | Yes | Very high; needs level shifters and pads not in PDK | Not feasible now |

### Recommended: P-B (two SoC domains at 1.8 V)

```
Board: 12 V / 5 V
  └─ PMIC TPS65217
       ├─ 1.8 V always-on rail ──────────────┐
       │                                      ├─ AON domain (LPTIM, wake, PMU, reset)
       └─ 1.8 V switchable rail ── power switch ── core + periph domain
```

- Both SoC domains are 1.8 V, so **no level shifters** are needed between them.
- Isolation cells are required on all core→AON and AON→core signals that cross the switchable boundary.
- No retention flops in first silicon; firmware saves context to AON-retained registers or external flash before DEEP.
- The PMIC controls the switchable rail; the SoC provides `pwr_hold`/`iso_en` handshakes so isolation is asserted before the rail drops.
- 1.0 V and 3.3 V remain **board rails** for other devices; the SoC does not consume them. If 3.3 V I/O is mandatory, external level shifters or a different pad library are required (new blocker).

### Why not P-C/P-D now

- P-C adds a third switchable domain with little benefit for a first tapeout.
- P-D cannot be implemented with the open PDK's 1.8 V cells and pads; claiming it would repeat the documentation-reality gap this stage exists to close.

---

## 4. Power intent (UPF scope)

If P-B is approved, the UPF must define:

| Element | Content |
|---|---|
| Domains | `PD_AON` (always_on), `PD_CORE` (switchable, includes periph) |
| Supply ports | `VDD_AON`, `VDD_CORE`, `VSS` |
| Power switch | External PMIC control; SoC `pwr_hold` output and `pwr_ack` input |
| Isolation | `iso_en` from AON; clamp core→AON outputs to 0; AON→core inputs unprotected but core is off |
| Level shifters | None (same 1.8 V) |
| Retention | None in first silicon; strategy documented |
| Always-on cells | AON LPTIM, wake controller, PMU sticky registers, reset stretcher |
| Power states | ACTIVE, SLEEP (clock gated), DEEP (core rail off) |

UPF is **not created in Stage 1**. It is a Stage 10 deliverable after TD-005 approval. Without UPF, multi-domain implementation cannot be signed off.

---

## 5. Sequencing and reset

| Event | Sequence |
|---|---|
| Power-up | AON rail stable → AON reset release → PMIC I²C config → core rail on → core reset release |
| Sleep entry | software request → gate clocks → save context → assert `iso_en` → PMIC off core rail |
| Wake | AON timer/GPIO → `pwr_hold` → PMIC core rail on → wait `pwr_ack` → release `iso_en` → core reset release → restore context |
| Brown-out | PMIC alert → AON records event → core reset asserted → recovery boot |

The SoC has no brown-out comparator. Either add a PMIC alert input (pin budget) or descope FR-PWR-006.

---

## 6. Impact and approval

| Area | Impact |
|---|---|
| RTL | AON domain, LPTIM, wake controller, isolation handshakes, PMU registers |
| Pins | `pwr_hold`, `pwr_ack`, PMIC_ALERT/IRQ, 32 kHz clock input |
| UPF | Two domains, isolation, no LS, no retention |
| PDN | Two power meshes; AON small; core switchable |
| STA | AON timing separate; isolation paths constrained |
| Verification | Power-state sequences, isolation, wake latency |
| Board | PMIC rail control; 32 kHz source |

### Decision package (TD-005)

| Item | Content |
|---|---|
| Current | One 1.8 V domain, clock gating only |
| Recommended | P-B: AON + switchable core/periph, both 1.8 V; board PMIC rails; UPF in Stage 10 |
| Alternative | P-A with formal descope of FR-PWR-003/004/005 (single domain, clock gating, external wake only) |
| Rejected | P-D on-chip 1.0/3.3 V domains (no PDK support) |
| Risks | Isolation/sequencing bugs can corrupt state; AON adds area; PMIC behavior is board-dependent |
| Downstream | Stage 10 PDN, Stage 15 electrical signoff, Stage 17 GDS |
| Approval | User/design owner |
| Acceptance | Approved domain diagram, UPF scope, pin list, and explicit board PMIC contract |

**Verified:** current single domain, clock-gating behavior, absent UPF, PDK voltage.
**Recommended:** P-B two-domain 1.8 V architecture.
**Not approved:** TD-005 remains READY FOR APPROVAL.
