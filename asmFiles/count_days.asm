# Sheik Dawood
# Lab2 - Section3
# count_days.asm - Lab2
# Day count subroutine

	org 0x0000
	ori $29, $0, 0xFFFC
	#Day
	ori $4, $0, 15
	#Month
	ori $5, $0, 1
	#Year
	ori $6, $0, 2015
count_days:
	addi $6, $6, -2000
	push $6
	ori $1, $0, 365
	push $1
	jal mult
	pop $6
	addi $5, $5, -1
	push $5
	ori $1, $0, 30
	push $1
	jal mult
	pop $5
	add $1, $5, $6
	add $1, $1, $4
	halt


#Mult Subroutine
mult:	pop $2
	pop $3
	push $4 #mask
	push $6 #result
	ori $4, $0, 0x0001 #initialize mask to 1
	ori $6, $0, 0x0000 #initialize result to 0
loop:	and $1, $3, $4 #And mask and multiplier
	beq $1, $0, shift
	add $6, $6, $2 #Add (shifted) multipicand to result
shift:	sll $2, $2, 0x0001
	sll $4, $4, 0x0001
	bne $4, $0, loop
	ori $1, $6, 0x0000
	pop $6
	pop $4
	push $1
	jr $31
