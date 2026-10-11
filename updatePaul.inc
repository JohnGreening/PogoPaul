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
        LD HL, keyDelay                             ; we only allow up/down to be pressed every few frames
        DEC (HL)                                    ; -1 from up/down key delay
        JR NZ, showPaul0                            ; branch over up/down key processing if it's not zero

        LD A, keyDelayInit                          ; reset key delay for next time
        LD (HL), A                                  ; save it
keyDown
        LD BC, $fefe                                ; read keyboard up/down
        IN A, (C)                                   ; read port
        BIT 1, A                                    ; check "z" key
        JR NZ, keyUp                                ; branch if not pressed

        ; get strength value and branch if already 0
        ; otherwise store decrement and show new power
        LD A, (strengthInd)
        SUB 1
        JR C, keyUp
        LD (strengthInd), A
        CALL showPower
keyUp
        LD BC, $fdfe                                ; read keyboard up/down
        IN A, (C)                                   ; read port
        BIT 0, A                                    ; check "a" key
        JR NZ, showPaul0                            ; branch if not pressed
        
        ; get strength value and branch if already 15
        ; otherwise store increment and show new power
        LD A, (strengthInd)
        CP 15
        JR Z, showPaul0
        INC A
        LD (strengthInd), A
        CALL showPower

showPaul0
; --------------------------------------------------------------------------
; vertical movement: 8.8 fixed point velocity (velY, +ve = up) with gravity.
; at most 2 px per tick, applied as two 1 px sub-steps so every pixel is
; collision checked. The first pixel is moved here, a second (if any) is
; left in pendStep and done at paulFinish after this pixel was checked.
; --------------------------------------------------------------------------
        LD IX, manSprite                            ; point to Paul data
        LD HL, (velY)                               ; current vertical velocity
        LD DE, -gravity                             ; apply gravity
        ADD HL, DE
        BIT 7, H                                    ; falling?
        JR Z, .velOk                                ; no, rising so no clamp
        PUSH HL
        LD DE, termVel
        ADD HL, DE                                  ; carry set if velY >= -termVel
        POP HL
        JR C, .velOk
        LD HL, -termVel                             ; clamp to terminal fall speed
.velOk
        LD (velY), HL
        LD A, (fracY)                               ; add the sub-pixel remainder
        ADD HL, A
        LD A, L
        LD (fracY), A                               ; new remainder
        LD A, H                                     ; whole pixels to move, signed -2..+2 (+ve = up)
        OR A
        JR Z, .noMove
        BIT 7, A
        JR NZ, .moveDown
        DEC A                                       ; 1 -> 0, 2 -> 1 pending up
        LD (pendStep), A
        DEC (IX +strucBalloon.lowY)                 ; move Paul up 1 px
        LD A, -1
        JR .moved
.moveDown
        INC A                                       ; -1 -> 0, -2 -> -1 pending down
        LD (pendStep), A
        INC (IX +strucBalloon.lowY)                 ; move Paul down 1 px
        LD A, 1
.moved
        LD (lastStep), A                            ; remember this sub-step for undo
        JR doLeftRight
.noMove
        XOR A
        LD (pendStep), A
        LD (lastStep), A

doLeftRight
; so here we decide if Paul is allowed to move left/right
; it is restricted so that movement resembles a sin wave
; so only when the counter is 0, movement is allowed
        LD HL, leftRightCount
        DEC (HL)
        JP NZ, leftrightEnd                         ; if not theres no horizontal mvmt

        LD A, (leftRightDelay)                      ; set L/R countdown default
        LD (HL), A

        LD A, (spriteDirH)                          ; get the horizontal movement
        AND A                                       ; is it 0?
        JR Z, leftrightEnd                          ; 0 = up/down only
        DEC A                                       ; was it 1?
        JR Z, paulLeft                              ; 1 = left
        DEC A                                       ; was it 2?
        JR Z, paulRight                             ; 2 = right
        JR leftrightEnd
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
        LD A, (hitind)                              ; get collision occured indicator
        AND A                                       ; is it non 0
        JP Z, paulFinish                            ; branch over if 0

; here xy coords have been updated and we have detected a collision
; has occured
; Paul is 32 pixels tall, 0 top - 31 bottom
; the very top pixel lines are blank, his head starts at pixel line 6
; hitind1 is the lowest pixel line with collision
; hitind  is the highest pixel line with collision
tileCollision
        LD A, (hitind1)                             ; get lowest pixel line of collision
        CP 22                                       ; bottom ish of Paul & pogo stick?
        JP nc, bounce                               ; if A >= 22, this is a bounce

tileCollision1
        CP 8
        JR NC, .notHeadHit                          ; A >= 8, dont decrease health if so

        LD A, (healthDelay)                         ; get current health delay
        SUB 3                                       ; decrease it
        AND %00001111
        LD (healthDelay), A                         ; and save it
        CP 0                                        ; was it 0
        JR NZ, .notHeadHit                          ; branch over if not
        LD A, healthDefault                         ; get default health delay
        LD (healthDelay), A                         ; and reset health delay
        LD A, (health)                              ; get current health
        DEC A                                       ; decrease it
        LD (health), A                              ; and save it

