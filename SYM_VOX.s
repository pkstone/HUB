------- FILE SYM_VOX.asm LEVEL 1 PASS 2
      1  03ca ????						;SYM memory player (scans parts of memory and 'plays' through PB7)
      2  03ca ????
      3  03ca ????
      4  03ca ????				      processor	6502
      5  0200				   .	      =	$200
      6  0200
      7  0200							;---------  CONSTANTS
      8  0200		       60 00	   T2_VAL     =	$6000	;Timer 2 interval (tempo timer)
      9  0200
     10  0200							;---------  6532 (which includes system RAM)
     11  0200		       a6 40	   DSPBUF     =	$A640	;6532 System RAM: Display Buffer
     12  0200
     13  0200
     14  0200							;------ PORTS
     15  0200		       a8 06	   T1LL       =	$A806
     16  0200		       a8 05	   T1CH       =	$A805
     17  0200		       a8 0b	   ACR	      =	$A80B
     18  0200		       a8 0d	   IFR	      =	$A80D
     19  0200		       a8 0e	   IER	      =	$A80E
     20  0200		       a8 08	   T2LL       =	$A808
     21  0200		       a8 09	   T2CH       =	$A809
     22  0200
     23  0200							;------ VARIABLES
     24  0200		       00 00	   VARS       =	$00
     25  0200		       00 00	   TEMPO      =	$00
     26  0200		       00 01	   PRNIBS     =	$01	;Four address nibbles:
     27  0200		       00 01	   PNIBN3     =	$01	;  for memory read pointer
     28  0200		       00 02	   PNIBN2     =	$02
     29  0200		       00 03	   PNIBN1     =	$03
     30  0200		       00 04	   PNIBN0     =	$04
     31  0200		       00 05	   RANGE      =	$05
     32  0200		       00 06	   STPFLG     =	$06
     33  0200		       00 07	   RSTFLG     =	$07
     34  0200		       00 08	   YPTR       =	$08
     35  0200		       00 09	   RMASK      =	$09
     36  0200		       00 0a	   INDEX      =	$0A
     37  0200		       00 0b	   SCANAD     =	$0B	;16-bt memory-scan address
     38  0200							;$0C
     39  0200		       00 0d	   TCOUNT     =	$0D	;Timer interrupt count
     40  0200		       00 0e	   RIFLEN     =	$0E	;16-bit riff length
     41  0200							;$0F
     42  0200		       00 10	   SCORE      =	$10	;16-bit score pointer
     43  0200							;$11
     44  0200		       00 12	   SCRCTR     =	$12	;16-bit score counter
     45  0200							;$13
     46  0200
     47  0200							;------ MONITOR SUBROUTINES
     48  0200		       81 c4	   RESALL     =	$81C4
     49  0200		       81 88	   SAVER      =	$8188
     50  0200		       82 75	   ASCNIB     =	$8275
     51  0200		       88 af	   GETKEY     =	$88AF
     52  0200		       89 06	   SCAND      =	$8906
     53  0200		       89 23	   KEYQ       =	$8923
     54  0200		       89 2c	   LRNKEY     =	$892C
     55  0200		       89 72	   BEEP       =	$8972
     56  0200		       89 9b	   NOBEEP     =	$899B
     57  0200		       8b 86	   ACCESS     =	$8B86
     58  0200		       8c 29	   SEGSM1     =	$8C29	; SYM display
     59  0200
     60  0200		       ff f6	   USRBRK     =	$FFF6	;User break vector
     61  0200		       ff fe	   IRQVEC     =	$FFFE	;Interrupt vector
     62  0200
     63  0200
     64  0200		       78	   INIT       SEI
     65  0201		       20 86 8b 	      JSR	ACCESS
     66  0204		       20 30 03 	      JSR	SETDSP
     67  0207		       a9 4a		      LDA	#<IRQSRV
     68  0209		       8d fe ff 	      STA	IRQVEC
     69  020c		       a9 03		      LDA	#>IRQSRV
     70  020e		       8d ff ff 	      STA	IRQVEC+1
     71  0211		       a9 c0		      LDA	#$C0	;Set timer 1: free-running, output on PB7
     72  0213		       8d 0b a8 	      STA	ACR	;    timer 2: one-shot (will trigger interrupt)
     73  0216		       a9 a0		      LDA	#$A0
     74  0218		       8d 0e a8 	      STA	IER
     75  021b		       a9 c8		      LDA	#$C8
     76  021d		       85 0c		      STA	SCANAD+1
     77  021f		       85 11		      STA	SCORE+1
     78  0221		       a9 00		      LDA	#$00
     79  0223		       85 0b		      STA	SCANAD
     80  0225		       85 10		      STA	SCORE
     81  0227		       a9 07		      LDA	#7
     82  0229		       85 05		      STA	RANGE
     83  022b		       a9 0e		      LDA	#$0E
     84  022d		       85 00		      STA	TEMPO
     85  022f		       a9 40		      LDA	#$40
     86  0231		       85 09		      STA	RMASK	;Arbitrary rest tester: try $04
     87  0233		       a9 10		      LDA	#16
     88  0235		       85 0e		      STA	RIFLEN	;Initial riff length = 16
     89  0237		       85 12		      STA	SCRCTR
     90  0239		       a9 00		      LDA	#0
     91  023b		       85 0f		      STA	RIFLEN+1
     92  023d		       85 13		      STA	SCRCTR+1
     93  023f		       a9 00		      LDA	#0
     94  0241		       85 06		      STA	STPFLG
     95  0243		       85 07		      STA	RSTFLG
     96  0245		       a9 01		      LDA	#1
     97  0247		       85 0d		      STA	TCOUNT
     98  0249		       a9 00		      LDA	#<T2_VAL	;Set Timer 2 (tempo) value
     99  024b		       8d 08 a8 	      STA	T2LL
    100  024e		       a9 60		      LDA	#>T2_VAL
    101  0250		       8d 09 a8 	      STA	T2CH	;and start it
    102  0253		       58		      CLI
    103  0254
    104  0254							; MAIN LOOP: scan keyboard
    105  0254		       20 6f 02    MLOOP      JSR	GETCMD
    106  0257		       4c 54 02 	      JMP	MLOOP
    107  025a
    108  025a
    109  025a							;---------- Play one note
    110  025a		       8d 06 a8    BOP	      STA	T1LL	; Store low byte of freq. in timer lo latch
    111  025d		       a5 07		      LDA	RSTFLG
    112  025f		       f0 08		      BEQ	GOON
    113  0261		       a9 00		      LDA	#0
    114  0263		       8d 05 a8 	      STA	T1CH
    115  0266		       85 07		      STA	RSTFLG
    116  0268		       60		      RTS
    117  0269		       a5 05	   GOON       LDA	RANGE	;store upper byte of timer ('pitch' range), which
    118  026b		       8d 05 a8 	      STA	T1CH	;triggers the free-running counter output on PB7
    119  026e		       60		      RTS
    120  026f
    121  026f
    122  026f							;---------- Get pressed key (if any) and process it (scan display once)
    123  026f		       20 88 81    GETCMD     JSR	SAVER
    124  0272		       20 06 89 	      JSR	SCAND	;Scan display once
    125  0275		       20 23 89 	      JSR	KEYQ
    126  0278		       d0 03		      BNE	GTKY
    127  027a		       4c c4 81 	      JMP	RESALL	;No key down: restore regs. and return
    128  027d		       20 2c 89    GTKY       JSR	LRNKEY
    129  0280		       48		      PHA
    130  0281		       20 23 89    DEBNCE     JSR	KEYQ
    131  0284		       d0 fb		      BNE	DEBNCE	;Key still down? Wait longer.
    132  0286		       20 9b 89 	      JSR	NOBEEP
    133  0289		       20 23 89 	      JSR	KEYQ
    134  028c		       d0 f3		      BNE	DEBNCE
    135  028e		       68	   PARSE      PLA
    136  028f		       c9 0d		      CMP	#$0D	; < CR > = HALT
    137  0291		       d0 05		      BNE	NEXT1
    138  0293		       85 06		      STA	STPFLG
    139  0295		       4c c4 81 	      JMP	RESALL
    140  0298		       c9 2d	   NEXT1      CMP	#$2D	; < - > =	tempo
    141  029a		       d0 05		      BNE	NEXT2
    142  029c		       a2 00		      LDX	#TEMPO
    143  029e		       4c 28 03 	      JMP	SETIDX
    144  02a1		       c9 3e	   NEXT2      CMP	#$3E	; < -> > =	pitch range
    145  02a3		       d0 05		      BNE	NEXT3
    146  02a5		       a2 05		      LDX	#RANGE
    147  02a7		       4c 28 03 	      JMP	SETIDX
    148  02aa		       c9 47	   NEXT3      CMP	#$47	; < GO > =	PNIBN1
    149  02ac		       d0 05		      BNE	NEXT4
    150  02ae		       a2 03		      LDX	#PNIBN1
    151  02b0		       4c 28 03 	      JMP	SETIDX
    152  02b3		       c9 52	   NEXT4      CMP	#$52	; < reg > =	PNIBN0
    153  02b5		       d0 05		      BNE	NEXT5
    154  02b7		       a2 04		      LDX	#PNIBN0
    155  02b9		       4c 28 03 	      JMP	SETIDX
    156  02bc		       c9 13	   NEXT5      CMP	#$13	;< L2 > = PNIBN3
    157  02be		       d0 05		      BNE	NEXT6
    158  02c0		       a2 01		      LDX	#PNIBN3
    159  02c2		       4c 28 03 	      JMP	SETIDX
    160  02c5		       c9 1e	   NEXT6      CMP	#$1E	;< S2 > = PNIBN2
    161  02c7		       d0 05		      BNE	NEXT7
    162  02c9		       a2 02		      LDX	#PNIBN2
    163  02cb		       4c 28 03 	      JMP	SETIDX
    164  02ce		       c9 4d	   NEXT7      CMP	#$4D	;< MEM > = RMASK
    165  02d0		       d0 05		      BNE	NEXT8
    166  02d2		       a2 09		      LDX	#RMASK	; (will require processing)
    167  02d4		       4c 28 03 	      JMP	SETIDX
    168  02d7		       c9 ff	   NEXT8      CMP	#$FF	;< SHIFT > = RIFLEN
    169  02d9		       d0 05		      BNE	PARAM
    170  02db		       a2 0e		      LDX	#RIFLEN	; (will require processing)
    171  02dd		       4c 28 03 	      JMP	SETIDX
    172  02e0
    173  02e0		       20 75 82    PARAM      JSR	ASCNIB
    174  02e3		       a6 0a		      LDX	INDEX
    175  02e5		       e0 09		      CPX	#RMASK	; Mem key (set rest mask)?
    176  02e7		       d0 0c		      BNE	P1
    177  02e9		       aa		      TAX
    178  02ea		       a9 01		      LDA	#1
    179  02ec		       0a	   SHFT       ASL
    180  02ed		       ca		      DEX
    181  02ee		       d0 fc		      BNE	SHFT
    182  02f0		       85 09		      STA	RMASK
    183  02f2		       4c c4 81 	      JMP	RESALL
    184  02f5
    185  02f5		       e0 0e	   P1	      CPX	#RIFLEN	; Shift key (set Riff length)
    186  02f7		       d0 19		      BNE	P2
    187  02f9		       0a		      ASL		;double the index value
    188  02fa		       aa		      TAX
    189  02fb		       bd aa 03 	      LDA	RFLTAB,X
    190  02fe		       85 0e		      STA	RIFLEN
    191  0300		       bd ab 03 	      LDA	RFLTAB+1,X
    192  0303		       85 0f		      STA	RIFLEN+1
    193  0305		       78		      SEI
    194  0306		       a9 01		      LDA	#1	; Force immediate riff reset
    195  0308		       85 12		      STA	SCRCTR
    196  030a		       a9 00		      LDA	#0
    197  030c		       85 13		      STA	SCRCTR+1
    198  030e		       58		      CLI
    199  030f		       4c c4 81 	      JMP	RESALL
    200  0312
    201  0312		       95 00	   P2	      STA	VARS,X
    202  0314		       a5 03		      LDA	PNIBN1	; (re)build memory-scan pointer
    203  0316		       0a		      ASL
    204  0317		       0a		      ASL
    205  0318		       0a		      ASL
    206  0319		       0a		      ASL
    207  031a		       65 04		      ADC	PNIBN0
    208  031c		       85 0b		      STA	SCANAD
    209  031e		       a5 01		      LDA	PNIBN3
    210  0320		       0a		      ASL
    211  0321		       0a		      ASL
    212  0322		       0a		      ASL
    213  0323		       0a		      ASL
    214  0324		       65 02		      ADC	PNIBN2
    215  0326		       85 0c		      STA	SCANAD+1
    216  0328
    217  0328		       86 0a	   SETIDX     STX	INDEX
    218  032a		       20 30 03 	      JSR	SETDSP
    219  032d		       4c c4 81 	      JMP	RESALL
    220  0330
    221  0330
    222  0330							;---------- Display memory pointer
    223  0330		       a2 03	   SETDSP     LDX	#3
    224  0332		       b4 01	   SETD2      LDY	PRNIBS,X
    225  0334		       b9 29 8c 	      LDA	SEGSM1,Y
    226  0337		       9d 40 a6 	      STA	DSPBUF,X
    227  033a		       ca		      DEX
    228  033b		       10 f5		      BPL	SETD2
    229  033d		       a9 00		      LDA	#0
    230  033f		       09 80		      ORA	#$80	; light up decimal point
    231  0341		       8d 44 a6 	      STA	DSPBUF+4
    232  0344		       a9 00		      LDA	#0
    233  0346		       8d 45 a6 	      STA	DSPBUF+5
    234  0349		       60		      RTS
    235  034a
    236  034a
    237  034a							;---------- Interrupt service routine -- called by timeout of TIMER 2 (tempo timer)
    238  034a		       48	   IRQSRV     PHA
    239  034b		       8a		      TXA
    240  034c		       48		      PHA
    241  034d		       98		      TYA
    242  034e		       48		      PHA
    243  034f		       ba		      TSX
    244  0350		       bd 04 01 	      LDA	$0104,X
    245  0353		       29 10		      AND	#$10
    246  0355		       f0 08		      BEQ	NOBRK
    247  0357		       68		      PLA
    248  0358		       a8		      TAY
    249  0359		       68		      PLA
    250  035a		       aa		      TAX
    251  035b		       68		      PLA
    252  035c		       6c f6 ff 	      JMP	(USRBRK)
    253  035f
    254  035f		       ad 0d a8    NOBRK      LDA	IFR
    255  0362		       8d 0d a8 	      STA	IFR	; clear interrupt
    256  0365							; Re-set the (one-shot) Timer
    257  0365		       a9 00		      LDA	#<T2_VAL	;Set Timer 2 (tempo) value
    258  0367		       8d 08 a8 	      STA	T2LL
    259  036a		       a9 60		      LDA	#>T2_VAL
    260  036c		       8d 09 a8 	      STA	T2CH	;and re-start it
    261  036f
    262  036f		       c6 0d		      DEC	TCOUNT
    263  0371		       d0 31		      BNE	IRQOUT
    264  0373
    265  0373		       a5 00		      LDA	TEMPO	;Reset the tempo value
    266  0375		       85 0d		      STA	TCOUNT
    267  0377		       a0 00	   PLAY       LDY	#0
    268  0379		       b1 10		      LDA	(SCORE),Y	;Get next 'pitch'
    269  037b		       24 09		      BIT	RMASK	;Arbitrary rest test
    270  037d		       d0 04		      BNE	CONTIN
    271  037f		       85 07		      STA	RSTFLG
    272  0381		       a9 00		      LDA	#0
    273  0383		       20 5a 02    CONTIN     JSR	BOP
    274  0386		       e6 10	   NEXT       INC	SCORE
    275  0388		       d0 02		      BNE	NX1
    276  038a		       e6 11		      INC	SCORE+1
    277  038c		       c6 12	   NX1	      DEC	SCRCTR
    278  038e		       d0 14		      BNE	IRQOUT
    279  0390		       c6 13		      DEC	SCRCTR+1
    280  0392		       d0 10		      BNE	IRQOUT
    281  0394		       a5 0b		      LDA	SCANAD	; End of riff: loop back to start
    282  0396		       85 10		      STA	SCORE
    283  0398		       a5 0c		      LDA	SCANAD+1
    284  039a		       85 11		      STA	SCORE+1
    285  039c		       a5 0e		      LDA	RIFLEN
    286  039e		       85 12		      STA	SCRCTR
    287  03a0		       a5 0f		      LDA	RIFLEN+1
    288  03a2		       85 13		      STA	SCRCTR+1
    289  03a4
    290  03a4		       68	   IRQOUT     PLA
    291  03a5		       a8		      TAY
    292  03a6		       68		      PLA
    293  03a7		       aa		      TAX
    294  03a8		       68		      PLA
    295  03a9		       40		      RTI
    296  03aa
    297  03aa		       02 00	   RFLTAB     .WORD.w	2	;Riff length table
    298  03ac		       03 00		      .WORD.w	3
    299  03ae		       04 00		      .WORD.w	4
    300  03b0		       08 00		      .WORD.w	8
    301  03b2		       0c 00		      .WORD.w	12
    302  03b4		       10 00		      .WORD.w	16
    303  03b6		       18 00		      .WORD.w	24
    304  03b8		       20 00		      .WORD.w	32
    305  03ba		       40 00		      .WORD.w	64
    306  03bc		       80 00		      .WORD.w	128
    307  03be		       00 01		      .WORD.w	256
    308  03c0		       00 02		      .WORD.w	512
    309  03c2		       00 04		      .WORD.w	1024
    310  03c4		       00 08		      .WORD.w	2048
    311  03c6		       00 10		      .WORD.w	4096
    312  03c8		       00 20		      .WORD.w	8192
    313  03ca
    314  03ca
    315  03ca
