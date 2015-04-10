# mbfi is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# mbfi is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with mbfi.  If not, see <http://www.gnu.org/licenses/>.

# TODO;
#	* Clean up code, remove some obvious redundancies
#	* Document the code with comments

.data
nl:	.asciiz	"\n"

p1:	.asciiz	"(I)nline or (F)ile: "
p2:	.asciiz "\n> "
p3:	.asciiz "\nFile Path (Absolute): "

e1:	.asciiz "ERROR: File not found"
e2:	.asciiz	"ERROR: Unbalanced brackets"
e3:	.asciiz "ERROR: Bounds exceeded"

strb:	.space 2	# Enough room for 1 character and a null terminator
pthb:	.space 256	# Room enough for a path with 255 characters.

store: 	.space 1024	# For storing the BF code, arbitrary size
labor:	.space 1024	# For code to operate on, arbitrary size; consider 5000
.text
start:
	la	$s0, store		# Where the code string is stored
	la	$s1, labor		# Where the operations and evaluations take place

	li	$v0, 4			# Prepare to print a string
	la	$a0, p1			# Adress of Prompt1
	syscall				# Ask if they want to do it inline or use a file
	
	li 	$v0, 8			# Prime the syscall to accept a string
	la 	$a0, strb		# Set the first argument to our buffer
	li 	$a1, 2			# Set our length to 1 character plus the terminator character		
	syscall
	
	lb	$t0, strb		# Get the char value in the buffer
	beq	$t0, 73, inline		# Handle I
	beq	$t0, 105, inline	# Handle i
	beq	$t0, 70, file		# Handle F
	beq	$t0, 102, file		# Handle f
					
					# Otherwise...
	li	$v0, 4			# Prepare to print a string
	la	$a0, nl			# Adress of newline
	syscall				# Incorrect input, ask again
	j start
	
inline:
	li	$v0, 4			# Prepare to print a string
	la	$a0, p2			# Adress of Prompt2
	syscall				# Give the > to let them know they can do line input
	
	li 	$v0, 8			# Prime the syscall to accept a string
	la 	$a0, store		# Set the first argument to our buffer
	li 	$a1, 1024		# Set our length to 1024, same size as the store array	
	syscall				# Accept the string
	
	j verify			# Time for the work to begin!
	
file:
	li	$v0, 4			# Prepare to print a string
	la	$a0, p3			# Adress of Prompt3
	syscall				# Ask them to give the absolute path
	
	li	$v0, 8			# Prepare to accept a string
	la	$a0, pthb		# The string goes in our path buffer
	li	$a1, 256		# Expect up to 255 characters (256 with null terminator)
	syscall
	
	# The string will normally have a newline in it because the user probably hit return, so we have to remove that
	la	$t1, pthb			# Let this be our way of keeping position
	findnl:
		lb	$t2, ($t1)		# Load the value of the byte at this point
		addi	$t1, $t1, 1
		bne	$t2, 10, findnl		# If we haven't hit \n yet, keep going
		addi	$t1, $t1, -1		# That previous addi moved us to the next byte, so we need to go back.
		sb	$zero, ($t1)		# Set the byte to null terminator
	
	li	$v0, 13			# Open file
	la	$a0, pthb		# Give it the file path
	li	$a1, 0			# Flag for read only
	li	$a2, 0			# Ignored...?
	syscall
	move	$t0, $v0		# Keep the file descriptor
	bltz	$t0, fileerror		# If there's an error, tell the user
	
	li	$v0, 14			# Prepare to read
	move	$a0, $t0		# Move in the file descriptor
	la	$a1, store		# Give it the code storage's address
	li	$a2, 1024		# Buffer size, same as store's
	syscall				# Read
	
	li	$v0, 16			# Prepare to close file
	move	$a0, $t0		# Move the descriptor into the argument
	syscall				# Close
	
	j verify			# On to the real deal now

verify:
	la	$t0, store		# Will move along the code
	li	$t1, 0			# Will keep track of bracket balance
	
	verifyloop:
		lb	$t2, ($t0)	# Load the character value
		seq	$t3, $t2, 91	# Screw branches! Let's just do some math.
		seq	$t4, $t2, 93	# 91 is open bracket, 93 is close
		add	$t1, $t1, $t3	# Add to balance if open bracket
		sub	$t1, $t1, $t4	# Subtract from balance number if close bracket
		addi	$t0, $t0, 1	# Increment the counter
		bnez	$t2, verifyloop	# Continue until we hit \0
	bnez	$t1, bracketerror	# Unbalanced brackets encountered!
		
mainloop:				# Main loop for going through the code
	lb 	$t0, ($s0)		# Load the byte (char) into $t0
	beqz 	$t0, exit		# If we reach the null terminator, then stop 
	move 	$a0, $t0		# Move the current character to our 1st argument
	jal 	actions			# Proceed to handle our argument
	
	addi	$s0, $s0, 1		# Add 1 to our position in the string
	j 	mainloop		# Do it all again!

