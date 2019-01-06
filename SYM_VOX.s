------- FILE SYM_VOX.asm LEVEL 1 PASS 2
      1  0428 ????						;SYM memory player (scans parts of memory and 'plays' through PB7)
      2  0428 ????
      3  0428 ????				      processor	6502
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
     24  0200		       00 00	   TEMPO      =	$00
     25  0200		       00 01	   ADNBS3     =	$01	;Four address nibbles for scanning address
     26  0200		       00 02	   ADNBS2     =	$02
     27  0200		       00 03	   ADNBS1     =	$03
     28  0200		       00 04	   ADNBS0     =	$04
     29  0200		       00 05	   RANGE      =	$05	;'Pitch' range (upper byte of timer)
     30  0200		       00 06	   STPFLG     =	$06
     31  0200		       00 07	   RSTFLG     =	$07
     32  0200
     33  0200		       00 09	   RMASK      =	$09
     34  0200		       00 0a	   INDEX      =	$0A
     35  0200		       00 0b	   SCANAD     =	$0B	;16-bt memory-scan address
     36  0200							;$0C
     37  0200		       00 0d	   TCOUNT     =	$0D	;Timer interrupt count
     38  0200		       00 0e	   RIFLEN     =	$0E	;16-bit riff length
     39  0200							;$0F
     40  0200		       00 10	   SCORE      =	$10	;16-bit score pointer
     41  0200							;$11
     42  0200		       00 12	   SCRCTR     =	$12	;16-bit score counter
     43  0200							;$13
     44  0200
     45  0200							;------ MONITOR SUBROUTINES
     46  0200		       81 c4	   RESALL     =	$81C4
     47  0200		       81 88	   SAVER      =	$8188
     48  0200		       82 75	   ASCNIB     =	$8275
     49  0200		       88 af	   GETKEY     =	$88AF
     50  0200		       89 06	   SCAND      =	$8906
     51  0200		       89 23	   KEYQ       =	$8923
     52  0200		       89 2c	   LRNKEY     =	$892C
     53  0200		       89 72	   BEEP       =	$8972
     54  0200		       89 9b	   NOBEEP     =	$899B
     55  0200		       8b 86	   ACCESS     =	$8B86
     56  0200		       8c 29	   SEGSM1     =	$8C29	; SYM display
     57  0200
     58  0200		       ff f6	   USRBRK     =	$FFF6	;User break vector
     59  0200		       ff fe	   IRQVEC     =	$FFFE	;Interrupt vector
     60  0200
     61  0200
     62  0200		       78	   INIT       SEI
     63  0201		       20 86 8b 	      JSR	ACCESS
     64  0204		       a9 96		      LDA	#<IRQSRV
     65  0206		       8d fe ff 	      STA	IRQVEC
     66  0209		       a9 03		      LDA	#>IRQSRV
     67  020b		       8d ff ff 	      STA	IRQVEC+1
     68  020e		       a9 c0		      LDA	#$C0	;Set timer 1: free-running, output on PB7
     69  0210		       8d 0b a8 	      STA	ACR	;    timer 2: one-shot (will trigger interrupt)
     70  0213		       a9 a0		      LDA	#$A0
     71  0215		       8d 0e a8 	      STA	IER
     72  0218		       a9 00		      LDA	#$00
     73  021a		       85 0c		      STA	SCANAD+1
     74  021c		       85 11		      STA	SCORE+1
     75  021e		       85 0b		      STA	SCANAD
     76  0220		       85 10		      STA	SCORE
     77  0222		       85 04		      STA	ADNBS0
     78  0224		       85 03		      STA	ADNBS1
     79  0226		       85 02		      STA	ADNBS2
     80  0228		       85 01		      STA	ADNBS3
     81  022a		       a9 07		      LDA	#7
     82  022c		       85 05		      STA	RANGE
     83  022e		       a9 0e		      LDA	#$0E
     84  0230		       85 00		      STA	TEMPO
     85  0232		       a9 40		      LDA	#$40
     86  0234		       85 09		      STA	RMASK	;Arbitrary rest tester: try $04
     87  0236		       a9 10		      LDA	#16
     88  0238		       85 0e		      STA	RIFLEN	;Initial riff length = 16
     89  023a		       85 12		      STA	SCRCTR
     90  023c		       a9 00		      LDA	#0
     91  023e		       85 0f		      STA	RIFLEN+1
     92  0240		       85 13		      STA	SCRCTR+1
     93  0242		       a9 00		      LDA	#0
     94  0244		       85 06		      STA	STPFLG
     95  0246		       85 07		      STA	RSTFLG
     96  0248		       a9 01		      LDA	#1
     97  024a		       85 0d		      STA	TCOUNT
     98  024c		       a9 00		      LDA	#<T2_VAL	;Set Timer 2 (tempo) value
     99  024e		       8d 08 a8 	      STA	T2LL
    100  0251		       a9 60		      LDA	#>T2_VAL
    101  0253		       8d 09 a8 	      STA	T2CH	;and start it
    102  0256		       58		      CLI
    103  0257
    104  0257							; MAIN LOOP: scan keyboard
    105  0257		       20 5d 02    MLOOP      JSR	GETCMD
    106  025a		       4c 57 02 	      JMP	MLOOP
    107  025d
    108  025d
    109  025d							;---------- Get pressed key (if any) and process it (scan display once)
    110  025d		       20 88 81    GETCMD     JSR	SAVER
    111  0260		       20 06 89 	      JSR	SCAND	;Scan display once
    112  0263		       20 23 89 	      JSR	KEYQ
    113  0266		       d0 03		      BNE	GTKY
    114  0268		       4c c4 81 	      JMP	RESALL	;No key down: restore regs. and return
    115  026b		       20 2c 89    GTKY       JSR	LRNKEY
    116  026e		       48		      PHA
    117  026f		       20 23 89    DEBNCE     JSR	KEYQ
    118  0272		       d0 fb		      BNE	DEBNCE	;Key still down? Wait longer.
    119  0274		       20 9b 89 	      JSR	NOBEEP
    120  0277		       20 23 89 	      JSR	KEYQ
    121  027a		       d0 f3		      BNE	DEBNCE
    122  027c		       68	   PARSE      PLA
    123  027d		       c9 0d		      CMP	#$0D	; < CR > = HALT
    124  027f		       d0 05		      BNE	NEXT1
    125  0281		       85 06		      STA	STPFLG
    126  0283		       4c c4 81 	      JMP	RESALL
    127  0286		       c9 2d	   NEXT1      CMP	#$2D	; < - > =	tempo
    128  0288		       d0 05		      BNE	NEXT2
    129  028a		       a2 00		      LDX	#TEMPO
    130  028c		       4c 2c 03 	      JMP	SETIDX
    131  028f		       c9 3e	   NEXT2      CMP	#$3E	; < -> > =	pitch range
    132  0291		       d0 05		      BNE	NEXT3
    133  0293		       a2 05		      LDX	#RANGE
    134  0295		       4c 2c 03 	      JMP	SETIDX
    135  0298		       c9 47	   NEXT3      CMP	#$47	; < GO > = ADNBS1
    136  029a		       d0 05		      BNE	NEXT4
    137  029c		       a2 03		      LDX	#ADNBS1
    138  029e		       4c 2c 03 	      JMP	SETIDX
    139  02a1		       c9 52	   NEXT4      CMP	#$52	; < reg > =	ADNBS0
    140  02a3		       d0 05		      BNE	NEXT5
    141  02a5		       a2 04		      LDX	#ADNBS0
    142  02a7		       4c 2c 03 	      JMP	SETIDX
    143  02aa		       c9 13	   NEXT5      CMP	#$13	;< L2 > = ADNBS3
    144  02ac		       d0 05		      BNE	NEXT6
    145  02ae		       a2 01		      LDX	#ADNBS3
    146  02b0		       4c 2c 03 	      JMP	SETIDX
    147  02b3		       c9 1e	   NEXT6      CMP	#$1E	;< S2 > = ADNBS2
    148  02b5		       d0 05		      BNE	NEXT7
    149  02b7		       a2 02		      LDX	#ADNBS2
    150  02b9		       4c 2c 03 	      JMP	SETIDX
    151  02bc		       c9 4d	   NEXT7      CMP	#$4D	;< MEM > = RMASK
    152  02be		       d0 05		      BNE	NEXT8
    153  02c0		       a2 09		      LDX	#RMASK	; (will require processing)
    154  02c2		       4c 2c 03 	      JMP	SETIDX
    155  02c5		       c9 ff	   NEXT8      CMP	#$FF	;< SHIFT > = RIFLEN
    156  02c7		       d0 05		      BNE	PARAM
    157  02c9		       a2 0e		      LDX	#RIFLEN	; (will require processing)
    158  02cb		       4c 2c 03 	      JMP	SETIDX
    159  02ce
    160  02ce		       20 75 82    PARAM      JSR	ASCNIB
    161  02d1		       a6 0a		      LDX	INDEX
    162  02d3		       e0 00		      CPX	#TEMPO	; Tempo?
    163  02d5		       d0 07		      BNE	P0
    164  02d7		       69 01		      ADC	#1
    165  02d9		       85 00		      STA	TEMPO
    166  02db		       4c c4 81 	      JMP	RESALL
    167  02de
    168  02de		       e0 09	   P0	      CPX	#RMASK	; Set rest mask?
    169  02e0		       d0 17		      BNE	P1
    170  02e2		       aa		      TAX
    171  02e3		       f0 0f		      BEQ	STRM
    172  02e5		       18		      CLC
    173  02e6		       c9 08		      CMP	#8	; If choice > 8, set mask to $FF (silence)
    174  02e8		       90 04		      BCC	SKX
    175  02ea		       a9 ff		      LDA	#$FF
    176  02ec		       d0 06		      BNE	STRM
    177  02ee		       a9 01	   SKX	      LDA	#1
    178  02f0		       0a	   SHFT       ASL
    179  02f1		       ca		      DEX
    180  02f2		       d0 fc		      BNE	SHFT
    181  02f4		       85 09	   STRM       STA	RMASK
    182  02f6		       4c c4 81 	      JMP	RESALL
    183  02f9
    184  02f9		       e0 0e	   P1	      CPX	#RIFLEN	; Shift key (set Riff length)
    185  02fb		       d0 19		      BNE	P2
    186  02fd		       0a		      ASL		;double the index value
    187  02fe		       aa		      TAX
    188  02ff		       bd 08 04 	      LDA	RFLTAB,X
    189  0302		       85 0e		      STA	RIFLEN
    190  0304		       bd 09 04 	      LDA	RFLTAB+1,X
    191  0307		       85 0f		      STA	RIFLEN+1
    192  0309		       78		      SEI
    193  030a		       a9 00		      LDA	#0	; Force immediate riff reset
    194  030c		       85 12		      STA	SCRCTR
    195  030e		       a9 00		      LDA	#0
    196  0310		       85 13		      STA	SCRCTR+1
    197  0312		       58		      CLI
    198  0313		       4c c4 81 	      JMP	RESALL
    199  0316
    200  0316		       95 00	   P2	      STA	VARS,X
    201  0318		       a5 03		      LDA	ADNBS1	; (re)build memory-scan pointer
    202  031a		       0a		      ASL
    203  031b		       0a		      ASL
    204  031c		       0a		      ASL
    205  031d		       0a		      ASL
    206  031e		       65 04		      ADC	ADNBS0
    207  0320		       85 0b		      STA	SCANAD
    208  0322		       a5 01		      LDA	ADNBS3
    209  0324		       0a		      ASL
    210  0325		       0a		      ASL
    211  0326		       0a		      ASL
    212  0327		       0a		      ASL
    213  0328		       65 02		      ADC	ADNBS2
    214  032a		       85 0c		      STA	SCANAD+1
    215  032c
    216  032c		       86 0a	   SETIDX     STX	INDEX
    217  032e		       4c c4 81 	      JMP	RESALL
    218  0331
    219  0331
    220  0331							;---------- Display byte in Acc. on 2 lowest display positions
    221  0331		       48	   DSPBYT     PHA
    222  0332		       29 0f		      AND	#$0F
    223  0334		       a8		      TAY
    224  0335		       b9 29 8c 	      LDA	SEGSM1,Y
    225  0338		       8d 45 a6 	      STA	DSPBUF+5
    226  033b		       68		      PLA
    227  033c		       48		      PHA
    228  033d		       4a		      LSR
    229  033e		       4a		      LSR
    230  033f		       4a		      LSR
    231  0340		       4a		      LSR
    232  0341		       a8		      TAY
    233  0342		       b9 29 8c 	      LDA	SEGSM1,Y
    234  0345		       8d 44 a6 	      STA	DSPBUF+4
    235  0348		       68		      PLA
    236  0349		       60		      RTS
    237  034a
    238  034a
    239  034a							;---------- Display memory pointer
    240  034a		       a5 11	   DSPPTR     LDA	SCORE+1
    241  034c		       29 f0		      AND	#$F0
    242  034e		       4a		      LSR
    243  034f		       4a		      LSR
    244  0350		       4a		      LSR
    245  0351		       4a		      LSR
    246  0352		       a8		      TAY
    247  0353		       b9 29 8c 	      LDA	SEGSM1,Y
    248  0356		       8d 40 a6 	      STA	DSPBUF
    249  0359		       a5 11		      LDA	SCORE+1
    250  035b		       29 f0		      AND	#$F0
    251  035d		       a8		      TAY
    252  035e		       b9 29 8c 	      LDA	SEGSM1,Y
    253  0361		       8d 41 a6 	      STA	DSPBUF+1
    254  0364
    255  0364		       a5 10		      LDA	SCORE
    256  0366		       29 f0		      AND	#$F0
    257  0368		       4a		      LSR
    258  0369		       4a		      LSR
    259  036a		       4a		      LSR
    260  036b		       4a		      LSR
    261  036c		       a8		      TAY
    262  036d		       b9 29 8c 	      LDA	SEGSM1,Y
    263  0370		       8d 42 a6 	      STA	DSPBUF+2
    264  0373		       a5 10		      LDA	SCORE
    265  0375		       29 0f		      AND	#$0F
    266  0377		       a8		      TAY
    267  0378		       b9 29 8c 	      LDA	SEGSM1,Y
    268  037b		       09 80		      ORA	#$80	;light up decimal point
    269  037d		       8d 43 a6 	      STA	DSPBUF+3
    270  0380		       60		      RTS
    271  0381
    272  0381
    273  0381							;---------- Play one note
    274  0381		       8d 06 a8    BOP	      STA	T1LL	;Store low byte of freq. in timer lo latch
    275  0384		       a5 07		      LDA	RSTFLG
    276  0386		       f0 08		      BEQ	GOON
    277  0388		       a9 00		      LDA	#0
    278  038a		       8d 05 a8 	      STA	T1CH
    279  038d		       85 07		      STA	RSTFLG
    280  038f		       60		      RTS
    281  0390		       a5 05	   GOON       LDA	RANGE	;store upper byte of timer ('pitch' range), which
    282  0392		       8d 05 a8 	      STA	T1CH	;triggers the free-running counter output on PB7
    283  0395		       60		      RTS
    284  0396
    285  0396
    286  0396							;---------- Interrupt service routine -- called by timeout of TIMER 2 (tempo timer)
    287  0396		       48	   IRQSRV     PHA
    288  0397		       8a		      TXA
    289  0398		       48		      PHA
    290  0399		       98		      TYA
    291  039a		       48		      PHA
    292  039b		       ba		      TSX
    293  039c		       bd 04 01 	      LDA	$0104,X
    294  039f		       29 10		      AND	#$10
    295  03a1		       f0 08		      BEQ	NOBRK
    296  03a3		       68		      PLA
    297  03a4		       a8		      TAY
    298  03a5		       68		      PLA
    299  03a6		       aa		      TAX
    300  03a7		       68		      PLA
    301  03a8		       6c f6 ff 	      JMP	(USRBRK)
    302  03ab
    303  03ab		       ad 0d a8    NOBRK      LDA	IFR
    304  03ae		       8d 0d a8 	      STA	IFR	;Clear interrupt
    305  03b1		       a9 00		      LDA	#<T2_VAL	;Reset (one-shot) Timer 2
    306  03b3		       8d 08 a8 	      STA	T2LL
    307  03b6		       a9 60		      LDA	#>T2_VAL
    308  03b8		       8d 09 a8 	      STA	T2CH	;and re-start it
    309  03bb
    310  03bb		       c6 0d		      DEC	TCOUNT
    311  03bd		       d0 43		      BNE	IRQOUT
    312  03bf
    313  03bf		       a5 00		      LDA	TEMPO	;Reset the tempo value
    314  03c1		       85 0d		      STA	TCOUNT
    315  03c3
    316  03c3		       a5 12		      LDA	SCRCTR	;Score counter at zero?
    317  03c5		       d0 14		      BNE	PLAY
    318  03c7		       a5 13		      LDA	SCRCTR+1
    319  03c9		       d0 10		      BNE	PLAY
    320  03cb		       a5 0b		      LDA	SCANAD	;Yes: end of riff: loop back to start
    321  03cd		       85 10		      STA	SCORE
    322  03cf		       a5 0c		      LDA	SCANAD+1
    323  03d1		       85 11		      STA	SCORE+1
    324  03d3		       a5 0e		      LDA	RIFLEN
    325  03d5		       85 12		      STA	SCRCTR
    326  03d7		       a5 0f		      LDA	RIFLEN+1
    327  03d9		       85 13		      STA	SCRCTR+1
    328  03db
    329  03db		       20 4a 03    PLAY       JSR	DSPPTR
    330  03de		       a0 00		      LDY	#0
    331  03e0		       b1 10		      LDA	(SCORE),Y	;Get next 'pitch'
    332  03e2		       20 31 03 	      JSR	DSPBYT	;Display it
    333  03e5		       24 09		      BIT	RMASK	;Arbitrary rest test
    334  03e7		       f0 06		      BEQ	CONTIN
    335  03e9		       a9 01		      LDA	#1
    336  03eb		       85 07		      STA	RSTFLG
    337  03ed		       a9 00		      LDA	#0
    338  03ef		       20 81 03    CONTIN     JSR	BOP
    339  03f2		       e6 10		      INC	SCORE
    340  03f4		       d0 02		      BNE	DECCTR
    341  03f6		       e6 11		      INC	SCORE+1
    342  03f8
    343  03f8		       c6 12	   DECCTR     DEC	SCRCTR
    344  03fa		       a5 12		      LDA	SCRCTR
    345  03fc		       c9 ff		      CMP	#$FF
    346  03fe		       d0 02		      BNE	IRQOUT
    347  0400		       c6 13		      DEC	SCRCTR+1
    348  0402
    349  0402		       68	   IRQOUT     PLA
    350  0403		       a8		      TAY
    351  0404		       68		      PLA
    352  0405		       aa		      TAX
    353  0406		       68		      PLA
    354  0407		       40		      RTI
    355  0408
    356  0408		       00 00	   RFLTAB     .WORD.w	0	;Riff length table
    357  040a		       01 00		      .WORD.w	1
    358  040c		       02 00		      .WORD.w	2
    359  040e		       03 00		      .WORD.w	3
    360  0410		       04 00		      .WORD.w	4
    361  0412		       05 00		      .WORD.w	5
    362  0414		       07 00		      .WORD.w	7
    363  0416		       08 00		      .WORD.w	8
    364  0418		       0c 00		      .WORD.w	12
    365  041a		       10 00		      .WORD.w	16
    366  041c		       18 00		      .WORD.w	24
    367  041e		       20 00		      .WORD.w	32
    368  0420		       40 00		      .WORD.w	64
    369  0422		       80 00		      .WORD.w	128
    370  0424		       00 02		      .WORD.w	512
    371  0426		       00 20		      .WORD.w	8192
    372  0428
    373  0428					      .END
