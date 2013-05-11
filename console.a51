$NOMOD51
#include <Reg517a.inc>

NAME processC

EXTRN CODE (processA, processB)
EXTRN DATA (processStartAdress, newBit, processTable)
EXTRN NUMBER (isNew, isDel, isNon)
PUBLIC processC

; create code segment for this process
processCSegment SEGMENT CODE
RSEG processCSegment

processC:
	; set stackpointer relative to 
	; processTable
	MOV A, #processTable
	ADD A, #56D
	MOV SP, A

	endlessLoop:
		; reset watchdog timer
		SETB WDT
		SETB SWDT
		
		; wait for input on UART0
		loopRec:
			MOV A, S0CON
		JNB RI0, loopRec
		
		; save received input in R7
		; and call the input handler
		MOV R7, S0BUF
		CALL handleSerial0Input
		
		CLR RI0
	JMP endlessLoop
RET	

; triggers creation or deletion of a process
; according to the received input
handleSerial0Input:

	; check input on R7 and set parameters accordingly
	CJNE R7,#'a', afterA
		; trigger creation of processA
		inputA:
			MOV DPTR, #processA
			MOV processStartAdress + 1, DPL
			MOV processStartAdress + 0, DPH
			MOV newBit, #isNew
	afterA:
	CJNE R7,#'b', afterB
		; trigger deletion of processA
		inputB:
			MOV DPTR, #processA
			MOV processStartAdress + 1, DPL
			MOV processStartAdress + 0, DPH
			MOV newBit, #isDel
	afterB:
	CJNE R7,#'c', afterC
		; trigger creation of processB
		inputC:
			MOV DPTR, #processB
			MOV processStartAdress + 1, DPL
			MOV processStartAdress + 0, DPH
			MOV newBit, #isNew			
	afterC:
	
	; reset R7
	MOV R7, #0x00
RET

END