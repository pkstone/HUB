;SYM-HUB: maintain 2-way communication with 4 ACIAs

HMEM00  = $06           ; $06 - $09 base addresses for each Hub channel

MPTR_A  = $0A			;5 bytes of read/write pointers for channel A
MPTR_B  = $0F			;5 bytes of read/write pointers for channel B 
MPTR_C  = $14			;5 bytes of read/write pointers for channel C
MPTR_D  = $19			;5 bytes of read/write pointers for channel D

INBYTE  = $1E            ;Incoming byte (Command nibble | data nibble)
DATA    = $20            ;Data
CMDVEC  = $22            ;Command vector

ADRPTR  = $24            ;Pointer to read and write pointers for each channel

MEMORY  = $26            ;Pointer into actual storage ($300-$4FF)

HUBCHN  = $28            ;Hub channel 0-3

D_ACTV  = $2A

HX_PTR  = $2E            ;Pointer to 'external' page of Hub memory, for copying operation

READVC  = $2F            ;ACIA Read vector (2 bytes)

WRITVC  = $31            ;ACIA Write vector (2 bytes)

IN_BUF  = $39            ;Incoming bytes (and associated channel) from ACIA interrupts stored here
OU_BUF  = $3B            ;  Keeps track of processed bytes

HL_MEM  = $300          ; memory space for 3 local Hub members (84 bytes each)
HX_MEM  = $400          ; memory space for 3 'external' Hub members (84 bytes each)


HUB_AS = $4010           ;HUB ACIA A - Control/Status register
HUB_A  = $4011           ;HUB ACIA A - Data register
HUB_BS = $4020           ;HUB ACIA B - Control/Status register
HUB_B  = $4021           ;HUB ACIA B - Data register
HUB_CS = $4040           ;HUB ACIA C - Control/Status register
HUB_C  = $4041           ;HUB ACIA C - Data register
HUB_DS = $4080           ;HUB ACIA D - Control/Status register
HUB_D  = $4081           ;HUB ACIA D - Data register

; SYM Monitor subroutines
BEEP   = $8972

; VIA (6522) #1
V1T1CL = $A004           ;VIA 1 Timer 1 Write Latch / Read Counter Low byte
V1T2CL = $A008           ;VIA 1 Timer 2 Write Latch / Read Counter Low byte
V1_ACR = $A00B           ;VIA 1 Auxiliary Control Register
V1_IFR = $A00D           ;VIA 1 Interrupt Flag Register
V1_IER = $A00E           ;VIA 1 Interrupt Enable Register

; 6532 (which includes system RAM)
KBDORA = $A400           ;6532 Output register A (Keyboard columns)
KBDORB = $A402           ;6532 Output register B (Keyboard rows)
DSPBUF = $A640           ;6532 System RAM: Display Buffer

; VIA (6522) #2
V2T2CL = $A808           ;VIA 2 Timer 2 Write Latch / Read Counter Low byte
V2_ACR = $A80B           ;VIA 2 Auxiliary Control Register
V2_IFR = $A80D           ;VIA 2 Interrupt Flag Register
V2_IER = $A80E           ;VIA 2 Interrupt Enable Register

USRBRK = $FFF6           ;User break vector
RSTVEC = $FFFC           ;Reset vector
IRQVEC = $FFFE           ;Interrupt vector


                            * = C800
C800   78                   SEI
C801   20 86 8B             JSR ACCESS
C804   AD FC FF             LDA RSTVEC
C807   85 3F                STA $3F
C809   AD FD FF             LDA RSTVEC+1
C80C   85 40                STA $40
C80E   A9 55                LDA #<RSTTRG
C810   8D FC FF             STA RSTVEC
C813   A9 CC                LDA #>RSTTRG
C815   8D FD FF             STA RSTVEC+1
C818   A9 00                LDA #$00
C81A   85 00                STA $00
C81C   85 01                STA $01
C81E   85 02                STA $02
C820   85 03                STA $03
C822   85 04                STA $04
C824   85 05                STA $05
C826   85 2D                STA $2D
C828   85 2E                STA HX_PTR
C82A   85 39                STA IN_BUF
C82C   85 3B                STA OU_BUF
C82E   85 3D                STA $3D
C830   85 25                STA $25
C832   85 42                STA $42
C834   A9 02                LDA #$02
C836   85 3A                STA $3A
C838   85 3C                STA $3C
C83A   A9 09                LDA #$09
C83C   20 A5 89             JSR CONFIG
C83F   A2 03                LDX #$03
C841   BD 2E C9    SETDSP   LDA DSPDAT,X       ;Set display to 'Hub 3.1'
C844   9D 40 A6             STA DSPBUF,X
C847   CA                   DEX
C848   10 F7                BPL SETDSP
C84A   A2 01                LDX #$01
C84C   BD 29 8C             LDA SEGSM1,X
C84F   09 80                ORA #$80
C851   8D 44 A6             STA DSPBUF+4
C854   A2 03                LDX #$03
C856   BD 29 8C             LDA SEGSM1,X
C859   8D 45 A6             STA DSPBUF+5

