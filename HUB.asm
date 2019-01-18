     processor 6502
;------------------------------------------------------------   
;SYM-HUB: RS232 Mailbox for 3 Hubsters, 84 bytes apiece
;  -- connects to an identical box for 3 more Hubsters
; author Phil Stone, 1987
;
; Source recreated from machine code of original SYM HUB ROM
;  -- assembles back to identical machine code as in ROM
;------------------------------------------------------------

* = $C800
            
;---------   CONSTANTS
;OFFSETS into 5-byte read/write info:
WRI_PT  = $00		;WRITE_PTR(2 bytes)
REA_PT  = $02		;READ_PTR(2 bytes)
DAT_PT  = $04		;Data
ACSTAT  = $00		;ACIA register offsets
ACDATA  = $01

;----------   ZERO PAGE VARIABLES
HTIMER  = $00		;HUB timer: 60Hz 16-bit count since start or reset
					; and $01
HMEM00  = $06		;$06 - $09 base addresses for each Hub channel
MPTR_A  = $0A		;5 bytes of read/write ptrs/data for channel A
MPTR_B  = $0F		;5 bytes of read/write ptrs/data for channel B 
MPTR_C  = $14		;5 bytes of read/write ptrs/data for channel C
MPTR_D  = $19		;5 bytes of read/write ptrs/data for channel D
INBYTE  = $1E		;incoming byte (command nibble | data nibble)
DATA    = $20		;data nibble
CMDVEC  = $0022		;2-byte command vector
ADRPTR  = $24		;pointer to read and write pointers for each channel
MEMORY  = $26		;pointer into actual storage ($300-$4FF)
HUBCHN  = $28		;Hub channel 0-3
PRTSNO  = $29		;set to 2 to use PORT D as extra Hubster (no copy channel)
D_ACTV  = $2A		;Hub-to-Hub copy operation (on 'D' ACIAs) active?
BVECTR  = $2B		;two-byte jump vector
HCPY_F  = $2D		;HUB copy (from) pointer
HX_PTR  = $2E		;pointer to 'external' page of Hub memory, for copying operation
READVC  = $002F		;ACIA Read vector (2 bytes)
WRITVC  = $0031		;ACIA Write vector (2 bytes)
HTDSP0  = $34		;Hub timer display digits
HTDSP1  = $35
HTDSP2  = $36
HTDSP3  = $37
HTDSP4  = $38
IN_BUF  = $39		;input buffer pointer (2 bytes)
OU_BUF  = $3B		;output (processed) buffer pointer (2 bytes)
IN_BLOC = $3D		;block incoming data? (overrun)
DSTATX  = $3E		;copy of last ACIA channel D status
XRSTVC  = $003F		;2-byte custom reset vector
V1IFLG  = $41		;copy of last VIA #1 interrupt flags
TPAUSE  = $42		;Boolean: in 'pause' state of HUB memory copy?

;----------  BUFFER PAGE
BUFPGE  = $200		; - $2FF: used for input buffering

;----------  'HUB' SHARED MEMORY
HL_MEM  = $300		;memory space for 3 local Hub members (84 bytes each)
HX_MEM  = $400		;memory space for 3 'external' Hub members (84 bytes each)

;----------  4 X 6850 ACIA (Serial interface) chips
HUB_AS = $4010		;HUB ACIA A - Control/Status register
HUB_A  = $4011		;HUB ACIA A - Data register
HUB_BS = $4020		;HUB ACIA B - Control/Status register
HUB_B  = $4021		;HUB ACIA B - Data register
HUB_CS = $4040		;HUB ACIA C - Control/Status register
HUB_C  = $4041		;HUB ACIA C - Data register
HUB_DS = $4080		;HUB ACIA D - Control/Status register
HUB_D  = $4081		;HUB ACIA D - Data register

;----------  SYM Monitor subroutines
BEEP   = $8972		;Beep the SYM annunciator
CONFIG = $89A5		;Configure SYM I/O (kbd and display)
ACCESS = $8B86		;Unlock system memory (kbd and display)
SEGSM1 = $8C29		;SYM display

