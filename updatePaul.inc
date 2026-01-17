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
        BIT 1, A                                    ; check "a" key
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
        BIT 0, A                                    ; check for "q"
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
        LD IX, manSprite                            ; point to Paul data
        LD A, (riseCnt)                             ; determine vertical direction, >0 is rising
        OR A                                        ; = 0?
        JR Z, paulFalling                           ; branch if so, falling

        DEC A                                       ; otherwise sub 1
        LD (riseCnt), A                             ; and store

paulRising
        DEC (IX +strucBalloon.lowY)                 ; and move Paul up
        JR doLeftRight                              ; end of rise processing

paulFalling
        INC (IX +strucBalloon.lowY)                 ; move Paul down

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

;.diagnostics
;        jp .diagnosticsEnd
;        LD IY, tileMapData +837
;        LD A, (hitind1)
;        CALL DispA
;        LD IY, tileMapData +877
;        LD A, (hitind)
;        CALL DispA
;        LD IY, tileMapData +917
;        LD A, (riseCnt)
;        CALL DispA
;        LD IY, tileMapData +957
;        LD A, (IX +strucBalloon.dirH)
;        CALL DispA
;        LD IY, tileMapData +997
;        LD A, (hitLind)
;        CALL DispA
;        LD IY, tileMapData +1037
;        LD A, (hitRind)
;        CALL DispA
;
;        LD A, (hitind1)                     
;        ld b, a                             ; store lowest pixel line with hit
;        ld a, (hitind)                     
;        ld c, a                             ; store highest pixel line with hit
;
;
;       ld a, b
;       cp 22
;       jp nc, .diagnosticsEnd              ; skip if hitind1 >= 22
;
;        cp c
;        jp z, .diagnosticsEnd               ; skip if hitind1 = hitind, e.g. 6/6 etc.
;
;.diagnostics1
;        ; show Paul in-situ (with collision) if hit
;        ld a, (hitind1)
;        AND A
;        CALL NZ, showPaul1
;
;        ; wait for space if hit
;        LD A, (hitind1)
;        AND A
;        CALL NZ, keySpace
;
;.diagnosticsEnd
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

        ld a, (riseCnt)                             ; obtain riseCnt, i.e. were we jumping or falling
        and a                                       ; test for 0 (falling)
        jr z, .hr1                                  ; branch if falling
        jr .hr2                                     ; otherwise do the jumping branch

.hr1
        dec (ix +strucBalloon.lowY)                 ; reverse falling, move Paul up
        jr .hr3                                     ; done
.hr2
        INC (IX +strucBalloon.lowY)                 ; reverse jumping, move Paul down
        jr .hr3                                     ; done

.hr3
        XOR A                                       ; Paul is now falling
        LD (riseCnt), A                             ; set it

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

        CALL setRiseCnt                             ; set riseCnt and lrDelay
        CALL keyProcess                             ; it's a bounce, so allow Paul to change horizontal direction

paulFinish
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
        LD A, (strengthInd)                         ; get index into bounce table
        LD HL, bounceTable                          ; point to bounce table
        ADD HL, A                                   ; add offset for strength
        LD A, (HL)                                  ; get the rise count
        LD (riseCnt), A                             ; and store
        ADD HL, 16                                  ; point to left/right delay
        LD A, (HL)                                  ; get the left/right delay
        LD (leftRightCount), A                      ; and store it
        LD (leftRightDelay), A
        RET