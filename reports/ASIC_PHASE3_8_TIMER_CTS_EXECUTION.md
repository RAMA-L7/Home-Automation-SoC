# ASIC Phase 3.8 — Timer Block CTS Execution Report

**Approval date:** 2026-11-14  
**Scope:** Isolated timer block CTS experiment (Context A only)  
**Authorized:** D2 = 40.000 ns (timer block period), D6 setup uncertainty = 0.100 ns provisional, hold uncertainty = 0.050 ns provisional  
**Authorization:** User explicitly approved creation of the 14-field approval record and execution of the approved timer CTS experiment. No routing, no full-SoC CTS, and no production RTL, SDC or PDK modifications.

---

## 1. APPROVAL GATE

| Field | Value |
|---|---|
| `approved_period_ns` | 40.000 |
| `approved_by` | project owner (explicit approval in agent session) |
| `approved_date` | 2026-11-14 |
| `scope` | isolated timer block CTS experiment (Context A) |
| `sdc_sha256` | d9d7768567001b38d346ef2a0657c4ab55d22e9b5a2c9ae91b0fe84a31d74c69 |
| `cts_config_sha256` | 76bb517004bb2b59b983c36f2f814755fdaa78b5eec6038d483c7d79532f548c |
| `odb_sha256` | 499720e79176f70693c5b03a311f0f81f8b692510cde930be610277193a2488e |
| `def_sha256` | 38c2191b3be370afb9c7b3803f856e3a7cc54c44a623b9a66a433a864da2b018 |
| `driver_sha256` | b433567733d2dac68ef8deb15ac37ba04341e43a337cd58c141f7974515feeec |
| `liberty_sha256` | 2347eaf80ba9c31bf169bc2b73840c67e4182789e2c872ea61258137e5f4dc2c |
| `lef_sha256` | b844f77ca764b45c97e67f07439a40bdbb59253f43e1244767b2215de4ae55e0 |
| `rc_sha256` | b8231da947daba8b162d1d47b186474c34213e7a367a0df5f166d1ce91d2ab0d |
| `platform_cfg_sha256` | d8ebcb45d52ec4a2ce57d74837a1bb56e67350c99cbe7f91525b077ef7250171 |
| `approval_token` | TYIEZtYjYRdmESNoccAFupewtqASipgR |

**Gate status:** `GATE_STATUS : APPROVED` — all 7 manifest+file hash checks matched, token validated.

---

## 2. CTS EXECUTION

CTS was executed exactly once (single pass, no retry, no constraint change) using `driver.manifest` as the sole binding reference. TritonCTS processed 1 clock net.

**Command/config:** TritonCTS with H-Tree topology, provisional SDC (`timer_pclk_provisional.sdc`), provisional period 40.000 ns, setup uncertainty 0.100 ns, hold uncertainty 0.050 ns.

**Sink count:** 67 flip-flop CLK pins, all placed on a single clock net.

**Buffer counts:** 9 `clkbuf_8` + 1 `clkbuf_4` = 10 buffers (total 14 instances counted across all buffer sizes including characterization usage).

**Clock nets created:** 9.

**Topology:** H-Tree depth 3. `Max level of the clock tree: 3`.

**Fanout distribution:** 6:2, 7:1, 8:2, 10:1, 11:2 (sorted).

**Insertion delay:** ≈ 0.309–0.311 ns (source latency 0.31 ns, target −0.31 ns).

**Skew:** source latency 0.31 ns, target −0.31 ns, uncertainty 0.10 ns, CRPR 0.00 → **setup skew 0.11 ns**.

**Dummy loads inserted:** 6.

**Runtime:** 0.90 s.

**Warnings/errors:** 0 (CTS completed cleanly).

---

## 3. CLOCK TREE TOPOLOGY

**Clock sink count:** 73 (pin-endpoints, including buffer inputs).

**Leaf buffers:** 0.

**Average sink wire length:** 129.42 um.

**Path depth:** 2 – 2.

**Clock nets in the tree:** 10 (including non-pclk nets traced in the ODB).

**Clock buffers seen:** 14 total (9 × clkbuf_8, 1 × clkbuf_4).

**Topology detail (buffer levels / fanout):**

| Buffer | Count |
|---|---|
| `clkbuf_4` | 1 |
| `clkbuf_8` | 9 |

**Routed segments:** 0 (no routing performed in this phase).

**Connectivity state:**

| Metric | Value |
|---|---|
| Nets with any routing wire | 0 |
| Total routed segments | 0 |
| Nets with 1 pin (dangling) | 28 |
| Nets with 0 pins | 0 |

---

## 4. PLACEMENT LEGALITY

The post-CTS placement check (`check_placement`) reports a **site-alignment failure** on 15 CTS-inserted cells. These cells were placed by the hand-rolled Phase 3 floorplan and do not align to standard cellsites.