.notHeadHit
        LD A, soundHithead
        CALL playsound

        CALL reverseX1                              ; reverse previous left/right

        LD A, (lastStep)                            ; undo this sub-step's vertical pixel
        OR A
        JR Z, .hr3                                  ; no vertical move this sub-step
        BIT 7, A
        JR NZ, .hr2
.hr1
        DEC (IX +strucBalloon.lowY)                 ; was moving down, move back up
        JR .hr3
.hr2
        INC (IX +strucBalloon.lowY)                 ; was moving up, move back down
.hr3
        XOR A
        LD (pendStep), A                            ; drop any second sub-step
        LD A, (velY+1)
        BIT 7, A
        JR NZ, .keepFall                            ; falling: keep speed (no wall stick)
        LD HL, 0
        LD (velY), HL                               ; rising: head bump stops the rise
        XOR A
        LD (fracY), A
.keepFall

        LD A, (hitind)                              ; get highest pixel line of collision
        ld b, a                                     ; save it
        ld a, (hitind1)                             ; get lowest pixel line of collision
        cp b                                        ; same as highest?
        jp z, paulFinish                            ; jump if so, e.g. 6/6, 7/7 etc

;
; hitind / hitind1 are different. This probably means we've jumped into a wall or something similar
; in which case, stop horizontal movement, so we just fall vertically down
;
        XOR A                                       ; A=0
        LD (spriteDirH), A                          ; set direction to 0 (none)
        JP paulFinish                               ; done

;
; any collision with pixel line 22+ of Paul is treated as a bounce
;
bounce
        LD A, (strengthInd)
        ADD A, A
        ADD A, A
        AND %00111111
        OR 3
        LD (sound3Dur), A                           ; set duration related to strength
        LD A, soundBounce
        CALL playsound

        DEC (IX +strucBalloon.lowY)                 ; move Paul up

        CALL setRiseCnt                             ; set launch velocity and lrDelay
        CALL keyProcess                             ; it's a bounce, so allow Paul to change horizontal direction
        XOR A
        LD (pendStep), A                            ; bounce cancels any second sub-step

paulFinish
        LD A, (pendStep)                            ; second pixel still to move this tick?
        OR A
        JR Z, paulFinish1
        LD B, A
        XOR A
        LD (pendStep), A
        BIT 7, B
        JR NZ, .pendDown
        DEC (IX +strucBalloon.lowY)                 ; second pixel up
        LD A, -1
        JR .pendGo
.pendDown
        INC (IX +strucBalloon.lowY)                 ; second pixel down
        LD A, 1
.pendGo
        LD (lastStep), A
        JP leftrightEnd                             ; collision check this pixel too
paulFinish1
        CALL showPaul1                              ; show Paul sprite

        CALL chkSpriteCollision                     ; check balloon collision
        CALL showHealth                             ; update health bar display
        LD A, (health)                              ; get health value
        AND A                                       ; see if it's zero
        RET NZ                                      ; return if not
        SCF                                         ; otherwise set carry flag
        RET                                         ; and return, dead

keyProcess
; this should only be called on a bounce
        LD A, (features)                            ; get screen features
        BIT 0, A                                    ; check keyboard is on
        RET NZ                                      ; return if not

keyLeft
        LD BC, $dffe                                ; keys Y U I O P
        IN A, (C)                                   ; read port
        BIT 1, A                                    ; check for "o"
        JR NZ, keyRight                             ; branch if not pressed

        LD A, facingLeft                            ; Paul is not facing left
        LD (manPat), A                              ; set it
        LD A, left                                  ; Paul is now moving left
        LD (spriteDirH), A                          ; set it

keyRight
        LD BC, $dffe                                ; keys Y U I O P
        IN A, (C)                                   ; read port
        BIT 0, A                                    ; check for "p"
        JR NZ, keyEnd                               ; branch if not pressed

        LD A, facingRight                           ; Paul is now facing right
        LD (manPat), A                              ; set it
        LD A, right                                 ; Paul is now moving right
        LD (spriteDirH), A                          ; set it

keyEnd
        RET

movePaulRight
        LD HL, (spriteX)                            ; get current X co-ord
        INC HL                                      ; add 1
        LD (spriteX), HL                            ; save it
        RET

movePaulLeft
        LD HL, (spriteX)                            ; get current X co-ord
        DEC HL                                      ; minus 1
        LD (spriteX), HL                            ; set it
        RET

;
; on a collision, we back Paul away from the direction he was facing
;
reverseX1
        LD A, (manPat)                              ; get Paul's sprite pattern and hence facing direction
        CP facingLeft                               ; is he facing left
        JR Z, movePaulRight                         ; if so, move him right
        CP facingRight                              ; is he facing right
        JR Z, movePaulLeft                          ; if so move him left
        RET

setRiseCnt
; on a bounce (and paulInit): launch velocity from launchTable, L/R delay from bounceTable row 2
        LD A, (strengthInd)
        ADD A, A
        LD HL, launchTable
        ADD HL, A
        LD E, (HL)
        INC HL
        LD D, (HL)
        LD (velY), DE
        XOR A
        LD (fracY), A
        LD (pendStep), A
        LD A, (strengthInd)
        LD HL, bounceTable +16                      ; left/right delay row
        ADD HL, A
        LD A, (HL)
        LD (leftRightCount), A
        LD (leftRightDelay), A
        RET
