showPaul1
        LD IX, manSprite
        CALL showSP
        CALL showManRels
;        HALT
;        HALT
;        HALT
;        HALT
        RET

showPaul
        LD HL, keyDelay                     ; we only allow up/down to be pressed every few frames
        DEC (HL)
        JR NZ, showPaul0

        LD A, keyDelayInit
        LD (HL), A
keyDown
        LD BC, $fefe                        ; read keyboard up/down
        IN A, (C)
        BIT 1, A
        JR NZ, keyUp

        ; get strength value and branch if already 0
        ; otherwise store decrement and show power
        LD A, (strengthInd)
        SUB 1
        JR C, keyUp
        LD (strengthInd), A
        CALL showPower
keyUp
        LD BC, $fdfe
        IN A, (C)
        BIT 0, A
        JR NZ, showPaul0
        
        LD A, (strengthInd)
        CP 15
        JR Z, showPaul0
        INC A
        LD (strengthInd), A
        CALL showPower

showPaul0
        LD IX, manSprite                    ; point to Paul data
;        LD DE, spriteY
        LD A, (riseCnt)                     ; determine vertical direction, >0 is rising
        DEC A                               ; sub 1
        JP M, paulFalling                   ; branch if minus, i.e. was already 0
        LD (riseCnt), A                     ; otherwise store
        JP Z, paulFalling                   ; branch if 0, falling now

paulRising
        DEC (IX +sBalloon.lowY)             ; otherwise move Paul up
;        LD A, (DE)
;        DEC A
;        LD (DE), A
        JR doLeftRight                      ; end of rise processing

paulFalling
        INC (IX +sBalloon.lowY)             ; move Paul down
;        LD A, (DE)
;        INC A
;        LD (DE), A

doLeftRight
; so here we decide if Paul is allowed to move left/right
; it is restricted so that movement resembles a sin wave
; so only when the counter is 0, movement is allowed
        LD HL, leftRightCount
        DEC (HL)
        JP NZ, leftrightEnd                 ; if not theres no horizontal mvmt

        LD A, (leftRightDelay)              ; set L/R countdown default
        LD (HL), A

        LD A, (spriteDirH)                  ; get the horizontal movement
        AND A
        ;CP nothing                          ; is it 0
        JR Z, leftrightEnd                  ; 0 = up/down only
        DEC A
        ;CP left                             ; is it 1
        JR Z, paulLeft                      ; 1 = left
        DEC A
        ;CP right                            ; is it 2
        JR Z, paulRight                     ; 2 = right
        CALL keySpace
paulLeft
        CALL movePaulLeft
        JR leftrightEnd

paulRight
        CALL movePaulRight
        JR leftrightEnd

leftrightEnd
        CALL paulTileCollision

.diagnostics
        jp .diagnosticsEnd
        LD IY, tileMapData +837
        LD A, (hitind1)
        CALL DispA
        LD IY, tileMapData +877
        LD A, (hitind)
        CALL DispA
        LD IY, tileMapData +917
        LD A, (riseCnt)
        CALL DispA
        LD IY, tileMapData +957
        LD A, (IX +sBalloon.dirH)
        CALL DispA
        LD IY, tileMapData +997
        LD A, (hitLind)
        CALL DispA
        LD IY, tileMapData +1037
        LD A, (hitRind)
        CALL DispA

        LD A, (hitind1)                     
        ld b, a                             ; store lowest pixel line with hit
        ld a, (hitind)                     
        ld c, a                             ; store highest pixel line with hit


        ld a, b
        cp 22
        jp nc, .diagnosticsEnd              ; skip if hitind1 >= 22

        cp c
        jp z, .diagnosticsEnd               ; skip if hitind1 = hitind, e.g. 6/6 etc.

.diagnostics1
        ; show Paul in-situ (with collision) if hit
        ld a, (hitind1)
        AND A
        CALL NZ, showPaul1

        ; wait for space if hit
        LD A, (hitind1)
        AND A
        CALL NZ, keySpace

.diagnosticsEnd
        LD A, (hitind)
        AND A
        JP Z, paulFinish

