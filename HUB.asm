     processor 6502
     
;SYM-HUB: maintain 2-way communication with 4 ACIAs
* = $C800
            
;---------   CONSTANTS
;OFFSETS into 5-byte read/write info:
WRI_PT  = $00           ;WRITE_PTR(2 bytes)
REA_PT  = $02           ;READ_PTR(2 bytes)
DAT_PT  = $04           ;Data
ACSTAT  = $00           ; ACIA register offsets
ACDATA  = $01

;----------   ZERO PAGE VARIABLES
HTIMER  = $00           ; HUB timer: 60Hz 16-count since start or reset                        
HMEM00  = $06           ; $06 - $09 base addresses for each Hub channel
MPTR_A  = $0A           ;5 bytes of read/write ptrs/data for channel A
MPTR_B  = $0F           ;5 bytes of read/write ptrs/data for channel B 
MPTR_C  = $14           ;5 bytes of read/write ptrs/data for channel C
MPTR_D  = $19           ;5 bytes of read/write ptrs/data for channel D
INBYTE  = $1E           ;Incoming byte (command nibble | data nibble)
DATA    = $20           ;Data
CMDVEC  = $0022         ;2-byte command vector
ADRPTR  = $24           ;Pointer to read and write pointers for each channel
MEMORY  = $26           ;Pointer into actual storage ($300-$4FF)
HUBCHN  = $28           ;Hub channel 0-3
PRTSNO  = $29           ;Set to $03 to use PORT D as extra Hubster (no copy channel)
D_ACTV  = $2A
BVECTR  = $2B           ;two-byte jump vector
HCPY_F  = $2D           ;HUB copy (from) pointer
HX_PTR  = $2E           ;Pointer to 'external' page of Hub memory, for copying operation
READVC  = $002F         ;ACIA Read vector (2 bytes)
WRITVC  = $0031         ;ACIA Write vector (2 bytes)
IN_BUF  = $39           ;Incoming bytes (and associated channel) from ACIA interrupts stored here
OU_BUF  = $3B           ;  Keeps track of processed bytes
IN_BLOC = $3D           ;Block incoming data? (overrun)
DSTATX  = $3E           ; copy of last ACIA channel D status
V1IFLG  = $41           ; copy of last VIA #1 interrupt flags
TPAUSE  = $42           ;Boolean: in 'pause' state of HUB memory copy?

;----------  'HUB' SHARED MEMORY
HL_MEM  = $300          ; memory space for 3 local Hub members (84 bytes each)
HX_MEM  = $400          ; memory space for 3 'external' Hub members (84 bytes each)

;----------  4 X 6850 ACIA (Serial interface) chips
HUB_AS = $4010           ;HUB ACIA A - Control/Status register
HUB_A  = $4011           ;HUB ACIA A - Data register
HUB_BS = $4020           ;HUB ACIA B - Control/Status register
HUB_B  = $4021           ;HUB ACIA B - Data register
HUB_CS = $4040           ;HUB ACIA C - Control/Status register
HUB_C  = $4041           ;HUB ACIA C - Data register
HUB_DS = $4080           ;HUB ACIA D - Control/Status register
HUB_D  = $4081           ;HUB ACIA D - Data register

BEEP   = $8972           ; SYM Monitor subroutines
CONFIG = $89A5
ACCESS = $8B86
SEGSM1 = $8C29           ; SYM display

;---------  VIA (6522) #1
V1T1CL = $A004           ;VIA 1 Timer 1 Write Latch / Read Counter Low byte
V1T2CL = $A008           ;VIA 1 Timer 2 Write Latch / Read Counter Low byte
V1_ACR = $A00B           ;VIA 1 Auxiliary Control Register
V1_IFR = $A00D           ;VIA 1 Interrupt Flag Register
V1_IER = $A00E           ;VIA 1 Interrupt Enable Register

;---------  6532 (which includes system RAM)
KBDORA = $A400           ;6532 Output register A (Keyboard columns)
KBDORB = $A402           ;6532 Output register B (Keyboard rows)
DSPBUF = $A640           ;6532 System RAM: Display Buffer

