.data
Stack_Top: 	              #Allocates memory
Stack_End:         .word 0:80 

Simon_Array: .word 0:80

Error_Width:   .asciiz "Error: Horizontal line is too long\n"

.data

ColorTable: 
	.word 0x000000     #black
	.word 0xffff00     #yellow
	.word 0x0000ff     #blue
	.word 0x00ff00     #green
	.word 0xff0000     #red
	.word 0xffffff	   #white
	
BoxTable:
	.word 0, 16, 5	   #Coordinate for Horizontal divider
	.word 4, 4, 1      #Box 1, Upper Left, Yellow 
	.word 20, 4, 2    #Box 2, Upper Right, Blue, 
	.word 4, 20, 3     #Box 3, Bottom Left, Green,
	.word 20, 20, 4    #Box 4, Bottom Right, Red
	.word 16, 0, 5     #Coordinate for Vertical divider 
	
	
BlinkTimes:
	.word 750	   #Millisecond Time for Simon box blinking
	.word 400
	.word 100
	

.text
la $sp, Stack_End	#point $sp to memory stack

######## Main Function #############
MAIN:

jal Init		   #Initialize program, seeds random value

jal DrawQuadrants           #Draws the quadrants on the bitmap
 
loopAgain:
add $s3, $s3, 1		   #Loop counter 
jal GetRandNum		   #Reqests next random number to

add $a0, $0, $v0	   #Pass return from GetRandNumb to AddNumbToSimonStack 
jal AddNumbToSimonStack    #Calls fucntion to add random number onto Simon stack

jal BlinkLights		   #Blinks the simon square(s)

jal ReadMemoryMatch
blt $s3, 5, loopAgain

add $s3, $0, $0		   #Clear long term storage

exit:li   $v0, 10          #system call for exit
syscall                    # Exit!

######### Fuction that Reads User Memory Match ############
### $v1 1 if matches sequence, 0 if failed
###########################################################
ReadMemoryMatch:
add $t0, $0, $s0	#Total number of numbers on Simon stack
la $t1, Simon_Array
lw $t2, -4($t1) 

matchLoop:
add $v1, $0, 1		#Set return for Succesful match
beqz $t0, exitMatch
lw $t2, 4($t1) 

li $v0, 12             #specify read char
syscall
add $t3, $0, $v0	#Moves return to temp reg

li $a0, 10              #load char value into arg for new line
li $v0, 11	        #cmd to print char,
syscall

add $t3, $t3, -30      #Adjust hex ascii value to decimal
add $t0, $t0, -4	#Decrement remaining simon stack words
beq $t3, $t2, matchLoop	#Continue if user matches number

add $v1, $0, $0		#Return failed

exitMatch:
jr $ra

######## Function to initalize the program, seeds random value ##########
Init:
#addi $sp, $sp, -4	 
#sw $ra, 0($sp)          #Store stackpointer for $ra

li $v0, 30               #Syscall for time system, returns current time
syscall

add $a1, $a0, $0	  #Copy return value for milliseconds into seed value
add $a0, $0, $0		  #Set ID of generator

li $v0, 40                #specify read char
syscall	

#lw $ra, 0($sp)          #Store stackpointer for $ra
#addi $sp, $sp, 4

jr $ra

#####Add new number to sequence ######
### v0 return a random number #######
GetRandNum:
add $a0, $0, $0	         #Generator 0, we only are using one generator for this lab
sw $ra, 4($sp)           #Store stackpointer for $ra

add $a1, $0, 4	         #Specify the limit on the range
li $v0, 42               #specify read char
syscall
add $a0, $a0, 1		 #Add to return, range will be 1-4

add $v0, $0, $a0

jr $ra

####Add a new number to Simon Stack#######
### a0 number to store
#########################################
AddNumbToSimonStack:	
add $s0, $s0, 4		 #Increment total values on simon stack, 4=1

add $t0, $0, $sp         #Temp store for current address Stack_End

la $sp, Simon_Array     #Move pointer to simon stack
sub $sp, $sp, $s0	 #Allocate new memory on stack, moving to next memory address

