# 437 Lab 2
# Everett Berry
# epberry@purdue.edu
#
# Count number of days since Jan 1 2000
#
###############################################################################
#                                                                             #
# Days = CurrentDay + (30 * (CurrentMonth - 1)) + 365 * (CurrentYear -2000)   #
#                                                                             #
###############################################################################

org 0x0000
ori $29, $0, 0xFFFC

ori $20, $0, 23       # Day
ori $21, $0, 1        # Month
ori $22, $0, 2015     # Year
ori $23, $0, 0        # Number of Days since

addi $24, $21, -1
ori $25, $0, 30

push $24
push $25
jal MULTIPLY
pop $26

addi $27, $22, -2000

ori $28, $0, 365

push $27
push $28
jal MULTIPLY
pop $19

add $18, $19, $26
add $17, $20, $18

END:
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
