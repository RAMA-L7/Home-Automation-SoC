# ASIC Stage 1 — Interface and Address-Map Closure

Date: 2026-11-15
Status: **READY FOR APPROVAL** (TD-016, TD-017)
Machine-readable: `architecture/interface_inventory.csv` (50 interfaces)
Sources of truth: `rtl/rtl_top/has_addr_map.sv`, `rtl/rtl_top/has_soc.sv`, peripheral RTL headers.

---

## 1. Authoritative address map (recommended)

The RTL map is recommended because the firmware, linker script and all tests already use it. The documents must be corrected, not the RTL.

| Region | Base | End | Size | Decoded? |
|---|---|---|---:|---|
| Boot ROM | `0x0000_0000` | `0x0000_3FFF` | 16 KB | yes (array is 64 KB — fix) |
| TCM | `0x0001_0000` | `0x0001_7FFF` | 32 KB | yes |
| SRAM | `0x2000_0000` | `0x2001_FFFF` | 128 KB | yes (array is 256 KB — fix) |
| QSPI flash | `0x4000_0000` | `0x43FF_FFFF` | 64 MB window | AXI slave; controller addresses 16 MB (alias) |
| APB | `0x5000_0000` | `0x500F_FFFF` | 1 MB window | 36 KB decoded (9 slots) |
| CLINT | `0x8000_0000` | `0x8000_0FFF` | 4 KB | yes |
| PLIC | `0x8000_1000` | `0x8000_1FFF` | 4 KB | yes |
| Reserved INTC | `0x8000_2000` | `0x8000_FFFF` | 56 KB | no |

Unmapped AXI accesses return a decode error (`SEL_INVALID`); unmapped APB slots return PSLVERR.

---

## 2. APB peripheral map (RTL truth)

| Slot | Peripheral | Base | Size | Module | IRQ (PLIC ID) |
|---:|---|---|---:|---|---:|
| 0 | GPIO | `0x5000_0000` | 4 KB | `gpio` | 4 |
| 1 | UART0 | `0x5000_1000` | 4 KB | `uart` | 1 |
| 2 | I2C0 | `0x5000_2000` | 4 KB | `i2c_ctrl` | 3 |
| 3 | SPI0 | `0x5000_3000` | 4 KB | `spi_ctrl` | 2 |
| 4 | PWM | `0x5000_4000` | 4 KB | `pwm` | 5 |
| 5 | Timer | `0x5000_5000` | 4 KB | `timer` | 6 |
| 6 | Watchdog | `0x5000_6000` | 4 KB | `watchdog` | 7 |
| 7 | I2S | `0x5000_7000` | 4 KB | `i2s` | 8 |
| 8 | Power manager | `0x5000_8000` | 4 KB | `power_mgr_regs` | none |

**Documentation mismatch:** the SRS/ADR/interface docs list UART0 at slot 0, I2C at 1, SPI at 2, GPIO at 3, I2S at 5, Timer at 6, LPTIM at 7, AES at 8. That ordering is not implemented. Firmware uses the RTL order.

---

## 3. Register map (implemented)

All offsets are byte offsets within the 4 KB slot. Reset values are as implemented; “—” means read-only/no reset state.

### GPIO `0x5000_0000`

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 | DATA_OUT | RW | 0x0000 |
| 0x04 | DATA_IN | RO | pin state |
| 0x08 | OE | RW | 0x0000 |
| 0x0C | INT_EN | RW | 0x0000 |
| 0x10 | INT_RISE | RW | 0x0000 |
| 0x14 | INT_FALL | RW | 0x0000 |
| 0x18 | INT_PEND | RW1C | 0x0000 |

### UART0 `0x5000_1000` (16550 subset, no FIFO)

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 | THR/RBR (DLL when DLAB=1) | RW/RO | 0 / divisor 434 |
| 0x04 | IER (DLM when DLAB=1) | RW | 0 |
| 0x08 | FCR | WO | reads 0x01 |
| 0x0C | LCR | RW | 0 |
| 0x10 | MCR | RW | 0 (ignored) |
| 0x14 | LSR | RO | 0x60 (THRE/TEMT) |
| 0x18 | MSR | RO | 0 |
| 0x1C | SPR | RW | 0 |

