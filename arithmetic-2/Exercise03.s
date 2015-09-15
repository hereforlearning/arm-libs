            TTL Memory, Conditional Branching, and Debugging Tools
			
;****************************************************************
;this program evaluates a system of equations with three
;input variables and then sums their result. 
; 
;Name:Justin Peterson
;Date:09/10/2015
;Class:CMPE-250
;Section:03 - TR 2-4 PM
;---------------------------------------------------------------
;Keil Simulator Template for KL46
;R. W. Melton
;January 23, 2015
;****************************************************************
;Assembler directives
            THUMB
            OPT    64  			  ;Turn on listing macro expansions
;****************************************************************
;EQUates
;Vectors
VECTOR_TABLE_SIZE EQU 0x000000C0
VECTOR_SIZE       EQU 4           ;Bytes per vector

;Shift Amounts
;****************************************************************
MULT2		  	  EQU 1			  ;Logical shift by 1 = 2^1 = 2
MULT4		  	  EQU 2    		  ;Logical shift by 2 = 2^2 = 4
SHIFT24		  	  EQU 24    	  ;Logical shift by 24 bits. Conv to most sig. word
	
;Stack
SSTACK_SIZE EQU  0x00000100
;****************************************************************
;Program
;Linker requires Reset_Handler
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
Reset_Handler
main
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<
			
			;Load memory addresses for P, Q, R, and result
			LDR R1, =P
			LDR R2, =Q
			LDR R3, =R
			LDR R7, =result
			
			;Load variable values from addresses into registers
			LDR R1, [R1, #0]
			LDR R2, [R2, #0]
			LDR R3, [R3, #0]
			LDR R7, [R7, #0]
			
			;Compute for F [2P - 3Q + R + 51]
			;--------------------------------------
			MOVS R4, #0				; Initalize R4 to Zero
			
			LSLS R5, R1, #MULT2     ; Multiply P by 2
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDF
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDF
			
			LSLS R6, R2, #MULT2     ; Multiply Q by 2
			ADDS R6, R6, R2 		; Add Q to 2Q to make 3Q
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDF
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDF
			
			SUBS R5, R5, R6 		; R5 = 2P - 3Q
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDF
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDF
			
			ADDS R5, R5, R3 		; Add R to (2P - 3Q)
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDF
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDF
			
			ADDS R5, R5, #51 		; Add 51 to final result
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDF
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDF
			
			MOVS R4, R5				; If all goes well, move R5 to R4
					
ENDF			
			LDR R6, =F	  			; R6 <- &F
			STR R4, [R6, #0]  		; F <- R4
			
			
			;Compute for G [5P - 4Q -2R + 7]
			;Shifting to most significant byte
			;to simulate and check for overflow
			;-----------------------------------------
			
			MOVS R4, #0 			; Refresh state of R4
			
			LSLS R5, R1, #MULT4 	; R5 = 4 * P
			
			ADDS R5, R5, R1			; R5 = 4P + P = 5P
			
			LSLS R6, R2, #MULT4 	; R6 = 4Q
			LSLS R7, R3, #MULT2 	; R7 = 2R
			
			;Shift P, Q, and R to most significant byte
			LSLS R5, R5, #SHIFT24
			LSLS R6, R6, #SHIFT24
			LSLS R7, R7, #SHIFT24
			
			SUBS R5, R5, R6			; R5 = 5P - 4Q
			BVS ENDG 				; Check for overflow
		
			SUBS R5, R5, R7			; R5 = R5 - 2R
			BVS ENDG				; Check for overflow
		 
									;In order to add 7, shift left 24 bits, add, and check	
			MOVS R6, #7
			LSLS R6, R6, #SHIFT24
			ADDS R5, R5, R6	        ; R5 = R5 + (shift) 7
			BVS ENDG				; Check for overflow
			
			LSLS R5, R1, #MULT4 	; R5 = 4 * P
			ADDS R5, R5, R1			; R5 = 4P + P = 5P
			
			LSLS R6, R2, #MULT4     ; R6 = 4Q
			LSLS R7, R3, #MULT2     ; R7 = 2R
			
			SUBS R5, R5, R6			; R5 = 5P - 4Q
			SUBS R5, R5, R7			; R5 = R5 - 2R
			ADDS R5, R5, #7			; R5 = R5 + 7
			
			MOVS R4, R5 			; If all goes well, move R5 to R4
			
ENDG			
			LDR R6, =G	  			; R6 <- &G
			STR R4, [R6, #0]  		; G <- R4
			
			
			;Compute for H [P - 2Q + R - 91]
			;-----------------------------------------
			MOVS R5, R1				; Move P into R5
			LSLS R6, R2, #MULT2     ; R6 = 2Q
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R6, #127			; Compare to 127
			BGT	 ENDH
			CMN  R6, #-128			; Compare to -128
			BGT	 ENDH
			
			MOVS R7, R3				; Move R into R7
			
			SUBS R5, R5, R6			; R5 = P - 2Q
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDH
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDH
			
			ADDS R5, R5, R7			; R5 = R5 + R
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDH
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDH
			
			SUBS R5, R5, #91		; R5 = R5 - 91
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			
			CMP  R5, #127			; Compare to 127
			BGT	 ENDH
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDH
			
			MOVS R4, R5	        	; If all goes well, move R5 to R4

ENDH
			LDR R6, =H	  			; R6 <- &H
			STR R4, [R6, #0]  		; H <- R4
			
			
			;Compute for result [F + G + H]
			;-----------------------------------------
			LDR R1, =F
			LDR R2, =G
			LDR R3, =H
			
			LDR R1, [R1, #0]
			LDR R2, [R2, #0]
			LDR R3, [R3, #0]
			
			ADDS R5, R1, R2 		; R5 <- F + G
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDRESULT
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDRESULT
			
			ADDS R5, R5, R3			; R5 <- F + G + H
			
			;If op results in > 127 or < -128
			;Set final to zero and return
			CMP  R5, #127			; Compare to 127
			BGT	 ENDRESULT
			CMN  R5, #-128			; Compare to -128
			BGT	 ENDRESULT
			
			MOVS R4, R5				; If all goes well, move R5 to R4

ENDRESULT
			LDR R6, =result			; R6 <- &result
			STR R4, [R6, #0]		; result <- R4
				
			
;>>>>>   end main program code <<<<<
;Stay here
            B       .
;---------------------------------------------------------------
;>>>>> begin subroutine code <<<<<
;>>>>>   end subroutine code <<<<<
            ALIGN
;****************************************************************
;Vector Table Mapped to Address 0 at Reset
;Linker requires __Vectors to be exported
            AREA    RESET, DATA, READONLY
            EXPORT  __Vectors
            EXPORT  __Vectors_End
            EXPORT  __Vectors_Size
__Vectors 
                                      ;ARM core vectors
            DCD    __initial_sp       ;00:end of stack
            DCD    Reset_Handler      ;reset vector
            SPACE  (VECTOR_TABLE_SIZE - (2 * VECTOR_SIZE))
__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors
            ALIGN
;****************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<
const_F		DCD 	51
const_G		DCD		7
const_H		DCD		-91
;>>>>>   end constants here <<<<<
;****************************************************************
            AREA    |.ARM.__at_0x1FFFE000|,DATA,READWRITE,ALIGN=3
            EXPORT  __initial_sp
;Allocate system stack
            IF      :LNOT::DEF:SSTACK_SIZE
SSTACK_SIZE EQU     0x00000100
            ENDIF
Stack_Mem   SPACE   SSTACK_SIZE
__initial_sp
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
F			SPACE	4
G			SPACE	4
H			SPACE	4
P			SPACE	4
Q			SPACE	4
R			SPACE	4
result		SPACE	4
					
;>>>>>   end variables here <<<<<
            END