; here xy coords have been updated and we have detected a collision
; has occured
; Paul is 32 pixels tall, 0 top - 31 bottom
; the very top pixel lines are blank, his head starts at pixel line 6
; hitind1 is the lowest pixel line with collision
; hitind  is the highest pixel line with collision
tileCollision
        LD A, (hitind1)                     ; get high point of hit
        CP 22                               ; bottom of pogo stick?
        JP nc, bounce                       ; if A >= 24, this is a bounce

;        CP 26                               ; near bottom of pogo stick
;        JR C, tileCollision1                ; branch if not
                                            ; but check low point to ensure
;        LD A, (hitind)                     ; that it's still a bounce
;        CP 31
;        JR NZ tileCollision1               ; branch if its not

;        CALL reverseX1                      ; kinda bounce but reverse any
;        JP bounce                           ; left/right movement and bounce

tileCollision1
;        LD A, (riseCnt)
;        AND A
;        JR Z, hitFalling
;        JR hitRising

; hit whilst rising
hitRising
        LD A, soundHithead
        CALL playsound

        LD A, (hitind1)                     ; see highpoint of hit
        CP 8
        JR NC, hitRising1                   ; A >= 8, dont decrease health if so

        LD A, (healthDelay)                 ; get current health delay
        SUB 3                               ; decrease it
        AND %00001111
        LD (healthDelay), A                 ; and save it
        CP 0                                ; was it 0
        JR NZ, hitRising1                   ; branch over if not
        LD A, healthDefault                 ; get default health delay
        LD (healthDelay), A                 ; and reset health delay
        LD A, (health)                      ; get current health
        DEC A                               ; decrease it
        LD (health), A                      ; and save it

hitRising1
        CALL reverseX1                      ; reverse previous left/right

        ld a, (riseCnt)                     ; obtain riseCnt, i.e. were we jumping or falling
        and a                               ; test for 0 (falling)
        jr z, .hr1                          ; branch if falling
        jr .hr2                             ; otherwise do the jumping branch

.hr1
        dec (ix +sBalloon.lowY)             ; reverse falling, move Paul up
        jr .hr3                             ; done
.hr2
        INC (IX +sBalloon.lowY)             ; reverse jumping, move Paul down
        jr .hr3                             ; done

        ;LD A, (DE)
        ;INC A
        ;LD (DE), A
.hr3
        XOR A                               ; Paul is now falling
        LD (riseCnt), A                     ; set it

        LD A, (hitind)                      ; get highest pixel line of collision
        ld b, a                             ; save it
        ld a, (hitind1)                     ; get lowest pixel line of collision
        cp b                                ; same as highest?
        jp z, paulFinish                    ; jump if so, e.g. 6/6, 7/7 etc
       ; CP 6                                ; if its just Paul's head
       ; JP Z, paulFinish
       ; cp 7
       ; jp z, paulFinish


        XOR A                               ; A=0
        LD (spriteDirH), A                  ; sdet direction to 0 (none)
        JP paulFinish                       ; done


;hitFalling
        ; hit whilst falling, but it is not a bounce?!
;        LD A, (hitLind)
;        LD B, A
;        LD A, (hitRind)
;        LD C, A
;        LD A, (manPat)
;        CP facingLeft
;        JR Z, fallingLeft
;        JR fallingRight

;fallingLeft
;        LD A, B
;        AND C
;        CP 1
;        JR Z, FLEnd
;        LD A, B
;        CP 1
;        JR Z, FLhitL
;        JR FLhitR

;FLhitL
;        CALL reverseX1
;        JR FLEnd
;FLhitR
 ;       CALL movePaulLeft
 ;       JR FLEnd

;fallingRight
;        LD A, B
;        AND C
;        CP 1
;        JR Z, FLEnd
;        LD A, C
;        CP 1
;        JR Z, FRhitR
;        JR FRhitL
;FRhitR
;        CALL reverseX1
;        JR FLEnd
;FRhitL
;        CALL movePaulRight
;        JR FLEnd

;FLEnd
     ;   LD A, (DE)
     ;   DEC A
     ;   LD (DE), A
 ;       DEC (IX +sBalloon.lowY)
 ;       LD A, nothing
 ;       LD (spriteDirH), A
 ;       LD A, (hitind)
 ;       CP 31
 ;       JR Z, bounce
 ;       JP paulFinish

