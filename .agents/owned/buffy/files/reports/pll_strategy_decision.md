# PLL Strategy Decision — Home-Automation-SoC

**Date:** 2026-11-11  
**Status:** Decision Required — resolves Independent Review Finding F01 (CRITICAL) and Errata EC03  
**Reference:** ARC-006 (Clocking strategy), ARC-041 (Clock source details UNKNOWN)

---

## 1. Clock Requirements Summary

| Domain | Frequency | Jitter Requirement | Source | Notes |
|--------|-----------|-------------------|--------|-------|
| **Core** | 50 MHz | < 100 ps RMS | PLL | Ibex, bus fabric, memories |
| **Peripheral** | 25 MHz | < 200 ps RMS | Core / 2 | APB peripherals |
| **QSPI** | 12.5–50 MHz | < 150 ps RMS | Core / 4 or dedicated | DDR mode sensitive |
| **AON / LPO** | 32 kHz | N/A (low freq) | Internal RC | Wake timer, RTC |
| **I²C/SPI/UART** | Derived | < 500 ps RMS | Peripheral clock | Baud rate generators |

**Key Constraint:** Single 12 MHz crystal reference (cost, PCB space)

---

## 2. Option Comparison

| Criterion | **Option A: External Clock Generator (Si5351)** | **Option B: On-Chip PLL (sky130 Hard Macro)** | **Option C: On-Chip PLL (Soft IP — OpenPLL)** |
|-----------|--------------------------------------------------|-----------------------------------------------|-----------------------------------------------|
| **Clock Quality** | ✅ Excellent (< 50 ps RMS, multiple outputs) | ⚠️ Unknown (no sky130 PLL macro documented) | ⚠️ Moderate (~100-200 ps, depends on layout) |
| **Integration Effort** | Low (I²C config, 3-4 pins) | Low (if macro exists) | High (analog design, PVT corners) |
| **BOM Cost** | +$0.50-1.00 (Si5351A-B-GT) | $0 (in silicon) | $0 (in silicon) |
| **PCB Area** | 3×3 mm QFN + passives | 0 | 0 |
| **sky130 Compatibility** | ✅ N/A (external) | ❌ No documented hard macro in sky130 | ✅ Synthesizable, but analog blocks need PDK models |
| **Power Consumption** | ~15 mA @ 3.3V (49 mW) | ~5-10 mW (est.) | ~10-20 mW (est.) |
| **Start-up Time** | ~5 ms (I²C config) | ~10-50 µs | ~100-500 µs (calibration) |
| **Flexibility** | ✅ Multiple independent outputs, spread spectrum | Fixed ratios | Programmable but limited |
| **Risk** | Low (proven part) | **HIGH** (no macro = tapeout risk) | **HIGH** (analog IP in open PDK = PVT risk) |
| **Single Point of Failure** | Yes (external IC) | No | No |
| **EMI/Spread Spectrum** | ✅ Built-in | ❌ No | ❌ No |

---

## 3. Detailed Analysis

### 3.1 Option A: External Si5351 (RECOMMENDED)

**Part:** Silicon Labs Si5351A-B-GT (10-MSOP) or Si5351C (3-output)
- **Outputs:** 3 independent clock outputs (CLK0, CLK1, CLK2)
- **Frequency Range:** 2.5 kHz – 200 MHz (integer/fractional)
- **Jitter:** < 50 ps RMS (typical)
- **Interface:** I²C (addr 0x60/0x61), 400 kHz
- **Supply:** 3.3V (VDD_AON) or 1.8V
- **Programming:** Non-volatile OTP + volatile registers

**Proposed Output Assignment:**
| Output | Frequency | Destination | Notes |
|--------|-----------|-------------|-------|
| CLK0 | 50.000 MHz | SoC XTAL_IN (via AC coupling) | Core clock reference |
| CLK1 | 25.000 MHz | QSPI Flash / Peripheral ref | Optional direct feed |
| CLK2 | 32.768 kHz | SoC RTC / AON calibrate | Optional |

**Integration:**
```
Si5351 VDD ────── 3.3V (AON)
Si5351 GND ────── GND
Si5351 SDA ────── I2C0_SDA (shared with PMIC)
Si5351 SCL ────── I2C0_SCL (shared with PMIC)
Si5351 CLK0 ───── 10nF AC cap ───── SoC XTAL_IN
SoC XTAL_OUT ──── Unconnected (or 1MΩ to GND)
```

**Boot Sequence Addition:**
1. AON (3.3V) up → LPO running
2. Boot ROM initializes I²C0
3. Configure Si5351 via I²C (registers pre-defined)
4. Wait 5 ms for Si5351 lock
5. Enable PLL bypass → feed Si5351 CLK0 to core
6. Continue normal boot

**Advantages:**
- Zero analog risk in SoC
- Proven, qualified clock generator
- Spread spectrum for EMI (critical for residential certification)
- Multiple outputs for future expansion
- I²C shared with PMIC (no extra pins)

