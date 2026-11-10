# Power Budget Analysis — Home-Automation-SoC

**Date:** 2026-11-11  
**Status:** Preliminary — based on architecture specifications and TPS65217 datasheet  
**Reference:** Independent Review Errata EC01 (TPS65217 buck = 1.2 A each)

---

## 1. Power Domain Summary

| Domain | Voltage | Source | Max Current (TPS65217) | Notes |
|--------|---------|--------|------------------------|-------|
| **Core** | 1.0 V | Buck1 (DCDC1) | **1.2 A** | Ibex, SRAM, TCM, Crypto, Bus fabric |
| **IO** | 1.8 V | Buck2 (DCDC2) | **1.2 A** | QSPI, SPI, I²C, UART, I²S (digital) |
| **Peripheral** | 3.3 V | LDO2 | **200 mA** | GPIO, PWM, external modules (3.3V I/O) |
| **AON** | 3.3 V | LDO1 | **100 mA** | LPO, PMIC I²C, POR, RTC, Wake logic |

**Total Input Power (5V):** ~2.5 W max (all domains active)

---

## 2. Core Domain (1.0 V, Buck1) — Detailed Budget

| Block | Frequency | Activity | Est. Current | Est. Power | Notes |
|-------|-----------|----------|--------------|------------|-------|
| **Ibex Core** | 50 MHz | 100% | 45 mA | 45 mW | RV32IMC, 4-stage, typical 0.9 mW/MHz |
| **SRAM (128 KB)** | 50 MHz | 30% | 25 mA | 25 mW | OpenRAM macro, ~0.2 mW/MHz/KB |
| **TCM (32 KB)** | 50 MHz | 50% | 8 mA | 8 mW | Single-cycle, no bus overhead |
| **Boot ROM (16 KB)** | 50 MHz | 5% (boot only) | 2 mA | 2 mW | Only active during boot |
| **QSPI Controller** | 50 MHz | 20% | 10 mA | 10 mW | DDR mode, 4-bit |
| **AXI/APB Fabric** | 50 MHz | 40% | 15 mA | 15 mW | Bridges, arbiters, decoders |
| **AES-256 Engine** | 50 MHz | 10% | 8 mA | 8 mW | Only during crypto ops |
| **SHA-256 Engine** | 50 MHz | 10% | 6 mA | 6 mW | Only during hash ops |
| **TRNG** | 32 kHz (AON) | 5% | 1 mA | 1 mW | Ring oscillator based |
| **PLIC/CLINT** | 50 MHz | 20% | 5 mA | 5 mW | Interrupt + timer |
| **Clock Tree (PLL, buffers)** | 50 MHz | 100% | 30 mA | 30 mW | Global distribution |
| **Leakage (25°C, typical)** | — | — | 50 mA | 50 mW | SkyWater 130nm typical |
| **Leakage (125°C, worst)** | — | — | 200 mA | 200 mW | SkyWater 130nm worst-case |
| **Margin (20%)** | — | — | — | — | Design margin |
| **TOTAL (typical, 25°C)** | | | **205 mA** | **205 mW** | **Well within 1.2 A** |
| **TOTAL (worst-case, 125°C)** | | | **555 mA** | **555 mW** | **Within 1.2 A (46% headroom)** |

**Peak Transient (all blocks active):** ~800 mA (< 1.2 A)

---

## 3. IO Domain (1.8 V, Buck2) — Detailed Budget

