//------------------------------------------------------------------------------
// Home-Automation-SoC — production boot loader (runs from the boot ROM)
//
// This is the cold-start path used when the memories are NOT preloaded: a real
// SRAM/TCM macro powers up with undefined contents, so the code that runs at
// 0x0000_0000 must place everything before the CPU executes any RAM code.
//
// What it does, in order:
//   1. set the stack pointer (top of TCM, which is also where the RAM image
//      lands, so it is set before anything can push),
//   2. copy the .text/.rodata image from the ROM into TCM,
//   3. copy the .data image from the ROM into SRAM,
//   4. zero .bss in SRAM,
//   5. jump to the payload entry point.
//
// The sizes and destinations are NOT assembled in: they are read from a header
// table at ROM offset 0x800 that `scripts/fw_build/gen_boot_image.js` writes
// from the actual payload.  A stale or mismatched header therefore produces a
// visibly wrong image rather than a silently wrong one.
//
// Header (one 32-bit word each, little-endian, at 0x0000_0800):
//   0x00  TCM destination address        (0x0001_0000)
//   0x04  TCM image length in words
//   0x08  .data destination address      (0x2000_0000)
//   0x0C  .data image length in words
//   0x10  .bss destination address
//   0x14  .bss length in words
//   0x18  payload entry address
//   0x1C  .data image source offset in ROM
//
// The TCM image always starts at ROM offset 0x1000.  External QSPI flash is
// NOT used here: qspi_flash_ctrl implements a single-line READ engine only, and
// with no program/erase path there is no way to place a boot image in flash on
// this design.  Loading from the on-die boot ROM is therefore the only boot
// path that exists today; see reports/BOOT_PATH_QUALIFICATION.md.
//------------------------------------------------------------------------------

.equ HDR_BASE,   0x00000800
.equ TCM_SRC,    0x00001000
.equ STACK_TOP,  0x00018000

.org 0x00000000

_start:
    li   sp, STACK_TOP
    li   s0, HDR_BASE

    // 1. text/rodata: ROM -> TCM
    lw   a0, 0x00(s0)
    lw   a1, 0x04(s0)
    li   a2, TCM_SRC
    call copy_words

    // 2. initialised data: ROM -> SRAM
    lw   a0, 0x08(s0)
    lw   a1, 0x0C(s0)
    lw   a2, 0x1C(s0)
    call copy_words

    // 3. bss: SRAM <- zero
    lw   a0, 0x10(s0)
    lw   a1, 0x14(s0)
    li   a2, 0
    call fill_words

    // 4. hand control to the payload
    lw   t0, 0x18(s0)
    jr   t0

//------------------------------------------------------------------------------
// copy_words: a0 = destination, a1 = word count, a2 = source
//------------------------------------------------------------------------------
copy_words:
    beqz a1, copy_done
copy_loop:
    lw   t0, 0(a2)
    sw   t0, 0(a0)
    addi a0, a0, 4
    addi a2, a2, 4
    addi a1, a1, -1
    bnez a1, copy_loop
copy_done:
    ret

//------------------------------------------------------------------------------
// fill_words: a0 = destination, a1 = word count, a2 = fill value
//------------------------------------------------------------------------------
fill_words:
    beqz a1, fill_done
fill_loop:
    sw   a2, 0(a0)
    addi a0, a0, 4
    addi a1, a1, -1
    bnez a1, fill_loop
fill_done:
    ret
