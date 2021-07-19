
SECTION code

                            ; 8085A A12 goes through 7404 1->2 to 8155 /CE
                            ; RAM is located from $1000 to $1100

                            ; 8155 Command / Status is above $08 (xxxxx000b) I/O address
                            ; PA Register xxxxx001b
                            ; PB Register xxxxx010b
                            ; PC Register xxxxx011b
                            ; Timer Register LSB xxxxx100b
                            ; Timer Register MSB xxxxx101b

                            ; TRAP (RST 4.5)    24h
                            ; RST 5.5           2Ch
                            ; RST 6.5           34h
                            ; RST 7.5           3Ch

                            ; Interface Port
                            ;                                       IN
                            ;  _________________________________________
                            ; | GND | 5V  | IR  | TR  | 5.5 | 6.5 | 7.5 |
                            ; |_____|_____|_____|_____|_____|_____|_____|
                            ; | GND | 5V  | A0  | SOD | RST | SID | RDY |
                            ; |_____|_____|_____|_____|_____|_____|_____|
                            ;               OUT         IN

                            ; I/O Port
                            ;   IN    IN    IN
                            ;  _________________________________________
                            ; | B0  | B2  | B4  | B6  | A7  | A5  | A3  |
                            ; |_____|_____|_____|_____|_____|_____|_____|
                            ; | C0  | B1  | B3  | B5  | B7  | A6  | A4  |
                            ; |_____|_____|_____|_____|_____|_____|_____|
                            ;         IN                            OUT

ORG 0000h

.RST_00
    ld      sp,$1100        ;[0001] 31 00 11    8155 RAM $1000 to $1100
    ld      a,$19           ;[0004] 3e 19
    sim                     ;[0006] 30          Reset R7.5, Set MSE, and Mask R5.5
    ld      a,$01           ;[0007] 3e 01
    out     ($10),a         ;[0009] d3 10       Write $01 to 8155 Command Register -> PA Output / PB Input
    ld      a,$00           ;[000b] 3e 00
    out     ($11),a         ;[000d] d3 11       Write $00 to 8155 PA Register -> FACE (clear PA)
    call    SIGN_ON         ;                   Write a serial sign on message
    jp      SELECTOR        ;[000f] c3 40 00

ORG 0024h

.TRAP
    jp      $0000           ;                   Reboot if trap occurs

ORG 002Ch

.RST_55
    jp      $0000           ;                   Reboot if R5.5 occurs (even though it is masked)

ORG 0034h

.RST_65
    jp      COMMAND         ;                   Use RST 6.5 to look for serial input

ORG 003Ch

.RST_75
    ei                      ;[003c] fb          Read RST 7.5 for REMOTE START (trigger)
    ret                     ;[003d] c9

ORG 0040

.SELECTOR
    in      a,($12)         ;[0040] db 12       Read 8155 PB (setting of timer wheel & switches)
    cp      $00             ;[0042] fe 00       and depending on value jump to the right delay.
    jp      Z,STANDARD_10   ;[0044] ca 60 01
    cp      $01             ;[0047] fe 01
    jp      Z,STANDARD_20   ;[0049] ca 30 01
    cp      $02             ;[004c] fe 02
    jp      Z,STANDARD_150  ;[004e] ca 00 01
    cp      $03             ;[0051] fe 03
    jp      Z,CENTERFIRE_RAPID  ;[0053] ca 90 01
    cp      $04             ;[0056] fe 04
    jp      Z,RAPID_8       ;[0058] ca 00 04
    cp      $05             ;[005b] fe 05
    jp      Z,RAPID_6       ;[005d] ca 30 04
    cp      $06             ;[0060] fe 06
    jp      Z,RAPID_4       ;[0062] ca 60 04
    cp      $10             ;[0065] fe 10
    jp      Z,SERVICE_165   ;[0067] ca 90 02
    cp      $11             ;[006a] fe 11
    jp      Z,SERVICE_35    ;[006c] ca c0 02
    cp      $12             ;[006f] fe 12
    jp      Z,SERVICE_15    ;[0071] ca f0 02
    cp      $13             ;[0074] fe 13
    jp      Z,SERVICE_6     ;[0076] ca 20 03
    cp      $14             ;[0079] fe 14
    jp      Z,SERVICE_8     ;[007b] ca 50 03
    cp      $15             ;[007e] fe 15
    jp      Z,SERVICE_4     ;[0080] ca 80 03
    cp      $16             ;[0083] fe 16
    jp      Z,SERVICE_15    ;[0085] ca f0 02
    jp      RST_00          ;[0088] c3 00 00