;---------  VIA (6522) #2
V2T2CL = $A808           ;VIA 2 Timer 2 Write Latch / Read Counter Low byte
V2_ACR = $A80B           ;VIA 2 Auxiliary Control Register
V2_IFR = $A80D           ;VIA 2 Interrupt Flag Register
V2_IER = $A80E           ;VIA 2 Interrupt Enable Register

USRBRK = $FFF6           ;User break vector
RSTVEC = $FFFC           ;Reset vector
IRQVEC = $FFFE           ;Interrupt vector


            SEI
            JSR ACCESS				;Unlock system RAM (display, keyboard)
            LDA RSTVEC				;Splice into reset vector
            STA $3F
            LDA RSTVEC+1
            STA $40
            LDA #<RSTTRG
            STA RSTVEC
            LDA #>RSTTRG
            STA RSTVEC+1				;Init page zero vars
            LDA #$00
            STA $00
            STA $01
            STA $02
            STA $03
            STA $04
            STA $05
            STA HCPY_F
            STA HX_PTR
            STA IN_BUF
            STA OU_BUF
            STA IN_BLOC
            STA $25
            STA TPAUSE
            LDA #$02
            STA $3A
            STA $3C
            LDA #$09
            JSR CONFIG
            LDX #$03
SETDSP      LDA DSPDAT,X				;Set display to 'Hub 3.1'
            STA DSPBUF,X
            DEX
            BPL SETDSP
            LDX #$01
            LDA SEGSM1,X
            ORA #$80
            STA DSPBUF+4
            LDX #$03
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
            LDA #$00
            STA $0B
            STA $0D
            STA $10
            STA $12
            STA $15
            STA $17
            STA $1A
            STA $1C
            LDA #$02					;Make ACIA D a 'copy channel' (not a 4th hubster channel)
            STA PRTSNO
            LDA #$00
            STA D_ACTV
            LDX #$03					;Write to all 4 ACIA status registers
            LDY #ACSTAT
WR1         LDA #$03					;Master reset
            JSR WRACIA				;Write to ACIA channel (X)
            LDA #$95					; /16 = 9600 baud, 8 bits + 1 stop bit, 
            JSR WRACIA				;   receive interrupt enabled
            DEX
            BPL WR1
            CLI
;BEGIN MAIN LOOP
MAINLP      LDA D_ACTV				;ACIA D already active? (external HUB)
            BNE BRC8BB				; Yes: skip past ACIA D polling-for-start
            LDA HUB_DS				; No: see if start byte is ready now
            AND #$01					;Receive data register full on ACIA D?
            BEQ BRC8BB				; No: skip ahead
            LDA HUB_D				; Yes: grab the data from ACIA D
            JSR STHTMR				;  and start the HUB timer (and copy process)
BRC8BB      SEI
            LDA IN_BUF				;Any incoming data from ACIA(s) to process?
            CMP OU_BUF
            BEQ MLOOPX				; No: skip to end of main loop
            LDY #$00					; Yes: read it in to the appropriate place in HUB memory
            LDA (OU_BUF),Y			; Get data byte
            STA INBYTE
            INC OU_BUF
            LDA (OU_BUF),Y			;Get HUB channel
            TAX						; stash it in X
            STX HUBCHN				; and in var
            INC OU_BUF
            LDA IN_BLOC				;Read interrupts disabled (to catch up)?
            BEQ BRC8E4				; No: skip to processing command from queue 
            DEC IN_BLOC
            BNE BRC8E4
            LDA #$95					;Re-enable read interrupts
            STA HUB_AS				; (and set /16 (9600 baud)) on ACIAs A,B and C
            STA HUB_BS
            STA HUB_CS
BRC8E4      CLI
            LDA HMEM00,X				;Get the base address for this Hub channel's alloted memory
            STA ADRPTR
            LDA #$0F
            AND INBYTE
            STA DATA					;Data nibble from incoming Command/Data byte
            LDA #$F0
            AND INBYTE
            STA INBYTE				;Shift the 'command nibble' into place
            LSR						; which indexes CMDTAB, below
            LSR
            LSR
            TAX
            LDA CMDTAB,X
            STA CMDVEC
            INX
            LDA CMDTAB,X
            STA CMDVEC+1
            JMP (CMDVEC)
MLOOPX      CLI
            JSR UPDDSP
JUMP00      JMP MAINLP				;End of main loop

