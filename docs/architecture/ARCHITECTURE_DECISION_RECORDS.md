# Architecture Decision Records (ADRs) — Complete 72-Entry Register

**Status Legend:** PROPOSED, PENDING APPROVAL, APPROVED, BLOCKED, DEFERRED  
**Evidence Tags:** VERIFIED (direct source), DOCUMENTED (public docs), ESTIMATED (industry practice), ASSUMED (reasonable), UNKNOWN (no source)

---

## Core & ISA (ARC-001 – ARC-010)

| ARC | Decision | Status | Evidence |
|-----|----------|--------|----------|
| **ARC-001** | Processor: Ibex (lowRISC) RV32IMC | PENDING APPROVAL | DS-01 Sec.1, DS-02 Sec.1 (VERIFIED) |
| **ARC-002** | Bus: AXI4-Lite (CPU↔Mem) + APB (Peripherals) | PROPOSED | DS-01 Sec.2 (VERIFIED), DS-02 Sec.3 (ASSUMED) |
| **ARC-003** | Memory Map: 32-bit consistent (ARC-019) | PROPOSED | DS-01 Sec.3, DS-05 Sec.11 (VERIFIED) |
| **ARC-004** | Boot ROM: 16 KB @ 0x0000_0000, OpenTitan-derived | PROPOSED | DS-01 Sec.5, DS-04 Sec.6 (DOCUMENTED) |
| **ARC-005** | Peripheral Set: UART, I²C, SPI/QSPI, GPIO, PWM, I²S, Timer, PLIC, CLINT, AES, SHA, TRNG | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-006** | Clocking: 50 MHz core (Si5351), 25 MHz periph, 32 kHz LPO (AON) | PROPOSED | DS-02 Sec.3, PLL Decision Report (VERIFIED) |
| **ARC-007** | Reset: Multi-stage POR → Core → Peripheral (active-low) | PROPOSED | DS-02 Sec.4 (DOCUMENTED) |
| **ARC-008** | Power Domains: AON (3.3V), Core (1.0V), IO (1.8V), PERIPH (3.3V) | PROPOSED | DS-05 Sec.3, DS-06 Sec.2 (VERIFIED) |
| **ARC-009** | PMIC: TI TPS65217 (3 Buck + 2 LDO, I²C config) | PROPOSED | DS-06 Sec.2 (VERIFIED) |
| **ARC-010** | Ibex Interface: Native req/gnt (NOT APB) — corrected | PROPOSED | DS-01 Sec.1, Ibex Ref Manual (VERIFIED) |

---

## Bus Bridges & Interconnect (ARC-011 – ARC-020)

| ARC | Decision | Status | Evidence |
|-----|----------|--------|----------|
| **ARC-011** | Ibex→AXI4-Lite Bridge: LiteX `ibex_axi_bridge` (req/gnt → AXI-Lite) | PROPOSED | DS-02 Sec.5, DS-01 Sec.5 (DOCUMENTED) |
| **ARC-012** | AXI4-Lite→APB Bridge: LiteX `apb_bridge` | PROPOSED | DS-01 Sec.2, DS-02 Sec.5 (VERIFIED) |
| **ARC-013** | Boot ROM/APB Overlap Resolved: ROM @ 0x0000_0000–0x0000_3FFF, APB @ 0x5000_0000 | PROPOSED | DS-01 Sec.5, DS-02 Sec.4 (VERIFIED) |
| **ARC-014** | Interrupt Controller: PLIC (external) + CLINT (core-local) | PROPOSED | DS-01 Sec.5 (VERIFIED) |
| **ARC-015** | Timer/Watchdog: CLINT MTIME/MTIMECMP + LPTIM (AON) | PROPOSED | DS-01 Sec.5 (VERIFIED) |
| **ARC-016** | Crypto Accelerators: AES-256, SHA-256 on APB | PROPOSED | DS-01 Sec.5 (DOCUMENTED) |
| **ARC-017** | TRNG: Ring-oscillator based, FIPS 140-2 health tests | PROPOSED | DS-01 Sec.5 (DOCUMENTED) |
| **ARC-018** | Boot Flow: ROM → Verify QSPI (ECDSA-P256) → Jump to SRAM/TCM | PROPOSED | DS-04 Sec.6 (DOCUMENTED) |
| **ARC-019** | Memory Map Final (32-bit): See table below | PROPOSED | DS-01 Sec.3, DS-05 Sec.11 (VERIFIED) |
| **ARC-020** | APB Peripheral Address Allocation: 1 MB @ 0x5000_0000, 4-byte aligned | PROPOSED | DS-02 Sec.5 (DOCUMENTED) |