### I2C0 `0x5000_2000` (single-byte master)

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 | CTRL (bit0 enable) | RW | 0 |
| 0x04 | ADDR (7-bit) | RW | 0 |
| 0x08 | DATA | RW | 0 |
| 0x0C | CMD (start/stop/read/write) | WO | — |
| 0x10 | STATUS (busy/ack_error/done) | RO | 0 |
| 0x14 | CLKDIV | RW | 32 |

### SPI0 `0x5000_3000` (mode 0, 8-bit, one CS)

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 | CTRL (enable/CS hold/loopback) | RW | 0 |
| 0x04 | DATA | RW | 0 |
| 0x08 | CMD (start) | WO | — |
| 0x0C | STATUS (busy/done) | RO | 0 |
| 0x10 | CLKDIV | RW | 8 |

### PWM `0x5000_4000`

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 + 8c | PERIOD[c] | RW | 0 |
| 0x04 + 8c | DUTY[c] | RW | 0 |
| 0x20 | CTRL (enable per channel) | RW | 0 |
| 0x24 | STATUS (running) | RO | 0 |

### Timer `0x5000_5000`

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 | COUNT | RO | 0 |
| 0x04 | COMPARE | RW | 0 |
| 0x08 | CTRL (enable, irq enable) | RW | 0 |
| 0x0C | STATUS (match, RW1C) | RW1C | 0 |

### Watchdog `0x5000_6000` (clocked by ungated `clk`)

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 | LOAD (pet) | RW | 0 |
| 0x04 | CTRL (enable, reset enable) | RW | 0 |
| 0x08 | STATUS (expired) | RO | 0 |
| 0x0C | KEY (0x5A5A_0001 locks) | WO | — |

### I2S `0x5000_7000` (TX, 16-bit)

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 | CTRL (enable) | RW | 0 |
| 0x04 | DATA | WO | 0 |
| 0x08 | STATUS (tx_ready) | RO | 0 |
| 0x0C | CLKDIV | RW | 8 |

### Power manager `0x5000_8000`

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x00 | PM_CTRL (sleep_request) | RW | 0 |
| 0x04 | PM_STATUS (in_sleep) | RO | 0 |
| 0x08 | PM_WAKE_EN | RW | 0 |

### CLINT `0x8000_0000` (non-standard offsets)

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x000 | MSIP | RW | 0 |
| 0x3F8 | MTIMECMP low | RW | 0xFFFF_FFFF |
| 0x3FC | MTIMECMP high | RW | 0xFFFF_FFFF |
| 0x7F8 | MTIME low | RO | 0 |
| 0x7FC | MTIME high | RO | 0 |

### PLIC `0x8000_1000` (8 sources, one context)

| Offset | Name | Access | Reset |
|---:|---|---|---|
| 0x004 + 4(id−1) | priority[id] | RW | 0 |
| 0x100 | pending | RO | 0 |
| 0x200 | enable | RW | 0 |
| 0x204 | threshold | RW | 0 |
| 0x208 | claim/complete | RW | 0 |

---

## 4. Interrupt map

| PLIC ID | Source | RTL signal |
|---:|---|---|
| 1 | UART0 | `uart_irq` |
| 2 | SPI0 | `spi_irq` |
| 3 | I2C0 | `i2c_irq` |
| 4 | GPIO | `gpio_irq` |
| 5 | PWM | `pwm_irq` |
| 6 | Timer | `timer_irq` |
| 7 | Watchdog | `wdog_irq` |
| 8 | I2S | `i2s_irq` |

- PLIC IRQ output → core external interrupt.
- CLINT → core machine timer and software interrupts.
- Top-level `ext_irq[31:0]` is **not connected** to the PLIC; it is tied to an unused XOR. The 32 external interrupt pad signals in the RTL are dead.

---

## 5. Bus interface specification

| Property | AXI4-Lite fabric | APB bridge |
|---|---|---|
| Data width | 32 bit | 32 bit |
| Address width | 32 bit | 32 bit (`paddr[15:12]` slot select) |
| Masters | 1 (core adapter) | 1 (AXI slave 4) |
| Slaves | 6 (ROM, TCM, SRAM, QSPI, APB, INTC) | 9 slots |
| Bursts | none (Lite) | n/a |
| Outstanding | 1 | 1 |
| Response | OKAY/SLVERR via `bresp/rresp` | PSLVERR for unmapped/partial write |
| Byte strobes | `wstrb` honored by SRAM; APB partial writes rejected | `pstrb` forwarded but unused by peripherals |
| Reset | `reset_n`/`rst_sys_n` | same |

