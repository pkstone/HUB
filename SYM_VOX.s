------- FILE SYM_VOX.asm LEVEL 1 PASS 2
      1  0348 ????						;SYM memory player (scans parts of memory and 'plays' through PB7)
      2  0348 ????
      3  0348 ????
      4  0348 ????				      processor	6502
      5  0200				   .	      =	$200
      6  0200
      7  0200							;---------  CONSTANTS
      8  0200		       30 00	   T2_VAL     =	$3000	;Set Timer 2 interval
      9  0200
     10  0200							;---------  6532 (which includes system RAM)
     11  0200		       a4 00	   KBDORA     =	$A400	;6532 Output register A (Keyboard columns)
     12  0200		       a4 02	   KBDORB     =	$A402	;6532 Output register B (Keyboard rows)
     13  0200		       a6 40	   DSPBUF     =	$A640	;6532 System RAM: Display Buffer
     14  0200
     15  0200
     16  0200							;------ PORTS
     17  0200		       a8 06	   T1LL       =	$A806
     18  0200		       a8 05	   T1CH       =	$A805
     19  0200		       a8 0b	   ACR	      =	$A80B
     20  0200		       a8 0d	   IFR	      =	$A80D
     21  0200		       a8 0e	   IER	      =	$A80E
     22  0200		       a8 08	   T2LL       =	$A808
     23  0200		       a8 09	   T2CH       =	$A809
     24  0200
     25  0200							;------ VARIABLES
     26  0200		       00 00	   VARS       =	$00
     27  0200		       00 00	   TEMPO      =	$00
     28  0200		       00 01	   PRNIBS     =	$01	;Four address nibbles:
     29  0200		       00 01	   PORTN3     =	$01	;Address nibbles for memory read pointer
     30  0200		       00 02	   PORTN2     =	$02
     31  0200		       00 03	   PORTN1     =	$03
     32  0200		       00 04	   PORTN0     =	$04
     33  0200		       00 05	   RANGE      =	$05
     34  0200		       00 06	   STPFLG     =	$06
     35  0200		       00 07	   RSTFLG     =	$07
     36  0200		       00 08	   YPTR       =	$08
     37  0200		       00 09	   RMASK      =	$09
     38  0200		       00 0a	   INDEX      =	$0A
     39  0200		       00 0b	   PORTLO     =	$0B
     40  0200		       00 0c	   PORTHI     =	$0C
     41  0200		       00 0d	   TCOUNT     =	$0D	;Timer interrupt count
     42  0200
     43  0200							;------ MONITOR SUBROUTINES
     44  0200		       81 c4	   RESALL     =	$81C4
     45  0200		       81 88	   SAVER      =	$8188
     46  0200		       82 75	   ASCNIB     =	$8275
     47  0200		       88 af	   GETKEY     =	$88AF
     48  0200		       89 06	   SCAND      =	$8906
     49  0200		       89 23	   KEYQ       =	$8923
     50  0200		       89 2c	   LRNKEY     =	$892C
     51  0200		       89 72	   BEEP       =	$8972
     52  0200		       89 9b	   NOBEEP     =	$899B
     53  0200		       8b 86	   ACCESS     =	$8B86
     54  0200		       8c 29	   SEGSM1     =	$8C29	; SYM display
     55  0200
     56  0200		       ff f6	   USRBRK     =	$FFF6	;User break vector
     57  0200		       ff fe	   IRQVEC     =	$FFFE	;Interrupt vector
     58  0200
     59  0200
     60  0200		       78	   INIT       SEI
     61  0201		       20 86 8b 	      JSR	ACCESS
     62  0204		       20 e0 02 	      JSR	SETDSP
     63  0207		       a9 fa		      LDA	#<IRQSRV
     64  0209		       8d fe ff 	      STA	IRQVEC
     65  020c		       a9 02		      LDA	#>IRQSRV
     66  020e		       8d ff ff 	      STA	IRQVEC+1
     67  0211		       a9 c0		      LDA	#$C0	;Set timer 1: free-running, output on PB7
     68  0213		       8d 0b a8 	      STA	ACR	;    timer 2: one-shot (will trigger interrupt)
     69  0216		       a9 a0		      LDA	#$A0
     70  0218		       8d 0e a8 	      STA	IER
     71  021b		       a9 c8		      LDA	#$C8
     72  021d		       85 0c		      STA	PORTHI
     73  021f		       a9 00		      LDA	#$00
     74  0221		       85 0b		      STA	PORTLO
     75  0223		       a9 07		      LDA	#7
     76  0225		       85 05		      STA	RANGE
     77  0227		       a9 0e		      LDA	#$0E
     78  0229		       85 00		      STA	TEMPO
     79  022b		       a9 40		      LDA	#$40
     80  022d		       85 09		      STA	RMASK	;Arbitrary rest tester: try $04
     81  022f		       a9 00		      LDA	#0	;zero the score pointer
     82  0231		       85 08		      STA	YPTR
     83  0233		       85 06		      STA	STPFLG
     84  0235		       85 07		      STA	RSTFLG
     85  0237		       a9 01		      LDA	#1
     86  0239		       85 0d		      STA	TCOUNT
     87  023b		       a9 00		      LDA	#<T2_VAL	;Set Timer 2 (tempo) value
     88  023d		       8d 08 a8 	      STA	T2LL
     89  0240		       a9 30		      LDA	#>T2_VAL
     90  0242		       8d 09 a8 	      STA	T2CH	;and start it
     91  0245		       58		      CLI
     92  0246
     93  0246							; MAIN LOOP: scan keyboard
     94  0246		       20 61 02    MLOOP      JSR	GETCMD
     95  0249		       4c 46 02 	      JMP	MLOOP
     96  024c
     97  024c		       8d 06 a8    BOP	      STA	T1LL	; Store low byte of freq. in timer lo latch
     98  024f		       a5 07		      LDA	RSTFLG
     99  0251		       f0 08		      BEQ	GOON
    100  0253		       a9 00		      LDA	#0
    101  0255		       8d 05 a8 	      STA	T1CH
    102  0258		       85 07		      STA	RSTFLG
    103  025a		       60		      RTS
    104  025b		       a5 05	   GOON       LDA	RANGE	;store upper byte of timer ('pitch' range), which
    105  025d		       8d 05 a8 	      STA	T1CH	;triggers the free-running counter output on PB7
    106  0260		       60		      RTS
    107  0261
    108  0261							; Get pressed key (if any)
    109  0261		       20 88 81    GETCMD     JSR	SAVER
    110  0264		       20 06 89 	      JSR	SCAND	;Scan display once
    111  0267		       20 23 89 	      JSR	KEYQ
    112  026a		       f0 71		      BEQ	EXIT
    113  026c		       20 2c 89 	      JSR	LRNKEY
    114  026f		       48		      PHA
    115  0270		       20 23 89    DEBNCE     JSR	KEYQ
    116  0273		       d0 fb		      BNE	DEBNCE	;Key still down? Wait longer.
    117  0275		       20 9b 89 	      JSR	NOBEEP
    118  0278		       20 23 89 	      JSR	KEYQ
    119  027b		       d0 f3		      BNE	DEBNCE
    120  027d		       68	   PARSE      PLA
    121  027e		       c9 0d		      CMP	#$0D	; < CR > = HALT
    122  0280		       d0 05		      BNE	NEXT1
    123  0282		       85 06		      STA	STPFLG
    124  0284		       4c dd 02 	      JMP	EXIT
    125  0287		       c9 2d	   NEXT1      CMP	#$2D	; < - > =	tempo
    126  0289		       d0 05		      BNE	NEXT2
    127  028b		       a2 00		      LDX	#0	; zeroeth parameter
    128  028d		       4c d8 02 	      JMP	OUT
    129  0290		       c9 3e	   NEXT2      CMP	#$3E	; < -> > =	pitch range
    130  0292		       d0 05		      BNE	NEXT3
    131  0294		       a2 05		      LDX	#5	; fifth parameter
    132  0296		       4c d8 02 	      JMP	OUT
    133  0299		       c9 47	   NEXT3      CMP	#$47	; < GO > =	PORTN1
    134  029b		       d0 05		      BNE	NEXT4
    135  029d		       a2 03		      LDX	#3	; third parameter
    136  029f		       4c d8 02 	      JMP	OUT
    137  02a2		       c9 52	   NEXT4      CMP	#$52	; < reg > =	PORTN0
    138  02a4		       d0 05		      BNE	NEXT5
    139  02a6		       a2 04		      LDX	#4	; fourth parameter
    140  02a8		       4c d8 02 	      JMP	OUT
    141  02ab		       c9 13	   NEXT5      CMP	#$13	;< L2 > = PORTN3
    142  02ad		       d0 05		      BNE	NEXT6
    143  02af		       a2 01		      LDX	#1	; first parameter
    144  02b1		       4c d8 02 	      JMP	OUT
    145  02b4		       c9 1e	   NEXT6      CMP	#$1E	;< S2 > = PORTN2
    146  02b6		       d0 05		      BNE	PARAM
    147  02b8		       a2 02		      LDX	#2	; second parameter
    148  02ba		       4c d8 02 	      JMP	OUT
    149  02bd
    150  02bd		       20 75 82    PARAM      JSR	ASCNIB
    151  02c0		       a6 0a		      LDX	INDEX
    152  02c2		       95 00		      STA	VARS,X
    153  02c4		       a5 03		      LDA	PORTN1	; (re)build memory-scan pointer
    154  02c6		       0a		      ASL
    155  02c7		       0a		      ASL
    156  02c8		       0a		      ASL
    157  02c9		       0a		      ASL
    158  02ca		       65 04		      ADC	PORTN0
    159  02cc		       85 0b		      STA	PORTLO
    160  02ce		       a5 01		      LDA	PORTN3
    161  02d0		       0a		      ASL
    162  02d1		       0a		      ASL
    163  02d2		       0a		      ASL
    164  02d3		       0a		      ASL
    165  02d4		       65 02		      ADC	PORTN2
    166  02d6		       85 0c		      STA	PORTHI
    167  02d8
    168  02d8		       86 0a	   OUT	      STX	INDEX
    169  02da		       20 e0 02 	      JSR	SETDSP
    170  02dd		       4c c4 81    EXIT       JMP	RESALL
    171  02e0
    172  02e0							;Display memory pointer
    173  02e0		       a2 03	   SETDSP     LDX	#3
    174  02e2		       b4 01	   SETD2      LDY	PRNIBS,X
    175  02e4		       b9 29 8c 	      LDA	SEGSM1,Y
    176  02e7		       9d 40 a6 	      STA	DSPBUF,X
    177  02ea		       ca		      DEX
    178  02eb		       10 f5		      BPL	SETD2
    179  02ed		       a9 00		      LDA	#0
    180  02ef		       09 80		      ORA	#$80	; light up decimal point
    181  02f1		       8d 44 a6 	      STA	DSPBUF+4
    182  02f4		       a9 00		      LDA	#0
    183  02f6		       8d 45 a6 	      STA	DSPBUF+5
    184  02f9		       60		      RTS
    185  02fa
    186  02fa							; Interrupt service routine -- called by timeout of TIMER 2 (tempo timer)
    187  02fa		       48	   IRQSRV     PHA
    188  02fb		       8a		      TXA
    189  02fc		       48		      PHA
    190  02fd		       98		      TYA
    191  02fe		       48		      PHA
    192  02ff		       ba		      TSX
    193  0300		       bd 04 01 	      LDA	$0104,X
    194  0303		       29 10		      AND	#$10
    195  0305		       f0 08		      BEQ	NOBRK
    196  0307		       68		      PLA
    197  0308		       a8		      TAY
    198  0309		       68		      PLA
    199  030a		       aa		      TAX
    200  030b		       68		      PLA
    201  030c		       6c f6 ff 	      JMP	(USRBRK)
    202  030f
    203  030f		       ad 0d a8    NOBRK      LDA	IFR
    204  0312		       8d 0d a8 	      STA	IFR	; clear interrupt
    205  0315							; Re-set the (one-shot) Timer
    206  0315		       a9 00		      LDA	#<T2_VAL	;Set Timer 2 (tempo) value
    207  0317		       8d 08 a8 	      STA	T2LL
    208  031a		       a9 30		      LDA	#>T2_VAL
    209  031c		       8d 09 a8 	      STA	T2CH	;and re-start it
    210  031f
    211  031f		       c6 0d		      DEC	TCOUNT
    212  0321		       d0 1f		      BNE	IRQOUT
    213  0323
    214  0323		       a5 00		      LDA	TEMPO	;Reset the tempo value
    215  0325		       85 0d		      STA	TCOUNT
    216  0327		       a4 08	   PLAY       LDY	YPTR
    217  0329		       b1 0b		      LDA	(PORTLO),Y	;Get next 'pitch'
    218  032b		       24 09		      BIT	RMASK	;Arbitrary rest test
    219  032d		       d0 04		      BNE	CONTIN
    220  032f		       85 07		      STA	RSTFLG
    221  0331		       a9 00		      LDA	#0
    222  0333		       20 4c 02    CONTIN     JSR	BOP
    223  0336		       e6 08	   NEXT       INC	YPTR
    224  0338		       a4 08		      LDY	YPTR
    225  033a		       c0 10		      CPY	#$10	; End of bar?
    226  033c		       d0 04		      BNE	IRQOUT
    227  033e		       a0 00		      LDY	#0	; Yes: reset score pointer
    228  0340		       84 08		      STY	YPTR
    229  0342
    230  0342		       68	   IRQOUT     PLA
    231  0343		       a8		      TAY
    232  0344		       68		      PLA
    233  0345		       aa		      TAX
    234  0346		       68		      PLA
    235  0347		       40		      RTI
    236  0348
