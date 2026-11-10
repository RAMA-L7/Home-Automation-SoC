# Performance Requirements Specification — Home-Automation-SoC

**Document ID:** HAS-SoC-PRS-001  
**Version:** 1.0  
**Date:** 2026-11-11  
**Status:** DRAFT — For Review  
**Parent:** HAS-SoC-SRS-001 (System Requirements)

---

## 1. Processing Performance

### 1.1 Core Performance Targets

| Metric | Target | Condition | Verification |
|--------|--------|-----------|--------------|
| **Clock Frequency** | 50 MHz | Nominal, 1.0V, 25°C | STA, FPGA |
| **Clock Frequency (Max)** | 60 MHz | 1.05V, -40°C | STA corners |
| **Clock Frequency (Min)** | 40 MHz | 0.95V, 125°C | STA corners |
| **DMIPS/MHz** | ≥ 0.9 | RV32IMC, GCC -O2 | CoreMark, Dhrystone |
| **CoreMark Score** | ≥ 110 | 50 MHz, GCC -O2 | FPGA benchmark |
| **Interrupt Latency** | ≤ 50 cycles | PLIC → handler entry | Sim + FW measurement |
| **Context Switch (Zephyr)** | ≤ 5 µs | 50 MHz, minimal config | FW benchmark |
| **Branch Prediction** | Static (always not taken) | Ibex default | RTL sim |

### 1.2 Memory Performance

| Metric | Target | Condition | Verification |
|--------|--------|-----------|--------------|
| **SRAM Access Latency** | 1 cycle (read), 1 cycle (write) | 50 MHz, no contention | RTL sim, STA |
| **SRAM Throughput** | 200 MB/s (32-bit @ 50 MHz) | Sequential access | RTL sim |
| **TCM Access Latency** | 0 cycles (combinational) | Core pipeline direct | RTL sim |
| **TCM Throughput** | 200 MB/s (32-bit @ 50 MHz) | Zero wait states | RTL sim |
| **Boot ROM Latency** | 1 cycle | 50 MHz | RTL sim |
| **QSPI Flash (XIP, SDR)** | 50 MB/s | 50 MHz, 1-bit | FW benchmark |
| **QSPI Flash (XIP, DDR)** | 100 MB/s | 50 MHz DDR, 4-bit | FW benchmark |
| **Boot ROM Verify Time** | < 100 ms | ECDSA-P256 + SHA-256 | HW measurement |

### 1.3 Bus and Interconnect Performance

| Metric | Target | Condition | Verification |
|--------|--------|-----------|--------------|
| **AXI4-Lite Read Latency** | 3 cycles (addr → data) | No contention | RTL sim |
| **AXI4-Lite Write Latency** | 2 cycles (addr+data → resp) | No contention | RTL sim |
| **APB Bridge Latency** | +2 cycles (AXI → APB) | Peripheral access | RTL sim |
| **Bus Utilization (Peak)** | < 70% | All masters active | Sim + analysis |
| **Arbitration Latency** | ≤ 2 cycles | Round-robin | RTL sim |

---

## 2. Peripheral Performance

### 2.1 Communication Interfaces

| Interface | Metric | Target | Condition |
|-----------|--------|--------|-----------|
| **UART0/1** | Max Baud Rate | 3 Mbps | 1.8V domain, 50 MHz ref |
| **UART0/1** | TX Throughput | ≥ 2.5 Mbps sustained | FIFO + interrupt |
| **UART0/1** | RX Throughput | ≥ 2.5 Mbps sustained | FIFO + interrupt |
| **I²C0** | Max Speed | 1 Mbps (Fast+) | 400 kHz typical |
| **I²C0** | Bus Capacitance | ≤ 400 pF | Standard |
| **SPI0 (Flash)** | Max Frequency | 50 MHz DDR | 4-bit Quad |
| **SPI0 (Flash)** | Read Throughput | ≥ 20 MB/s (XIP) | DDR mode |
| **SPI0 (Radio)** | Max Frequency | 25 MHz | Single-bit |
| **I²S** | Sample Rates | 8–48 kHz | Master/Slave |
| **I²S** | Data Width | 16/24/32-bit | Configurable |