C85C   A9 AA                LDA #<INPUT 
C85E   85 2B                STA $2B
C860   A9 CB                LDA #>INPUT 
C862   85 2C                STA $2C
C864   A9 16                LDA #<IRQSRV
C866   8D FE FF             STA IRQVCL
C869   A9 CB                LDA #>IQRSRV
C86B   8D FF FF             STA IRQVCH

C86E   A9 0A                LDA #MPTR_A
C870   85 06                STA HMEM00
C872   A9 0F                LDA #MPTR_B
C874   85 07                STA HMEM00+1
C876   A9 14                LDA #MPTR_C
C878   85 08                STA HMEM00+2
C87A   A9 19                LDA #MPTR_D
C87C   85 09                STA HMEM00+3

C87E   A9 00                LDA #$00
C880   85 0B                STA $0B
C882   85 0D                STA $0D
C884   85 10                STA $10
C886   85 12                STA $12
C888   85 15                STA $15
C88A   85 17                STA $17
C88C   85 1A                STA $1A
C88E   85 1C                STA $1C
C890   A9 02                LDA #$02
C892   85 29                STA $29
C894   A9 00                LDA #$00
C896   85 2A                STA D_ACTV

C898   A2 03                LDX #$03            ;Write to all 4 ACIAs
C89A   A0 00                LDY #$00
C89C   A9 03       WR1      LDA #$03
C89E   20 D5 CA             JSR WRACIA          ;Write to ACIA pos (X)
C8A1   A9 95                LDA #$95
C8A3   20 D5 CA             JSR WRACIA
C8A6   CA                   DEX
C8A7   10 F3                BPL WR1
C8A9   58                   CLI

C8AA   A5 2A       MAINLP   LDA D_ACTV           ;BEGIN MAIN LOOP
C8AC   D0 0D                BNE BRC8BB
C8AE   AD 80 40             LDA HUB_DS
C8B1   29 01                AND #$01
C8B3   F0 06                BEQ BRC8BB
C8B5   AD 81 40             LDA HUB_D
C8B8   20 5C CA             JSR STHTMR
C8BB   78          BRC8BB   SEI
C8BC   A5 39                LDA IN_BUF
C8BE   C5 3B                CMP OU_BUF
C8C0   F0 45                BEQ MLOOPX
C8C2   A0 00                LDY #$00
C8C4   B1 3B                LDA (OU_BUF),Y
C8C6   85 1E                STA INBYTE
C8C8   E6 3B                INC OU_BUF
C8CA   B1 3B                LDA (OU_BUF),Y
C8CC   AA                   TAX
C8CD   86 28                STX HUBCHN
C8CF   E6 3B                INC OU_BUF
C8D1   A5 3D                LDA $3D
C8D3   F0 0F                BEQ BRC8E4
C8D5   C6 3D                DEC $3D
C8D7   D0 0B                BNE BRC8E4
C8D9   A9 95                LDA #$95              ;Configure ACIAs: baud rate, byte format, interrupt enable
C8DB   8D 10 40             STA HUB_AS
C8DE   8D 20 40             STA HUB_BS
C8E1   8D 40 40             STA HUB_CS
C8E4   58          BRC8E4   CLI
C8E5   B5 06                LDA HMEM00,X          ;Get the base address for this Hub channel's alloted memory
C8E7   85 24                STA ADRPTR
C8E9   A9 0F                LDA #$0F
C8EB   25 1E                AND INBYTE
C8ED   85 20                STA DATA              ;Data nibble from incoming Command/Data byte
C8EF   A9 F0                LDA #$F0
C8F1   25 1E                AND INBYTE
C8F3   85 1E                STA INBYTE            ; Shift the 'command nibble' into place
C8F5   4A                   LSR A                 ; which indexes CMDTAB, below
C8F6   4A                   LSR A
C8F7   4A                   LSR A
C8F8   AA                   TAX
C8F9   BD 0E C9             LDA CMDTAB,X
C8FC   85 22                STA CMDVEC
C8FE   E8                   INX
C8FF   BD 0E C9             LDA CMDTAB,X
C902   85 23                STA CMDVEC+1
C904   6C 22 00             JMP (CMDVEC)
C907   58         MLOOPX    CLI
C908   20 02 CB             JSR UPDDSP
C90B   4C AA C8   JUMP00    JMP MAINLP         ;End of main loop