;---------  VIA (6522) #1
V1T1CL = $A004		;VIA 1 Timer 1 Write Latch / Read Counter Low byte
V1T2CL = $A008		;VIA 1 Timer 2 Write Latch / Read Counter Low byte
V1_ACR = $A00B		;VIA 1 Auxiliary Control Register
V1_IFR = $A00D		;VIA 1 Interrupt Flag Register
V1_IER = $A00E		;VIA 1 Interrupt Enable Register

;---------  6532 (which includes system RAM)
KBDORA = $A400		;6532 Output register A (Keyboard columns)
KBDORB = $A402		;6532 Output register B (Keyboard rows)
DSPBUF = $A640		;6532 System RAM: Display Buffer

;---------  VIA (6522) #2
V2T2CL = $A808		;VIA 2 Timer 2 Write Latch / Read Counter Low byte
V2_ACR = $A80B		;VIA 2 Auxiliary Control Register
V2_IFR = $A80D		;VIA 2 Interrupt Flag Register
V2_IER = $A80E		;VIA 2 Interrupt Enable Register

USRBRK = $FFF6		;user break vector
RSTVEC = $FFFC		;reset vector
IRQVEC = $FFFE		;interrupt vector


 ;---------- INITIALIZATION
 
            SEI
            JSR ACCESS		;unlock system RAM (display, keyboard)
            LDA RSTVEC		;splice ACIA reset routine into reset vector
            STA XRSTVC
            LDA RSTVEC+1
            STA XRSTVC+1
            LDA #<RSTTRG
            STA RSTVEC
            LDA #>RSTTRG
            STA RSTVEC+1
            LDA #0			;init page zero vars
            STA HTIMER
            STA HTIMER+1
            STA $02			;unused locations 2-5
            STA $03
            STA $04
            STA $05
            STA HCPY_F
            STA HX_PTR
            STA IN_BUF
            STA OU_BUF
            STA IN_BLOC
            STA ADRPTR+1
            STA TPAUSE
            LDA #>BUFPGE		;in/out buffer: $200-$2FF
            STA IN_BUF+1
            STA OU_BUF+1
            LDA #9
            JSR CONFIG
            LDX #3
SETDSP      LDA DSPDAT,X		;set display to 'Hub 3.1'
            STA DSPBUF,X
            DEX
            BPL SETDSP
            LDX #1
            LDA SEGSM1,X
            ORA #$80
            STA DSPBUF+4
            LDX #3
            LDA SEGSM1,X
            STA DSPBUF+5
            LDA #<HUBCPY 
            STA BVECTR
            LDA #>HUBCPY 
            STA BVECTR+1
            LDA #<IRQSRV
            STA IRQVEC
            LDA #>IRQSRV
            STA IRQVEC+1
            LDA #MPTR_A
            STA HMEM00
            LDA #MPTR_B
            STA HMEM00+1
            LDA #MPTR_C
            STA HMEM00+2
            LDA #MPTR_D
            STA HMEM00+3
            LDA #0
            STA MPTR_A+1		;set hi bytes of memory pointers to 0
            STA MPTR_A+3
            STA MPTR_B+1
            STA MPTR_B+3
            STA MPTR_C+1
            STA MPTR_C+3
            STA MPTR_D+1
            STA MPTR_D+3
            LDA #2			;make ACIA D a 'copy channel' (not a 4th hubster channel)
            STA PRTSNO
            LDA #0
            STA D_ACTV
            LDX #3			;write to all 4 ACIA status registers
            LDY #ACSTAT
WR1         LDA #$03			;master reset
            JSR WRACIA		;write to ACIA channel (X)
            LDA #$95			; /16 = 9600 baud, 8 bits + 1 stop bit, 
            JSR WRACIA		;   receive interrupt enabled
            DEX
            BPL WR1
            CLI
            
;---------- BEGIN MAIN LOOP

MAINLP      LDA D_ACTV		;ACIA D already active? (external HUB)
            BNE BRC8BB		; Yes: skip past ACIA D polling-for-start
            LDA HUB_DS		; No: see if start byte is ready now
            AND #$01			;receive data register full on ACIA D?
            BEQ BRC8BB		; No: skip ahead
            LDA HUB_D		; Yes: grab the start byte from ACIA D
            JSR STHTMR		;  and start the HUB timer (and copy process)