**Memory Map (ARC-019):**
```
0x0000_0000 – 0x0000_3FFF : Boot ROM (16 KB)
0x0001_0000 – 0x0001_7FFF : TCM (32 KB)
0x2000_0000 – 0x2001_FFFF : SRAM (128 KB)
0x4000_0000 – 0x43FF_FFFF : QSPI Flash (64 MB)
0x5000_0000 – 0x500F_FFFF : APB Peripherals (1 MB)
0x8000_0000 – 0x8000_FFFF : PLIC / CLINT (64 KB)
```

---

## External Interface & Package (ARC-021 – ARC-034)

| ARC | Decision | Status | Evidence |
|-----|----------|--------|----------|
| **ARC-021** | External RF: Wi-Fi/BLE/Zigbee via UART1 + SPI_CS1 + RF_CTRL GPIOs | PROPOSED | DS-06 Sec.1 (DOCUMENTED) |
| **ARC-022** | Package: QFN-64 (9×9mm, 0.5mm pitch, EP=GND) | PROPOSED | DS-01 Sec.7 (VERIFIED) |
| **ARC-023** | Pin Assignment: 56 usable I/O mapped in `constraints/pin_assignment_qfn64.csv` | PROPOSED | DS-06 Sec.2, Pin CSV (VERIFIED) |
| **ARC-024** | Debug: JTAG (TCK/TMS/TDI/TDO/TRST) + optional SWD (shared) | PROPOSED | DS-06 Sec.3 (VERIFIED) |
| **ARC-025** | Key Provisioning: TRNG→OTP (DUK) → KDF → ECDSA/AES keys | PROPOSED | DS-04 Sec.6 (DOCUMENTED) |
| **ARC-026** | OTA Security: AES-256-GCM decrypt + ECDSA-P256 verify + rollback counter | PROPOSED | DS-04 Sec.6 (DOCUMENTED) |
| **ARC-027** | Power-Loss Detect: PMIC ALERT pin → backup regulator (10 mA AON) | PROPOSED | DS-06 Sec.2 (DOCUMENTED) |
| **ARC-028** | PMIC Regulator Assignment: Buck1=Core 1.0V, Buck2=IO 1.8V, LDO1=AON 3.3V, LDO2=PERIPH 3.3V | PENDING APPROVAL | DS-06 Sec.2 (VERIFIED) |
| **ARC-029** | Power-Loss Calc: Worst-case I×V/eff + 10% margin | PROPOSED | DS-06 Sec.2 (ESTIMATED) |
| **ARC-030** | FPGA vs ASIC Power Budget Separate: FPGA 3.3V/500mA, ASIC Core 1.0V/350mA | PROPOSED | DS-06 Sec.1 (ESTIMATED) |
| **ARC-031** | Reset Polarity: Active-low `reset_n` distributed via POR tree | PROPOSED | DS-02 Sec.4 (DOCUMENTED) |
| **ARC-032** | JTAG/SWD Pinout: 6-pin header (TCK,TMS,TDI,TDO,TRST,UART_DBG) | PROPOSED | DS-06 Sec.3 (VERIFIED) |
| **ARC-033** | Security Dependency Chain: Boot ROM → Crypto → OTP Key Provisioning | PROPOSED | DS-04 Sec.6 (DOCUMENTED) |
| **ARC-034** | ARC Count Reconciled: 72 total entries | PROPOSED | This Register |

---

## Blockers & Cross-Cutting (ARC-035 – ARC-042)

| ARC | Decision | Status | Evidence |
|-----|----------|--------|----------|
| **ARC-035** | Architecture Freeze Blocker: Pending ARC-001 (Ibex) approval | **BLOCKED** | ADR-001 |
| **ARC-036** | Formal CDC Verification Required: SymbiYosys properties for 3 clock domains | **BLOCKED** | ADR-010, CDC Plan (this session) |
| **ARC-037** | ASIC Sign-off Blocker: DFT/ATPG + IR-Drop require commercial tools | **BLOCKED** | ADR-012, DFT Strategy (this session) |
| **ARC-038** | SRAM ECC: Optional SECDED (disabled baseline, configurable) | PROPOSED | DS-05 Sec.11 (ESTIMATED) |
| **ARC-039** | QSPI Controller: OpenSPI, 4-bit DDR, XIP mode @ 0x4000_0000 | PROPOSED | DS-01 Sec.4, DS-04 Sec.6 (VERIFIED) |
| **ARC-040** | Clock Gating: Per-peripheral enable via Power-Domain Controller | PROPOSED | DS-02 Sec.2 (VERIFIED) |
| **ARC-041** | PLL Strategy: External Si5351 (resolves UNKNOWN) | **APPROVED** | PLL Decision Report (VERIFIED) |
| **ARC-042** | Pin Budget: QFN-64 56 I/O sufficient with multiplexing | PROPOSED | Pin CSV, EC04 (VERIFIED) |

