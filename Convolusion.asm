# Created by Nguyen Quoc Hieu
# Ho Chi Minh University of Technology
# 09/11/2024 22:44
# This code below is not optimized

.data
    buffer_read: 			.asciiz "input_matrix.txt"  
    buffer_write:           .asciiz "output_matrix.txt"
    buffer:	 				.space 1024    
    buff:                   .space 1024
    error: 					.asciiz "terminate called after throwing an instance of 'mips::file_error'\n what(): Cannot open file"
    newline: 				.asciiz "\n"
    implement: 				.asciiz "######################################################################################################"

    image_size: 			.word 0	# N
    kernel_size: 			.word 0	# M
    value_padding: 			.word 0	# p
    value_stride: 			.word 0	# s

    image: 					.word 0 : 300
    kernel:					.word 0 : 300
    padded: 				.word 0 : 300
    out: 					.word 0 : 300
    new_out:                .word 0 : 300

    newline2:				.asciiz "\n\n"
    space: 					.asciiz " "
    check:                  .asciiz "Hello"

    num_10:                 .float 10.0    
    num_0_5:                .float 0.05
    zero:                   .float 0.0
    dot:                    .asciiz "."
    minus:                  .asciiz "-"    
.text
.globl main

main:
    # Set pointers to matrices
    la $s0, image
    la $s1, kernel
    la $s2, padded
    la $s3, out
    la $s5, new_out

    # Open file
    li $v0, 13               
    la $a0, buffer_read      
    li $a1, 0                
    li $a2, 0                
    syscall
    move $s6, $v0            
    bltz $s6, file_error     

    # Read file
    li $v0, 14				
    move $a0, $s6           
    la $a1, buffer          
    li $a2, 1024            
    syscall
    j set_buffer
#########################################################################################################


#########################################################################################################
set_buffer:
    # Initialize buffer pointer
    la $s4, buffer			

read_matrix_params:                                 
    # Read N (image size)
    lb $t4, 0($s4)              
    sub $t4, $t4, '0'           
    sw $t4, image_size          
    addi $s4, $s4, 2            
    
    # Read M (kernel size)
    lb $t4, 0($s4)              
    sub $t4, $t4, '0'           
    sw $t4, kernel_size         
    addi $s4, $s4, 2            
    
    # Read p (padding)
    lb $t4, 0($s4)              
    sub $t4, $t4, '0'           
    sw $t4, value_padding       
    addi $s4, $s4, 2            
    
    # Read s (stride)
    lb $t4, 0($s4)              
    sub $t4, $t4, '0'           
    sw $t4, value_stride        
    addi $s4, $s4, 3            
    j validate

read_image:
    li $t3, 0                           # Mode flag (0 for image)
read_image_loop:
    lb $t1, 0($s4)
    beq $t1, 10, read_kernel            # Newline
    beq $t1, 32, next_image_char        # Space
    beq $t1, 13, read_kernel            # End of file
    j cvt_string_float
    
next_image_char:
    addi $s4, $s4, 1
    j read_image_loop

read_kernel:
    addi $s4, $s4, 1                    # Skip newline
    li $t3, 1                           # Mode flag (1 for kernel)
read_kernel_loop:
    lb $t1, 0($s4)
    beq $t1, 10, start_build_padded_image     # Newline
    beq $t1, 32, next_kernel_char             # Space
    beq $t1, 0, start_build_padded_image      # End of file
    j cvt_string_float
    
next_kernel_char:
    addi $s4, $s4, 1
    j read_kernel_loop
