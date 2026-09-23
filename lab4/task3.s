.data
array:
    .word 5, 2, 8

.text
main:
    # Example array:
    # a = {5, 2, 8}
    
    la   x10, array        # x10 = address of array
    addi x11, x0, 3       # x11 = length = 3

    jal  x1, bubble        # call bubble(a, 3)

    # array = {1, 2, 3}
    j end

bubble:
    beq  x10, x0, return #if (a == NULL)
    beq  x11, x0, return # if (len == 0)
    addi x5, x0, 0         # i = 0


outer_loop:
    # for (i = 0; i < len; i++)
    bge  x5, x11, return   # if i >= len, finish
    addi x6, x5, 0         # j = i


inner_loop:
    # for (j = i; j < len; j++)
    bge  x6, x11, next_i   # if j >= len, go to next i

    slli x7, x5, 2         # x7 = i * 4
    add  x7, x10, x7       # x7 = address of a[i]

    lw   x8, 0(x7)         # x8 = a[i]

    slli x9, x6, 2         # x9 = j * 4
    add  x9, x10, x9       # x9 = address of a[j]

    lw   x12, 0(x9)        # x12 = a[j]

    bge  x8, x12, no_swap  # if a[i] >= a[j], don't swap

    sw   x12, 0(x7)        # a[i] = a[j]
    sw   x8, 0(x9)         # a[j] = temp

no_swap:
    addi x6, x6, 1         # j++
    jal  x0, inner_loop


next_i:
    addi x5, x5, 1         # i++
    jal  x0, outer_loop


return:
    jalr x0, 0(x1)         # return



end:
