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

; Datensegment zum speichern der Prozess Tabelle 
mainData SEGMENT DATA
RSEG mainData
	processTable: DS 78
	processStartAdress: DS 2
	index: DS 1
	newBit: DS 1
	
isNew EQU 1
isDel EQU 2
isNon EQU 0

; define addresses of processTable rows
isProcessA EQU processTable
isProcessB EQU processTable + 26
isProcessC EQU processTable + 52

;Timer Interrupt
CSEG AT 0x1B
JMP		timer1Interrupt

CSEG AT 0
JMP		main

; Datensegment für die eigenen Variablen anlegen
mainSegment SEGMENT CODE
RSEG mainSegment	

timer1Interrupt:
	CLR TF1
	
	; TODO: No Calls in Interrup Routine.
	; Copy all external code directly into this routine
	JMP pushRegisters
	returnPushRegisters:
	
	; saveStackPointer
	MOV R0, index
	INC R0
	MOV @R0, SP
	MOV SP, #?STACK
	
	; Iterate through table
	processTableLoop:		
		; reset watchdog timer
		SETB WDT
		SETB SWDT
		
		; Increment Index
		MOV A, index
		CJNE A, #processtable + 52, notOffset52;
			MOV A, #processTable
			JMP writeBack
		notOffset52:
			ADD A, #26d
		writeBack:
			MOV index, A
		
		; update Table if newBit is Set to isNew
		MOV R0, newBit
		CJNE R0, #isNew, afterNew
			JMP new
		afterNew:
			; update Table if newBit is Set to isDel
			CJNE R0, #isDel, newOrDeleteFinished
				CALL delete
		
		newOrDeleteFinished:
		
		;Reset newBit 
		MOV newBit, #isNon
		
		; check active flag
		MOV R1, index
	CJNE @R1,#0x01, processTableLoop 
	
	MOV TL1, #0x00
	CJNE R1, #isProcessA, notProcessA
		CLR TR1
		MOV TH1, #0x20
		SETB TR1
	notProcessA:
	CJNE R1, #isProcessB, notProcessB
		CLR TR1
		MOV TH1, #0x40
		SETB TR1
	notProcessB:
	CJNE R1, #isProcessC, notProcessC
		CLR TR1
		MOV TH1, #0x80
		SETB TR1
	notProcessC:
	
	JMP loadStackPointer
	returnLoadStackPointer:	
	
	JMP popRegisters	
	returnPopRegisters:
RETI

main:
	; Stack Pointer auf reservierten Bereich setzen
	MOV		SP,#?STACK
	
	CALL init
	CALL callProcessC
	
	MOV R7, TL1

	endlessSchedLoop:
		NOP
		NOP
		NOP
		NOP	
		; reset watchdog timer
		SETB WDT
		SETB SWDT
	JMP endlessSchedLoop

callProcessC:
	MOV DPTR, #processC
	MOV processStartAdress + 1, DPL
	MOV processStartAdress + 0, DPH
	MOV newBit, #isNew
RET

init:
	
	; Enable All Interrupts and the specific Serial0
	SETB EAL
	SETB IEN0.3
	
	; Serial Mode 1: 8bit-UART bei Baudrate 9600
	CLR		SM0
	SETB	SM1

	; Port1
	SETB	REN0			; Empfang ermöglichen
	SETB	BD				; Baudraten-Generator aktivieren
	MOV	S0RELL,#0xD9	; Baudrate einstellen
	MOV	S0RELH,#0x03	; 9600 = 03D9H
	
	; Set TimerMode
	MOV A, TMOD
	ANL A, #11001111b
	ORL A, #00010000b
	MOV TMOD, A
	
	; Setting Prescaler (currently not working)	
	;MOV TL1, #0xFF
	;MOV TH1, #0xFF
	
	; Start Timer 1
	SETB TR1
	
	; Initialize newBit to 0
	MOV newBit, #isNon
	
	;Initialize processTable "processStartAdress" columns and reset "Active" coulmn
	;Process A
	MOV DPTR, #processA
	MOV processTable + 3, DPL ; ff 09
	MOV processTable + 2, DPH
	MOV processTable, #0x00

	;Process B
	MOV DPTR, #processB
	MOV processTable + 29, DPL
	MOV processTable + 28, DPH
	MOV processTable + 26, #0x00
	
	;Process C
	MOV DPTR, #processC
	MOV processTable + 55, DPL
	MOV processTable + 54, DPH
	MOV processTable + 52, #0x00
	
	; init index with correct offset of the processtable
	MOV index, #processTable
RET

delete:
	; Set DPTR to the Lable Adress given by the console process
	MOV DPH, processStartAdress + 0
	MOV DPL, processStartAdress + 1
	MOV R1, DPL
	MOV R2, DPH
	
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
RET

new:
	; Set DPTR to the Lable Adress given by the console process
	MOV DPH, processStartAdress + 0
	MOV DPL, processStartAdress + 1
	MOV R1, DPL
	MOV R2, DPH
	
	MOV R3, #0x00
	
	MOV A, processTable + 2
	
	newCheckProcessA:
		CJNE A, 2, newCheckProcessB
			MOV A, processTable + 3
			CJNE A, 1, newCheckProcessB			
				
				MOV SP, #processTable + 4
				PUSH 1
				PUSH 2
				;Push Zero Registers to Stack
				MOV R3,#0x00 ;TODO: deleteLN
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
				MOV processTable + 1, SP
				MOV processTable + 0, #0x01
				
				JMP endNew
				
	newCheckProcessB:
		MOV A, processTable + 28
		CJNE A, 2, newCheckProcessC
			MOV A, processTable + 29
			CJNE A, 1, newCheckProcessC
				MOV SP, #processTable + 30
				PUSH 1
				PUSH 2
				;Push Zero Registers to Stack
				MOV R3,#0x00
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
				MOV processTable + 27, SP
				MOV processTable + 26, #0x01
				
				JMP endNew
	newCheckProcessC:
		MOV A, processTable + 54
		CJNE A, 2, endNew
			MOV A, processTable + 55
			CJNE A, 1, endNew
				MOV SP, #processTable + 56
				PUSH 1
				PUSH 2
				;Push Zero Registers to Stack
				MOV R3,#0x00
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
				MOV processTable + 53, SP
				MOV processTable + 52, #0x01
				
				JMP endNew
	endNew:

;RET to interrupt routine
JMP newOrDeleteFinished

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

loadStackPointer:
	MOV R0, index
	INC R0
	MOV SP, @R0
JMP returnLoadStackPointer

END