### 2.2 Control Interfaces

| Interface | Metric | Target | Condition |
|-----------|--------|--------|-----------|
| **GPIO** | Toggle Rate | ≥ 25 MHz | Output mode, no load |
| **GPIO** | Interrupt Latency | ≤ 100 ns | Edge detect → PLIC |
| **PWM** | Frequency Range | 1 Hz – 1 MHz | 16-bit resolution |
| **PWM** | Duty Resolution | 16-bit (65,536 steps) | At 1 MHz: 15 ns steps |
| **PWM** | Jitter | < 1 ns | Cycle-to-cycle |
| **Timer0/1** | Resolution | 32-bit @ 25 MHz | 40 ns ticks |
| **Timer0/1** | Max Period | 171 s | 32-bit @ 25 MHz |
| **LPTIM** | Resolution | 32-bit @ 32 kHz | 30.5 µs ticks |
| **LPTIM** | Max Period | 36 hours | 32-bit @ 32 kHz |
| **LPTIM** | Wake Accuracy | ±1 tick | Deep sleep exit |

---

## 3. Security Performance

### 3.1 Cryptographic Accelerators

| Engine | Metric | Target | Standard/Mode |
|--------|--------|--------|---------------|
| **AES-256** | Throughput | ≥ 10 MB/s | ECB/CBC/CTR/GCM |
| **AES-256** | Latency (1 block) | ≤ 200 cycles | 128-bit block |
| **AES-256** | Key Setup | ≤ 50 cycles | Key expansion |
| **SHA-256** | Throughput | ≥ 15 MB/s | Streaming |
| **SHA-256** | Latency (1 block) | ≤ 100 cycles | 512-bit block |
| **SHA-256** | Context Switch | ≤ 20 cycles | Save/restore |
| **TRNG** | Entropy Rate | ≥ 1 Mbps | Continuous |
| **TRNG** | Latency (256-bit) | ≤ 1 ms | Health test included |
| **ECDSA-P256 (SW)** | Sign | ≤ 50 ms | Mbed TLS, 50 MHz |
| **ECDSA-P256 (SW)** | Verify | ≤ 100 ms | Mbed TLS, 50 MHz |
| **Secure Boot Total** | Verify + Measure | ≤ 100 ms | ROM + HW accel |

### 3.2 OTA Update Performance

| Metric | Target | Condition |
|--------|--------|-----------|
| **Download Rate** | ≥ 500 kbps | BLE/Wi-Fi dependent |
| **Decrypt+Verify (1 MB)** | ≤ 500 ms | AES-GCM + ECDSA |
| **Flash Write (1 MB)** | ≤ 2 s | QSPI page program |
| **Total OTA Time (1 MB)** | ≤ 3 s | End-to-end |
| **Rollback Time** | ≤ 100 ms | Metadata switch + reboot |

---

## 4. Power Performance

### 4.1 Active Mode (All Domains On)

| Domain | Voltage | Typical Current | Max Current (125°C) | Power (Typ) | Power (Max) |
|--------|---------|-----------------|---------------------|-------------|-------------|
| **Core (1.0V)** | 1.0V | 205 mA | 555 mA | 205 mW | 555 mW |
| **IO (1.8V)** | 1.8V | 86 mA | 100 mA | 155 mW | 180 mW |
| **Peripheral (3.3V)** | 3.3V | 173 mA | 200 mA | 571 mW | 660 mW |
| **AON (3.3V)** | 3.3V | 0.1 mA | 1 mA | 0.3 mW | 3.3 mW |
| **TOTAL** | — | **464 mA** | **856 mA** | **931 mW** | **1.4 W** |

*Peripheral domain excludes external radio modules (separate supply)*

### 4.2 Low-Power Modes

| Mode | Domains Active | Current (3.3V eq.) | Power | Wake Latency | Wake Sources |
|------|----------------|-------------------|-------|--------------|--------------|
| **Idle (WFI)** | AON + Core (clk gated) | ~15 mA | ~50 mW | < 1 µs | Any interrupt |
| **Light Sleep** | AON + Core (retention) | ~5 mA | ~16 mW | ~10 µs | GPIO, Timer, PMIC |
| **Deep Sleep** | AON only | ~0.3 mA | **< 1 mW** | **< 10 ms** | LPTIM, GPIO, PMIC_ALERT |
| **Shutdown** | None (RTC only) | ~10 µA | ~33 µW | ~50 ms | PMIC_IRQ, RTC alarm |

### 4.3 Power State Transitions

| Transition | Energy | Time | Notes |
|------------|--------|------|-------|
| **Active → Idle** | Negligible | 1 cycle | WFI instruction |
| **Idle → Active** | Negligible | 1 cycle | Interrupt |
| **Active → Deep Sleep** | ~1 mJ | ~100 µs | Context save + rail off |
| **Deep Sleep → Active** | ~5 mJ | < 10 ms | PLL lock + context restore |
| **Shutdown → Active** | ~10 mJ | ~50 ms | Full boot (secure) |

---

## 5. Boot and Startup Performance

| Phase | Target Time | Cumulative | Notes |
|-------|-------------|------------|-------|
| **POR → AON Stable** | 1 ms | 1 ms | LPO + PMIC I²C |
| **PMIC Sequencing** | 5 ms | 6 ms | 4 rails |
| **Si5351 Config + Lock** | 5 ms | 11 ms | I²C + PLL lock |
| **Global Reset Release** | 1 ms | 12 ms | |
| **Boot ROM Self-Test** | 5 ms | 17 ms | SRAM march test |
| **Boot ROM Crypto Init** | 5 ms | 22 ms | TRNG, AES, SHA |
| **Firmware Verify (ECDSA)** | 50 ms | 72 ms | 256 KB image |
| **Firmware Measure (SHA)** | 20 ms | 92 ms | For attestation |
| **Jump to Firmware** | 1 ms | 93 ms | |
| **Zephyr Early Init** | 30 ms | 123 ms | Kernel, drivers |
| **App Start (Matter/HA)** | 50 ms | 173 ms | Network connect |
| **TOTAL (POR → App Ready)** | **< 200 ms** | **173 ms** | **Target met** |

---

## 6. Interrupt and Real-Time Performance

### 6.1 Interrupt Latency (PLIC → Handler)

| Priority Level | Target | Measurement Point |
|----------------|--------|-------------------|
| **Highest (7)** | ≤ 30 cycles | PLIC claim → first handler insn |
| **Medium (3–4)** | ≤ 50 cycles | PLIC claim → first handler insn |
| **Lowest (1)** | ≤ 100 cycles | PLIC claim → first handler insn |
| **Nested (High preempts Low)** | ≤ 20 cycles additional | Preemption overhead |

### 6.2 Real-Time Determinism

| Metric | Target | Condition |
|--------|--------|-----------|
| **Jitter (Highest Priority)** | < 5 cycles | No cache, TCM code |
| **Jitter (Medium Priority)** | < 20 cycles | SRAM code, no contention |
| **Worst-Case Latency** | < 200 cycles | All sources, max nesting |
| **Timer Accuracy (CLINT)** | ±100 ppm | Crystal-derived |
| **Timer Accuracy (LPTIM)** | ±1% | Calibrated LPO |

---

## 7. Communication Stack Performance

### 7.1 Matter/Thread (Zephyr + OpenThread)

| Metric | Target | Notes |
|--------|--------|-------|
| **Commissioning Time** | < 30 s | BLE + Thread |
| **Message Latency (Local)** | < 10 ms | Thread mesh hop |
| **Message Latency (Cloud)** | < 200 ms | Via border router |
| **Throughput (TCP/TLS)** | ≥ 1 Mbps | Matter over Thread |
| **Concurrent Sessions** | ≥ 10 | Matter exchanges |
| **OTA Image Size** | ≤ 1 MB | Compressed + signed |
| **OTA Apply Time** | < 30 s | Download + verify + swap |

