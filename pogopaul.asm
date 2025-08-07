device ZXSPECTRUMNEXT

INCLUDE "myMacros.inc"
INCLUDE "c.inc"
INCLUDE "globals.inc"
INCLUDE "initialisation.inc"
INCLUDE "melody.inc"
INCLUDE "utilities.inc"
INCLUDE "levelSetup.inc"
INCLUDE "ingameRoutines.inc"
INCLUDE "soundEffects.inc"
INCLUDE "updateBalloons.inc"
INCLUDE "updatePaul.inc"

; ----------------------------
; Game Initialization
; ----------------------------
MAINPROG
; this stuff is only called ONCE
;        NEXTREG $7, 2                       ; set speed to 14mhz
        CALL spriteSetup                    ; initialise graphics in c.odn
        LD HL, $5c78                        ; frame counter for rnd seed
        LD A, (HL)
        LD (LFSRSeed), A
        INC HL
        LD A, (HL)
        LD (LFSRSeed+1), A

        CALL setupIM2
        CALL buildbmp                       ; build 1bit bitmaps for collision
        CALL convertChars                   ; generate char tiles (86-127)


; ----------------------------
; main game start
; ----------------------------
GameStart:
        CALL newGame                ; game start from scratch

RestartLevel:
        CALL restartGame

; ----------------------------
; Main Game Loop
; ----------------------------
MainLoop:
        CALL showPaul
        JR C, HandleDeath

        CALL balloonUpt

        CALL showPaul
        JR C, HandleDeath

        HALT

        ; Check if Paul reached the exit
        LD HL, (spriteX)
        LD A, H
        CP 1
        JR NZ, CheckPause
        LD A, L
        CP 40
        JR C, CheckPause

        CALL levelUp
        JR MainLoop

; ----------------------------
; Pause Handling (H key)
; ----------------------------
CheckPause:
        LD BC, $bffe                ; key group with H
        IN A, (C)
        AND %00010000               ; bit 4 = H
        JR NZ, CheckExit

PauseLoop:
        HALT
        IN A, (C)
        AND %00010000
        JR NZ, PauseLoop            ; wait until H pressed again

; ----------------------------
; Exit Handling (X key)
; ----------------------------
CheckExit:
        LD BC, $fefe                ; key group: shift, Z, X, C, V
        IN A, (C)
        AND %00000100               ; bit 2 = X
        JR NZ, MainLoop             ; X not pressed → continue game
        JR EndProgram               ; X pressed → end program

; ----------------------------
; Paul Died: Lose a life
; ----------------------------
HandleDeath:
        LD A, (lives)
        DEC A
        LD (lives), A
        JR NZ, RestartLevel         ; still have lives → retry level
        JR GameStart                ; no lives → new game

; ----------------------------
; Program End
; ----------------------------
EndProgram:
        CALL endProg
        NEXTREG $7, 0                   ; set speed to 3.5mhz
        IM 1
        RET


showSP
        LD A, (IX +sBalloon.index)      ; get the sprite index
        NEXTREG $34, A          ; set sprite to activate

        LD A, (IX +sBalloon.lowX)     ; get sprite X lsb
        NEXTREG $35, A          ; set attr byte 0 of port $0057

        LD A, (IX +sBalloon.lowY)     ; get sprite Y lsb
        NEXTREG $36, A          ; set attr byte 1 of port $0057

        LD A, (IX +sBalloon.highX)    ; get sprite X msb
        AND 1                   ; only need bit 0 of X msb
        NEXTREG $37, A          ; bits 7-4 palette offset
                                ;        3 1=enable X mirroring
                                ;        2 1=enable Y mirroring
                                ;        1 1=rotate 90 clockwise
                                ;        0 msb of X
                                ; this is attr byte 2 of port $0057
        LD A, (IX +sBalloon.pattern)      ; get pattern index to use
        OR %11000000            ;
;        OR %10000000            ;

        NEXTREG $38, A          ; bits 7 1=make sprite visible
                                ;      6 1=enable optional attr byte 4
                                ;      5-0 pattern 0-63, 7th bit in byte 4

        LD A, %00100000         ; bits 7-6 00 = anchor sprite 8 bit (01=rel)
                                ; bit    5 1=unified, 0=composite
                                ; bits 4-3 X axis scale
                                ; bits 2-1 Y axis scale
                                ; bit    0 msb of Y coord
        NEXTREG $39, A          ;
        RET