---

## Memory Subsystem Detail (ARC-043 – ARC-050)

| ARC | Decision | Status | Evidence |
|-----|----------|--------|----------|
| **ARC-043** | SRAM Macro: OpenRAM SkyWater 130nm, 128 KB, 32-bit, 1-cycle | PROPOSED | DS-05 Sec.11 (VERIFIED) |
| **ARC-044** | TCM: Direct core connect, zero-wait, 32 KB, no ECC | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-045** | Boot ROM: 16 KB, immutable, OpenTitan-derived, RV32IMC | PROPOSED | DS-01 Sec.5 (DOCUMENTED) |
| **ARC-046** | QSPI Flash: 64 MB (Winbond W25Q512), Quad DDR, XIP | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-047** | OTP/eFuse: SkyWater 130nm macro, 256-bit DUK + config | PROPOSED | DS-05 Sec.11 (ESTIMATED) |
| **ARC-048** | Memory Protection: Ibex PMP (16 regions, TOR/NAPOT, M/U modes) | PROPOSED | ARC-001, RISC-V Priv Spec (VERIFIED) |
| **ARC-049** | Address Decoding: AXI4-Lite decoder with fixed map (ARC-019) | PROPOSED | DS-02 Sec.5 (DOCUMENTED) |
| **ARC-050** | Endianness: Little-endian (RISC-V standard) | PROPOSED | RISC-V ISA (VERIFIED) |

---

## Peripheral Implementation Detail (ARC-051 – ARC-058)

| ARC | Decision | Status | Evidence |
|-----|----------|--------|----------|
| **ARC-051** | UART: 16550-compatible, APB, 16-byte FIFO, up to 3 Mbps | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-052** | I²C: Master-only, Fast+ (1 Mbps), 7-bit addr, clock stretch | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-053** | SPI/QSPI: Master, Mode 0/3, 50 MHz DDR (Flash), 25 MHz (Radio) | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-054** | GPIO: 16 pins, 3.3V domain, 4/8/12 mA drive, pull up/down, interrupt | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-055** | PWM: 4 channels, 16-bit, 1 Hz–1 MHz, edge/center align, dead-time | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-056** | I²S: Master/Slave, 8–48 kHz, 16/24/32-bit, Philips/LJ/RJ/TDM | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-057** | Timers: 2× 32-bit APB (25 MHz) + 1× LPTIM (AON, 32 kHz) | PROPOSED | DS-01 Sec.4 (VERIFIED) |
| **ARC-058** | Pinmux: APB-controlled, per-pin alternate functions (UART1, I2C1, SPI1, PWM4-7, etc.) | PROPOSED | Pin CSV, Peripheral Arch (DOCUMENTED) |

---

## Security Implementation Detail (ARC-059 – ARC-064)

| ARC | Decision | Status | Evidence |
|-----|----------|--------|----------|
| **ARC-059** | AES-256: ECB/CBC/CTR/GCM, APB, ≥10 MB/s, side-channel masking | PROPOSED | DS-01 Sec.5 (DOCUMENTED) |
| **ARC-060** | SHA-256: Streaming, context save/restore, APB, ≥15 MB/s | PROPOSED | DS-01 Sec.5 (DOCUMENTED) |
| **ARC-061** | TRNG: Ring oscillator, FIPS 140-2 continuous/startup health tests | PROPOSED | DS-01 Sec.5 (DOCUMENTED) |
| **ARC-062** | Secure Boot: ECDSA-P256 verify, SHA-256 measure, <100 ms | PROPOSED | DS-04 Sec.6, Boot Arch (DOCUMENTED) |
| **ARC-063** | OTA: A/B partitions (32 MB each), signed+encrypted, rollback counter | PROPOSED | DS-04 Sec.6, Boot Arch (DOCUMENTED) |
| **ARC-064** | Debug Lock: OTP fuse disables JTAG after provisioning | PROPOSED | DS-06 Sec.3, Sec Arch (DOCUMENTED) |

---

## Previously Missing Entries (ARC-065 – ARC-072) — NOW EXPANDED

