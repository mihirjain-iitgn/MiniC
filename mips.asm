.data
     newline: .asciiz " " 
.text
main:
sw $t8,-4($sp)
sw $ra,-8($sp)
move $t8, $sp
addi $sp, $sp,-16
li $t0,0
sw $t0,-12($t8)
addi $v0, $zero, 5
syscall
move $t0,$v0
sw $t0,-12($t8)
li $t0,0
sw $t0,-16($t8)
lw $t0,-12($t8)
sw $t0, -12($sp)
jal fib
move $t0,$v0

sw $t0,-16($t8)
lw $t0,-16($t8)
move $a0,$t0
addi $v0,$zero,1
syscall
li $v0, 4
la $a0, newline
syscall
li $v0, 10
syscall
fib:
sw $t8,-4($sp)
sw $ra,-8($sp)
move $t8, $sp
addi $sp, $sp,-24
li $t0,0
sw $t0,-16($t8)
li $t0,0
sw $t0,-20($t8)
li $t0,0
sw $t0,-24($t8)
li $t0,2
sw $t0,-4($sp)
addi $sp,$sp,-4
lw $t0,-12($t8)

sw $t0 -4($sp)
addi $sp,$sp,-4
lw $t1,0($sp)
addi $sp,$sp,4
lw $t0,0($sp)
addi $sp,$sp,4
sge $t0,$t0,$t1

beq $t0, $0, else0
lw $t0,-12($t8)
sw $t0,-4($sp)
addi $sp,$sp,-4
li $t0,1

sw $t0,-4($sp)
addi $sp,$sp,-4
lw $t1,0($sp)
addi $sp,$sp,4
lw $t0,0($sp)
addi $sp,$sp,4
seq $t0,$t0,$t1

beq $t0, $0, else1
li $t0,0

sw $t0,-16($t8)
j ifEnded1
else1:
li $t0,1

sw $t0,-16($t8)
ifEnded1:
j ifEnded0
else0:
lw $t0,-12($t8)
sw $t0 -4($sp)
addi $sp,$sp,-4
li $t0,1

sw,$t0 -4($sp)
addi $sp,$sp,-4
lw $t1,0($sp)
addi $sp,$sp,4
lw $t0,0($sp)
addi $sp,$sp,4
sub $t0,$t0,$t1

sw $t0,-20($t8)
lw $t0,-12($t8)
sw $t0 -4($sp)
addi $sp,$sp,-4
li $t0,2

sw,$t0 -4($sp)
addi $sp,$sp,-4
lw $t1,0($sp)
addi $sp,$sp,4
lw $t0,0($sp)
addi $sp,$sp,4
sub $t0,$t0,$t1

sw $t0,-24($t8)
lw $t0,-20($t8)
sw $t0, -12($sp)
jal fib
move $t0,$v0
sw $t0 -4($sp)
addi $sp,$sp,-4
lw $t0,-24($t8)
sw $t0, -12($sp)
jal fib
move $t0,$v0

sw,$t0 -4($sp)
addi $sp,$sp,-4
lw $t1,0($sp)
addi $sp,$sp,4
lw $t0,0($sp)
addi $sp,$sp,4
add $t0,$t0,$t1

sw $t0,-16($t8)
ifEnded0:
lw $t0,-16($t8)
move $v0,$t0
addi $sp, $sp, 24
lw $t8,-4($sp)
lw $ra,-8($sp)
jr $ra