sw $a0, 4($sp)	         #Add value to simon stack
la $s1, 0($sp)		 #Store current address for Simon Stack
la $sp, 0($t0)		 #Restore stack pointer to address on Stack_End

jr $ra

############ Function to Blink Simon Box ###################
### $a0 Simon Box Reqest
### $a1 $a2 Blink time "Milliseconds"
##########################################################
BlinkSimonBox:
addiu $sp, $sp, -16     #Allocate space on stack to save ra
sw $ra, 12($sp)	        #Store ra
sw $a0, 8($sp)	        #Store Box Number requested
sw $a1, 4($sp)		#Store Blink time

la $t0, BoxTable	#Load address of array on stack	
lw $a0, 0($t0)		#Load word for x variable of horiz divider
lw $a1, 4($t0)          #Load word for y variable of horiz divider
lw $a2, 8($t0)          #Load word for pixel color
add $a3, $0, 32		#Length of line

lw $t1, 8($sp)		#Request Simon box number, original a0
mul $t1, $t1, 12	#Requested box number address offset
la $t0, BoxTable	#Load address of array of boxes
add $t0, $t0, $t1	#Address of Requested Box
sw $t0, 0($sp)		#Store Address of BoxTable + Offset

lw $a0, 0($t0)		#Load word for x variable of horiz divider
lw $a1, 4($t0)          #Load word for y variable of horiz divider
lw $a2, 8($t0)          #Load word for requested box color
add $a3, $0, 8		#Length of line

jal DrawBox
lw $ra, 12($sp)	       #Restore ra

lw $a0, 4($sp)	       #Load arguement for pause time before "Blink time"

jal Pause
lw $ra, 12($sp)	       #Restore ra

lw $t0, 0($sp)		#Rstore Address of BoxTable + Offset
lw $a0, 0($t0)		#Load word for x variable of horiz divider
lw $a1, 4($t0)          #Load word for y variable of horiz divider
lw $a2 ColorTable           #Load word for BLACK box color, erases the box
add $a3, $0, 8		#Length of line

jal DrawBox

lw $ra, 12($sp)	       #Restore ra
lw $a0, 8($sp)	       #Restore Box Number requested
lw $a1, 4($sp)	       #Restore Blink time

addiu $sp, $sp, 16       #Move back up stack to

jr $ra

########## Blink Lights #############
#####################################
BlinkLights:
addiu $sp, $sp, -24     #Allocate space on stack to save ra
sw $ra, 20($sp)	        #Store ra
sw $t2, 16($sp)

add $s4, $0, $sp        #Temp store for current address Stack_End

la $sp, Simon_Array	#Load address of where the Simon values are stored
lw $a0, 0($sp)		#Load first box to blink from Simom Stack
la $sp, ($s4)		#Move Stack pointer back to nested functions

la $t4, BlinkTimes	#Load address to check blink speed
lw $a1, 0($t4)		#Blink Speed Beginner
beqz $s5, Blink		#Start Blinking when level 0
lw $a1, 4($t4)		#Blink Speed Intermediate
beq $s5, 1, Blink	#Start Blinking when level 1
lw $a1, 8($t4)		#Blink Speed Expert

#li $v0, 1		#Syscall to print int
#syscall 

Blink:
jal BlinkSimonBox	#Blinks the simon square
lw $ra, 20($sp)	        #Restore ra

#li $a0, 10             #load char value into arg for new line
#li $v0, 11	        #cmd to print char,
#syscall

ble $s0, 4, exitBLoop	#When only on value, no traversal through Simon Stack, exit function

add $t1, $0, $0		#Initialize loop counter
add $t2, $0, $s0	#Use temp to hold total amount of bytes to traverse
la $t3, Simon_Array	#Use temp to hold Step address, used for decrementing down Simon Stack		
add $t3, $t3, 4		#Correct address offset

bLoop:
add $t1, $t1, 4		#Clear loop counter
addi $t3, $t3, -4	#Increment to next value on Simon stack
lw $a0, 0($t3)		#Load next box value for BlinkSimonBox
#li $v0, 1		#Syscall to print int
#syscall

