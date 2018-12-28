;SYM-HUB: maintain 2-way communication with 4 ACIAs



                        ;---------   CONSTANTS
                        
                        ;OFFSETS into 5-byte read/write info:
WRI_PT  = $00			;WRITE_PTR(2 bytes)
REA_PT  = $02           ;READ_PTR(2 bytes)
DAT_PT  = $04           ;Data

ACSTAT  = $00           ; ACIA register offsets
ACDATA  = $01


                        ;----------   ZERO PAGE VARIABLES
						
HTIMER  = $00           ; HUB timer: 60Hz 16-count since start or reset						
HMEM00  = $06           ; $06 - $09 base addresses for each Hub channel

MPTR_A  = $0A			;5 bytes of read/write ptrs/data for channel A
MPTR_B  = $0F			;5 bytes of read/write ptrs/data for channel B 
MPTR_C  = $14			;5 bytes of read/write ptrs/data for channel C
MPTR_D  = $19			;5 bytes of read/write ptrs/data for channel D

INBYTE  = $1E            ;Incoming byte (command nibble | data nibble)
DATA    = $20            ;Data
CMDVEC  = $22            ;2-byte command vector

ADRPTR  = $24            ;Pointer to read and write pointers for each channel

MEMORY  = $26            ;Pointer into actual storage ($300-$4FF)

HUBCHN  = $28            ;Hub channel 0-3

D_ACTV  = $2A
BVECTR  = $2B            ;two-byte jump vector

HCPY_F  = $2D            ;HUB copy (from) pointer

HX_PTR  = $2E            ;Pointer to 'external' page of Hub memory, for copying operation

READVC  = $2F            ;ACIA Read vector (2 bytes)

WRITVC  = $31            ;ACIA Write vector (2 bytes)

IN_BUF  = $39            ;Incoming bytes (and associated channel) from ACIA interrupts stored here
OU_BUF  = $3B            ;  Keeps track of processed bytes

DSTATX  = $3E           ; copy of last ACIA channel D status

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

; SYM Monitor subroutine
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
C826   85 2D                STA HCPY_F
C828   85 2E                STA HX_PTR
C82A   85 39                STA IN_BUF
C82C   85 3B                STA OU_BUF
C82E   85 3D                STA IN_BLOC
C830   85 25                STA $25
C832   85 42                STA TPAUSE
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

C85C   A9 AA                LDA #<HUBCPY 
C85E   85 2B                STA BVECTR
C860   A9 CB                LDA #>HUBCPY 
C862   85 2C                STA BVECTR+1
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

C898   A2 03                LDX #$03            ;Write to all 4 ACIA status registers
C89A   A0 00                LDY #ACSTAT
C89C   A9 03       WR1      LDA #$03            ;Master reset
C89E   20 D5 CA             JSR WRACIA          ;Write to ACIA channel (X)
C8A1   A9 95                LDA #$95            ; /16 = 9600 baud, 8 bits + 1 stop bit, 
C8A3   20 D5 CA             JSR WRACIA          ;   receive interrupt enabled
C8A6   CA                   DEX
C8A7   10 F3                BPL WR1
C8A9   58                   CLI

                   ;BEGIN MAIN LOOP
                  