BRC8BB      SEI
            LDA IN_BUF		;any incoming data from ACIA(s) to process?
            CMP OU_BUF
            BEQ MLOOPX		; No: skip to end of main loop
            LDY #0			; Yes: read it in to the appropriate place in HUB memory
            LDA (OU_BUF),Y	; get data byte
            STA INBYTE
            INC OU_BUF
            LDA (OU_BUF),Y	;get Hub channel
            TAX				; stash it in X
            STX HUBCHN		; and in var
            INC OU_BUF
            LDA IN_BLOC		;read interrupts disabled (to catch up)?
            BEQ BRC8E4		; No: skip to processing command from queue 
            DEC IN_BLOC
            BNE BRC8E4
            LDA #$95			;re-enable read interrupts
            STA HUB_AS		; (and set /16 (9600 baud)) on ACIAs A,B and C
            STA HUB_BS
            STA HUB_CS
BRC8E4      CLI
            LDA HMEM00,X		;get the base address for this Hub channel's alloted memory
            STA ADRPTR
            LDA #$0F
            AND INBYTE
            STA DATA			;data nibble from incoming Command/Data byte
            LDA #$F0
            AND INBYTE
            STA INBYTE		;shift the 'command nibble' into place
            LSR				; which indexes CMDTAB, below
            LSR
            LSR
            TAX
            LDA CMDTAB,X
            STA CMDVEC
            INX
            LDA CMDTAB,X
            STA CMDVEC+1
            JMP (CMDVEC)		;execute command
MLOOPX      CLI
            JSR UPDDSP
JUMP00      JMP MAINLP

;---------- END MAIN LOOP

; Vector values for jump to commands, below
CMDTAB      .WORD CMD_00		;set write address LO nibble
            .WORD CMD_01		;set write address MID nibble
            .WORD CMD_02		;set write address HI nibble
            .WORD CMD_03		;write lo nibble of byte to write address
            .WORD CMD_04		;write hi nibble of byte to write address
            .WORD CMD_05		;add offset to write address
            .WORD CMD_06		;write hi nibble of byte and increment write address
            .WORD CMD_07		;NOP
            .WORD CMD_08		;set read address LO nibble
            .WORD CMD_09		;set read address MID nibble
            .WORD CMD_0A		;set read address HI nibble
            .WORD CMD_0B		;read byte
            .WORD CMD_0C		;read and increment read address
            .WORD CMD_0D		;read HUB timer lo byte
            .WORD CMD_0E		;read HUB timer hi byte
            .WORD CMD_0F		;start HUB timer

DSPDAT      .BYTE $74		;codes for "hub 3.1" message on start-up display
            .BYTE $1C
            .BYTE $7C
            .BYTE $00
            .BYTE $86
            .BYTE $BB

L_HNIB      TYA				;set HI or LO nibble of read or write address
            AND #$01
            BNE SETHIX
            LDA (ADRPTR),Y	;set LO nibble
            AND #$F0
            ORA DATA
            STA (ADRPTR),Y
            RTS

SETHIX      CLC				;set HI nibble
            LDA (ADRPTR),Y
            AND #$F0
            ORA DATA
            ADC #>HL_MEM		;Hub memory is at $300
            STA (ADRPTR),Y
            RTS

MIDNIB      LDA (ADRPTR),Y	;set MID nibble of read or write address
            AND #$0F
            ASL DATA
            ASL DATA
            ASL DATA
            ASL DATA
            ORA DATA
            STA (ADRPTR),Y
            RTS

PREPRW      LDA (ADRPTR),Y	;set up memory pointer
            STA MEMORY
            INY
            LDA (ADRPTR),Y
            STA MEMORY+1
            RTS

WRITEX      LDY #WRI_PT		;write current data byte to current MEMORY address
            JSR PREPRW
            LDY #DAT_PT
            LDA (ADRPTR),Y
            LDY #WRI_PT
            STA (MEMORY),Y
            RTS

