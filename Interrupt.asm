#Jamar Fraction
#CPTS 260
#HW12

.text

#Receiver control
li $a0, 0xffff0000
lw $t0, 0($a0)


#set bit 1 to enable input interrupts
ori $t0, 0x02       

#update Receiver control                         
sw $t0, 0($a0)    

#Transmitter control ready bit
li $a1, 0xffff0008
lw $t0, 0($a1)

#set bit zero to enable transmission control ready
ori $t0, 0x01

#update transmission control
sw $t0, 0($a1) 




#Loop that does nothing
LOOP:
addi $s0, $s0, 1
addi $s0, $s0, -1
j LOOP

#Handler Code
myIntHandler:

#store the return address
addi $sp, $sp, -4
sw $ra, 0($sp)

jal RETRIEVE

#move the retrieved bit to the $a0 for storage in the expBuffer
move $a0, $v0

#store the latest char
jal STORE

#Check if the byte stored was an = sign
li $t2, '='
bne $v0, $t2, EXITHANDLER

#Perform the evaluation
jal EVALUATE

#$v0 now represents the result
move $a0, $v0
jal CONVERTANDSTORE

jal SENDTODISPLAY

EXITHANDLER:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
#////////////////////////////////////////////////
#////////////////////////////////////////////////
#Functions
SENDTODISPLAY:

#Buffer length in decimal
lw $t0, expBufferLength

#Loop control vars
li $t1, 0
la $t2, expBuffer
li $v0, 0

DISPLAYLOOP:
beq $t0, $t1, EXITDISPLAYLOOP

li $t3, 0xffff0008
li $t4, 0xffff000C

#$t2 = expBuffer[$t1]
add $t2, $t2, $t1

wrpoll:

lb $v0, 0($t3)
andi $v0, $v0, 0x01 
beq $v0, $zero, wrpoll 

lb $t5, 0($t2)
sb $t5, 0($t4) 

addi $t1, $t1, 4
j DISPLAYLOOP

EXITDISPLAYLOOP:
  
jr $ra



CONVERTANDSTORE:
addi $sp, $sp, -4
sw $ra, 0($sp)

#Load 10 into $t0 for compare
li $t0, 0x0A

bge $a0, $t0, TENORGREATER
jal STORE
j END

TENORGREATER:
#original $a0
addi $s0, $a0, 0

#load the number 1
li $t0, 0x01

#store 1
move $a0, $t0
jal STORE

#convert the remainder
addi $s0, $s0, -10
move $a0, $s0
jal CONVERTTOHEX

#store the remainder
move $a0, $v0
jal STORE


END:
#restore return address
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra



RETRIEVE:
lbu $v0, 0xffff0004
jr $ra



EVALUATE:
#store the return address
addi $sp, $sp, -4
sw $ra, 0($sp)

#Perform the math
# $s1 + $s2 = $v0
# $s1
li $t0, 0
la $t1, expBuffer
add $t1, $t1, $t0
lb $a0 ($t1) 
jal CONVERTTODECIMAL
move $s1, $v0

# $s2
li $t0, 8
la $t1, expBuffer
add $t1, $t1, $t0
lb $a0 ($t1) 
jal CONVERTTODECIMAL
move $s2, $v0

#Add the 2 values
add $v0, $s1, $s2

#restore return address
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra



CONVERTTODECIMAL:
addi $v0, $a0, -48
jr $ra



CONVERTTOHEX:
addi $v0, $a0, 48
jr $ra


STORE:
lw $t0, expBufferLength

la $t1, expBuffer

# $t1 = expBuffer[expBufferLength]
add $t1, $t1, $t0

#Store the byte in $a0 to the expBuffer[expBufferLength]
sb $a0, 0($t1)

#increase the buffer length
addi $t3, $t0, 4
sw $t3, expBufferLength

jr $ra
#////////////////////////////////////////////////
#////////////////////////////////////////////////



.data
expBuffer: .space 60
expBufferLength: .word 0




#////////////////////////////////////////////////
#////////////////////////////////////////////////
.ktext 0x80000180
#get cause
mfc0 $k0, $13

#Extract ExcCode Field
srl $k0, $k0, 2	
andi $k0, $k0, 0x1f

#Check for keyboard hardware interrupt code
bnez $k0, RECOVERANDEXIT

#Only dealing with hardware interrupt
la $k0, myIntHandler
jalr $k0

#reset cause register
mtc0 $zero, $13
mfc0 $k0, $12

# clear EXL bit
andi $k0, 0xfffd

#Interrupts enabled
ori  $k0, 0x11				
mtc0 $k0, $12

RECOVERANDEXIT:
#recover all registers

#get out of here
eret

.kdata


