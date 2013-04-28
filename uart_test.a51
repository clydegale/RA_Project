sadfNAME UARTTEST

PUBLIC start

data_segme 
;
; Start-Funktion
;
start:
	
	; Stack Pointer auf reservierten Bereich setzen
	MOV		SP,#STACK

	
	; Serial Mode 1: 8bit-UART bei Baudrate 9600
	CLR		SM0
	SETB	SM1

	; Port1
	SETB		REN0			; Empfang ermöglichen
	SETB		BD				; Baudraten-Generator aktivieren
	MOV		S0RELL,#0xD9	; Baudrate einstellen
	MOV		S0RELH,#0x03	; 9600 = 03D9H

	; Port2
	;!!! andere Funktionsweise als Port1 !!!
	; Bits nicht direkt adressierbar, sondern nur über S1CON
	; S1CON:  SM | - | SM21 | REN1 | TB81 | RB81 | TI1 | RI1

	MOV		S1CON,#10010000b	; SM=1 (8bit UART), REN1=1 (Empfang ermöglichen)
	MOV		S1RELL,#0xB2		; Baudrate einstellen (anders als bei Port1!)
	MOV 		S1RELH, #0FFh		; 9600 = B2H
	
	; Unterprogramm aufrufen
	CALL	myFunc
	
	; wieder von vorne anfangen
	;JMP		start
	
	; Programm beenden
	JMP endFunc
	

	
myFunc:

	loopRec:
		MOV A,S0CON
		JNB ACC.0,loopRec
	
	MOV r1,S0BUF
	
	ANL A,#11111110b
	MOV S0CON,A



	MOV S1BUF,r1

	MOV A,S1CON
	loop:
		MOV A, S1CON
		JNB ACC.1,loop
	
	ANL	A,#11111101b
	MOV S1CON,A
	
	;MOV r0,S1BUF
	RET

endFunc:
	NOP
	NOP
	END