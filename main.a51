$NOMOD51
#include <Reg517a.inc>

EXTRN CODE (processA, processB, processC)
PUBLIC Delete, New, processStartAdress, newBit, processTable
PUBLIC isNew, isDel, isNon

;------------------------------------------------------------------------------
; Put the STACK segment in the main module.
;------------------------------------------------------------------------------
?STACK	SEGMENT IDATA           ; ?STACK goes into IDATA RAM.
				RSEG    ?STACK          ; switch to ?STACK segment.
				DS 5 ; reserve your stack space

 ;Datensegment zum speichern der Prozess Tabelle 
mainData SEGMENT DATA
RSEG mainData
	processTable: DS 78
	processStartAdress: DS 2
	index: DS 1
	newBit: DS 1
	
	
isNew EQU 1
isDel EQU 2
isNon EQU 0

;Timer Interrupt
CSEG AT 0x1B
JMP		timer1Interrupt



;ORG 0
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
	
	CALL saveStackPointer
	
	processTableLoop:
		CALL resetWD
		CALL incrementIndex
		
		MOV R0, newBit
		CJNE R0, #isNew, afterNew
			JMP new
		afterNew:
			CJNE R0, #isDel, newOrDeleteFinished
				CALL delete
		
		newOrDeleteFinished:
		
		; check active flag
		MOV R1, index
	CJNE R1,#0x01, processTableLoop 
	
	CALL loadStackPointer	
	JMP popRegisters
	returnPopRegisters:
	
	;Reset newBit
	MOV newBit, #isNon
	
RETI


main:
	; Stack Pointer auf reservierten Bereich setzen
	MOV		SP,#?STACK
	
	CALL init
	CALL callProcessC
	
	; Setting Prescaler (currently not working)
	;MOV TL1, #10000000b
	

	endlessSchedLoop:
		NOP
		NOP
		NOP
		NOP	
		CALL resetWD
	JMP endlessSchedLoop

callProcessC:
	MOV DPTR, #processA
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
	MOV TMOD,A
	; Start Timer 1
	SETB TR1
	
	; Initialize newBit to 0
	MOV newBit, #isNon
	
	;Initialize Index to 0
	MOV index, #0x00
	
	;Initialize processTable "processStartAdress" columns and reset "Active" coulmn
	;Process A
	MOV DPTR, #processA
	MOV processTable + 3, DPL
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
	MOV DPTR, #processStartAdress
	MOV R1, DPL
	MOV R2, DPH
	
	checkProcessA:
		CJNE R2, #processTable + 2, checkProcessB
			CJNE R1, #processTable + 3, checkProcessB
				MOV R0, #processTable + 0
				MOV @R0, #0x00
				JMP endDelete
	checkProcessB:
		CJNE R2, #processTable + 28, checkProcessC
			CJNE R1, #processTable + 29, checkProcessC
				MOV R0, #processTable + 26
				MOV @R0, #0x00
				JMP endDelete
	checkProcessC:
		CJNE R2, #processTable + 54, endDelete
			CJNE R1, #processTable + 55, endDelete
				MOV R0, #processTable + 52
				MOV @R0, #0x00
				JMP endDelete
	
	endDelete:
	NOP
RET

new:
	;MOV DPTR, {processStartAdress}
	MOV DPL, processStartAdress + 0
	MOV DPH, processStartAdress + 1
	MOV R1, DPL
	MOV R2, DPH
	
	MOV R3, #0x00
	
	newCheckProcessA:
		CJNE R2,#processTable + 2, newCheckProcessB
			CJNE R1,#processTable + 3, newCheckProcessB
				
				MOV SP, processTable + 4
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
				MOV processTable + 0, #0x01
				JMP endNew
	newCheckProcessB:
		CJNE R2,#processTable + 28, newCheckProcessC
			CJNE R1,#processTable + 29, newCheckProcessC
				MOV SP, processTable + 30
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
				MOV processTable + 26, #0x01
				
				JMP endNew
	newCheckProcessC:
		CJNE R2,#processTable + 54, endNew
			CJNE R1,#processTable + 55, endNew
				MOV SP, processTable + 56
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
				MOV processTable + 52, #0x01
				
				JMP endNew
	
	endNew:

;RET to interrupt routine
JMP newOrDeleteFinished

resetWD:
	; reset watchdog timer
	SETB WDT
	SETB SWDT
RET

pushRegisters:
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

	PUSH PSW
	
	JMP returnPushRegisters
;RET
			
popRegisters:
	POP PSW
	
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
	
	JMP returnPopRegisters
;RET

saveStackPointer:
	MOV R0, index
	INC R0
	MOV @R0, SP
RET

loadStackPointer:
	MOV R0, index
	INC R0
	MOV SP, R0
RET

incrementIndex:
	; MOV R7, processTable
	MOV A, index
	CJNE A, #processtable + 72, notOffset72
		MOV A, #processTable
		JMP writeBack
	notOffset72:
		ADD A, #26d
	writeBack:
		MOV index, A
RET
END