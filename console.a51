$NOMOD51
#include <Reg517a.inc>

NAME processC

EXTRN CODE (processA, processB)
EXTRN DATA (processStartAdress, newBit, processTable)
EXTRN NUMBER (isNew, isDel, isNon)
PUBLIC processC

; Datensegment für die eigenen Variablen anlegen
processCSegment SEGMENT CODE
RSEG		processCSegment



processC:
	
		MOV A, #processTable
		ADD A, 56
		MOV SP,A
	; TODO add processes to table of scheduler

	endlessLoop:
		; reset watchdog timer
		SETB WDT
		SETB SWDT
		
		loopRec:
			MOV A,S0CON	
		JNB RI0,loopRec
		
		MOV r7,S0BUF
		CALL handleSerial0Input
		
		CLR RI0
		
	
	JMP endlessLoop
RET	
	
handleSerial0Input:
; check input on r7 and call specific routine
	
	CJNE R7,#'a', afterA 
	
	inputA:
		MOV DPTR, #processA
		MOV processStartAdress + 1, DPL
		MOV processStartAdress + 0, DPH
		MOV newBit, #isNew
	
	afterA:
		CJNE R7,#'b', afterB
	
		inputB:
			MOV DPTR, #processA
			MOV processStartAdress + 1, DPL
			MOV processStartAdress + 0, DPH
			MOV newBit, #isDel
	afterB:
		CJNE R7,#'c', afterC
	
		inputC:
			MOV DPTR, #processB
			MOV processStartAdress + 1, DPL
			MOV processStartAdress + 0, DPH
			MOV newBit, #isNew
			
	afterC:
	
	MOV R7, #0x00

RET

END