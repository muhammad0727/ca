
main:
    # x5=a, x6=b, x7=i, x29=j & x10=baseOf-D
    li x10, 0x1000
    #######
for1:bge x7, x5, end
    li x29, 0 #j=0
for2:bge x29, x6, next
    #inner working of the loop
    add x11, x7, x29 # i + j
    slli x12, x29, 2 #j*4 
    add x10, x12, x10 # baseOf-D + j*4
    sw x11, 0(x10) # D[j*4] = i + j
    addi x29, x29, 1 # j++
    j for2
next:
    addi x7, x7, 1 #i++
    j for1
end: