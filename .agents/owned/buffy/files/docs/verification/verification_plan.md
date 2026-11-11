# Home-Automation-SoC Verification Plan
# Stage 4 Verification

## Verification Strategy

| Method | Tool | Status | Target |
|--------|------|--------|--------|
| RTL Lint | Verilator | READY | 0 errors/warnings |
| Functional Simulation | Verilator + Icarus | SCRIPTS READY | SRAM, UART, GPIO, SPI, I2C, PWM, Timers |
| Formal CDC | SymbiYosys | SBY CREATED | 10 CDC paths proven |
| Formal Assertion | SymbiYosys | PLANNED | Bus protocol, reset, FIFO |
| Coverage-driven | Verilator (future) | PLANNED | 95% line, 90% toggle |

## Testbench Architecture

```
sim/
├── sim_top/
│   ├── sim_main.cpp          # Verilator C++ testbench
│   ├── tb_has_soc.v          # Icarus Verilog testbench
│   ├── Makefile.verilator    # Verilator build
│   └── Makefile.icarus       # Icarus build
├── tb/
│   ├── tb_sram_simple.v      # Simple SRAM test (PASS)
│   ├── tb_uart.v             # UART TX/RX test
│   ├── tb_gpio.v             # GPIO test
│   ├── tb_spi.v              # SPI master test
│   ├── tb_i2c.v              # I2C master test
│   ├── tb_pwm.v              # PWM test
│   ├── tb_timer.v            # Timer/CLINT test
│   ├── tb_plic.v             # PLIC interrupt test
│   ├── tb_boot_rom.v         # Boot ROM test
│   └── tb_integration.v      # Full SoC integration test
├── waveforms/
│   └── *.vcd                 # Waveform dumps
└── formal/
    └── cdc.sby               # SymbiYosys CDC verification
```

## Test Scenarios

### 1. SRAM Interface (COMPLETE)
- Write/read full word, byte, halfword
- Back-to-back transactions
- Address boundary tests

### 2. UART (PLANNED)
- TX polling mode
- RX polling mode
- Baud rate accuracy
- FIFO overflow/underflow
- Parity/frame error detection

### 3. GPIO (PLANNED)
- Output mode toggle
- Input mode read
- Interrupt on rising/falling edge
- Alternate function muxing

### 4. SPI/QSPI (PLANNED)
- Single/dual/quad mode
- Flash read/write/erase
- Radio SPI communication
- CS timing

### 5. I2C (PLANNED)
- Master transmit/receive
- PMIC register access
- Sensor read (BME280 simulation)
- Clock stretching

### 6. PWM (PLANNED)
- Frequency/duty cycle accuracy
- Edge/center aligned
- Dead time insertion
- Synchronization

### 7. Timer/CLINT (PLANNED)
- MTIME free-running
- MTIMECMP compare interrupt
- MSIP software interrupt
- LPTIM wake from sleep

### 8. PLIC (PLANNED)
- Priority arbitration
- Preemption
- Claim/complete protocol
- Threshold filtering

### 9. Power Management (PLANNED)
- Sleep entry/exit
- Wake sources
- PMIC I2C sequencing

### 10. Boot ROM / Secure Boot (PLANNED)
- ROM signature verification
- Firmware header validation
- A/B partition selection
- Recovery mode

## Coverage Goals

| Coverage Type | Target | Measurement |
|---------------|--------|-------------|
| Line | 95% | Verilator --coverage |
| Toggle | 90% | Verilator --coverage |
| FSM | 100% | All state machines |
| Assert | 100% | All assertions hit |
| CDC | 100% | All 10 paths proven |

## Regression Suite

```bash
# Full regression
python scripts/eda/run_verilator_sim.py all
python scripts/eda/run_icarus_sim.py all
python scripts/formal/run_sby.py run

# Individual tests
python scripts/eda/run_verilator_sim.py run
python scripts/eda/run_icarus_sim.py run
python scripts/formal/run_sby.py task cdc_core_periph
```

## Blockers

1. **No g++/make** - Cannot build Verilator C++ simulation executable
2. **No Python** - Cannot run coverage analysis or cocotb
3. **Limited SystemVerilog in Icarus** - Some features not supported

## Workarounds

1. Verilator lint-only works (no C++ compilation needed)
2. Icarus Verilog runs simple testbenches (tb_sram_simple.v PASSED)
3. SymbiYosys formal verification runs on RTL directly
4. Python scripts ready for when toolchain is complete