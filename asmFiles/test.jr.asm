	org 0x0000
	ori $29, $0, 0xFFFC
	ori $4, $0, 0x0002
	ori $5, $0, 0x0008
	ori $11, $0, 0x0100
	push $4
	push $5
	jal mult
	sw $2, 0($11)
	halt

#Mult Subroutine - $2 and $3 are bound to change
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
	subu $31, $31, $0
	addu $31, $31, $0
	jr $31