C8AA   A5 2A       MAINLP   LDA D_ACTV           ;ACIA D already active? (external HUB)
C8AC   D0 0D                BNE BRC8BB           ;Yes -- skip past ACIA D polling-for-start
C8AE   AD 80 40             LDA HUB_DS           ;NO: see if start byte is ready now
C8B1   29 01                AND #$01             ;Receive data register full on ACIA D?
C8B3   F0 06                BEQ BRC8BB           ;No -- skip ahead
C8B5   AD 81 40             LDA HUB_D            ;Yes: grab the data from ACIA D
C8B8   20 5C CA             JSR STHTMR           ; and start the HUB timer (and copy process)
C8BB   78          BRC8BB   SEI
C8BC   A5 39                LDA IN_BUF           ;Any incoming data from ACIA(s) to process?
C8BE   C5 3B                CMP OU_BUF
C8C0   F0 45                BEQ MLOOPX           ;No: skip to end of main loop
C8C2   A0 00                LDY #$00             ;Yes: read it in to the appropriate place in HUB memory
C8C4   B1 3B                LDA (OU_BUF),Y       ; Get data byte
C8C6   85 1E                STA INBYTE
C8C8   E6 3B                INC OU_BUF
C8CA   B1 3B                LDA (OU_BUF),Y       ;Get HUB channel
C8CC   AA                   TAX                  ; stash it in X
C8CD   86 28                STX HUBCHN           ; and in var
C8CF   E6 3B                INC OU_BUF
C8D1   A5 3D                LDA IN_BLOC          ;Read interrupts disabled (to catch up)?
C8D3   F0 0F                BEQ BRC8E4           ;No: skip to processing command from queue 
C8D5   C6 3D                DEC IN_BLOC
C8D7   D0 0B                BNE BRC8E4
C8D9   A9 95                LDA #$95             ;Re-enable read interrupts
C8DB   8D 10 40             STA HUB_AS           ; (and set /16 (9600 baud)) on ACIAs A,B and C
C8DE   8D 20 40             STA HUB_BS
C8E1   8D 40 40             STA HUB_CS
C8E4   58          BRC8E4   CLI
C8E5   B5 06                LDA HMEM00,X         ;Get the base address for this Hub channel's alloted memory
C8E7   85 24                STA ADRPTR
C8E9   A9 0F                LDA #$0F
C8EB   25 1E                AND INBYTE
C8ED   85 20                STA DATA             ;Data nibble from incoming Command/Data byte
C8EF   A9 F0                LDA #$F0
C8F1   25 1E                AND INBYTE
C8F3   85 1E                STA INBYTE           ; Shift the 'command nibble' into place
C8F5   4A                   LSR A                ; which indexes CMDTAB, below
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
C937   D0 09                BNE SETHIX
C939   B1 24                LDA (ADRPTR),Y     ;Set LO nibble
C93B   29 F0                AND #$F0
C93D   05 20                ORA DATA
C93F   91 24                STA (ADRPTR),Y
C941   60                   RTS
C942   18        SETHIX     CLC                ;Set HI nibble
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

C969   A0 00     WRITEX     LDY #WRI_PT        ;Write current data byte to current MEMORY address
C96B   20 5F C9             JSR PREPRW
C96E   A0 04                LDY #DAT_PT
C970   B1 24                LDA (ADRPTR),Y
C972   A0 00                LDY #WRI_PT
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

C989   A6 28      READXX    LDX HUBCHN		;Read data byte from current MEMORY address
C98B   A0 00                LDY #ACSTAT      ; and write it to requesting HUB channel
C98D   20 AA CA   BRC98D    JSR RDACIA       ;Wait for that ACIA to be ready to transmit
C990   29 02                AND #$02
C992   F0 F9                BEQ BRC98D
C994   A0 00                LDY #$00
C996   B1 26                LDA (MEMORY),Y
C998   A0 01                LDY #ACDATA
C99A   20 D5 CA             JSR WRACIA       ;Write data byte to ACIA (X) data register
C99D   60                   RTS

C99E   A6 28      SRC99E    LDX HUBCHN
C9A0   A0 00                LDY #ACSTAT
C9A2   48                   PHA
C9A3   20 AA CA   BRC9A3    JSR RDACIA        ;Read ACIA status register
C9A6   29 02                AND #$02
C9A8   F0 F9                BEQ BRC9A3
C9AA   68                   PLA
C9AB   A0 01                LDY #ACDATA
C9AD   20 D5 CA             JSR WRACIA         ;Write to ACIA data register
C9B0   60                   RTS

                   ; Commands received from ACIAs
