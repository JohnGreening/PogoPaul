;==========================================================================
; updatePaul.inc - everything that moves and draws Paul
;
; showPaul is called twice per frame from MainLoop (one call = one "tick").
; Each tick:
;   1. handlePowerKeys  - A / Z adjust pogo power (every keyDelayInit ticks)
;   2. updateSpeedY     - gravity on paulSpeedY, work out 0..2 pixels to move
;   3. pixel step loop  - move ONE pixel at a time and check the tiles after
;                         each pixel, so Paul can never pass through a tile.
;                         The sideways step (if due) happens with the first pixel.
;   4. onTileHit        - landed (bounce) or hit head / wall
;   5. drawPaul, balloon collisions, health bar
; Returns carry set if Paul has died (health = 0).
;
; Paul is 32 pixel rows tall (row 0 top .. row 31 bottom, head starts at row 6).
; paulTileCollision returns:
;   hitind1 = topmost Paul row touching a tile (0 = no hit)
;   hitind  = bottom-most Paul row touching a tile
;==========================================================================

bounceRow       EQU 22          ; topmost hit row >= this: feet/pogo touched, bounce
headRow         EQU 8           ; topmost hit row <  this: head bump, costs health
headHitDamage   EQU 3           ; healthDelay is reduced by this per head bump

; keyboard half-rows (active low)
keyPortZ        EQU $fefe       ; shift z x c v
keyBitZ         EQU 1
keyPortA        EQU $fdfe       ; a s d f g
keyBitA         EQU 0
keyPortOP       EQU $dffe       ; p o i u y
keyBitP         EQU 0
keyBitO         EQU 1

maxPower        EQU 15

;--------------------------------------------------------------------------
; showPaul - one tick of Paul. Out: carry set = Paul is dead
;--------------------------------------------------------------------------
showPaul
        CALL handlePowerKeys
        LD IX, manSprite                            ; IX = Paul's record (needed by paulTileCollision)
        CALL updateSpeedY                           ; sets lastMoveY (direction) and extraPixelY

        CALL movePaulY                              ; first pixel (if any)
        CALL moveHorizontal                         ; sideways step (if due)
.checkTiles
        CALL paulTileCollision
        LD A, (hitind)
        AND A
        JR NZ, .hit                                 ; touching a tile, deal with it
        LD A, (extraPixelY)                         ; second pixel to move this tick?
        AND A
        JR Z, .done
        XOR A
        LD (extraPixelY), A
        CALL movePaulY                              ; second pixel, then check again
        JR .checkTiles
.hit
        CALL onTileHit                              ; a hit ends this tick's movement
.done
        CALL drawPaul
        CALL chkSpriteCollision                     ; balloons, items, skulls
        CALL showHealth
        LD A, (health)
        AND A                                       ; clears carry
        RET NZ                                      ; still alive
        SCF                                         ; dead
        RET

;--------------------------------------------------------------------------
; drawPaul - show Paul's two sprites (also called from levelSetup)
;--------------------------------------------------------------------------
drawPaul
        LD IX, manSprite
        CALL showSP                                 ; top half (anchor)
        JP showManRels                              ; bottom half (relative)

;--------------------------------------------------------------------------
; handlePowerKeys - Z lowers, A raises pogo power, once every keyDelayInit ticks
;--------------------------------------------------------------------------
handlePowerKeys
        LD HL, keyDelay
        DEC (HL)
        RET NZ                                      ; not time to read the keys yet
        LD (HL), keyDelayInit

        LD BC, keyPortZ
        IN A, (C)
        BIT keyBitZ, A
        JR NZ, .checkA                              ; Z not pressed
        LD A, (strengthInd)
        SUB 1
        JR C, .checkA                               ; already 0
        LD (strengthInd), A
        CALL showPower
.checkA
        LD BC, keyPortA
        IN A, (C)
        BIT keyBitA, A
        RET NZ                                      ; A not pressed
        LD A, (strengthInd)
        CP maxPower
        RET Z                                       ; already at maximum
        INC A
        LD (strengthInd), A
        JP showPower

;--------------------------------------------------------------------------
; updateSpeedY - apply gravity and split this tick's movement into pixels
;   paulSpeedY: 8.8 fixed point px/tick, +ve = up, capped at maxFallSpeed down
;   subPixelY : fraction of a pixel carried to the next tick
; Out: lastMoveY   = -1 up, +1 down, 0 no vertical move this tick
;      extraPixelY = 1 if a second pixel must be moved this tick, else 0
;--------------------------------------------------------------------------
updateSpeedY
        LD HL, (paulSpeedY)
        LD DE, -gravity
        ADD HL, DE
        BIT 7, H
        JR Z, .speedDone                            ; rising, no cap needed
        PUSH HL
        LD DE, maxFallSpeed
        ADD HL, DE                                  ; carry set if speed >= -maxFallSpeed
        POP HL
        JR C, .speedDone
        LD HL, -maxFallSpeed                        ; cap fall speed
.speedDone
        LD (paulSpeedY), HL
        LD A, (subPixelY)
        ADD HL, A                                   ; H = whole pixels (-2..+2), L = new fraction
        LD A, L
        LD (subPixelY), A

        LD A, H
        LD B, 0                                     ; B = direction, C = extra pixel
        LD C, B
        AND A
        JR Z, .store                                ; no vertical move
        BIT 7, A
        JR NZ, .down
        DEC A                                       ; up: +1 -> 0 extra, +2 -> 1 extra
        LD C, A
        DEC B                                       ; B = -1 (up)
        JR .store
