------- FILE SYM_VOX.asm LEVEL 1 PASS 2
      1  0434 ????						;SYM memory player (scans parts of memory and 'plays' through PB7)
      2  0434 ????
      3  0434 ????				      processor	6502
      4  0200				   .	      =	$200
      5  0200
      6  0200							;---------  CONSTANTS
      7  0200		       60 00	   T2_VAL     =	$6000	;Timer 2 interval (tempo timer)
      8  0200
      9  0200							;---------  6532 (which includes system RAM)
     10  0200		       a6 40	   DSPBUF     =	$A640	;6532 System RAM: Display Buffer
     11  0200
     12  0200
     13  0200							;------ PORTS
     14  0200		       a8 06	   T1LL       =	$A806
     15  0200		       a8 05	   T1CH       =	$A805
     16  0200		       a8 0b	   ACR	      =	$A80B
     17  0200		       a8 0d	   IFR	      =	$A80D
     18  0200		       a8 0e	   IER	      =	$A80E
     19  0200		       a8 08	   T2LL       =	$A808
     20  0200		       a8 09	   T2CH       =	$A809
     21  0200
     22  0200							;------ VARIABLES
     23  0200		       00 00	   VARS       =	$00
     24  0200		       00 00	   ADNBS3     =	$00	;Four address nibbles for scanning address
     25  0200		       00 01	   ADNBS2     =	$01
     26  0200		       00 02	   ADNBS1     =	$02
     27  0200		       00 03	   ADNBS0     =	$03
     28  0200		       00 04	   RANGE      =	$04	;'Pitch' range (upper byte of timer)
     29  0200		       00 05	   TEMPO      =	$05
     30  0200		       00 06	   RMASK      =	$06
     31  0200
     32  0200		       00 07	   STPFLG     =	$07
     33  0200		       00 08	   RSTFLG     =	$08
     34  0200		       00 0a	   INDEX      =	$0A
     35  0200
     36  0200		       00 0b	   SCANAD     =	$0B	;16-bt memory-scan address
     37  0200							;$0C
     38  0200		       00 0d	   TCOUNT     =	$0D	;Timer interrupt count
     39  0200		       00 0e	   RIFLEN     =	$0E	;16-bit riff length
     40  0200							;$0F
     41  0200		       00 10	   SCORE      =	$10	;16-bit score pointer
     42  0200							;$11
     43  0200		       00 12	   SCRCTR     =	$12	;16-bit score counter
     44  0200							;$13
     45  0200
     46  0200							;------ MONITOR SUBROUTINES
     47  0200		       81 c4	   RESALL     =	$81C4
     48  0200		       81 88	   SAVER      =	$8188
     49  0200		       82 75	   ASCNIB     =	$8275
     50  0200		       88 af	   GETKEY     =	$88AF
     51  0200		       89 06	   SCAND      =	$8906
     52  0200		       89 23	   KEYQ       =	$8923
     53  0200		       89 2c	   LRNKEY     =	$892C
     54  0200		       89 72	   BEEP       =	$8972
     55  0200		       89 9b	   NOBEEP     =	$899B
     56  0200		       8b 86	   ACCESS     =	$8B86
     57  0200		       8c 29	   SEGSM1     =	$8C29	; SYM display
     58  0200
     59  0200		       ff f6	   USRBRK     =	$FFF6	;User break vector
     60  0200		       ff fe	   IRQVEC     =	$FFFE	;Interrupt vector
     61  0200
     62  0200
     63  0200		       78	   INIT       SEI
     64  0201		       20 86 8b 	      JSR	ACCESS
     65  0204		       a9 9c		      LDA	#<IRQSRV
     66  0206		       8d fe ff 	      STA	IRQVEC
     67  0209		       a9 03		      LDA	#>IRQSRV
     68  020b		       8d ff ff 	      STA	IRQVEC+1
     69  020e		       a9 c0		      LDA	#$C0	;Set timer 1: free-running, output on PB7
     70  0210		       8d 0b a8 	      STA	ACR	;    timer 2: one-shot (will trigger interrupt)
     71  0213		       a9 a0		      LDA	#$A0
     72  0215		       8d 0e a8 	      STA	IER
     73  0218		       a9 00		      LDA	#$00
     74  021a		       85 0c		      STA	SCANAD+1
     75  021c		       85 11		      STA	SCORE+1
     76  021e		       85 0b		      STA	SCANAD
     77  0220		       85 10		      STA	SCORE
     78  0222		       85 03		      STA	ADNBS0
     79  0224		       85 02		      STA	ADNBS1
     80  0226		       85 01		      STA	ADNBS2
     81  0228		       85 00		      STA	ADNBS3
     82  022a		       a9 07		      LDA	#7
     83  022c		       85 04		      STA	RANGE
     84  022e		       a9 0e		      LDA	#$0E
     85  0230		       85 05		      STA	TEMPO
     86  0232		       a9 40		      LDA	#$40
     87  0234		       85 06		      STA	RMASK	;Arbitrary rest tester: try $04
     88  0236		       a9 10		      LDA	#16
     89  0238		       85 0e		      STA	RIFLEN	;Initial riff length = 16
     90  023a		       85 12		      STA	SCRCTR
     91  023c		       a9 00		      LDA	#0
     92  023e		       85 0f		      STA	RIFLEN+1
     93  0240		       85 13		      STA	SCRCTR+1
     94  0242		       a9 00		      LDA	#0
     95  0244		       85 07		      STA	STPFLG
     96  0246		       85 08		      STA	RSTFLG
     97  0248		       a9 01		      LDA	#1
     98  024a		       85 0d		      STA	TCOUNT
     99  024c		       a9 00		      LDA	#<T2_VAL	;Set Timer 2 (tempo) value
    100  024e		       8d 08 a8 	      STA	T2LL
    101  0251		       a9 60		      LDA	#>T2_VAL
    102  0253		       8d 09 a8 	      STA	T2CH	;and start it
    103  0256		       58		      CLI
    104  0257
    105  0257							; MAIN LOOP: scan keyboard
    106  0257		       20 5d 02    MLOOP      JSR	GETCMD
    107  025a		       4c 57 02 	      JMP	MLOOP
    108  025d
    109  025d
    110  025d							;---------- Get pressed key (if any) and process it (scan display once)
    111  025d		       20 88 81    GETCMD     JSR	SAVER
    112  0260		       20 06 89 	      JSR	SCAND	;Scan display once
    113  0263		       20 23 89 	      JSR	KEYQ
    114  0266		       d0 03		      BNE	GTKY
    115  0268		       4c c4 81 	      JMP	RESALL	;No key down: restore regs. and return
    116  026b		       20 2c 89    GTKY       JSR	LRNKEY
    117  026e		       48		      PHA
    118  026f		       20 23 89    DEBNCE     JSR	KEYQ
    119  0272		       d0 fb		      BNE	DEBNCE	;Key still down? Wait longer.
    120  0274		       20 9b 89 	      JSR	NOBEEP
    121  0277		       20 23 89 	      JSR	KEYQ
    122  027a		       d0 f3		      BNE	DEBNCE
    123  027c		       68	   PARSE      PLA
    124  027d		       c9 0d		      CMP	#$0D	; < CR > = Currently does nothing
    125  027f		       d0 04		      BNE	NEXT1
    126  0281		       ea		      NOP
    127  0282		       4c c4 81 	      JMP	RESALL
    128  0285		       c9 2d	   NEXT1      CMP	#$2D	; < - > =	tempo
    129  0287		       d0 05		      BNE	NEXT2
    130  0289		       a2 05		      LDX	#TEMPO
    131  028b		       4c 32 03 	      JMP	SETIDX
    132  028e		       c9 3e	   NEXT2      CMP	#$3E	; < -> > =	pitch range
    133  0290		       d0 05		      BNE	NEXT3
    134  0292		       a2 04		      LDX	#RANGE
    135  0294		       4c 32 03 	      JMP	SETIDX
    136  0297		       c9 47	   NEXT3      CMP	#$47	; < GO > = ADNBS1
    137  0299		       d0 05		      BNE	NEXT4
    138  029b		       a2 02		      LDX	#ADNBS1
    139  029d		       4c 32 03 	      JMP	SETIDX
    140  02a0		       c9 52	   NEXT4      CMP	#$52	; < reg > =	ADNBS0
    141  02a2		       d0 05		      BNE	NEXT5
    142  02a4		       a2 03		      LDX	#ADNBS0
    143  02a6		       4c 32 03 	      JMP	SETIDX
    144  02a9		       c9 13	   NEXT5      CMP	#$13	;< L2 > = ADNBS3
    145  02ab		       d0 05		      BNE	NEXT6
    146  02ad		       a2 00		      LDX	#ADNBS3
    147  02af		       4c 32 03 	      JMP	SETIDX
    148  02b2		       c9 1e	   NEXT6      CMP	#$1E	;< S2 > = ADNBS2
    149  02b4		       d0 05		      BNE	NEXT7
    150  02b6		       a2 01		      LDX	#ADNBS2
    151  02b8		       4c 32 03 	      JMP	SETIDX
    152  02bb		       c9 4d	   NEXT7      CMP	#$4D	;< MEM > = RMASK
    153  02bd		       d0 05		      BNE	NEXT8
    154  02bf		       a2 06		      LDX	#RMASK	; (will require processing)
    155  02c1		       4c 32 03 	      JMP	SETIDX
    156  02c4		       c9 ff	   NEXT8      CMP	#$FF	;< SHIFT > = RIFLEN
    157  02c6		       d0 05		      BNE	PARAM
    158  02c8		       a2 0e		      LDX	#RIFLEN	; (will require processing)
    159  02ca		       4c 32 03 	      JMP	SETIDX
    160  02cd
    161  02cd		       20 75 82    PARAM      JSR	ASCNIB
    162  02d0		       a6 0a		      LDX	INDEX
    163  02d2		       e0 05		      CPX	#TEMPO	; Tempo?
    164  02d4		       d0 07		      BNE	P0
    165  02d6		       69 01		      ADC	#1
    166  02d8		       85 05		      STA	TEMPO
    167  02da		       4c c4 81 	      JMP	RESALL
    168  02dd
    169  02dd		       e0 06	   P0	      CPX	#RMASK	; Set rest mask?
    170  02df		       d0 16		      BNE	P1
    171  02e1		       aa		      TAX
    172  02e2		       f0 0e		      BEQ	STRM
    173  02e4		       c9 08		      CMP	#8	; If choice > 8, set mask to $FF (silence)
    174  02e6		       90 04		      BCC	SKX
    175  02e8		       a9 ff		      LDA	#$FF
    176  02ea		       d0 06		      BNE	STRM
    177  02ec		       a9 01	   SKX	      LDA	#1
    178  02ee		       0a	   SHFT       ASL
    179  02ef		       ca		      DEX
    180  02f0		       d0 fc		      BNE	SHFT
    181  02f2		       85 06	   STRM       STA	RMASK
    182  02f4		       4c c4 81 	      JMP	RESALL
    183  02f7
    184  02f7		       e0 0e	   P1	      CPX	#RIFLEN	; Shift key (set Riff length)
    185  02f9		       d0 19		      BNE	P2
    186  02fb		       0a		      ASL		;double the index value
    187  02fc		       aa		      TAX
    188  02fd		       bd 14 04 	      LDA	RFLTAB,X
    189  0300		       85 0e		      STA	RIFLEN
    190  0302		       bd 15 04 	      LDA	RFLTAB+1,X
    191  0305		       85 0f		      STA	RIFLEN+1
    192  0307		       78	   FORCE      SEI
    193  0308		       a9 00		      LDA	#0	; Force immediate riff reset
    194  030a		       85 12		      STA	SCRCTR
    195  030c		       a9 00		      LDA	#0
    196  030e		       85 13		      STA	SCRCTR+1
    197  0310		       58		      CLI
    198  0311		       4c c4 81 	      JMP	RESALL
    199  0314
    200  0314		       95 00	   P2	      STA	VARS,X
    201  0316		       e0 04		      CPX	#ADNBS0+1	;Address change?
    202  0318		       b0 18		      BCS	SETIDX
    203  031a
    204  031a		       78		      SEI
    205  031b		       a5 02		      LDA	ADNBS1	; (re)build memory-scan pointer
    206  031d		       0a		      ASL
    207  031e		       0a		      ASL
    208  031f		       0a		      ASL
    209  0320		       0a		      ASL
    210  0321		       65 03		      ADC	ADNBS0
    211  0323		       85 0b		      STA	SCANAD
    212  0325		       a5 00		      LDA	ADNBS3
    213  0327		       0a		      ASL
    214  0328		       0a		      ASL
    215  0329		       0a		      ASL
    216  032a		       0a		      ASL
    217  032b		       65 01		      ADC	ADNBS2
    218  032d		       85 0c		      STA	SCANAD+1
    219  032f		       4c 07 03 	      JMP	FORCE	; Force immediate riff reset
    220  0332
    221  0332		       86 0a	   SETIDX     STX	INDEX
    222  0334		       4c c4 81 	      JMP	RESALL
    223  0337
    224  0337
    225  0337							;---------- Display byte in Acc. on 2 lowest display positions
    226  0337		       48	   DSPBYT     PHA
    227  0338		       29 0f		      AND	#$0F
    228  033a		       a8		      TAY
    229  033b		       b9 29 8c 	      LDA	SEGSM1,Y
    230  033e		       8d 45 a6 	      STA	DSPBUF+5
    231  0341		       68		      PLA
    232  0342		       48		      PHA
    233  0343		       4a		      LSR
    234  0344		       4a		      LSR
    235  0345		       4a		      LSR
    236  0346		       4a		      LSR
    237  0347		       a8		      TAY
    238  0348		       b9 29 8c 	      LDA	SEGSM1,Y
    239  034b		       8d 44 a6 	      STA	DSPBUF+4
    240  034e		       68		      PLA
    241  034f		       60		      RTS
    242  0350
    243  0350
    244  0350							;---------- Display memory pointer
    245  0350		       a5 11	   DSPPTR     LDA	SCORE+1
    246  0352		       48		      PHA
    247  0353		       29 f0		      AND	#$F0
    248  0355		       4a		      LSR
    249  0356		       4a		      LSR
    250  0357		       4a		      LSR
    251  0358		       4a		      LSR
    252  0359		       a8		      TAY
    253  035a		       b9 29 8c 	      LDA	SEGSM1,Y
    254  035d		       8d 40 a6 	      STA	DSPBUF
    255  0360		       68		      PLA
    256  0361		       29 0f		      AND	#$0F
    257  0363		       a8		      TAY
    258  0364		       b9 29 8c 	      LDA	SEGSM1,Y
    259  0367		       8d 41 a6 	      STA	DSPBUF+1
    260  036a
    261  036a		       a5 10		      LDA	SCORE
    262  036c		       48		      PHA
    263  036d		       29 f0		      AND	#$F0
    264  036f		       4a		      LSR
    265  0370		       4a		      LSR
    266  0371		       4a		      LSR
    267  0372		       4a		      LSR
    268  0373		       a8		      TAY
    269  0374		       b9 29 8c 	      LDA	SEGSM1,Y
    270  0377		       8d 42 a6 	      STA	DSPBUF+2
    271  037a		       68		      PLA
    272  037b		       29 0f		      AND	#$0F
    273  037d		       a8		      TAY
    274  037e		       b9 29 8c 	      LDA	SEGSM1,Y
    275  0381		       09 80		      ORA	#$80	;light up decimal point
    276  0383		       8d 43 a6 	      STA	DSPBUF+3
    277  0386		       60		      RTS
    278  0387
    279  0387
    280  0387							;---------- Play one note
    281  0387		       8d 06 a8    BOP	      STA	T1LL	;Store low byte of freq. in timer lo latch
    282  038a		       a5 08		      LDA	RSTFLG
    283  038c		       f0 08		      BEQ	GOON
    284  038e		       a9 00		      LDA	#0
    285  0390		       8d 05 a8 	      STA	T1CH
    286  0393		       85 08		      STA	RSTFLG
    287  0395		       60		      RTS
    288  0396		       a5 04	   GOON       LDA	RANGE	;store upper byte of timer ('pitch' range), which
    289  0398		       8d 05 a8 	      STA	T1CH	;triggers the free-running counter output on PB7
    290  039b		       60		      RTS
    291  039c
    292  039c
    293  039c							;---------- Interrupt service routine -- called by timeout of TIMER 2 (tempo timer)
    294  039c		       48	   IRQSRV     PHA
    295  039d		       8a		      TXA
    296  039e		       48		      PHA
    297  039f		       98		      TYA
    298  03a0		       48		      PHA
    299  03a1		       ba		      TSX
    300  03a2		       bd 04 01 	      LDA	$0104,X
    301  03a5		       29 10		      AND	#$10
    302  03a7		       f0 08		      BEQ	NOBRK
    303  03a9		       68		      PLA
    304  03aa		       a8		      TAY
    305  03ab		       68		      PLA
    306  03ac		       aa		      TAX
    307  03ad		       68		      PLA
    308  03ae		       6c f6 ff 	      JMP	(USRBRK)
    309  03b1
    310  03b1		       ad 0d a8    NOBRK      LDA	IFR
    311  03b4		       8d 0d a8 	      STA	IFR	;Clear interrupt
    312  03b7		       a9 00		      LDA	#<T2_VAL	;Reset (one-shot) Timer 2
    313  03b9		       8d 08 a8 	      STA	T2LL
    314  03bc		       a9 60		      LDA	#>T2_VAL
    315  03be		       8d 09 a8 	      STA	T2CH	;and re-start it
    316  03c1
    317  03c1		       c6 0d		      DEC	TCOUNT
    318  03c3		       d0 49		      BNE	IRQOUT
    319  03c5
    320  03c5		       a5 05		      LDA	TEMPO	;Reset the tempo value
    321  03c7		       85 0d		      STA	TCOUNT
    322  03c9
    323  03c9		       a5 12		      LDA	SCRCTR	;Score counter at zero?
    324  03cb		       d0 14		      BNE	PLAY
    325  03cd		       a5 13		      LDA	SCRCTR+1
    326  03cf		       d0 10		      BNE	PLAY
    327  03d1		       a5 0b		      LDA	SCANAD	;Yes: end of riff: loop back to start
    328  03d3		       85 10		      STA	SCORE
    329  03d5		       a5 0c		      LDA	SCANAD+1
    330  03d7		       85 11		      STA	SCORE+1
    331  03d9		       a5 0e		      LDA	RIFLEN
    332  03db		       85 12		      STA	SCRCTR
    333  03dd		       a5 0f		      LDA	RIFLEN+1
    334  03df		       85 13		      STA	SCRCTR+1
    335  03e1
    336  03e1		       20 50 03    PLAY       JSR	DSPPTR
    337  03e4		       a0 00		      LDY	#0
    338  03e6		       b1 10		      LDA	(SCORE),Y	;Get next 'pitch'
    339  03e8		       20 37 03 	      JSR	DSPBYT	;Display it
    340  03eb		       a4 06		      LDY	RMASK
    341  03ed		       c0 ff		      CPY	#$FF	;Silence?
    342  03ef		       f0 04		      BEQ	SHHH
    343  03f1		       24 06		      BIT	RMASK	;Arbitrary rest test
    344  03f3		       f0 06		      BEQ	CONTIN
    345  03f5		       a9 01	   SHHH       LDA	#1
    346  03f7		       85 08		      STA	RSTFLG
    347  03f9		       a9 00		      LDA	#0
    348  03fb		       20 87 03    CONTIN     JSR	BOP
    349  03fe		       e6 10		      INC	SCORE
    350  0400		       d0 02		      BNE	DECCTR
    351  0402		       e6 11		      INC	SCORE+1
    352  0404
    353  0404		       c6 12	   DECCTR     DEC	SCRCTR
    354  0406		       a5 12		      LDA	SCRCTR
    355  0408		       c9 ff		      CMP	#$FF
    356  040a		       d0 02		      BNE	IRQOUT
    357  040c		       c6 13		      DEC	SCRCTR+1
    358  040e
    359  040e		       68	   IRQOUT     PLA
    360  040f		       a8		      TAY
    361  0410		       68		      PLA
    362  0411		       aa		      TAX
    363  0412		       68		      PLA
    364  0413		       40		      RTI
    365  0414
    366  0414				   -------------		;Riff length table
    367  0414		       02 00	   RFLTAB     .WORD.w	2
    368  0416		       03 00		      .WORD.w	3
    369  0418		       04 00		      .WORD.w	4
    370  041a		       05 00		      .WORD.w	5
    371  041c		       07 00		      .WORD.w	7
    372  041e		       08 00		      .WORD.w	8
    373  0420		       0c 00		      .WORD.w	12
    374  0422		       10 00		      .WORD.w	16
    375  0424		       20 00		      .WORD.w	32
    376  0426		       40 00		      .WORD.w	64
    377  0428		       80 00		      .WORD.w	128
    378  042a		       00 01		      .WORD.w	256
    379  042c		       00 02		      .WORD.w	512
    380  042e		       00 08		      .WORD.w	2048
    381  0430		       00 10		      .WORD.w	4096
    382  0432		       00 20		      .WORD.w	8192
    383  0434
    384  0434					      .END