#########################################################################################################
cvt_string_float:																						#																				
	seq $t2, $t1, 45					# Check if sign of the character is negtive or positive			# 
																										#
	# IEEE 754 format to stack and use lwc1																#
    lui $t6, 0x0000 					# we cannot directly set a register to float					#
	addi $sp, $sp, -4					# create space in stack											#
	sw $t6, 0($sp)																						#
	lwc1 $f0, 0($sp)					# initialize f0 with 0.0										#
	addi $sp, $sp, 4					# pop the stack												    #
                                                                                                        #
	lui $t6, 0x4120																						#
	addi $sp, $sp, -4																					#
	sw $t6, 0($sp)																						#
	lwc1 $f1, 0($sp)					# initialize f1 with 10.0, float for whole number				#
    addi $sp, $sp, 4                                                                                    #
                                                                                                        #
	lui $t6, 0x4120																						#
	addi $sp, $sp, -4																					#
	sw $t6, 0($sp)																						#
	lwc1 $f2, 0($sp)					# initialize f1 with 10.0, float for decimal part				#
	addi $sp, $sp, 4																					#
                                                                                                        #
	beqz $t2, before_point 				# if the number is positive skip below line						#
	addi $s4, $s4, 1																					#
	before_point:																						#
		lb $t1, 0($s4) 					# load current character										#
		beq $t1, 0, store_float			# NULL															#
		beq $t1, 10, store_float		# LINE FEED														#
		beq $t1, 13, store_float		# CARRIAGE RETURN												#
		beq $t1, 32, store_float		# SPACE															#
		beq $t1, '.', after_point		# handle decimal after point									#
																										#
		sub $t1, $t1, '0'				# Convert ASCII to integer										#
		addi $sp, $sp, -4																				#
		sw $t1, 0($sp)																					#
		lwc1 $f3, 0($sp) 				# Change integer to float 										#
		addi $sp, $sp, 4				# pop															#
		cvt.s.w $f3, $f3				# confirmly get the float from word								#
																										#
		mul.s $f0, $f0, $f1				# multiply with 10(shift left)									#
		add.s $f0, $f0, $f3 			# add new digit													#
																										#
		addi $s4, $s4, 1				# move to new character											#
		j before_point																					#
#########################################################################################################	
	after_point:																						#																					
		addi $s4, $s4, 1				# move to new character											#
        j handle_point																					#
	handle_point:																						#
		lb $t1, 0($s4)					# load current character										#
		beq $t1, 0, store_float			# NULL															#
		beq $t1, 10, store_float		# LINE FEED														#
		beq $t1, 13, store_float		# CARRIAGE RETURN												#
		beq $t1, 32, store_float		# SPACE															#
																										#
		sub $t1, $t1, '0'				# Convert ASCII to integer										#
		add $sp, $sp, -4																				#
		sw $t1, 0($sp)																					#
		lwc1 $f3, 0($sp)				# Convert integer to float										#
		addi $sp, $sp, 4				# pop															#
		cvt.s.w $f3, $f3				# confirmly get the float from word								#
																										#
		div.s $f3, $f3, $f1				# shift right to make number after point						#
		mul.s $f1, $f1, $f2				# multiply with 10												#
		add.s $f0, $f0, $f3				# add new digit													#
																										#
		addi $s4, $s4, 1				# move to new character											#
		j handle_point																					#
#########################################################################################################
	# store the result in image/kernel matrix															#
	store_float:																						#
		beq $t2, 1, sign_float			# float < 0														#
		beq $t3, 0, store_image			# mode 0 -> image												#
		beq $t3, 1, store_kernel 		# mode 1 -> kernel												#
																										#
	sign_float:																							#
		lui $t4, 0x0000																					#
		addi $sp, $sp, -4				# create space in stack										    #
		sw $t4, 0($sp)																					#
		lwc1 $f1, 0($sp)				# initialize f0 with 0.0									    #
		add $sp, $sp, 4					# pop the stack												    #
		sub.s $f0, $f1, $f0				# f0 = 0 - f0												    #
		li $t2, 0 						# reset t1 to 0												    #
		j store_float																					#
																										#
        store_image:																					#
            swc1 $f0, 0($s0)																			#
            addi $s0, $s0, 4			# move to next word										        #
            j next_char																					#
        store_kernel:																					#
            swc1 $f0, 0($s1)																			#
            addi $s1, $s1, 4			# move to next word										        #
            j next_char																					#
	next_char:																							#
        addi $s4, $s4, 1																				#
		beq $t3, 0, read_image_loop																		#
		beq $t3, 1, read_kernel_loop																	#