actions:
	beq 	$a0, 43, inc		# Increment value at current memory location
	beq 	$a0, 45, dec		# Decrement value at current memory location
	beq 	$a0, 62, right		# Move to next memory position
	beq 	$a0, 60, left		# Move to previous memory position
	
	beq 	$a0, 46, output		# Output character at current memory location
	beq 	$a0, 44, input		# Input entered character into current memory location
	
	beq 	$a0, 91, open		# Check current pointer value; If zero, jump past matching ]
	beq 	$a0, 93, close		# Check current pointer value; If nonzero, jump back to matching [
	
	jr 	$ra			# If none of these happen, then just jump back to the address
	
	inc:
		addi	$sp, $sp, -4	# Move the stack pointer back
		sw	$t0, ($sp)	# Store whatever is at t0 on the stack
		
		lb 	$t0, ($s1)	# Load byte at current position
		addi 	$t0, $t0, 1	# Increment the value
		sb 	$t0, ($s1)	# Write this new value back to that position
		
		lw	$t0, ($sp)	# Load the word stored on the stack to t0
		addi	$sp, $sp, 4	# Restore the stack pointer to its previous position
		jr 	$ra		# Jump back to the return address
	
	dec:
		addi	$sp, $sp, -4	# Move the stack pointer back
		sw	$t0, ($sp)	# Store whatever is at t0 on the stack
		
		lb 	$t5, ($s1)	# Load byte at current position
		subi 	$t5, $t5, 1	# Decrement the value
		sb 	$t5, ($s1)	# Write the new value back to the position
		
		lw	$t0, ($sp)	# Load the word stored on the stack to t0
		addi	$sp, $sp, 4	# Restore the stack pointer to its previous position
		jr 	$ra		# Jump back to the return address
	
	right:
		addi 	$s1, $s1, 1	# Add 1 to the current position
		jr 	$ra		# Jump back to the linked address
		
	left:
		subi 	$s1, $s1, 1	# Subtract 1 from the current memory position
		jr 	$ra		# Jump back to the linked address
	
	output:
		li 	$v0, 11		# Prime the syscall to print char's.
		lb 	$a0, ($s1)	# Load the byte from the current memory address
		syscall			# Print the character out
		jr 	$ra		# Jump back to the linked address
		
	input:
		li 	$v0, 8		# Prime the syscall to accept a string
		la 	$a0, strb	# Set the first argument to our buffer
		li 	$a1, 2		# Set our length to 1 character plus the terminator character		
		syscall
		lb 	$v0, strb	# Load the byte at the string buffer
		sb 	$v0, ($s1)	# Store the value back into the current memory address
		jr 	$ra		# Jump back to the linked address
	
	open:
		addi	$sp, $sp, -12	# Move the stack pointer back for 3 words
		sw	$t0, 8($sp)	# Store whatever is at t0 on the stack
		sw	$t1, 4($sp)	# Store whatever is at t1 on the stack
		sw	$t2, 0($sp)	# Store whatever is at t2 on the stack
		
		lb 	$t0, ($s1)
		li 	$t1, 1
		beqz 	$t0, findclose
		j 	openfinish
		findclose:
			addi 	$s0, $s0, 1
			lb 	$t2, ($s0)
			beq 	$t2, 91, fcnestadd
			beq 	$t2, 93, fcnestsub
			j 	findclose
			fcnestadd:
				addi	$t1, $t1, 1
				j 	findclose
			fcnestsub:
				subi $t1, $t1, 1
				bnez $t1, findclose
				
		openfinish:
			lw	$t0, 8($sp)	# Load whatever is third on the stack
			lw	$t1, 4($sp)	# Store whatever is second on the stack
			lw	$t2, 0($sp)	# Store whatever is first on the stack
			addi	$sp, $sp, 12	# Move the stack pointer forward
			jr	$ra		# Jump to the return address
	
	close:
		addi	$sp, $sp, -12	# Move the stack pointer back for 3 words
		sw	$t0, 8($sp)	# Store whatever is at t0 on the stack
		sw	$t1, 4($sp)	# Store whatever is at t1 on the stack
		sw	$t2, 0($sp)	# Store whatever is at t2 on the stack
		
		lb $t0, ($s1)
		li $t1, 1
		bnez $t0, findopen
		j closefinish
		findopen:
			subi 	$s0, $s0, 1
			lb 	$t2, ($s0)
			beq 	$t2, 93, fonestadd
			beq 	$t2, 91, fonestsub
			j 	findopen
			fonestadd:
				addiu 	$t1, $t1, 1
				j 	findopen
			fonestsub:
				subiu 	$t1, $t1, 1
				bnez 	$t1, findopen
				
		closefinish:
			lw	$t0, 8($sp)	# Load whatever is third on the stack
			lw	$t1, 4($sp)	# Store whatever is second on the stack
			lw	$t2, 0($sp)	# Store whatever is first on the stack
			addi	$sp, $sp, 12	# Move the stack pointer forward
			jr	$ra			# Jump to the return address

fileerror:
	li	$v0, 4		# Tell it we're gonna print a string
	la	$a0, e1		# Give it the address of the 404 error string
	syscall			# Print
	j exit
	
bracketerror:
	li	$v0, 4		# Tell it we're gonna print a string
	la	$a0, e2		# Give it the address of the unbalanced error string
	syscall			# Print
	j exit

exit:
	li 	$v0, 10		# Prepare to exit
	syscall			# Exit