INCADR      CLC				;increment a 16-bit address pointer
            LDA (ADRPTR),Y
            ADC #1
            STA (ADRPTR),Y
            BCC BRC988
            CLC
            INY
            LDA (ADRPTR),Y
            ADC #1
            STA (ADRPTR),Y
BRC988      RTS

READXX      LDX HUBCHN		;read data byte from current MEMORY address
            LDY #ACSTAT		; and write it to requesting HUB channel
BRC98D      JSR RDACIA		;wait for that ACIA to be ready to transmit
            AND #$02
            BEQ BRC98D
            LDY #0
            LDA (MEMORY),Y
            LDY #ACDATA
            JSR WRACIA		;write data byte to ACIA (X) data register
            RTS

BYTOUT      LDX HUBCHN
            LDY #ACSTAT
            PHA
BRC9A3      JSR RDACIA		;read ACIA status register
            AND #$02
            BEQ BRC9A3
            PLA
            LDY #ACDATA
            JSR WRACIA		;write to ACIA data register
            RTS

; Commands received from Hubster ACIAs
CMD_00      LDY #WRI_PT		;set write address LO nibble
            JSR L_HNIB
            JMP JUMP00

CMD_01      LDY #WRI_PT		;set write address MID nibble
            JSR MIDNIB
            JMP JUMP00

CMD_02      LDY #WRI_PT+1	;set write address HI nibble
            JSR L_HNIB
            JMP JUMP00

CMD_03      LDY #DAT_PT		;write lo nibble of byte
            JSR L_HNIB
            JMP JUMP00

CMD_04      LDY #DAT_PT		;write hi nibble of byte to write address
            JSR MIDNIB
            JSR WRITEX
            JMP JUMP00

CMD_05      CLC				;add data value to the write address
            LDY #WRI_PT
            LDA (ADRPTR),Y
            ADC DATA
            STA (ADRPTR),Y
            BCC BRC9F0
            CLC
            LDY #WRI_PT+1
            LDA (ADRPTR),Y
            ADC #1
            STA (ADRPTR),Y
BRC9F0      JMP JUMP00

CMD_06      LDY #DAT_PT		;write hi nibble of byte and incrememnt write address
            JSR MIDNIB
            JSR WRITEX
            LDY #WRI_PT
            JSR INCADR
            JMP JUMP00

CMD_07      NOP				;placeholder
            JMP JUMP00

CMD_08      LDY #REA_PT		;set read address LO nibble
            JSR L_HNIB
            JMP JUMP00

CMD_09      LDY #REA_PT		;set read address MID nibble
            JSR MIDNIB
            JMP JUMP00

CMD_0A      LDY #REA_PT+1	;set read address HI nibble
            JSR L_HNIB
            JMP JUMP00

CMD_0B      LDY #REA_PT		;read byte from MEMORY and write to requesting Hub channel
            JSR PREPRW
            JSR READXX
            JMP JUMP00

CMD_0C      LDY #REA_PT		;read byte and increment read address
            JSR PREPRW
            JSR READXX
            LDY #REA_PT
            JSR INCADR
            JMP JUMP00

CMD_0D      LDA HTIMER		;read Hub timer lo
            JSR BYTOUT
            JMP JUMP00
CMD_0E      LDA HTIMER+1		;read Hub timer hi
            JSR BYTOUT
            JMP JUMP00

CMD_0F      LDA DATA			;start Hub timer (and Hub-Hub copy process)
            CMP #1
            BNE BRCA56
            JSR CLRDSP
            JMP JUMP00
BRCA56      JSR STHTMR
            JMP JUMP00

; Start HUB timer and enable interrupts from channel D (external copy)
STHTMR      SEI
            LDA #$C0
            STA V1_ACR		;V1 Timer 1 is free-running
            LDA #0
            STA V2_ACR		;V2 Timer 1 is one-shot
            LDA #$7F
            STA V1_IER
            STA V2_IER
            LDA #$E0
            STA V1_IER
            LDA #$A0
            STA V2_IER
            LDA #$1A			;set V1 Timer 1 to $411A (16.667 mSecs, or 60 Hz)
            STA V1T1CL
            LDA #$41
            STA V1T1CL+1
            LDA #$B6			;config. ACIA D: /64 (2400 baud) - 8 bits + 1 stop bit,
            STA HUB_DS		;  enable receive AND transmit interrupts 
            LDA #$FF
            STA D_ACTV
            STA HUB_D		;send "initiator" byte to other HUB to start copy process