CMDTAB      .WORD CMD_00				;Set write address LO nibble
            .WORD CMD_01				;Set write address MID nibble
            .WORD CMD_02				;Set write address HI nibble
            .WORD CMD_03				;Write lo nibble of byte to write address
            .WORD CMD_04				;Write hi nibble of byte to write address
            .WORD CMD_05				;Add offset to write address
            .WORD CMD_06				;Write hi nibble of byte and increment write address
            .WORD CMD_07				;NOP
            .WORD CMD_08				;Set read address LO nibble
            .WORD CMD_09				;Set read address MID nibble
            .WORD CMD_0A				;Set read address HI nibble
            .WORD CMD_0B				;Read byte
            .WORD CMD_0C				;Read and increment read address
            .WORD CMD_0D				;Read HUB timer lo byte
            .WORD CMD_0E				;Read HUB timer hi byte
            .WORD CMD_0F				;Start HUB timer

DSPDAT      .BYTE $74				;Codes for "hub 3.1" message on display
            .BYTE $1C
            .BYTE $7C
            .BYTE $00
            .BYTE $86
            .BYTE $BB

L_HNIB      TYA						;Set HI or LO nibble of read or write address
            AND #$01
            BNE SETHIX
            LDA (ADRPTR),Y			;Set LO nibble
            AND #$F0
            ORA DATA
            STA (ADRPTR),Y
            RTS

SETHIX      CLC						;Set HI nibble
            LDA (ADRPTR),Y
            AND #$F0
            ORA DATA
            ADC #>HL_MEM				;Hub memory is at $300
            STA (ADRPTR),Y
            RTS

MIDNIB      LDA (ADRPTR),Y			;Set MID nibble of read or write address
            AND #$0F
            ASL DATA
            ASL DATA
            ASL DATA
            ASL DATA
            ORA DATA
            STA (ADRPTR),Y
            RTS

PREPRW      LDA (ADRPTR),Y			;Set up memory pointer
            STA MEMORY
            INY
            LDA (ADRPTR),Y
            STA MEMORY+1
            RTS

WRITEX      LDY #WRI_PT				;Write current data byte to current MEMORY address
            JSR PREPRW
            LDY #DAT_PT
            LDA (ADRPTR),Y
            LDY #WRI_PT
            STA (MEMORY),Y
            RTS

INCADR      CLC
            LDA (ADRPTR),Y
            ADC #$01
            STA (ADRPTR),Y
            BCC BRC988
            CLC
            INY
            LDA (ADRPTR),Y
            ADC #$01
            STA (ADRPTR),Y
BRC988      RTS

READXX      LDX HUBCHN				;Read data byte from current MEMORY address
            LDY #ACSTAT				; and write it to requesting HUB channel
BRC98D      JSR RDACIA				;Wait for that ACIA to be ready to transmit
            AND #$02
            BEQ BRC98D
            LDY #$00
            LDA (MEMORY),Y
            LDY #ACDATA
            JSR WRACIA				;Write data byte to ACIA (X) data register
            RTS

BYTOUT      LDX HUBCHN
            LDY #ACSTAT
            PHA
BRC9A3      JSR RDACIA				;Read ACIA status register
            AND #$02
            BEQ BRC9A3
            PLA
            LDY #ACDATA
            JSR WRACIA				;Write to ACIA data register
            RTS

; Commands received from Hubster ACIAs
CMD_00      LDY #WRI_PT				;Set write address LO nibble
            JSR L_HNIB
            JMP JUMP00

CMD_01      LDY #WRI_PT				;Set write address MID nibble
            JSR MIDNIB
            JMP JUMP00

CMD_02      LDY #WRI_PT+1			;Set write address HI nibble
            JSR L_HNIB
            JMP JUMP00

CMD_03      LDY #DAT_PT				;Write lo nibble of byte
            JSR L_HNIB
            JMP JUMP00

CMD_04      LDY #DAT_PT				;Write hi nibble of byte to write address
            JSR MIDNIB
            JSR WRITEX
            JMP JUMP00

CMD_05      CLC						;Add data value to the write address
            LDY #WRI_PT
            LDA (ADRPTR),Y
            ADC DATA
            STA (ADRPTR),Y
            BCC BRC9F0
            CLC
            LDY #WRI_PT+1
            LDA (ADRPTR),Y
            ADC #$01
            STA (ADRPTR),Y
