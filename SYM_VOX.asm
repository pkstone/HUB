         processor 6502
* = $200

 
;SYM memory player (scans parts of memory and 'plays' through PB7)
 
;---------  6532 (which includes system RAM)
KBDORA = $A400           ;6532 Output register A (Keyboard columns)
KBDORB = $A402           ;6532 Output register B (Keyboard rows)
DSPBUF = $A640           ;6532 System RAM: Display Buffer


;------ PORTS
T1LL   = $A806
T1CH   = $A805
ACR    = $A80B
IFR    = $A80D
T2LL   = $A808
T2CH   = $A809
 
;------ VARIABLES
VARS   = $00
TEMPO  = $00
DRUMLO = $01
DRUMHI = $02
PORTLO = $03
PORTHI = $04
RANGE  = $05
STPFLG = $06
RSTFLG = $07
YPTR   = $08
MASK   = $09
INDEX  = $0A
 
;------ MONITOR SUBROUTINES
RESALL = $81C4
SAVER  = $8188
ASCNIB = $8275
GETKEY = $88AF
SCAND  = $8906
KEYQ   = $8923
LRNKEY = $892C
BEEP   = $8972
NOBEEP = $899B
ACCESS = $8B86
SEGSM1 = $8C29           ; SYM display

INIT			JSR ACCESS 
			JSR SETDSP
			LDA #$C0
 			STA ACR
 			LDA #$C8
 			STA PORTHI
 			LDA #$00
 			STA PORTLO
 			LDA #7
 			STA RANGE
 			LDA #$0E
 			STA TEMPO
 			LDA #$40
 			STA MASK		   ;Arbitrary rest tester: try $04
TOP			LDA #0
 			STA STPFLG
 			STA RSTFLG
 			JSR KEYQ       ;Wait for a key press
 			BEQ TOP
 			JSR GETCMD
NEWBAR		LDA #0
 			STA YPTR
 			LDY YPTR
PLAY			LDA (PORTLO),Y	 ;Get next 'pitch'
 			BIT MASK			 ;Arbitrary rest test
 			BNE CONTIN			
 			STA RSTFLG
 			LDA #0
CONTIN		LDY TEMPO
 			JSR BOP
 			JSR GETCMD
 			LDA STPFLG
 			BNE TOP
NEXT			INC YPTR
 			LDY YPTR
 			CPY #$10				; End of bar?
 			BEQ NEWBAR
 			JMP PLAY				;  NO: back to top of play loop
 			
BOP			STA T1LL
			LDA RSTFLG
			BEQ GOON
			LDA #0
			STA T1CH
			STA RSTFLG
			JMP STALL
			
GOON			LDA RANGE
			STA T1CH
STALL		LDX #$40
WAIT			DEX
			BNE WAIT
TIME			LDA #$FF
			STA T2LL				;adjustable
			LDA #$10
			STA T2CH				;adjustable
			JSR GETCMD
			LDA STPFLG
			BNE TOP
			LDA #$20
WAITIR		BIT IFR
			BNE TIME2
			JMP WAITIR
TIME2		DEY
			BNE TIME
			RTS
			
            ; Get pressed key (if any)
GETCMD		JSR SAVER
			JSR SCAND			;Scan display once
			JSR KEYQ
			BEQ EXIT
			JSR LRNKEY
			PHA
DEBNCE		JSR KEYQ
			BNE DEBNCE			;Key still down? Wait longer.
			JSR NOBEEP
			JSR KEYQ
			BNE DEBNCE
PARSE		PLA
			CMP #$0D				; < CR > = HALT
			BNE NEXT1
			STA STPFLG
			JMP EXIT
NEXT1		CMP #$2D				; < - > = 	tempo
			BNE NEXT2
			LDX #0				; zeroeth parameter
			JMP OUT		
NEXT2		CMP #$3E				; < -> > = 	pitch range
			BNE NEXT3
			LDX #5				; fifth parameter
			JMP OUT		
NEXT3		CMP #$47				; < GO > = 	PORTHI
			BNE NEXT4
			LDX #4				; fourth parameter
			JMP OUT		
NEXT4		CMP #$52				; < reg > = 	PORTLO
			BNE PARAM
			LDX #3				; third parameter
			JMP OUT		
 		  
PARAM		JSR ASCNIB
			LDX INDEX
			CPX #5
			BEQ NOSHFT
			CPX #4
			BEQ NOSHFT
			CPX #2
			BEQ NOSHFT
SHIFT		ASL
			ASL
			ASL
			ASL
NOSHFT		STA VARS,X
OUT			STX INDEX
EXIT			JMP RESALL

SETDSP		LDX #3
SETD2		LDA DSPDAT,X       ;Set display to 'Hub 3.1'
			STA DSPBUF,X
			DEX
			BPL SETD2
			LDX #$01
			LDA SEGSM1,X
			ORA #$80
			STA DSPBUF+4
			LDX #$03
			LDA SEGSM1,X
			STA DSPBUF+5
			RTS
	
DSPDAT      .BYTE $74          ;Codes for "hub 3.1" message on display
            .BYTE $1C
            .BYTE $7C
            .BYTE $00
            .BYTE $86
            .BYTE $BB

			.END
			