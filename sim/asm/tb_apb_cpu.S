.org 0x10000
li t0, 0x10400
csrw mtvec, t0

# valid GPIO write + read
li t0, 0x50000000
li t1, 0x1234
sw t1, 0(t0)
lw t2, 0(t0)
bne t2, t1, fail

# unmapped write -> store access fault
li t3, 0x60000000
sw t1, 0(t3)

# unmapped read -> load access fault
lw t6, 0(t3)

# alias write within APB aperture -> trap
li t3, 0x50010000
sw t1, 0(t3)

# partial byte write -> trap
li t5, 0x55
sb t5, 0(t0)

# back-to-back valid writes
li t1, 0xaaaa
sw t1, 0(t0)
li t1, 0xbbbb
sw t1, 0(t0)
lw t2, 0(t0)
li t1, 0xbbbb
bne t2, t1, fail

# success
li a6, 0x10200
li a0, 1
sw a0, 0(a6)
j hang

fail:
li a6, 0x10200
li a0, 0
sw a0, 0(a6)
j hang

.org 0x10400
li a0, 0x10204
lw a1, 0(a0)
addi a1, a1, 1
sw a1, 0(a0)
csrr a2, mcause
li a0, 0x10208
sw a2, 0(a0)
csrr a2, mepc
addi a2, a2, 4
csrw mepc, a2
mret

hang:
j hang