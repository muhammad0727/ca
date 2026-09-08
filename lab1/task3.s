
main:
    # Initialize the stack pointer
    li x1, 5 # a = 5
    li x2, 0 # b = 0
    addi x1, x2, 32 # a = b + 32 = 32
    add x3, x1, x2 # c = a + b = 32
    addi x4, x3,-5 # d = c - 5 = 27
    sub x5, x1, x4 # e = a - d = 5
    sub x6, x2, x1 # f = b - a = -32
    add x7, x5, x6 # g = e + f = -27
    add x8, x7, x4 # intermediate e = g + d = 0
    # final statement
    add x5, x1, x2 # e = a + b = 32
    add x5, x5, x4 # e = e + d = 59
    

end:
    j end