BRC9F0      JMP JUMP00

CMD_06      LDY #DAT_PT				;Write hi nibble of byte and incrememnt write address
            JSR MIDNIB
            JSR WRITEX
            LDY #WRI_PT
            JSR INCADR
            JMP JUMP00

CMD_07      NOP						;Placeholder
            JMP JUMP00

CMD_08      LDY #REA_PT				;Set read address LO nibble
            JSR L_HNIB
            JMP JUMP00

CMD_09      LDY #REA_PT				;Set read address MID nibble
            JSR MIDNIB
            JMP JUMP00

CMD_0A      LDY #REA_PT+1			;Set read address HI nibble
            JSR L_HNIB
            JMP JUMP00

CMD_0B      LDY #REA_PT				;Read byte from MEMORY and write to requesting Hub channel
            JSR PREPRW
            JSR READXX
            JMP JUMP00

CMD_0C      LDY #REA_PT				;Read byte and increment read address
            JSR PREPRW
            JSR READXX
            LDY #REA_PT
            JSR INCADR
            JMP JUMP00

CMD_0D      LDA HTIMER				;Read HUB timer lo
            JSR BYTOUT
            JMP JUMP00
CMD_0E      LDA HTIMER+1				;Read HUB timer hi
            JSR BYTOUT
            JMP JUMP00

CMD_0F      LDA DATA					;Start HUB timer
            CMP #$01
            BNE BRCA56
            JSR CLRDSP
            JMP JUMP00
BRCA56      JSR STHTMR
            JMP JUMP00

;Start HUB timer and enable interrupts from channel D (external copy)
STHTMR      SEI
            LDA #$C0
            STA V1_ACR				;V1 Timer 1 is free-running
            LDA #$00
            STA V2_ACR				;V2 Timer 1 is one-shot
            LDA #$7F
            STA V1_IER
            STA V2_IER
            LDA #$E0
            STA V1_IER
            LDA #$A0
            STA V2_IER
            LDA #$1A					;Set V1 Timer 1 to $411A (16.667 mSecs, or 60 Hz)
            STA V1T1CL
            LDA #$41
            STA V1T1CL+1
            LDA #$B6					;Config. ACIA D: /64 (2400 baud) - 8 bits + 1 stop bit,
            STA HUB_DS				;  enable receive AND transmit interrupts 
            LDA #$FF
            STA D_ACTV
            STA HUB_D				; Send "initiator" byte to other HUB to start copy process
CLRDSP      SEI						;Reset HUB timer and clear display
            LDA #$00
            STA HTIMER
            STA HTIMER+1
            STA $38
            STA $37
            STA $36
            STA $35
            STA $34
            LDX #$05
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
UPDDSP      LDX #$05
            LDY #$00
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

NOBRK       LDY #$00
            LDX PRTSNO
            CPX #$03
            BCC CHK_C
            LDA HUB_DS					; Any data ready from ACIA D?
            BPL CHECK_C
            LDA HUB_D					; Yes: grab it
            JSR STOREB
CHECK_C     DEX
CHK_C      	LDA HUB_CS					; Any data ready from ACIA C?
            BPL CHECKB
            LDA HUB_C					; Yes: grab it
            JSR STOREB
CHECKB      DEX
            LDA HUB_BS					; Any data ready from ACIA B?
            BPL CHECKA
            LDA HUB_B					; Yes: grab it
            JSR STOREB
CHECKA      DEX
            LDA HUB_AS					; Any data ready from ACIA A?
            BPL CHECKT
            LDA HUB_A					; Yes: grab it
            JSR STOREB
CHECKT      LDA V1_IFR					; Is this a V1 timer interrupt?
            STA V1IFLG
            STA V1_IFR					; Clear all bits in V1 IFR
            BPL GOJUMP
            AND #$40						; Timeout of timer 1?
            BEQ GOJUMP
            INC HTIMER					; Yes: increment Hub timer count
            BNE BRCB76
            INC HTIMER+1
BRCB76      JSR SCAN_D
            JMP GOJUMP

IRQOUT      PLA
            TAY
            PLA
            TAX
            PLA
            RTI