#########################################################################################################                                                                                                    #
start_build_padded_image:                                                                               #
	la $s0, image                       # Load image adress                                             #
	la $s2, padded	                    # Load padded adress                                            #
                                                                                                        #
	la $t0, image_size		            # Load N                                                        #
	lw $t0, 0($t0)                                                                                      #
                                                                                                        #
	la $t2, value_padding		        # Load p                                                        #
	lw $t2, 0($t2)                                                                                      #
                                                                                                        #
	mul $t3, $t2, 2		                # t3 = 2p                                                       #
	add $t3, $t0, $t3	                # t3 = N + 2*p                                                  #
	mul $t3, $t3, $t2	                # t3 = (N + 2*p)*p                                              #
	add $t3, $t3, $t2	                # t3 = (N + 2*p)*p+p                                            #
                                                                                                        #
	mul $t3, $t3, 4		                # t3 = t3 * 4 bytes                                             #
	add $s2, $s2, $t3	                # move the pointers to the begin to copy                        #
                                                                                                        #
	li $t4, 0		                    # Outer loop counter                                            #
	outside_loop:                                                                                       #
		beq $t4, $t0, exit_outer    # if t4 == N -> end                                                 #
		li $t5, 0	                    # Inner loop counter                                            #
		inner_loop:                                                                                     #
			beq $t5, $t0, exit_inner                                                                    #
			lwc1 $f4, 0($s0)                                                                            #
			swc1 $f4, 0($s2)                                                                            #                                                                                 
			addi $s0, $s0, 4                                                                            #
			addi $s2, $s2, 4                                                                            #
			addi $t5, $t5, 1                                                                            #
			j inner_loop                                                                                #
		exit_inner:                                                                                     #
			move $t6, $t2                                                                               #
			mul $t6, $t6, 8                                                                             #
			add $s2, $s2, $t6                                                                           #
		addi $t4, $t4, 1                                                                                #
		j outside_loop                                                                                  #
	exit_outer:                                                                                         #
        j start_build_convolved_matrix                                                                  #
#########################################################################################################
start_build_convolved_matrix:
    # Reset pointers
    la $s2, padded          # Load padded matrix address
    la $s1, kernel          # Load kernel matrix address
    la $s3, out             # Load output matrix address

    # Load parameters
    lw $t0, image_size      # N
    lw $t1, kernel_size     # M
    lw $t2, value_padding   # p
    lw $t3, value_stride    # s

    # Calculate padded size
    mul $t4, $t2, 2         # 2p
    add $t4, $t0, $t4       # N + 2p
    
    # Calculate output size
    sub $t5, $t4, $t1       # (N + 2p) - M
    div $t5, $t3            # ((N + 2p) - M) / s
    mflo $t5
    addi $t5, $t5, 1        # ((N + 2p) - M) / s + 1
    
    # Initialize row counter for output
    li $t6, 0               # i = 0
convolution_row_loop:
    bge $t6, $t5, end_convolution    # if i >= output_size, end
    
    # Initialize column counter for output
    li $t7, 0               # j = 0
convolution_col_loop:
    bge $t7, $t5, next_conv_row    # if j >= output_size, next row

    # Calculate starting position in padded matrix
    mul $t8, $t6, $t3       # i * stride
    mul $t9, $t7, $t3       # j * stride
    
    # Initialize sum for convolution
    lui $t0, 0x0000         # Load 0.0 into stack
    addi $sp, $sp, -4
    sw $t0, 0($sp)
    lwc1 $f0, 0($sp)        # f0 = sum = 0.0
    addi $sp, $sp, 4

    # Reset kernel position
    la $s1, kernel          # Reset kernel pointer
    
    # Kernel row counter
    li $s4, 0               # kr = 0
kernel_row_loop:
    bge $s4, $t1, store_result    # if kr >= kernel_size, store result
    
    # Kernel column counter
    li $s5, 0               # kc = 0
