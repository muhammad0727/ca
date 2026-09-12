main:
# g=x10, h=x11, i=x12, j=x13, f=x20
# saved x18, x19, x20
    li x10, 2
    li x11, 3
    li x12, 4
    li x13, 5
    jal x1, leaf_exp
    # jump out of code
    j end


leaf_exp:
# making the space and storing the values in stack
    addi sp, sp, -12
    sw x18, 4(sp)
    sw x19, 8(sp)
    sw x20, 12(sp)
# doing the actual calculations
    li x20, 0
    add x18, x10, x11
    add x19, x12, x13
    sub x20, x18, x19
    mv x10, x20
# restoring the original values of saved (currently named temps) values
    lw  x18, 4(sp)
    lw x19, 8(sp)
    lw x20, 12(sp)
    addi sp, sp, 12
# returing to the main function!

    jalr x0, 0(x1)

end:

