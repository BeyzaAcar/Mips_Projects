#------GENERAL RULES OF REGISTER USAGE------

# 1- A function always takes its arguments from a registers ($a0, $a1, $a2, $a3) 
# 2- A function can use $t0, $t1, $t2, $t3 registers without saving their values to the stack
# 3- A function must save its argument values in the stack for later use
# 4- A function must save the local variables in the stack for later use
# 5- A function must return its result in $v0 register
# 6- Because of the collision of some labels, I give different id numbers to the labels in the functions (e.g. outerLoop, outerLoop2, outerLoop3, etc.)
#	 And you can see the id numbers on the top of the functions with comments, every function has its own unique id number
# 7- A function must save the value of $ra register in the stack for later use if it calls another function
.data
	newline:    .asciiz "\n"
	grid:       .space 40000  # 200 * 200 grid, 20000 bytes
	r:          .word 0        # row 
	c:          .word 0        # column 
	n:          .word 0        # 
	promptRow:    .asciiz "Enter the row..: "
	promptColumn: .asciiz "Enter the column: "
	promptTime:    .asciiz "Enter the time: "
	promptGrid:    .asciiz "Enter the grid:\n"	

.text
					
	#the c code is:
		#void main()
		#{
		#	takeAllInputs();
		#	initializeFirstBombs();
		#	timePasses();
		#	while(n>0)
		#	{
		#		timePasses();
		#		explodeBomb();
		#		if(n<=0) break;
		#		fillWithBombs();
		# 		timePasses();
		#       explodeBomb();
		#	}
		#	printGrid();
		#}
	
	main: #(void) main()
		#the main function
		#there are no arguments so we dont need to expand the stack (RULE 4 of GENERAL RULES OF REGISTER USAGE)
		# s2 = i, s3 = j
		li $s2, 0 #i=0
		li $s3, 0 #j=0
		li $t0, 0 #t0=0
		li $t1, 0 #t1=0

		jal takeAllInputs #call takeAllInputs()
		jal initializeFirstBombs #call initializeFirstBombs()
		jal timePasses #call timePasses()

		#while(n>0)
		whileLoop:
			#check if n>0
			lw $t0, n #t0=n
			li $t1, 0 #t1=0
			ble $t0, $t1, whileLoopEnd #if n<=0, go to whileLoopEnd

			whileLoopBody:
				jal timePasses #call timePasses()
				jal explodeBomb #call explodeBomb()

				#if(n<=0) break;
				lw $t0, n #t0=n
				li $t1, 0 #t1=0
				ble $t0, $t1, whileLoopEnd  #if n<=0, go to whileLoopEnd

				jal fillWithBombs #call fillWithBombs()
				jal timePasses #call timePasses()
				jal explodeBomb #call explodeBomb()
				
				j whileLoop #go to whileLoop

			whileLoopEnd:
				#printGrid();
				jal printGrid #call printGrid()
				j endOfMain #return to the caller

		endOfMain:
			li $v0, 10       # Sistem çağrısı numarası: 10 (programı sonlandır)
			syscall


	printChar:
		#prints the character in $a0
		li $v0, 11         # Print character system call
		syscall

		jr $ra             # Return to caller

	printNewLine:
		# Print the newline character
		li $v0, 4          # Print string system call
		li $a0, 10    # Newline ascii value
		syscall

		jr $ra             # Return to the caller

	isDigit:
		# Checks the value in $a0 is a digit or not
		# Returns 1 if it is a digit, 0 otherwise ($v0)
		li $v0, 0          # $v0 = 0
		li $t0, 48         # $t0 = 48 (ascii value of '0')
		li $t1, 57         # $t1 = 57 (ascii value of '9')
		blt $a0, $t0, endOfIsDigit # if value < '0', return 0
		bgt $a0, $t1, endOfIsDigit # if value > '9', return 0
		li $v0, 1          # $v0 = 1
		endOfIsDigit:
			jr $ra             # Return to the caller


	setGridValue: #(void) setGridValue(rowIndex, columnIndex, value) (int, int, char)
		#takes three parameters from a registers ($a0, $a1, $a2) and sets the value of the grid[rowIndex*c+columnIndex] to value
		#first parameter is : rowIndex
		#second parameter is : columnIndex
		#third parameter is : (char) value
		#the c code is grid[rowIndex*c+columnIndex]=value;
		#expand the stack to store the arguments 
		sub $sp, $sp, 12

		#store the arguments in the a registers to the stack
		sw $a0, 0($sp) #rowIndex
		sw $a1, 4($sp) #columnIndex
		sb $a2, 8($sp) #value (char)
 
		#load the arguments from the stack
		lw $t0, 0($sp) #rowIndex 
		lw $t1, 4($sp) #columnIndex 
		lw $t2, c #c 

		#calculate the address of the grid[rowIndex*c+columnIndex] and store it in $t0
		mult $t0, $t2 #rowIndex*c in $t0 
		mflo $t0 #rowIndex*c in $t0 (we take the lower 32 bits of the result)
		add $t0, $t0, $t1 #rowIndex*c+columnIndex in $t0
		#t0 = rowIndex*c+columnIndex

		#store the address of the grid[rowIndex*c+columnIndex] in $t1
		la $t1, grid #t1 is the address of the grid which is the first element of the grid = grid[0]
		add $t1, $t1, $t0 #t1 points to grid[rowIndex*c+columnIndex]

		#Lastly, store the value in the grid[rowIndex*c+columnIndex]
		lw $t2, 8($sp) #value
		sb $t2, 0($t1) #grid[rowIndex*c+columnIndex]= t2 (value)


		#shrink the stack back to its original position
		add $sp, $sp, 12

		jr $ra #return to the caller

	getGridValue: #(int) getGridValue(rowIndex, columnIndex) (int, int)
		#takes two parameters from a registers ($a0, $a1) and returns the value of the grid[rowIndex*c+columnIndex]
		#first parameter is : rowIndex
		#second parameter is : columnIndex
		#the c code is : return grid[rowIndex*c+columnIndex];
		#expand the stack to store the arguments (RULE 4 of GENERAL RULES OF REGISTER USAGE)
		sub $sp, $sp, 8

		#store the arguments in the a registers to the stack
		sw $a0, 0($sp) #rowIndex
		sw $a1, 4($sp) #columnIndex
 
		#load the arguments from the stack
		lw $t0, 0($sp) #rowIndex 
		lw $t1, 4($sp) #columnIndex 
		lw $t2, c #c 

		#calculate the address of the grid[rowIndex*c+columnIndex] and store it in $t0
		mult $t0, $t2 #rowIndex*c in $t0 
		mflo $t0 #rowIndex*c in $t0 (we take the lower 32 bits of the result)
		add $t0, $t0, $t1 #rowIndex*c+columnIndex in $t0
		#t0 = rowIndex*c+columnIndex

		#store the address of the grid[rowIndex*c+columnIndex] in $t1
		la $t1, grid #t1 is the address of the grid which is the first element of the grid = grid[0]
		add $t1, $t1, $t0 #t1 points to grid[rowIndex*c+columnIndex]

		#Lastly, load the value in the grid[rowIndex*c+columnIndex] to $v0 (RULE 5 of GENERAL RULES OF REGISTER USAGE)
		lb $v0, 0($t1) #grid[rowIndex*c+columnIndex] is stored in v0

		#shrink the stack
		add $sp, $sp, 8

		jr $ra #return to the caller


	takeAllInputs: # (void) takeAllInputs() 
		#takes all inputs from the user and stores in the actual variables in the data field (r,c,n grid)
		#since there are no arguments and calls to other functions, we dont need to expand the stack (combination of the rule4 and rule7)
	
		#take the row input from the user
		li $v0, 4 #print string system call
		la $a0, promptRow #load the address of the promptRow
		syscall #print the promptRow

		li $v0, 5 #read integer system call
		syscall #read the row input from the user
		la $t0, r #load the address of the r
		sw $v0, 0($t0) #store the row input in r

		#take the column input from the user
		li $v0, 4 #print string system call
		la $a0, promptColumn #load the address of the promptColumn
		syscall #print the promptColumn

		li $v0, 5 #read integer system call
		syscall #read the column input from the user
		la $t0, c #load the address of the c
		sw $v0, 0($t0) #store the column input in c

		#take the time input from the user
		li $v0, 4 #print string system call
		la $a0, promptTime #load the address of the promptTime
		syscall #print the promptTime

		li $v0, 5 #read integer system call
		syscall #read the time input from the user
		la $t0, n #load the address of the n
		sw $v0, 0($t0) #store the time input in n

		#take the grid input from the user
		li $v0, 4 #print string system call
		la $a0, promptGrid #load the address of the promptGrid
		syscall #print the promptGrid

		li $v0, 8 #read string system call
		la $a0, grid #load the address of the grid
		li $a1, 20000 #load the length of the grid
		syscall #read the grid input from the user

		jr $ra #return to the caller






	#the c code is:
		#void initializeFirstBombs()
		#{
		#	int i;
		#	int j;
		#	for(i=0;i<r;i++)
		#	{
		#		for(j=0;j<c;j++)
		#		{
		#			if(grid[i*c+j]=='O')
		#				setGridValue(i,j,'');
		#		}
		#	}
		#}
	initializeFirstBombs: #(void) initializeFirstBombs()
		# ID = 1 (Please check the GENERAL RULES OF REGISTER USAGE at the top of the file, RULE 6 for the reason of the id numbers)
		# User give the bomb values as 'O' in the grid, but the program represents bomb as integers (remaining time of the bomb to explode)
		# So, this function converts the 'O' values in the grid to the '3' values in the grid (3 means 3 seconds remaining to explode)
		# s0 = i, s1 = j
		li $s0, 0 #i=0
		li $s1, 0 #j=0
		li $t0, 0 #t0=0
		li $t1, 0 #t1=0

		#store ra in the stack for later use
		sub $sp, $sp, 4 #expand the stack
		sw $ra, 0($sp) #store ra in the stack

		outerLoop1: 
			#check if i<r 
			lw $t0, r #t0=r
			blt $s0, $t0, innerLoop1 #if i<r, go to outerLoopBody
			j outerLoopEnd1 #if i>=r, go to outerLoopEnd1

			#outerLoopBody
			#inner loop
			innerLoop1:
				#check if j<c
				lw $t0, c #t0=c
				blt $s1, $t0, innerLoopBody1 #if j<c, go to innerLoopBody
				j innerLoopEnd1 #if j>=c, go to innerLoopEnd1

				innerLoopBody1:
					#innerLoopBody1
					#check if grid[i*c+j]=='O' with getGridValue(i,j)
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j	
					jal getGridValue #call getGridValue(i,j) and store the return value in v0
					li $t0, 79 #t0=79 (ascii value of 'O') 
					bne $v0, $t0, continueInner1 #if grid[i*c+j]!='O', go to innerLoop

					#if(grid[i*c+j]=='O') :

					#setBomb
					#setGridValue(i,j,3)
					#ascii value of '3' is 51
					li $t0, 51 #t0='3' (ascii value of '3')
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j
					move $a2, $t0 #a2=3
					jal setGridValue #call setGridValue(i,j,3) 

				continueInner1: #j++ and go to innerLoop 
					addi $s1, $s1, 1 #j++
					j innerLoop1 #go to innerLoop
				
				innerLoopEnd1: #j=0 and go to outerLoop
					li $s1, 0 #j=0
					j continueOuter1 #go to outerLoop

				continueOuter1: #i++ and go to outerLoop
					addi $s0, $s0, 1 #i++
					j outerLoop1 #go to outerLoop

			outerLoopEnd1: #dont change i and return to the caller
				j endOfInitializeFirstBombs #return to the caller
			
		endOfInitializeFirstBombs: #return to the caller
			lw $ra, 0($sp) #restore ra from the stack
			add $sp, $sp, 4 #shrink the stack
			jr $ra #return to the caller




	#the c code is:
		#void timePasses()
		#{
		#	int i;
		#	int j;
		#	for(i=0;i<r;i++)
		#	{
		#		for(j=0;j<c;j++)
		#		{
		#			if(isDigit(grid[i*c+j]) == 1)
		#				grid[i*c+j]--;
		#		}
		#	}
		#	n--;
		#}
	timePasses: #(void) timePasses()
		# ID = 2 (Please check the GENERAL RULES OF REGISTER USAGE at the top of the file, RULE 6 for the reason of the id numbers)
		#decrements the remaining time of the bombs by 1
		# s0 = i, s1 = j
		li $s0, 0 #i=0
		li $s1, 0 #j=0
		li $t0, 0 #t0=0
		li $t1, 0 #t1=0

		#store ra in the stack for later use
		sub $sp, $sp, 4 #expand the stack
		sw $ra, 0($sp) #store ra in the stack

		outerLoop2: 
			#check if i<r 
			lw $t0, r #t0=r
			#if i>=r, go to outerLoopEnd2 or just continue
			blt $s0, $t0, innerLoop2 #if i<r, go to outerLoopBody
			j outerLoopEnd2 #if i>=r, go to outerLoopEnd2

			#outerLoopBody2:
			#inner loop
			innerLoop2:
				#check if j<c
				lw $t0, c #t0=c
				#if j>=c, go to innerLoopEnd2 or just continue
				blt $s1, $t0, innerLoopBody2 #if j<c, go to innerLoopBody
				j innerLoopEnd2 #if j>=c, go to innerLoopEnd

				innerLoopBody2:
					#innerLoopBody2
					#check if isDigit(grid[i*c+j]) == 1 with isDigit(grid[i*c+j])
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j	
					jal getGridValue #call getGridValue(i,j) and store the return value in v0
					move $a0, $v0 #a0=v0 (the return value of getGridValue(i,j) was stored in v0, we need to pass it to isDigit as an argument)
					jal isDigit #call isDigit(grid[i*c+j]) and store the return value in v0
					li $t0, 1 #t0=1
					bne $v0, $t0, continueInner2 #if isDigit(grid[i*c+j]) != 1, go to continueInner

					#if(isDigit(grid[i*c+j]) == 1) (if the element is a bomb, decrement its remaining time by 1)

					#decrementBomb
					#grid[i*c+j]--;
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j
					jal getGridValue #call getGridValue(i,j) and store the return value in v0
					addi $v0, $v0, -1 #v0--
					move $a2, $v0 #a2=v0
					jal setGridValue #call setGridValue(i,j,v0) 

				continueInner2: #j++ and go to innerLoop 
					addi $s1, $s1, 1 #j++
					j innerLoop2 #go to innerLoop
				
				innerLoopEnd2: #j=0 and go to outerLoop
					li $s1, 0 #j=0
					j continueOuter2

			continueOuter2: #i++ and go to outerLoop
				addi $s0, $s0, 1 #i++
				j outerLoop2 #go to outerLoop
		
		outerLoopEnd2: #dont change i and return to the caller
			j endOfTimePasses #return to the caller

		endOfTimePasses: #return to the caller
			#decrement n by 1
			lw $t0, n #t0=n
			addi $t0, $t0, -1 #t0--
			la $t1, n #t1=n
			sw $t0, 0($t1) #n=t0 (decremented n)

			lw $ra, 0($sp) #restore ra from the stack
			add $sp, $sp, 4 #shrink the stack
			jr $ra #return to the caller

	
	#the c code is:
		#void fillWithBombs() 	
		#{
		#	int i;
		#	int j;
		#	for(i=0;i<r;i++)
		#	{
		#		for(j=0;j<c;j++)
		#		{
		#			if(grid[i*c+j]=='.')
		#				setGridValue(i,j,'3');
		#		}
		#	}
		#}

	fillWithBombs: #(void) fillWithBombs()
		# ID = 3 (Please check the GENERAL RULES OF REGISTER USAGE at the top of the file, RULE 6 for the reason of the id numbers)
		#fills the empty cells with bombs
		# s0 = i, s1 = j
		li $s0, 0 #i=0
		li $s1, 0 #j=0
		li $t0, 0 #t0=0
		li $t1, 0 #t1=0

		#store ra in the stack for later use
		sub $sp, $sp, 4 #expand the stack
		sw $ra, 0($sp) #store ra in the stack

		outerLoop3: 
			#check if i<r 
			lw $t0, r #t0=r
			#if i>=r, go to outerLoopEnd3 or just continue
			blt $s0, $t0, innerLoop3 #if i<r, go to innerLoop
			j outerLoopEnd3 #if i>=r, go to outerLoopEnd

			#outerLoopBody3:
			#inner loop
			innerLoop3:
				#check if j<c
				lw $t0, c #t0=c
				#if j>=c, go to innerLoopEnd3 or just continue
				blt $s1, $t0, innerLoopBody3 #if j<c, go to innerLoopBody
				j innerLoopEnd3 #if j>=c, go to innerLoopEnd

				innerLoopBody3:
					#innerLoopBody
					#check if grid[i*c+j]=='.' with getGridValue(i,j)
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j	
					jal getGridValue #call getGridValue(i,j) and store the return value in v0
					li $t0, 46 #t0=46 (ascii value of '.')
					bne $v0, $t0, continueInner3 #if grid[i*c+j]!='.', go to continueInner

					#if(grid[i*c+j]=='.') :

					#fillWithBomb
					#setGridValue(i,j,'3')
					li $t0, 51 #t0=51 (ascii value of '3')
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j
					move $a2, $t0 #a2= 51 (ascii value of '3')
					jal setGridValue #call setGridValue(i,j,'3') 

				continueInner3: #j++ and go to innerLoop 
					addi $s1, $s1, 1 #j++
					j innerLoop3 #go to innerLoop
				
				innerLoopEnd3: #j=0 and go to outerLoop
					li $s1, 0 #j=0
					j continueOuter3

			continueOuter3: #i++ and go to outerLoop
				addi $s0, $s0, 1 #i++
				j outerLoop3 #go to outerLoop
			
		outerLoopEnd3: #dont change i and return to the caller
			j endOfFillWithBombs #return to the caller

		endOfFillWithBombs: #return to the caller
			lw $ra, 0($sp) #restore ra from the stack
			add $sp, $sp, 4 #shrink the stack
			jr $ra #return to the caller



	#the c code is:
		#void explodeBomb()
		#{
		#	int i;
		#	int j;
		#	for(i=0;i<r;i++)
		#	{
		#		for(j=0;j<c;j++)
		#		{
		#			if(grid[i*c+j]=='0') //if the element is a bomb about to explode (remaining time is 0)
		#			{
		#				setGridValue(i,j,'.'); //set the element to '.' which means it is exploded and now its neighbors should be inactivated if they are bombs and the remaining time is more than 0
		#				if(i!=0 && grid[(i-1)*c+j]!='0') //if the element is not in the first row and the element above it is a bomb and the remaining time is more than 0
		#					setGridValue(i-1,j,'.'); //decrement the remaining time of the bomb above it by 1
		#				if(i!=r-1 && grid[(i+1)*c+j]!='0') //if the element is not in the last row and the element below it is a bomb and the remaining time is more than 0
		#					setGridValue(i+1,j,'.'); //decrement the remaining time of the bomb below it by 1
		#				if(j!=0 && grid[i*c+j-1]!=0) //if the element is not in the first column and the element left to it is a bomb and the remaining time is more than 0
		#					setGridValue(i,j-1,'.'); //decrement the remaining time of the bomb left to it by 1
		#				if(j!=c-1 && grid[i*c+j+1]!='0') //if the element is not in the last column and the element right to it is a bomb and the remaining time is more than 0
		#					setGridValue(i,j+1,'.'); //decrement the remaining time of the bomb right to it by 1
		#			}
		#		}
		#	}
		#}

	explodeBomb: #(void) explodeBomb()
		# ID = 4 (Please check the GENERAL RULES OF REGISTER USAGE at the top of the file, RULE 6 for the reason of the id numbers)
		#explodes the bombs
		# s0 = i, s1 = j
		li $s0, 0 #i=0
		li $s1, 0 #j=0
		li $t0, 0 #t0=0
		li $t1, 0 #t1=0

		#store ra in the stack for later use
		sub $sp, $sp, 4 #expand the stack
		sw $ra, 0($sp) #store ra in the stack

		outerLoop4: 
			#check if i<r 
			lw $t0, r #t0=r
			#if i>=r, go to outerLoopEnd4 or just continue
			blt $s0, $t0, innerLoop4 #if i<r, go to innerLoopBody
			j outerLoopEnd4 #if i>=r, go to outerLoopEnd

			#outerLoopBody:
			#inner loop
			innerLoop4:
				#check if j<c
				lw $t0, c #t0=c
				#if j>=c, go to innerLoopEnd or just continue
				blt $s1, $t0, innerLoopBody4 #if j<c, go to innerLoopBody
				j innerLoopEnd4 #if j>=c, go to innerLoopEnd

				innerLoopBody4:
					#innerLoopBody
					#check if grid[i*c+j]=='0' with getGridValue(i,j)
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j	
					jal getGridValue #call getGridValue(i,j) and store the return value in v0
					li $t0, 48 #t0=48 (ascii value of '0')
					bne $v0, $t0, continueInner4 #if grid[i*c+j]!=0, go to continueInner

					#if(grid[i*c+j]=='0') :

					#explodeBomb by setting the element to '.'
					#setGridValue(i,j,'.')
					li $t0, 46 #t0=46 (ascii value of '.')
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j
					move $a2, $t0 #a2=46
					jal setGridValue #call setGridValue(i,j,'.') 

					#CHECK THE NEIGHBOR BOMBS AND INACTIVATE THEM IF THEY ARE BOMBS AND THE REMAINING TIME IS MORE THAN 0
					j checkAbove4 #go to checkAbove

					checkAbove4:
						#check if i!=0
						li $t0, 0 #t0=0
						bne $s0, $t0, checkAboveTwo4 #if i!=0, go to checkAboveBody
						j checkBelow4 #if i==0, go to checkBelow 

						checkAboveTwo4:
							#check if grid[(i-1)*c+j]!='0' with getGridValue(i-1,j)
							move $t0, $s0 #t0=i
							addi $t0, $t0, -1 #t0=i-1
							move $a0, $t0 #a0=i-1
							move $a1, $s1 #a1=j	
							jal getGridValue #call getGridValue(i-1,j) and store the return value in v0
							li $t0, 48 #t0=48 (ascii value of '0')
							beq $v0, $t0, checkBelow4 #if grid[(i-1)*c+j]=='0', go to checkBelow

							#if(grid[(i-1)*c+j]!='0') :

							#inactiveBomb by setting the element to '.'
							li $t0, 46 #t0=46 (ascii value of '.')
							move $t1, $s0 #t1=i
							addi $t1, $t1, -1 #t1=i-1
							move $a0, $t1 #a0=i-1
							move $a1, $s1 #a1=j
							move $a2, $t0 #a2=46
							jal setGridValue #call setGridValue(i-1,j,'.') 

					checkBelow4:
						#check if i!=r-1
						lw $t0, r #t0=r
						addi $t0, $t0, -1 #t0=r-1
						bne $s0, $t0, checkBelowTwo4 #if i!=r-1, go to checkBelowTwo
						j checkLeft4 #if i==r-1, go to checkLeft

						checkBelowTwo4:
							#check if grid[(i+1)*c+j]!='0' with getGridValue(i+1,j)
							move $t0, $s0 #t0=i	
							addi $t0, $t0, 1 #t0=i+1
							move $a0, $t0 #a0=i+1
							move $a1, $s1 #a1=j
							jal getGridValue #call getGridValue(i+1,j) and store the return value in v0
							li $t0, 48 #t0=48 (ascii value of '0')
							beq $v0, $t0, checkLeft4 #if grid[(i+1)*c+j]=='0', go to checkLeft

							#if grid[(i+1)*c+j]!='0' with getGridValue(i+1,j) :

							#inactiveBomb by setting the element to '.'
							li $t0, 46 #t0=46 (ascii value of '.')
							move $t1, $s0 #t1=i
							addi $t1, $t1, 1 #t1=i+1
							move $a0, $t1 #a0=i+1
							move $a1, $s1 #a1=j
							move $a2, $t0 #a2=46
							jal setGridValue #call setGridValue(i+1,j,'.')


					checkLeft4:
						#check if j!=0
						li $t0, 0 #t0=0
						bne $s1, $t0, checkLeftTwo4 #if j!=0, go to checkLeftTwo
						j checkRight4 #if j==0, go to checkRight

						checkLeftTwo4:
							#check if grid[i*c+j-1]!='0' with getGridValue(i,j-1)
							move $t0, $s1 #t0=j
							addi $t0, $t0, -1 #t0=j-1
							move $a0, $s0 #a0=i
							move $a1, $t0 #a1=j-1
							jal getGridValue #call getGridValue(i,j-1) and store the return value in v0
							li $t0, 48 #t0=48 (ascii value of '0')
							beq $v0, $t0, checkRight4 #if grid[i*c+j-1]=='0', go to checkRight

							#if grid[i*c+j-1]!='0' with getGridValue(i,j-1) :

							#inactiveBomb by setting the element to '.'
							move $a0, $s0 #a0=i
							move $t1, $s1 #t1=j
							addi $t1, $t1, -1 #t1=j-1
							move $a1, $t1 #a1=j-1
							li $t0, 46 #t0=46 (ascii value of '.')
							move $a2, $t0 #a2=46
							jal setGridValue #call setGridValue(i,j-1,'.')		

					checkRight4:
						#check if j!=c-1
						lw $t0, c #t0=c
						addi $t0, $t0, -1 #t0=c-1
						bne $s1, $t0, checkRightTwo4 #if j!=c-1, go to continueInner
						j continueInner4 #if j==c-1, go to continueInner

						checkRightTwo4:
							#check if grid[i*c+j+1]!='0' with getGridValue(i,j+1)
							move $t0, $s1 #t0=j
							addi $t0, $t0, 1 #t0=j+1
							move $a0, $s0 #a0=i
							move $a1, $t0 #a1=j+1
							jal getGridValue #call getGridValue(i,j+1) and store the return value in v0
							li $t0, 48 #t0=48 (ascii value of '0')
							beq $v0, $t0, continueInner4 #if grid[i*c+j+1]==0, go to continueInner

							#if grid[i*c+j+1]!='0' with getGridValue(i,j+1) :

							#inactiveBomb by setting the element to '.'
							move $t1, $s1 #t1=j
							addi $t1, $t1, 1 #t1=j+1
							li $t0, 46 #t0=46 (ascii value of '.')
							move $a0, $s0 #a0=i
							move $a1, $t1 #a1=j+1
							move $a2, $t0 #a2=46
							jal setGridValue #call setGridValue(i,j+1,'.')	

				continueInner4: #j++ and go to innerLoop
					addi $s1, $s1, 1 #j++
					j innerLoop4 #go to innerLoop

				innerLoopEnd4: #j=0 and go to outerLoop
					li $s1, 0 #j=0
					j continueOuter4
				
			continueOuter4: #i++ and go to outerLoop
				addi $s0, $s0, 1 #i++
				j outerLoop4 #go to outerLoop


		outerLoopEnd4: #dont change i and return to the caller
			j endOfExplodeBomb #return to the caller
		
		endOfExplodeBomb: #return to the caller
			lw $ra, 0($sp) #restore ra from the stack
			add $sp, $sp, 4 #shrink the stack
			jr $ra #return to the caller


	#the c code is:
		#void printGrid()
		#{
		#	int i;
		#	int j;
		#	for(i=0;i<r;i++)
		#	{
		#		for(j=0;j<c;j++)
		#		{
		#			if(isDigit(grid[i*c+j]) == 1)
		#          		printf("O");
		#          	else
		#          		printf("%c",grid[i*c+j]);
		#		}
		#		printf("\n");
		#	}
		#}

	printGrid: #(void) printGrid()
		# ID = 5 (Please check the GENERAL RULES OF REGISTER USAGE at the top of the file, RULE 6 for the reason of the id numbers)
		#prints the grid
		# s0 = i, s1 = j
		li $s0, 0 #i=0
		li $s1, 0 #j=0
		li $t0, 0 #t0=0
		li $t1, 0 #t1=0

		#store ra in the stack (RULE 7 of GENERAL RULES OF REGISTER USAGE)
		#expand the stack by 4 bytes
		addi $sp, $sp, -4 #sp=sp-4
		sw $ra, 0($sp) #store ra in the stack

		outerLoop5: 
			#check if i<r 
			lw $t0, r #t0=r
			#if i>=r, go to outerLoopEnd or just continue
			blt $s0, $t0, innerLoop5 #if i<r, go to innerLoopBody
			j outerLoopEnd5 #if i>=r, go to outerLoopEnd

			#outerLoopBody5:
			#inner loop
			innerLoop5:
				#check if j<c
				lw $t0, c #t0=c
				#if j>=c, go to innerLoopEnd or just continue
				blt $s1, $t0, innerLoopBody5 #if j<c, go to innerLoopBody
				j innerLoopEnd5 #if j>=c, go to innerLoopEnd

				innerLoopBody5:
					#innerLoopBody5
					#check if isDigit(grid[i*c+j]) == 1 with isDigit(grid[i*c+j])
					move $a0, $s0 #a0=i
					move $a1, $s1 #a1=j	
					jal getGridValue #call getGridValue(i,j) and store the return value in v0
					move $a0, $v0 #a0=v0 (the return value of getGridValue(i,j) was stored in v0, we need to pass it to isDigit as an argument)
					jal isDigit #call isDigit(grid[i*c+j]) and store the return value in v0
					li $t0, 1 #t0=1
					bne $v0, $t0, else5 #if is
					#if body
						#print 'O' using printChar method
						li $a0, 79 #ascii value of 'O'
						jal printChar #call printChar('O')
						j continueInner5 #go to continueInner

					else5:
						#print grid[i*c+j] using printChar method
						move $a0, $s0 #a0=i
						move $a1, $s1 #a1=j
						jal getGridValue #call getGridValue(i,j) and store the return value in v0
						move $a0, $v0 #a0=v0 (the return value of getGridValue(i,j) was stored in v0, we need to pass it to printChar as an argument)
						jal printChar #call printChar(grid[i*c+j])
						j continueInner5 #go to continueInner

				continueInner5: #j++ and go to innerLoop 
					addi $s1, $s1, 1 #j++
					j innerLoop5 #go to innerLoop

				innerLoopEnd5: #j=0 and go to outerLoop
					li $s1, 0 #j=0
					j continueOuter5
				
			continueOuter5: #i++ and go to outerLoop
				li $a0, 10 #load newline to $a0
                jal printChar #print newline
				addi $s0, $s0, 1 #i++
				j outerLoop5 #go to outerLoop

			outerLoopEnd5: #dont change i and return to the caller
				j endOfPrintGrid #return to the caller
			
		endOfPrintGrid: #return to the caller
			lw $ra, 0($sp) #load ra from the stack
			addi $sp, $sp, 4 #sp=sp+4 (shrink the stack)
			jr $ra #return to the caller

				