CLRDSP      SEI				;reset HUB timer and its display digits
            LDA #0
            STA HTIMER
            STA HTIMER+1
            STA HTDSP4
            STA HTDSP3
            STA HTDSP2
            STA HTDSP1
            STA HTDSP0
            LDX #5
BRCAA2      STA DSPBUF,X
            DEX
            BPL BRCAA2
            CLI
            RTS

; Read byte from HUB channel (X) ACIA, register (Y)
RDACIA      TXA
            PHA
            ASL
            TAX
            LDA HBRADR,X
            STA READVC
            LDA HBRADR+1,X
            STA READVC+1
            PLA
            TAX
            JMP (READVC)
HBRADR      .WORD HUBR0
            .WORD HUBR1
            .WORD HUBR2
            .WORD HUBR3
HUBR0       LDA HUB_AS,Y
            RTS
HUBR1       LDA HUB_BS,Y
            RTS
HUBR2       LDA HUB_CS,Y
            RTS
HUBR3       LDA HUB_DS,Y
            RTS

; Write byte to HUB channel (X) ACIA, register (Y)
WRACIA      PHA
            TXA
            PHA
            ASL
            TAX
            LDA HBWADR,X
            STA WRITVC
            LDA HBWADR+1,X
            STA WRITVC+1
            PLA
            TAX
            PLA
            JMP (WRITVC)
HBWADR      .WORD HUBW0
            .WORD HUBW1
            .WORD HUBW2
            .WORD HUBW3
HUBW0       STA HUB_AS,Y
            RTS
HUBW1       STA HUB_BS,Y
            RTS
HUBW2       STA HUB_CS,Y
            RTS
HUBW3       STA HUB_DS,Y
            RTS
UPDDSP      LDX #5
            LDY #0
SCNLUP      LDA DSPBUF,X
            STY KBDORA
            STX KBDORB
            STA KBDORA
            DEX
            BPL SCNLUP
            RTS

; Interrupt service routine
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

NOBRK       LDY #0
            LDX PRTSNO
            CPX #3
            BCC CHK_C
            LDA HUB_DS		;any data ready from ACIA D?
            BPL CHECK_C
            LDA HUB_D		; Yes: grab it
            JSR STOREB
CHECK_C     DEX
CHK_C      	LDA HUB_CS		;any data ready from ACIA C?
            BPL CHECKB
            LDA HUB_C		; Yes: grab it
            JSR STOREB
CHECKB      DEX
            LDA HUB_BS		;any data ready from ACIA B?
            BPL CHECKA
            LDA HUB_B		; Yes: grab it
            JSR STOREB
CHECKA      DEX
            LDA HUB_AS		;any data ready from ACIA A?
            BPL CHECKT
            LDA HUB_A		; Yes: grab it
            JSR STOREB
CHECKT      LDA V1_IFR		;is this a V1 timer interrupt?
            STA V1IFLG
            STA V1_IFR		;clear all bits in V1 IFR
            BPL GOJUMP
            AND #$40			;timeout of timer 1?
            BEQ GOJUMP
            INC HTIMER		; Yes: increment Hub timer count
            BNE BRCB76
            INC HTIMER+1
BRCB76      JSR DSP_HT		;update Hub timer and display/scan it
            JMP GOJUMP

IRQOUT      PLA
            TAY
            PLA
            TAX
            PLA
            RTI

; Stash incoming byte (and channel it came from)
;  and check for data overrun
STOREB      STA (IN_BUF),Y	;stash byte
            INC IN_BUF
            TXA
            STA (IN_BUF),Y	; and the channel it came from
            INC IN_BUF
            LDA IN_BUF
            CLC
            ADC #$10			;check to see if we're not keeping up with incoming
            CMP OU_BUF
            BNE BRCBA6		; everything's ok -- keep going
            LDA #$55			;we're falling behind against incoming data:
            STA HUB_AS		; temporarily disable ACIA A,B and C read interrupts
            STA HUB_BS
            STA HUB_CS
            LDA #2			; keep 'em disabled for 2 main loops
            STA IN_BLOC
            JSR BEEP			; make a beep to signal overrun
