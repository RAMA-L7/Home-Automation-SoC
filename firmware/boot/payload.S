//------------------------------------------------------------------------------
// Home-Automation-SoC — RAM-resident boot payload (production boot test)
//
// This program is NOT in the boot ROM.  It is copied there by
// firmware/boot/loader.S and executes from TCM at 0x0001_0000, i.e. it is the
// proof that a cold start with undefined TCM/SRAM reaches real code.
//
// It also proves the two pieces of initialisation that a preload hides:
//   * .data  — a word that only exists in the ROM image and must be copied to
//              SRAM by the loader (expected 0xC0FFEE01);
//   * .bss   — a word that must read as 0 because the loader zeroed it.  The
//              SRAM macro models power up undefined, so a missing clear shows
//              up as an x/FAIL line instead of a silent pass.
//
// It then arms the watchdog and stops petting it, so the same boot path is
// re-entered from reset: the testbench must observe the banner twice with a
// watchdog reset in between.
//
// Image layout (assembled as one flat image, split by
// scripts/fw_build/gen_boot_image.js at DATA_IMAGE_WORD):
//   words [0, DATA_IMAGE_WORD)        -> TCM   0x0001_0000
//   words [DATA_IMAGE_WORD, end)      -> SRAM  0x2000_0000
//------------------------------------------------------------------------------

.equ UART_BASE,   0x50001000
.equ UART_THR,    0x00
.equ UART_LSR,    0x14

.equ WDOG_BASE,   0x50006000
.equ WDOG_LOAD,   0x00
.equ WDOG_CTRL,   0x04

// The .data image is copied to 0x2000_0000; its first word is DATA_WORD.
.equ DATA_ADDR,   0x20000000
.equ DATA_VALUE,  0xC0FFEE01
// .bss is the word after it, zeroed by the loader before this code runs.
.equ BSS_ADDR,    0x20000004

.equ DATA_IMAGE_WORD, 0x3C0        // 0x0F00 / 4: code+rodata below, data above

// Assembled at its RUN address: every label resolves to the TCM address it
// will actually occupy, because the loader copies the image there verbatim.
.org 0x00010000

payload_entry:
    la   a0, msg_boot
    call puts

    // --- .data must have been copied out of the ROM image -----------------
    li   t0, DATA_ADDR
    lw   t1, 0(t0)
    li   t2, DATA_VALUE
    bne  t1, t2, data_fail
    la   a0, msg_data_ok
    call puts
    j    check_bss
data_fail:
    la   a0, msg_data_err
    call puts
    lw   a0, 0(t0)
    call puthex
    la   a0, msg_nl
    call puts

check_bss:
    // --- .bss must be zero -------------------------------------------------
    li   t0, BSS_ADDR
    lw   t1, 0(t0)
    bnez t1, bss_fail
    la   a0, msg_bss_ok
    call puts
    j    cold_done
bss_fail:
    la   a0, msg_bss_err
    call puts
    lw   a0, 0(t0)
    call puthex
    la   a0, msg_nl
    call puts

cold_done:
    la   a0, msg_cold_ok
    call puts

    // --- arm the watchdog and starve it: the next boot proves recovery -----
    li   t0, WDOG_BASE
    li   t1, 20000
    sw   t1, WDOG_LOAD(t0)
    li   t1, 0x3                     // bit0 enable, bit1 reset enable
    sw   t1, WDOG_CTRL(t0)

starve:
    j    starve

//------------------------------------------------------------------------------
// Minimal UART console (same THRE polling contract as firmware/boot/boot.S)
//------------------------------------------------------------------------------
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

putc:
    li   t0, UART_BASE
putc_wait:
    lw   t1, UART_LSR(t0)
    andi t1, t1, 0x20
    beqz t1, putc_wait
    sw   a0, UART_THR(t0)
    ret

// puthex: a0 = value, prints 8 lowercase hex digits, clobbers t0-t4
puthex:
    addi sp, sp, -20
    sw   ra, 16(sp)
    sw   t4, 12(sp)
    sw   t3, 8(sp)
    sw   t2, 4(sp)
    sw   t1, 0(sp)
    mv   t4, a0
    li   t3, 8
hex_loop:
    srli t2, t4, 28
    slli t4, t4, 4
    li   t0, 10
    blt  t2, t0, hex_digit
    addi t2, t2, 39
    j    hex_emit
hex_digit:
    addi t2, t2, 48
hex_emit:
    mv   a0, t2
    call putc
    addi t3, t3, -1
    bnez t3, hex_loop
    lw   t1, 0(sp)
    lw   t2, 4(sp)
    lw   t3, 8(sp)
    lw   t4, 12(sp)
    lw   ra, 16(sp)
    addi sp, sp, 20
    ret

//------------------------------------------------------------------------------
// Read-only strings — part of the TCM image, addressed through their resolved
// TCM labels.
//------------------------------------------------------------------------------
msg_boot:      .asciz "BOOT: PAYLOAD RUNNING FROM TCM\r\n"
msg_data_ok:   .asciz "BOOT: DATA OK\r\n"
msg_data_err:  .asciz "BOOT: DATA FAIL "
msg_bss_ok:    .asciz "BOOT: BSS OK\r\n"
msg_bss_err:   .asciz "BOOT: BSS FAIL "
msg_cold_ok:   .asciz "BOOT: COLD BOOT PASS\r\n"
msg_nl:        .asciz "\r\n"

//------------------------------------------------------------------------------
// The split point: everything above is copied to TCM, this word is copied to
// SRAM at 0x2000_0000.  It exists ONLY in the ROM image — the payload reads it
// back through the absolute address, which is what proves the copy happened.
//------------------------------------------------------------------------------
.org 0x00010F00                    // DATA_IMAGE_WORD * 4

data_block:
    .word 0xC0FFEE01
