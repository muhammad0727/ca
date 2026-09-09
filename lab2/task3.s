
main:
    #initializing the array with indexes
    # x22=i, x23=sum, 0x200=a (base location)
    #loading the numbers
    li x22, 0
    li x24, 0x200 
    li x25, 10

    # for
for:blt x22, x25, work
    j reset
work: 
    sw x22, 0(x24)
    addi x22, x22, 1
    addi x24, x24, 4
    j for
reset:

# summing the numbers of the array in var (sum)
    li x22, 0
    li x24, 0x200 

for1: blt x22, x25, work1
    j end

# loading the value of a[i] in x30
work1: lw x30, 0(x24)
    add x23, x23, x30
    addi x22, x22, 1
    addi x24, x24, 4

    j for1
end: