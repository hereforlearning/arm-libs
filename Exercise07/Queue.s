		TTL Exercise 07 Circular FIFO Queue Operations
		
;****************************************************************
;Date:  10/01/2015
;Class:  CMPE-250
;Section:  03 TR 2-4PM
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

;Max length of queue
Q_BUF_SZ				EQU 80
Q_REC_SZ                EQU 18

;Max length of prompt string
MAX_STRING 				EQU 79
	
IN_PTR					EQU 0
OUT_PTR					EQU 4
BUF_START				EQU 8
BUF_PAST				EQU 12
BUF_SIZE				EQU 16
NUM_ENQD				EQU 17

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
			
            ;Load input params to initalize queue structure
			LDR R1, =QueueRecord
			LDR R0, =Queue
			MOVS R2, #Q_BUF_SZ
			
			;Initalize Queue structure once variables are loaded
			BL		InitQueue
			
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
			;Check if the sanitized character is one of the four inputs
			CMP R0, #'d'
			BEQ PRINT_DEQUEUE
			CMP R0, #'e'
			BEQ PRINT_ENQUEUE
			CMP R0, #'h'
			BEQ PRINT_HELP
			CMP R0, #'p'
			BEQ PRINT_ACTIVE_QUEUE
			CMP R0, #'s'
			BEQ PRINT_STATUS
			B PROMPT
			
PRINT_DEQUEUE

			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			;Load input params to initalize queue structure
			LDR R1, =QueueRecord
			LDR R0, =Queue
			MOVS R2, #Q_BUF_SZ
			
			BL DeQueue
			
			;ASPR C flag set to 1, print that the queue is empty
			BCS QUEUE_PRINT_ERROR
			
			;Print value retrieved from the queue
			BL PutChar
			MOVS R0, #':'
			BL PutChar
			
			LDR R0, =QueueRecord
			BL PrintQueueStatus
			
			B	CMD_END
			
QUEUE_PRINT_ERROR
			
			;Print that dequeue opeation failed and restart prompt
			LDR R0, =Failure
			BL	PutStringSB
			
			LDR R0, =QueueRecord
			BL PrintQueueStatus
			
			B	CMD_END

PRINT_ENQUEUE

			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			;Prompt user to enter a char to enqueue
			LDR R0, =EnqueuePrompt
			BL 	PutStringSB
			
			;Load input params to initalize queue structure
			LDR R1, =QueueRecord
			LDR R0, =Queue
			MOVS R2, #Q_BUF_SZ
			
			;Grab a charater from the terminal and insert it into the queue
			BL GetChar
			
			;Convert charater to ASCII value
			MOVS R0, R3
			BL	PutChar
			
			BL EnQueue
			
			;If the queue is full, print failure message
			BCS ENQUEUE_FAILURE
			
			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			LDR R0, =Success
			BL PutStringSB
			
			LDR R0, =QueueRecord
			BL PrintQueueStatus
			
			B	CMD_END
			
ENQUEUE_FAILURE
			
			;Load failure string and print to the console
			LDR R0, =Failure
			BL	PutStringSB
			
			LDR R0, =QueueRecord
			BL PrintQueueStatus
			
			B	CMD_END

PRINT_HELP

			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar

			;Load help string address
			LDR R0, =HelpString
			
			;Print help string
			BL PutStringSB
			
			B CMD_END

PRINT_STATUS

			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			;Print the initial 'Status: ' String
			LDR R0, =Status
			BL PutStringSB
			
			;Print entire status string of the queue
			LDR R0, =QueueRecord
			BL PrintQueueStatus
			
			
			B CMD_END