ORG 0090

.DELAY                      ;                   Delay based on BC contents (each 500ms)
    ld      de,$f420        ;[0090] 11 20 f4
.DELAY_LOOP
    dec     de              ;[0093] 1b
    ld      a,d             ;[0094] 7a
    or      e               ;[0095] b3
    jp      NZ,DELAY_LOOP   ;[0096] c2 93 00
    dec     bc              ;[0099] 0b
    ld      a,b             ;[009a] 78
    or      c               ;[009b] b1
    jp      NZ,DELAY        ;[009c] c2 90 00
    ret                     ;[009f] c9

ORG 0100h

.STANDARD_150
    ei                      ;[0100] fb
    halt                    ;[0101] 76
    ld      a,$ff           ;[0102] 3e ff
    out     ($11),a         ;[0104] d3 11       TURN (set PA)
    ld      bc,$000e        ;[0106] 01 0e 00
    call    $0090           ;[0109] cd 90 00    DELAY 7
    ld      a,$00           ;[010c] 3e 00
    out     ($11),a         ;[010e] d3 11       FACE (clear PA) FIRE
    ld      bc,$012c        ;[0110] 01 2c 01
    call    $0090           ;[0113] cd 90 00    DELAY 150
    ld      a,$ff           ;[0116] 3e ff
    out     ($11),a         ;[0118] d3 11       TURN (set PA)
    halt                    ;[011a] 76
    ld      a,$00           ;[011b] 3e 00
    out     ($11),a         ;[011d] d3 11       FACE (clear PA) SCORE
    halt                    ;[011f] 76
    ld      bc,$0004        ;[0120] 01 04 00
    call    $0090           ;[0123] cd 90 00    DELAY 2
    jp      STANDARD_150    ;[0126] c3 00 01

ORG 0130h

.STANDARD_20
    ei                      ;[0130] fb
    halt                    ;[0131] 76
    ld      a,$ff           ;[0132] 3e ff
    out     ($11),a         ;[0134] d3 11       TURN (set PA)
    ld      bc,$000e        ;[0136] 01 0e 00
    call    $0090           ;[0139] cd 90 00    DELAY 7
    ld      a,$00           ;[013c] 3e 00
    out     ($11),a         ;[013e] d3 11       FACE (clear PA) FIRE
    ld      bc,$0028        ;[0140] 01 28 00
    call    $0090           ;[0143] cd 90 00    DELAY 20
    ld      a,$ff           ;[0146] 3e ff
    out     ($11),a         ;[0148] d3 11       TURN (set PA)
    halt                    ;[014a] 76
    ld      a,$00           ;[014b] 3e 00
    out     ($11),a         ;[014d] d3 11       FACE (clear PA) SCORE
    halt                    ;[014f] 76
    ld      bc,$0004        ;[0150] 01 04 00
    call    $0090           ;[0153] cd 90 00    DELAY 2
    jp      STANDARD_20     ;[0156] c3 30 01

ORG 0160h

.STANDARD_10
    ei                      ;[0160] fb
    halt                    ;[0161] 76
    ld      a,$ff           ;[0162] 3e ff
    out     ($11),a         ;[0164] d3 11       TURN (set PA)
    ld      bc,$000e        ;[0166] 01 0e 00
    call    $0090           ;[0169] cd 90 00    DELAY 7
    ld      a,$00           ;[016c] 3e 00
    out     ($11),a         ;[016e] d3 11       FACE (clear PA) FIRE
    ld      bc,$0014        ;[0170] 01 14 00
    call    $0090           ;[0173] cd 90 00    DELAY 10
    ld      a,$ff           ;[0176] 3e ff
    out     ($11),a         ;[0178] d3 11       TURN (set PA)
    halt                    ;[017a] 76
    ld      a,$00           ;[017b] 3e 00
    out     ($11),a         ;[017d] d3 11       FACE (clear PA) SCORE
    halt                    ;[017f] 76
    ld      bc,$0004        ;[0180] 01 04 00
    call    $0090           ;[0183] cd 90 00    DELAY 2
    jp      STANDARD_10     ;[0186] c3 60 01

