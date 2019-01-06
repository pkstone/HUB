;SYM memory player (scans parts of memory and 'plays' through PB7)

         processor 6502
* = $200

;---------  CONSTANTS
T2_VAL = $6000          ;Timer 2 interval (tempo timer)
 
;---------  6532 (which includes system RAM)
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
ADNBS3 = $01				;Four address nibbles for scanning address
ADNBS2 = $02
ADNBS1 = $03
ADNBS0 = $04
RANGE  = $05				;'Pitch' range (upper byte of timer)
STPFLG = $06
RSTFLG = $07

RMASK  = $09
INDEX  = $0A
SCANAD = $0B				;16-bt memory-scan address
		;$0C
TCOUNT = $0D				;Timer interrupt count
RIFLEN = $0E				;16-bit riff length
		;$0F
SCORE  = $10				;16-bit score pointer
		;$11
SCRCTR = $12				;16-bit score counter
		;$13
 
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


INIT		SEI
		JSR ACCESS
		LDA #<IRQSRV
		STA IRQVEC
		LDA #>IRQSRV
		STA IRQVEC+1
		LDA #$C0			;Set timer 1: free-running, output on PB7
		STA ACR			;    timer 2: one-shot (will trigger interrupt)
		LDA #$A0
		STA IER
 		LDA #$00
		STA SCANAD+1
		STA SCORE+1
		STA SCANAD
 		STA SCORE
 		STA ADNBS0
 		STA ADNBS1
 		STA ADNBS2
 		STA ADNBS3
		LDA #7
		STA RANGE
		LDA #$0E
		STA TEMPO
		LDA #$40
		STA RMASK		;Arbitrary rest tester: try $04
		LDA #16
		STA RIFLEN		;Initial riff length = 16
		STA SCRCTR
		LDA #0
		STA RIFLEN+1
		STA SCRCTR+1
		LDA #0
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
MLOOP	JSR GETCMD
		JMP MLOOP
 			
 			
;---------- Get pressed key (if any) and process it (scan display once)
GETCMD	JSR SAVER
		JSR SCAND			;Scan display once
		JSR KEYQ
		BNE GTKY
		JMP RESALL			;No key down: restore regs. and return
GTKY		JSR LRNKEY
		PHA
DEBNCE	JSR KEYQ
		BNE DEBNCE			;Key still down? Wait longer.
		JSR NOBEEP
		JSR KEYQ
		BNE DEBNCE
PARSE	PLA
		CMP #$0D				; < CR > = HALT
		BNE NEXT1
		STA STPFLG
		JMP RESALL
NEXT1	CMP #$2D				; < - > = 	tempo
		BNE NEXT2
		LDX #TEMPO
		JMP SETIDX		
NEXT2	CMP #$3E				; < -> > = 	pitch range
		BNE NEXT3
		LDX #RANGE
		JMP SETIDX		
NEXT3	CMP #$47				; < GO > = ADNBS1
		BNE NEXT4
		LDX #ADNBS1
		JMP SETIDX		
NEXT4	CMP #$52				; < reg > = 	ADNBS0
		BNE NEXT5
		LDX #ADNBS0
		JMP SETIDX
NEXT5	CMP #$13				;< L2 > = ADNBS3
		BNE NEXT6
		LDX #ADNBS3	
		JMP SETIDX
NEXT6	CMP #$1E				;< S2 > = ADNBS2
		BNE NEXT7
		LDX #ADNBS2
		JMP SETIDX
NEXT7	CMP #$4D				;< MEM > = RMASK
		BNE NEXT8
		LDX #RMASK			; (will require processing)
		JMP SETIDX
NEXT8	CMP #$FF				;< SHIFT > = RIFLEN
		BNE PARAM
		LDX #RIFLEN			; (will require processing)
		JMP SETIDX

PARAM	JSR ASCNIB
		LDX INDEX
		CPX #TEMPO			; Tempo?
		BNE P0
		ADC #1
		STA TEMPO
		JMP RESALL
		
P0		CPX #RMASK			; Set rest mask?
		BNE P1
		TAX
		BEQ STRM
		CLC
		CMP #8				; If choice > 8, set mask to $FF (silence)
		BCC SKX
		LDA #$FF
		BNE STRM
SKX		LDA #1
SHFT		ASL
		DEX
		BNE SHFT
