$NOMOD51
#include <Reg517a.inc>

EXTRN CODE (processA, processB, processC)
PUBLIC Delete, New, processStartAdress, newBit, processTable
PUBLIC isNew, isDel, isNon

;------------------------------------------------------------------------------
; Put the STACK segment in the main module.
;------------------------------------------------------------------------------
?STACK	SEGMENT IDATA ; ?STACK goes into IDATA RAM.
RSEG ?STACK ; switch to ?STACK segment.
DS 25 ; reserve your stack space

; reserve data segments for the scheduler 
mainData SEGMENT DATA
RSEG mainData
	; processTable of the scheduler
	processTable: DS 78
	
	; public data segmet which is used to tell the
	; scheduler which process has to be started or
	; stopped
	processStartAdress: DS 2
	
	; points to the current row of the processTable
	index: DS 1
	
	; public data segment which tells the scheduler
	; if the process stored in processStartAdress
	; has to be started or stopped.
	; Should be set to isNew, isDel or isNon!
	newBit: DS 1

; define constants for semantical usage
isNew EQU 1
isDel EQU 2
isNon EQU 0

; define addresses of processTable rows
isProcessA EQU processTable
isProcessB EQU processTable + 26
isProcessC EQU processTable + 52

; Timer Interrupt
CSEG AT 0x1B
JMP		timer1Interrupt

CSEG AT 0
JMP		bootStrap

; create data segment for the scheduler
mainSegment SEGMENT CODE
RSEG mainSegment	

; interrupt routine that loops through the
; processTable and determines the next process.
; it also creates new processes in the table or
; delete processes
timer1Interrupt:
	CLR TF1
	
	; backup registers of current process
	JMP pushRegisters
	returnPushRegisters:
	
	; save StackPointer in processTable
	; and set SP to stack of scheduler
	MOV R0, index
	INC R0
	MOV @R0, SP
	MOV SP, #?STACK
	
	; iterate through table until an active process
	; is found
	processTableLoop:		
		; reset watchdog timer
		SETB WDT
		SETB SWDT
		
		; Increment Index
		MOV A, index
		CJNE A, #processtable + 52, notOffset52;
			; reset index if it already points 
			; to the last row of the processTable
			MOV A, #processTable
			JMP writeBack
		notOffset52:
			; set pointer to the next row
			ADD A, #26d
		writeBack:
			MOV index, A
		
		; update table if newBit is set to isNew
		MOV R0, newBit
		CJNE R0, #isNew, afterNew
			JMP new
		afterNew:
			; update Table if newBit is set to isDel
			CJNE R0, #isDel, newOrDeleteFinished
				JMP delete
		newOrDeleteFinished:
		
		; reset newBit 
		MOV newBit, #isNon
		
		; check active flag
		MOV R1, index
	CJNE @R1,#0x01, processTableLoop 
	
	; set timer according to priority
	MOV TL1, #0x00
	CJNE R1, #isProcessA, notProcessA
		CLR TR1
		MOV TH1, #0xE0
		SETB TR1
	notProcessA:
	CJNE R1, #isProcessB, notProcessB
		CLR TR1
		MOV TH1, #0xF0
		SETB TR1
	notProcessB:
	CJNE R1, #isProcessC, notProcessC
		CLR TR1
		MOV TH1, #0xF8
		SETB TR1
	notProcessC:
	
	JMP loadStackPointer
	returnLoadStackPointer:	
	
	JMP popRegisters	
	returnPopRegisters:
RETI

bootStrap:
	; set SP to a new stack for the scheduler
	MOV SP,#?STACK
	
	CALL init
	CALL callProcessC

	; endless loop to make sure the scheduler
	; never ends
	endlessSchedLoop:
		NOP
		NOP
		NOP
		NOP
		
		; reset watchdog timer
		SETB WDT
		SETB SWDT
	JMP endlessSchedLoop

; set the flags so that console process
; is started by the schedulers interrupt routine
callProcessC:
	MOV DPTR, #processC
	MOV processStartAdress + 1, DPL
	MOV processStartAdress + 0, DPH
	MOV newBit, #isNew
RET

; enables interrupts and UARTs, sets timermodes and
; initializes the processTable
init:	
	; enable all interrupts and the specific 
	; serial0-interrupt
	SETB EAL
	SETB IEN0.3
	
	; set UART mode to 8-bit
	CLR	SM0
	SETB SM1

	; enable receive bit
	SETB REN0
	
	; enable baud rate generator
	SETB BD
	
	; set baud rate to 9600
	MOV	S0RELL,#0xD9
	MOV	S0RELH,#0x03
	
	; set mode of timer1 to 16-bit
	MOV A, TMOD
	ANL A, #11001111b
	ORL A, #00010000b
	MOV TMOD, A
	
	; start timer1
	SETB TR1
	
	; initialize newBit to 0
	MOV newBit, #isNon
	
	; initialize processTable "processStartAdress" columns and 
	; reset "Active" columns
	
	; Process A
	MOV DPTR, #processA
	MOV processTable + 3, DPL ; ff 09
	MOV processTable + 2, DPH
	MOV processTable, #0x00

	; Process B
	MOV DPTR, #processB
	MOV processTable + 29, DPL
	MOV processTable + 28, DPH
	MOV processTable + 26, #0x00
	
	; Process C
	MOV DPTR, #processC
	MOV processTable + 55, DPL
	MOV processTable + 54, DPH
	MOV processTable + 52, #0x00
	
	; init index with correct offset of the processtable
	MOV index, #processTable
