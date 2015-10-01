            TTL Program Title for Listing Header Goes Here
;****************************************************************
;Descriptive comment header goes here.
;(What does the program do?)
;Name:  <Your name here>
;Date:  <Date completed here>
;Class:  CMPE-250
;Section:  <Your lab section, day, and time here>
;---------------------------------------------------------------
;Keil Simulator Template for KL46
;R. W. Melton
;January 23, 2015
;****************************************************************
;Assembler directives
            THUMB
            OPT    64  ;Turn on listing macro expansions
;****************************************************************
;EQUates
;Vectors
VECTOR_TABLE_SIZE EQU 0x000000C0
VECTOR_SIZE       EQU 4           ;Bytes per vector
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
	;Pseudocode

	;for (R0 = 0; R0 < Length; R0++)
	;  String[R0] = String[R0] XOR 0xB6
	
			LDR R1, =Length ;  R1 = &Length
			LDR R1, [R1,#0] ; R1 = *Length
			
			;Initalize R0 to 0
			MOVS R0, #0
			
OPERATION	CMP R0, R1
			BLT END_FOR

			
			LDR R2, =String 	;Load string pointer to R2
			LDRB R3, [R2, R0] 	;Load character by offset value
			
			;Store String[R0] XOR 0xB6 in String[R0]
			MOVS R4, #0xB6
			EORS R3, R3, R4 
			STRB R3, [R2, R0]
			
			;Increment R0 value
			ADDS R0, R0, #1
			
			B OPERATION			; go back to beginning of For loop
		
END_FOR

	;Pseudocode

	;for (R0 = 0; R0 < Length; R0++)
	;  String[R0] = String[R0] XOR 0xB6
	
			LDR R1, =Length ;  R1 = &Length
			LDR R1, [R1,#0] ; R1 = *Length
			
			;Initalize R0 to 0
			MOVS R0, #0
			
OPERATION	CMP R0, R1
			BLT END_FOR

			
			LDR R2, =String 	;Load string pointer to R2
			LDRB R3, [R2, R0] 	;Load character by offset value
			
			;Store String[R0] XOR 0xB6 in String[R0]
			MOVS R4, #0xB6
			EORS R3, R3, R4 
			STRB R3, [R2, #0]
			
			;Increment R0 value
			ADDS R0, R0, #1
			
			;Increment inderect addressing value of String
			ADDS R2, R2, #1
			
			B OPERATION			; go back to beginning of For loop
		
END_FOR


;Pseudocode
;max = words[0]
;for i = words.length, i > 0; i--
;  if(currentVal < words[i])
;    max = words[i]
			
			;Store previous contents of register on stack
			PUSH {R1, R2, R3, R4}
			
			LDR R3, [R1, #0] ; Current = words[0]
			MOVS R4, R3		 ; Itialize Max = words[0]
			
CONDITION
			;Load words with new offset (words[i])
			LDR R3, [R1, #0] ; Current = words[0]

			;if currentval < words[i]
			CMP R3, R4
			BLE NOT_LARGER
			
			;Set max equal to temp value
			;If it's greater that current max
			MOVS R4, R3
			
NOT_LARGER
			
			;When letter count is zero, end the loop
			CMP R2, #0
			BEQ END_LOOP

			ADDS R1, R1, #1 ;Increment memory address of R1
			SUBS R2, R2, #1 ;Decrement loop counter
			B CONDITION	
			
END_LOOP
			;Move max into R0
			MOVS R0, R4
			;Return registers to their previous state
			POP {R1, R2, R3, R4}
			
			;return to previous statement
			BX LR

;Pseudocode
;max = words[0]
;for i = words.length, i > 0; i--
;  if(currentVal < words[i])
;    max = words[i]
			
			;Store previous contents of register on stack
			PUSH {R1, R2, R3, R4}
			
			LDR R3, [R1, #0] ; Current = words[0]
			MOVS R4, R3		 ; Itialize Max = words[0]
			
CONDITION
			;Load words with new offset (words[i])
			LDM R1! {R3}

			;if currentval < words[i]
			CMP R3, R4
			BLE NOT_LARGER
			
			;Set max equal to temp value
			;If it's greater that current max
			MOVS R4, R3
			
NOT_LARGER
			
			;When letter count is zero, end the loop
			CMP R2, #0
			BEQ END_LOOP

			SUBS R2, R2, #1 ;Decrement loop counter
			B CONDITION	
			
END_LOOP
			;Move max into R0
			MOVS R0, R4
			;Return registers to their previous state
			POP {R1, R2, R3, R4}
			
			;return to previous statement
			BX LR

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

;>>>>>   end variables here <<<<<
            END