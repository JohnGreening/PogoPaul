showSP
        LD A, (IX +strucBalloon.index)      ; get the sprite index
        NEXTREG $34, A                  ; set sprite to activate

        LD A, (IX +strucBalloon.lowX)       ; get sprite X lsb
        NEXTREG $35, A                  ; set attr byte 0 of port $0057

        LD A, (IX +strucBalloon.lowY)       ; get sprite Y lsb
        NEXTREG $36, A                  ; set attr byte 1 of port $0057

        LD A, (IX +strucBalloon.highX)      ; get sprite X msb
        AND 1                           ; only need bit 0 of X msb
        NEXTREG $37, A                  ; bits 7-4 palette offset
                                        ;        3 1=enable X mirroring
                                        ;        2 1=enable Y mirroring
                                        ;        1 1=rotate 90 clockwise
                                        ;        0 msb of X
                                        ; this is attr byte 2 of port $0057
        LD A, (IX +strucBalloon.pattern)    ; get pattern index to use
        OR %11000000                    ;
;        OR %10000000                   ;

        NEXTREG $38, A                  ; bits 7 1=make sprite visible
                                        ;      6 1=enable optional attr byte 4
                                        ;      5-0 pattern 0-63, 7th bit in byte 4

        LD A, %00100000                 ; bits 7-6 00 = anchor sprite 8 bit (01=rel)
                                        ; bit    5 1=unified, 0=composite
                                        ; bits 4-3 X axis scale
                                        ; bits 2-1 Y axis scale
                                        ; bit    0 msb of Y coord
        NEXTREG $39, A                  ;
        RET

showSP1
        LD A, (IX +strucBalloon.index)      ; get the sprite index
        NEXTREG $34, A                  ; set sprite to activate
        LD A, (IX +strucBalloon.lowX)       ; get sprite X lsb
        NEXTREG $35, A                  ; set attr byte 0 of port $0057
        LD A, (IX +strucBalloon.lowY)       ; get sprite Y lsb
        NEXTREG $36, A                  ; set attr byte 1 of port $0057
        LD A, (IX +strucBalloon.highX)      ; get sprite X msb
        AND 1                           ; only need bit 0 of X msb
        NEXTREG $37, A                  ; bits 7-4 palette offset

        LD A, (IX +strucBalloon.pattern)    ; get pattern index to use

        OR %10000000                    ;
        NEXTREG $38, A                  ; bits 7 1=make sprite visible
        RET

showManRels
        LD A, (IX +strucBalloon.index)      ; set first RELATIVE sprite
        INC A
        NEXTREG $34, A                  ; set sprite to activate

        LD A, 0                         ; X offset from ANCHOR sprite is 0
        NEXTREG $35, A                  ; set attr byte 0 of port $0057

        LD A, 16                        ; Y offset from ANCHOR sprite is 16
        NEXTREG $36, A                  ; set attr byte 1 of port $0057

        LD A, 1                         ; use ANCHOR palette offset
        NEXTREG $37, A                  ; set attr byte 2 of port $0057

        LD A, %11000001                 ; set visible and enable byte 4, patt offset 1
        NEXTREG $38, A                  ; set attr byte 3 of port $0057

        LD A, %01000001                 ; set as RELATIVE and use relative pattern
        NEXTREG $39, A                  ; set attr byte 4 of port $0057

        RET
