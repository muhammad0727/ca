main:

    # x10=v[]
    # x11=k

    # computing the memory index of v[k]
    slli x5, x11, 2
    add x5, x5, x10 #x5 = address of v[k]
    lw x6,  0(x5) # loading the value of v[k] and x6=temp


    # computing the memory index of v[k + 1]
    addi x28, x11, 1 # k + 1
    slli x28, x28, 2 # (k+1)*4
    add x28, x28, x10 # address of v[k+1] in memory
    lw x7, 0(x28) # loading the value of v[k + 1]

    # v[k] = v[k + 1]
    sw x7, 0(x5)
    # v[k+1] = temp
    sw x6, 0(x28)

end:
