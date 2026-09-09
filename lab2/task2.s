
main:
# x, a, b, c = x20, x21, x22, x23
#initializing with random vals
    li x22 10
    li x23 20

    #switch case code
    # case values in temp registers
    li x28, 1
    li x29, 2
    li x30, 3
    li x31, 4

case1:bne x20, x28, case2
    add x21, x22, x23
    j end
case2:bne x20, x29, case3
    sub x21, x22, x23
    j end
case3:bne x20, x30, case4
    slli x21, x22, 1
    j end
case4:bne x20, x31, default
    srli x21, x22, 1
    j end
default: li x21 0

end: