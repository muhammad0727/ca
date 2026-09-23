main:

 addi x10 , x0 , 3 # argument n = 3
 jal x1 , fact # call fact(n)

 # exit program
 j end

## RECURSIVE METHOD
fact:
 addi sp, sp, -8 # adjust stack for 2 items
 sw x1 , 4(sp) # save return address
 sw x10 , 0(sp) # save argument n

 addi x5 , x10 , -1 # x5 = n - 1
 bge x5 , x0 , L1 # if (n - 1) >= 0, go to L1

 addi x10 , x0 , 1 # return 1
 addi sp , sp , 8 # pop stack
 jalr x0 , 0(x1) # return

L1:
 addi x10 , x10 , -1 # argument = n - 1
 jal x1 , fact # recursive call

 addi x6 , x10 , 0 # save result of fact(n-1)
 lw x10 , 0(sp) # restore original n
 lw x1 , 4(sp) # restore return address
 addi sp , sp , 8 # pop stack

 mul x10 , x10 , x6 # n * fact(n-1)
 jalr x0 , 0(x1) # return

end:

# ITERATIVE METHOD

# x10 = n
# result will be kept in x5
li x10, 3 
fact_iter:
    addi x5, x0, 1       # acc = 1

loop:
    beq x10, x0, done    # if n == 0, finish

    mul x5, x5, x10      # acc = acc * n
    addi x10, x10, -1    # n = n - 1
    jal x0, loop         # repeat

done:
    addi x10, x5, 0      # return value in x10
    jalr x0, 0(x1)       # return
