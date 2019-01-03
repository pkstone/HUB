;SYM memory player (scans parts of memory and 'plays' through PB7)


         processor 6502
* = $200

;---------  CONSTANTS
T2_VAL = $3000          ;Set Timer 2 interval
 
;---------  6532 (which includes system RAM)
KBDORA = $A400           ;6532 Output register A (Keyboard columns)
KBDORB = $A402           ;6532 Output register B (Keyboard rows)
DSPBUF = $A640           ;6532 System RAM: Display Buffer


;------ PORTS
T1LL   = $A806
T1CH   = $A805
ACR    = $A80B
IFR    = $A80D
IER    = $A80E
T2LL   = $A808
T2CH   = $A809
 
;------ VARIABLES
VARS   = $00
TEMPO  = $00
PRNIBS = $01				;Four address nibbles:
PORTN3 = $01				;Address nibbles for memory read pointer
PORTN2 = $02
PORTN1 = $03
PORTN0 = $04
RANGE  = $05
STPFLG = $06
RSTFLG = $07
YPTR   = $08
RMASK  = $09
INDEX  = $0A
PORTLO = $0B
PORTHI = $0C
TCOUNT = $0D				;Timer interrupt count
 
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

USRBRK = $FFF6           ;User break vector
IRQVEC = $FFFE           ;Interrupt vector


INIT			SEI
			JSR ACCESS 
			JSR SETDSP
			LDA #<IRQSRV
			STA IRQVEC
			LDA #>IRQSRV
			STA IRQVEC+1
			LDA #$C0		;Set timer 1: free-running, output on PB7
 			STA ACR		;    timer 2: one-shot (will trigger interrupt)
 			LDA #$A0
 			STA IER
 			LDA #$C8
 			STA PORTHI
 			LDA #$00
 			STA PORTLO
 			LDA #7
 			STA RANGE
 			LDA #$0E
 			STA TEMPO
 			LDA #$40
 			STA RMASK		;Arbitrary rest tester: try $04
 			LDA #0			;zero the score pointer
 			STA YPTR
 			STA STPFLG
 			STA RSTFLG
 			LDA #1
 			STA TCOUNT
			LDA #<T2_VAL		;Set Timer 2 (tempo) value
			STA T2LL
			LDA #>T2_VAL
			STA T2CH			;and start it 			
 			CLI
 			
 			; MAIN LOOP: scan keyboard
MLOOP		JSR GETCMD
 			JMP MLOOP

BOP			STA T1LL				; Store low byte of freq. in timer lo latch
			LDA RSTFLG
			BEQ GOON
			LDA #0
			STA T1CH
			STA RSTFLG
			RTS			
GOON			LDA RANGE			;store upper byte of timer ('pitch' range), which
			STA T1CH				;triggers the free-running counter output on PB7
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
NEXT3		CMP #$47				; < GO > = 	PORTN1
			BNE NEXT4
			LDX #3				; third parameter
			JMP OUT		
NEXT4		CMP #$52				; < reg > = 	PORTN0
			BNE NEXT5
			LDX #4				; fourth parameter
			JMP OUT
NEXT5		CMP #$13				;< L2 > = PORTN3
			BNE NEXT6
			LDX #1				; first parameter
			JMP OUT
NEXT6		CMP #$1E				;< S2 > = PORTN2
			BNE PARAM
			LDX #2				; second parameter
			JMP OUT
 		  
PARAM		JSR ASCNIB
			LDX INDEX
			STA VARS,X
			LDA PORTN1			; (re)build memory-scan pointer
			ASL
			ASL
			ASL
			ASL
			ADC PORTN0
			STA PORTLO
			LDA PORTN3
			ASL
			ASL
			ASL
			ASL
			ADC PORTN2
			STA PORTHI
			
OUT			STX INDEX			
			JSR SETDSP
EXIT			JMP RESALL

			;Display memory pointer
SETDSP		LDX #3
SETD2		LDY PRNIBS,X
			LDA SEGSM1,Y
			STA DSPBUF,X
			DEX
			BPL SETD2
			LDA #0
			ORA #$80			; light up decimal point
			STA DSPBUF+4
			LDA #0
			STA DSPBUF+5
			RTS
	
; Interrupt service routine -- called by timeout of TIMER 2 (tempo timer)
IRQSRV      PHA
            TXA
            PHA
            TYA
            PHA
            TSX
            LDA $0104,X
            AND #$10
            BEQ NOBRK
            PLA
            TAY
            PLA
            TAX
            PLA
            JMP (USRBRK)

NOBRK		LDA IFR
			STA IFR			; clear interrupt
			; Re-set the (one-shot) Timer 
			LDA #<T2_VAL		;Set Timer 2 (tempo) value
			STA T2LL
			LDA #>T2_VAL
			STA T2CH			;and re-start it
			
			DEC TCOUNT
			BNE IRQOUT
			
			LDA TEMPO		;Reset the tempo value
			STA TCOUNT
PLAY			LDY YPTR
			LDA (PORTLO),Y	;Get next 'pitch'
 			BIT RMASK		;Arbitrary rest test
 			BNE CONTIN			
 			STA RSTFLG
 			LDA #0
CONTIN		JSR BOP
NEXT			INC YPTR
 			LDY YPTR
 			CPY #$10				; End of bar?
 			BNE IRQOUT
 			LDY #0				; Yes: reset score pointer
 			STY YPTR
 			 			
IRQOUT      PLA
            TAY
            PLA
            TAX
            PLA
            RTI
			