.down
        INC A                                       ; down: -1 -> 0, -2 -> -1
        AND 1                                       ; extra = 0 or 1
        LD C, A
        INC B                                       ; B = +1 (down)
.store
        LD A, B
        LD (lastMoveY), A
        LD A, C
        LD (extraPixelY), A
        RET

;--------------------------------------------------------------------------
; movePaulY - move Paul one pixel in direction lastMoveY (-1 / 0 / +1)
;--------------------------------------------------------------------------
movePaulY
        LD A, (lastMoveY)
        ADD A, (IX +strucBalloon.lowY)
        LD (IX +strucBalloon.lowY), A
        RET

;--------------------------------------------------------------------------
; moveHorizontal - one pixel sideways every leftRightDelay ticks
; in the direction chosen at the last bounce (spriteDirH)
;--------------------------------------------------------------------------
moveHorizontal
        LD HL, leftRightCount
        DEC (HL)
        RET NZ                                      ; not due yet
        LD A, (leftRightDelay)
        LD (HL), A
        LD A, (spriteDirH)
        CP left
        JR Z, movePaulLeft
        CP right
        JR Z, movePaulRight
        RET                                         ; nothing: straight up and down

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

;--------------------------------------------------------------------------
; onTileHit - decide what kind of tile contact this was
;--------------------------------------------------------------------------
onTileHit
        LD A, (hitind1)
        CP bounceRow
        JR NC, onLand                               ; only feet / lower body touching

;--------------------------------------------------------------------------
; onHeadOrWallHit - head bump or body against a wall
;   - head (rows < headRow) costs health
;   - step back one pixel sideways and undo this pixel's vertical move
;   - a rising Paul stops rising; a falling Paul keeps falling
;   - a hit on several rows means a wall: stop sideways movement
;--------------------------------------------------------------------------
onHeadOrWallHit
        CP headRow                                  ; A = hitind1
        JR NC, .noDamage
        LD A, (healthDelay)
        SUB headHitDamage
        AND %00001111
        LD (healthDelay), A
        JR NZ, .noDamage
        LD A, healthDefault
        LD (healthDelay), A
        LD HL, health
        DEC (HL)
.noDamage
        LD A, soundHithead
        CALL playsound

        CALL stepBackX
        LD HL, lastMoveY                            ; undo this pixel's vertical move
        LD A, (IX +strucBalloon.lowY)
        SUB (HL)
        LD (IX +strucBalloon.lowY), A

        LD A, (paulSpeedY +1)
        BIT 7, A
        JR NZ, .keepFalling                         ; falling: keep speed (no wall stick)
        LD HL, 0
        LD (paulSpeedY), HL                         ; rising (or at apex): stop the rise
        XOR A
        LD (subPixelY), A
.keepFalling
        LD A, (hitind)
        LD B, A
        LD A, (hitind1)
        CP B
        RET Z                                       ; single row: head bump only
        XOR A
        LD (spriteDirH), A                          ; several rows: wall, drop straight down
        RET

;--------------------------------------------------------------------------
; stepBackX - move Paul one pixel away from the way he is facing
;--------------------------------------------------------------------------
stepBackX
        LD A, (manPat)
        CP facingLeft
        JR Z, movePaulRight
        CP facingRight
        JR Z, movePaulLeft
        RET

;--------------------------------------------------------------------------
; onLand - feet hit something: bounce
;--------------------------------------------------------------------------
onLand
        LD A, (strengthInd)                         ; bounce sound length grows with power
        ADD A, A
        ADD A, A
        AND %00111111
        OR 3
        LD (sound3Dur), A
        LD A, soundBounce
        CALL playsound

        DEC (IX +strucBalloon.lowY)                 ; lift Paul clear of the floor
        CALL startBounce
        ; fall through: direction can only change at a bounce

;--------------------------------------------------------------------------
; readDirectionKeys - O = left, P = right (P wins if both); no key = keep going
;--------------------------------------------------------------------------
readDirectionKeys
        LD A, (features)
        BIT 0, A
        RET NZ                                      ; keyboard disabled (splash screen)
        LD BC, keyPortOP
        IN A, (C)
        LD E, A                                     ; keep the row for both tests
        BIT keyBitO, E
        JR NZ, .checkP
        LD A, facingLeft
        LD (manPat), A
        LD A, left
        LD (spriteDirH), A
.checkP
        BIT keyBitP, E
        RET NZ
        LD A, facingRight
        LD (manPat), A
        LD A, right
        LD (spriteDirH), A
        RET

;--------------------------------------------------------------------------
; startBounce - launch Paul upwards at the current power (also from paulInit)
;   speed from bounceSpeedTable, sideways step delay from bounceTable row 2
;--------------------------------------------------------------------------
startBounce
        LD A, (strengthInd)
        ADD A, A
        LD HL, bounceSpeedTable
        ADD HL, A
        LD E, (HL)
        INC HL
        LD D, (HL)
        LD (paulSpeedY), DE
        XOR A
        LD (subPixelY), A
        LD A, (strengthInd)
        LD HL, bounceTable +16
        ADD HL, A
        LD A, (HL)
        LD (leftRightCount), A
        LD (leftRightDelay), A
        RET