kernel_col_loop:
    bge $s5, $t1, next_kernel_row    # if kc >= kernel_size, next row
    
    # Calculate position in padded matrix
    add $s6, $t8, $s4       # row = i*stride + kr
    mul $s6, $s6, $t4       # row * padded_size
    add $s7, $t9, $s5       # col = j*stride + kc
    add $s6, $s6, $s7       # final position = row * padded_size + col
    mul $s6, $s6, 4         # multiply by 4 for byte offset
    add $s6, $s2, $s6       # add to padded base address
    
    # Load values and multiply
    lwc1 $f1, 0($s6)        # Load padded value
    lwc1 $f2, 0($s1)        # Load kernel value
    mul.s $f3, $f1, $f2     # Multiply values
    add.s $f0, $f0, $f3     # Add to sum
    
    # Move to next kernel position
    addi $s1, $s1, 4        # Move kernel pointer
    addi $s5, $s5, 1        # kj++
    j kernel_col_loop

next_kernel_row:
    addi $s4, $s4, 1        # ki++
    j kernel_row_loop

store_result:
    swc1 $f0, 0($s3)        # Store result in output matrix
    addi $s3, $s3, 4        # Move output pointer
    
    addi $t7, $t7, 1        # j++
    j convolution_col_loop

next_conv_row:
    addi $t6, $t6, 1        # i++
    j convolution_row_loop

end_convolution:
    j print_params          # Move to printing results        
#########################################################################################################
validate:																								                                                #
    # Load sizes																						                                            #
    lw $t0, image_size																					                                        #
    lw $t1, kernel_size																					                                        #
    lw $t2, value_padding																				                                        #
    lw $t3, value_stride																				                                        #
																										                                                    #    
    # Calculate output size																				                                      #
    mul $t4, $t2, 2         # 2p																		                                    #
    add $t4, $t0, $t4       # N + 2p																	                                  #
    sub $t4, $t4, $t1       # N + 2p - M																                                #
    div $t4, $t3            # (N + 2p - M)/s															                              #
    add $t4, $t4, 1         # ((N + 2p - M)/s) + 1														                          #
    j read_image                                                                                        #
#########################################################################################################


#########################################################################################################
close_file:																								                                              #
    li $v0, 16																							                                            #
    move $a0, $s6																						                                            #
    syscall		                                                                                          #
    j exit_program																				                                              #
#########################################################################################################

#########################################################################################################
print_params:																							                                              #
    # Print N																							                                              #
    li $v0, 1																							                                              #
    lw $a0, image_size																					                                        #
    syscall																								                                              #
																										                                                    #
    li $v0, 4																							                                              #
    la $a0, space																						                                            #
    syscall																								                                              #
																										                                                    #
    # Print M																							                                              #
    li $v0, 1																							                                              #
    lw $a0, kernel_size																					                                        #
    syscall																								                                              #
																										                                                    #
    li $v0, 4																							                                              #
    la $a0, space																						                                            #
    syscall																								                                              #
																										                                                    #
    # Print p																							                                              #
    li $v0, 1																							                                              #
    lw $a0, value_padding																				                                        #
    syscall																								                                              #
																										                                                    #
    li $v0, 4																							                                              #
    la $a0, space																						                                            #
    syscall																								                                              #
																										                                                    #
    # Print s																							                                              #
    li $v0, 1																							                                              #
    lw $a0, value_stride																				                                        #
    syscall																								                                              #
																										                                                    #
    li $v0, 4																							                                              #
    la $a0, newline																						                                          #
    syscall																								                                              #
#########################################################################################################
print_matrices:																							                                            #
    la $s0, image      # Reset image pointer															                              #
    la $s1, kernel     # Reset kernel pointer															                              #
																										                                                    #
    # Print separator																					                                          #
    li $v0, 4																							                                              #
    la $a0, implement																					                                          #
    syscall																								                                              #
																										                                                    #
    li $v0, 4																							                                              #
    la $a0, newline																						                                          #
    syscall																								                                              #
#########################################################################################################
    # Print image matrix																				                                        #
    lw $t0, image_size																					                                        #
    mul $t0, $t0, $t0  # N*N elements																	                                  #
    li $t1, 0          # Counter																	  	                                  #
    li $t2, 0          # Counter until N																                                #
    lw $t3, image_size																					                                        #
