main:

 addi x10 , x0 , 5 # argument n = 5
 jal x1 , ntri # call ntri(n)
 addi x11, x10, 0 # store result in x10
 li x10, 1 # load 1 into x10
 ecall
 # exit program
 j end

## RECURSIVE METHOD
ntri:
 addi sp, sp, -8 # adjust stack for 2 items
 sw x1 , 4(sp) # save return address
 sw x10 , 0(sp) # save argument n

 addi x5 , x10 , -2 # x5 = n - 2
 bge x5 , x0 , L1 # if (n - 2) >= 0, go to L1

 addi x10 , x0 , 1 # return 1
 addi sp , sp , 8 # pop stack
 jalr x0 , 0(x1) # return

L1:
 addi x10 , x10 , -1 # argument = n - 1
 jal x1 , ntri # recursive call

 addi x6 , x10 , 0 # save result of fact(n-1)
 lw x10 , 0(sp) # restore original n
 lw x1 , 4(sp) # restore return address
 addi sp , sp , 8 # pop stack

 add x10 , x10 , x6 # n + ntri(n-1)
 jalr x0 , 0(x1) # return

end:

# ITERATIVE METHOD