showSP1
        LD A, (IX +sBalloon.index)    ; get the sprite index
        NEXTREG $34, A          ; set sprite to activate
        LD A, (IX +sBalloon.lowX)     ; get sprite X lsb
        NEXTREG $35, A          ; set attr byte 0 of port $0057
        LD A, (IX +sBalloon.lowY)     ; get sprite Y lsb
        NEXTREG $36, A          ; set attr byte 1 of port $0057
        LD A, (IX +sBalloon.highX)    ; get sprite X msb
        AND 1                   ; only need bit 0 of X msb
        NEXTREG $37, A          ; bits 7-4 palette offset

        LD A, (IX +sBalloon.pattern)      ; get pattern index to use

        OR %10000000            ;
        NEXTREG $38, A          ; bits 7 1=make sprite visible
        RET

showManRels
        LD A, (IX +sBalloon.index)    ; set first RELATIVE sprite
        INC A
        NEXTREG $34, A          ; set sprite to activate

        LD A, 0                 ; X offset from ANCHOR sprite is 0
        NEXTREG $35, A          ; set attr byte 0 of port $0057

        LD A, 16                ; Y offset from ANCHOR sprite is 16
        NEXTREG $36, A          ; set attr byte 1 of port $0057

        LD A, 1                 ; use ANCHOR palette offset
        NEXTREG $37, A          ; set attr byte 2 of port $0057

        LD A, %11000001         ; set visible and enable byte 4, patt offset 1
        NEXTREG $38, A          ; set attr byte 3 of port $0057

        LD A, %01000001         ; set as RELATIVE and use relative pattern
        NEXTREG $39, A          ; set attr byte 4 of port $0057

        RET

DispA
; pass IY with location to display A
; routine will display A (retained)
        PUSH HL
        PUSH BC
        PUSH AF
        LD H, 0
        LD L, A
        CALL DispA3Digit
        POP AF
        POP BC
        POP HL
        RET
DispA1
        PUSH AF
        LD H, 0
        LD L, A
        CALL DispA1Digit
        POP AF
        RET
DispA2
        PUSH AF
        LD H, 0
        LD L, A
        CALL DispA2Digit
        POP AF
        RET

DispIX
; pass IY with location to display IX
; routine will display IX (retained)
        PUSH HL
        PUSH BC
        PUSH AF
        PUSH IX

        PUSH IX
        POP HL
        CALL DispHL1
        POP IX
        POP AF
        POP BC
        POP HL
        RET

DispHL
; pass IY with location to display HL
; routine will display HL (retained)
        PUSH HL
        PUSH BC
        PUSH AF
        CALL DispHL1
        POP AF
        POP BC
        POP HL
        RET

DispHL1
             LD BC, -10000
             CALL num1
             LD BC, -1000
             CALL num1
DispA3Digit                                 ; use this for 3 digits
             LD BC, -100
             CALL num1
DispA2Digit
             LD BC, -10
             CALL num1
DispA1Digit                                 ; use this for 1 digit
             LD BC, -1
num1
;            114 is the tilemap for 0
             LD A, 112 -1
num2
             INC A
             ADD HL, BC
             JR C, num2
             SBC HL, BC

             LD (IY), A
             INC IY
             RET

DispT
; pass IY pointing to text to display
; format is Y, X, "text", $FF
; full ZX Spectrum char set used
             LD A, (IY)         ; get the Y line
             LD D, A            ; put in D
             LD E, 40           ; get ready to multiply by 40 (chars per line)
             MUL D,E            ; do it
             INC IY             ; point to X row
             LD A, (IY)         ; get it
             ADD DE, A          ; add to result
             LD HL, tileMapData ; tilemap
             ADD HL, DE         ; point to char position
DispT1
             INC IY             ; point to character to print
             LD A, (IY)         ; get it
             CP $ff             ; are we finished
             RET Z              ; exit if so
DispTAlpha
             CP " "
             JR Z, charSpace
             CP 128
             JR NC, showTile
             LD C, A
             LD DE, charSet
             LD B, 0
searchChar
             LD A, (DE)
             CP 255
             JR Z, charNotFound
             CP C
             JR Z, charFound
             INC DE
             INC B
             JR searchChar

