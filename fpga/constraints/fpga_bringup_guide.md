# Home-Automation-SoC — FPGA Bring-Up Guide
# Stage 5 FPGA
# Target: Digilent Nexys A7-100T (Artix-7 XC7A100TCSG324-1)

## Prerequisites
- Xilinx Vivado (WebPACK edition is free) — NOT installed in this environment
- OpenOCD (available at D:\tools\oss-cad-suite\bin\openocd.exe)
- Digilent JTAG drivers

## Build Flow

### 1. Create Vivado Project
- Create new Vivado project targeting xc7a100tcsg324-1
- Add all RTL files from D:\Home-Automation-SoC\rtl\rtl_top\ and rtl_peripherals\
- Add constraint file: fpga\constraints\nexys_a7.xdc
- Set top module: has_soc

### 2. Synthesize and Implement
- Run Synthesis
- Run Implementation
- Generate Bitstream

### 3. Program FPGA
- Open Hardware Manager
- Connect to Nexys A7 JTAG
- Program device with generated bitstream

### 4. Verify via OpenOCD
```
set PATH=D:\tools\oss-cad-suite\bin;%PATH%
openocd -f fpga\constraints\openocd.cfg
```

In another terminal:
```
telnet localhost 4444
> reset init
> halt
> mdw 0x20000000  (read SRAM)
```

## Status: BLOCKED
- No Xilinx Vivado installed in this environment
- No FPGA hardware confirmed present
- RTL is Verilator-lint clean (0 errors) and ready for synthesis

## Next Steps (when Vivado + hardware available)
1. Synthesize with Vivado to confirm ASIC/FPGA compatibility
2. Run timing analysis (50 MHz target)
3. Load firmware via OpenOCD JTAG
4. Verify SRAM read/write over JTAG
5. Verify UART console output
