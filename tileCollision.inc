; PogoPaul is 2 sprites tall by 1 sprite wide, i.e. 32 pixels tall by 16 wide
; a tile is 8x8 pixels
; a standard "char" is 8x8 pixels, 8 bytes
; here we create a bitmap (1 bit per pixel) around PogoPaul
; it would be 4x2 chars but allowing for Paul being "mid-char" we add a
; 1 character buffer making it 5x3 chars * 8 bytes = 120 bytes
tileBmpMap   DEFS 120, 0
yChars       DB 0

hitind  DB 0
hitind1 DB 0
hitRind DB 0
hitLind DB 0

paulTileCollision
        XOR A                               ; no hit
        LD (hitind), A                      ; no hit Y pixel count - bottom
        LD (hitind1), A                     ; no hit Y pixel count - top
        LD (hitRind), A                     ; no hit RHS
        LD (hitLind), A                     ; no hit LHS

        LD A, 5
        LD (yChars), A
        CALL build3x5                       ; build tile bitmap around sprite

        PUSH IX                             ; save pointer to Paul
        CALL testPaulHit                    ; have we hit anything
        POP IX
        RET


testPaulHit
        ; "logically" move Sprite down over the map
        ; depending on Y pixel co-ord, i.e. how far down into the next char
        LD A, (IX +sBalloon.lowY)           ; get the Y pixel coord
        AND %00000111                       ; mask to get portion into next char
        LD D, A                             ; we then multiply by 3 because
        LD E, 3                             ; of starting at the RHS of the
        MUL D, E                            ; 5x3 tile bitmap

        LD HL, tileBmpMap +2                ; point to RHS of the map
        ADD HL, DE                          ; move down DE pixels

        LD A, (IX +sBalloon.lowX)           ; now get the X pixel coord
        AND %00000111                       ; similarly mask of 0-7
        LD B, A                             ; how many pixels into next char across

        LD A, (IX +sBalloon.pattern)        ; get Sprite patten
        CP 0                                ; is it Paul facing right?
        JR Z, testHita                      ; jump if so to facing right routine
        JR   testHitb                       ; jump to facing left routine

testHita
        LD IX, paulbmpR
        LD C, 0
        JR chkLines
testHitb
        LD IX, paulbmpL
        LD C, 0
        JR chkLines

