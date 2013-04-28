$NOMOD51
#include <Reg517a.inc>

; Variablen anlegen
dataSegment	SEGMENT DATA
RSEG		dataSegment

STACK:	DS	4

; Haupt-Code
CSEG
ORG 0

processB:
	CALL initUARTForOutput
	CALL printToUART
	CALL resetUART
	CALL EOF

initUARTForOutput:
	; Serial Mode 1: 8bit-UART bei Baudrate 9600
	CLR		SM0
	SETB	SM1

	; Port1
	SETB	REN0			; Empfang ermöglichen
	SETB	BD				; Baudraten-Generator aktivieren
	MOV		S0RELL,#0xD9	; Baudrate einstellen
	MOV		S0RELH,#0x03	; 9600 = 03D9H
	
RET

; for later use
resetUART:
	MOV S0CON, #0x00
	CLR REN0
	CLR BD
	
RET

printToUART:
	; 0 = 48
	; 1 = 49
	
	MOV R1, #53d
	
	countDownLoop:
		MOV S0BUF, R1
		
		waitForSendFinished:
			MOV	A, S0CON
		JNB	ACC.1, waitForSendFinished
		
		DEC R1
		
		ANL A, #11111101b
		MOV S0CON, A
		
	CJNE R1, #48d, countDownLoop
	
RET
	
EOF:
	END