charSpace
             LD A, 0
             JR DispT2
showTile
             SUB 128
             JR DispT2
charNotFound
             LD A, lastTile
             JR DispT2
charFound
             LD A, B
             ADD charStart
DispT2
             LD (HL), A         ; put tile A in HL
             INC HL             ; point to next tile
             JR DispT1          ; and repeat

charStart EQU 86
lastTile  EQU 127

charSet
;     86,  87,  88,  89,  90,  91,  92,  93,  94,  95,  96,  97,  98,  99
DB "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"

;    100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111
DB "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"

;    112, 113, 114, 115, 116, 117, 118, 119, 120, 121
DB "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"

;    122  123, 124, 125, 126, 127
DB ".", ",", "'", "!", ":", "?"
DB 255



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
        XOR A                             ; no hit
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
        LD A, (IX +sBalloon.lowY)             ; get the Y pixel coord
        AND %00000111                   ; mask to get portion into next char
        LD D, A                         ; we then multiply by 3 because
        LD E, 3                         ; of starting at the RHS of the
        MUL D, E                        ; 5x3 tile bitmap

        LD HL, tileBmpMap +2            ; point to RHS of the map
        ADD HL, DE                      ; move down DE pixels

        LD A, (IX +sBalloon.lowX)             ; now get the X pixel coord
        AND %00000111                   ; similarly mask of 0-7
        LD B, A                         ; how many pixels into next char across

        LD A, (IX +sBalloon.pattern)              ; get Sprite patten
        CP 0                            ; is it Paul facing right?
        JR Z, testHita                  ; jump if so to facing right routine
        JR   testHitb                  ; jump to facing left routine

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
        LD A, (IX +sBalloon.lowY)             ; get the Y pixel coord
        AND %00000111                   ; mask to get portion into next char
        LD D, A                         ; we then multiply by 3 because
        LD E, 3                         ; of starting at the RHS of the
        MUL D, E                        ; 5x3 tile bitmap

        LD HL, tileBmpMap +47           ; point to RHS of the map
        ADD HL, DE                      ; move down DE pixels

        LD A, (IX +sBalloon.lowX)             ; now get the X pixel coord
        AND %00000111                   ; similarly mask of 0-7
        LD B, A                         ; how many pixels into next char across

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

        LD E, (IX +sBalloon.lowX)                 ; get X char coord
        LD D, (IX +sBalloon.highX)                ; i.e. X pixel / 8
        LD B, 3
        BSRA DE,B
        LD B, E                             ; B = X pixel / 8

        LD A, (IX +sBalloon.lowY)                 ; get Y char coord
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
        ADD A, A                               ; multiply by 8
        ADD A, A                               ; to point to udg we want
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

chkCollide
; get Paul's 1bit bitmap depending on his direction
        LD IX, manSprite
        LD A, (IX +sBalloon.pattern)
        AND A
        JR Z, cMBM1
        JR cMBM2
cMBM1
        LD HL, paulbmpR
        LD (manBitmap), HL
        JR chkCollide1
cMBM2
        LD HL, paulbmpL
        LD (manBitmap), HL

chkCollide1
; point to start of balloon data
        LD IX, balloonSpr

chkSprite
; for each "balloon" or until collision is detected
; - reset collision ind (0=no hit, 1=hit)
; - exit if end marker
; - call collision check routine
; - check if collision and loop if not, otherwise return IX = balloon hit
        XOR A
        LD (collisionInd), A

        LD A, (IX +sBalloon.pattern)
        CP 255
        RET Z

        PUSH IX
        CALL chkSprite1
        POP IX

        LD A, (collisionInd)
        AND A
        RET NZ
        LD DE, sBalloon
        ADD IX, DE
        JR chkSprite

chkSprite1
        CP blank
        RET Z

; point to collideAction table and pick up routine to jump to in DE/HL
; and the "balloon" bitmap to use in BC
        ADD A, A
        ADD A, A
        LD HL, collideAction
        ADD HL, A
        LD E, (HL)
        INC HL
        LD D, (HL)
        INC HL
        LD C, (HL)
        INC HL
        LD B, (HL)
        EX DE, HL

        JP (HL)