C90E   B1 C9      CMDTAB    .WORD CMD_00       ;Set write address LO nibble
C910   B9 C9                .WORD CMD_01       ;Set write address MID nibble
C912   C1 C9                .WORD CMD_02       ;Set write address HI nibble
C914   C9 C9                .WORD CMD_03       ;Write lo nibble of byte to write address
C916   D1 C9                .WORD CMD_04       ;Write hi nibble of byte to write address
C918   DC C9                .WORD CMD_05
C91A   F3 C9                .WORD CMD_06       ;Write hi nibble of byte and increment write address
C91C   03 CA                .WORD CMD_07       ;NOP
C91E   07 CA                .WORD CMD_08       ;Set read address LO nibble
C920   0F CA                .WORD CMD_09       ;Set read address MID nibble
C922   17 CA                .WORD CMD_0A       ;Set read address HI nibble
C924   1F CA                .WORD CMD_0B       ;Read byte
C926   2A CA                .WORD CMD_0C       ;Read and increment read address
C928   3A CA                .WORD CMD_0D       ;Read HUB timer lo byte
C92A   42 CA                .WORD CMD_0E       ;Read HUB timer hi byte
C92C   4A CA                .WORD CMD_0F       ;Start HUB timer

C92E   74        DSPDAT     .BYTE $74          ;Codes for "hub 3.1" message on display
C92F   1C                   .BYTE $1C
C930   7C                   .BYTE $7C
C931   00                   .BYTE $00

C932   86                   .BYTE $86
C933   BB                   .BYTE $BB

C934   98        L_HNIB     TYA                ;Set HI or LO nibble of read or write address
C935   29 01                AND #$01
C937   D0 09                BNE BRC942
C939   B1 24                LDA (ADRPTR),Y     ;Set LO nibble
C93B   29 F0                AND #$F0
C93D   05 20                ORA DATA
C93F   91 24                STA (ADRPTR),Y
C941   60                   RTS
C942   18        BRC942     CLC                ;Set HI nibble
C943   B1 24                LDA (ADRPTR),Y
C945   29 F0                AND #$F0
C947   05 20                ORA DATA
C949   69 03                ADC #<HL_MEM       ;Hub memory is at $300
C94B   91 24                STA (ADRPTR),Y
C94D   60                   RTS

C94E   B1 24     MIDNIB     LDA (ADRPTR),Y     ;Set MID nibble of read or write address
C950   29 0F                AND #$0F
C952   06 20                ASL DATA
C954   06 20                ASL DATA
C956   06 20                ASL DATA
C958   06 20                ASL DATA
C95A   05 20                ORA DATA
C95C   91 24                STA (ADRPTR),Y
C95E   60                   RTS

C95F   B1 24     PREPRW     LDA (ADRPTR),Y
C961   85 26                STA MEMORY
C963   C8                   INY
C964   B1 24                LDA (ADRPTR),Y
C966   85 27                STA MEMORY+1
C968   60                   RTS

C969   A0 00     SAVBYT     LDY #$00
C96B   20 5F C9             JSR PREPRW
C96E   A0 04                LDY #$04
C970   B1 24                LDA (ADRPTR),Y
C972   A0 00                LDY #$00
C974   91 26                STA (MEMORY),Y
C976   60                   RTS

C977   18        INCADR     CLC
C978   B1 24                LDA (ADRPTR),Y
C97A   69 01                ADC #$01
C97C   91 24                STA (ADRPTR),Y
C97E   90 08                BCC BRC988
C980   18                   CLC
C981   C8                   INY
C982   B1 24                LDA (ADRPTR),Y
C984   69 01                ADC #$01
C986   91 24                STA (ADRPTR),Y
C988   60         BRC988    RTS