**QSPI slave:** read-only engine, single-line 0x03, 24-bit address, 32-bit data; writes SLVERR.

**INTC slave:** `addr[12]` selects CLINT (0) or PLIC (1); both are 4 KB windows.

---

## 6. Pin interface and budget

### 6.1 Current RTL pad signals: 81

| Group | Signals | Pins |
|---|---|---:|
| Clock/reset | `clk`, `reset_n` | 2 |
| JTAG | `jtag_tck/tms/tdi/tdo/trst_n` | 5 |
| External IRQ | `ext_irq[31:0]` | 32 |
| UART0 | `uart_tx/rx` | 2 |
| SPI0 | `spi_sck/mosi/miso/cs_n` | 4 |
| I2C0 | `i2c_scl/sda` | 2 |
| GPIO | `gpio[15:0]` | 16 |
| PWM | `pwm_out[3:0]` | 4 |
| I2S | `i2s_bclk/lrclk/dout/din` | 4 |
| QSPI | `qspi_sck/cs_n/io[3:0]` | 6 |
| Watchdog | `wdog_reset_n_out` | 1 |
| Power | `core_clk_en_o`, `wake_req`, `wake_ack` | 3 |
| **Total** | | **81** |

### 6.2 Recommended package plan (54 of 56 usable I/O)

| Group | Pins | Change |
|---|---:|---|
| Clock/reset | 2 | keep |
| JTAG | 5 | keep |
| UART0 | 2 | keep |
| UART1 | 2 | add (required by FR-PER-001) |
| I2C0 | 2 | keep |
| SPI0 | 4 | keep (CS0 only) |
| QSPI | 6 | keep |
| GPIO | 16 | keep; 8 pins double as PLIC IRQ inputs |
| PWM | 4 | keep |
| I2S | 4 | keep |
| Watchdog out | 1 | keep |
| BOOT_MODE | 2 | add |
| PMIC alert/IRQ | 2 | add |
| RF_CTRL | 2 | add |
| **Total** | **54** | 2 spare |

Remove from the package: `ext_irq[31:0]` (dead), `core_clk_en_o`, `wake_req`, `wake_ack` (internal handshakes; expose only if test requires). This is the only way the RTL fits QFN-64 without a pinmux.

### 6.3 Voltage reality

sky130hd is a **1.8 V** digital process. The SRS requires 3.3 V-tolerant GPIO and 1.0 V core. There are no 3.3 V-tolerant pads in the open PDK. The board must provide level shifters, or the pin specification must change. Do not claim 3.3 V tolerance in the datasheet until a pad library is selected.

---

## 7. Clock-domain ownership

| Domain | Blocks | Current | Recommended |
|---|---|---|---|
| `clk_core` 50 MHz | core, AXI, ROM/TCM/SRAM, QSPI, JTAG logic | yes | yes |
| `clk_periph` 25 MHz | APB bridge slave side, all APB peripherals | **no** (50 MHz gated) | yes (generated /2) |
| `clk_aon` 32.768 kHz | LPTIM, wake, PMU sticky state, reset stretcher | **no** | yes (external) |
| `jtag_tck` | TAP shift logic | yes | yes |

Watchdog currently runs on ungated `clk` (core domain), not AON. Under the recommendation it moves to AON if it must reset the SoC during deep sleep.

---

## 8. Findings and actions

| Finding | Action | Decision |
|---|---|---|
| Docs and RTL APB order differ | Correct docs; keep RTL/firmware | TD-016 |
| PLIC/CLINT bases differ from docs | Correct docs; keep 4 KB/8 KB | TD-016 |
| CLINT MTIME non-standard | Document or move to 0xBFF8 in Stage 2 | TD-016 |
| 32-bit dead `ext_irq` | Remove or mux 8 IRQs onto GPIO | TD-016 |
| 81 pad signals vs 56 I/O | Adopt 54-pin package plan | TD-016 |
| QSPI window aliases 16 MB | Fix address width or reduce window | TD-017 |
| No pinmux | Implement or descope | TD-016/017 |
| No 3.3 V pads | Board level shifters or pad library change | TD-005/017 |
| APB partial writes rejected | Document; peripherals ignore pstrb | TD-016 |

**Approval required:** TD-016 pin/interface baseline and TD-017 requirements baseline.
**Acceptance:** one map, one register table, one interrupt table, one pin table, all matching RTL or approved changes.