print_image_loop:																						                                            #
    bge $t1, $t0, print_kernel_header																	                                  #
    bge $t2, $t3, print_newline_image																	                                  #
    j print_image																						                                            #
print_newline_image:																					                                          #
    li $v0, 4																							                                              #
    la $a0, newline																						                                          #
    syscall																								                                              #
    li $t2, 0       #reset $t2																			                                    #
    j print_image_loop																					                                        #
																										                                                    #
print_image:																							                                              #
    li $v0, 2																							                                              #
    lwc1 $f12, 0($s0)																					                                          #
    syscall																								                                              #
																										                                                    #
    li $v0, 4																							                                              #
    la $a0, space																						                                            #
    syscall																								                                              #
																										                                                    #
    addi $s0, $s0, 4																					                                          #
    addi $t1, $t1, 1																					                                          #
    addi $t2, $t2, 1																					                                          #
    j print_image_loop																					                                        #
#########################################################################################################
print_kernel_header:																					                                          #
    li $v0, 4																							                                              #
    la $a0, newline																						                                          #
    syscall																								                                              #
																										                                                    #
    li $v0, 4																							                                              #
    la $a0, newline																						                                          #
    syscall																								                                              #
																										                                                    #
    # Print kernel matrix																				                                        #
    lw $t0, kernel_size																					                                        #
    mul $t0, $t0, $t0  # M*M elements																	                                  #
    li $t1, 0          # Counter																		                                    #
    li $t2, 0          # Counter until M																                                #
    lw $t3, kernel_size																					                                        #
print_kernel_loop:																						                                          #
    bge $t1, $t0, print_check_padding																                                    #
    bge $t2, $t3, print_newline_kernel																	                                #
    j print_kernal																						                                          #
print_newline_kernel:																					                                          #
    li $v0, 4																							                                              #
    la $a0, newline																						                                          #
    syscall																								                                              #
    li $t2, 0																							                                              #
    j print_kernel_loop																					                                        #
																										                                                    #
print_kernal:																							                                              #
	li $v0, 2																							                                                #
    lwc1 $f12, 0($s1)																					                                          #
    syscall																								                                              #
																										                                                    #
    li $v0, 4																							                                              #
    la $a0, space																						                                            #  
    syscall																								                                              #
																										                                                    #
    addi $s1, $s1, 4																					                                          #  
    addi $t1, $t1, 1																					                                          #
    addi $t2, $t2, 1																					                                          #
    j print_kernel_loop																					                                        #
#########################################################################################################
                                                                                                        #
print_check_padding:                                                                                    #
    li $v0, 4                                                                                           #
    la $a0, newline2                                                                                    #
    syscall                                                                                             #
                                                                                                        #
    la $s2, padded                                                                                      #
    li $t0, 0               # Counter                                                                   #
    li $t1, 0               # Counter until N + 2*p                                                     #
    lw $t3, image_size      # N                                                                         #
    lw $t4, value_padding   # p                                                                         #
    mul $t4, $t4, 2         # 2p                                                                        #
    add $t4, $t4, $t3       # N + 2p                                                                    #
    add $t5, $t4, $zero                                                                                 #
    mul $t5, $t5, $t5       # padding_size x padding_size                                               #
print_padding_loop:                                                                                     #
    bge $t0, $t5, print_output                                                                          #
    bge $t1, $t4, print_newline_padding                                                                 #
    j print_padding                                                                                     #
print_newline_padding:                                                                                  #
    li $v0, 4                                                                                           #
    la $a0, newline                                                                                     #
    syscall                                                                                             #
                                                                                                        #
    li $t1, 0                                                                                           #
    j print_padding_loop                                                                                #
print_padding:                                                                                          #
    li $v0, 2                                                                                           #
    lwc1 $f12, 0($s2)                                                                                   #
    syscall                                                                                             #
                                                                                                        #
    li $v0, 4                                                                                           #
    la $a0, space                                                                                       #
    syscall                                                                                             #
                                                                                                        #
    addi $s2, $s2, 4                                                                                    #
    addi $t0, $t0, 1                                                                                    #
    addi $t1, $t1, 1                                                                                    #
    j print_padding_loop                                                                                #