C989   A6 28      READXX    LDX HUBCHN
C98B   A0 00                LDY #$00
C98D   20 AA CA   BRC98D    JSR RDACIA       ;Read ACIA status register
C990   29 02                AND #$02
C992   F0 F9                BEQ BRC98D       ;Wait for byte ready
C994   A0 00                LDY #$00
C996   B1 26                LDA (MEMORY),Y
C998   A0 01                LDY #$01
C99A   20 D5 CA             JSR WRACIA       ;Write to ACIA pos 1
C99D   60                   RTS

C99E   A6 28      SRC99E    LDX HUBCHN
C9A0   A0 00                LDY #$00
C9A2   48                   PHA
C9A3   20 AA CA   BRC9A3    JSR RDACIA        ;Read ACIA status register
C9A6   29 02                AND #$02
C9A8   F0 F9                BEQ BRC9A3
C9AA   68                   PLA
C9AB   A0 01                LDY #$01
C9AD   20 D5 CA             JSR WRACIA         ;Write to ACIA pos 1
C9B0   60                   RTS

                                              ; Commands received from ACIAs
C9B1   A0 00       CMD_00   LDY #$00          ;Set write address LO nibble
C9B3   20 34 C9             JSR L_HNIB
C9B6   4C 0B C9             JMP JUMP00

C9B9   A0 00       CMD_01   LDY #$00          ;Set write address MID nibble
C9BB   20 4E C9             JSR MIDNIB
C9BE   4C 0B C9             JMP JUMP00

C9C1   A0 01       CMD_02   LDY #$01          ;Set write address HI nibble
C9C3   20 34 C9             JSR L_HNIB
C9C6   4C 0B C9             JMP JUMP00

C9C9   A0 04       CMD_03   LDY #$04          ;Write lo nibble of byte to write address
C9CB   20 34 C9             JSR L_HNIB
C9CE   4C 0B C9             JMP JUMP00

C9D1   A0 04       CMD_04   LDY #$04          ;Write hi nibble of byte to write address
C9D3   20 4E C9             JSR MIDNIB
C9D6   20 69 C9             JSR SAVBYT
C9D9   4C 0B C9             JMP JUMP00

C9DC   18          CMD_05   CLC               ;MYSTERY ROUTINE
C9DD   A0 00                LDY #$00
C9DF   B1 24                LDA (ADRPTR),Y
C9E1   65 20                ADC DATA
C9E3   91 24                STA (ADRPTR),Y
C9E5   90 09                BCC BRC9F0
C9E7   18                   CLC
C9E8   A0 01                LDY #$01
C9EA   B1 24                LDA (ADRPTR),Y
C9EC   69 01                ADC #$01
C9EE   91 24                STA (ADRPTR),Y
C9F0   4C 0B C9    BRC9F0   JMP JUMP00

C9F3   A0 04       CMD_06   LDY #$04         ;Write hi nibble of byte and incrememnt write address
C9F5   20 4E C9             JSR MIDNIB
C9F8   20 69 C9             JSR SAVBYT
C9FB   A0 00                LDY #$00
C9FD   20 77 C9             JSR INCADR
CA00   4C 0B C9             JMP JUMP00

CA03   EA          CMD_07   NOP              ;Placeholder
CA04   4C 0B C9             JMP JUMP00

CA07   A0 02       CMD_08   LDY #$02         ;Set read address LO nibble
CA09   20 34 C9             JSR L_HNIB
CA0C   4C 0B C9             JMP JUMP00

CA0F   A0 02       CMD_09   LDY #$02         ;Set read address MID nibble
CA11   20 4E C9             JSR MIDNIB
CA14   4C 0B C9             JMP JUMP00

CA17   A0 03       CMD_0A   LDY #$03         ;Set read address HI nibble
CA19   20 34 C9             JSR L_HNIB
CA1C   4C 0B C9             JMP JUMP00

CA1F   A0 02       CMD_0B   LDY #$02         ; Read byte
CA21   20 5F C9             JSR PREPRW
CA24   20 89 C9             JSR READXX
CA27   4C 0B C9             JMP JUMP00

CA2A   A0 02       CMD_0C   LDY #$02         ; Read byte and increment read address
CA2C   20 5F C9             JSR PREPRW
CA2F   20 89 C9             JSR READXX
CA32   A0 02                LDY #$02
CA34   20 77 C9             JSR INCADR
CA37   4C 0B C9             JMP JUMP00

