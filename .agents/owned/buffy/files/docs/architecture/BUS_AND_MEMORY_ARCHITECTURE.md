# Bus and Memory Architecture

## 1. System Bus Architecture

### 1.1 Primary Interconnect: AXI4-Lite
- **Standard:** AMBA AXI4-Lite (subset of AXI4, no burst, fixed 32-bit data width)
- **Role:** Main CPU-to-memory and CPU-to-peripheral-bridge interconnect
- **Master:** Ibex core (via req/gnt → AXI4-Lite bridge, see ARC-011)
- **Slaves:** Boot ROM, TCM, SRAM, QSPI Flash Controller, APB Bridge
- **Evidence:** DS-01 Section 2, DS-02 Section 5 (VERIFIED)

### 1.2 Peripheral Bus: APB
- **Standard:** AMBA APB (Advanced Peripheral Bus)
- **Role:** Low-bandwidth peripheral register access
- **Bridge:** AXI4-Lite to APB bridge (LiteX `apb_bridge`, ARC-012)
- **Peripherals:** UART, I²C, SPI, GPIO, PWM, I²S, Timer/RTC, PLIC, CLINT, AES, SHA, TRNG
- **Evidence:** DS-01 Section 2, DS-02 Section 5 (VERIFIED)

### 1.3 Ibex Core Interface
- **Native Interface:** Simple request/grant (req/gnt) handshake for instruction and data ports
- **NOT APB:** Ibex does not natively speak APB (corrected in ARC-010)
- **Adapter Required:** req/gnt → AXI4-Lite bridge (LiteX `ibex_axi_bridge` or lowRISC `axi_adapter`)
- **Evidence:** DS-01 Section 1, Ibex Reference Manual (VERIFIED)

## 2. Memory Subsystem

### 2.1 On-Chip SRAM Macro
- **Size:** 128 KB
- **Data Width:** 32-bit (or 16-bit with 2-cycle access)
- **Interface:** Synchronous, single-port or dual-port
- **ECC:** Optional single-bit error correction (disabled initially for area/power)
- **Generation:** OpenRAM (SkyWater 130nm)
- **Address Range:** 0x2000_0000 – 0x2001_FFFF (ARC-019)
- **Evidence:** DS-01 Section 3, DS-05 Section 11 (VERIFIED)

### 2.2 Tightly-Coupled Memory (TCM)
- **Size:** 32 KB
- **Interface:** Direct to Ibex pipeline (zero-wait latency)
- **No Bus:** Bypasses AXI/APB interconnect entirely
- **Use Case:** Interrupt vectors, critical loops, stack
- **Address Range:** 0x0001_0000 – 0x0001_7FFF (ARC-019)
- **Evidence:** DS-01 Section 4 (VERIFIED)

### 2.3 Boot ROM
- **Size:** 16 KB
- **Content:** Secure boot code, RSA/ECDSA verification, key provisioning
- **Source:** OpenTitan-derived (lowRISC)
- **Address Range:** 0x0000_0000 – 0x0000_3FFF (ARC-013, ARC-019)
- **Execution:** First instruction fetch after POR
- **Evidence:** DS-01 Section 5, DS-04 Section 6 (DOCUMENTED)

### 2.4 QSPI Flash Controller
- **Controller:** OpenSPI QSPI controller
- **Mode:** 4-bit DDR (double data rate), memory-mapped
- **Flash Size:** 64 MB (Winbond W25Q512 or equivalent)
- **Address Range:** 0x4000_0000 – 0x43FF_FFFF (ARC-019)
- **Boot Access:** Direct read for OTA image verification
- **Evidence:** DS-01 Section 4, DS-04 Section 6 (VERIFIED)

## 3. Consolidated Memory Map (ARC-019, 32-bit)

| Region | Base Address | End Address | Size | Description |
|--------|-------------|-------------|------|-------------|
| Boot ROM | 0x0000_0000 | 0x0000_3FFF | 16 KB | Secure boot ROM |
| *Reserved* | 0x0000_4000 | 0x0000_FFFF | 48 KB | — |
| TCM | 0x0001_0000 | 0x0001_7FFF | 32 KB | Tightly-coupled memory |
| *Reserved* | 0x0001_8000 | 0x1FFF_FFFF | ~511 MB | — |
| SRAM | 0x2000_0000 | 0x2001_FFFF | 128 KB | On-chip SRAM macro |
| *Reserved* | 0x2002_0000 | 0x3FFF_FFFF | ~511 MB | — |
| QSPI Flash | 0x4000_0000 | 0x43FF_FFFF | 64 MB | External QSPI flash |
| *Reserved* | 0x4400_0000 | 0x4FFF_FFFF | ~192 MB | — |
| APB Peripherals | 0x5000_0000 | 0x500F_FFFF | 1 MB | APB peripheral space |
| *Reserved* | 0x5010_0000 | 0x7FFF_FFFF | ~767 MB | — |
| PLIC / CLINT | 0x8000_0000 | 0x8000_FFFF | 64 KB | Interrupt controllers |
| *Reserved* | 0x8001_0000 | 0xFFFF_FFFF | ~2 GB | — |

