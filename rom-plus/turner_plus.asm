
SECTION code

                            ; feilipu (C) 2021
                            ;
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

                            ; Serial interface using SID/SOD is 9600 baud 8n2
                            ; Triggered by RST65 held high.

                            ; Build with z88dk:
                            ; zcc +z80  -m8085 --no-crt --list -Ca-f0xFF turner_plus.asm -o turner_plus
                            ; z88dk-appmake +hex --code-fence 0x1000 --pad --clean -b turner_plus_code.bin -o turner_plus.hex

ORG $0000

.RST_00
    ld      sp,$1100        ; 8155 RAM $1000 to $1100
    ld      a,$19
    sim                     ; Reset R7.5, Set MSE, and mask R5.5
    ld      a,$01
    out     ($10),a         ; Write $01 to 8155 Command Register -> PA Output / PB Input
    ld      a,$00
    out     ($11),a         ; Write $00 to 8155 PA Register -> FACE (clear PA)
    call    SIGN_ON         ; Write a serial sign on message
    jp      SELECTOR        ; Hardware (switch) selector

ALIGN $0024

.TRAP
    jp      RST_00          ; Reboot if Trap occurs

ALIGN $002C

.RST_55
    jp      RST_00          ; Reboot if R5.5 occurs (even though it is masked)

ALIGN $0034

.RST_65
    jp      COMMAND         ; Use RST 6.5 for serial input or for remote trigger of timed sequence

ALIGN $0038

.RST_70
    jp      RST_00          ; Reboot and recover from reading empty addresses ($FF)

ALIGN $003C

.RST_75
.GO
    ei                      ; Read RST 7.5 for local trigger of timed sequence
    ret
    
ALIGN $0040

    DEFM    "feilipu (c) 2021 Target Turner Plus", 0

ALIGN $0080

.SELECTOR
    in      a,($12)         ; Read 8155 PB (setting of timer wheel & switches)
    cp      $00             ; and depending on value jump to the right delay.
    jp      Z,STANDARD_10
    cp      $01
    jp      Z,STANDARD_20
    cp      $02
    jp      Z,STANDARD_150
    cp      $03
    jp      Z,CENTERFIRE_RAPID
    cp      $04
    jp      Z,RAPID_8
    cp      $05
    jp      Z,RAPID_6
    cp      $06
    jp      Z,RAPID_4
    cp      $10
    jp      Z,SERVICE_165
    cp      $11
    jp      Z,SERVICE_35
    cp      $12
    jp      Z,SERVICE_15
    cp      $13
    jp      Z,SERVICE_6
    cp      $14
    jp      Z,SERVICE_8
    cp      $15
    jp      Z,SERVICE_4
    cp      $16
    jp      Z,SERVICE_15
    jp      RST_00

ALIGN $020

.DELAY                      ; Delay based on BC contents (each 500ms)
    ld      de,$f420
.DELAY_LOOP
    dec     de
    ld      a,d
    or      e
    jp      NZ,DELAY_LOOP
    dec     bc
    ld      a,b
    or      c
    jp      NZ,DELAY
    ret

ALIGN $020

.STANDARD_150_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,STANDARD_150_65  ; if so, wait until it is cleared.

.STANDARD_150
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$012c
    call    DELAY           ; DELAY 150
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      STANDARD_150

ALIGN $020

.STANDARD_20_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,STANDARD_20_65   ; if so, wait until it is cleared.

.STANDARD_20
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$0028
    call    DELAY           ; DELAY 20
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      STANDARD_20

ALIGN $020

.STANDARD_10_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,STANDARD_10_65   ; if so, wait until it is cleared.

.STANDARD_10
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$0014
    call    DELAY           ; DELAY 10
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      STANDARD_10

ALIGN $020

.CENTERFIRE_RAPID_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,CENTERFIRE_RAPID_65  ; if so, wait until it is cleared.

.CENTERFIRE_RAPID
    ei
    halt
    ld      l,$05           ; REPEAT 5x
    ld      a,$ff
.CENTERFIRE_LOOP
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$0006
    call    DELAY           ; DELAY 3
    dec     l
    ld      a,$00
    out     ($11),a         ; FACE (clear PA)
    cp      l
    jp      NZ,CENTERFIRE_LOOP
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      CENTERFIRE_RAPID

ALIGN $020

.SERVICE_165_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,SERVICE_165_65   ; if so, wait until it is cleared.

.SERVICE_165
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$014a
    call    DELAY           ; DELAY 165
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      SERVICE_165

ALIGN $020

.SERVICE_35_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,SERVICE_35_65    ; if so, wait until it is cleared.

.SERVICE_35
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$0046
    call    DELAY           ; DELAY 35
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      SERVICE_35

ALIGN $020

.SERVICE_15_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,SERVICE_15_65    ; if so, wait until it is cleared.

.SERVICE_15
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$001e
    call    DELAY           ; DELAY 15
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      SERVICE_15

ALIGN $020

.SERVICE_6_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,SERVICE_6_65 ; if so, wait until it is cleared.