collideSkull
        CALL CS1
        LD A, (collisionInd)
        AND A
        RET Z

        LD A, soundHitskull
        CALL playsound
        LD A, (healthDelay)
        DEC A
        LD (healthDelay), A
        RET NZ
        LD A, (healthDefault)
        LD (healthDelay), A
        LD A, (health)
        DEC A
        LD (health), A
        RET

collideHeart
        CALL CS1
        LD A, (collisionInd)
        AND A
        RET Z

        LD A, 15
        LD (health), A
        LD A, (lives)
        INC A
        LD (lives), A
        CALL showLives
        JP itemCollideCommon

collideApple
        CALL CS1
        LD A, (collisionInd)
        AND A
        RET Z

        LD A, 15
        LD (health), A
        JP itemCollideCommon

collideKey
        CALL CS1
        LD A, (collisionInd)
        AND A
        RET Z

        LD A, 1
        LD (keyCnt), A
        CALL showKey
        JP itemCollideCommon

collidePoints
        CALL CS1
        LD A, (collisionInd)
        AND A
        RET Z

        LD HL, (score)
        ADD HL, 100
        LD (score), HL
        CALL showScore
        JP itemCollideCommon

collideDynamite
        CALL CS1
        LD A, (collisionInd)
        AND A
        RET Z

        LD A, 1
        LD (dynamiteCnt), A
        CALL showDynamite
        JP itemCollideCommon

collideBalloon
        CALL CS1
        LD A, (collisionInd)
        AND A
        RET Z

        LD HL, (score)
        ADD HL, 50
        LD (score), HL
        CALL showScore
        LD A, soundPop
        CALL playsound

        LD IY, (collisionInx)
        LD A, balloon +1
        JR itemHitCommon

itemCollideCommon
        LD A, soundCollect
        CALL playsound
        LD IY, (collisionInx)
        LD A, blank
        LD (IY +sBalloon.newSprite), A
itemHitCommon
        LD (IY +sBalloon.pattern), A
        XOR A
        LD (IY +sBalloon.popDelayH), A
        LD A, 15
        LD (IY +sBalloon.popDelayL), A
        AND A
        RET

noAction
        RET

CS1
        LD (spriteBitmap), BC               ; save off location of 1bit bitmap
        LD (collisionInx), IX               ; and the balloon in question
doYDiff
        LD A, (spriteY)                     ; get Paul's Y coord
        LD B, (IX +sBalloon.lowY)                 ; get Balloon Y coord
        SUB B                               ; A= Paul Y - Balloon Y
        JR C, spriteBelowPaul               ; if carry BalloonY > Paul Y

spriteAbovePaul
        ; Balloon Y <= Paul Y, i.e. +ve diff
        ; exit if there is no overlap
        CP 16
        RET NC

        ; we only want to test for a hit on the overlap pixels
        ; the bitmap is 3 bytes per pixel line
        ; C is calculated as the number of lines to test
        LD HL, (spriteBitmap)
        LD D, A
        LD E, 3
        MUL D, E
        ADD HL, DE
        LD (spriteBitmap), HL
        LD C, A
        LD A, 16
        SUB C
        LD C, A
        JP doXDiff

spriteBelowPaul
        ; Balloon Y > Paul Y, i.e. -ve diff
        ; exit if there is no overlap
        ; Paul is 32 pixels tall and might be fully or partially overlapped
        NEG 
        CP 32
        RET NC

        ; we only want to test for a hit on the overlap pixels
        ; the bitmap is 3 bytes per pixel line
        ; C is calculated as the number of lines to test
        LD HL, (manBitmap)
        LD D, A
        LD E, 3
        MUL D, E
        ADD HL, DE
        LD (manBitmap), HL
        LD C, 16
        CP 16
        JR NC, doXDiff
        LD C, A
        LD A, 32
        SUB C
        LD C, A

doXDiff
        LD HL, (spriteX)
        LD E, (IX +sBalloon.lowX)
        LD D, (IX +sBalloon.highX)
        SBC HL, DE
        BIT 7, H
        JR Z, balloonLeftOfPaul

balloonRightOfPaul
        ; balloon X > Paul X
        ; hence -ve diff and bit 7 of H was set
        CALL absHL
        CP 16
        RET NC

        LD B, A
        LD IX, (manBitmap)
        LD IY, (spriteBitmap)
