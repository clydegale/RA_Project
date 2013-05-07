$NOMOD51
#include <Reg517a.inc>

NAME processA

EXTRN DATA (processTable)
PUBLIC processA

; Datensegment für die eigenen Variablen anlegen
processASegment SEGMENT CODE
RSEG		processASegment

;CALL processA
;SJMP EOF

processA:

	MOV A, #processTable
	ADD A, #4D
	MOV SP,A
	
	MOV R5, #0xF6 ; magic loop number

	mainLoop:
		CALL printAToUART
		CALL waitRoutine		
	JMP mainLoop

printAToUART:
	MOV S0BUF, #'a'
	
	waitForSendFinished:
		MOV	A, S0CON
	JNB	ACC.1, waitForSendFinished
	
	ANL A, #11111101b
	MOV S0CON, A
RET

waitRoutine:
	MOV A, TCON
	ORL A, #00010000b
	MOV TCON, A
	
	MOV R1, #0x00	
	timerPollingLoop:
		MOV A, TCON
		
		; loop counter
		INC R1
		
		; check if loop is finished
	JNB ACC.5, timerPollingLoop
	
	CALL resetWD

	; reset TCON
	MOV A, TCON	
	ANL A, #11011111b
	MOV TCON, A
	
	DJNZ R5, timerPollingLoop
	
RET
	
resetWD:
	; reset watchdog timer
	SETB WDT
	SETB SWDT
RET

END