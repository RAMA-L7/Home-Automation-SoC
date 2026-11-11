# DFT/ATPG and Sign-off Strategy — Home-Automation-SoC

**Document ID:** HAS-SoC-DFT-PLAN-001  
**Version:** 1.0  
**Date:** 2026-11-11  
**Status:** DRAFT — For Review  
**Addresses:** ARC-037 (BLOCKED), ARC-066 (BLOCKED), ARC-067 (BLOCKED), ADR-012

---

## 1. DFT Requirements Summary

| Requirement | Target | Rationale |
|-------------|--------|-----------|
| **Scan Coverage (Stuck-at)** | > 95% | Manufacturing test quality |
| **Scan Coverage (Transition)** | > 90% | Delay defect detection |
| **MBIST Coverage** | 100% (SRAM, TCM, ROM) | Memory reliability |
| **JTAG Compliance** | IEEE 1149.1 + 1149.6 | Board-level test + debug |
| **Test Time** | < 10 sec/device | Production throughput |
| **Pattern Count** | < 50k patterns | Test cost control |
| **Compression Ratio** | ≥ 50x | ATE memory reduction |

---

## 2. DFT Architecture

### 2.1 Scan Chain Organization

| Domain | Scan Chains | Flops/Chain | Total Flops | Compression |
|--------|-------------|-------------|-------------|-------------|
| **Core (clk_core)** | 4 | ~3,000 | ~12,000 | 50x (EDT) |
| **Peripheral (clk_periph)** | 2 | ~2,000 | ~4,000 | 50x (EDT) |
| **AON (clk_aon)** | 1 | ~500 | ~500 | None (short) |
| **Total** | **7** | — | **~16,500** | — |

**Notes:**
- Ibex core has internal scan (provided by lowRISC)
- Peripherals: Custom scan insertion via DFT tool
- AON domain: Minimal flops, separate chain (always-on)

### 2.2 Test Access Port (TAP)

| Feature | Implementation |
|---------|----------------|
| **Standard** | IEEE 1149.1 (JTAG) + 1149.6 (AC coupling for SerDes - N/A) |
| **TAP Controller** | Standard 16-state (provided by Ibex debug module) |
| **Instruction Register** | 8-bit (BYPASS, SAMPLE/PRELOAD, EXTEST, IDCODE, USER) |
| **Data Registers** | BSR (Boundary Scan), Scan Chains (7), IDCODE |
| **IDCODE** | 0x1234_567F (to be assigned by IEEE) |

### 2.3 Boundary Scan (BSR)

| Pin Type | BSR Cells | Notes |
|----------|-----------|-------|
| Digital I/O | 56 × 3 (In/Out/Control) | 168 cells |
| Power/Ground | 0 | Not in BSR |
| Analog (XTAL) | 2 × 1 (Observe only) | 2 cells |
| **Total BSR** | **170 cells** | |

---

## 3. Memory BIST (MBIST)

### 3.1 Memory Instances Requiring MBIST

| Memory | Size | Type | MBIST Controller | Algorithm |
|--------|------|------|------------------|-----------|
| **SRAM Macro** | 128 KB | OpenRAM SP/DP | Shared MBIST | March C-, Checkerboard |
| **TCM** | 32 KB | Custom SP | Dedicated MBIST | March C- |
| **Boot ROM** | 16 KB | ROM | Shared MBIST | Checksum + March |
| **QSPI Controller FIFO** | 32×64 | FIFO | Shared MBIST | March |

### 3.2 MBIST Architecture

- **Controller:** Single MBIST controller (clk_core domain) with per-memory config
- **Access:** Via JTAG USER instruction + APB shadow registers
- **Algorithms:** March C- (stuck-at), March LR (transition), Checkerboard (coupling)
- **Repair:** Not supported (no redundancy in baseline)
- **Diagnostics:** Fail bitmap output via JTAG

---

## 4. ATPG Strategy

### 4.1 Tool Selection (Commercial Required)

| Tool | Vendor | Capability | Estimated Cost |
|------|--------|------------|----------------|
| **DFTMAX Ultra** | Synopsys | Scan insert, ATPG, compression, MBIST | $50k–80k/yr |
| **Modus** | Cadence | Scan insert, ATPG, compression, MBIST | $50k–80k/yr |
| **Tessent** | Siemens | Scan insert, ATPG, compression, MBIST | $40k–70k/yr |

**Recommendation:** **Synopsys DFTMAX Ultra** (best OpenROAD/OpenLane integration, industry standard)

### 4.2 ATPG Flow