BROP
        LD H, (IX +0)
        LD L, (IX +1)
        LD D, (IY +0)
        LD E, (IY +1)
        BSRA DE, B
        LD A, H
        AND D
        JR NZ, myhit
        LD A, L
        AND E
        JR NZ, myhit
        LD DE, 3
        ADD IX, DE
        ADD IY, DE
        DEC C
        JR NZ, BROP
        RET

balloonLeftOfPaul
        ; balloon X <= Paul X
        ; hence +ve diff and bit 7 of H was 0
        CALL absHL
        CP 16
        RET NC

        LD B, A
        LD IX, (manBitmap)
        LD IY, (spriteBitmap)
BLOP
        LD H, (IX +0)
        LD L, (IX +1)
        LD D, (IY +0)
        LD E, (IY +1)
        BSLA DE, B
        LD A, H
        AND D
        JR NZ, myhit
        LD A, L
        AND E
        JR NZ, myhit
        LD DE, 3
        ADD IX, DE
        ADD IY, DE
        DEC C
        JR NZ, BLOP
        RET

myhit
        LD A, 1
        LD (collisionInd), A
        RET

absHL
        ; dirty routine to return ABS(HL)
        ; L returned as result or 255 if clearly out of range
        XOR A                               ; zero A and clear carry flag
        BIT 7, H                            ; was subtraction -ve
        JR Z, absHL1                        ; branch if not
        SUB L                               ; do ABS(HL)
        LD L, A
        SBC A, A
        SUB H
        LD H, A
absHL1
        LD A, H                             ; get high byte and hence see if
        AND A                               ; result was > 255
        JR Z, absHL2                        ; branch if not
        LD L, 255                           ; set a dummy value
absHL2
        LD A, L                             ; return L
        RET



manBitmap    DW 00              ; location of our man bitmap
spriteBitmap DW 00              ; location of sprite bitmap being checked
collisionInd DB 0
collisionInx DW $00

collideAction
DW noAction, $00                            ; sprite  0
DW noAction, $00                            ; sprite  1
DW noAction, $00                            ; sprite  2
DW noAction, $00                            ; sprite  3
DW collideSkull, skullbmp                   ; skull
DW noAction, $00                            ; sprite  5
DW noAction, $00                            ; sprite  6
DW noAction, $00                            ; sprite  7
DW collideBalloon, balloonbmp               ; balloon
DW noAction, $00                            ; sprite  9
DW noAction, $00                            ; sprite 10
DW noAction, $00                            ; sprite 11
DW noAction, $00                            ; sprite 12
DW collideHeart, heartbmp                   ; heart landed
DW noAction, $00                            ; sprite 14
DW noAction, $00                            ; sprite 15
DW noAction, $00                            ; sprite 16
DW collideApple, applebmp                   ; apple landed
DW noAction, $00                            ; sprite 18
DW noAction, $00                            ; sprite 19
DW noAction, $00                            ; sprite 20
DW collideKey, keybmp                       ; key landed
DW noAction, $00                            ; sprite 22
DW noAction, $00                            ; sprite 23
DW noAction, $00                            ; sprite 24
DW collidePoints, pointsbmp                 ; points landed
DW noAction, $00                            ; sprite 26
DW noAction, $00                            ; sprite 27
DW noAction, $00                            ; sprite 28
DW collideDynamite, dynamitebmp             ; dynamite landed
DW noAction, $00                            ; sprite 30
DW noAction, $00                            ; sprite 31
DW noAction, $00                            ; sprite 32
DW CS1, toxicbmp                            ; toxic drop




setupIM2:
; sub routine to set-up IM2 to point to BB
        DI 
        LD HL, IM2Tab
        LD DE, IM2Tab +1
        LD A, H
        LD I , A
        LD A, $f0
        LD (HL), A
        LD BC, 256
        LDIR 

        IM 2
        EI
        RET

; Align 256
DEFS -$&$FF
IM2Tab:
        DEFS 257, 0

ORG $f0f0
im2Routine
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL


; this is the IM2 routine
; gets called every 1/50 second, i.e. 20ms
; push/pop are in main program


        LD C, AYPortC              ; shared port for AY chip access

; select AY1
        LD B, AYPortSelectB              ; AYSelect
        LD A, 255
        OUT (C), A

