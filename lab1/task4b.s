

main:
# first iteration
    lb x1, 0x100(x0)
    lh x2, 0x200(x0)

    add x4, x1, x2
    sw x4, 0x300(x0)
# second iteration
    lb x5, 0x101(x0)
    lh x6, 0x202(x0)

    add x8, x5, x6
    sw x8, 0x304(x0)

# third iteration
    lb x9, 0x102(x0)
    lh x10, 0x204(x0)

    add x12, x9, x10
    sw x12, 0x308(x0)

#fourth iteration
    lb x13, 0x103(x0)
    lh x14, 0x206(x0)

    add x15, x13, x14
    sw x15, 0x30c(x0)
end:
    j end