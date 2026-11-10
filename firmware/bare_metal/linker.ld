/*------------------------------------------------------------------------------
 * Home-Automation-SoC — Linker Script
 * Stage 3 Firmware
 *
 * Memory map matches has_addr_map_pkg:
 *   Boot ROM: 0x0000_0000 (16 KB)
 *   TCM:      0x0001_0000 (32 KB)
 *   SRAM:     0x2000_0000 (128 KB)
 *----------------------------------------------------------------------------*/

MEMORY
{
    bootrom (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
    tcm     (rwx) : ORIGIN = 0x00010000, LENGTH = 32K
    sram    (rwx) : ORIGIN = 0x20000000, LENGTH = 128K
    qspiflash (rx): ORIGIN = 0x40000000, LENGTH = 64M
}

ENTRY(_reset)

SECTIONS
{
    /* Reset vector at start of boot ROM */
    .text.reset 0x00000000 :
    {
        KEEP(*(.text.reset))
        *(.text.vectors)
    } > bootrom

    /* Main program in TCM (zero-wait) */
    .text 0x00010000 :
    {
        *(.text*)
        *(.rodata*)
    } > tcm

    /* Data in SRAM */
    .data 0x20000000 :
    {
        _sidata = LOADADDR(.data);
        _sdata = .;
        *(.data*)
        *(.sdata*)
        _edata = .;
    } > sram AT > qspiflash

    /* BSS in SRAM */
    .bss 0x20000000 + SIZEOF(.data) :
    {
        _sbss = .;
        *(.bss*)
        *(.sbss*)
        _ebss = .;
    } > sram

    /* Stack at end of TCM */
    _stack_top = 0x00018000;

    /* Symbols for firmware */
    _firmware_start = 0x00010000;
    _firmware_end = .;
}