```bash
# 1. RTL with DFT pragmas
# 2. Synthesis (Yosys/OpenROAD) with scan insertion
# 3. DFTMAX: Scan chain definition, compression setup
# 4. DFTMAX: ATPG pattern generation (stuck-at + transition)
# 5. DFTMAX: Fault simulation, coverage report
# 6. Pattern translation: STIL/Verilog → ATE format
# 7. Silicon validation: Apply patterns, measure coverage
```

### 4.3 DFT Constraints

| Constraint | Value | Reason |
|------------|-------|--------|
| **Max Scan Chain Length** | 5,000 flops | Test time < 10 sec @ 10 MHz |
| **Clock Gating** | Scan enable overrides | Prevent clock gating during shift |
| **Reset** | Async assert, sync deassert in scan | Standard |
| **Power Domains** | Separate chains per domain | Domain isolation |
| **Compression** | EDT (Embedded Deterministic Test) | 50x typical |
| **X-Handling** | X-tolerant ATPG | Unknown states in memories |

---

## 5. Power Grid / IR-Drop Sign-off (ARC-067)

### 5.1 Power Grid Specification

| Layer | Direction | Pitch | Width | Purpose |
|-------|-----------|-------|-------|---------|
| **M6 (Top)** | Horizontal | 10 µm | 5 µm | Global VDD/GND straps |
| **M5** | Vertical | 10 µm | 5 µm | Global VDD/GND straps |
| **M4** | Horizontal | 5 µm | 2 µm | Regional distribution |
| **M3** | Vertical | 5 µm | 2 µm | Regional distribution |
| **M2/M1** | Local | Standard | Standard | Standard cell rails |

**Decoupling Capacitors:**
- **Density:** 1 decap cell per 100 µm²
- **Types:** High-K (MIM) + MOSCAP mix
- **Placement:** Automated (OpenROAD PDN gen + manual reinforcement)

### 5.2 IR-Drop Analysis Requirements

| Analysis | Tool | Corners | Target |
|----------|------|---------|--------|
| **Static IR-Drop** | PrimeTime-PX / Voltus | SS/FF/TT, -40°C/+125°C | < 10% VDD (100mV @ 1.0V) |
| **Dynamic IR-Drop** | PrimeTime-PX / Voltus | Worst-case switching | < 5% VDD (50mV @ 1.0V) |
| **Electromigration** | PrimeTime-PX / Voltus | All signal nets | < 0.1 mA/µm (avg), < 1 mA/µm (peak) |
| **Ground Bounce** | PrimeTime-PX / Voltus | Simultaneous switching | < 50 mV |

### 5.3 Sign-off Flow (Commercial Tool Required)

```bash
# 1. Post-PNR netlist + SPEF (OpenROAD)
# 2. Power intent (UPF) — defines domains, switches, retention
# 3. PrimeTime-PX / Voltus: Static IR analysis
# 4. PrimeTime-PX / Voltus: Dynamic IR (with SAIF/VCD from sim)
# 5. PrimeTime-PX / Voltus: EM analysis
# 6. Iterate: Add straps, decaps, widen rails → re-analyze
# 7. Sign-off: All corners clean
```

---

## 6. UPF (Unified Power Format) Definition

### 6.1 Power Domains (from ARC-008)

```tcl
# UPF 3.0 for HAS-SoC
create_power_domain PD_AON      -include {AON/*}      -supply {VDD_AON VSS}
create_power_domain PD_CORE     -include {CORE/*}     -supply {VDD_CORE VSS}
create_power_domain PD_PERIPH   -include {PERIPH/*}   -supply {VDD_PERIPH VSS}
create_power_domain PD_IO       -include {IO/*}       -supply {VDD_IO VSS}

# Supply ports
create_supply_port VDD_AON      -direction in
create_supply_port VDD_CORE     -direction in
create_supply_port VDD_PERIPH   -direction in
create_supply_port VDD_IO       -direction in
create_supply_port VSS          -direction in

# Supply nets
create_supply_net VDD_AON       -domain PD_AON
create_supply_net VDD_CORE      -domain PD_CORE
create_supply_net VDD_PERIPH    -domain PD_PERIPH
create_supply_net VDD_IO        -domain PD_IO
create_supply_net VSS           -domain {PD_AON PD_CORE PD_PERIPH PD_IO}

# Power switches (PMIC controlled via GPIO)
create_power_switch SW_CORE     -domain PD_CORE     -control {PMIC_BUCK1_EN} -on_state {VDD_CORE} -off_state {VSS}
create_power_switch SW_PERIPH   -domain PD_PERIPH   -control {PMIC_LDO2_EN}  -on_state {VDD_PERIPH} -off_state {VSS}
create_power_switch SW_IO       -domain PD_IO       -control {PMIC_BUCK2_EN} -on_state {VDD_IO} -off_state {VSS}

# Retention (AON only)
create_retention_rule RET_AON   -domain PD_AON      -retention_power_net VDD_AON -retention_ground_net VSS

# Isolation (Core/Periph/IO → AON)
create_isolation_rule ISO_CORE2AON   -domain PD_CORE     -applies_to inputs -clamp_value 0 -isolation_power_net VDD_AON -isolation_ground_net VSS -isolation_signal {PMIC_PWR_GOOD_CORE}
create_isolation_rule ISO_PERIPH2AON -domain PD_PERIPH   -applies_to inputs -clamp_value 0 -isolation_power_net VDD_AON -isolation_ground_net VSS -isolation_signal {PMIC_PWR_GOOD_PERIPH}
```

