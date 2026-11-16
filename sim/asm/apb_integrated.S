# Home-Automation-SoC — integrated APB address/response probe
#
# Loaded into the TCM (base 0x0001_0000) and reached through the boot ROM's
# `j 0x10000`.  It runs on the real SoC, so every access goes through the
# req/gnt adapter, the AXI4-Lite interconnect, the AXI-to-APB bridge and the
# peripheral decode in has_soc.sv — the path where the address and response
# defects actually live.
#
# s1 holds the TCM base (0x1_0000): result slots and the handler scratch live at
# offsets from it, never at raw low addresses (those are the read-only boot ROM).
#
# Targets:
#   R2  A byte write (PSTRB = 0001) is rejected with PSLVERR *and must not
#       change the register*.  No APB peripheral decodes PSTRB, so before the
#       fix the error response also performed a full-word write.
#   R3  Same for a halfword write (PSTRB = 0011 / 1100).
#   R4  An unmapped APB slot (0x5000_9000) completes with an error instead of
#       holding PREADY low forever.
#   R5  The APB aperture is 1 MB but the decode only looked at paddr[15:12], so
#       0x5001_0000 aliased GPIO.  It must now be unmapped (error, no write).
#   R1/R6  Supported word writes still work, including after the faults.
#
# Results (TCM word offsets):
#   0x100  GPIO DATA_OUT after the supported word write      expect 0x1234
#   0x104  ... after the rejected byte write                 expect 0x1234
#   0x108  ... after the rejected halfword write             expect 0x1234
#   0x10C  ... after the aliased write                       expect 0x1234
#   0x110  ... after the post-fault supported write          expect 0x5678
#   0x200  trap count                                        expect 4
#   0x220+4i mcause (all four traps are store access faults, mcause 7)
#   0x260+4i mtval (the faulting address)

.org 0
    li    s1, 0x10000           # TCM base
    li    t0, 0x10300           # trap handler: TCM offset 0x300
    csrw  mtvec, t0

    li    s0, 0x50000000        # GPIO slot base

    # ---- R1: supported word write ---------------------------------------
    li    t1, 0x1234
    sw    t1, 0(s0)
    lw    t2, 0(s0)
    sw    t2, 0x100(s1)

    # ---- R2: byte write must be rejected with no side effect ------------
    li    t1, 0xAB
    sb    t1, 0(s0)
    lw    t2, 0(s0)
    sw    t2, 0x104(s1)

    # ---- R3: halfword write must be rejected with no side effect --------
    li    t1, 0xCDEF
    sh    t1, 0(s0)
    lw    t2, 0(s0)
    sw    t2, 0x108(s1)

    # ---- R4: unmapped APB slot must complete with an error --------------
    li    t3, 0x50009000
    li    t1, 0x55
    sw    t1, 0(t3)

    # ---- R5: address beyond the 64 KB sub-block must not alias GPIO -----
    li    t3, 0x50010000
    sw    t1, 0(t3)
    lw    t2, 0(s0)
    sw    t2, 0x10C(s1)

    # ---- R6: a supported word write still works -------------------------
    li    t1, 0x5678
    sw    t1, 0(s0)
    lw    t2, 0(s0)
    sw    t2, 0x110(s1)

halt:
    j halt

#------------------------------------------------------------------------------
# Trap handler: record mcause/mtval/mepc per trap, skip the faulting word.
# Only t0/t1/t2 are clobbered; s1 (TCM base) is preserved.
#------------------------------------------------------------------------------
.org 0x300
    lw    t0, 0x200(s1)
    addi  t1, t0, 1
    sw    t1, 0x200(s1)
    slli  t0, t0, 2
    addi  t2, x0, 0x220
    add   t0, t0, t2
    add   t0, t0, s1
    csrr  t1, mcause
    sw    t1, 0(t0)
    csrr  t1, mtval
    addi  t2, t0, 0x40
    sw    t1, 0(t2)
    csrr  t1, mepc
    addi  t2, t0, 0x60
    sw    t1, 0(t2)
    addi  t1, t1, 4
    csrw  mepc, t1
    mret
