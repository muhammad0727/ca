
main:
# x10, x11 contains the base address of string x, and y
# x19 is i
    li x19, 0
    li x10, 0x124
    li x11, 0x456

    addi sp, sp, -4
    sw x19, 0(sp)
  

    mv x28, x10
    mv x29, x11
    
loop:

    #loading the value from y[i]
    lb x30, 0(x29)
    # storing it immediately in x[i]
    sb x30, 0(x28)
    #end condition
    beq x30, x0, end
    
    addi x28, x28, 1
    addi x29, x29, 1

    addi x19, x19, 1
    j loop

end:

lw   x19, 0(sp)
addi sp, sp, 4
ret