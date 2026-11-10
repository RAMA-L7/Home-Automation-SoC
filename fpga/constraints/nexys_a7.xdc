#------------------------------------------------------------------------------
# Home-Automation-SoC — FPGA Constraints (Xilinx XDC)
# Target: Digilent Nexys A7-100T (Artix-7 XC7A100TCSG324-1)
# Stage 5 FPGA
#------------------------------------------------------------------------------

# Clock: 100 MHz onboard oscillator
create_clock -period 10.000 -name sys_clk_pin [get_ports clk]
set_input_jitter 0.3 [get_clocks sys_clk_pin]

# Clock pin (Nexys A7: W5 = 100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset: push button CPU_RESET (C17)
set_property PACKAGE_PIN C17 [get_ports reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]

#------------------------------------------------------------------------------
# UART (USB-UART on Nexys A7: TX = D1, RX = E2)
#------------------------------------------------------------------------------
set_property PACKAGE_PIN D1  [get_ports uart_tx]
set_property PACKAGE_PIN E2  [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

#------------------------------------------------------------------------------
# SPI (Jmod header or header pins)
#------------------------------------------------------------------------------
set_property PACKAGE_PIN H1  [get_ports spi_sck]
set_property PACKAGE_PIN G1  [get_ports spi_mosi]
set_property PACKAGE_PIN G3  [get_ports spi_miso]
set_property PACKAGE_PIN H2  [get_ports spi_cs_n]
set_property IOSTANDARD LVCMOS33 [get_ports spi_sck]
set_property IOSTANDARD LVCMOS33 [get_ports spi_mosi]
set_property IOSTANDARD LVCMOS33 [get_ports spi_miso]
set_property IOSTANDARD LVCMOS33 [get_ports spi_cs_n]

#------------------------------------------------------------------------------
# I2C (header pins)
#------------------------------------------------------------------------------
set_property PACKAGE_PIN H3  [get_ports i2c_scl]
set_property PACKAGE_PIN H4  [get_ports i2c_sda]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_scl]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_sda]

#------------------------------------------------------------------------------
# GPIO (16 bits on switches/LEDs)
#------------------------------------------------------------------------------
set_property PACKAGE_PIN T1  [get_ports {gpio[0]}]
set_property PACKAGE_PIN T2  [get_ports {gpio[1]}]
set_property PACKAGE_PIN R1  [get_ports {gpio[2]}]
set_property PACKAGE_PIN R2  [get_ports {gpio[3]}]
set_property PACKAGE_PIN P1  [get_ports {gpio[4]}]
set_property PACKAGE_PIN P2  [get_ports {gpio[5]}]
set_property PACKAGE_PIN N1  [get_ports {gpio[6]}]
set_property PACKAGE_PIN N2  [get_ports {gpio[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[*]}]

#------------------------------------------------------------------------------
# PWM (4 channels)
#------------------------------------------------------------------------------
set_property PACKAGE_PIN V6  [get_ports {pwm_out[0]}]
set_property PACKAGE_PIN V7  [get_ports {pwm_out[1]}]
set_property PACKAGE_PIN V8  [get_ports {pwm_out[2]}]
set_property PACKAGE_PIN W7  [get_ports {pwm_out[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out[*]}]

#------------------------------------------------------------------------------
# QSPI flash (onboard QSPI flash: U1-U5 etc.)
#------------------------------------------------------------------------------
set_property PACKAGE_PIN U1  [get_ports qspi_sck]
set_property PACKAGE_PIN U2  [get_ports qspi_cs_n]
set_property PACKAGE_PIN U3  [get_ports {qspi_io[0]}]
set_property PACKAGE_PIN U4  [get_ports {qspi_io[1]}]
set_property PACKAGE_PIN U5  [get_ports {qspi_io[2]}]
set_property PACKAGE_PIN U6  [get_ports {qspi_io[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports qspi_sck]
set_property IOSTANDARD LVCMOS33 [get_ports qspi_cs_n]
set_property IOSTANDARD LVCMOS33 [get_ports {qspi_io[*]}]

#------------------------------------------------------------------------------
# JTAG debug (onboard JTAG: TCK=T11, TMS=T12, TDI=T13, TDO=T14, TRST=T15)
#------------------------------------------------------------------------------
set_property PACKAGE_PIN T11 [get_ports jtag_tck]
set_property PACKAGE_PIN T12 [get_ports jtag_tms]
set_property PACKAGE_PIN T13 [get_ports jtag_tdi]
set_property PACKAGE_PIN T14 [get_ports jtag_tdo]
set_property PACKAGE_PIN T15 [get_ports jtag_trst_n]
set_property IOSTANDARD LVCMOS33 [get_ports {jtag_tck jtag_tms jtag_tdi jtag_tdo jtag_trst_n}]

#------------------------------------------------------------------------------
# Watchdog reset out
#------------------------------------------------------------------------------
set_property PACKAGE_PIN T3  [get_ports wdog_reset_n_out]
set_property IOSTANDARD LVCMOS33 [get_ports wdog_reset_n_out]

#------------------------------------------------------------------------------
# Power wake
#------------------------------------------------------------------------------
set_property PACKAGE_PIN T4  [get_ports wake_req]
set_property PACKAGE_PIN T5  [get_ports wake_ack]
set_property IOSTANDARD LVCMOS33 [get_ports wake_req]
set_property IOSTANDARD LVCMOS33 [get_ports wake_ack]

#------------------------------------------------------------------------------
# I2S (not used in minimal config, pinned for future)
#------------------------------------------------------------------------------
set_property PACKAGE_PIN V9  [get_ports i2s_bclk]
set_property PACKAGE_PIN V10 [get_ports i2s_lrclk]
set_property PACKAGE_PIN W9  [get_ports i2s_dout]
set_property PACKAGE_PIN W10 [get_ports i2s_din]
set_property IOSTANDARD LVCMOS33 [get_ports i2s_bclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s_lrclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2s_dout]
set_property IOSTANDARD LVCMOS33 [get_ports i2s_din]

#------------------------------------------------------------------------------
# Timing constraints
#------------------------------------------------------------------------------
set_max_delay -datapath_only [all_inputs] [all_outputs]
