//------------------------------------------------------------------------------
// Home-Automation-SoC — Boot firmware (RV32IM assembly)
//
// Runs from the boot ROM, exercises the SoC end to end and prints results over
// UART at 115200 baud (50 MHz clock, default divisor).
//
// Built with scripts/fw/as.js (no RISC-V toolchain is installed).  Output is a
// $readmemh image loaded into boot_rom.
//
// Memory map
//   ROM   0x0000_0000   SRAM  0x2000_0000
//   GPIO  0x5000_0000   UART  0x5000_1000   I2C 0x5000_2000   SPI 0x5000_3000
//   PWM   0x5000_4000   TIMER 0x5000_5000   WDOG 0x5000_6000  I2S 0x5000_7000
//   PWR   0x5000_8000   CLINT 0x8000_0000   PLIC 0x8000_1000
//------------------------------------------------------------------------------

.equ UART_BASE,   0x50001000
.equ UART_THR,    0x00
.equ UART_LSR,    0x14

.equ GPIO_BASE,   0x50000000
.equ GPIO_OUT,    0x00
.equ GPIO_OE,     0x08

.equ TIMER_BASE,  0x50005000
.equ TIMER_COUNT, 0x00
.equ TIMER_COMP,  0x04
.equ TIMER_CTRL,  0x08
.equ TIMER_STAT,  0x0C

.equ PWM_BASE,    0x50004000

.equ PWR_BASE,    0x50008000

.equ CLINT_BASE,  0x80000000
.equ CLINT_MSIP,  0x000
.equ CLINT_CMP,   0x3F8
.equ CLINT_CMPH,  0x3FC
.equ CLINT_MTIME, 0x7F8
.equ CLINT_MTIMEH,0x7FC

.equ PLIC_BASE,   0x80001000
.equ PLIC_EN,     0x200
.equ PLIC_THRESH, 0x204
.equ PLIC_CLAIM,  0x208

.equ MSTATUS_MIE, 0x8
.equ MIE_MTIE,    0x80
.equ MIE_MEIE,    0x800

.org 0x00000000

//------------------------------------------------------------------------------
// Reset vector
//------------------------------------------------------------------------------
_start:
    li   sp, 0x20010000          // stack at top of 128 KB SRAM
    li   s0, 0                   // pass counter
    li   s1, 0                   // fail counter
    li   s2, 0                   // timer IRQ counter
    li   s3, 0                   // PLIC IRQ counter
    la   t0, trap_entry
    csrw mtvec, t0

    la   a0, msg_boot
    call puts

//------------------------------------------------------------------------------
// Test 1: SRAM word / halfword / byte access
//------------------------------------------------------------------------------
t_sram:
    li   t0, 0x20000000
    li   t1, 0xDEADBEEF
    sw   t1, 0(t0)
    lw   t2, 0(t0)
    bne  t2, t1, sram_fail

    li   t1, 0x12345678
    sw   t1, 4(t0)
    lbu  t2, 4(t0)
    li   t3, 0x78
    bne  t2, t3, sram_fail

    lbu  t2, 5(t0)
    li   t3, 0x56
    bne  t2, t3, sram_fail

    lhu  t2, 4(t0)
    li   t3, 0x5678
    bne  t2, t3, sram_fail

    // sign extension: store 0xFFFFFF80 as a byte, read back signed
    li   t1, 0xFFFFFF80
    sb   t1, 8(t0)
    lb   t2, 8(t0)
    bne  t2, t1, sram_fail

    la   a0, msg_ok_sram
    call puts
    addi s0, s0, 1
    j    t_gpio
sram_fail:
    la   a0, msg_err_sram
    call puts
    addi s1, s1, 1

//------------------------------------------------------------------------------
// Test 2: GPIO output enable + data register readback
//------------------------------------------------------------------------------
t_gpio:
    li   t0, GPIO_BASE
    li   t1, 0x0000FFFF
    sw   t1, GPIO_OE(t0)
    li   t1, 0x0000A5A5
    sw   t1, GPIO_OUT(t0)
    lw   t2, GPIO_OUT(t0)
    li   t3, 0x0000A5A5
    bne  t2, t3, gpio_fail
    la   a0, msg_ok_gpio
    call puts
    addi s0, s0, 1
    j    t_mul
gpio_fail:
    la   a0, msg_err_gpio
    call puts
    addi s1, s1, 1

//------------------------------------------------------------------------------
// Test 3: M extension (multiply / divide)
//------------------------------------------------------------------------------
t_mul:
    li   t0, 7
    li   t1, 6
    mul  t2, t0, t1
    li   t3, 42
    bne  t2, t3, mul_fail

    li   t0, 100
    li   t1, 7
    div  t2, t0, t1
    li   t3, 14
    bne  t2, t3, mul_fail

    rem  t2, t0, t1
    li   t3, 2
    bne  t2, t3, mul_fail

    // division by zero must not trap and must return -1
    li   t0, 5
    li   t1, 0
    divu t2, t0, t1
    li   t3, -1
    bne  t2, t3, mul_fail

    la   a0, msg_ok_mul
    call puts
    addi s0, s0, 1
    j    t_csr
