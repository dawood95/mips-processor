# Sheik Dawood
# Lab2 - Section3
# mult_procedure.asm - Lab2
# multiplation_procedure subroutine

	org 0x0000
	ori $29, $0, 0xFFFC
	ori $1, $0, 0x0002
	push $1
	ori $1, $0, 0x0003	
	push $1
	ori $1, $0, 0x0004
	push $1
	jal mult_procedure
	pop $1
	halt

# Multiplication Procedure Subroutine
mult_procedure:
	ori $4, $0, 0xFFFC
check:	pop $2
	beq $29, $4, end
	pop $3
	push $31
	push $3
	push $2
	jal mult
	pop $2
	pop $31
	push $2
	j check
end:	push $2
	jr $31

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