bounce
; here we were either falling and glanced or fully hit the ground
; - make the bounce sound
; - if we were falling, then change to jumping
; - if we were jumping then continue jumping
        LD A, (strengthInd)
        ADD A, A
        ADD A, A
        AND %00111111
        OR 3
        LD (sound3Dur), A                   ; set duration related to strength
        LD A, soundBounce
        CALL playsound

    ;    LD A, (DE)
    ;    DEC A
    ;    LD (DE), A
    ;    LD HL, (spriteY)
    ;    DEC HL
    ;    LD (spriteY), HL

        DEC (IX +sBalloon.lowY)             ; move Paul up

        LD A, (strengthInd)                 ; get index into bounce table
        LD HL, bounceTable                  ; point to bounce table
        ADD HL, A                           ; add offset for strength
        LD A, (HL)                          ; get the rise count
        LD (riseCnt), A                     ; and store
        ADD HL, 16                          ; point to left/right delay
        LD A, (HL)                          ; get the left/right delay
        LD (leftRightCount), A              ; and store it
        LD (leftRightDelay), A
        CALL keyProcess

paulFinish
        CALL showPaul1                      ; show man sprite

;        LD BC, $7ffe                        ; ready keypoard port
;        IN A, (C)                           ; read it
;        AND %00000001                       ; mask except spacebar
;        XOR %00000001                       ; reverse so press = 1
;        LD B, A                             ; save in B
;        LD A, (dynamiteCnt)                 ; see if we have any dynamite
;        AND B                               ; if press and dynamite
;        CALL NZ, killSkulls                 ; kill the skulls

        CALL chkSpriteCollision             ; check balloon collision
        CALL showHealth
        LD A, (health)                      ; get health value
        AND A                               ; see if it's zero
        RET NZ                              ; return if not
        SCF                                 ; otherwise set carry flag
        RET                                 ; and return, dead

;killSkulls
;        PUSH IY
;        LD IY, balloonSpr
;        LD A, (balloonSprCnt)
;        LD C, 0                             ; skull kill count
;        LD B, A                             ; "balloons" to process
;ks0
;        LD A, (IY +sBalloon.pattern)        ; get pattern
;        CP skull                            ; was it a skull
;        JR NZ, ks1                          ; branch if not, next to test
;        INC A                               ; +1 to pattern -> explosion
;        LD (IY +sBalloon.pattern), A        ; set it
;        LD HL, 15                           ; and a little pop delay
;        LD (IY +sBalloon.popDelayH), H
;        LD (IY +sBalloon.popDelayL), L
;        INC C                               ; increase killed skulls count
;ks1
;        LD DE, sBalloon
;        ADD IY, DE
;        DJNZ ks0
;        POP IY
;        LD A, C                             ; get killed skulls count
;        AND A                               ; was it 0
;        RET Z                               ; return if so
;ks2
;        LD A, soundKillskull                ; make sound fx
;        CALL playsound
;        XOR A                               ; dynamite is exhausted
;        LD (dynamiteCnt), A
;        CALL showDynamite
;        RET

keyProcess
; this should only be called on a bounce
        LD A, (features)                    ; get screen features
        BIT 0, A                            ; check keyboard is on
        RET NZ                              ; return if not

keyLeft
        LD BC, $dffe                        ; keys Y U I O P
        IN A, (C)
        BIT 1, A
        JR NZ, keyRight

        LD A, facingLeft
        LD (manPat), A
        LD A, left
        LD (spriteDirH), A

keyRight
        ;LD BC, $dffe                        ; keys Y U I O P
        ;IN A, (C)
        BIT 0, A
        JR NZ, keyEnd

        LD A, facingRight
        LD (manPat), A
        LD A, right
        LD (spriteDirH), A

keyEnd
        RET

movePaulRight
        LD HL, (spriteX)
        INC HL
        LD (spriteX), HL
        RET

movePaulLeft
        LD HL, (spriteX)
        DEC HL
        LD (spriteX), HL
        RET

reverseX1
        LD A, (manPat)
        CP facingLeft
        JR Z, movePaulRight
        CP facingRight
        JR Z, movePaulLeft
        RET
