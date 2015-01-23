# 437 Lab 2
# Everett Berry
# epberry@purdue.edu
#
# Multiplication in software
# Multiply 2 numbers by pushing to the stack
#
# Result in $2
#

# Base address and init stack
org 0x0000
ori $29, $0, 0xFFFC

# Multiply 5 (multiplier) by 2 (multiplicand)
ori $5, $0, 5
ori $4, $0, 2
push $5
push $4

# Pop inputs off stack
pop $10
pop $11

# Init result register
ori $2, $0, 0x0000

# Function does multiply
MULT:
beq $11, $0, END
addu $2, $2, $10
addi $11, $11, -1
j MULT

END:
HALT