; get the Ch1 tone value
; apply delta
        LD HL, (Ch1Pitch)
        LD DE, (Ch1PitchD)
        ADD HL, DE
        LD (Ch1Pitch), HL

; write Ch1 tone to AY chip
        LD B, AYPortSelectB             ; AYSelect
        LD A, channel1ToneL
        OUT (C), A
        LD B, AYPortWriteB              ; AYrw
        OUT (C), L

        LD B, AYPortSelectB
        LD A, channel1ToneH
        OUT (C), A
        LD B, AYPortWriteB
        OUT (C), H

; get the Ch1 volume value
; apply delta
        LD HL, (Ch1Volume)
        LD DE, (Ch1VolumeD)
        ADD HL, DE
        LD (Ch1Volume), HL

        LD A, H
        AND 15

; write Ch1 volume to AY chip
        LD B, AYPortSelectB
        LD H, channel1Volume
        OUT (C), H
        LD B, AYPortWriteB
        OUT (C), A

; get the Ch2 tone value
; apply delta
        LD HL, (Ch2Pitch)
        LD DE, (Ch2PitchD)
        ADD HL, DE
        LD (Ch2Pitch), HL

; write Ch2 tone to AY chip
        LD B, AYPortSelectB
        LD A, channel2ToneL
        OUT (C), A
        LD B, AYPortWriteB
        OUT (C), L

        LD B, AYPortSelectB
        LD A, channel2ToneH
        OUT (C), A
        LD B, AYPortWriteB
        OUT (C), H

; get the Ch2 volume value
; apply delta
        LD HL, (Ch2Volume)
        LD DE, (Ch2VolumeD)
        ADD HL, DE
        LD (Ch2Volume), HL

        LD A, H
        AND 15

; write Ch2 volume to AY chip
        LD B, AYPortSelectB
        LD H, channel2Volume
        OUT (C), H
        LD B, AYPortWriteB
        OUT (C), A

; get the Ch3 tone value
; apply delta
        LD HL, (Ch3Pitch)
        LD DE, (Ch3PitchD)
        ADD HL, DE
        LD (Ch3Pitch), HL

; write Ch3 tone to AY chip
        LD B, AYPortSelectB
        LD A, channel3ToneL
        OUT (C), A
        LD B, AYPortWriteB
        OUT (C), L

        LD B, AYPortSelectB
        LD A, channel3ToneH
        OUT (C), A
        LD B, AYPortWriteB
        OUT (C), H

; get the Ch3 volume value
; apply delta
        LD HL, (Ch3Volume)
        LD DE, (Ch3VolumeD)
        ADD HL, DE
        LD (Ch3Volume), HL

        LD A, H
        AND 15

; write Ch3 volume to AY chip
        LD B, AYPortSelectB
        LD H, channel3Volume
        OUT (C), H
        LD B, AYPortWriteB
        OUT (C), A

; set the AY mixer value depending on ch1Flags, ch2Flags & ch3Flags
; these control the tone and noise flags in main AY mixer setting
; mapping is as follows and we negate the Ch1/2/3Flag setting
; Ch1Flags
; bit
; 0 -> 0
; 1 -> 3
; Ch2Flags
; 0 -> 1
; 1 -> 4
; Ch3Flags
; 0 -> 2
; 1 -> 5
        LD C, 255                               ; initialise to all 1's, everything off
        LD HL, mixerFlags                       ; point to mapping data for Ch1Flags
        LD A, (Ch1Flags)                        ; get Ch1Flags setting
        AND %00000011                           ; we're only interested in bits 0,1
        ADD HL, A                               ; offset into mixerFlags mapping
        LD A, (HL)                              ; get value
        AND C                                   ; AND with existing
        LD C, A                                 ; store back

        LD HL, mixerFlags +4
        LD A, (Ch2Flags)
        AND %00000011
        ADD HL, A
        LD A, (HL)
        AND C
        LD C, A
        LD HL, mixerFlags +8
        LD A, (Ch3Flags)
        AND %00000011
        ADD HL, A
        LD A, (HL)
        AND C
        LD BC, AYSelect
        LD D, mixerFlag
        OUT (C), D
        LD BC, AYrw
        OUT (C), A
        
        LD A, (Ch1Length)
        DEC A
        JR NZ, ch1endskip
        LD (Ch1Flags), A
        LD HL, 0
        LD (Ch1Volume), HL
        LD (Ch1VolumeD), HL
