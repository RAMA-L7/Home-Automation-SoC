.org 0
# setup mtvec = 0x200
lui t0, 0
addi t0, t0, 0x200
csrw mtvec, t0

# CSR immediate test: x7=-1, zimm=7 should win
addi x7, x0, -1
csrrwi x10, mscratch, 7
csrrs x11, mscratch, x0
sw x10, 0(x0)
sw x11, 4(x0)

# minstret test
csrr x20, minstret
nop
csrr x21, minstret
sw x20, 8(x0)
sw x21, 12(x0)

# LHU aligned
lui t1, 0
addi t1, t1, 0x40
li t2, 0x1234
sh t2, 0(t1)
lhu x22, 0(t1)
sw x22, 16(x0)

# unsupported CSR read -> trap; handler records mcause at 0x20
csrr x23, misa
sw x23, 20(x0)

# LHU odd address -> trap (last trap, so mcause final = 4)
lui t1, 0
addi t1, t1, 0x40
lhu x24, 1(t1)

# halt
jal x0, 0x400

.org 0x200
# trap handler: log mcause, mtval, mepc
csrr t0, mcause
sw t0, 0x20(x0)
csrr t1, mtval
sw t1, 0x24(x0)
csrr t2, mepc
sw t2, 0x28(x0)
addi t2, t2, 4
csrw mepc, t2
mret

.org 0x400
j 0x400