ORG 0190h

.CENTREFIRE_RAPID
    ei                      ;[0190] fb
    halt                    ;[0191] 76
    ld      l,$05           ;[0192] 2e 05       REPEAT 5x
    ld      a,$ff           ;[0194] 3e ff
.CENTREFIRE_LOOP
    out     ($11),a         ;[0196] d3 11       TURN (set PA)
    ld      bc,$000e        ;[0198] 01 0e 00
    call    $0090           ;[019b] cd 90 00    DELAY 7
    ld      a,$00           ;[019e] 3e 00
    out     ($11),a         ;[01a0] d3 11       FACE (clear PA) FIRE
    ld      bc,$0006        ;[01a2] 01 06 00
    call    $0090           ;[01a5] cd 90 00    DELAY 3
    dec     l               ;[01a8] 2d
    ld      a,$00           ;[01a9] 3e 00
    out     ($11),a         ;[01ab] d3 11       FACE (clear PA)
    cp      l               ;[01ad] bd
    jp      NZ,CENTREFIRE_LOOP  ;[01ae] c2 94 01
    ld      a,$ff           ;[01b1] 3e ff
    out     ($11),a         ;[01b3] d3 11       TURN (set PA)
    halt                    ;[01b5] 76
    ld      a,$00           ;[01b6] 3e 00
    out     ($11),a         ;[01b8] d3 11       FACE (clear PA) SCORE
    ld      bc,$0004        ;[01ba] 01 04 00
    call    $0090           ;[01bd] cd 90 00    DELAY 2
    jp      CENTREFIRE_RAPID    ;[01c0] c3 90 01

ORG 0290h

.SERVICE_165
    ei                      ;[0290] fb
    halt                    ;[0291] 76
    ld      a,$ff           ;[0292] 3e ff
    out     ($11),a         ;[0294] d3 11       TURN (set PA)
    ld      bc,$000e        ;[0296] 01 0e 00
    call    $0090           ;[0299] cd 90 00    DELAY 7
    ld      a,$00           ;[029c] 3e 00
    out     ($11),a         ;[029e] d3 11       FACE (clear PA) FIRE
    ld      bc,$014a        ;[02a0] 01 4a 01
    call    $0090           ;[02a3] cd 90 00    DELAY 165
    ld      a,$ff           ;[02a6] 3e ff
    out     ($11),a         ;[02a8] d3 11       TURN (set PA)
    halt                    ;[02aa] 76
    ld      a,$ff           ;[02ab] 3e ff
    out     ($11),a         ;[02ad] d3 11       TURN (set PA) SCORE
    halt                    ;[02af] 76
    ld      bc,$0004        ;[02b0] 01 04 00
    call    $0090           ;[02b3] cd 90 00    DELAY 2
    jp      SERVICE_165     ;[02b6] c3 90 02

ORG 02C0h

.SERVICE_35
    ei                      ;[02c0] fb
    halt                    ;[02c1] 76
    ld      a,$ff           ;[02c2] 3e ff
    out     ($11),a         ;[02c4] d3 11       TURN (set PA)
    ld      bc,$000e        ;[02c6] 01 0e 00
    call    $0090           ;[02c9] cd 90 00    DELAY 7
    ld      a,$00           ;[02cc] 3e 00
    out     ($11),a         ;[02ce] d3 11       FACE (clear PA) FIRE
    ld      bc,$0046        ;[02d0] 01 46 00
    call    $0090           ;[02d3] cd 90 00    DELAY 35
    ld      a,$ff           ;[02d6] 3e ff
    out     ($11),a         ;[02d8] d3 11       TURN (set PA)
    halt                    ;[02da] 76
    ld      a,$00           ;[02db] 3e 00
    out     ($11),a         ;[02dd] d3 11       FACE (clear PA) SCORE
    halt                    ;[02df] 76
    ld      bc,$0004        ;[02e0] 01 04 00
    call    $0090           ;[02e3] cd 90 00    DELAY 2
    jp      SERVICE_35      ;[02e6] c3 c0 02