mul_fail:
    la   a0, msg_err_mul
    call puts
    addi s1, s1, 1

//------------------------------------------------------------------------------
// Test 4: CSR counter advances
//------------------------------------------------------------------------------
t_csr:
    csrr t0, mcycle
    csrr t1, mcycle
    beq  t0, t1, csr_fail        // must differ after two instructions
    la   a0, msg_ok_csr
    call puts
    addi s0, s0, 1
    j    t_plic
csr_fail:
    la   a0, msg_err_csr
    call puts
    addi s1, s1, 1

//------------------------------------------------------------------------------
// Test 5: PLIC -> machine external interrupt, sourced by the peripheral timer
// PLIC source IDs: 1 uart, 2 spi, 3 i2c, 4 gpio, 5 pwm, 6 timer, 7 wdog, 8 i2s
//------------------------------------------------------------------------------
t_plic:
    li   t0, PLIC_BASE
    li   t1, 2
    sw   t1, 0x018(t0)           // prio(source 6) = 2  (0x004 + 4*(6-1))
    li   t1, 0x00000020
    sw   t1, PLIC_EN(t0)         // enable source 6
    li   t1, 0
    sw   t1, PLIC_THRESH(t0)     // threshold 0

    li   t0, TIMER_BASE
    li   t1, 40
    sw   t1, TIMER_COMP(t0)
    li   t1, 0x3                // enable + interrupt enable
    sw   t1, TIMER_CTRL(t0)

    li   t1, MIE_MEIE
    csrs mie, t1
    li   t1, MSTATUS_MIE
    csrs mstatus, t1

    li   t2, 0
plic_wait:
    addi t2, t2, 1
    li   t3, 2000
    bgeu t2, t3, plic_timeout
    beqz s3, plic_wait

    csrci mstatus, MSTATUS_MIE
    csrc  mie, t1                 // t1 = MEIE  (kept from above)
    la    a0, msg_ok_plic
    call  puts
    addi  s0, s0, 1
    j     t_pwm
plic_timeout:
    la    a0, msg_err_plic
    call  puts
    addi  s1, s1, 1

//------------------------------------------------------------------------------
// Test 6: PWM register programming
//------------------------------------------------------------------------------
t_pwm:
    li   t0, PWM_BASE
    li   t1, 100                 // period
    sw   t1, 0x00(t0)
    li   t1, 25                  // duty 25%
    sw   t1, 0x04(t0)
    lw   t2, 0x00(t0)
    li   t3, 100
    bne  t2, t3, pwm_fail

    li   t1, 0x1                 // enable channel 0
    sw   t1, 0x20(t0)
    lw   t2, 0x20(t0)
    bne  t2, t1, pwm_fail

    la   a0, msg_ok_pwm
    call puts
    addi s0, s0, 1
    j    t_pwr
pwm_fail:
    la   a0, msg_err_pwm
    call puts
    addi s1, s1, 1

//------------------------------------------------------------------------------
// Test 7: power manager register visibility (sleep is not entered here: the
// wake path is driven by the testbench)
//------------------------------------------------------------------------------
t_pwr:
    li   t0, PWR_BASE
    li   t1, 1
    sw   t1, 0x08(t0)            // wake_en = 1
    lw   t2, 0x08(t0)
    bne  t2, t1, pwr_fail

    // Peripheral-address isolation.  Every earlier subtest drove a different
    // APB slot (GPIO, UART, PWM, timer).  PM_CTRL must still read 0 and GPIO
    // must still hold its own value: before each peripheral's ACCESS phase was
    // qualified by its slot, a UART THR write (paddr[11:2]==0) also landed in
    // PM_CTRL and set sleep_request, gating the core clock.
    lw   t2, 0x00(t0)
    bnez t2, pwr_fail
    li   t0, GPIO_BASE
    lw   t2, GPIO_OUT(t0)
    li   t3, 0x0000A5A5
    bne  t2, t3, pwr_fail

    la   a0, msg_ok_pwr
    call puts
    addi s0, s0, 1
    j    summary
pwr_fail:
    la   a0, msg_err_pwr
    call puts
    addi s1, s1, 1

//------------------------------------------------------------------------------
// Summary
//------------------------------------------------------------------------------
summary:
    la   a0, msg_summary
    call puts

    mv   a0, s0
    call puthex
    la   a0, msg_pass
    call puts

    mv   a0, s1
    call puthex
    la   a0, msg_fail
    call puts

    beqz s1, all_ok
    la   a0, msg_banner_fail
    call puts
    j    idle