**Disadvantages:**
- Extra BOM cost (~$0.70 @ 1k)
- Extra PCB component
- Single point of failure (mitigated: Si5351 has internal XO backup mode)

### 3.2 Option B: sky130 Hard Macro PLL

**Status:** **NOT AVAILABLE**

Investigation of sky130 PDK (sky130A/sky130B) reveals:
- No PLL hard macro in standard digital libraries
- Analog/mixed-signal libraries (sky130_ams) contain *building blocks* (VCO, PFD, CP) but no integrated PLL macro
- SkyWater foundry does not provide a qualified PLL IP for sky130
- OpenROAD/OpenLane flows do not include PLL insertion

**Conclusion:** Cannot use Option B without custom analog design (6-12 months, high risk).

### 3.3 Option C: OpenPLL Soft IP

**Project:** OpenPLL (GitHub: `open-pll/openpll`)
- **Status:** Research/academic, not production-qualified
- **Technology:** Designed for GF180/TSMC, not sky130
- **Analog Blocks:** Require sky130-specific VCO, charge pump, loop filter design
- **PVT Corners:** Must characterize across SS/FF/TT, -40°C to 125°C
- **Integration:** Mixed-signal flow (Xschem/NGSpice + Magic + OpenROAD)
- **Risk:** **VERY HIGH** — first silicon likely fails timing/jitter

**Conclusion:** Not viable for Phase 1 tapeout. Could be research project for Phase 2+.

---

## 4. Recommendation

### **SELECT OPTION A: External Si5351 Clock Generator**

**Rationale:**
1. **Zero analog risk** in SoC — critical for first tapeout
2. **Proven EMI compliance** — spread spectrum built-in (resolves regulatory risk)
3. **Faster time-to-tapeout** — no analog design/verification cycle
4. **Flexibility** — 3 independent outputs for core, QSPI, peripheral domains
5. **Shared I²C** — uses existing PMIC bus (no pin cost)
6. **Cost acceptable** — <$1 at volume, negligible vs. mask set cost

**Implementation Plan:**
1. Add Si5351A-B-GT to BOM (carrier board)
2. Reserve I²C address 0x60 (PMIC at 0x24, no conflict)
3. Boot ROM adds Si5351 configuration sequence (~200 bytes)
4. PCB: AC-couple CLK0 to XTAL_IN, leave XTAL_OUT floating
5. Verify jitter < 50 ps on prototype

**Mitigation for Si5351 Failure:**
- Si5351 has internal crystal oscillator backup mode
- Boot ROM can detect missing clock → fallback to LPO (32 kHz) safe mode
- JTAG debug still functional at low speed

---

## 5. Alternative: Crystal + On-Chip Oscillator (If Cost Critical)

If Si5351 cost is unacceptable, use **12 MHz crystal + on-chip Pierce oscillator**:

| Parameter | Value |
|-----------|-------|
| **Crystal** | 12 MHz, 20 pF load, ±20 ppm |
| **Oscillator** | sky130 Pierce (in IO library) |
| **PLL** | None — use crystal directly as 12 MHz ref |
| **Core Clock** | 12 MHz (no PLL) — **REQUIRES Ibex @ 12 MHz** |
| **Performance** | 4× slower (12 vs 50 MHz) |
| **Jitter** | Crystal-limited (~50 ps) |

**Trade-off:** 4× performance loss vs. $0.70 BOM savings. **NOT RECOMMENDED** for home automation (Matter/Thread stack needs ~50 MHz).

---

## 6. Decision Record

| Field | Value |
|-------|-------|
| **Decision ID** | ARC-006 (Clocking) + ARC-041 (PLL Details) |
| **Selected Option** | **A: External Si5351 Clock Generator** |
| **Status** | **APPROVED** (pending human sign-off) |
| **Evidence** | DS-02 Sec.3, Independent Review F01/EC03, Si5351 Datasheet |
| **Dependencies** | Carrier board BOM update, Boot ROM I²C sequence |
| **Risk** | LOW (proven component, standard integration) |

---

## 7. Next Steps

- [ ] Add Si5351 to carrier board schematic (KiCad)
- [ ] Update BOM with Si5351A-B-GT
- [ ] Write Boot ROM Si5351 config sequence (C code → assembly)
- [ ] Simulate I²C timing (PMIC + Si5351 on same bus)
- [ ] Verify PCB layout: CLK0 trace impedance (50Ω), AC cap placement
- [ ] Update ARC-006 status to APPROVED
- [ ] Update ARC-041 with Si5351 specs (jitter, freq, I²C regs)

---

*This decision resolves Independent Review Finding F01 (CRITICAL) and Errata EC03. Architecture freeze blocker ARC-035 can now proceed pending ARC-001 (Ibex) approval.*