ORG 02F0h

.SERVICE_15
    ei                      ;[02f0] fb
    halt                    ;[02f1] 76
    ld      a,$ff           ;[02f2] 3e ff
    out     ($11),a         ;[02f4] d3 11       TURN (set PA)
    ld      bc,$000e        ;[02f6] 01 0e 00
    call    $0090           ;[02f9] cd 90 00    DELAY 7
    ld      a,$00           ;[02fc] 3e 00
    out     ($11),a         ;[02fe] d3 11       FACE (clear PA) FIRE
    ld      bc,$001e        ;[0300] 01 1e 00
    call    $0090           ;[0303] cd 90 00    DELAY 15
    ld      a,$ff           ;[0306] 3e ff
    out     ($11),a         ;[0308] d3 11       TURN (set PA)
    halt                    ;[030a] 76
    ld      a,$00           ;[030b] 3e 00
    out     ($11),a         ;[030d] d3 11       FACE (clear PA) SCORE
    halt                    ;[030f] 76
    ld      bc,$0004        ;[0310] 01 04 00
    call    $0090           ;[0313] cd 90 00    DELAY 2
    jp      SERVICE_15      ;[0316] c3 f0 02

ORG 0320h

.SERVICE_6
    ei                      ;[0320] fb
    halt                    ;[0321] 76
    ld      a,$ff           ;[0322] 3e ff
    out     ($11),a         ;[0324] d3 11       TURN (set PA)
    ld      bc,$000e        ;[0326] 01 0e 00
    call    $0090           ;[0329] cd 90 00    DELAY 7
    ld      a,$00           ;[032c] 3e 00
    out     ($11),a         ;[032e] d3 11       FACE (clear PA) FIRE
    ld      bc,$000c        ;[0330] 01 0c 00
    call    $0090           ;[0333] cd 90 00    DELAY 6
    ld      a,$ff           ;[0336] 3e ff
    out     ($11),a         ;[0338] d3 11       TURN (set PA)
    halt                    ;[033a] 76
    ld      a,$00           ;[033b] 3e 00
    out     ($11),a         ;[033d] d3 11       FACE (clear PA) SCORE
    halt                    ;[033f] 76
    ld      bc,$0004        ;[0340] 01 04 00
    call    $0090           ;[0343] cd 90 00    DELAY 2
    jp      SERVICE_6       ;[0346] c3 20 03

ORG 0350h

.SERVICE_8
    ei                      ;[0350] fb
    halt                    ;[0351] 76
    ld      a,$ff           ;[0352] 3e ff
    out     ($11),a         ;[0354] d3 11       TURN (set PA)
    ld      bc,$000e        ;[0356] 01 0e 00
    call    $0090           ;[0359] cd 90 00    DELAY 7
    ld      a,$00           ;[035c] 3e 00
    out     ($11),a         ;[035e] d3 11       FACE (clear PA) FIRE
    ld      bc,$0010        ;[0360] 01 10 00
    call    $0090           ;[0363] cd 90 00    DELAY 8
    ld      a,$ff           ;[0366] 3e ff
    out     ($11),a         ;[0368] d3 11       TURN (set PA)
    halt                    ;[036a] 76
    ld      a,$00           ;[036b] 3e 00
    out     ($11),a         ;[036d] d3 11       FACE (clear PA) SCORE
    halt                    ;[036f] 76
    ld      bc,$0004        ;[0370] 01 04 00
    call    $0090           ;[0373] cd 90 00    DELAY 2
    jp      SERVICE_8       ;[0376] c3 50 03

ORG 0380h