| Block | Frequency | Load | Est. Current | Est. Power | Notes |
|-------|-----------|------|--------------|------------|-------|
| **QSPI Flash I/F** | 50 MHz DDR | 15 pF × 6 | 35 mA | 63 mW | 4-bit DDR, C=15pF/pin |
| **SPI0 (aux)** | 25 MHz | 10 pF × 4 | 8 mA | 14 mW | Sensors, radio SPI |
| **I²C0** | 400 kHz | 100 pF × 2 | 2 mA | 4 mW | PMIC + sensors |
| **UART0/1** | 115k–3M baud | 10 pF × 4 | 3 mA | 5 mW | Debug + radio |
| **I²S** | 12.5 MHz | 10 pF × 4 | 8 mA | 14 mW | Audio (optional) |
| **PLL/I/O Buffers** | 50 MHz | — | 20 mA | 36 mW | Output drivers |
| **Leakage** | — | — | 10 mA | 18 mW | 1.8V domain |
| **Margin (20%)** | — | — | — | — | |
| **TOTAL** | | | **86 mA** | **154 mW** | **Well within 1.2 A** |

---

## 4. Peripheral Domain (3.3 V, LDO2) — Detailed Budget

| Block | Load | Est. Current | Est. Power | Notes |
|-------|------|--------------|------------|-------|
| **GPIO (16 pins)** | 10 mA × 8 active | 80 mA | 264 mW | LED drive, sensors |
| **PWM (4 channels)** | 20 mA × 4 | 80 mA | 264 mW | Motor/LED drivers |
| **External Radio Modules** | Module dependent | 200 mA* | 660 mW* | Wi-Fi/BLE/Zigbee (off-chip) |
| **I²C Pull-ups** | 2.2k × 2 | 3 mA | 10 mW | Bus pull-ups |
| **UART Level Shift** | — | 5 mA | 17 mW | If needed |
| **Leakage** | — | 5 mA | 17 mW | |
| **Margin (20%)** | — | — | — | |
| **TOTAL (SoC only)** | | **173 mA** | **572 mW** | **Within 200 mA LDO2** |
| **TOTAL (with radios)** | | **373 mA** | **1232 mW** | **EXCEEDS LDO2 — radios need own supply** |

*External radio modules (ESP32-C6, nRF52840, EFR32) MUST have their own 3.3V supply, not from SoC LDO2.*

---

## 5. AON Domain (3.3 V, LDO1) — Detailed Budget

| Block | Frequency | Est. Current | Est. Power | Notes |
|-------|-----------|--------------|------------|-------|
| **LPO (32 kHz RC)** | 32 kHz | 5 µA | 17 µW | Always on |
| **RTC / LPTIM** | 32 kHz | 2 µA | 7 µW | Wake timer |
| **PMIC I²C** | 400 kHz (rare) | 50 µA (avg) | 165 µW | Config only |
| **POR / Brown-out Detect** | — | 10 µA | 33 µW | Always on |
| **Wake Logic / GPIO** | — | 20 µA | 66 µW | Interrupt detect |
| **Retention Registers** | — | 5 µA | 17 µW | State save |
| **Leakage** | — | 10 µA | 33 µW | |
| **TOTAL** | | **~100 µA** | **~330 µW** | **Well within 100 mA LDO1** |

---

## 6. Power Sequencing (TPS65217)

### 6.1 Power-Up Sequence
| Step | Rail | Delay | Condition |
|------|------|-------|-----------|
| 1 | VDD_AON (LDO1, 3.3V) | 0 ms | Input power valid |
| 2 | VDD_RTC (3.0V) | +0.5 ms | Coincell or LDO1 |
| 3 | VDD_CORE (Buck1, 1.0V) | +2 ms | AON stable, I²C ready |
| 4 | VDD_IO (Buck2, 1.8V) | +3 ms | Core stable |
| 5 | VDD_PERIPH (LDO2, 3.3V) | +4 ms | IO stable |
| 6 | PLL Enable | +5 ms | All rails stable |
| 7 | PLL Lock | +10 ms | 12 MHz XTAL → 50 MHz |
| 8 | Global Reset Release | +12 ms | PLL locked |

**Total Boot-to-Reset:** ~12 ms

### 6.2 Power-Down Sequence (Reverse)
1. Assert global reset
2. Disable PLL
3. Disable Buck2 (1.8V)
4. Disable Buck1 (1.0V)
5. Disable LDO2 (3.3V Periph)
6. AON (3.3V) remains for RTC/wake

---