#########################################################################################################
print_output:                                                                                           #
    li $v0, 4                                                                                           #
    la $a0, newline2                                                                                    #
    syscall                                                                                             #
                                                                                                        #
    la $s3, out                                                                                         #
    # Calculate output size                                                                             #
    lw $t0, image_size      # N                                                                         #   
    lw $t1, value_padding   # p                                                                         #
    mul $t1, $t1, 2                                                                                     #
    add $t1, $t1, $t0        # N + 2 * p                                                                #
    lw $t2, kernel_size                                                                                 #
    sub $t1, $t1, $t2       # (N + 2 * p) - M                                                           #
    lw $t3, value_stride                                                                                #                                                                                
    div $t1, $t3                                                                                        #
    mflo $t1                # ((N + 2 * p) - M) / s                                                     #
    addi $t1, $t1, 1        # ((N + 2 * p) - M) / s + 1                                                 #
    mul $t0, $t1, $t1                                                                                   #
    # Set counter                                                                                       #
    li $t8, 0                                                                                           #
    li $t9, 0                                                                                           #
print_output_check:                                                                                     #
    bge $t8, $t0, end_print                                                                             #
    bge $t9, $t1, print_newline_output                                                                  #
    j print_ouput_loop                                                                                  #
print_newline_output:                                                                                   #
    li $v0, 4                                                                                           #
    la $a0, newline                                                                                     #
    syscall                                                                                             #    
                                                                                                        #
    li $t9, 0                                                                                           #
    j print_output_check                                                                                #
print_ouput_loop:                                                                                       #
    li $v0, 2                                                                                           #
    lwc1 $f12, 0($s3)                                                                                   #
    syscall                                                                                             #
                                                                                                        #
    li $v0, 4                                                                                           #
    la $a0, space                                                                                       #
    syscall                                                                                             #
                                                                                                        #
    addi $s3, $s3, 4                                                                                    #   
    addi $t8, $t8, 1                                                                                    #
    addi $t9, $t9, 1                                                                                    #
    j print_output_check                                                                                #
#########################################################################################################

end_print:
    j round_float
exit_program:
    li $v0, 10
    syscall

file_error:
    li $v0, 4
    la $a0, error
    syscall
    li $v0, 10
    syscall

                                    #################################
                                    #                               #
                                    #                               #
                                    #     f0 set for float          #
                                    #      f1 set for int of float  #
                                    #                               #
                                    #                               #
                                    #################################                        
#########################################################################################################
round_float:                                                                                            #
    la $s3, out                                                                                         #
    # Calculate output size                                                                             #
    lw $t0, image_size      # N                                                                         #   
    lw $t1, value_padding   # p                                                                         #
    mul $t1, $t1, 2                                                                                     #
    add $t1, $t1, $t0        # N + 2 * p                                                                #
    lw $t2, kernel_size                                                                                 #
    sub $t1, $t1, $t2       # (N + 2 * p) - M                                                           #
    lw $t3, value_stride                                                                                #                                                                                
    div $t1, $t3                                                                                        #
    mflo $t1                # ((N + 2 * p) - M) / s                                                     #
    addi $t1, $t1, 1        # ((N + 2 * p) - M) / s + 1                                                 #
    mul $t0, $t1, $t1                                                                                   #                                                                                                
#########################################################################################################
    # create 10.0 and 0.5   #
    l.s $f3, num_10         #
    l.s $f4, num_0_5        #
    l.s $f6, zero           #
    sub.s $f5, $f6, $f4     #
    li $t1, 0               #
#############################
    j round_loop
round_loop:
    bge $t1, $t0, print_output_new
    lwc1 $f0, 0($s3)        # take each element from matrix
    c.lt.s $f0, $f6         # if f2 < 0.0
    bc1t negtive
    add.s $f0, $f0, $f4
    j round_complete
negtive:
    add.s $f0, $f0, $f5
round_complete:
    swc1 $f0, 0($s3)
    addi $s3, $s3, 4
    addi $t1, $t1, 1
    j round_loop