### 7.2 Wi-Fi/BLE (External Module)

| Metric | Target | Notes |
|--------|--------|-------|
| **Wi-Fi Connect** | < 5 s | From scan to IP |
| **BLE Advertise Interval** | 100 ms | Configurable |
| **BLE Throughput** | ≥ 100 kbps | GATT notifications |
| **Coexistence** | No deadlock | Wi-Fi + BLE + Thread |

---

## 8. Area and Frequency Scaling

### 8.1 Area vs Frequency Trade-offs (SkyWater 130nm)

| Config | Frequency | Est. Area | Est. Power (Active) | Use Case |
|--------|-----------|-----------|---------------------|----------|
| **Minimal** | 25 MHz | 7.5 mm² | 400 mW | Battery-only, sensors |
| **Balanced (Baseline)** | 50 MHz | 9.5 mm² | 931 mW | Mains-powered hub |
| **Performance** | 75 MHz | 11.5 mm² | 1.8 W | High-throughput gateway |

### 8.2 Voltage-Frequency Operating Points

| OPP | Voltage | Frequency | Power (Typ) | Use Case |
|-----|---------|-----------|-------------|----------|
| **OPP_LOW** | 0.9V | 25 MHz | 300 mW | Deep sleep exit, background |
| **OPP_NOM** | 1.0V | 50 MHz | 931 mW | Normal operation |
| **OPP_HIGH** | 1.05V | 60 MHz | 1.2 W | Burst compute (crypto) |
| **OPP_ULTRA** | 1.1V | 75 MHz | 1.8 W | Short bursts only |

*Dynamic voltage/frequency scaling (DVFS) via PMIC I²C — future phase*

---

## 9. Environmental Performance

| Parameter | Specification | Verification |
|-----------|---------------|--------------|
| **Operating Temp (Ambient)** | -40°C to +85°C | Qualification |
| **Junction Temp (Max)** | +125°C | Thermal simulation |
| **Thermal Resistance (θJA)** | ≤ 25°C/W | QFN-64, 4-layer PCB |
| **Max Power (No Heatsink)** | 2.0 W | At +85°C ambient |
| **Thermal Shutdown** | PMIC OT (150°C) | PMIC feature |

---

## 10. Quality and Reliability Performance

| Metric | Target | Method |
|--------|--------|--------|
| **MTBF (Telcordia SR-332)** | > 1,000,000 hrs | Calculation |
| **Soft Error Rate (SER)** | < 1 FIT/Mb | Analysis |
| **Latch-up Immunity** | > ±100 mA | Characterization |
| **ESD HBM** | ±2 kV | Qualification |
| **ESD CDM** | ±500 V | Qualification |
| **EMC Margin** | ≥ 6 dB | Pre-compliance scan |

---

## 11. Verification Performance Targets

### 11.1 Simulation Performance

| Simulator | Target Speed | Test Type |
|-----------|--------------|-----------|
| **Verilator** | ≥ 1 MHz equivalent | Regression, long tests |
| **Icarus Verilog** | ≥ 100 kHz equivalent | Quick checks, analog cosim |
| **SymbiYosys** | < 30 min / property | Formal proofs |

### 11.2 Coverage Targets

| Coverage Type | Target | Scope |
|---------------|--------|-------|
| **Code Coverage (Line)** | 95% | All RTL |
| **Code Coverage (Toggle)** | 90% | All signals |
| **Functional Coverage** | 100% | Defined coverpoints |
| **Assert Coverage** | 100% | All assertions proven/hit |
| **CDC Coverage** | 100% | All clock crossings proven |

---

## 12. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-11-11 | Lead | Initial release from architecture and power analysis |

---

*This PRS is derived from the System Requirements Specification (HAS-SoC-SRS-001), Power Budget Analysis, and Architecture Decisions. All targets are measurable and traceable to ARC decisions.*