CA3A   A5 00       CMD_0D   LDA $00           ; Read HUB timer lo
CA3C   20 9E C9             JSR SRC99E
CA3F   4C 0B C9             JMP JUMP00

CA42   A5 01       CMD_0E   LDA $01           ; Read HUB timer hi
CA44   20 9E C9             JSR SRC99E
CA47   4C 0B C9             JMP JUMP00

CA4A   A5 20       CMD_0F   LDA DATA          ; Start HUB timer
CA4C   C9 01                CMP #$01
CA4E   D0 06                BNE BRCA56
CA50   20 8F CA             JSR CLRDSP
CA53   4C 0B C9             JMP JUMP00
CA56   20 5C CA    BRCA56   JSR STHTMR
CA59   4C 0B C9             JMP JUMP00

CA5C   78          STHTMR   SEI
CA5D   A9 C0                LDA #$C0
CA5F   8D 0B A0             STA V1_ACR
CA62   A9 00                LDA #$00
CA64   8D 0B A8             STA V2_ACR
CA67   A9 7F                LDA #$7F
CA69   8D 0E A0             STA V1_IER
CA6C   8D 0E A8             STA V2_IER
CA6F   A9 E0                LDA #$E0
CA71   8D 0E A0             STA V1_IER
CA74   A9 A0                LDA #$A0
CA76   8D 0E A8             STA V2_IER
CA79   A9 1A                LDA #$1A
CA7B   8D 04 A0             STA V1T1CL
CA7E   A9 41                LDA #$41
CA80   8D 05 A0             STA V1T1CL+1
CA83   A9 B6                LDA #$B6
CA85   8D 80 40             STA HUB_DS
CA88   A9 FF                LDA #$FF
CA8A   85 2A                STA D_ACTV
CA8C   8D 81 40             STA HUB_D

CA8F   78         CLRDSP    SEI
CA90   A9 00                LDA #$00
CA92   85 00                STA $00
CA94   85 01                STA $01
CA96   85 38                STA $38
CA98   85 37                STA $37
CA9A   85 36                STA $36
CA9C   85 35                STA $35
CA9E   85 34                STA $34
CAA0   A2 05                LDX #$05
CAA2   9D 40 A6   BRCAA2    STA DSPBUF,X
CAA5   CA                   DEX
CAA6   10 FA                BPL BRCAA2
CAA8   58                   CLI
CAA9   60                   RTS

; Read byte from HUB channel (X) ACIA, register (Y)
CAAA   8A         RDACIA    TXA
CAAB   48                   PHA
CAAC   0A                   ASL A
CAAD   AA                   TAX
CAAE   BD BD CA             LDA HBWADR,X
CAB1   85 2F                STA READVC
CAB3   BD BE CA             LDA HBWADR+1,X
CAB6   85 30                STA READVC+1
CAB8   68                   PLA
CAB9   AA                   TAX
CABA   6C 2F 00             JMP (READVC)

CABD   C5 CA      HBWADR    .WORD HUBR0
CABF   C9 CA                .WORD HUBR1
CAC1   CD CA                .WORD HUBR2
CAC3   D1 CA                .WORD HUBR3

CAC5   B9 10 40   HUBR0     LDA HUB_AS,Y
CAC8   60                   RTS
CAC9   B9 20 40   HUBR1     LDA HUB_BS,Y
CACC   60                   RTS
CACD   B9 40 40   HUBR2     LDA HUB_CS,Y
CAD0   60                   RTS
CAD1   B9 80 40   HUBR3     LDA HUB_DS,Y
CAD4   60                   RTS

; Write byte to HUB channel (X) ACIA, register (Y)
CAD5   48         WRACIA    PHA
CAD6   8A                   TXA
CAD7   48                   PHA
CAD8   0A                   ASL A
CAD9   AA                   TAX
CADA   BD EA CA             LDA HBRADR,X
CADD   85 31                STA WRITVC
CADF   BD EB CA             LDA HBRADR+1,X
CAE2   85 32                STA WRITVC+1
CAE4   68                   PLA
CAE5   AA                   TAX
CAE6   68                   PLA
CAE7   6C 31 00             JMP (WRITVC)

CAEA   F2 CA      HBRADR    .WORD HUBW0
CAEC   F6 CA                .WORD HUBW1
CAEF   FA CA                .WORD HUBW2
CAF0   FE CA                .WORD HUBW3