C9B1   A0 00       CMD_00   LDY #WRI_PT         ;Set write address LO nibble
C9B3   20 34 C9             JSR L_HNIB
C9B6   4C 0B C9             JMP JUMP00

C9B9   A0 00       CMD_01   LDY #WRI_PT         ;Set write address MID nibble
C9BB   20 4E C9             JSR MIDNIB
C9BE   4C 0B C9             JMP JUMP00

C9C1   A0 01       CMD_02   LDY #WRI_PT+1       ;Set write address HI nibble
C9C3   20 34 C9             JSR L_HNIB
C9C6   4C 0B C9             JMP JUMP00

C9C9   A0 04       CMD_03   LDY #DAT_PT          ;Write lo nibble of byte
C9CB   20 34 C9             JSR L_HNIB
C9CE   4C 0B C9             JMP JUMP00

C9D1   A0 04       CMD_04   LDY #DAT_PT          ;Write hi nibble of byte to write address
C9D3   20 4E C9             JSR MIDNIB
C9D6   20 69 C9             JSR WRITEX
C9D9   4C 0B C9             JMP JUMP00

C9DC   18          CMD_05   CLC                  ;Add data value to the write address
C9DD   A0 00                LDY #WRI_PT
C9DF   B1 24                LDA (ADRPTR),Y
C9E1   65 20                ADC DATA
C9E3   91 24                STA (ADRPTR),Y
C9E5   90 09                BCC BRC9F0
C9E7   18                   CLC
C9E8   A0 01                LDY #WRI_PT+1
C9EA   B1 24                LDA (ADRPTR),Y
C9EC   69 01                ADC #$01
C9EE   91 24                STA (ADRPTR),Y
C9F0   4C 0B C9    BRC9F0   JMP JUMP00

C9F3   A0 04       CMD_06   LDY #DAT_PT         ;Write hi nibble of byte and incrememnt write address
C9F5   20 4E C9             JSR MIDNIB
C9F8   20 69 C9             JSR WRITEX
C9FB   A0 00                LDY #WRI_PT
C9FD   20 77 C9             JSR INCADR
CA00   4C 0B C9             JMP JUMP00

CA03   EA          CMD_07   NOP                 ;Placeholder
CA04   4C 0B C9             JMP JUMP00

CA07   A0 02       CMD_08   LDY #REA_PT         ;Set read address LO nibble
CA09   20 34 C9             JSR L_HNIB
CA0C   4C 0B C9             JMP JUMP00

CA0F   A0 02       CMD_09   LDY #REA_PT         ;Set read address MID nibble
CA11   20 4E C9             JSR MIDNIB
CA14   4C 0B C9             JMP JUMP00

CA17   A0 03       CMD_0A   LDY #REA_PT+1       ;Set read address HI nibble
CA19   20 34 C9             JSR L_HNIB
CA1C   4C 0B C9             JMP JUMP00

CA1F   A0 02       CMD_0B   LDY #REA_PT         ;Read byte from MEMORY and write to requesting Hub channel
CA21   20 5F C9             JSR PREPRW
CA24   20 89 C9             JSR READXX
CA27   4C 0B C9             JMP JUMP00

CA2A   A0 02       CMD_0C   LDY #REA_PT         ;Read byte and increment read address
CA2C   20 5F C9             JSR PREPRW
CA2F   20 89 C9             JSR READXX
CA32   A0 02                LDY #REA_PT
CA34   20 77 C9             JSR INCADR
CA37   4C 0B C9             JMP JUMP00

CA3A   A5 00       CMD_0D   LDA HTIMER          ;Read HUB timer lo
CA3C   20 9E C9             JSR SRC99E
CA3F   4C 0B C9             JMP JUMP00

CA42   A5 01       CMD_0E   LDA HTIMER+1        ;Read HUB timer hi
CA44   20 9E C9             JSR SRC99E
CA47   4C 0B C9             JMP JUMP00