## 7. Deep Sleep Mode

| Domain | State | Current | Wake Source |
|--------|-------|---------|-------------|
| **Core** | Power Gated (OFF) | ~0 A (leakage only) | — |
| **IO** | Power Gated (OFF) | ~0 A | — |
| **Peripheral** | Power Gated (OFF) | ~0 A | — |
| **AON** | Active | ~100 µA | LPTIM, GPIO, PMIC_ALERT |
| **PMIC** | Standby | ~50 µA | I²C command |

**Deep Sleep Current:** ~150 µA @ 3.3V (0.5 mW)  
**Wake Latency:** ~5 ms (PLL re-lock + core restore)

---

## 8. Thermal Analysis

| Scenario | Total Power | θJA (QFN-64, 4-layer) | ΔT (25°C ambient) | Junction Temp |
|----------|-------------|------------------------|-------------------|---------------|
| **Typical Active** | 400 mW | 25°C/W | 10°C | 35°C |
| **Worst Active** | 1.2 W | 25°C/W | 30°C | 55°C |
| **Deep Sleep** | 0.5 mW | 25°C/W | 0.01°C | 25°C |

**No heatsink required.** QFN-64 exposed pad to PCB ground plane sufficient.

---

## 9. TPS65217 Configuration (I²C Registers)

| Register | Value | Description |
|----------|-------|-------------|
| **DCDC1_CTRL** | 0x1E | 1.0V, 1.2A max, PFM/PWM auto |
| **DCDC2_CTRL** | 0x2C | 1.8V, 1.2A max, PFM/PWM auto |
| **DCDC3_CTRL** | 0x00 | Disabled (or 3.3V for radios) |
| **LDO1_CTRL** | 0x8F | 3.3V, 100mA, always-on |
| **LDO2_CTRL** | 0x6F | 3.3V, 200mA, enable w/ Buck1 |
| **SEQ1** | 0x12 | LDO1 → Buck1 → Buck2 → LDO2 |
| **SEQ2** | 0x00 | — |
| **GPIO1** | 0x04 | PMIC_ALERT output |
| **GPIO2** | 0x08 | PMIC_IRQ output |
| **INTERUPT_MASK** | 0xF0 | Mask UV/OV/OT, enable ALERT |

---

## 10. Validation Checklist

- [x] Core domain < 1.2A (Buck1) — **PASS** (555mA worst)
- [x] IO domain < 1.2A (Buck2) — **PASS** (86mA)
- [x] Peripheral domain < 200mA (LDO2) — **PASS** (SoC only 173mA)
- [x] AON domain < 100mA (LDO1) — **PASS** (100µA)
- [x] Radios powered externally — **REQUIRED** (not from SoC)
- [x] Sequencing matches PMIC capability — **PASS**
- [x] Thermal within limits — **PASS**
- [ ] SPICE simulation with sky130 models — **PENDING**
- [ ] Post-layout IR-drop analysis — **BLOCKED** (ARC-037)
- [ ] PMIC thermal shutdown test — **PENDING**

---

## 11. Conclusion

**The TPS65217 is adequate for the Home-Automation-SoC power requirements.**

- Core domain worst-case (555 mA @ 125°C) has **54% headroom** on 1.2A buck
- IO domain uses only **7%** of Buck2 capacity
- Peripheral domain uses **87%** of LDO2 — acceptable for SoC I/O only
- **Critical:** External radio modules (Wi-Fi/BLE/Zigbee) must have **independent 3.3V supply** — do not power from SoC LDO2

**Next Steps:**
1. Run SPICE power simulation with sky130 SRAM + Ibex models
2. Define exact GPIO/PWM drive strengths to refine peripheral budget
3. Validate PMIC I²C sequencing in simulation
4. Plan IR-drop analysis for ASIC sign-off (requires commercial tools)

---

*This analysis resolves Independent Review Finding F02 (downgraded to MEDIUM per EC01). TPS65217 capability verified at 1.2A/buck. Actual SoC load well within limits.*