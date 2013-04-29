$NOMOD51
#include <Reg517a.inc>

EXTRN CODE (processA, processB, processC)
PUBLIC Delete, New

;------------------------------------------------------------------------------
; Put the STACK segment in the main module.
;------------------------------------------------------------------------------
?STACK         	SEGMENT IDATA           ; ?STACK goes into IDATA RAM.
						RSEG    ?STACK          ; switch to ?STACK segment.
						DS      5               ; reserve your stack space
                                        ; 5 bytes in this example.




; Input Interrupt
CSEG AT 0x23
JMP		port1Interrupt



;ORG 0
CSEG AT 0
JMP		main

; Datensegment für die eigenen Variablen anlegen
mainSegment SEGMENT CODE
RSEG		mainSegment

port1Interrupt:
	MOV r7, #0xFF
RETI


main:
	
	; Stack Pointer auf reservierten Bereich setzen
	MOV		SP,#?STACK
	
	SETB EAL
	SETB IEN0.4
	
	CALL initUART
	CALL processC

initUART:
	; Serial Mode 1: 8bit-UART bei Baudrate 9600
	CLR		SM0
	SETB	SM1

	; Port1
	SETB	REN0			; Empfang ermöglichen
	SETB	BD				; Baudraten-Generator aktivieren
	MOV		S0RELL,#0xD9	; Baudrate einstellen
	MOV		S0RELH,#0x03	; 9600 = 03D9H
	
RET

Delete:
	
New:


EOF:
	END