CAF2   99 10 40   HUBW0     STA HUB_AS,Y
CAF5   60                   RTS
CAF6   99 20 40   HUBW1     STA HUB_BS,Y
CAF9   60                   RTS
CAFA   99 40 40   HUBW2     STA HUB_CS,Y
CAFD   60                   RTS
CAFE   99 80 40   HUBW3     STA HUB_DS,Y
CB01   60                   RTS

CB02   A2 05      UPDDSP    LDX #$05
CB04   A0 00                LDY #$00
CB06   BD 40 A6   SCNLUP    LDA DSPBUF,X
CB09   8C 00 A4             STY KBDORA
CB0C   8E 02 A4             STX KBDORB
CB0F   8D 00 A4             STA KBDORA
CB12   CA                   DEX
CB13   10 F1                BPL SCNLUP
CB15   60                   RTS

; Interrupt service routine
CB16   48         IRQSRV    PHA
CB17   8A                   TXA
CB18   48                   PHA
CB19   98                   TYA
CB1A   48                   PHA
CB1B   BA                   TSX
CB1C   BD 04 01             LDA $0104,X
CB1F   29 10                AND #$10
CB21   F0 08                BEQ NOBRK
CB23   68                   PLA
CB24   A8                   TAY
CB25   68                   PLA
CB26   AA                   TAX
CB27   68                   PLA
CB28   6C F6 FF             JMP (USRBRK)

CB2B   A0 00       NOBRK    LDY #$00
CB2D   A6 29                LDX $29
CB2F   E0 03                CPX #$03
CB31   90 0C                BCC BRCB3F
CB33   AD 80 40             LDA HUB_DS     ; Any data ready from ACIA D?
CB36   10 06                BPL BRCB3E
CB38   AD 81 40             LDA HUB_D      ; Yes: grab it
CB3B   20 82 CB             JSR STOREB
CB3E   CA          BRCB3E   DEX
CB3F   AD 40 40    BRCB3F   LDA HUB_CS     ; Any data ready from ACIA C?
CB42   10 06                BPL BRCB4A
CB44   AD 41 40             LDA HUB_C      ; Yes: grab it
CB47   20 82 CB             JSR STOREB
CB4A   CA          BRCB4A   DEX
CB4B   AD 20 40             LDA HUB_BS     ; Any data ready from ACIA B?
CB4E   10 06                BPL BRCB56
CB50   AD 21 40             LDA HUB_B      ; Yes: grab it
CB53   20 82 CB             JSR STOREB
CB56   CA         BRCB56    DEX
CB57   AD 10 40             LDA HUB_AS     ; Any data ready from ACIA A?
CB5A   10 06                BPL BRCB62
CB5C   AD 11 40             LDA HUB_A      ; Yes: grab it
CB5F   20 82 CB             JSR STOREB
CB62   AD 0D A0   BRCB62    LDA V1_IFR     ; Is this a V1 timer interrupt?
CB65   85 41                STA $41
CB67   8D 0D A0             STA V1_IFR     ; Clear all bits in IFR
CB6A   10 3B                BPL BRCBA7
CB6C   29 40                AND #$40       ; Timeout of timer 1?
CB6E   F0 37                BEQ BRCBA7
CB70   E6 00                INC $00        ; Yes: increment Hub timer count
CB72   D0 02                BNE BRCB76
CB74   E6 01                INC $01
CB76   20 14 CC   BRCB76    JSR SRCC14
CB79   4C A7 CB             JMP BRCBA7

CB7C   68         IRQOUT    PLA
CB7D   A8                   TAY
CB7E   68                   PLA
CB7F   AA                   TAX
CB80   68                   PLA
CB81   40                   RTI

CB82   91 39      STOREB    STA (IN_BUF),Y     ; Stash byte
CB84   E6 39                INC IN_BUF
CB86   8A                   TXA
CB87   91 39                STA (IN_BUF),Y     ; and the channel it came from
CB89   E6 39                INC IN_BUF
CB8B   A5 39                LDA IN_BUF
CB8D   18                   CLC
CB8E   69 10                ADC #$10
CB90   C5 3B                CMP OU_BUF
CB92   D0 12                BNE BRCBA6
CB94   A9 55                LDA #$55           ; Clear all ACIA interrupts (I think!??)
CB96   8D 10 40             STA HUB_AS
CB99   8D 20 40             STA HUB_BS
CB9C   8D 40 40             STA HUB_CS
CB9F   A9 02                LDA #$02
CBA1   85 3D                STA $3D
CBA3   20 72 89             JSR BEEP         ;SYM monitor call
CBA6   60         BRCBA6    RTS