| ARC | Decision | Status | Evidence |
|-----|----------|--------|----------|
| **ARC-065** | **Formal CDC Properties**: Define async FIFO depth=2, multi-flop sync (3 stages), handshake protocols for Core↔Periph (50↔25 MHz), Core↔AON (50↔32 kHz), Periph↔AON (25↔32 kHz). Verify with SymbiYosys. | **BLOCKED** (pending CDC plan) | ADR-010, CDC Plan (this session) |
| **ARC-066** | **DFT/ATPG Strategy**: No open-source ATPG. Procure Synopsys DFTMAX Ultra or Cadence Modus for scan insertion (target >95% coverage), MBIST for SRAM/TCM/ROM, ATPG pattern generation. Budget: $50k–100k. Alternative: Outsource to foundry service. | **BLOCKED** (pending budget/procurement) | ADR-012, ds05 report, DFT Strategy (this session) |
| **ARC-067** | **IR-Drop/Power Grid Sign-off**: Requires commercial IR-drop tool (Synopsys PrimeTime-PX, Cadence Voltus). Define power grid: 4-layer mesh (M4/M5 horizontal, M3/M6 vertical), strap width ≥2µm, decap cells 1 per 100µm². Target <10% VDD droop at max current. | **BLOCKED** (pending tool access) | ADR-012, ds05 report, Power Budget (this session) |
| **ARC-068** | **PLL Jitter Spec**: Si5351 CLK0 <50 ps RMS (12 kHz–20 MHz), satisfies core <100 ps requirement. Spread spectrum ±0.5% for EMI. | PROPOSED | PLL Decision, Si5351 DS (VERIFIED) |
| **ARC-069** | **LPO Calibration**: Periodic calibration of 32 kHz RC vs 25 MHz crystal (via Timer0) to ±1%. Calibration interval: 1 hour active, 24 hours deep sleep. | PROPOSED | Clock Arch, DS-02 Sec.3 (ASSUMED) |
| **ARC-070** | **Boot ROM Size Margin**: 16 KB provides ~8 KB headroom for future crypto algos. Monitor usage; expand to 32 KB only if needed (TCM can absorb). | PROPOSED | Boot Arch, ARC-004 (ESTIMATED) |
| **ARC-071** | **Reset Synchronization**: All domain resets synchronized to local clock (3-flop). POR asynchronous assert, synchronous deassert per domain. | PROPOSED | Reset Arch, ARC-007 (DOCUMENTED) |
| **ARC-072** | **Analog IP Summary**: No on-chip PLL/ADC/DAC. External: 12 MHz XTAL, Si5351, PMIC. SoC is all-digital + LPO. | PROPOSED | PLL Decision, Clock Arch (VERIFIED) |

---

## Open Questions — UPDATED STATUS

| # | Question | Current Status |
|---|----------|----------------|
| 1 | **Clock Source PLL Details** | **RESOLVED** — Si5351 selected (ARC-041, ARC-068) |
| 2 | **DFT/ATPG Strategy** | **BLOCKED** — Commercial tool required (ARC-066) |
| 3 | **IR-Drop & Power Grid Sign-off** | **BLOCKED** — Commercial tool required (ARC-067) |
| 4 | **External RF Module Isolation** | **PENDING** — PCB layout rules needed (ARC-021) |
| 5 | **Memory Map Overlaps** | **RESOLVED** — Consistent 32-bit map defined (ARC-019) |
| 6 | **Formal CDC Verification** | **BLOCKED** — SymbiYosys properties needed (ARC-036, ARC-065) |
| 7 | **ASIC Sign-off Commercial Tools** | **BLOCKED** — Budget approval needed (ARC-037) |

---

## Traceability: ARC → Requirements (SRS)

| ARC Range | SRS Sections |
|-----------|--------------|
| ARC-001–010 | FR-PROC, FR-BUS, FR-MEM, FR-CLK, FR-RST |
| ARC-011–020 | FR-BUS, FR-MEM, FR-PER, FR-SEC |
| ARC-021–034 | IF-PIN, IF-ELE, IF-COM, FR-DBG, FR-EXT |
| ARC-035–042 | NFR-QUA, ARC-035/036/037 blockers |
| ARC-043–050 | FR-MEM, NFR-AREA |
| ARC-051–058 | FR-PER, IF-COM |
| ARC-059–064 | FR-SEC, NFR-PERF (crypto) |
| ARC-065–072 | NFR-QUA, ARC-036/037 resolution |

---

*All 72 ARC entries now explicitly documented. Blockers (ARC-035, 036, 037, 065, 066, 067) require external resolution before Gate 1 (Architecture Freeze).*