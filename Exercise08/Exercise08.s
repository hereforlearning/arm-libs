	TTL Exercise 08 String Operations
		
;****************************************************************
;Date:  10/22/2015
;Class:  CMPE-250
;Section:  03 TR 2-4PM
;Implementation of laboratory exercise 08: String Operations
;Command line interface to perform reversal, character subsitution,
;and copying of input strings in memory
;---------------------------------------------------------------
;Keil Template for KL46
;R. W. Melton
;April 3, 2015
;****************************************************************
;Assembler directives
            THUMB
            OPT    64  ;Turn on listing macro expansions
;****************************************************************
;Include files
            GET  MKL46Z4.s     ;Included by start.s
            OPT  1   ;Turn on listing
;****************************************************************
;EQUates

;---------------------------------------------------------------
;PORTx_PCRn (Port x pin control register n [for pin n])
;___->10-08:Pin mux control (select 0 to 8)
;Use provided PORT_PCR_MUX_SELECT_2_MASK
;---------------------------------------------------------------
;Port A
PORT_PCR_SET_PTA1_UART0_RX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
PORT_PCR_SET_PTA2_UART0_TX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
;---------------------------------------------------------------
;SIM_SCGC4
;1->10:UART0 clock gate control (enabled)
;Use provided SIM_SCGC4_UART0_MASK
;---------------------------------------------------------------
;SIM_SCGC5
;1->09:Port A clock gate control (enabled)
;Use provided SIM_SCGC5_PORTA_MASK
;---------------------------------------------------------------
;SIM_SOPT2
;01=27-26:UART0SRC=UART0 clock source select
;         (PLLFLLSEL determines MCGFLLCLK' or MCGPLLCLK/2)
; 1=   16:PLLFLLSEL=PLL/FLL clock select (MCGPLLCLK/2)
SIM_SOPT2_UART0SRC_MCGPLLCLK  EQU  \
                                 (1 << SIM_SOPT2_UART0SRC_SHIFT)
SIM_SOPT2_UART0_MCGPLLCLK_DIV2 EQU \
    (SIM_SOPT2_UART0SRC_MCGPLLCLK :OR: SIM_SOPT2_PLLFLLSEL_MASK)
;---------------------------------------------------------------
;SIM_SOPT5
; 0->   16:UART0 open drain enable (disabled)
; 0->   02:UART0 receive data select (UART0_RX)
;00->01-00:UART0 transmit data select source (UART0_TX)
SIM_SOPT5_UART0_EXTERN_MASK_CLEAR  EQU  \
                               (SIM_SOPT5_UART0ODE_MASK :OR: \
                                SIM_SOPT5_UART0RXSRC_MASK :OR: \
                                SIM_SOPT5_UART0TXSRC_MASK)
;---------------------------------------------------------------
;UART0_BDH
;    0->  7:LIN break detect IE (disabled)
;    0->  6:RxD input active edge IE (disabled)
;    0->  5:Stop bit number select (1)
;00001->4-0:SBR[12:0] (UART0CLK / [9600 * (OSR + 1)]) 
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDH_9600  EQU  0x01
;---------------------------------------------------------------
;UART0_BDL
;26->7-0:SBR[7:0] (UART0CLK / [9600 * (OSR + 1)])
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDL_9600  EQU  0x38
;---------------------------------------------------------------
;UART0_C1
;0-->7:LOOPS=loops select (normal)
;0-->6:DOZEEN=doze enable (disabled)
;0-->5:RSRC=receiver source select (internal--no effect LOOPS=0)
;0-->4:M=9- or 8-bit mode select 
;        (1 start, 8 data [lsb first], 1 stop)
;0-->3:WAKE=receiver wakeup method select (idle)
;0-->2:IDLE=idle line type select (idle begins after start bit)
;0-->1:PE=parity enable (disabled)
;0-->0:PT=parity type (even parity--no effect PE=0)
UART0_C1_8N1  EQU  0x00
;---------------------------------------------------------------
;UART0_C2
;0-->7:TIE=transmit IE for TDRE (disabled)
;0-->6:TCIE=transmission complete IE for TC (disabled)
;0-->5:RIE=receiver IE for RDRF (disabled)
;0-->4:ILIE=idle line IE for IDLE (disabled)
;1-->3:TE=transmitter enable (enabled)
;1-->2:RE=receiver enable (enabled)
;0-->1:RWU=receiver wakeup control (normal)
;0-->0:SBK=send break (disabled, normal)
UART0_C2_T_R  EQU  (UART0_C2_TE_MASK :OR: UART0_C2_RE_MASK)
;---------------------------------------------------------------
;UART0_C3
;0-->7:R8T9=9th data bit for receiver (not used M=0)
;           10th data bit for transmitter (not used M10=0)
;0-->6:R9T8=9th data bit for transmitter (not used M=0)
;           10th data bit for receiver (not used M10=0)
;0-->5:TXDIR=UART_TX pin direction in single-wire mode
;            (no effect LOOPS=0)
;0-->4:TXINV=transmit data inversion (not inverted)
;0-->3:ORIE=overrun IE for OR (disabled)
;0-->2:NEIE=noise error IE for NF (disabled)
;0-->1:FEIE=framing error IE for FE (disabled)
;0-->0:PEIE=parity error IE for PF (disabled)
UART0_C3_NO_TXINV  EQU  0x00
;---------------------------------------------------------------
;UART0_C4
;    0-->  7:MAEN1=match address mode enable 1 (disabled)
;    0-->  6:MAEN2=match address mode enable 2 (disabled)
;    0-->  5:M10=10-bit mode select (not selected)
;01111-->4-0:OSR=over sampling ratio (16)
;               = 1 + OSR for 3 <= OSR <= 31
;               = 16 for 0 <= OSR <= 2 (invalid values)
UART0_C4_OSR_16           EQU  0x0F
UART0_C4_NO_MATCH_OSR_16  EQU  UART0_C4_OSR_16
;---------------------------------------------------------------
;UART0_C5
;  0-->  7:TDMAE=transmitter DMA enable (disabled)
;  0-->  6:Reserved; read-only; always 0
;  0-->  5:RDMAE=receiver full DMA enable (disabled)
;000-->4-2:Reserved; read-only; always 0
;  0-->  1:BOTHEDGE=both edge sampling (rising edge only)
;  0-->  0:RESYNCDIS=resynchronization disable (enabled)
UART0_C5_NO_DMA_SSR_SYNC  EQU  0x00
;---------------------------------------------------------------
;UART0_S1
;0-->7:TDRE=transmit data register empty flag; read-only
;0-->6:TC=transmission complete flag; read-only
;0-->5:RDRF=receive data register full flag; read-only
;1-->4:IDLE=idle line flag; write 1 to clear (clear)
;1-->3:OR=receiver overrun flag; write 1 to clear (clear)
;1-->2:NF=noise flag; write 1 to clear (clear)
;1-->1:FE=framing error flag; write 1 to clear (clear)
;1-->0:PF=parity error flag; write 1 to clear (clear)
UART0_S1_CLEAR_FLAGS  EQU  0x1F
;---------------------------------------------------------------
;UART0_S2
;1-->7:LBKDIF=LIN break detect interrupt flag (clear)
;             write 1 to clear
;1-->6:RXEDGIF=RxD pin active edge interrupt flag (clear)
;              write 1 to clear
;0-->5:(reserved); read-only; always 0
;0-->4:RXINV=receive data inversion (disabled)
;0-->3:RWUID=receive wake-up idle detect
;0-->2:BRK13=break character generation length (10)
;0-->1:LBKDE=LIN break detect enable (disabled)
;0-->0:RAF=receiver active flag; read-only
UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS  EQU  0xC0
;---------------------------------------------------------------
;Max length of prompt string
MAX_STRING 				EQU 79


;****************************************************************
;Program
;Linker requires Reset_Handler
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
            IMPORT  Startup
Reset_Handler
main
;---------------------------------------------------------------
;Mask interrupts
            CPSID   I
;KL46 system startup with 48-MHz system clock
            BL      Startup
			BL      Init_UART0_Polling
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<

			;Initalize the op-string with the default value
			LDR R0, =TestString
			LDR R1, =ResultString
			
			BL CopyString

PRINT_PROMPT

			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
            
			;Load static prompt string address
			LDR R0, =Prompt
			
			;Print prompt string
			BL PutStringSB

PROMPT			
			
			;Request a single character from the terminal
			BL GetChar
			MOVS R0, R3
			
			BL PutChar
			
			;If character is <= ASCII code 90, check if it's a capital letter
			CMP R0, #90
			BLE IF_LOWER
			B PARSE_COMMAND
IF_LOWER
			
			CMP R0, #65
			BGE CONVERT_TO_LOWER
			B PARSE_COMMAND
			
CONVERT_TO_LOWER
			;Convert char to lower case representation
			ADDS R0, R0, #32
			
PARSE_COMMAND
			;Check if the sanitized character is one of the inputs
			CMP R0 , #0x0D
			BEQ PRINT_NEWLINE
			CMP R0, #'g'
			BEQ GET_STRING
			CMP R0, #'h'
			BEQ PRINT_HELP
			CMP R0, #'m'
			BEQ PRINT_MODIFY
			CMP R0, #'p'
			BEQ PRINT_PUT_STRING
			CMP R0, #'r'
			BEQ PRINT_REVERSE_STRING
			
			B PRINT_INVALID
			
PRINT_INVALID
			LDR R0, =Invalid
			BL PutStringSB
			B PRINT_PROMPT
			
GET_STRING
			MOVS R1, #MAX_STRING
			
			;Get string from user and print to the terminal
			
			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			LDR R0, =EnterPrompt
			BL PutStringSB
			
			LDR R0, =ResultString
			
			BL GetStringSB
			
			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			;Print string back to the terminal
			LDR R0, =ResultString
			BL PutStringSB
			B PRINT_PROMPT
			
PRINT_HELP
			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			LDR R0, =HelpString
			BL PutStringSB
			
			B PRINT_PROMPT
			
PRINT_MODIFY

			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			LDR R0, =ResultString
			BL ModifyString
			
			BL PutStringSB
			
			B PRINT_PROMPT
			
PRINT_PUT_STRING
			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			LDR R0, =ResultString
			
			BL PutStringSB
			
			B PRINT_PROMPT
			
PRINT_REVERSE_STRING
			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			LDR R0, =ResultString
			BL ReverseString
			
			BL PutStringSB
			
			B PRINT_PROMPT

PRINT_NEWLINE
			B PRINT_PROMPT

;>>>>>   end main program code <<<<<
;Stay here
            B       .
;>>>>> begin subroutine code <<<<<

;-------------------------------------------

CopyString
;CopyString: Create a null terminated string beginning
;at the address in R1 and copy from a null terminated source 
;string that is stored in R0.

;Inputs
;	R0 - Memory address of beginning of source string

;Outputs
;	R1 - Memory address of beginning of copied string
;--------------------------------------------

	PUSH {R0, R2, R3}
	
	;Initalize offset
	MOVS R2, #0

CHECK_CHAR
	
	;Load character from the source string with
	;R2 as an offset.
	LDRB R3, [R0, R2]

	;If char is the null character, we've hit the end
	CMP R3, #0
	BEQ END_STRING_CPY
	
	;Copy character into new string at the same index
	STRB R3, [R1, R2]
	
	;Increment offset and continue the loop
	ADDS R2, R2, #1
	B CHECK_CHAR
	
	
END_STRING_CPY

	;Append a null terminator to the newly copied string
	MOVS R3, #0
	STRB R3, [R1, R2]
	
	;restore state of registers and return
	POP {R0, R2, R3}
	BX LR
	
;-------------------------------------------

ModifyString
;ModifyString: Modify string with mem address starting in R0
;to have the following properties:

; - every space is replaced with an underscore
; - every upper case character is lowercased
; - every numeric character is replaced with a pound sign

;Inputs
;	R0 - Memory address of beginning of source string

;Outputs
;	R0 - Memory address of beginning of modified string
;--------------------------------------------

	PUSH {R2, R3, R4}
	
	;Initalize offset
	MOVS R2, #0

CHECK_C

	;Load character from the source string with
	;R2 as an offset.
	LDRB R3, [R0, R2]

	;If char is the null character, we've hit the end
	CMP R3, #0
	BEQ END_STRING_REPL
	
	;If character is a space, do a space replace!
	CMP R3, #32
	BEQ SPACE_REPLACE
	
	;If the character is > code 48
	;It potentially is a number or capital letter that
	;needs to be replaced in the string
	CMP R3, #48
	BGE CHECK_IF_NUM
	
CHECK_IF_NUM
	;If code is greater than value for '9', check if it's
	;a capital letter
	CMP R3, #57
	BGT CHECK_IF_CAP
	
	;Otherwise the current character is a number
	;Replace space character with a pound in memory
	MOVS R4, #0x23
	STRB R4, [R0, R2]
	
	B NEXT_C
	
CHECK_IF_CAP
	
	;Check if character code is lower than 'A'
	CMP R3, #65
	BLT NEXT_C
	
	;Check if character code is higher than 'Z'
	CMP R3, #90
	BGT NEXT_C
	
	;If char is in range of a capital, replace it
	;with its lowercase value
	ADDS R3, R3, #32
	STRB R3, [R0, R2]
	
	B NEXT_C
	
	
SPACE_REPLACE
	;Replace space character with an underscore in memory
	MOVS R4, #0x5F
	STRB R4, [R0, R2]
	
NEXT_C
	;Increment offset and continue the loop
	ADDS R2, #1
	B CHECK_C
	
	
END_STRING_REPL
	;restore state of registers and return
	POP {R2, R3, R4}
	BX LR
	
;-------------------------------------------

ReverseString
;ReverseString: Reverse the values of the null terminated
;string in memory that begins at the address stored in R0

;Keep track of two pointers incrementing from the
;beginning of the string forward and from the end of the
;string backwards. Swap characters at these two pointers and
;increment/decrement them respectively until the pointers
;end on the same character or cross one another in the
;middle of the string.

;Inputs
;	R0 - Memory address of beginning of source string

;Outputs
;	R0 - Memory address of beginning of reversed string

;Subs Used:
	;- LengthStringSB [determines length of string in memory]
;--------------------------------------------

	PUSH {R1, R2, R3, R4, R5, LR}

	;Cursor to iterate over the string
	MOVS R5, #0

	;Grab the length of the string in memory
	MOVS R1, #MAX_STRING
	BL LengthStringSB
	
	;Shave off the null pointer from end pointer
	SUBS R2, R2, #1
	
SWAP_CHARS

	;If both pointers have crossed, string reversal has ended
	CMP R5, R2
	BGE END_REVERSAL
	
	;Load last character of the string (offset = string length)
	LDRB R3, [R0, R2]
	
	;Load forward incrementing character of the string
	LDRB R4, [R0, R5]
	
	;Swap characters with one another
	STRB R3, [R0, R5]
	STRB R4, [R0, R2]
	
	;Increment forward pointer, decrement reverse
	ADDS R5, R5, #1
	SUBS R2, R2, #1
	
	B SWAP_CHARS
	
END_REVERSAL
	
	POP {R1, R2, R3, R4, R5, PC}
	

;-------------------------------------------

PutNumHex
;PutNumHex: Print hex representation of a value
;To the console. Separates each nibble via masking
;And then converts to appropriate ASCII representation
;Inputs:
    ;R0 - Value to print to the screen
;Outputs: N/A
;--------------------------------------------
        PUSH {R2, R3, R4, LR}
    
        MOVS R2, #32

HEX_PRINT_LOOP

        ;Iterate 8 times for each digit stored in a register
        CMP R2, #0
        BLT END_PRINT_HEX
        
        ;Shift current nibble to print to
        ;the rightmost value of register
        MOVS R3, R0
		MOVS R4, #0x0F
		LSRS R3, R2
		
		ANDS R4, R4, R3
		
        ;Convert to appropriate ASCII value
        CMP R4, #10
        BGE PRINT_LETTER
        
        ;If 0-9 should be printed, add ASCII '0' val
        ADDS R4, #'0'
        B PRINT_HX
        
PRINT_LETTER
        
        ;If A-F should be printed, Add ASCII '55'
        ;To convert to capital letter value
        ADDS R4, R4, #55
        
PRINT_HX
        ;Print ASCII value to the screen
        ;Make sure not to destroy vlue in R0!
        PUSH {R0}
        MOVS R0, R4
        BL PutChar
        POP {R0}
        
        ;Reset value in R3 and increment loop counter
        MOVS R4, #0
        SUBS R2, R2, #4
        B HEX_PRINT_LOOP
        
END_PRINT_HEX
       
        POP {R2, R3, R4, PC}

;--------------------------------------------

;Send a character out of UART0
;--------------------------------------------
PutChar
			PUSH {R1, R2, R3} ; Push varibles on the stack to avoid loss
			
			;Poll TDRE Until UART0 is ready for transmit
			LDR R1, =UART0_BASE
			MOVS R2, #UART0_S1_TDRE_MASK
			
PollTx
			LDRB R3, [R1, #UART0_S1_OFFSET]
			ANDS R3, R3, R2
			BEQ PollTx
			
			;Transmit Character Stored in R0
			STRB R0, [R1, #UART0_D_OFFSET]
			
			;Pop original register values off the stack
			POP {R1, R2, R3}
			
			BX LR
;--------------------------------------------
            
;Receive a character from UART0
;Store in Register R0
;--------------------------------------------
GetChar
			PUSH {R1, R2} ; Push varibles on the stack to avoid loss
			LDR R1, =UART0_BASE
			MOVS R2, #UART0_S1_RDRF_MASK
PollRx
			LDRB R3, [R1, #UART0_S1_OFFSET]
			ANDS R3, R3, R2
			BEQ	PollRx
			
			;Receive character and store in R0
			LDRB R3, [R1, #UART0_D_OFFSET]
			
			POP {R1, R2}
			BX LR
			
;--------------------------------------------

;R0 = memory location to store string
;R1 = Buffer capacity (numChars)

;--------------------------------------------
GetStringSB

		PUSH {R1, R2, R3, LR}
		MOVS R2, #0 ;Initalize string offset to zero
		
		
TAKE_INPUT
            
		;Grab the next character of input and store in R3
        BL      GetChar
		
		;check if character is a carrige return
		CMP R3, #13
		BEQ END_GET_STR
		
		;If all characters have been processed
		;and another comes in, dont echo and reset.
		CMP R1, #0
        BEQ TAKE_INPUT
		
		;Echo character to the terminal
		PUSH {R0} ;Preserve state of R0 and LR
		MOVS R0, R3 ;Move char in R3 for transit
		BL PutChar
		POP {R0}
		
		;String[i] = input char
		STRB R3, [R0, R2]
		
		;Decrement number of characters left to read
        SUBS    R1, R1, #1
		;Add to offset index for string
		ADDS	R2, R2, #1
		
        B TAKE_INPUT
		
END_GET_STR
		
		;null terminate String
		MOVS R3, #0
		STRB R3, [R0, R2]
		
		;Pop PC returns nested subroutine
		POP {R1, R2, R3, PC}
		
		
PrintCharLF
		;Print character in R0
		;In addition to a carrige return and a line feed
		;Used to produce the command 'menu' with single char inputs
		
		PUSH {R0, LR}
		;Echo the char back to the user
		BL PutChar
			
		;Print CR and LF to the screen
		MOVS R0, #0x0D
		BL PutChar
			
		MOVS R0, #0x0A
		BL PutChar
		
		POP {R0, PC}
		
;--------------------------------------------
		
;R0 = memory location of string to print
;R1 = Buffer capacity (numChars)
PutStringSB
;--------------------------------------------

		PUSH {R0, R1, R2, R3, LR}
		
		;Determine the length of the string before printing
		BL LengthStringSB
		MOVS R1, R2
		
READ_CHAR
		
		;If all characters have been processed
		;End subroutine execution
		CMP R1, #0
        BEQ END_PUT_STR
		
		;Grab the next character of input and store in R3
        LDRB R3, [R0, #0]
		
		;Echo character to the terminal
		PUSH {R0} ;Preserve state of R0 and LR
		MOVS R0, R3 ;Move char in R3 for transit
		BL PutChar
		POP {R0}
		
		;Decrement number of characters left to read
        SUBS    R1, R1, #1
		;Add to offset index for string
		ADDS	R0, R0, #1
		
        B READ_CHAR
		
END_PUT_STR

		;Pop PC returns nested subroutine
		;Return with pointer at last char of string in R0
		POP {R0, R1, R2, R3, PC}
		
;--------------------------------------------
		

;R0 = memory location of string 
;R1 = Buffer capacity (numChars)
;R2 = Output num of String length
LengthStringSB
;--------------------------------------------

		PUSH {R0, R1, R3, R4, LR}
		MOVS R1, #MAX_STRING
		MOVS R2, #0; Initalize length to zero.
		MOVS R4, #0; Initalize STR offset to zero
		
ADD_TO_LEN

		;if legth is >= buffer, return
		CMP R2, R1
        BGE END_GET_LEN
		
		;Grab the next character of input and store in R3
        LDRB R3, [R0, R4]
		
		;check if character is a null terminator
		CMP R3, #0
		BEQ END_GET_LEN
		
		;Add to string offset
		ADDS R4, R4, #1 
		;Add 1 to max
		ADDS R2, R2, #1
		
        B ADD_TO_LEN
		
END_GET_LEN

		;Pop PC returns nested subroutine
		POP {R0, R1, R3, R4, PC}
		
;--------------------------------------------

DIVU
;--------------------------------------------
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
			
;--------------------------------------------
		
Init_UART0_Polling
;--------------------------------------------
			;Allocate R0-2 for Ri=k 
			;Store prevoius values for restoration
			PUSH {R0, R1, R2}

            ;Select MCGPLLCLK / 2 as UART0 clock source
             LDR R0,=SIM_SOPT2
             LDR R1,=SIM_SOPT2_UART0SRC_MASK
             LDR R2,[R0,#0]
             BICS R2,R2,R1
             LDR R1,=SIM_SOPT2_UART0_MCGPLLCLK_DIV2
             ORRS R2,R2,R1
             STR R2,[R0,#0]
            ;Enable external connection for UART0
             LDR R0,=SIM_SOPT5
             LDR R1,= SIM_SOPT5_UART0_EXTERN_MASK_CLEAR
             LDR R2,[R0,#0]
             BICS R2,R2,R1
             STR R2,[R0,#0]
            ;Enable clock for UART0 module
             LDR R0,=SIM_SCGC4
             LDR R1,= SIM_SCGC4_UART0_MASK
             LDR R2,[R0,#0]
             ORRS R2,R2,R1
             STR R2,[R0,#0]
            ;Enable clock for Port A module
             LDR R0,=SIM_SCGC5
             LDR R1,= SIM_SCGC5_PORTA_MASK
             LDR R2,[R0,#0]
             ORRS R2,R2,R1
             STR R2,[R0,#0]
            ;Connect PORT A Pin 1 (PTA1) to UART0 Rx (J1 Pin 02)
             LDR R0,=PORTA_PCR1
             LDR R1,=PORT_PCR_SET_PTA1_UART0_RX
             STR R1,[R0,#0]
            ;Connect PORT A Pin 2 (PTA2) to UART0 Tx (J1 Pin 04)
             LDR R0,=PORTA_PCR2
             LDR R1,=PORT_PCR_SET_PTA2_UART0_TX
             STR R1,[R0,#0] 
             
             ;Disable UART0 receiver and transmitter
             LDR R0,=UART0_BASE
             MOVS R1,#UART0_C2_T_R
             LDRB R2,[R0,#UART0_C2_OFFSET]
             BICS R2,R2,R1
             STRB R2,[R0,#UART0_C2_OFFSET]
            ;Set UART0 for 9600 baud, 8N1 protocol
             MOVS R1,#UART0_BDH_9600
             STRB R1,[R0,#UART0_BDH_OFFSET]
             MOVS R1,#UART0_BDL_9600
             STRB R1,[R0,#UART0_BDL_OFFSET]
             MOVS R1,#UART0_C1_8N1
             STRB R1,[R0,#UART0_C1_OFFSET]
             MOVS R1,#UART0_C3_NO_TXINV
             STRB R1,[R0,#UART0_C3_OFFSET]
             MOVS R1,#UART0_C4_NO_MATCH_OSR_16
             STRB R1,[R0,#UART0_C4_OFFSET]
             MOVS R1,#UART0_C5_NO_DMA_SSR_SYNC
             STRB R1,[R0,#UART0_C5_OFFSET]
             MOVS R1,#UART0_S1_CLEAR_FLAGS
             STRB R1,[R0,#UART0_S1_OFFSET]
             MOVS R1, \
             #UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS
             STRB R1,[R0,#UART0_S2_OFFSET] 
             
             ;Enable UART0 receiver and transmitter
             MOVS R1,#UART0_C2_T_R
             STRB R1,[R0,#UART0_C2_OFFSET] 
                        
			;Pop prevous R0-2 values off the stack.
			POP {R0, R1, R2}

			BX LR
		

;PutNumU: Print ASCII value to terminal screen
;Inputs:
	;R0 - Character to print
;Outputs:
	;N/A
;--------------------------------------------'
PutNumU

		;Divide R0 value by 10
		;continually printing the remainder
		
		PUSH {R0, R1, R2, LR}

		;Initalize Array offset to Zero
		MOVS R2, #0
		
DIV_NUM
		;Num is too small to divide by 10
		;finish subroutine
		CMP R0, #10
		BLT COMPLETE_PUT_NUM
		
		;Move dividend to R1, set divisor to 10
		MOVS R1, R0
		MOVS R0, #10
		
		;R1 / R0 = R0 Remainder R1
		BL DIVU
		
		;Print remainder stored in R1
		PUSH {R0}
		LDR R0, =StringReversal
		
		STRB R1, [R0, R2]
		ADDS R2, R2, #1
		
		POP {R0}
		
		;repeat until num is no longer divisible by 10
		B DIV_NUM

COMPLETE_PUT_NUM

		;Convert to ASCII Value
		ADDS R0, R0, #'0'
		BL PutChar
		
		;TODO: Check if this works
		SUBS R2, R2, #1
		
PRINT_CHAR		
		;Iterate over array and print
		LDR R0, =StringReversal
		
		CMP R2, #0
		BLT END_PUTNUM
		
		LDRB R1, [R0, R2]
		MOVS R0, R1
		
		;Convert to ASCII Character and Print
		ADDS R0, R0, #'0'
		BL PutChar
		
		SUBS R2, R2, #1
	
		B PRINT_CHAR
		
END_PUTNUM
		;restore previous values to register and return
		POP {R0, R1, R2, PC}

			
;-------------------------------------------------------------------

;>>>>>   end subroutine code <<<<<
            ALIGN
;****************************************************************
;Vector Table Mapped to Address 0 at Reset
;Linker requires __Vectors to be exported
            AREA    RESET, DATA, READONLY
            EXPORT  __Vectors
            EXPORT  __Vectors_End
            EXPORT  __Vectors_Size
            IMPORT  __initial_sp
            IMPORT  Dummy_Handler
__Vectors 
                                      ;ARM core vectors
            DCD    __initial_sp       ;00:end of stack
            DCD    Reset_Handler      ;01:reset vector
            DCD    Dummy_Handler      ;02:NMI
            DCD    Dummy_Handler      ;03:hard fault
            DCD    Dummy_Handler      ;04:(reserved)
            DCD    Dummy_Handler      ;05:(reserved)
            DCD    Dummy_Handler      ;06:(reserved)
            DCD    Dummy_Handler      ;07:(reserved)
            DCD    Dummy_Handler      ;08:(reserved)
            DCD    Dummy_Handler      ;09:(reserved)
            DCD    Dummy_Handler      ;10:(reserved)
            DCD    Dummy_Handler      ;11:SVCall (supervisor call)
            DCD    Dummy_Handler      ;12:(reserved)
            DCD    Dummy_Handler      ;13:(reserved)
            DCD    Dummy_Handler      ;14:PendableSrvReq (pendable request 
                                      ;   for system service)
            DCD    Dummy_Handler      ;15:SysTick (system tick timer)
            DCD    Dummy_Handler      ;16:DMA channel 0 xfer complete/error
            DCD    Dummy_Handler      ;17:DMA channel 1 xfer complete/error
            DCD    Dummy_Handler      ;18:DMA channel 2 xfer complete/error
            DCD    Dummy_Handler      ;19:DMA channel 3 xfer complete/error
            DCD    Dummy_Handler      ;20:(reserved)
            DCD    Dummy_Handler      ;21:command complete; read collision
            DCD    Dummy_Handler      ;22:low-voltage detect;
                                      ;   low-voltage warning
            DCD    Dummy_Handler      ;23:low leakage wakeup
            DCD    Dummy_Handler      ;24:I2C0
            DCD    Dummy_Handler      ;25:I2C1
            DCD    Dummy_Handler      ;26:SPI0 (all IRQ sources)
            DCD    Dummy_Handler      ;27:SPI1 (all IRQ sources)
            DCD    Dummy_Handler      ;28:UART0 (status; error)
            DCD    Dummy_Handler      ;29:UART1 (status; error)
            DCD    Dummy_Handler      ;30:UART2 (status; error)
            DCD    Dummy_Handler      ;31:ADC0
            DCD    Dummy_Handler      ;32:CMP0
            DCD    Dummy_Handler      ;33:TPM0
            DCD    Dummy_Handler      ;34:TPM1
            DCD    Dummy_Handler      ;35:TPM2
            DCD    Dummy_Handler      ;36:RTC (alarm)
            DCD    Dummy_Handler      ;37:RTC (seconds)
            DCD    Dummy_Handler      ;38:PIT (all IRQ sources)
            DCD    Dummy_Handler      ;39:I2S0
            DCD    Dummy_Handler      ;40:USB0
            DCD    Dummy_Handler      ;41:DAC0
            DCD    Dummy_Handler      ;42:TSI0
            DCD    Dummy_Handler      ;43:MCG
            DCD    Dummy_Handler      ;44:LPTMR0
            DCD    Dummy_Handler      ;45:Segment LCD
            DCD    Dummy_Handler      ;46:PORTA pin detect
            DCD    Dummy_Handler      ;47:PORTC and PORTD pin detect
__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors
            ALIGN
;****************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<
;Personal program test vars
TestString			DCB "Initial string", 0

;Console I/O Vars
Prompt			DCB "Enter a string command (g,h,m,p,r)>", 0
Invalid			DCB	":Invalid command", 0
EnterPrompt		DCB "Please enter a string: ",0
HelpString		DCB "g (get), h (help), m (modify), p (print), r (reverse)", 0 


;>>>>>   end constants here <<<<<
            ALIGN
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
	
StringReversal		SPACE	2
ResultString		SPACE	MAX_STRING
	
;>>>>>   end variables here <<<<<
            ALIGN
            END
