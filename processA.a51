$NOMOD51
#include <Reg517a.inc>

; Datensegment für die eigenen Variablen anlegen
dataSegment	SEGMENT DATA
RSEG		dataSegment

; Speicherplatz für den Stack Pointer reservieren (wird bei CALL-Aufrufen hochgezählt)
; Ansonsten startet er bei 0 und kann eigene Variablen überschreiben!
STACK:	DS	4


; Ins Code-Segment wechseln
CSEG
ORG 0

; Stack Pointer auf reservierten Bereich setzen
MOV		SP,#STACK


; Serial Mode 1: 8bit-UART bei Baudrate 9600
CLR		SM0
SETB	SM1

; Port1
SETB	REN0			; Empfang ermöglichen
SETB	BD				; Baudraten-Generator aktivieren
MOV		S0RELL,#0xD9	; Baudrate einstellen
MOV		S0RELH,#0x03	; 9600 = 03D9H

MOV R5, #0x09

;CALL processA
;SJMP EOF



processA:
	

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
		
	
	; reset TCON
	MOV A, TCON	
	ANL A, #11011111b
	MOV TCON, A
	
	DJNZ R5, timerPollingLoop
	;RET

;EOF:
	END