.SERVICE_4
    ei                      ;[0380] fb
    halt                    ;[0381] 76
    ld      a,$ff           ;[0382] 3e ff
    out     ($11),a         ;[0384] d3 11       TURN (set PA)
    ld      bc,$000e        ;[0386] 01 0e 00
    call    $0090           ;[0389] cd 90 00    DELAY 7
    ld      a,$00           ;[038c] 3e 00
    out     ($11),a         ;[038e] d3 11       FACE (clear PA) FIRE
    ld      bc,$0008        ;[0390] 01 08 00
    call    $0090           ;[0393] cd 90 00    DELAY 4
    ld      a,$ff           ;[0396] 3e ff
    out     ($11),a         ;[0398] d3 11       TURN (set PA)
    halt                    ;[039a] 76
    ld      a,$00           ;[039b] 3e 00
    out     ($11),a         ;[039d] d3 11       FACE (clear PA) SCORE
    halt                    ;[039f] 76
    ld      bc,$0004        ;[03a0] 01 04 00
    call    $0090           ;[03a3] cd 90 00    DELAY 2
    jp      SERVICE_4       ;[03a6] c3 80 03


ORG 0400h

.RAPID_8
    ei                      ;[0400] fb
    ld      a,$00           ;[0401] 3e 00
    out     ($11),a         ;[0403] d3 11       FACE (clear PA) SCORE
    halt                    ;[0405] 76
    ld      a,$ff           ;[0406] 3e ff
    out     ($11),a         ;[0408] d3 11       TURN (set PA)
    ld      bc,$0002        ;[040a] 01 02 00
    call    $0090           ;[040d] cd 90 00    DELAY 1
    halt                    ;[0410] 76
    ld      bc,$0006        ;[0411] 01 06 00
    call    $0090           ;[0414] cd 90 00    DELAY 3
    ld      a,$00           ;[0417] 3e 00
    out     ($11),a         ;[0419] d3 11       FACE (clear PA) FIRE
    ld      bc,$0010        ;[041b] 01 10 00
    call    $0090           ;[041e] cd 90 00    DELAY 8
    ld      a,$ff           ;[0421] 3e ff
    out     ($11),a         ;[0423] d3 11       TURN (set PA)
    halt                    ;[0425] 76
    ld      bc,$0002        ;[0426] 01 02 00
    call    $0090           ;[0429] cd 90 00    DELAY 1
    jp      RAPID_8         ;[042c] c3 00 04

ORG 0430h

.RAPID_6
    ei                      ;[0430] fb
    ld      a,$00           ;[0431] 3e 00
    out     ($11),a         ;[0433] d3 11       FACE (clear PA) SCORE
    halt                    ;[0435] 76
    ld      a,$ff           ;[0436] 3e ff
    out     ($11),a         ;[0438] d3 11       TURN (set PA)
    ld      bc,$0002        ;[043a] 01 02 00
    call    $0090           ;[043d] cd 90 00    DELAY 1
    halt                    ;[0440] 76
    ld      bc,$0006        ;[0441] 01 06 00
    call    $0090           ;[0444] cd 90 00    DELAY 3
    ld      a,$00           ;[0447] 3e 00
    out     ($11),a         ;[0449] d3 11       FACE (clear PA) FIRE
    ld      bc,$000c        ;[044b] 01 0c 00
    call    $0090           ;[044e] cd 90 00    DELAY 6
    ld      a,$ff           ;[0451] 3e ff
    out     ($11),a         ;[0453] d3 11       TURN (set PA)
    halt                    ;[0455] 76
    ld      bc,$0002        ;[0456] 01 02 00
    call    $0090           ;[0459] cd 90 00    DELAY 1
    jp      RAPID_6         ;[045c] c3 30 04

ORG 0460h

.RAPID_4
    ei                      ;[0460] fb
    ld      a,$00           ;[0461] 3e 00
    out     ($11),a         ;[0463] d3 11       FACE (clear PA) SCORE
    halt                    ;[0465] 76
    ld      a,$ff           ;[0466] 3e ff
    out     ($11),a         ;[0468] d3 11       TURN (set PA)
    ld      bc,$0002        ;[046a] 01 02 00
    call    $0090           ;[046d] cd 90 00    DELAY 1
    halt                    ;[0470] 76
    ld      bc,$0006        ;[0471] 01 06 00
    call    $0090           ;[0474] cd 90 00    DELAY 3
    ld      a,$00           ;[0477] 3e 00
    out     ($11),a         ;[0479] d3 11       FACE (clear PA) FIRE
    ld      bc,$0008        ;[047b] 01 08 00
    call    $0090           ;[047e] cd 90 00    DELAY 4
    ld      a,$ff           ;[0481] 3e ff
    out     ($11),a         ;[0483] d3 11       TURN (set PA)
    halt                    ;[0485] 76
    ld      bc,$0002        ;[0486] 01 02 00
    call    $0090           ;[0489] cd 90 00    DELAY 1
    jp      RAPID_4         ;[048c] c3 60 04