## 4. Address Map Details (ARC-020) — APB Peripheral Allocation

| Peripheral | Base Offset | Size | Registers |
|------------|-------------|------|-----------|
| UART0 | 0x5000_0000 | 4 KB | TX, RX, CTRL, STATUS, BAUD |
| I²C0 | 0x5000_1000 | 4 KB | CTRL, STATUS, DATA, ADDR |
| SPI0 | 0x5000_2000 | 4 KB | CTRL, TX, RX, CS, CLKDIV |
| GPIO | 0x5000_3000 | 4 KB | IN, OUT, OE, INT_EN, INT_STS |
| PWM | 0x5000_4000 | 4 KB | CTRL[4], PERIOD[4], DUTY[4] |
| I²S | 0x5000_5000 | 4 KB | CTRL, TX_FIFO, RX_FIFO, CLKDIV |
| Timer/RTC | 0x5000_6000 | 4 KB | CTRL, VALUE, CMP, LOAD |
| LPTIM | 0x5000_7000 | 4 KB | CTRL, VALUE, CMP, WAKE_EN |
| PLIC | 0x8000_0000 | 32 KB | PRIORITY, ENABLE, THRESHOLD, CLAIM |
| CLINT | 0x8000_8000 | 32 KB | MTIME, MTIMECMP, MSIP |
| AES | 0x5000_8000 | 4 KB | CTRL, KEY, IV, DATA_IN, DATA_OUT |
| SHA-256 | 0x5000_9000 | 4 KB | CTRL, DATA_IN, DIGEST |
| TRNG | 0x5000_A000 | 4 KB | CTRL, STATUS, DATA |
| PMIC I²C | 0x5000_B000 | 4 KB | CTRL, STATUS, DATA, ADDR |

*All offsets 4-byte aligned per LiteX convention (DS-02 Section 5)*

## 5. Bus Bridge Specifications (ARC-011, ARC-012)

### 5.1 Ibex req/gnt → AXI4-Lite Bridge
- **IP Candidate:** LiteX `ibex_axi_bridge` or lowRISC `axi_adapter`
- **Function:** Translate Ibex instruction/data req/gnt to AXI4-Lite master transactions
- **Outstanding Transactions:** 1 (Ibex does not support multiple outstanding)
- **Latency:** +1 cycle for address phase, +1 for data phase
- **Status:** PROPOSED — concrete IP selection pending

### 5.2 AXI4-Lite → APB Bridge
- **IP:** LiteX `apb_bridge` (VERIFIED)
- **Function:** Convert AXI4-Lite read/write to APB transactions
- **Latency:** 2-3 cycles (AXI → APB setup/access/hold)
- **Address Decoding:** Upper bits select peripheral; lower bits register offset

## 6. Clock Domain Crossing (CDC) in Bus Fabric

| Crossing | From Domain | To Domain | Mechanism |
|----------|-------------|-----------|-----------|
| CPU → SRAM | Core (50 MHz) | Core (50 MHz) | Same domain — no CDC |
| CPU → QSPI | Core (50 MHz) | Core (50 MHz) | Same domain — no CDC |
| CPU → APB Bridge | Core (50 MHz) | Peripheral (25 MHz) | Async FIFO in bridge |
| APB Peripherals | Peripheral (25 MHz) | Core (50 MHz) | Register synchronizers |
| AON → Core | AON (32 kHz) | Core (50 MHz) | Multi-flop synchronizers |

*Formal CDC verification required (ARC-036, BLOCKED)*

## 7. Outstanding Decisions

| Item | Status | Notes |
|------|--------|-------|
| Exact Ibex bridge IP selection | PROPOSED | LiteX vs lowRISC vs custom |
| SRAM ECC enable/disable | PROPOSED | Area/power vs reliability trade-off |
| QSPI controller XIP mode details | PROPOSED | Memory-mapped vs register access |
| APB wait-state configuration | PROPOSED | Peripheral-dependent |
| Formal CDC property definitions | BLOCKED | Requires SymbiYosys integration |

---

*All decisions traceable to ARC IDs in Phase 0 Closure Matrix. Evidence tags: VERIFIED, DOCUMENTED, PROPOSED.*