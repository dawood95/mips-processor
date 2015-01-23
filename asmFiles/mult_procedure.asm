# 437 Lab 2
# Everett Berry
# epberry@purdue.edu
#
# Multiply 3 numbers using a procedure and the stack
#

# Base address, init stack, add 1 item
org 0x0000
ori $29, $0, 0xFFFC
ori $28, $0, 0xFFF8

# Inputs onto stack
ori $3, $0, 3
ori $4, $0, 4
ori $5, $0, 5
push $3
push $4
push $5

# Calls multiply procedure
LOOP:
  beq $29, $28, END
  jal MULTIPLY
j LOOP

# Get result
END:
pop $6
HALT

# Procedures
MULTIPLY:
  ori $2, $0, 0x0000

  pop $10
  pop $11

  MULT:
    beq $11, $0, EXIT
    addu $2, $2, $10
    addi $11, $11, -1
  j MULT

  EXIT:
  push $2
jr $31