CA4A   A5 20       CMD_0F   LDA DATA            ;Start HUB timer
CA4C   C9 01                CMP #$01
CA4E   D0 06                BNE BRCA56
CA50   20 8F CA             JSR CLRDSP
CA53   4C 0B C9             JMP JUMP00
CA56   20 5C CA    BRCA56   JSR STHTMR
CA59   4C 0B C9             JMP JUMP00

                   ;Start HUB timer and enable interrupts from channel D (external copy)
CA5C   78          STHTMR   SEI
CA5D   A9 C0                LDA #$C0
CA5F   8D 0B A0             STA V1_ACR       ;V1 Timer 1 is free-running
CA62   A9 00                LDA #$00
CA64   8D 0B A8             STA V2_ACR       ;V2 Timer 1 is one-shot
CA67   A9 7F                LDA #$7F
CA69   8D 0E A0             STA V1_IER
CA6C   8D 0E A8             STA V2_IER
CA6F   A9 E0                LDA #$E0
CA71   8D 0E A0             STA V1_IER
CA74   A9 A0                LDA #$A0
CA76   8D 0E A8             STA V2_IER
CA79   A9 1A                LDA #$1A          ;Set V1 Timer 1 to $411A (16.667 mSecs, or 60 Hz)
CA7B   8D 04 A0             STA V1T1CL
CA7E   A9 41                LDA #$41
CA80   8D 05 A0             STA V1T1CL+1
CA83   A9 B6                LDA #$B6          ;Config. ACIA D: /64 (2400 baud) - 8 bits + 1 stop bit,
CA85   8D 80 40             STA HUB_DS        ;  enable receive AND transmit interrupts 
CA88   A9 FF                LDA #$FF
CA8A   85 2A                STA D_ACTV
CA8C   8D 81 40             STA HUB_D         ; Send "initiator" byte to other HUB to start copy process

CA8F   78         CLRDSP    SEI               ;Reset HUB timer and clear display
CA90   A9 00                LDA #$00
CA92   85 00                STA HTIMER
CA94   85 01                STA HTIMER+1
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
CB65   85 41                STA V1IFLG
CB67   8D 0D A0             STA V1_IFR     ; Clear all bits in V1 IFR
CB6A   10 3B                BPL GOJUMP
CB6C   29 40                AND #$40       ; Timeout of timer 1?
CB6E   F0 37                BEQ GOJUMP
CB70   E6 00                INC HTIMER     ; Yes: increment Hub timer count
CB72   D0 02                BNE BRCB76
CB74   E6 01                INC HTIMER+1
CB76   20 14 CC   BRCB76    JSR SCAN_D
CB79   4C A7 CB             JMP GOJUMP

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
CB8E   69 10                ADC #$10           ;Check to see if we're not keeping up with incoming
CB90   C5 3B                CMP OU_BUF
CB92   D0 12                BNE BRCBA6         ; Everything's ok -- keep going
CB94   A9 55                LDA #$55           ;We're falling behind against incoming data:
CB96   8D 10 40             STA HUB_AS         ; temporarily disable ACIA A,B and C read interrupts
CB99   8D 20 40             STA HUB_BS
CB9C   8D 40 40             STA HUB_CS
CB9F   A9 02                LDA #$02           ;Keep 'em disabled for 2 main loops
CBA1   85 3D                STA IN_BLOC
CBA3   20 72 89             JSR BEEP           ;Make a beep to signal overrun
CBA6   60         BRCBA6    RTS

CBA7   6C 2B 00   GOJUMP    JMP (BVECTR)		;This jumps to 'HUBCPY' just below

                  ;Read in copy of external HUB data page - and write out copy of local page to external HUB