.SERVICE_6
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$000c
    call    DELAY           ; DELAY 6
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      SERVICE_6

ALIGN $020

.SERVICE_8_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,SERVICE_8_65 ; if so, wait until it is cleared.

.SERVICE_8
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$0010
    call    DELAY           ; DELAY 8
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      SERVICE_8

ALIGN $020

.SERVICE_4_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,SERVICE_4_65 ; if so, wait until it is cleared.

.SERVICE_4
    ei
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$000e
    call    DELAY           ; DELAY 7
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$0008
    call    DELAY           ; DELAY 4
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      bc,$0004
    call    DELAY           ; DELAY 2
    jp      SERVICE_4

ALIGN $020

.RAPID_8_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,RAPID_8_65   ; if so, wait until it is cleared.

.RAPID_8
    ei
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$0002
    call    DELAY           ; DELAY 1
    halt
    ld      bc,$0006
    call    DELAY           ; DELAY 3
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$0010
    call    DELAY           ; DELAY 8
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      bc,$0002
    call    DELAY           ;[0429] cd 90 00    DELAY 1
    jp      RAPID_8         ;[042c] c3 00 04

ALIGN $020

.RAPID_6_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,RAPID_6_65   ; if so, wait until it is cleared.

.RAPID_6
    ei
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$0002
    call    DELAY           ; DELAY 1
    halt
    ld      bc,$0006 
    call    DELAY           ; DELAY 3
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$000c
    call    DELAY           ; DELAY 6
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      bc,$0002
    call    DELAY           ; DELAY 1
    jp      RAPID_6


ALIGN $020

.RAPID_4_65
    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,RAPID_4_65   ; if so, wait until it is cleared.

.RAPID_4
    ei
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) SCORE
    halt
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    ld      bc,$0002
    call    DELAY           ; DELAY 1
    halt
    ld      bc,$0006
    call    DELAY           ; DELAY 3
    ld      a,$00
    out     ($11),a         ; FACE (clear PA) FIRE
    ld      bc,$0008
    call    DELAY           ; DELAY 4
    ld      a,$ff
    out     ($11),a         ; TURN (set PA)
    halt
    ld      bc,$0002
    call    DELAY           ; DELAY 1
    jp      RAPID_4


ALIGN $100
                            ; arrive from R6.5
                            ; look for serial input
                            ; G - execute programmed sequence
                            ; x - decode additional sequence and program it
.COMMAND
    ex      (sp),hl         ; short delay to allow remote RST_65 trigger to reset (no further input)
    ex      (sp),hl
    ex      (sp),hl
    ex      (sp),hl
    ex      (sp),hl
    ex      (sp),hl
    ex      (sp),hl
    ex      (sp),hl

    rim
    and     00100000b       ; check whether R6.5 pin is asserted
    jp      Z,GO            ; if set, check for a character otherwise just GO

    call    CIN             ; read character into C
    call    COUT            ; echo it back as acknowledgement
    ld      a,c
    cp      'G'             ; 0x47
    jp      Z,GO            ; do already programmed timing (trigger timed sequence)

    cp      '@'             ; 0x40
    jp      Z,STANDARD_10_65
    cp      'A'
    jp      Z,STANDARD_20_65
    cp      'B'
    jp      Z,STANDARD_150_65
    cp      'C'
    jp      Z,CENTERFIRE_RAPID_65
    cp      'D'
    jp      Z,RAPID_8_65
    cp      'E'
    jp      Z,RAPID_6_65
    cp      'F'
    jp      Z,RAPID_4_65

    cp      'P'             ; 0x50
    jp      Z,SERVICE_165_65
    cp      'Q'
    jp      Z,SERVICE_35_65
    cp      'R'
    jp      Z,SERVICE_15_65
    cp      'S'
    jp      Z,SERVICE_6_65
    cp      'T'
    jp      Z,SERVICE_8_65
    cp      'U'
    jp      Z,SERVICE_4_65
    cp      'V'
    jp      Z,SERVICE_15_65

    ld      bc,$0001        ; 500ms delay if we don't receive a valid character
    call    DELAY

    rim
    and     00100000b       ; check whether R6.5 pin is still asserted
    jp      NZ,COMMAND      ; if so, check for another character
                            ; otherwise for any other character
    jp      GO              ; just start programmed sequence

ALIGN $020

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

ALIGN $020

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
    ld      hl,(BITTIME)
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

ALIGN $020

.CIN                        ; serial input returns with 8 bits in C
;   di
    push    hl

    ld      b,9             ; 9 bits per byte
.CIN1
    rim
    or      a               ; wait for start bit
    jp      M,CIN1

    ld      hl,(HALFBIT)
.CIN2
    dec     l
    jp      NZ,CIN2
    dec     h
    jp      NZ,CIN2         ; wait until middle of start bit 

.CIN3
    ld      hl,(BITTIME)
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

ALIGN $100

.BITTIME
    DEFW    $0112           ; value for 9600 baud

.HALFBIT
    DEFW    $0109           ; value for 9600 baud
    
.MESSAGE
    DEFM    "\nOPC - Target Turner\n\n", 0