BRCBA6      RTS

GOJUMP      JMP (BVECTR)		;this jumps to 'HUBCPY' just below

; Hub-Hub copy process
;  Read in copy of external HUB data page,
;  and write out copy of local page to external HUB
HUBCPY      LDA V1IFLG		;check flags from last VIA #1 interrupt
            BPL BRCBBB		; no interrupt -- skip ahead
            AND #$20			;V1 timer 2 interrupt?
            BEQ BRCBBB		; No: skip ahead
            LDA #0			; Yes: end PAUSE of memory copy
            STA TPAUSE
            LDA #$B6			;config. ACIA D: x/64 (2400 baud) - 8 bits + 1 stop bit,
            STA HUB_DS		;  enable receive AND transmit interrupts 
BRCBBB      LDA V2_IFR		;interrupt on V2? (HubCopy Timeout)
            BPL BRCBC7
            STA V2_IFR
            LDA #0			; Yes: reset HUB-copy write pointer to beginning of page
            STA HX_PTR
BRCBC7      LDA HUB_DS		;check if there's an incoming byte from remote HUB data
            STA DSTATX		;  (a.k.a channel D)
            BPL HCPYOU		; none ready
            AND #$01
            BEQ HCPYOU
            LDA HUB_D		;one *is* ready - read it in
            LDY HX_PTR
            STA HX_MEM,Y		;stash it...
            INC HX_PTR		; and increment the pointer
            LDA #$D2			;reset V2 Timer 2 (HubCopy Timeout) to $30D2 (12.498 mSec)
            STA V2T2CL
            LDA #$30
            STA V2T2CL+1
HCPYOU      LDA DSTATX		;get last ACIA D status
            BPL IRQOUT		; if no interrrupt request, skip out
            AND #$02			; if not 'Transmit Data Register Empty'
            BEQ IRQOUT		;     -- skip out
            BIT TPAUSE		; if in 'pause' state of mem. copy
            BMI IRQOUT		;     -- skip out
            LDY HCPY_F		; get current copy-from pointer
            INC HCPY_F		; increment copy-from pointer
            BNE WRBY00		; if no page wrap, skip to writing byte out
            LDA #$5E			;At page wrap: go into 21 mSec pause, for synchronization
            STA V1T2CL		; set VIA #1 Timer 2 to $515E (20.830 mSec)
            LDA #$51
            STA V1T2CL+1
            LDA #$FF
            STA TPAUSE
            LDA #$96			;enable RECEIVE but NOT TRANSMIT interrupts on ACIA D
            STA HUB_DS
WRBY00      LDA HL_MEM,Y
            STA HUB_D		;write current 'copy' byte to ACIA D (remote HUB)
            JMP IRQOUT

; Display Hub timer in stopwatch format
DSP_HT      INC HTDSP4
            LDA HTDSP4
            CMP #60
            BCC BRCC46
            LDA #0
            STA HTDSP4		; seconds
            INC HTDSP3
            LDA HTDSP3
            CMP #10
            BCC BRCC46
            LDA #0
            STA HTDSP3		; tens of seconds
            INC HTDSP2
            LDA HTDSP2
            CMP #6
            BCC BRCC46
            LDA #0
            STA HTDSP2		; minutes
            INC HTDSP1
            LDA HTDSP1
            CMP #10
            BCC BRCC46
            LDA #0
            STA HTDSP1		; tens of minutes
            INC HTDSP0
BRCC46      LDX #3
BRCC48      LDA HTDSP0,X
            TAY
            LDA SEGSM1,Y
            STA DSPBUF+2,X
            DEX
            BPL BRCC48
            RTS

; Reset ALL ACIAs - spliced into system reset
RSTTRG      LDA #3
            STA HUB_AS
            STA HUB_BS
            STA HUB_CS
            STA HUB_DS
            JMP (XRSTVC)
            
.END