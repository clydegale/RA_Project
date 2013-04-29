$NOMOD51
#include <Reg517a.inc>

NAME processB

PUBLIC processB


;Variablen anlegen
processBSegment SEGMENT CODE
RSEG		processBSegment



processB:

	CALL printToUART
	CALL EOF

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