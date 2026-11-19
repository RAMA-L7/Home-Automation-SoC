# Acceptance gates (frozen 2026-11-18)

Status vocabulary: `PASS` (checked in this study with linked evidence),
`PARTIAL`, `OPEN` (not attempted or blocked), `FAIL`. A gate is `PASS` only
when **every** applicable criterion below it is `PASS`.

Independent evaluation: **NOT AVAILABLE** in this environment. Everything here
is therefore SELF-EVALUATED, and G4 cannot be satisfied regardless of local
results.

## G0 — Reproducible baseline

| # | Criterion | Status | Evidence |
|---|---|---|---|
| G0.1 | Exact source state identified, worktree dirty-state recorded | PASS | `runs/RUN-0001-baseline-025ef24/source-manifest.json`; HEAD `025ef24` |
| G0.2 | Tools inventoried with versions and availability | PASS | `runs/RUN-0001-baseline-025ef24/logs/tools.txt` |
| G0.3 | Requirements and implementation boundary frozen | PASS | `research/requirements-baseline.md` |
| G0.4 | Existing verification results reproduced at this commit, or marked unverified | PASS | RUN-0011 re-ran every named target at `025ef24` + the recorded dirty tree: regression 27/27, gate 10/10, firmware build + E2E 7/7, formal 6/6, Verilator lint 0 errors, Verilator C++ rebuild + boot 7/7, structural/memory BLOCKED as declared. PPA and wrapper-based claims are marked unverified. `runs/RUN-0011-evidence-provenance/evidence-matrix.md` |
| G0.5 | No missing build inputs or unexplained stale-artifact dependency | PASS | F4 fixed: arithmetic source and testbench published at `asic/synthesis/provenance/` with hashes equal to the originals; stale artifacts identified and either regenerated (build/verify, build/obj_soc_r11) or banner-marked historical (reports/verification, build/baseline). No unexplained dependency remains |

**G0 overall: PASS** (G0.1–G0.5 all pass). Independent reproduction is a G4 requirement, not G0.

## G1 — Qualified RTL and firmware

| # | Criterion | Status | Evidence |
|---|---|---|---|
| G1.1 | Required behaviour traced to executable checks | PARTIAL | per-peripheral testbenches + `scripts/verify.js`; traceability table not complete |
| G1.2 | CPU, memory, bus, interrupt, reset, peripheral tests pass | PASS | regression 27/27, `runs/RUN-0001-baseline-025ef24/logs/regression.log` |
| G1.3 | Formal properties have reviewed assumptions and reachability | PARTIAL | 6/6 properties run; assumptions not externally reviewed |
| G1.4 | Sensor input → firmware decision → GPIO output → UART report through the real SoC | PARTIAL | C demo exercises UART, GPIO, watchdog reset; no sensor model exists |
| G1.5 | Watchdog reset/recovery during defined active-transaction cases | PARTIAL | idle-path reset demonstrated; reset during an active APB/AXI transaction not yet tested |
| G1.6 | Fresh firmware built from source with recorded provenance | PASS | `build_fw.js`/`gen_fw_mem.js` with discovery; image SHA-256 recorded in run artifacts |
| G1.7 | I²C bus protocol valid on the wire (START/STOP/data/ACK) | PASS | STOP phasing fixed (`i2c_ctrl.sv` I_STOP_B holds SDA low while SCL is high); negative control RUN-0002 fails, fix RUN-0003 passes, integration RUN-0004 27/27 + 9/9 |

**G1 overall: PARTIAL** — the protocol defect found on day 1 is fixed and regression-covered; G1.1, G1.3, G1.4 and G1.5 remain partial (no sensor path, no externally reviewed formal assumptions, watchdog reset during an active transaction not tested).

## G2 — ASIC implementation baseline

| # | Criterion | Status | Evidence |
|---|---|---|---|
| G2.1 | Real library cells and actual memory implementations identified | PARTIAL | cells mapped from `sky130_fd_sc_hd`; all four inferred memories are now identified, sized and reconciled (RUN-0009), but no memory implementation exists (F7) |
| G2.2 | No unexpected unresolved cells, multiple drivers, undriven signals | PARTIAL | Enforced and negative-controlled: `check -assert` + library-cell allowlist + gap accounting (RUN-0007, 7/7 controls, gate 10/10). Clean design PASSes; `has_soc` is **BLOCKED** on 4 declared `$mem_v2`, now fully inventoried with geometry and drift controls (`scripts/eda/audit_memory.js`, RUN-0009, F7), so the criterion cannot pass yet |
| G2.3 | Mapping/equivalence checks cover the transformations actually used | PARTIAL | `$pmux` rule now covered by exhaustive simulation + cell-level equivalence, negative-controlled (RUN-0005/RUN-0006). All 11 sequential cell models the stub defines now match their liberty `clocked_on`, and `dfrbp` is proven by directed vectors with a pre-fix negative control (RUN-0008, F3 closed). Still only one mapping rule (`$pmux`) is equivalence-checked; the other `sky130_map.v` rules are unproven |
| G2.4 | Clock, I/O, reset and timing exceptions explicit and justified | OPEN | no SDC audited; no pad ring |
| G2.5 | Memory, pad, clock, power interfaces consistent | OPEN | no pads; memory strategy unresolved (the requirement set is in RUN-0009: 2R1W byte-enable SRAM, dual-read ROM, F5 capacity decision outstanding) |
| G2.6 | Test access and manufacturing-test strategy documented | OPEN | DFT not started |

**G2 overall: PARTIAL.**

## G3 — Physical closure

| # | Criterion | Status | Evidence |
|---|---|---|---|
| G3.1 | Selected design placed and routed | OPEN | no PDK and no memory macro; a macro-backed netlist cannot be built, let alone placed |
| G3.2 | Connectivity/placement checks pass | OPEN | no implementation exists |
| G3.3 | Extracted setup/hold meets frozen constraints at required corners | OPEN | — |
| G3.4 | DRC, LVS, antenna, electrical, power integrity pass | OPEN | — |
| G3.5 | Waivers externally authorized, not self-approved | OPEN | no waivers |

**G3 overall: OPEN.**

## G4 — Audited handoff package

| # | Criterion | Status | Evidence |
|---|---|---|---|
| G4.1 | Source, netlist, layout, constraints, reports, manifests correspond | OPEN | no layout |
| G4.2 | Abstracts, timing models, power, test collateral present | OPEN | — |
| G4.3 | IP/PDK provenance recorded | PARTIAL | PDK provenance documented; no package |
| G4.4 | Independent reviewer evaluates the frozen package | OPEN | **no independent evaluator available** |
| G4.5 | All required gates pass without blocking findings | OPEN | — |

**G4 overall: OPEN.**

## Classification rule

Only `TAPEOUT-READINESS CHECKLIST SATISFIED` when every applicable criterion
and the independent review pass, naming platform and boundary exactly.
Otherwise: `PARTIAL — HIGHEST VERIFIED GATE Gx` with each blocker named.
`FOUNDRY-APPROVED` only with documented external approval, which does not exist.
