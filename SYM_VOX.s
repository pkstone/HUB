------- FILE SYM_VOX.asm LEVEL 1 PASS 2
      1  0318					      processor	6502
      2  0200				   .	      =	$200
      3  0200
      4  0200
      5  0200							;SYM memory player (scans parts of memory and 'plays' through PB7)
      6  0200
      7  0200							;---------  6532 (which includes system RAM)
      8  0200		       a4 00	   KBDORA     =	$A400	;6532 Output register A (Keyboard columns)
      9  0200		       a4 02	   KBDORB     =	$A402	;6532 Output register B (Keyboard rows)
     10  0200		       a6 40	   DSPBUF     =	$A640	;6532 System RAM: Display Buffer
     11  0200
     12  0200
     13  0200							;------ PORTS
     14  0200		       a8 06	   T1LL       =	$A806
     15  0200		       a8 05	   T1CH       =	$A805
     16  0200		       a8 0b	   ACR	      =	$A80B
     17  0200		       a8 0d	   IFR	      =	$A80D
     18  0200		       a8 08	   T2LL       =	$A808
     19  0200		       a8 09	   T2CH       =	$A809
     20  0200
     21  0200							;------ VARIABLES
     22  0200		       00 00	   VARS       =	$00
     23  0200		       00 00	   TEMPO      =	$00
     24  0200		       00 01	   DRUMLO     =	$01
     25  0200		       00 02	   DRUMHI     =	$02
     26  0200		       00 03	   PORTLO     =	$03
     27  0200		       00 04	   PORTHI     =	$04
     28  0200		       00 05	   RANGE      =	$05
     29  0200		       00 06	   STPFLG     =	$06
     30  0200		       00 07	   RSTFLG     =	$07
     31  0200		       00 08	   YPTR       =	$08
     32  0200		       00 09	   MASK       =	$09
     33  0200		       00 0a	   INDEX      =	$0A
     34  0200
     35  0200							;------ MONITOR SUBROUTINES
     36  0200		       81 c4	   RESALL     =	$81C4
     37  0200		       81 88	   SAVER      =	$8188
     38  0200		       82 75	   ASCNIB     =	$8275
     39  0200		       88 af	   GETKEY     =	$88AF
     40  0200		       89 06	   SCAND      =	$8906
     41  0200		       89 23	   KEYQ       =	$8923
     42  0200		       89 2c	   LRNKEY     =	$892C
     43  0200		       89 72	   BEEP       =	$8972
     44  0200		       89 9b	   NOBEEP     =	$899B
     45  0200		       8b 86	   ACCESS     =	$8B86
     46  0200		       8c 29	   SEGSM1     =	$8C29	; SYM display
     47  0200
     48  0200		       20 86 8b    INIT       JSR	ACCESS
     49  0203		       20 f4 02 	      JSR	SETDSP
     50  0206		       a9 c0		      LDA	#$C0
     51  0208		       8d 0b a8 	      STA	ACR
     52  020b		       a9 c8		      LDA	#$C8
     53  020d		       85 04		      STA	PORTHI
     54  020f		       a9 00		      LDA	#$00
     55  0211		       85 03		      STA	PORTLO
     56  0213		       a9 07		      LDA	#7
     57  0215		       85 05		      STA	RANGE
     58  0217		       a9 0e		      LDA	#$0E
     59  0219		       85 00		      STA	TEMPO
     60  021b		       a9 40		      LDA	#$40
     61  021d		       85 09		      STA	MASK	;Arbitrary rest tester: try $04
     62  021f		       a9 00	   TOP	      LDA	#0
     63  0221		       85 06		      STA	STPFLG
     64  0223		       85 07		      STA	RSTFLG
     65  0225		       20 23 89 	      JSR	KEYQ	;Wait for a key press
     66  0228		       f0 f5		      BEQ	TOP
     67  022a		       20 8e 02 	      JSR	GETCMD
     68  022d		       a9 00	   NEWBAR     LDA	#0
     69  022f		       85 08		      STA	YPTR
     70  0231		       a4 08		      LDY	YPTR
     71  0233		       b1 03	   PLAY       LDA	(PORTLO),Y	;Get next 'pitch'
     72  0235		       24 09		      BIT	MASK	;Arbitrary rest test
     73  0237		       d0 04		      BNE	CONTIN
     74  0239		       85 07		      STA	RSTFLG
     75  023b		       a9 00		      LDA	#0
     76  023d		       a4 00	   CONTIN     LDY	TEMPO
     77  023f		       20 54 02 	      JSR	BOP
     78  0242		       20 8e 02 	      JSR	GETCMD
     79  0245		       a5 06		      LDA	STPFLG
     80  0247		       d0 d6		      BNE	TOP
     81  0249		       e6 08	   NEXT       INC	YPTR
     82  024b		       a4 08		      LDY	YPTR
     83  024d		       c0 10		      CPY	#$10	; End of bar?
     84  024f		       f0 dc		      BEQ	NEWBAR
     85  0251		       4c 33 02 	      JMP	PLAY	;  NO: back to top of play loop
     86  0254
     87  0254		       8d 06 a8    BOP	      STA	T1LL
     88  0257		       a5 07		      LDA	RSTFLG
     89  0259		       f0 0a		      BEQ	GOON
     90  025b		       a9 00		      LDA	#0
     91  025d		       8d 05 a8 	      STA	T1CH
     92  0260		       85 07		      STA	RSTFLG
     93  0262		       4c 6a 02 	      JMP	STALL
     94  0265
     95  0265		       a5 05	   GOON       LDA	RANGE
     96  0267		       8d 05 a8 	      STA	T1CH
     97  026a		       a2 40	   STALL      LDX	#$40
     98  026c		       ca	   WAIT       DEX
     99  026d		       d0 fd		      BNE	WAIT
    100  026f		       a9 ff	   TIME       LDA	#$FF
    101  0271		       8d 08 a8 	      STA	T2LL	;adjustable
    102  0274		       a9 10		      LDA	#$10
    103  0276		       8d 09 a8 	      STA	T2CH	;adjustable
    104  0279		       20 8e 02 	      JSR	GETCMD
    105  027c		       a5 06		      LDA	STPFLG
    106  027e		       d0 9f		      BNE	TOP
    107  0280		       a9 20		      LDA	#$20
    108  0282		       2c 0d a8    WAITIR     BIT	IFR
    109  0285		       d0 03		      BNE	TIME2
    110  0287		       4c 82 02 	      JMP	WAITIR
    111  028a		       88	   TIME2      DEY
    112  028b		       d0 e2		      BNE	TIME
    113  028d		       60		      RTS
    114  028e
    115  028e							; Get pressed key (if any)
    116  028e		       20 88 81    GETCMD     JSR	SAVER
    117  0291		       20 06 89 	      JSR	SCAND	;Scan display once
    118  0294		       20 23 89 	      JSR	KEYQ
    119  0297		       f0 58		      BEQ	EXIT
    120  0299		       20 2c 89 	      JSR	LRNKEY
    121  029c		       48		      PHA
    122  029d		       20 23 89    DEBNCE     JSR	KEYQ
    123  02a0		       d0 fb		      BNE	DEBNCE	;Key still down? Wait longer.
    124  02a2		       20 9b 89 	      JSR	NOBEEP
    125  02a5		       20 23 89 	      JSR	KEYQ
    126  02a8		       d0 f3		      BNE	DEBNCE
    127  02aa		       68	   PARSE      PLA
    128  02ab		       c9 0d		      CMP	#$0D	; < CR > = HALT
    129  02ad		       d0 05		      BNE	NEXT1
    130  02af		       85 06		      STA	STPFLG
    131  02b1		       4c f1 02 	      JMP	EXIT
    132  02b4		       c9 2d	   NEXT1      CMP	#$2D	; < - > =	tempo
    133  02b6		       d0 05		      BNE	NEXT2
    134  02b8		       a2 00		      LDX	#0	; zeroeth parameter
    135  02ba		       4c ef 02 	      JMP	OUT
    136  02bd		       c9 3e	   NEXT2      CMP	#$3E	; < -> > =	pitch range
    137  02bf		       d0 05		      BNE	NEXT3
    138  02c1		       a2 05		      LDX	#5	; fifth parameter
    139  02c3		       4c ef 02 	      JMP	OUT
    140  02c6		       c9 47	   NEXT3      CMP	#$47	; < GO > =	PORTHI
    141  02c8		       d0 05		      BNE	NEXT4
    142  02ca		       a2 04		      LDX	#4	; fourth parameter
    143  02cc		       4c ef 02 	      JMP	OUT
    144  02cf		       c9 52	   NEXT4      CMP	#$52	; < reg > =	PORTLO
    145  02d1		       d0 05		      BNE	PARAM
    146  02d3		       a2 03		      LDX	#3	; third parameter
    147  02d5		       4c ef 02 	      JMP	OUT
    148  02d8
    149  02d8		       20 75 82    PARAM      JSR	ASCNIB
    150  02db		       a6 0a		      LDX	INDEX
    151  02dd		       e0 05		      CPX	#5
    152  02df		       f0 0c		      BEQ	NOSHFT
    153  02e1		       e0 04		      CPX	#4
    154  02e3		       f0 08		      BEQ	NOSHFT
    155  02e5		       e0 02		      CPX	#2
    156  02e7		       f0 04		      BEQ	NOSHFT
    157  02e9		       0a	   SHIFT      ASL
    158  02ea		       0a		      ASL
    159  02eb		       0a		      ASL
    160  02ec		       0a		      ASL
    161  02ed		       95 00	   NOSHFT     STA	VARS,X
    162  02ef		       86 0a	   OUT	      STX	INDEX
    163  02f1		       4c c4 81    EXIT       JMP	RESALL
    164  02f4
    165  02f4		       a2 03	   SETDSP     LDX	#3
    166  02f6		       bd 12 03    SETD2      LDA	DSPDAT,X	;Set display to 'Hub 3.1'
    167  02f9		       9d 40 a6 	      STA	DSPBUF,X
    168  02fc		       ca		      DEX
    169  02fd		       10 f7		      BPL	SETD2
    170  02ff		       a2 01		      LDX	#$01
    171  0301		       bd 29 8c 	      LDA	SEGSM1,X
    172  0304		       09 80		      ORA	#$80
    173  0306		       8d 44 a6 	      STA	DSPBUF+4
    174  0309		       a2 03		      LDX	#$03
    175  030b		       bd 29 8c 	      LDA	SEGSM1,X
    176  030e		       8d 45 a6 	      STA	DSPBUF+5
    177  0311		       60		      RTS
    178  0312
    179  0312		       74	   DSPDAT     .BYTE.b	$74	;Codes for "hub 3.1" message on display
    180  0313		       1c		      .BYTE.b	$1C
    181  0314		       7c		      .BYTE.b	$7C
    182  0315		       00		      .BYTE.b	$00
    183  0316		       86		      .BYTE.b	$86
    184  0317		       bb		      .BYTE.b	$BB
    185  0318
    186  0318					      .END