sw $t2, 16($sp)		#Store temps, bound to change in nested functions
sw $t1, 8($sp)
sw $t2, 4($sp)
sw $t3, 0($sp)

la $t4, BlinkTimes	#Load address to check blink speed
lw $a1, 0($t4)		#Blink Speed Beginner
beqz $s5, blinkNext	#Blink when level 0
lw $a1, 4($t4)		#Blink Speed Intermediate
beq $s5, 1, blinkNext	#Blink when level 1
lw $a1, 8($t4)		#Blink Speed Expert

blinkNext:jal BlinkSimonBox
lw $ra, 20($sp)	        #Restore ra and temp registers
lw $t2, 16($sp)		
lw $t1, 8($sp)
lw $t2, 4($sp)
lw $t3, 0($sp)

#li $a0, 10              #load char value into arg for new line
#li $v0, 11	         #cmd to print char,
#syscall

blt $t1, $t2, bLoop	#Check to see if total values have been traversed

exitBLoop:

#la $sp, 0($s4)

jr $ra

######### Function to Lookup Color from ColorTable #############
LookupColor:
la $t1, ColorTable
beq $a2, 0, colorBlack
beq $a2, 1, colorYellow
beq $a2, 2, colorBlue
beq $a2, 3, colorGreen
beq $a2, 4, colorRed
beq $a2, 5, colorWhite

colorBlack: lw $t0, 0($t1)
j returnColor

colorYellow: lw $t0, 4($t1)
j returnColor

colorBlue: lw $t0, 8($t1)
j returnColor

colorGreen: lw $t0, 12($t1)
j returnColor

colorRed: lw $t0, 16($t1)
j returnColor

colorWhite: lw $t0, 20($t1)
j returnColor

returnColor:
add $v1, $0, $t0

jr $ra

########### Function to Draw the Quadrants ########
###################################################
DrawQuadrants:

addiu $sp, $sp, -4     #Allocate space on stack to save ra
sw $ra, 0($sp)	       #Store ra 

la $t0, BoxTable	#Load address of array on stack	
lw $a0, 0($t0)		#Load word for x variable of horiz divider
lw $a1, 4($t0)          #Load word for y variable of horiz divider
lw $a2, 8($t0)          #Load word for white pixel color
add $a3, $0, 32		#Length of line

jal DrawHorizLine 

lw $ra, 0($sp)	       #Restore ra 

la $t0 BoxTable
lw $a0, 60($t0)		#Load word for x variable of horiz divider
lw $a1, 64($t0)         #Load word for y variable of horiz divider
lw $a2, 68($t0)         #Load word for white pixel color
add $a3, $0, 32		#Length of line

jal DrawVertLine

lw $ra, 0($sp)	       #Store ra 
addiu $sp, $sp, 4      #Move back up stack

jr $ra

########### Function to Draw a Box ###########
## $a0 for x 0-31
## $a1 for y 0-31
## $a2 for color number 0-7
## $a3 = size of the box 
##############################################
DrawBox:
addiu $sp, $sp, -24     #Open up two words on stack
sw $ra, 20($sp)		#Store ra
sw $a0, 16($sp)		#Store a0
sw $a1, 12($sp)		#Store a1
sw $a2, 8($sp)		#Store a2
sw $a3, 4($sp)		#Store a3
sw $s2, 0($sp)		#Store a4

add $s2, $0, $a3	#Copy a3 to temp reg

BoxLoop:
lw $a0, 16($sp)		#Store a0
lw $a1, 12($sp)		#Store a1
lw $a2, 8($sp)		#Store a2
lw $a3, 4($sp)		#Store a3

jal DrawHorizLine	#Draw current row
add $a1, $a1, 1		#Increment Y coordinate
sw $a1, 12($sp)		#Reload a1
lw $a3, 4($sp)		#Reload a3

addiu $s2, $s2, -1	#Decrement remaining rows left
bne $s2, $0, BoxLoop	#Continue when more rows are left

lw $ra, 20($sp)		#Restore ra
lw $s2, 0($sp)		#Restore a4
addiu $sp, $sp, 24      #Restore position of stack pointer
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

