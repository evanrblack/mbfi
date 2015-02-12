.data
#code:	.asciiz "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
code:	.asciiz ">++++++++[<+++++++++>-]<.>>+>+>++>[-]+<[>[->+<<++++>]<<]>.+++++++..+++.>>+++++++.<<<[[-]<[-]>]<+++++++++++++++.>>.+++.------.--------.>>+.>++++."
loc:	.byte 0 : 1000


.text
la $s0, code
la $s1, loc

loop:
	lb $t1, ($s0)
	beqz $t1, exit
	move $a0, $t1
	jal actions
	
	addi $s0, $s0, 1
	j loop

exit:
	li $v0, 10
	syscall

actions:
	beq $a0, 43, inc
	beq $a0, 45, dec
	beq $a0, 62, right
	beq $a0, 60, left
	
	beq $a0, 46, output
	beq $a0, 44, input
	
	beq $a0, 91, open
	beq $a0, 93, close
	
	jr $ra
	
	inc:
		lb $t5, ($s1)
		addiu $t5, $t5, 1
		sb $t5, ($s1)
		jr $ra
	
	dec:
		lb $t5, ($s1)
		subiu $t5, $t5, 1
		sb $t5, ($s1)
		jr $ra
	
	right:
		addiu $s1, $s1, 1
		jr $ra
		
	left:
		subiu $s1, $s1, 1
		jr $ra
	
	output:
		li $v0, 11
		lb $a0, ($s1)
		syscall
		jr $ra
		
	input:
		li $v0, 5
		syscall
		sb $v0, ($s1)
		jr $ra
	
	open:
		lb $t5, ($s1)
		li $t6, 1
		beqz $t5, findclose
		jr $ra
		findclose:
			addiu $s0, $s0, 1
			lb $t7, ($s0)
			beq $t7, 91, fcnestadd
			beq $t7, 93, fcnestsub
			j findclose
			fcnestadd:
				addiu $t6, $t6, 1
				j findclose
			fcnestsub:
				subiu $t6, $t6, 1
				beqz $t6, exitfindclose
				j findclose
			exitfindclose:
				#addiu $s0, $s0, 1
				jr $ra
	
	close:
		lb $t5, ($s1)
		li $t6, 1
		bnez $t5, findopen
		jr $ra
		findopen:
			subiu $s0, $s0, 1
			lb $t7, ($s0)
			beq $t7, 93, fonestadd
			beq $t7, 91, fonestsub
			j findopen
			fonestadd:
				addiu $t6, $t6, 1
				j findopen
			fonestsub:
				subiu $t6, $t6, 1
				beqz $t6, exitfindopen
				j findopen
			exitfindopen:
				#addiu $s0, $s0, 1
				jr $ra