RET

; called from the interrupt routine if isDel flag was set.
; sets the according process to inactive in the processTable.
delete:
	; set DPTR to the Lable Adress given by the console process
	MOV DPH, processStartAdress + 0
	MOV DPL, processStartAdress + 1
	MOV R1, DPL
	MOV R2, DPH
	
	; determine the process to delete in the processTable 
	; and set its active flag to 0
	MOV A, processTable + 2
	checkProcessA:
		CJNE A, 2, checkProcessB
			MOV A, processTable + 3
			CJNE A, 1, checkProcessB
				MOV R0, #processTable + 0
				MOV @R0, #0x00
				JMP endDelete
				
	checkProcessB:
		MOV A, processTable + 28
		CJNE A, 2, checkProcessC
			MOV A, processTable + 29
			CJNE A, 1, checkProcessC
				MOV R0, #processTable + 26
				MOV @R0, #0x00
				JMP endDelete
				
	checkProcessC:
		MOV A, processTable + 54
		CJNE A, 2, endDelete
			MOV A, processTable + 55
			CJNE A, 1, endDelete
				MOV R0, #processTable + 52
				MOV @R0, #0x00
				JMP endDelete
	
	endDelete:
	NOP
JMP newOrDeleteFinished

new:
	; set DPTR to the Lable Adress given by the console process
	MOV DPH, processStartAdress + 0
	MOV DPL, processStartAdress + 1
	MOV R1, DPL
	MOV R2, DPH
	
	MOV R3, #0x00
	
	; determine the according row for the process to create in the
	; processTable and store its startadress and some empty registers
	; on the stack within the processTable.
	MOV A, processTable + 2
	newCheckProcessA:
		CJNE A, 2, newCheckProcessB
			MOV A, processTable + 3
			CJNE A, 1, newCheckProcessB			
				
				; move stack pointer to the begin of the stack within
				; the processTable
				MOV SP, #processTable + 4
				
				; push startadress of the process on the stack
				PUSH 1
				PUSH 2
				
				; push empty registers on the stack
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				
				; store the changed stackpointer in the processTable
				; and set the active flag of the process to 1
				MOV processTable + 1, SP
				MOV processTable + 0, #0x01
				
				JMP endNew
				
	newCheckProcessB:
		MOV A, processTable + 28
		CJNE A, 2, newCheckProcessC
			MOV A, processTable + 29
			CJNE A, 1, newCheckProcessC
			
				; move stack pointer to the begin of the stack within
				; the processTable
				MOV SP, #processTable + 30
				
				; push startadress of the process on the stack
				PUSH 1
				PUSH 2
				
				; push empty registers on the stack
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				
				; store the changed stackpointer in the processTable
				; and set the active flag of the process to 1				
				MOV processTable + 27, SP
				MOV processTable + 26, #0x01
				
				JMP endNew
	newCheckProcessC:
		MOV A, processTable + 54
		CJNE A, 2, endNew
			MOV A, processTable + 55
			CJNE A, 1, endNew
			
				; move stack pointer to the begin of the stack within
				; the processTable			
				MOV SP, #processTable + 56
				
				; push startadress of the process on the stack				
				PUSH 1
				PUSH 2

				; push empty registers on the stack
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				PUSH 3
				
				; store the changed stackpointer in the processTable
				; and set the active flag of the process to 1				
				MOV processTable + 53, SP
				MOV processTable + 52, #0x01
				
				JMP endNew
	endNew:

JMP newOrDeleteFinished

; pushes all needed registers on the stack
pushRegisters:
	PUSH PSW
	PUSH 0
	PUSH 1
	PUSH 2
	PUSH 3
	PUSH 4
	PUSH 5
	PUSH 6
	PUSH 7
	PUSH ACC
	PUSH B
	PUSH DPH
	PUSH DPL
JMP returnPushRegisters

; pops all needed registers from the stack
popRegisters:
	POP DPL
	POP DPH
	POP B
	POP ACC
	POP 7
	POP 6
	POP 5
	POP 4
	POP 3
	POP 2
	POP 1
	POP 0
	POP PSW
JMP returnPopRegisters

; restores the SP of the next process to run
; from the processTable
loadStackPointer:
	MOV R0, index
	INC R0
	MOV SP, @R0
JMP returnLoadStackPointer

END