add $t0, $0, 32 	#Max Width of Bitmap
sub $t0, $t0, $a0	#Current distance to wall

ble $a3, $t0, HorizLoop
la $a0 Error_Width
li $v0, 4
syscall
j exit
		
HorizLoop:
jal DrawDot
add $a3, $a3, -1
add $a0, $a0, 1
bne $a3, $0, HorizLoop

add $ra, $ra, 4

lw $a1, 4($sp)		#restore register, DrawDot could change them
lw $a2, 0($sp)

lw $ra, 8($sp)		#restore return address
addi $sp, $sp, 12	#move stack pointer back up

jr $ra

######Function to Draw a Vertical Line #########
## $a0 for x 0-31
## $a1 for y 0-31
## $a2 for color number 0-7
## $a3 length of the horizontal line
#####################################
DrawVertLine:
addi $sp, $sp, -12	#store all changable variables to stack
sw $ra, 8($sp)		#Store return address on stack
sw $a1, 4($sp)		#Store a registers that could change
sw $a2, 0($sp)	

add $t0, $0, 32 	#Max Height of Bitmap
sub $t0, $t0, $a1	#Current distance to wall

ble $a3, $t0, VertLoop
la $a0 Error_Width
li $v0, 4
syscall
j exit
		
VertLoop:
jal DrawDot
add $a3, $a3, -1
add $a1, $a1, 1
bne $a3, $0, VertLoop

add $ra, $ra, 4

lw $a1, 4($sp)		#restore register, DrawDot could change them
lw $a2, 0($sp)

lw $ra, 8($sp)		#restore return address
addi $sp, $sp, 12	#move stack pointer back up

jr $ra

######Function to Draw a Dot#########
## $a0 for x 0-31
## $a1 for y 0-31
## $a2 for color number 0-7 #########
DrawDot:
addiu $sp, $sp, -8      #Open up two words on stack
sw $ra, 4($sp)		#Store ra
sw $a2, 0($sp)		#Store original a2

jal CalcAddress  #$v0 Las address for pixel
lw $a2, 0($sp)		#Restore a2
sw $v0, 0($sp)		#Store v0

jal LookupColor     	#$v1 has color 
lw $v0, 0($sp)    	#Restore v0

sw $v1, 0($v0)   	#make dot (color pixel)

lw $ra, 4($sp)		#Restore original ra
addiu $sp, $sp, 8	#Move sp back up stack

jr $ra

########### Function to clear display (256 x 256 Bitmap Display) ####
#####################################################################
ClearDisplay:
addiu $sp, $sp, -4     #Allocate space on stack to save ra
sw $ra, 0($sp)	       #Store ra 
add $a0, $0, $0	       #Hardcoded addres to start on (0,0) of 256 x 256 pixel Bitmap Display
add $a1, $0, $0
add $a2, $0, $0	       #Hardcoded color - black
add $a3, $0, 32

jal DrawBox

lw $ra, 0($sp)	      #Restore ra
addiu $sp, $sp, 4     #Clear ra data off the stack

jr $ra

######Function to Retrieve Bitmap Display Address ###########
## $a0 for x 0-31
## $a1 for y 0-31
## $v0 address for color a pixel
#############################################################
CalcAddress:
add $t0, $0, 0x10040000	#Starting address on Bitmap Display 0,0

mul $t1, $a1, 32		#Set offset for y
mul $t1, $t1, 4

mul $t2, $a0, 4

add $t1, $t1, $t2
add $v0, $t0, $t1

jr $ra

############## Function to Pause ##################
##### a0 Pause time "Milliseconds"
##############################################
Pause:
add $t4, $0, $a0      #Copy store time in temp register

add $t0, $0, $0       #Clear registers that will time comparison test
add $t1, $0, $0

li $v0, 30            #Get current timestap
syscall

add $t0, $a0, $0      #Store initial timestap

timeLoop:
syscall		       #Call for time to compare
add $t1, $a0, $0       #store compare time
subu $t3, $t1, $t0     #Subtract new first time stamp from second 
bltu $t3, $t4, timeLoop #Check to see if time has elapsed

syscall

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