ORG 0800h
                            ; arrive from R6.5
                            ; look for serial input
                            ; G - execute programmed sequence
                            ; x - decode additional sequence and program it
.COMMAND
    rim
    and     00100000b       ; check whether R6.5 pin is asserted
    jp      Z,GO            ; if set, check for a character otherwise...

    call    CIN             ; read character into C
    call    COUT            ; echo it back as acknowledgement
    ld      a,c
    cp      'G'             ; 0x47
    jp      Z,GO            ; do programmed timing

    cp      '@'             ; 0x40
    jp      Z,STANDARD_10
    cp      'A'
    jp      Z,STANDARD_20
    cp      'B'
    jp      Z,STANDARD_150
    cp      'C'
    jp      Z,CENTERFIRE_RAPID
    cp      'D'
    jp      Z,RAPID_8
    cp      'E'
    jp      Z,RAPID_6
    cp      'F'
    jp      Z,RAPID_4

    cp      'P'             ; 0x50
    jp      Z,SERVICE_165
    cp      'Q'
    jp      Z,SERVICE_35
    cp      'R'
    jp      Z,SERVICE_15
    cp      'S'
    jp      Z,SERVICE_6
    cp      'T'
    jp      Z,SERVICE_8
    cp      'U'
    jp      Z,SERVICE_4
    cp      'V'
    jp      Z,SERVICE_15

    ld      bc,$0001        ; 500ms delay
    call    DELAY

    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,COMMAND      ; if so, check for another character
                            ; otherwise for any other character
                            ; just start programmed sequence
.GO
    ei
    ret


.SIGN_ON
    ld      hl,MESSAGE      ; load address of message
.SIGN_ON_LOOP
    ld      c,(hl)          ; get next character
    xor     a
    or      c               ; check if null (end of string)
    ret     Z
    call    COUT            ; output character in C
    inc     hl              ; next character
    jp      SIGN_ON_LOOP


.COUT                       ; output a character in C
;   di
    push    hl
    push    bc

    ld      b,11            ; 11 bits per byte (2 stop bits)
    xor     a               ; clear carry for start bit
.COUT1
    ld      a,$80           ; set eventual SOD enable bit
    rra                     ; move carry into SOD bit
    sim                     ; output data
    ld      (hl),BITTIME
.COUT2
    dec     l
    jp      NZ,COUT2
    dec     h
    jp      NZ,COUT2        ; wait until a BITTIME has passed

    scf                     ; set eventual stop bit(s)
    ld      a,c
    rra
    ld      c,a
    dec     b
    jp      NZ,COUT1

    pop     bc
    pop     hl
;   ei
    ret


.CIN                        ; serial input returns with 8 bits in C
;   di
    push    hl

    ld      b,9             ; 9 bits per byte
.CIN1
    rim
    or      a               ; wait for start bit
    jp      M,CIN1

    ld      (hl),HALFBIT
.CIN2
    dec     l
    jp      NZ,CIN2
    dec     h
    jp      NZ,CIN2         ; wait until middle of start bit 

.CIN3
    ld      (hl),BITTIME
.CIN4
    dec     l
    jp      NZ,CIN4
    dec     h
    jp      NZ,CIN4         ; wait until a BITTIME has passed
    rim                     ; check SID level
    rla
    dec     b               ; is the the first stop bit
    jp      Z,CIN5          ; yes, then we're done

    ld      a,c             ; rotate character in C
    rra
    ld      c,a
    nop                     ; make CIN and COUT loop times equal
    jp      CIN3

.CIN5
    pop     hl
;   ei
    ret


.MESSAGE
    DEFB    "\nOPC - Target Turner\n\n",00h

.BITTIME
    DEFW    0112h           ; value for 9600 baud

.HALFBIT
    DEFW    0109h           ; value for 9600 baud

