balloonUpt
     ;   RET
        LD IX, balloonSpr                   ; point to balloon data

balloonUpt1
        LD A, (IX +strucBalloon.pattern)        ; get balloon pattern
        LD C, A                             ; save pattern
        CP 255                              ; check for finished marker
        RET Z                               ; exit if done

; balloonAction is just a table of addresses to jump to depending on the 
; balloon pattern being used. i.e. is it a balloon, object, skull etc
; actions are :
;    doBalloon   - regular balloon processing
;    balloonEnd  - do nothing, just skip
;    itemFalling - special action to drop item until it hits a floor
;    skull11     - special skull action
;    toxic1      - special toxic drop action         
        ADD A, A                            ; each address is 2 bytes
        LD HL, balloonAction                ; get base table
        ADD HL, A                           ; add offset and hence point to action needed
        LD E, (HL)                          ; low address into E
        INC HL                              ; 
        LD D, (HL)                          ; high address into D
        EX DE, HL                           ; swap DE into HL
        JP (HL)                             ; jump to action required

balloonAction
DW balloonEnd                               ;  0
DW balloonEnd                               ;  1
DW balloonEnd                               ;  2
DW balloonEnd                               ;  3
DW doBalloon                                ;  4 Balloon
DW doBalloon                                ;  5 Balloon popped #1
DW doBalloon                                ;  6 Balloon popped #2
DW doBalloon                                ;  7 Balloon popped #3
DW itemFalling                              ;  8 Heart falling
DW balloonEnd                               ;  9 Heart landed
DW itemFalling                              ; 10 Apple falling
DW balloonEnd                               ; 11 Apple landed
DW itemFalling                              ; 12 key falling
DW balloonEnd                               ; 13 key landed
DW itemFalling                              ; 14 points falling
DW balloonEnd                               ; 15 points landed
DW balloonEnd                               ; 16 blank pattern
DW skull1                                   ; 17 skull pattern
DW toxic1                                   ; 18 toxic drop pattern

doBalloon
        ;LD A, (IX +strucBalloon.newSprite)
        ;CP Skey
        ;JP Z, moveBalloonRight
        LD L, (IX +strucBalloon.popDelayL)      ; get the pop delay low byte
        LD H, (IX +strucBalloon.popDelayH)      ; get the pop delay high byte
        DEC HL                              ; decrease count
        LD (IX +strucBalloon.popDelayL), L      ; save low byte
        LD (IX +strucBalloon.popDelayH), H      ; save high byte
        LD A, L                             ; is it zero now
        OR H
        JP NZ, moveBalloonRight             ; branch if timer >0

balloonPop
; timer has run out and so we increment the animation by 1 frame
;
        LD A, C                             ; get the balloon pattern
        INC A                               ; add 1
        LD (IX +strucBalloon.pattern), A        ; save it

        LD A, C                             ; inspect original pattern
        CP Sblank
        JP Z, deadItem

        CP Sballoon +3                       ; is it now fully popped
        JR Z, fullyPopped                   ; branch if so

        CP Sskull + 3
        JP Z, deadItem

        CP Sballoon
        JR NZ, popDone

        ; here it should be a balloon that has popped on its own
        ; so turn it into a skull unless the item is the key
        LD A, soundPop
        CALL playsound
        LD A, (IX +strucBalloon.newSprite)
        CP Skey
        JR Z, popDone
        LD A, Sskull
        LD (IX +strucBalloon.newSprite), A
        LD A, skullDelay
        LD (IX +strucBalloon.landValue), A
        
popDone
        LD HL, 15                           ; set a little delay
        LD (IX +strucBalloon.popDelayL), L      ; save low byte
        LD (IX +strucBalloon.popDelayH), H      ; save high byte
        JP balloonEnd

