# Home-Automation-SoC — CPU architectural probes (CSR + retirement + alignment)
#
# Assembled with the independent GNU toolchain, NOT with scripts/fw/as.js, and
# the resulting words are inlined into sim/sim_top/tb_csr_arch.v.  That keeps
# the expected encodings out of the DUT's (and the project assembler's) hands.
#
#   riscv-none-elf-as -march=rv32im -mabi=ilp32 -o csr_arch.o csr_arch.S
#   riscv-none-elf-objdump -d csr_arch.o
#
# Result slots in data memory (word indices):
#   0x00/4  C1 old mscratch after CSRRWI  (must be 7, not rf[7])
#   0x04/4  C1 mscratch read back         (must be 7)
#   0x08/4  C2 after CSRRSI 0x10          (must be 0x17)
#   0x0C/4  C3 after CSRRCI 0x01          (must be 0x16)
#   0x10/4  C5 read-only CSR read         (must be 0, no trap)
#   0x14/4  C6 slot written after the trap (x14 never written -> 0)
#   0x6C/4  C7 minstret before the illegal instruction
#   0x98/4  C8 x30 after a faulting load  (must stay 0xDEADB7EF)
#   0x9C/4  C9 LHU odd slot               (must stay 0: the load did not retire)
#   0xA0/4  C10 aligned LHU               (must be 0xBEEF)
# Handler scratch:
#   0x300/4 trap index
#   0x400/4+4i mcause      0x500/4+4i mtval      0x600/4+4i mepc
#   0x700/4+4i minstret observed at trap entry
#
# Expected trap sequence (5 traps, mcause):
#   0: 2  CSRRW to read-only mhartid
#   1: 2  CSRRS of unsupported misa (0x301)
#   2: 2  illegal instruction (word 0x00000000)
#   3: 4  LW at 0x42 (2-byte aligned)
#   4: 4  LHU at 0x41 (odd)

.org 0
    lui   t0, 0
    addi  t0, x0, 0x200
    csrw  mtvec, t0

    # ---- data setup -------------------------------------------------------
    li    x5, 0xBEEF
    sh    x5, 0x40(x0)

    # ---- C1: CSRRWI must use the zero-extended zimm, not rf[zimm] ---------
    addi  x7, x0, -1            # rf[7] = 0xFFFFFFFF; zimm field is 7
    csrrwi x10, mscratch, 7
    csrrs  x11, mscratch, x0    # rs1 = x0 -> read only
    sw    x10, 0(x0)
    sw    x11, 4(x0)

    # ---- C2: CSRRSI sets bits from the zimm field -------------------------
    csrrsi x12, mscratch, 0x10
    sw    x12, 8(x0)

    # ---- C3: CSRRCI clears a bit named by the zimm field ------------------
    csrrci x13, mscratch, 0x1
    sw    x13, 12(x0)

    # ---- C4: writing a read-only CSR must trap (mcause 2) -----------------
    csrrw x0, mhartid, x5

    # ---- C5: reading a read-only CSR with rs1 = x0 must NOT trap ----------
    csrrs x1, mhartid, x0
    sw    x1, 16(x0)

    # ---- C6: an unsupported CSR must trap, not read 0 ---------------------
    csrr  x14, 0x301
    sw    x14, 20(x0)

    # ---- C7: a trapping instruction must not retire ----------------------
    csrr  x20, minstret
    sw    x20, 0x6C(x0)
    .word 0x00000000            # illegal opcode

    # ---- C8: a faulting load must not write back -------------------------
    lui   x30, 0xDEADB
    addi  x30, x30, 0x7EF
    addi  x6, x0, 0x40
    lw    x30, 2(x6)            # misaligned -> trap, x30 must be unchanged
    sw    x30, 0x98(x0)

    # ---- C9: odd-addressed LHU must trap --------------------------------
    addi  x6, x0, 0x40
    lhu   x24, 1(x6)
    sw    x24, 0x9C(x0)

    # ---- C10: aligned LHU is a control case (must not trap) --------------
    addi  x6, x0, 0x40
    lhu   x25, 0(x6)
    sw    x25, 0xA0(x0)

1:  j 1b

.org 0x200
    # Trap handler: record minstret-at-entry, then mcause/mtval/mepc, all in
    # per-trap slots indexed by a counter kept in memory (0x300).
    csrr  s1, minstret
    lw    t0, 0x300(x0)
    addi  t1, t0, 1
    sw    t1, 0x300(x0)
    slli  t0, t0, 2
    addi  t2, x0, 0x400
    add   t0, t0, t2            # t0 = 0x400 + 4*idx (mcause slot)
    addi  t2, x0, 0x300
    add   t2, t0, t2            # t2 = 0x700 + 4*idx (minstret slot)
    sw    s1, 0(t2)
    csrr  t1, mcause
    sw    t1, 0(t0)
    csrr  t1, mtval
    addi  t2, x0, 0x100
    add   t2, t0, t2
    sw    t1, 0(t2)
    csrr  t1, mepc
    addi  t2, x0, 0x200
    add   t2, t0, t2
    sw    t1, 0(t2)
    addi  t1, t1, 4
    csrw  mepc, t1
    mret