ch1endskip
        LD (Ch1Length), A

        LD A, (Ch2Length)
        DEC A
        JR NZ, ch2endskip
        LD (Ch2Flags), A
        LD HL, 0
        LD (Ch2Volume), HL
        LD (Ch2VolumeD), HL
ch2endskip
        LD (Ch2Length), A

        LD A, (Ch3Length)
        DEC A
        JR NZ, ch3endskip
        LD (Ch3Flags), A
        LD HL, 0
        LD (Ch3Volume), HL
        LD (Ch3VolumeD), HL
ch3endskip
        LD (Ch3Length), A


melodyRoutine
        LD A, (frameCount)                  ; pick up remaining note time
        DEC A                               ; decrease by 1 frame
        LD (frameCount), A                  ; save it back
        JP NZ, melodyEnd                    ; branch to end if not zero

        ; timer expired, so pick up next note to play
        ; - first set timer for this new note
mr0
        LD HL, (framePointer)               ; framePointer = timer table
        LD A, (HL)                          ; get note length

        INC HL                              ; skip past high byte
        CP 255                              ; is it 255 marker
        JR NZ, mr1                          ; branch if not

        LD HL, frameTable                   ; point to table start
        LD (framePointer), HL               ; save in framePointer
        JR mr0                              ; and test again !
mr1
        LD (frameCount), A                  ; save note length

        ; - point to the note, save in DE and update
        ;   framePointer for next time
        INC HL                              ; point to note data
        LD E, (HL)                          ; get low byte
        INC HL                              ; point to high byte
        LD D, (HL)                          ; get the high byte
        INC HL                              ; point to next timer entry
        LD (framePointer), HL               ; and save in framePointer

playNotes
        ld c, AYPortC

        ; -------------------- AY2 --------------------
        LD A, 254
        LD B, AYPortSelectB
        OUT (C), A

        ; Tone A
        XOR A
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        LD A, 1
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Volume A
        LD A, 8
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        AND %00000001
        LD H, A
        LD A, (volume)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Tone B
        LD A, 2
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        LD A, 3
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Volume B
        LD A, 9
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        AND %00000010
        OR H
        LD H, A
        LD A, (volume)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Tone C
        LD A, 4
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        LD A, 5
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Volume C
        LD A, 10
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        AND %00000100
        OR H
        LD H, A
        LD A, (volume)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Mixer
        LD A, 7
        LD B, AYPortSelectB
        OUT (C), A
        LD A, H
        XOR %11111111
        LD B, AYPortWriteB
        OUT (C), A

        ; -------------------- AY3 --------------------
        LD A, 253
        LD B, AYPortSelectB
        OUT (C), A

        ; Tone A
        XOR A
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        LD A, 1
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Volume A
        LD A, 8
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        AND %00000001
        LD H, A
        LD A, (volume)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Tone B
        LD A, 2
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        LD A, 3
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Volume B
        LD A, 9
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        AND %00000010
        OR H
        LD H, A
        LD A, (volume)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Tone C
        LD A, 4
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        LD A, 5
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        INC DE
        LD B, AYPortWriteB
        OUT (C), A

        ; Volume C
        LD A, 10
        LD B, AYPortSelectB
        OUT (C), A
        LD A, (DE)
        AND %00000100
        OR H
        LD H, A
        LD A, (volume)
        LD B, AYPortWriteB
        OUT (C), A

        ; Mixer
        LD A, 7
        LD B, AYPortSelectB
        OUT (C), A
        LD A, H
        XOR %11111111
        LD B, AYPortWriteB
        OUT (C), A

melodyEnd
        POP HL
        POP DE
        POP BC
        POP AF

        EI
        RETI 

frameCount   DB $01                         ; interrupt count for note set
framePointer DW frameTable                  ; pointer to the ic and note set
volume       DB %00001111                   ; volume

length EQU $ - $6000
SAVEBIN "pogopaul.bin", $6000, length

SAVENEX OPEN "pogopaul.nex", MAINPROG, $FF40
;SAVENEX CORE 2, 0, 0
;SAVENEX CFG 7, 0, 0, 0
SAVENEX AUTO
SAVENEX CLOSE