fullyPopped
; here balloon is fully popped
; we turn it into a skull, heart etc
        LD A, (IX +strucBalloon.newSprite)      ; get new sprite value
        LD (IX +strucBalloon.pattern), A        ; make this the pattern

        LD A, Sblank
        LD (IX +strucBalloon.newSprite), A

        ; since one balloon has now popped, can we create another
        LD A, (balloonNext)                 ; get next free balloon
        LD B, A                             ; save in B for later
        LD D, B                             ; calculate offset
        LD E, strucBalloon
        MUL D, E
        LD IY, balloonSpr
        ADD IY, DE
        LD A, (IY +strucBalloon.pattern)        ; get current Pattern
        CP 255                              ; if it's 255, we're at end
        JP Z, balloonEnd
        LD A, Sballoon
        LD (IY +strucBalloon.pattern), A
        LD A, B
        INC A
        LD (balloonNext), A
        JP balloonEnd

deadItem
        LD A, Sblank
        LD (IX +strucBalloon.pattern), A
        JP balloonEnd

moveBalloonRight
; move the balloon sprite right a bit
; and wrap to screen start if we are at the RHS
        LD H, (IX +strucBalloon.highX)          ; get high X
        LD L, (IX +strucBalloon.lowX)           ; get low X

; a pending balloon may decide to continue right
; therefore we need this entry point here
balloonR
        INC HL                              ; +1 the x coord
        LD A, H                             ; prepare to test X bounds
        AND A                               ; are we <= 255
        JR Z, storeX                        ; branch if so, no wrap needed
        ;LD A, L                             ; prepare to test <320
        ;AND %01000000                       ; are we <= 320
        BIT 6, L                            ; are we <=320
        JR Z, storeX                        ; branch if so, no wrap needed
        LD HL, 0                             ; LHS of screen
        ;LD L, 0                             ; LHS of screen
storeX
        LD (IX +strucBalloon.highX), H          ; set new high X
        LD (IX +strucBalloon.lowX), L           ; set new low X

; here we adj how long the balloon is going
; to continue going up or down
        LD A, (IX +strucBalloon.vDelay)         ; get delay
        INC A                               ; add 1
        AND 7                               ; limit 0-7
        LD (IX +strucBalloon.vDelay), A         ; save it
        AND A                               ; is it 0
        JR NZ, balloonYCng1                 ; jump if Not
        CALL random
        AND 7
        OR 3
        LD (IX +strucBalloon.vDelay), A
        LD A, (IX +strucBalloon.swoop)          ; get up/down index
        INC A                               ; add 1
        AND %00011111                       ; limit 0-31
        LD (IX +strucBalloon.swoop), A          ; save it

balloonYCng1
        LD A, (IX +strucBalloon.swoop)          ; get up/down index again !
        LD HL, balloonSwoop                 ; point to swooping data
        ADD HL, A                           ; add index
        LD A, (HL)                          ; get up/down value
        AND A                               ; was it 0
        JR Z, balloonDown                   ; move down if so
        DEC A                               ; what about now, was 1
        JR Z, balloonUp                     ; move up if so
        JP balloonEnd                       ; if originally 2, no up/down

balloonDown
        LD A, (IX +strucBalloon.lowY)
        INC A
        CP maxY
        JR C, clampMaxY1
        LD A, 16
        LD (IX +strucBalloon.swoop), A
        LD A, maxY
clampMaxY1
        LD (IX +strucBalloon.lowY), A
        JP balloonEnd
balloonUp
        LD A, (IX +strucBalloon.lowY)
        DEC A
        CP minY
        JR NC, clampMinY1
        XOR A
        LD (IX +strucBalloon.swoop), A
        LD A, minY
clampMinY1
        LD (IX +strucBalloon.lowY), A
        JP balloonEnd


; Skull has completly different movement
; so handle that here
skull1
        LD A, (IX +strucBalloon.landValue)
        DEC A
        LD (IX +strucBalloon.landValue), A
        JP NZ, balloonEnd
        LD A, skullDelay
        LD (IX +strucBalloon.landValue), A
        CALL random
        AND %00000001
        JR Z, skullX
        JR skullY
skullX
        LD HL, (spriteX)                    ; get Paul's X coord
        LD E, (IX +strucBalloon.lowX)       ; get Skulls X coord
        LD D, (IX +strucBalloon.highX)
        SBC HL, DE                          ; subtract Skull X from Paul's X
        JR C, SkullLeft                     ; Skull was greater, so move Left
        JR SkullRight                       ; otherwise move right