STOREB      STA (IN_BUF),Y				;Stash byte
            INC IN_BUF
            TXA
            STA (IN_BUF),Y				; and the channel it came from
            INC IN_BUF
            LDA IN_BUF
            CLC
            ADC #$10						;Check to see if we're not keeping up with incoming
            CMP OU_BUF
            BNE BRCBA6					; Everything's ok -- keep going
            LDA #$55						;We're falling behind against incoming data:
            STA HUB_AS					; Temporarily disable ACIA A,B and C read interrupts
            STA HUB_BS
            STA HUB_CS
            LDA #$02						; Keep 'em disabled for 2 main loops
            STA IN_BLOC
            JSR BEEP						; Make a beep to signal overrun
BRCBA6      RTS

GOJUMP      JMP (BVECTR)					;This jumps to 'HUBCPY' just below

;Read in copy of external HUB data page - and write out copy of local page to external HUB
HUBCPY      LDA V1IFLG					;Check flags from last VIA #1 interrupt
            BPL BRCBBB					; no interrupt -- skip ahead
            AND #$20						; V1 timer 2 interrupt?
            BEQ BRCBBB					; no -- skip ahead
            LDA #$00						; yes: end PAUSE of memory copy
            STA TPAUSE
            LDA #$B6						;Config. ACIA D: x/64 (2400 baud) - 8 bits + 1 stop bit,
            STA HUB_DS					;  enable receive AND transmit interrupts 
BRCBBB      LDA V2_IFR					;Interrupt on V2? (HubCopy Timeout)
            BPL BRCBC7
            STA V2_IFR
            LDA #$00						;Yes: reset HUB-copy write pointer to beginning of page
            STA HX_PTR
BRCBC7      LDA HUB_DS					;Check if there's an incoming byte from remote HUB data
            STA DSTATX					;  (a.k.a channel D)
            BPL HCPYOU					;None ready
            AND #$01
            BEQ HCPYOU
            LDA HUB_D					;One *is* ready - read it in
            LDY HX_PTR
            STA HX_MEM,Y					;Stash it...
            INC HX_PTR					; and increment the pointer
            LDA #$D2						;reset V2 Timer 2 (HubCopy Timeout) to $30D2 (12.498 mSec)
            STA V2T2CL
            LDA #$30
            STA V2T2CL+1
HCPYOU      LDA DSTATX					;Get last ACIA D status
            BPL IRQOUT					; If no interrrupt request, skip out
            AND #$02						; If not 'Transmit Data Register Empty'
            BEQ IRQOUT					;     -- skip out
            BIT TPAUSE					; If in 'pause' state of mem. copy
            BMI IRQOUT					;     -- skip out
            LDY HCPY_F					; Get current copy-from pointer
            INC HCPY_F					; Increment copy-from pointer
            BNE BRCC0B					; If no page wrap, skip to writing byte out
            LDA #$5E						;At page wrap: go into 21 mSec pause, for synchronization
            STA V1T2CL					;Set VIA #1 Timer 2 to $515E (20.830 mSec)
            LDA #$51
            STA V1T2CL+1
            LDA #$FF
            STA TPAUSE
            LDA #$96						;Enable RECEIVE but NOT TRANSMIT interrupts on ACIA D
            STA HUB_DS
BRCC0B      LDA HL_MEM,Y
            STA HUB_D					;Write current 'copy' byte to ACIA D (remote HUB)
            JMP IRQOUT


SCAN_D      INC $38						;Scan the display (? Not totally sure what else it does)
            LDA $38
            CMP #$3C
            BCC BRCC46
            LDA #$00
            STA $38
            INC $37
            LDA $37
            CMP #$0A
            BCC BRCC46
            LDA #$00
            STA $37
            INC $36
            LDA $36
            CMP #$06
            BCC BRCC46
            LDA #$00
            STA $36
            INC $35
            LDA $35
            CMP #$0A
            BCC BRCC46
            LDA #$00
            STA $35
            INC $34
BRCC46      LDX #$03
BRCC48      LDA $34,X
            TAY
            LDA SEGSM1,Y
            STA DSPBUF+2,X
            DEX
            BPL BRCC48
            RTS

;Reset ALL ACIAs
RSTTRG      LDA #$03
            STA HUB_AS
            STA HUB_BS
            STA HUB_CS
            STA HUB_DS
            JMP ($003F)
  .END