---

## 7. Commercial Tool Budget & Procurement

| Tool | Purpose | License Type | Annual Cost | Procurement Path |
|------|---------|--------------|-------------|------------------|
| **Synopsys DFTMAX Ultra** | Scan insert, ATPG, compression | Floating (2 seats) | ~$70k | Direct or via reseller |
| **Synopsys PrimeTime-PX** | Static/Dynamic IR, EM | Floating (1 seat) | ~$100k | Direct or via reseller |
| **Synopsys SpyGlass** | CDC/Lint/CDC (supplement SymbiYosys) | Floating (1 seat) | ~$30k | Direct or via reseller |
| **Cadence Voltus** | Alternative IR/EM | Floating (1 seat) | ~$90k | If PrimeTime unavailable |
| **Total (Synopsys Stack)** | — | — | **~$200k/yr** | — |

**Alternative: Foundry Service**
- **Efabless/Shuttle Service:** Includes DFT/ATPG for MPW (~$10k extra per shuttle)
- **IHP Service:** Includes sign-off for SG13G2 (~€15k)
- **Trade-off:** Less control, but no tool license cost

---

## 8. Open-Source Alternatives (Gap Analysis)

| Capability | Open-Source Tool | Status | Gap |
|------------|------------------|--------|-----|
| **Scan Insertion** | OpenROAD (partial) | Experimental | No compression, no X-handling |
| **ATPG** | **NONE** | — | Critical gap |
| **MBIST Insertion** | OpenROAD (partial) | Basic March only | No diagnostics, no repair |
| **Static IR** | OpenROAD (PDN) + OpenSTA | Basic | No dynamic, no EM |
| **Dynamic IR** | **NONE** | — | Critical gap |
| **EM Analysis** | **NONE** | — | Critical gap |
| **UPF Support** | OpenROAD (partial) | Basic | No power switch verification |

**Conclusion:** Open-source flow **cannot** achieve production sign-off for DFT/ATPG and IR/EM. Commercial tools **mandatory** for ARC-037/066/067 resolution.

---

## 9. Sign-off Checklist (Gate 4 — ASIC Tape-out)

| Item | Tool | Status |
|------|------|--------|
| Scan Insertion Complete | DFTMAX | ☐ |
| Stuck-at Coverage > 95% | DFTMAX | ☐ |
| Transition Coverage > 90% | DFTMAX | ☐ |
| MBIST Inserted (all memories) | DFTMAX | ☐ |
| MBIST Coverage 100% | DFTMAX | ☐ |
| Pattern Generation (STIL) | DFTMAX | ☐ |
| Static IR-Drop < 10% | PrimeTime-PX | ☐ |
| Dynamic IR-Drop < 5% | PrimeTime-PX | ☐ |
| EM Analysis Clean | PrimeTime-PX | ☐ |
| DRC Clean | Calibre / Magic | ☐ |
| LVS Clean | Calibre / Netgen | ☐ |
| ERC Clean | Calibre | ☐ |
| STA Sign-off (All Corners) | PrimeTime / OpenSTA | ☐ |
| Antenna Check | Calibre | ☐ |
| **ARC-037 / ARC-066 / ARC-067 → PROPOSED** | — | ☐ |

---

## 10. Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Commercial tool budget denied | High | Critical (blocks tapeout) | Pursue foundry service alternative; phase DFT to MPW |
| Tool license delays | Medium | Schedule slip | Start procurement now; 8–12 week lead time |
| Coverage < 95% | Medium | Re-spin | Design for testability (DFT-friendly RTL); add test points |
| IR-drop > 10% | Medium | Re-spin | Early PDN planning; decap budget; floorplan optimization |
| UPF/Power intent errors | Medium | Functional bugs | Formal UPF verification (SpyGlass); simulation cross-check |

---

## 11. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-11 | Lead | Initial DFT/ATPG/IR-Drop strategy for ARC-037/066/067 |

---

*This strategy document moves ARC-037, ARC-066, ARC-067 from BLOCKED → PROPOSED **pending commercial tool procurement commitment**. Actual sign-off requires tool execution.*