STRM		STA RMASK
		JMP RESALL
	
P1		CPX #RIFLEN			; Shift key (set Riff length)
		BNE P2
		ASL					;double the index value
		TAX
		LDA RFLTAB,X
		STA RIFLEN
		LDA RFLTAB+1,X
		STA RIFLEN+1
		SEI
		LDA #0				; Force immediate riff reset
		STA SCRCTR
		LDA #0
		STA SCRCTR+1
		CLI
		JMP RESALL

P2		STA VARS,X
		LDA ADNBS1			; (re)build memory-scan pointer
		ASL
		ASL
		ASL
		ASL
		ADC ADNBS0
		STA SCANAD
		LDA ADNBS3
		ASL
		ASL
		ASL
		ASL
		ADC ADNBS2
		STA SCANAD+1

SETIDX	STX INDEX
		JMP RESALL


;---------- Display byte in Acc. on 2 lowest display positions
DSPBYT	PHA
		AND #$0F
		TAY
		LDA SEGSM1,Y
		STA DSPBUF+5
		PLA
		PHA
		LSR
		LSR
		LSR
		LSR
		TAY
		LDA SEGSM1,Y
		STA DSPBUF+4
		PLA
		RTS


;---------- Display memory pointer
DSPPTR	LDA SCORE+1
		AND #$F0
		LSR
		LSR
		LSR
		LSR
		TAY		
		LDA SEGSM1,Y		
		STA DSPBUF		
		LDA SCORE+1
		AND #$F0
		TAY
		LDA SEGSM1,Y		
		STA DSPBUF+1
		
		LDA SCORE
		AND #$F0
		LSR
		LSR
		LSR
		LSR
		TAY
		LDA SEGSM1,Y		
		STA DSPBUF+2		
		LDA SCORE
		AND #$0F
		TAY
		LDA SEGSM1,Y		
		ORA #$80				;light up decimal point
		STA DSPBUF+3
		RTS


;---------- Play one note
BOP		STA T1LL				;Store low byte of freq. in timer lo latch
		LDA RSTFLG
		BEQ GOON
		LDA #0
		STA T1CH
		STA RSTFLG
		RTS			
GOON		LDA RANGE			;store upper byte of timer ('pitch' range), which
		STA T1CH				;triggers the free-running counter output on PB7
		RTS
	
	
;---------- Interrupt service routine -- called by timeout of TIMER 2 (tempo timer)
IRQSRV	PHA
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

NOBRK	LDA IFR
		STA IFR				;Clear interrupt
		LDA #<T2_VAL			;Reset (one-shot) Timer 2
		STA T2LL
		LDA #>T2_VAL
		STA T2CH				;and re-start it

		DEC TCOUNT
		BNE IRQOUT

		LDA TEMPO			;Reset the tempo value
		STA TCOUNT
		
		LDA SCRCTR			;Score counter at zero?
		BNE PLAY
 		LDA SCRCTR+1
 		BNE PLAY	
		LDA SCANAD			;Yes: end of riff: loop back to start
 		STA SCORE
 		LDA SCANAD+1
 		STA SCORE+1
 		LDA RIFLEN
  		STA SCRCTR
 		LDA RIFLEN+1
 		STA SCRCTR+1
 		
PLAY		JSR DSPPTR
		LDY #0
		LDA (SCORE),Y		;Get next 'pitch'
		JSR DSPBYT			;Display it
 		BIT RMASK			;Arbitrary rest test
 		BEQ CONTIN
 		LDA #1			
 		STA RSTFLG
 		LDA #0
CONTIN	JSR BOP
		INC SCORE
		BNE DECCTR
		INC SCORE+1
		
DECCTR	DEC SCRCTR
		LDA SCRCTR
		CMP #$FF
 		BNE IRQOUT
 		DEC SCRCTR+1	
  			 			
IRQOUT	PLA
		TAY
		PLA
		TAX
		PLA
 		RTI
            
RFLTAB	.WORD 0				;Riff length table
		.WORD 1
		.WORD 2
		.WORD 3
		.WORD 4
		.WORD 5
		.WORD 7
		.WORD 8
		.WORD 12
		.WORD 16
		.WORD 24
		.WORD 32
		.WORD 64
		.WORD 128
		.WORD 512
		.WORD 8192
		
		.END