CBA7   6C 2B 00   BRCBA7    JMP ($002B)

CBAA   A5 41      INPUT     LDA $41
CBAC   10 0D                BPL BRCBBB
CBAE   29 20                AND #$20
CBB0   F0 09                BEQ BRCBBB
CBB2   A9 00                LDA #$00
CBB4   85 42                STA $42
CBB6   A9 B6                LDA #$B6
CBB8   8D 80 40             STA HUB_DS
CBBB   AD 0D A8   BRCBBB    LDA V2_IFR
CBBE   10 07                BPL BRCBC7
CBC0   8D 0D A8             STA V2_IFR
CBC3   A9 00                LDA #$00
CBC5   85 2E                STA HX_PTR
CBC7   AD 80 40   BRCBC7    LDA HUB_DS
CBCA   85 3E                STA $3E
CBCC   10 18                BPL BRCBE6
CBCE   29 01                AND #$01
CBD0   F0 14                BEQ BRCBE6
CBD2   AD 81 40             LDA HUB_D
CBD5   A4 2E                LDY HX_PTR
CBD7   99 00 04             STA HX_MEM,Y
CBDA   E6 2E                INC HX_PTR
CBDC   A9 D2                LDA #$D2
CBDE   8D 08 A8             STA V2T2CL
CBE1   A9 30                LDA #$30
CBE3   8D 09 A8             STA V2T2CL+1
CBE6   A5 3E      BRCBE6    LDA $3E
CBE8   10 92                BPL IRQOUT
CBEA   29 02                AND #$02
CBEC   F0 8E                BEQ IRQOUT
CBEE   24 42                BIT $42
CBF0   30 8A                BMI IRQOUT
CBF2   A4 2D                LDY $2D
CBF4   E6 2D                INC $2D
CBF6   D0 13                BNE BRCC0B
CBF8   A9 5E                LDA #$5E
CBFA   8D 08 A0             STA V1T2CL
CBFD   A9 51                LDA #$51
CBFF   8D 09 A0             STA V1T2CL+1
CC02   A9 FF                LDA #$FF
CC04   85 42                STA $42
CC06   A9 96                LDA #$96
CC08   8D 80 40             STA HUB_DS
CC0B   B9 00 03   BRCC0B    LDA HL_MEM,Y
CC0E   8D 81 40             STA HUB_D
CC11   4C 7C CB             JMP IRQOUT

CC14   E6 38      SRCC14    INC $38
CC16   A5 38                LDA $38
CC18   C9 3C                CMP #$3C
CC1A   90 2A                BCC BRCC46
CC1C   A9 00                LDA #$00
CC1E   85 38                STA $38
CC20   E6 37                INC $37
CC22   A5 37                LDA $37
CC24   C9 0A                CMP #$0A
CC26   90 1E                BCC BRCC46
CC28   A9 00                LDA #$00
CC2A   85 37                STA $37
CC2C   E6 36                INC $36
CC2E   A5 36                LDA $36
CC30   C9 06                CMP #$06
CC32   90 12                BCC BRCC46
CC34   A9 00                LDA #$00
CC36   85 36                STA $36
CC38   E6 35                INC $35
CC3A   A5 35                LDA $35
CC3C   C9 0A                CMP #$0A
CC3E   90 06                BCC BRCC46
CC40   A9 00                LDA #$00
CC42   85 35                STA $35
CC44   E6 34                INC $34
CC46   A2 03     BRCC46     LDX #$03
CC48   B5 34     BRCC48     LDA $34,X
CC4A   A8                   TAY
CC4B   B9 29 8C             LDA SEGSM1,Y
CC4E   9D 42 A6             STA DSPBUF+2,X
CC51   CA                   DEX
CC52   10 F4                BPL BRCC48
CC54   60                   RTS



CC55   A9 03      RSTTRG    LDA #$03
CC57   8D 10 40             STA HUB_AS
CC5A   8D 20 40             STA HUB_BS
CC5D   8D 40 40             STA HUB_CS
CC60   8D 80 40             STA HUB_DS
CC63   6C 3F 00             JMP ($003F)

                  .END