PRINT_ACTIVE_QUEUE
		
			;Print CR and LF to the screen
			MOVS R0, #0x0D
			BL PutChar
			
			MOVS R0, #0x0A
			BL PutChar
			
			PUSH {R0-R4}
			
			;Print first delimeter to print queue contents
			MOVS R0, #'>'
			BL	PutChar
			
			;Load input params to initalize queue structure
			LDR R1, =QueueRecord
			LDR R0, =Queue
			
			LDR R2, [R1, #IN_PTR]
			LDR R3, [R1, #OUT_PTR]
			
PRINT_NEXT
			;if we've reached buf_past, we've hit the end of the queue
			CMP R3, R2
			BGE QUEUE_END_REACHED
			
			;Print queue character 
			LDRB R4, [R3, #0]
			
			;Move char to R0 to print
			PUSH {R0}
			MOVS R0, R4
			BL PutChar
			POP {R0}
			
			;Increment memory address to look for next queue char
			ADDS R3, #4
			B PRINT_NEXT
			
QUEUE_END_REACHED
			
			;Print ending delimeters, carrige return and line feed
			MOVS R0, #'<'
			BL PutChar
			MOVS R0, #0x0D
			BL PutChar
			MOVS R0, #0x0A
			BL PutChar
			
			POP {R0-R4}	
			B CMD_END
			
CMD_END
			;Return to initial prompt
			B PRINT_PROMPT
			
;>>>>>   end main program code <<<<<
;Stay here
            B       .
;>>>>> begin subroutine code <<<<<

PrintQueueStatus
;PrintQueueStatus: Print the inpointer, outpointer, and
;number of elements that are enqueued in the current queue.

;Inputs:
	;R0 = address of queue record structure
;Outputs
	;N/A
;-------------------------------------------
	PUSH {R0, R1, R2, R3, LR}
	
	LDR R1, [R0, #IN_PTR]
	LDR R2, [R0, #OUT_PTR]
	LDRB R3, [R0, #NUM_ENQD]
	
	;Print chars '   In='
	LDR R0, =Spaces
	BL PutStringSB
	LDR R0, =In
	BL PutStringSB
	
	;Print in_ptr address of queue
	MOVS R0, R1
	BL PutNumHex
	
	;Print chars '   Out='
	LDR R0, =Spaces
	BL PutStringSB
	LDR R0, =Out
	BL PutStringSB
	
	;Print out+ptr address of queue
	MOVS R0, R2
	BL PutNumHex
	
	;Print chars '   Num='
	LDR R0, =Spaces
	BL PutStringSB
	LDR R0, =Num
	BL PutStringSB
	
	;Print number of elements currently enqueued
	MOVS R0, R3
	BL PutNumU
	
	;Call it a day
	POP {R0, R1, R2, R3, PC}	
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

InitQueue
;InitQueue: Initalize Circular FIFO Queue Structure
;Inputs:
    ;R0 - Memory location of queue buffer
    ;R1 - Address to place Queue record structure
    ;R2 - Size of queue structure (character capacity)
;Outputs: N/A
;--------------------------------------------

		;Store memory address of front of queue
		;Into IN_PTR position of the buffer
		STR R0, [R1, #IN_PTR]

		;Store same memory address for OUT_PTR
		;position in the buffer since queue is empty
		STR R0, [R1, #OUT_PTR]

		;Store same memory address in BUF_START for initalization
		STR R0, [R1, #BUF_START]

		;Store BUF_PAST in last slot of buffer
        ADDS R0, R0, R2
		STR R0, [R1, #BUF_PAST]

		;Store BUF_SIZE with size in R2
		STR R2, [R1, #BUF_SIZE]
		
		;Initalize NUM_ENQD to zero and 
		;store in 6th slot of buffer
		MOVS R0, #0
		STRB R0, [R1, #NUM_ENQD]
		
		BX	LR

;--------------------------------------------

DeQueue
;DeQueue: Remove an element from the circular FIFO Queue
;Inputs:
	;R1 - Address of Queue record structure
;Outputs:
	;R0 - Character that has been dequeued
	;PSR C flag (failure if C = 1, C = 0 otherwise.)
;--------------------------------------------
			PUSH {R1, R2, R3, R4}
			
			;If the number enqueued is 0, 
			;Set failure PSR flag
			LDRB R3, [R1, #NUM_ENQD]
			CMP R3, #0
			BLE DEQUEUE_FAILURE
			
			;Remove the item from the queue
			;And place in R0
			LDR R0, [R1, #OUT_PTR]
			;Load actual queue value into R0
			LDR R0, [R0, #0]
			
			;Decrement number of enqueued elements
			;And store info back in buffer
			LDRB R3, [R1, #NUM_ENQD]
			SUBS R3, R3, #1
			STRB R3, [R1, #NUM_ENQD] 
			
			;Increment location of out_pointer
			LDR R3, [R1, #OUT_PTR]
			ADDS R3, R3, #4
			STR R3, [R1, #OUT_PTR] 
			
			;Compare OUT_PTR to BUF_PAST
			;If out_ptr >= BUF_PAST, wrap the queue around
			LDR R4, [R1, #BUF_PAST]
			CMP R3, R4
			BGE WRAP_BUFFER
			B DEQUEUE_CLEAR_PSR
			
WRAP_BUFFER
			;Adjust out_ptr to equal buf_start
			;Thus wrapping around the circular queue
			LDR R3, [R1, #BUF_START]
			STR R2, [R1, #OUT_PTR]

DEQUEUE_CLEAR_PSR
			;Clear the PSR C flag
			MRS R1, APSR
			MOVS R3, #0x20
			LSLS R1, R1, #24
			BICS R1, R1, R3
			MSR	APSR, R1
			
			;Successfully end the operation
			B END_DEQUEUE
			
DEQUEUE_FAILURE
			;Set PSR C flag to 1
			MRS R1, APSR
			MOVS R3, #0x20
			LSLS R3, R3, #24
			ORRS R1, R1, R3
			MSR APSR, R1
			
END_DEQUEUE
			POP {R1, R2, R3, R4}
			BX	LR
			
;--------------------------------------------
EnQueue
;EnQueue: Add an element to the circular FIFO Queue
;Inputs:
	;R0 - Character to enqueue
	;R1 - Address of the Queue record
;Outputs:
	;PSR C flag (failure if C = 1, C = 0 otherwise.)
;--------------------------------------------'

			PUSH {R2, R3, R4}
			
			;If num_enqd >= size of the queue
			;Then set PSR C flag to 1 indicating
			;the error that an element was not inserted
			;into a full queue
			
			LDRB R3, [R1, #NUM_ENQD]
			LDR R4, [R1, #BUF_SIZE]
			CMP R3, R4
			BGE QUEUE_FULL
			B BEGIN_ENQUEUE
			
QUEUE_FULL
			;Set PSR C flag to 1
			MRS R1, APSR
			MOVS R3, #0x20
			LSLS R3, R3, #24
			ORRS R1, R1, R3
			MSR APSR, R1
			B END_ENQUEUE
			
BEGIN_ENQUEUE
			
			;Load mem address of in_ptr
			;and then store the value to be enqueued
			;intot he value at that memory address
			LDR R3, [R1, #IN_PTR]
			STR R0, [R3, #0]
			
			;Increment value of in_ptr by 4, 1 value past
			;The queue item. Then store back in IN_PTR
			ADDS R3, R3, #4
			STR R3, [R1, #IN_PTR]
			
			;Increment number of enqueued elements
			LDRB R3, [R1, #NUM_ENQD]
			ADDS R3, R3, #1
			STRB R3, [R1, #NUM_ENQD]
			
			;If IN_PTR is >= BUF_PAST
			;Loop around and adjust inPtr to beginning of
			;the queue buffer
			LDR R3, [R1, #IN_PTR]
			LDR R4, [R1, #BUF_PAST]
			
			CMP R3, R4
			BGE WRAP_ENQUEUE
			B END_ENQUEUE
			
WRAP_ENQUEUE
			;Adjust in_ptr to beginning of queue buffer
			STR R1, [R2, #IN_PTR]
			
			;Clear the PSR C flag confirming successful result
			MRS R2, APSR
			MOVS R3, #0x20
			LSLS R2, R2, #24
			BICS R2, R2, R3
			MSR	APSR, R2
			
END_ENQUEUE
			
			POP {R2, R3, R4}
			BX LR

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
Prompt				DCB "Type a queue command (d, e, h, p, s):", 0
EnqueuePrompt 		DCB	"Character to enqueue: ", 0
HelpString			DCB	"d (dequeue), e (enqueue), h (help}, p (print), s (status)", 0
Success				DCB "Success: ", 0
Failure				DCB "Failure: ", 0
Status				DCB "Status: ", 0
In					DCB "In= ", 0
Out					DCB "Out= ", 0
Num					DCB "Num= ", 0
Spaces				DCB "   ", 0
;>>>>>   end constants here <<<<<
            ALIGN
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<

;Memory allocated to store String input from user
Queue 		SPACE Q_BUF_SZ	
;6 Byte buffer to store queue information 
QueueRecord SPACE Q_REC_SZ
	
StringReversal		SPACE 2
	
;>>>>>   end variables here <<<<<
            ALIGN
            END
