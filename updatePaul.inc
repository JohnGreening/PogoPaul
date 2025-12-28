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
        LD A, (riseCnt)                     ; determine vertical direction, >0 is rising
        DEC A                               ; sub 1
        JP M, paulFalling                   ; branch if minus, i.e. was already 0
        LD (riseCnt), A                     ; otherwise store
        JP Z, paulFalling                   ; branch if 0, falling now

paulRising
        DEC (IX +strucBalloon.lowY)             ; otherwise move Paul up
        JR doLeftRight                      ; end of rise processing

paulFalling
        INC (IX +strucBalloon.lowY)             ; move Paul down

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
        LD A, (IX +strucBalloon.dirH)
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
        LD A, (hitind)                      ; get collision occured indicator
        AND A                               ; is it non 0
        JP Z, paulFinish                    ; branch over if 0

; here xy coords have been updated and we have detected a collision
; has occured
; Paul is 32 pixels tall, 0 top - 31 bottom
; the very top pixel lines are blank, his head starts at pixel line 6
; hitind1 is the lowest pixel line with collision
; hitind  is the highest pixel line with collision
tileCollision
        LD A, (hitind1)                     ; get lowest pixel line of collision
        CP 22                               ; bottom ish of pogo stick?
        JP nc, bounce                       ; if A >= 22, this is a bounce

tileCollision1
        CP 8
        JR NC, .notHeadHit                  ; A >= 8, dont decrease health if so

        LD A, (healthDelay)                 ; get current health delay
        SUB 3                               ; decrease it
        AND %00001111
        LD (healthDelay), A                 ; and save it
        CP 0                                ; was it 0
        JR NZ, .notHeadHit                  ; branch over if not
        LD A, healthDefault                 ; get default health delay
        LD (healthDelay), A                 ; and reset health delay
        LD A, (health)                      ; get current health
        DEC A                               ; decrease it
        LD (health), A                      ; and save it

.notHeadHit
        LD A, soundHithead
        CALL playsound

        CALL reverseX1                      ; reverse previous left/right

        ld a, (riseCnt)                     ; obtain riseCnt, i.e. were we jumping or falling
        and a                               ; test for 0 (falling)
        jr z, .hr1                          ; branch if falling
        jr .hr2                             ; otherwise do the jumping branch

.hr1
        dec (ix +strucBalloon.lowY)             ; reverse falling, move Paul up
        jr .hr3                             ; done
.hr2
        INC (IX +strucBalloon.lowY)             ; reverse jumping, move Paul down
        jr .hr3                             ; done

.hr3
        XOR A                               ; Paul is now falling
        LD (riseCnt), A                     ; set it

        LD A, (hitind)                      ; get highest pixel line of collision
        ld b, a                             ; save it
        ld a, (hitind1)                     ; get lowest pixel line of collision
        cp b                                ; same as highest?
        jp z, paulFinish                    ; jump if so, e.g. 6/6, 7/7 etc

        XOR A                               ; A=0
        LD (spriteDirH), A                  ; sdet direction to 0 (none)
        JP paulFinish                       ; done

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

        DEC (IX +strucBalloon.lowY)             ; move Paul up

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

        CALL chkSpriteCollision             ; check balloon collision
        CALL showHealth
        LD A, (health)                      ; get health value
        AND A                               ; see if it's zero
        RET NZ                              ; return if not
        SCF                                 ; otherwise set carry flag
        RET                                 ; and return, dead

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
        LD BC, $dffe                        ; keys Y U I O P
        IN A, (C)
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