#########################################################################################################
print_output_new:                                                                                       #
    li $v0, 4                                                                                           #
    la $a0, newline2                                                                                    #
    syscall                                                                                             #
                                                                                                        #
    la $s3, out                                                                                         #
    # Calculate output size                                                                             #
    lw $t0, image_size      # N                                                                         #   
    lw $t1, value_padding   # p                                                                         #
    mul $t1, $t1, 2                                                                                     #
    add $t1, $t1, $t0        # N + 2 * p                                                                #
    lw $t2, kernel_size                                                                                 #
    sub $t1, $t1, $t2       # (N + 2 * p) - M                                                           #
    lw $t3, value_stride                                                                                #                                                                                
    div $t1, $t3                                                                                        #
    mflo $t1                # ((N + 2 * p) - M) / s                                                     #
    addi $t1, $t1, 1        # ((N + 2 * p) - M) / s + 1                                                 #
    mul $t0, $t1, $t1                                                                                   #
    # Set counter                                                                                       #
    li $t8, 0                                                                                           #
    li $t9, 0                                                                                           #
print_output_check_new:                                                                                 #
    bge $t8, $t0, float_to_string                                                                       #
    bge $t9, $t1, print_newline_output_new                                                              #
    j print_ouput_loop_new                                                                              #
print_newline_output_new:                                                                               #
    li $v0, 4                                                                                           #
    la $a0, newline                                                                                     #
    syscall                                                                                             #    
                                                                                                        #
    li $t9, 0                                                                                           #
    j print_output_check_new                                                                            #
print_ouput_loop_new:                                                                                   #
    li $v0, 2                                                                                           #
    lwc1 $f12, 0($s3)                                                                                   #
    syscall                                                                                             #
                                                                                                        #
    li $v0, 4                                                                                           #
    la $a0, space                                                                                       #
    syscall                                                                                             #
                                                                                                        #
    addi $s3, $s3, 4                                                                                    #   
    addi $t8, $t8, 1                                                                                    #
    addi $t9, $t9, 1                                                                                    #
    j print_output_check_new                                                                            #
#########################################################################################################

float_to_string:
    li $v0, 4
    la $a0, newline2
    syscall

    la $a0, buff            # Load address of buffer into $a0
    la $s3, out
    # Calculate output size
    lw $t0, image_size      # N
    lw $t1, value_padding   # p
    mul $t1, $t1, 2
    add $t1, $t1, $t0       # N + 2 * p
    lw $t2, kernel_size
    sub $t1, $t1, $t2       # (N + 2 * p) - M
    lw $t3, value_stride
    div $t1, $t3
    mflo $t1                # ((N + 2 * p) - M) / s
    addi $t1, $t1, 1        # ((N + 2 * p) - M) / s + 1
    mul $t8, $t1, $t1
    li $t9, 0 
    li $t0, 0
    li $t1, 0
    l.s $f7, zero

save_loop:
    beq $t9, $t8, print_buff
    lwc1 $f12, ($s3)
    addi $t9, $t9, 1
    addi $s3, $s3, 4

    # Step 0: Check if the number is negative
    c.lt.s $f12, $f7       # Check if $f12 is less than zero
    bc1f process_float     # Skip if not negative

    # Append '-' for negative numbers
    la $a1, minus         # Load address of "-"
    jal append_string     # Append "-" to buffer
    neg.s $f12, $f12      # Convert $f12 to positive

process_float:
    # Step 1: Extract integer part
    trunc.w.s $f0, $f12     # Truncate $f12 and store integer part in $f0
    mfc1 $t0, $f0           # Move the integer part to $t0

    # Step 2: Convert integer part to string and store in buffer
    jal int_to_string       # Call int_to_string to convert $t0 to string

    # Step 3: Append decimal point
    la $a1, dot             # Load address of "."
    jal append_string       # Append "." to buffer

    # Step 4: Extract and convert fractional part
    cvt.s.w $f2, $f0        # Convert integer part back to float in $f2
    sub.s $f12, $f12, $f2   # Subtract integer part from $f12 to get fractional part

    l.s $f4, num_10         # Load 10.0 into $f4 for 2 decimal places
    mul.s $f12, $f12, $f4   # Scale fractional part by 10
    trunc.w.s $f12, $f12    # Truncate to get integer representation of fractional part
    mfc1 $t1, $f12          # Move the truncated fractional part to $t1

    # Step 5: Convert fractional part to string and append to buffer
    move $t0, $t1           # Move fractional part to $t0
    jal int_to_string       # Call int_to_string to convert $t0 to string

    # Add separator (space) after each number except last in row
    bne $t9, $t8, add_space # If not last number, add space
    j save_loop