SkullLeft
        DEC DE
        LD (IX +strucBalloon.lowX), E
        LD (IX +strucBalloon.highX), D
        JP balloonEnd
SkullRight
        INC DE
        LD (IX +strucBalloon.lowX), E
        LD (IX +strucBalloon.highX), D
        JP balloonEnd
skullY
        LD HL, (spriteY)
        LD E, (IX +strucBalloon.lowY)
        LD D, 0
        SBC HL, DE
        JR C, SkullUp
        JR SkullDown
SkullUp
        DEC E
        LD (IX +strucBalloon.lowY), E
        JP balloonEnd
SkullDown
        INC E
        LD (IX +strucBalloon.lowY), E
        JR balloonEnd

; 
; handle the toxic drop movement
toxic1
        LD A, (IX +strucBalloon.popDelayL)          ; get the "pop" delay (low byte only used here)
        OR A                                        ; test for 0 (is drop falling?)
        JR Z, .dropToxic                            ; branch if it is falling
        DEC A                                       ; decrease count
        LD (IX +strucBalloon.popDelayL), A          ; save new count
        JP balloonEnd                               ; display toxic drop

.dropToxic
        LD A, (IX +strucBalloon.lowY)               ; get current Y co-ord
        CP maxY                                     ; are we at max?
        JR NC, .resetToxic                          ; branch if we are
        INC A                                       ; add 1 to Y co-ord
        LD (IX +strucBalloon.lowY), A               ; save new co-ord
        JP balloonEnd                               ; display toxic drop

.resetToxic
        LD A, (IX +strucBalloon.index)              ; get the toxic drop sprite index
        LD C, A                                     ; reset routine needs this in C
        CALL createToxic                            ; reset toxic drop to default parameters
        JP balloonEnd                               ; display toxic drop


itemFalling
; this is where Paul has popped a balloon and the item
; is now falling to the ground
; ensure X is such that when landed, it can be collected
; i.e. >=24 <=280 (%00011000 - %100011000)
        LD L, (IX +strucBalloon.lowX)           ; get the
        LD H, (IX +strucBalloon.highX)          ; x co-ord
        LD A, H                             ; get high byte
        AND A                               ; is HL > 255
        JR Z, p2                            ; branch if not
p1
        LD A, L                             ; get low byte
        CP 24                               ; we want < 280
        JR C, p3                            ; branch if it is
        JP balloonR                         ; otherwise keep drifting right
p2
        LD A, L                             ; get low byte
        CP 24                               ; we want > 24
        JR NC, p3                           ; branch if it is
        JP balloonR                         ; otherwise keep drifting right
p3
        LD E, (IX +strucBalloon.lowY)
        INC E
        LD (IX +strucBalloon.lowY), E
        LD A, E
        CP 23                               ; make sure we are below the titles
        JR C, balloonEnd
        CP 248                              ; and not wrapping over the titles
        JR NC, balloonEnd

        CALL itemTileCollision
        LD A, (IX +strucBalloon.landValue)
        LD B, A

; here we keep moving down until we dont hit anything
; then we keep moving down until we do!
; the idea being not to get caught in a block of bricks
        LD A, (hitind)                      ; get the hit ind
        CP B                                ; compare with test value
        JR Z, landtest                      ; match !
        JR balloonEnd                       ; otherwise drift down

landtest
        CP 0                                ; was the land test value 0
        JR NZ, landed                       ; if not, we've landed
        LD A, 31                            ; otherwise, set new seek value
        LD (IX +strucBalloon.landValue), A
        JR balloonEnd

landed
        DEC E
        LD (IX +strucBalloon.lowY), E
        LD A, (IX +strucBalloon.pattern)
        INC A
        LD (IX +strucBalloon.pattern), A
        JR balloonEnd

balloonEnd
        CALL showSP1                        ; show the sprite

        LD BC, strucBalloon                     ; balloon data structure length
        ADD IX, BC                          ; add and hence point to next balloon
        JP balloonUpt1                      ; loop