CBAA   A5 41      HUBCPY    LDA V1IFLG        ;Check flags from last VIA #1 interrupt
CBAC   10 0D                BPL BRCBBB        ; no interrupt -- skip ahead
CBAE   29 20                AND #$20          ; V1 timer 2 interrupt?
CBB0   F0 09                BEQ BRCBBB        ; no -- skip ahead
CBB2   A9 00                LDA #$00          ; yes: end PAUSE of memory copy
CBB4   85 42                STA TPAUSE
CBB6   A9 B6                LDA #$B6          ;Config. ACIA D: x/64 (2400 baud) - 8 bits + 1 stop bit,
CBB8   8D 80 40             STA HUB_DS        ;  enable receive AND transmit interrupts 
CBBB   AD 0D A8   BRCBBB    LDA V2_IFR        ;Interrupt on V2? (HubCopy Timeout)
CBBE   10 07                BPL BRCBC7
CBC0   8D 0D A8             STA V2_IFR
CBC3   A9 00                LDA #$00          ;Yes: reset HUB-copy write pointer to beginning of page
CBC5   85 2E                STA HX_PTR
CBC7   AD 80 40   BRCBC7    LDA HUB_DS        ;Check if there's an incoming byte from remote HUB data
CBCA   85 3E                STA DSTATX        ;  (a.k.a channel D)
CBCC   10 18                BPL HCPYOU        ;None ready
CBCE   29 01                AND #$01
CBD0   F0 14                BEQ HCPYOU
CBD2   AD 81 40             LDA HUB_D         ;One *is* ready - read it in
CBD5   A4 2E                LDY HX_PTR
CBD7   99 00 04             STA HX_MEM,Y      ;Stash it...
CBDA   E6 2E                INC HX_PTR        ; and increment the pointer
CBDC   A9 D2                LDA #$D2          ;reset V2 Timer 2 (HubCopy Timeout) to $30D2 (12.498 mSec)
CBDE   8D 08 A8             STA V2T2CL
CBE1   A9 30                LDA #$30
CBE3   8D 09 A8             STA V2T2CL+1
CBE6   A5 3E      HCPYOU    LDA DSTATX        ;Get last ACIA D status
CBE8   10 92                BPL IRQOUT        ; If no interrrupt request, skip out
CBEA   29 02                AND #$02          ; If not 'Transmit Data Register Empty'
CBEC   F0 8E                BEQ IRQOUT        ;     -- skip out
CBEE   24 42                BIT TPAUSE           ; If in 'pause' state of mem. copy
CBF0   30 8A                BMI IRQOUT        ;     -- skip out
CBF2   A4 2D                LDY HCPY_F        ; Get current copy-from pointer
CBF4   E6 2D                INC HCPY_F        ; Increment copy-from pointer
CBF6   D0 13                BNE BRCC0B        ; If no page wrap, skip to writing byte out

CBF8   A9 5E                LDA #$5E          ;At page wrap: go into 21 mSec pause, for synchronization
CBFA   8D 08 A0             STA V1T2CL        ;Set VIA #1 Timer 2 to $515E (20.830 mSec)
CBFD   A9 51                LDA #$51
CBFF   8D 09 A0             STA V1T2CL+1
CC02   A9 FF                LDA #$FF
CC04   85 42                STA TPAUSE
CC06   A9 96                LDA #$96          ;Enable RECEIVE but NOT TRANSMIT interrupts on ACIA D
CC08   8D 80 40             STA HUB_DS

CC0B   B9 00 03   BRCC0B    LDA HL_MEM,Y
CC0E   8D 81 40             STA HUB_D         ;Write current 'copy' byte to ACIA D (remote HUB)
CC11   4C 7C CB             JMP IRQOUT

CC14   E6 38      SCAN_D    INC $38           ;Scan the display (? Not totally sure what else it does)
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


                  ;Reset ALL ACIAs
CC55   A9 03      RSTTRG    LDA #$03
CC57   8D 10 40             STA HUB_AS
CC5A   8D 20 40             STA HUB_BS
CC5D   8D 40 40             STA HUB_CS
CC60   8D 80 40             STA HUB_DS
CC63   6C 3F 00             JMP ($003F)

                  .END