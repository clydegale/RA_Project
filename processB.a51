$NOMOD51
#include <Reg517a.inc>

NAME processB

EXTRN DATA (processTable, processStartAdress, newBit, isDel)
PUBLIC processB

; define local code segment
processBSegment SEGMENT CODE
RSEG processBSegment

processB:

	; set stack pointer relative to processTable
	MOV A, #processTable
	ADD A, #30D
	MOV SP,A

	CALL printToUART
	CALL cleanUp

; prints the characters '54321' to UART0
printToUART:
	; initialize counter with ascii value
	; of the character '5'
	MOV R1, #53d
	
	; loop while counter > '1'
	countDownLoop:
		MOV S0BUF, R1
		
		; loop until output of single character is finished
		waitForSendFinished:
			MOV	A, S0CON
		JNB	ACC.1, waitForSendFinished
		
		DEC R1
		
		; reset TI0 flag for further output
		ANL A, #11111101b
		MOV S0CON, A
		
	CJNE R1, #48d, countDownLoop
RET

cleanUp:
	; tell the scheduler to delete processB
	; from the processTable
	MOV DPTR, #processB
	MOV processStartAdress + 1, DPL
	MOV processStartAdress + 0, DPH
	MOV newBit, #isDel
	
	; loop until processor time of processB is over
	doNothingLoop:
		NOP
		NOP
	JMP doNothingLoop
END