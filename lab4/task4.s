.data
array:
    .word 2, 3, 4, 5

.text

main:
    
    la x10, array         # load address of array into x10
    li x11, 4             # length = 4
    jal x1, product       # call product(array, 4)

    

    j end

product:

   
    addi sp, sp, -8

    #return address
    sw x1, 4(sp)
   
    
    beq x11, x0, base # if (len == 0)

    

    # address of a[len-1]
    addi x5, x11, -1       # x5 = len - 1
    slli x5, x5, 2        # x5 = (len-1) * 4
    add x5, x10, x5       # x5 = address of a[len-1]

    lw x5, 0(x5)           # x5 = a[len-1]

    sw x5, 0(sp) # preserving the value of a[len-1] on the stack

    addi x11, x11, -1      # len = len - 1
    jal x1, product

    lw x5, 0(sp) # restoring the value of a[len-1] from the stack

    mul x10, x5, x10       # a[len-1] * recursive result

    lw x1, 4(sp)

    addi sp, sp, 8

    jalr x0, 0(x1)


base:
    # product of zero elements = 1
    li x10, 1

    # Restore return address
    lw x1, 4(sp)

    addi sp, sp, 8

    jalr x0, 0(x1)


end:
