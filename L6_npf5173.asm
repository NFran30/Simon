.data
Stack_Top: 	     #Allocates memory
Stack_End:    .word 0:80 

Simon_Array:  .word 0:80
Player_Array: .word 0:80

.data
ColorTable: 
	.word 0x000000     #black
	.word 0xffff00     #yellow
	.word 0x0000ff     #blue
	.word 0x00ff00     #green
	.word 0xff0000     #red
	.word 0xffffff	   #white

.text
la $sp, Stack_End	#point $sp to memory stack

######## Main Function #############
MAIN:

jal Init

loopAgain:
add $s3, $s3, 1
jal GetRandNum

jal AddNumbToSimonStack

jal BlinkLights
blt $s3, 20, loopAgain

li   $v0, 10               #system call for exit
syscall                    # Exit!

######## Function to initalize the program ##########
Init:
addi $sp, $sp, -4	 
sw $ra, 4($sp)          #Store stackpointer for $ra

li $v0, 30               #Syscall for time system, returns current time
syscall

add $a1, $a0, $0	  #Copy return value for milliseconds into seed value
add $a0, $0, $0		  #Set ID of generator

li $v0, 40                #specify read char
syscall	

lw $ra, 4($sp)          #Store stackpointer for $ra
addi $sp, $sp, 4

jr $ra

#####Add new number to sequence ######
GetRandNum:
add $a0, $0, $0	         #Generator 0, we only are using one generator for this lab
sw $ra, 4($sp)           #Store stackpointer for $ra

add $a1, $0, 4	         #Specify the limit on the range
li $v0, 42               #specify read char
syscall
add $a0, $a0, 1		 #Add to return, range will be 1-4

sw $a0, 4($sp)	         #store random value, returned in $a0

jr $ra

####Add Number to seq#######
AddNumbToSimonStack:
lw $a0, 4($sp)		
addi $sp, $sp, 4	 # Move pointer back up stack after popping number
add $s0, $s0, 4		 #Increment total values on simon stack, 4=1

add $t0, $0, $sp         #Temp store for current address Stack_End

la $sp, Simon_Array      #Move pointer to simon stack
sub $sp, $sp, $s0	 #Allocate new memory on stack, moving to next memory address

sw $a0, 4($sp)	         #Add value to simon stack
la $s1, 0($sp)		 #Store current address for Simon Stack
la $sp, 0($t0)		 #Restore stack pointer to address on Stack_End

jr $ra


########## Blink Lights #########
BlinkLights:
add $t0, $0, $sp        #Temp store for current address Stack_End

la $sp, Simon_Array	#Load address of where the Simon values are stored
lw $a0, 0($sp)
li $v0, 1		#Syscall to print int
syscall 

li $a0, 10              #load char value into arg for new line
li $v0, 11	        #cmd to print char,
syscall

ble $s0, 4, exitBLoop	#When only on value, no traversal through Simon Stack, exit function

add $t1, $0, $0		#Clear loop counter
bLoop:
add $t1, $t1, 4		#Clear loop counter
addi $sp, $sp, -4	#Increment to next value on Simon stack
lw $a0, 0($sp)
li $v0, 1		#Syscall to print int
syscall 

li $a0, 10              #load char value into arg for new line
li $v0, 11	        #cmd to print char,
syscall

blt $t1, $s0, bLoop	#Check to see if total values have been traversed

exitBLoop:

la $sp, 0($t0)

jr $ra

######### Function to Lookup Color from ColorTable #############
LookupColor:
la $a2, ColorTable
beq $a1, 0, colorBlack
beq $a1, 1, colorYellow
beq $a1, 2, colorBlue
beq $a1, 3, colorGreen
beq $a1, 4, colorRed
beq $a1, 5, colorWhite

colorBlack: lw $a2, 0($a2)
j returnColor

colorYellow: lw $a2, 4($a2)
j returnColor

colorBlue: lw $a2, 8($a2)
j returnColor

colorGreen: lw $a2, 12($a2)
j returnColor

colorRed: lw $a2, 16($a2)
j returnColor

colorWhite: lw $a2, 20($a2)
j returnColor

returnColor:
add $v1, $0, $a2

jr $ra

######Function to Draw a Dot#########
## $a0 for x 0-31
## $a1 for y 0-31
## $a2 for color number 0-7 #########
DrawDot:
addiu $sp, $sp, -8      #Open up two words on stack
sw $ra, 4($sp)		#Store ra
sw $a2, 0($sp)		#Store original a2

#jal CalcAddress  #$v0 Las address for pixel
lw $a2, 0($sp)		#Restore a2
sw $v0, 0($sp)		#Store v0

#jal GetColor     	#$v1 has color 
lw $v0, 0($sp)    	#Restore v0

sw $v1, 0($v0)   	#make dot  

lw $ra, 4($sp)		#Restore original ra
addiu $sp, $sp, 8	#Move sp back up stack

jr $ra

######Function to Draw a Horizontal Line#########
## $a0 for x 0-31
## $a1 for y 0-31
## $a2 for color number 0-7
## $a3 length of the horizontal line
#####################################
DrawHorizLine:
addi $sp, $sp, -12	#store all changable variables to stack
sw $ra, 8($sp)		#Store return address on stack
sw $a1, 4($sp)		#Store a registers that could change
sw $a2, 0($sp)

add $t0, $0, 31		#Set offset for x
mul $t0, $t0, 4
add $t1, $0, $0		#Clear reg

beq $a1, $0, HorizLoop	#No y adjustment needed when 0
add $t2, $0, $0 	#loop counter
yLoop: add $t1, $t1, 32	#Temp reg, Add in 32 bits to move down a row
add $t2, $t2, 1		#increment counter
blt $t2, $a1, yLoop	#Check condition to see if we are at reqested row
mul $a1, $t1, 4		#Adjust for 4 bytes

HorizLoop:
mul $a0, $t3, 4		#t3 is original a0, multiply by 4 bytes
add $a0, $a0, $t0	#add in offset for x

jal DrawDot

add $ra, $ra, 4

lw $a1, 4($sp)		#restore register, DrawDot could change them
lw $a2, 0($sp)

add $t3, $t3, 1		#Increment next pixel
add $a3, $a3, -1	#Decrement remaining horizontal line still to call
bne $a3, 0, HorizLoop	#Check to see if we are done

lw $ra, 8($sp)		#restore return address
addi $sp, $sp, 12	#move stack pointer back up

jr $ra

#Clear Seq
#Clear Display


#get Randn

#add to seq

#increment max

#blink lights , big section, for loop
#print number with syscall
#pause leave light on, then turn off,
#print new lines then conitiue


#User check, for loop
#get new entry from user, getChar Syscall
#compare with same spot in sequence
#if matches continue for loop, if not fail