linesToCheck DB 32
chkLines
; on entry here
; B  = sprite bitmap shift
; C  = count of pixel lines tested
; IX = sprite bitmap (ix+0 = lhs, ix+1=rhs, ix+2=filler
; HL = 5 x 3 bitmap map of tiles
        LD D, (IX +1)
; performance improvement
; E will always be 0 in the base bitmap
; we just use it to rotate the RHS byte into something
; for the compare. Saves 19 - 7 * 32 = 384 t-states !
;        LD E, (IX +2)
        LD E, 0
        BSRL DE, B
        LD A, (HL)
        AND E
        CALL NZ, hitR

        LD D, (IX +0)
        LD E, (IX +1)
        BSRL DE, B
        DEC HL
        LD A, (HL)
        AND E
        CALL NZ, hitM
        DEC HL
        LD A, (HL)
        AND D
        CALL NZ, hitL

        LD DE, 3
        ADD IX, DE
        LD A, 5
        ADD HL, A

        INC C
        LD A, C
        CP 32
        JR NZ, chkLines
        RET


itemTileCollision
        PUSH DE
        XOR A
        LD (hitind), A
        LD (hitind1), A
        LD (hitRind), A
        LD (hitLind), A

        LD A, 3
        LD (yChars), A
        CALL build3x5

        PUSH IX

        ; "logically" move Sprite down over the map
        ; depending on Y pixel co-ord, i.e. how far down into the next char
        LD A, (IX +sBalloon.lowY)           ; get the Y pixel coord
        AND %00000111                       ; mask to get portion into next char
        LD D, A                             ; we then multiply by 3 because
        LD E, 3                             ; of starting at the RHS of the
        MUL D, E                            ; 5x3 tile bitmap

        LD HL, tileBmpMap +47               ; point to RHS of the map
        ADD HL, DE                          ; move down DE pixels

        LD A, (IX +sBalloon.lowX)           ; now get the X pixel coord
        AND %00000111                       ; similarly mask of 0-7
        LD B, A                             ; how many pixels into next char across

        LD A, (IX +sBalloon.pattern)
        CP heart
        JR Z, heartCollision
        CP apple
        JR Z, appleCollision
        CP key
        JR Z, keyCollision
        CP points
        JR Z, pointsCollision
        CP dynamite
        JR Z, dynamiteCollision
        JR ITCEnd

heartCollision
        LD IX, heartbmp +45
        LD C, 31
        CALL chkLines
        JR ITCEnd

appleCollision
        LD IX, applebmp +45
        LD C, 31
        CALL chkLines
        JR ITCEnd

keyCollision
        LD IX, keybmp +45
        LD C, 31
        CALL chkLines
        JR ITCEnd

pointsCollision
        LD IX, pointsbmp +45
        LD C, 31
        CALL chkLines
        JR ITCEnd

dynamiteCollision
        LD IX, dynamitebmp +45
        LD C, 31
        CALL chkLines
        JR ITCEnd

ITCEnd
        POP IX
        POP DE
        RET


hitR
; hit here will always be RHS since this is the buffer char
        LD A, (hitind1)
        AND A
        JR NZ, hitR1
        LD A, C
        LD (hitind1), A
hitR1

        LD A, C
        LD (hitind), A
        LD A, 1
        LD (hitRind), A
        RET

hitM
; hit here could be LHS or RHS or BOTH ! depending on shift B
        LD A, B
        CP 4                                ;
        JR NC, hitL
        JR hitR

hitL
; hit here will always be the LHS
        LD A, (hitind1)
        AND A
        JR NZ, hitL1
        LD A, C
        LD (hitind1), A
hitL1
        LD A, C
        LD (hitind), A
        LD A, 1
        LD (hitLind), A
        RET



build3x5
; build a 3x5 bitmap of tilemap data where sprite currently is
; IX = sprite in question

        LD E, (IX +sBalloon.lowX)           ; get X char coord
        LD D, (IX +sBalloon.highX)          ; i.e. X pixel / 8
        LD B, 3
        BSRA DE,B
        LD B, E                             ; B = X pixel / 8

        LD A, (IX +sBalloon.lowY)           ; get Y char coord
        SRL A                               ; i.e. Y pixel / 8
        SRL A
        SRL A                               ; A = Y pixel / 8

        LD E, A
        LD D, 40

        MUL D, E                            ; Y * 40
        LD A, B                             ; + X
        ADD DE, A                           ; hence DE= tilemap offset

        LD IY, tileMapData                  ; base of tilemap
        ADD IY, DE                          ; add our offset for Paul

        LD C, 3                             ; const to move down a pixel line
        LD B, 3                             ; 3 chars across
        LD A, (yChars)
        LD E, A                             ; by 5 chars down
        LD HL, tileBmpMap                   ; point to base of 5x3 map

b3x5loop:
        PUSH DE                             ; save the char down counter
        PUSH HL                             ; save the tileBmpMap pointer

        LD A, (IY +0)                       ; get tile here
        LD DE, tilebmp                      ; get base of udgs for tiles
        ADD A, A                            ; multiply by 8
        ADD A, A                            ; to point to udg we want
        ADD A, A
        ADD DE, A                           ; DE now points to UDG

        LD A, (DE)                          ; get pixel line 1
        LD (HL), A                          ; put in map
        INC DE                              ; next pixel line down
        LD A, C                             ; ready to pixel line down in map
        ADD HL, A                           ; do it

        LD A, (DE)                          ; same for pixel line 2
        LD (HL), A
        INC DE
        LD A, C
        ADD HL, A

        LD A, (DE)                          ; same for pixel line 3
        LD (HL), A
        INC DE
        LD A, C
        ADD HL, A

        LD A, (DE)                          ; same for pixel line 4
        LD (HL), A
        INC DE
        LD A, C
        ADD HL, A

        LD A, (DE)                          ; same for pixel line 5
        LD (HL), A
        INC DE
        LD A, C
        ADD HL, A

        LD A, (DE)                          ; same for pixel line 6
        LD (HL), A
        INC DE
        LD A, C
        ADD HL, A

        LD A, (DE)                          ; get pixel line 7
        LD (HL), A                          ; put in map
        INC DE                              ; next pixel line down
        LD A, C                             ; ready to pixel line down in map
        ADD HL, A                           ; do it

        LD A, (DE)                          ; pixel line 8
        LD (HL), A

        POP HL                              ; restore BmpMap pointer
        POP DE                              ; restore char down counter
        INC IY                              ; point to next tile
        INC HL                              ; point to next pos in map
        DJNZ b3x5loop                       ; loop for 3 chars

        LD BC, 37
        ADD IY, BC
        LD A, 21
        ADD HL, A
        LD B, 3
        LD C, 3
        DEC E
        JR NZ, b3x5loop

        RET
