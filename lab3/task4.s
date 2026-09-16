
main:
# x5, x6 contains the base address of string x, and y
# x7 is i
    li x7, 0
    li x5, 0x124
    li x6, 0x456

    mv x28, x5
    mv x29, x6
    
loop:
    


    #lw x30, 0(x28)
    lb x30, 0(x29)

    sb x30, 0(x28)
    
    beq x30, x0, end
    
    addi x28, x28, 1
    addi x29, x29, 1

    addi x7, x7, 1
    j loop

end: