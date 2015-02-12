# TODO;
#	* Turn user input as single char string into byte value
#	* Check on bracket balance before running (Maybe left and right, too?). Could be done while running.
#	* Clean up code, remove some obvious redundancies
#	* Document the code with comments
#	* Implement user freedoms

.data
#Hello World! simple
#code:	.asciiz "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."

#Hello World! complex
#code:	.asciiz ">++++++++[<+++++++++>-]<.>>+>+>++>[-]+<[>[->+<<++++>]<<]>.+++++++..+++.>>+++++++.<<<[[-]<[-]>]<+++++++++++++++.>>.+++.------.--------.>>+.>++++."

#Square numbers up to 10,000
#code:	.asciiz "++++[>+++++<-]>[<+++++>-]+<+[>[>+>+<<-]++>>[<<+>>-]>>>[-]++>[-]+>>>+[[-]++++++>>>]<<<[[<++++++++<++>>-]+<.<[>----<-]<]<<[>>>>>[>>>[-]+++++++++<[>-<-]+++++++++>[-[<->-]+[<<<]]<[>+<-]>]<<-]<<-]"


loc:	.byte 0 : 1000			# Arbitrary size; consider 5000


.text
la $s0, code				# Address of the asciiz code
la $s1, loc				# Address of where pointer movement and actions occur

loop:					# Main loop for going through the code
	lb $t1, ($s0)			# Load the byte (char) into $t1
	beqz $t1, exit			# If we reach the null terminator, then stop 
	move $a0, $t1			# Move the current character to our 0th argument
	jal actions			# Proceed to handle our argument
	
	addi $s0, $s0, 1		# Add 1 to our position in the string
	j loop				# Do it all again!

exit:					# Exit cleanly
	li $v0, 10
	syscall

actions:
	beq $a0, 43, inc		# Increment value at current memory location
	beq $a0, 45, dec		# Decrement value at current memory location
	beq $a0, 62, right		# Move to next memory position
	beq $a0, 60, left		# Move to previous memory position
	
	beq $a0, 46, output		# Output character at current memory location
	beq $a0, 44, input		# Input entered character into current memory location
	
	beq $a0, 91, open		# Check current pointer value; If zero, jump past matching ]
	beq $a0, 93, close		# Check current pointer value; If nonzero, jump back to matching [
	
	jr $ra				# If none of these happen, then just jump back to the address
	
	inc:
		lb $t5, ($s1)		# Load byte at current position
		addi $t5, $t5, 1	# Add 1 to its value
		sb $t5, ($s1)		# Write this new value back to that position
		jr $ra			# Jump back to linked address
	
	dec:
		lb $t5, ($s1)		# Load byte at current position
		subi $t5, $t5, 1	# Subtract 1 from its value
		sb $t5, ($s1)		# Write the new value back to the position
		jr $ra			# Jump back to the linked address
	
	right:
		addiu $s1, $s1, 1	# Add 1 to the current position
		jr $ra			# Jump back to the linked address
		
	left:
		subiu $s1, $s1, 1	# Subtract 1 from the current memory position
		jr $ra			# Jump back to the linked address
	
	output:
		li $v0, 11		# Prime the syscall to print char's.
		lb $a0, ($s1)		# Load the byte from the current memory address
		syscall			# Print the character out
		jr $ra			# Jump back to the linked address
		
	input:
		li $v0, 5		# Prime the syscall to accept integers
		syscall			# Accept input
		sb $v0, ($s1)		# Store the value back into the current memory address
		jr $ra			# Jump back to the linked address
	
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
				jr $ra
