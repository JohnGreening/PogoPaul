chkSpriteCollision
; get Paul's 1bit bitmap depending on his direction
        LD A, (manPat)                      ; get current sprite pattern
        LD HL, paulbmpL                     ; default 1bit bitmap to Paul facing left
        AND A                               ; test current sprite pattern
        JR NZ, storePaulbmp                 ; branch if facing left 
        LD HL, paulbmpR                     ; otherwise set 1bit bitmap to Paul facing right
storePaulbmp
        LD (manBitmap), HL                  ; store correct 1bit bitmap

chkCollide1
; point to start of balloon data
        LD IX, balloonSpr

chkSprite
; for each "balloon" or until collision is detected
; - exit if end marker
; - call collision check routine
; - check if collision (carry set) and loop if not, otherwise return IX = balloon hit

        LD A, (IX +strucBalloon.pattern)
        CP 255
        RET Z

        CP Sblank
        CALL NZ, chkSprite1
        RET C                               ; exit if carry, i.e. hit detected
        
        LD DE, strucBalloon
        ADD IX, DE
        JR chkSprite

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
DW noAction, $00                            ; dynamite landed
DW noAction, $00                            ; sprite 30
DW noAction, $00                            ; sprite 31
DW noAction, $00                            ; sprite 32
DW CS1, toxicbmp                            ; toxic drop

;--------------------------------------------------------------------------
; A is passed with "balloon" sprite pattern to check against
chkSprite1

; point to collideAction table and pick up routine to jump to in DE/HL
; and the "balloon" bitmap to use in BC
        ADD A, A
        ADD A, A
        LD HL, collideAction
        ADD HL, A

        ; get into DE the routine to call
        ; get into BC the 1 bit bitmap to use
        LD E, (HL)
        INC HL
        LD D, (HL)
        INC HL
        LD C, (HL)
        INC HL
        LD B, (HL)

        ; swap DE and HL to do the jump to routine
        EX DE, HL
        JP (HL)

collideSkull
        CALL CS1
        RET NC

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
        RET NC

        LD A, 15
        LD (health), A
        LD A, (lives)
        INC A
        LD (lives), A
        CALL showLives
        JP itemCollideCommon

collideApple
        CALL CS1
        RET NC

        LD A, 15
        LD (health), A
        JP itemCollideCommon

collideKey
        CALL CS1
        RET NC

        LD A, 1
        LD (keyCnt), A
        CALL showKey
        JP itemCollideCommon

collidePoints
        CALL CS1
        RET NC        

        LD HL, (score)
        ADD HL, 100
        LD (score), HL
        CALL showScore
        JP itemCollideCommon

;collideDynamite
;        CALL CS1
;        RET NC
;
;        LD A, 1
;        LD (dynamiteCnt), A
;        CALL showDynamite
;        JP itemCollideCommon

collideBalloon
        CALL CS1
        RET NC

        LD HL, (score)
        ADD HL, 50
        LD (score), HL
        CALL showScore
        LD A, soundPop
        CALL playsound

        LD IY, (collisionInx)
        LD A, Sballoon +1
        JR itemHitCommon

itemCollideCommon
        LD A, soundCollect
        CALL playsound
        LD IY, (collisionInx)
        LD A, Sblank
        LD (IY +strucBalloon.newSprite), A
itemHitCommon
        LD (IY +strucBalloon.pattern), A
        XOR A
        LD (IY +strucBalloon.popDelayH), A
        LD A, 15
        LD (IY +strucBalloon.popDelayL), A
        AND A
        RET

noAction
        RET


;---------------------------------------------------------
; here we do a pixel perfect collision detection between
; Paul and the "balloon" sprite being tested
;---------------------------------------------------------
CS1
        LD (spriteBitmap), BC               ; save off location of 1bit bitmap
        LD (collisionInx), IX               ; and the balloon in question
doYDiff
        LD A, (spriteY)                     ; get Paul's Y coord
        LD B, (IX +strucBalloon.lowY)           ; get Balloon Y coord
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
        LD E, (IX +strucBalloon.lowX)
        LD D, (IX +strucBalloon.highX)

        OR A
        SBC HL, DE
        JR C, .negDelta

.posDelta
        LD A, H
        OR A
        RET NZ

        LD A, L
        CP 16
        RET NC

        LD B, A
        OR A
        JR balloonLeftOfPaul

.negDelta
        LD A, H
        CP $FF
        RET NZ

        LD A, L
        NEG
        CP 16
        RET NC

        LD B, A
        OR A

balloonRightOfPaul
        ; balloon X > Paul X
        ; B is holding the X delta
        ; C is holding pixel lines to test
        PUSH IX
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
        POP IX
        XOR A                               ; reset carry, no hit
        RET

balloonLeftOfPaul
        ; balloon X <= Paul X
        ; B is holding the X delta
        ; C is holding pixel lines to test
        PUSH IX
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
        POP IX
        XOR A                               ; reset carry, not hit
        RET

myhit
        POP IX
        SCF                                 ; signify a hit has occured
        RET

manBitmap    DW 00                          ; location of our man bitmap
spriteBitmap DW 00                          ; location of sprite bitmap being checked
collisionInx DW $00