all_ok:
    la   a0, msg_banner_ok
    call puts

idle:
    la   a0, msg_idle
    call puts
hang:
    j    hang

//------------------------------------------------------------------------------
// Trap handler
//------------------------------------------------------------------------------
trap_entry:
    csrr t0, mcause

    // machine timer interrupt (0x80000007)
    li   t1, 0x80000007
    beq  t0, t1, irq_timer_isr

    // machine external interrupt (0x8000000B)
    li   t1, 0x8000000B
    beq  t0, t1, irq_ext_isr

    // unexpected trap: report cause and stay here
    la   a0, msg_trap
    call puts
    csrr a0, mcause
    call puthex
    la   a0, msg_nl
    call puts
trap_hang:
    j    trap_hang

irq_timer_isr:
    addi s2, s2, 1
    // disarm: mtimecmp = all ones
    li   t0, CLINT_BASE
    li   t1, -1
    sw   t1, CLINT_CMP(t0)
    sw   t1, CLINT_CMPH(t0)
    mret

irq_ext_isr:
    addi s3, s3, 1
    // claim + complete the interrupt
    li   t0, PLIC_BASE
    lw   t1, PLIC_CLAIM(t0)
    sw   t1, PLIC_CLAIM(t0)
    // stop the peripheral timer so the level does not re-assert
    li   t0, TIMER_BASE
    li   t1, 0
    sw   t1, TIMER_CTRL(t0)
    li   t1, 1
    sw   t1, TIMER_STAT(t0)      // W1C the match flag
    mret

//------------------------------------------------------------------------------
// Subroutines
//------------------------------------------------------------------------------
// puts: a0 = NUL-terminated string
// Saves ra because it calls putc (a nested call would otherwise destroy it).
puts:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   t4, 0(sp)
    mv   t4, a0
puts_loop:
    lbu  a0, 0(t4)
    beqz a0, puts_done
    call putc
    addi t4, t4, 1
    j    puts_loop
puts_done:
    lw   t4, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8
    ret

// putc: a0 = byte; polls THRE (LSR bit 5)
// Uses only t0/t1 so callers may keep loop state in t4/t5 (puthex does).
putc:
    li   t0, UART_BASE
putc_wait:
    lw   t1, UART_LSR(t0)
    andi t1, t1, 0x20
    beqz t1, putc_wait
    sw   a0, UART_THR(t0)
    ret

// puthex: a0 = value, prints 8 hex digits
puthex:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   t4, 8(sp)
    sw   t5, 4(sp)
    sw   t6, 0(sp)
    mv   t4, a0
    li   t5, 8
puthex_loop:
    srli a0, t4, 28
    andi a0, a0, 0xF
    li   t6, 10
    bltu a0, t6, puthex_digit
    addi a0, a0, ('A' - 10)
    j    puthex_emit
puthex_digit:
    addi a0, a0, '0'
puthex_emit:
    call putc
    slli t4, t4, 4
    addi t5, t5, -1
    bnez t5, puthex_loop
    lw   t6, 0(sp)
    lw   t5, 4(sp)
    lw   t4, 8(sp)
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

//------------------------------------------------------------------------------
// Strings
//------------------------------------------------------------------------------
msg_boot:        .asciz "\r\nHAS-SoC boot: RV32IM\r\n"
msg_ok_sram:     .asciz "PASS sram\r\n"
msg_err_sram:    .asciz "FAIL sram\r\n"
msg_ok_gpio:     .asciz "PASS gpio\r\n"
msg_err_gpio:    .asciz "FAIL gpio\r\n"
msg_ok_mul:      .asciz "PASS muldiv\r\n"
msg_err_mul:     .asciz "FAIL muldiv\r\n"
msg_ok_csr:      .asciz "PASS csr\r\n"
msg_err_csr:     .asciz "FAIL csr\r\n"
msg_ok_plic:     .asciz "PASS plic\r\n"
msg_err_plic:    .asciz "FAIL plic\r\n"
msg_ok_pwm:      .asciz "PASS pwm\r\n"
msg_err_pwm:     .asciz "FAIL pwm\r\n"
msg_ok_pwr:      .asciz "PASS pwr\r\n"
msg_err_pwr:     .asciz "FAIL pwr\r\n"
msg_summary:     .asciz "\r\nsummary pass="
msg_pass:        .asciz " fail="
msg_fail:        .asciz "\r\n"
msg_banner_ok:   .asciz "RESULT: ALL TESTS PASSED\r\n"
msg_banner_fail: .asciz "RESULT: FAILURES PRESENT\r\n"
msg_idle:        .asciz "idle\r\n"
msg_trap:        .asciz "TRAP mcause="
msg_nl:          .asciz "\r\n"
