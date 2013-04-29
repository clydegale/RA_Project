$NOMOD51
#include <Reg517a.inc>

;
; Aufgabe:
;
; Auf UART0 eingehende Bytes nach UART1 ausgeben
; Auf UART1 eingehende Bytes nach UART0 ausgeben
; b) mit Interrupt
;


; Variablen anlegen
dataSegment	SEGMENT DATA
RSEG		dataSegment

STACK:	DS	4


; Interrupt-Routinen definieren
CSEG
ORG		0x23
JMP		port1Interrupt

ORG		0x83
JMP		port2Interrupt


; beim Starten die Hauptfunktion aufrufen
ORG 0
JMP		start


; Haupt-Programm in eigenes Code-Segment auslagern
codeSegment SEGMENT CODE
RSEG codeSegment

start:

; Interrupts aktivieren
SETB	EAL

MOV		A,IEN0	; Port1-Interrupt-Flag auf ES0 = IEN0.4
SETB	ACC.4
MOV		IEN0,A

MOV		A,IEN2	; Port2-Interrupt-Flag auf ES1 = IEN2.0
SETB	ACC.0
MOV		IEN2,A


; Serial Mode 1: 8bit-UART bei Baudrate 9600
CLR		SM0
SETB	SM1

; Port1
SETB	REN0			; Empfang ermöglichen
SETB	BD				; Baudraten-Generator aktivieren
MOV		S0RELL,#0xD9	; Baudrate einstellen
MOV		S0RELH,#0x03	; 9600 = 03D9H

; Port2
;!!! andere Funktionsweise als Port1 !!!
; Bits nicht direkt adressierbar, sondern nur über S1CON
; S1CON:  SM | - | SM21 | REN1 | TB81 | RB81 | TI1 | RI1

MOV		S1CON,#10010000b	; SM=1 (8bit UART), REN1=1 (Empfang ermöglichen)
MOV		S1RELL,#0xB2		; Baudrate einstellen (anders als bei Port1!)
MOV 	S1RELH, #0FFh		; 9600 = B2H
	
; Stack Pointer auf reservierten Bereich setzen
MOV		SP,#STACK


;
; Haupt-Funktion
;
mainProgram:
	
	; Watchdog-Reset
	; muss periodisch ausgeführt werden, sonst setzt der Watchdog die CPU zurück
	; und die Ausgaben gehen verloren
	SETB	WDT
	SETB	SWDT
	
	; Warteschleife
	MOV		R0,#0xFF
	
	pointlessLoop:
		NOP
		NOP
		NOP
		NOP
		NOP
		DJNZ	R0,pointlessLoop
		
JMP mainProgram


;
; Interrupt Port 1
;
port1Interrupt:
	
	MOV		A,S0BUF		; Daten auf Port1 lesen
	CLR		RI0			; Empfangs-Flag wieder löschen
	
	; Daten auf Port2 schreiben
	MOV		S1BUF,A		
	
	; warten, bis Senden abgeschlossen (TI1 = S1CON.1 gesetzt wurde)
	port2SendWait:
		MOV		A,S1CON
		JNB		ACC.1,port2SendWait
	
	ANL		A,#11111101b	; TI1 zurücksetzen
	MOV		S1CON,A
	
RETI


;
; Interrupt Port 2
;
port2Interrupt:
	
	MOV		A,S1BUF				; Daten auf Port2 lesen
	ANL		S1CON,#11111110b	; RI1 zurücksetzen
	
	; Daten auf Port1 schreiben
	MOV		S0BUF,A
	
	; warten, bis Senden abgeschlossen (TI0 gesetzt wurde)
	port1SendWait:
		NOP
		JNB		TI0,port1SendWait
	
	CLR		TI0		; TI0 zurücksetzen
	
RETI


END