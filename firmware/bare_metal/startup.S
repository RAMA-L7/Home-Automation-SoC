#------------------------------------------------------------------------------
# Home-Automation-SoC — RISC-V RV32IMC Startup Code
# Stage 3 Firmware
#
# Reset vector entry point. Sets up stack, clears .bss, copies .data from
# flash to RAM, then jumps to main().
#------------------------------------------------------------------------------
.section .text.reset
.global _reset
.type _reset, @function
_reset:
    # Set stack pointer to top of SRAM
    la sp, _stack_top

    # Copy .data from load address (flash) to VMA (SRAM)
    la t0, _sdata
    la t1, _edata
    la t2, _sidata
    bge t0, t1, 2f                      # if sdata >= edata, skip
1:  lw t3, 0(t2)
    sw t3, 0(t0)
    addi t0, t0, 4
    addi t2, t2, 4
    blt t0, t1, 1b
2:

    # Clear .bss (zero-initialized data)
    la t0, _sbss
    la t1, _ebss
    bge t0, t1, 3f                      # if sbss >= ebss, skip
    li t3, 0
3:  sw t3, 0(t0)
    addi t0, t0, 4
    blt t0, t1, 3b
3:

    # Jump to main
    call main

    # If main returns, hang
4:  wfi
    j 4b

.size _reset, .- _reset

#------------------------------------------------------------------------------
# Bootstrap data for linker
#------------------------------------------------------------------------------
.section .data
.global _sdata, _edata, _sbss, _ebss, _stack_top
_sdata:
.align 2
_edata:
_sbss:
.align 2
_ebss:

.section .stack
.global _stack_top
_stack_top:
.zero 4096                              # 4 KB stack