$NOMOD51
#include <Reg517a.inc>

NAME processC
PUBLIC processC

; Datensegment für die eigenen Variablen anlegen
processCSegment SEGMENT CODE
RSEG		processCSegment

processC:

	endlessLoop:
		; reset watchdog timer
		SETB WDT
		SETB SWDT
		
		loopRec:
			MOV A,S0CON	
		JNB RI0,loopRec
		
		MOV r7,S0BUF
		
		CLR RI0
		
	
	JMP endlessLoop

END