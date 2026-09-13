

main:
# listing 3 code translation
    # x19-x23 are dedicated to f to j vars
    # test data:
    li x20, 5      # f = 5
    li x21, 3      # g = 3  
    li x22, 10     # h = 10
    li x23, 10     # i = 10 

    bne x22, x23, Else
    add x19, x20, x21
    beq x0, x0, Exit
Else: sub x19, x20, x21

Exit:

# code of the listing 4
# i and k are in x22, x24, and the base address of 'save' is in x25
start:
    # test data:
    li x22, 0      # i = 0 (loop start)
    li x24, 5      # k = 5
Loop: slli x10, x22, 2
    add x10, x10, x25
    lw x9, 0(x10)
    bne x9, x24, end
    addi x22, x22, 1
    beq x0, x0, Loop

end: