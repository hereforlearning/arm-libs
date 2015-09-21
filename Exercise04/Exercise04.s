      TTL Program Title for Listing Header Goes Here
;****************************************************************
;Implementation and test procedure for a simple 
;division subroutine. Given Registers R0 and R1, the
;subroutine will provide R1 / R0 = R0 remainder R1 as output
;Setting the C flag to 1 if div by zero occurs and 0 otherwise.
;Name:  Justin Peterson
;Date:  09/17/2015
;Class:  CMPE-250
;Section:  03 TR 2-4 PM
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
	
;Custom EQUates
MAX_DATA EQU 25
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

			BL InitData			;Call InitData subroutine
			
CHECK_DIV	BL	LoadData		;Call LoadData subroutine
			
			BCS	END_PROGRAM		;Out of data to provide, program ends.
			
			;Load values for P and Q.
			LDR R0, =Q
			LDR R1, =P
			
			LDR R0, [R0, #0]
			LDR R1, [R1, #0]

			BL DIVU ;Call the division subroutine
			
			BCS DIV_ZERO
			B	STR_VARS
			
DIV_ZERO
			MOVS R0, #0
			MOVS R1, #0
			SUBS R0, R0, #1
			SUBS R1, R1, #1
					
STR_VARS			
			;Store values in P and Q
			LDR R3, =P	  			; R3 <- &P
			STR R0, [R3, #0]  		; P <- R0
			
			LDR R3, =Q	  			; R3 <- &Q
			STR R1, [R3, #0]  		; Q <- R1
			
			BL TestData ;Call the TestData subroutine
			
			B CHECK_DIV
			
;>>>>>   end main program code <<<<<

;Stay here
END_PROGRAM
            B       .
;---------------------------------------------------------------
;>>>>> begin subroutine code <<<<<
;****************************************************************

DIVU
			PUSH {R2,R3}		; Preserve state of Registers, will be using for computation
			CMP R0, #0
			BEQ	SET_C
			B NO_ERR 
			
SET_C
			
			MRS R2, APSR
			MOVS R3, #0x20
			LSLS R3, R3, #24
			ORRS R2, R2, R3
			MSR APSR, R2
			
			B RETURN
NO_ERR		
			MOVS R2, #0 		; Move beginning quotient to R2
			
DIVIDE_OP			
			CMP R1, R0
			BLO END_DIVIDE_WHILE
			
			SUBS R1, R1, R0 	; R1 = dividend - divisor
			ADDS R2, R2, #1 	; Quotient += 1
			
			B DIVIDE_OP
			
END_DIVIDE_WHILE
			MOVS R0, R2
			
			MRS R2, APSR
			MOVS R3, #0x20
			LSLS R2, R2, #24
			BICS R2, R2, R3
			MSR	APSR, R2
			
RETURN		
			POP {R2, R3}		;Return registers to previous state
			BX LR 				;Jump out of subroutine
			
			
			
;>>>>>   end custom subroutine code <<<<<
            ALIGN
				
;Machine code provided for Exercise Four
;R. W. Melton 9/14/2015
;Place at the end of your MyCode AREA
            AREA    |.ARM.__at_0x4000|,CODE,READONLY
InitData    DCI.W   0x26002700
            DCI     0x4770
LoadData    DCI.W   0xB40FA316
            DCI.W   0x19DBA13D
            DCI.W   0x428BD209
            DCI.W   0xCB034A10
            DCI.W   0x4B116010
            DCI.W   0x60193708
            DCI.W   0x20000840
            DCI.W   0xBC0F4770
            DCI.W   0x20010840
            DCI     0xE7FA
TestData    DCI.W   0xB40F480C
            DCI.W   0xA13419C0
            DCI.W   0x19C93808
            DCI.W   0x39084A07
            DCI.W   0x4B076812
            DCI.W   0x681BC00C
            DCI.W   0x68084290
            DCI.W   0xD1046848
            DCI.W   0x4298D101
            DCI.W   0xBC0F4770
            DCI.W   0x1C76E7FB
            ALIGN
PPtr        DCD     P
QPtr        DCD     Q
ResultsPtr  DCD     Results
            DCQ     0x0000000000000000,0x0000000000000001
            DCQ     0x0000000100000000,0x0000000100000010
            DCQ     0x0000000200000010,0x0000000400000010
            DCQ     0x0000000800000010,0x0000001000000010
            DCQ     0x0000002000000010,0x0000000100000007
            DCQ     0x0000000200000007,0x0000000300000007
            DCQ     0x0000000400000007,0x0000000500000007
            DCQ     0x0000000600000007,0x0000000700000007
            DCQ     0x0000000800000007,0x8000000080000000
            DCQ     0x8000000180000000,0x000F0000FFFFFFFF
            DCQ     0xFFFFFFFFFFFFFFFF,0xFFFFFFFFFFFFFFFF
            DCQ     0x0000000000000000,0x0000000000000010
            DCQ     0x0000000000000008,0x0000000000000004
            DCQ     0x0000000000000002,0x0000000000000001
            DCQ     0x0000001000000000,0x0000000000000007
            DCQ     0x0000000100000003,0x0000000100000002
            DCQ     0x0000000300000001,0x0000000200000001
            DCQ     0x0000000100000001,0x0000000000000001
            DCQ     0x0000000700000000,0x0000000000000001
            DCQ     0x8000000000000000,0x0000FFFF00001111
            ALIGN
;****************************************************************
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
P			SPACE	4
Q			SPACE	4
Results		SPACE	200
;>>>>>   end variables here <<<<<
            END