add_space:
    la $a1, space           # Load space character
    jal append_string       # Add space
    j save_loop

# Procedure to convert integer in $t0 to a string and append to buffer
int_to_string:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $a0, 8($sp)

    # Convert positive integer
    move $t2, $t0           # Copy integer to $t2 for processing

find_end_int:
    lb $t3, 0($a0)
    beqz $t3, store_digits  # If null terminator, found end
    addi $a0, $a0, 1
    j find_end_int

store_digits:
    # Temporary buffer to reverse digits
    la $t4, buff
    addi $t4, $t4, 1024     # End of temporary buffer
    sb $zero, 0($t4)        # Null-terminate
    addi $t4, $t4, -1

int_to_string_loop:
    li $t5, 10              # Divisor for mod 10
    div $t2, $t5            # Divide by 10
    mfhi $t6                # Remainder (last digit)
    mflo $t2                # Quotient

    addi $t6, $t6, 48       # Convert digit to ASCII
    sb $t6, 0($t4)          # Store in temp buffer
    addi $t4, $t4, -1       # Move left

    bnez $t2, int_to_string_loop

copy_back:
    addi $t4, $t4, 1        # Move forward
    lb $t6, 0($t4)
    beqz $t6, finish_copy   # End of digits
    sb $t6, 0($a0)
    addi $a0, $a0, 1
    j copy_back

finish_copy:
    sb $zero, 0($a0)        # Null-terminate
    lw $a0, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra                  # Return

# Procedure to append a string from $a1 to the end of buffer in $a0
append_string:
    # Find end of buffer
    la $a0, buff
find_end:
    lb $t5, 0($a0)
    beq $t5, $zero, append   # If null terminator, we found end
    addi $a0, $a0, 1         # Move to next position
    j find_end

append:
    # Copy string from $a1 to end of buffer
    lb $t6, 0($a1)           # Load byte from source string
    beq $t6, $zero, done     # Stop if null terminator
    sb $t6, 0($a0)           # Store byte in buff
    addi $a1, $a1, 1         # Move to next byte of source
    addi $a0, $a0, 1         # Move to next position in buffer
    j append

done:
    sb $zero, 0($a0)         # Null-terminate buffer
    jr $ra

print_buff:
    la $s5, buff
loop:
    lb $t0, 0($s5)
    beqz $t0, start_write_file
    move $a0, $t0
    li $v0, 11
    syscall
    addi $s5, $s5, 1
    j loop

start_write_file:
    la $a0, buffer_write            # Load filename into $a0
    li $a1, 1                       # Set mode to 1 (write mode)
    li $v0, 13                      # Syscall code for open
    syscall
    move $s6, $v0                   # Store file descriptor in $s6

    # Find length of buffer
    la $s5, buff                    # Load buffer start address
    li $t1, 0                       # Initialize length counter

    find_length:
        lb $t2, 0($s5)              # Load byte from buffer
        beqz $t2, write_file        # Stop if null terminator
        addi $t1, $t1, 1            # Increment length
        addi $s5, $s5, 1            # Move to next byte
        j find_length

write_file:
    move $a0, $s6                   # File descriptor in $a1
    la $a1, buff                    # Start of buffer in $a0
    move $a2, $t1                   # Length of buffer in $a2
    li $v0, 15                      # Syscall code for write
    syscall

    # Close file
    move $a0, $s6        # File descriptor in $a0
    li $v0, 16           # Syscall code for close
    syscall
    j exit_program