**Result:** `RESULT check_placement : FAILED (DPL-0033)`

**Failed sites (15):** `clkbuf_0_pclk`, `clkbuf_3_0__f_pclk`, `clkbuf_3_1__f_pclk`, … `clkbuf_3_7__f_pclk`, `clkload0`…`clkload5`.

**Placement counts:** PLACED = 316, UNPLACED = 0, other = 105 (FIXED/LOCKED tapcells).

**No legalizer or ECO was run.** The 15 site-alignment failures are reported as a measured legality failure with no remediation.

---

## 5. TIMING ANALYSIS (block-level, no I/O budgets, pre-route)

**Clock period:** 40.000000 ns.

**Setup skew:** 0.101 ns.

**Worst setup slack:** 37.770 ns (MET) — endpoint `_499_` → `_498_`. Trivially above MET at 40 ns.

**Worst hold slack:** 0.459 ns (MET) — endpoint `_500_`. Trivially above MET at 40 ns.

**check_setup warnings:**

- 71 input ports missing `set_input_delay`.
- 33 output ports missing `set_output_delay`.
- 33 unconstrained endpoints.

No timing-closure or signoff claims are made. All slacks are trivially satisfied at 40 ns.

---

## 6. ROUTING / CONNECTIVITY STATE

- **Routed segments:** 0 (no routing performed; this is a pre-route estimate).
- **Dangling nets (1 pin):** 28.
- **0-pin nets:** 0.
- **Multi-pin nets with routing:** 0.

---

## 7. SIGNOFF / FINAL VERDICT

| Classification | Status |
|---|---|
| APPROVAL GATE | PASSED (APPROVED) |
| CTS EXECUTION | COMPLETED (TritonCTS, single pass) |
| CLOCK TREE | H-Tree depth 3, 10 nets, 14 buffers |
| PLACEMENT | LEGALITY FAILED (DPL-0033, 15 site-aligned cells) |
| TIMING ANALYSIS | MET (setup 37.770 ns, hold 0.459 ns at 40 ns period) |
| ROUTING | N/A (no routing performed) |
| SIGNOFF | NOT APPLICABLE (no timing closure claimed, no SoC compliance, no signoff) |

**Verdict:** CTS PASSED — PLACEMENT LEGALITY FAILED.

The timer block CTS experiment completed successfully: buffers and clock nets were inserted, skew and slack are trivially within bounds at the 40 ns provisional period, and all approval-gate hashes match. However, placement legality check (`check_placement`) failed on 15 CTS-inserted cells due to site-alignment mismatches (DPL-0033). No routing was performed, no timing-closure or signoff claims are made, and no ECO or legalizer run was executed. The approval record remains valid with all input manifests unchanged.

---

## Appendices

### Appendix A: Post-CTS Database Counts

| Category | Count |
|---|---|
| Total insts | 421 |
| PLACED | 316 |
| UNPLACED | 0 |
| other (FIXED/LOCKED tapcells) | 105 |
| `clkbuf_4` | 1 |
| `clkbuf_8` | 9 |
| `clkinv_1` | 22 |
| `clkinv_2` | 2 |
| `clkinvlp_4` | 2 |

### Appendix B: Input Manifest Integrity

All 7 input manifests (def.manifest, driver.manifest, lef.manifest, liberty.manifest, odb.manifest, platform_cfg.manifest, rc.manifest) regenerated independently and verified **IDENTICAL** to the approved versions.

### Appendix C: Output Hashes

| File | SHA-256 |
|---|---|
| `timer_cts.odb` | 62d98f52647856aa3a9d9bc1997c0c35e64fc42bb316d91107fc04dd729d0974 |
| `timer_cts.def` | ca9d99de2d417736b6fc5d1030f6f2be2669ee6f6ff2a2f288faeda2f2dc6e44 |
| `APPROVAL` | 52bde609a3c70fb85a30b1e04a4314268f9421fcebf827a2a81b0027b08a448a |
| baseline `timer_mapped_placed.odb` | 75e445acb4c6a969463f8083ac16d5f4ccdbff8d4109833276445bb00cdbc921 |
| baseline `timer_mapped_placed.def` | 32f3daf76f7c49c111b5ff15bfe9a1200bc399cbcd31cf2c5ac0011946aeaa29 |

### Appendix D: Topology BFS Guard

The `post_cts_checks.tcl` script was patched with `NULL` guards (`if {$n eq "NULL"} { continue }`) in the frontier loop and in `sinks_of_net`/`out_net_of_inst` to prevent `invalid command name "NULL"` crashes when a net object is absent.

---

*Report generated from deterministic, read-only post-CTS verification. No timing-closure, SoC-compliance, or signoff claims are made.*