$NOMOD51
#include <Reg517a.inc>

NAME processA

EXTRN DATA (processTable)
PUBLIC processA

; create code segment for this process
processASegment SEGMENT CODE
RSEG processASegment

processA:
	; set stackpointer relative to the
	; processTable
	MOV A, #processTable
	ADD A, #4D
	MOV SP, A
	
	; magic loop number
	MOV R5, #0xF6

	mainLoop:
		CALL printAToUART
		CALL waitRoutine		
	JMP mainLoop

; write the character 'a' to UART0
printAToUART:
	MOV S0BUF, #'a'
	
	waitForSendFinished:
		MOV	A, S0CON
	JNB	ACC.1, waitForSendFinished
	
	; reset TI0
	ANL A, #11111101b
	MOV S0CON, A
RET

; loops for about 1 second
waitRoutine:
	; enable timer0
	MOV A, TCON
	ORL A, #00010000b
	MOV TCON, A
	
	; wait for timer0 overflow
	timerPollingLoop:
		MOV A, TCON
	JNB ACC.5, timerPollingLoop
	
	CALL resetWD

	; reset TCON
	MOV A, TCON	
	ANL A, #11011111b
	MOV TCON, A
	
	; return to timerPollingLoop if
	; routine did not wait 1s
	DJNZ R5, timerPollingLoop
	
RET
	
resetWD:
	; reset watchdog timer
	SETB WDT
	SETB SWDT
RET

END