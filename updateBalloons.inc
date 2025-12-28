balloonUpt
     ;   RET
        LD IX, balloonSpr                   ; point to balloon data

balloonUpt1
        LD A, (IX +sBalloon.pattern)        ; get balloon pattern
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
DW balloonEnd                               ; pattern  0
DW balloonEnd                               ; pattern  1
DW balloonEnd                               ; pattern  2
DW balloonEnd                               ; pattern  3
DW skull1                                   ; Skull pattern
DW doBalloon                                ; Skull exploding #1
DW doBalloon                                ; Skull exploding #2
DW doBalloon                                ; Skull exploding #3
DW doBalloon                                ; Balloon
DW doBalloon                                ; Balloon popping #1
DW doBalloon                                ; Balloon popping #2
DW doBalloon                                ; Balloon popping #3
DW itemFalling                              ; Heart falling
DW balloonEnd                               ; Heart landed
DW balloonEnd                               ; pattern 14
DW balloonEnd                               ; pattern 15
DW itemFalling                              ; Apple falling
DW balloonEnd                               ; Apple landed
DW balloonEnd                               ; pattern 18
DW balloonEnd                               ; pattern 19
DW itemFalling                              ; Key falling
DW balloonEnd                               ; Key landed
DW balloonEnd                               ; pattern 22
DW balloonEnd                               ; pattern 23
DW itemFalling                              ; Points falling
DW balloonEnd                               ; Points landed
DW balloonEnd                               ; pattern 26
DW balloonEnd                               ; pattern 27
DW itemFalling                              ; Dynamite falling
DW balloonEnd                               ; Dynamite landed
DW balloonEnd                               ; pattern 30
DW balloonEnd                               ; pattern 31
DW balloonEnd                               ; blank sprite
DW toxic1                                   ; Toxic drop

doBalloon
        LD L, (IX +sBalloon.popDelayL)      ; get the pop delay low byte
        LD H, (IX +sBalloon.popDelayH)      ; get the pop delay high byte
        DEC HL                              ; decrease count
        LD (IX +sBalloon.popDelayL), L      ; save low byte
        LD (IX +sBalloon.popDelayH), H      ; save high byte
        LD A, L                             ; is it zero now
        OR H
        JP NZ, moveBalloonRight             ; branch if timer >0

balloonPop
; timer has run out and so we increment the animation by 1 frame
;
        LD A, C                             ; get the balloon pattern
        INC A                               ; add 1
        LD (IX +sBalloon.pattern), A        ; save it

        LD A, C                             ; inspect original pattern
        CP blank
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
        LD A, (IX +sBalloon.newSprite)
        CP Skey
        JR Z, popDone
        LD A, Sskull
        LD (IX +sBalloon.newSprite), A
        LD A, skullDelay
        LD (IX +sBalloon.landValue), A
        
popDone
        LD HL, 15                           ; set a little delay
        LD (IX +sBalloon.popDelayL), L      ; save low byte
        LD (IX +sBalloon.popDelayH), H      ; save high byte
        JP balloonEnd

fullyPopped
; here balloon is fully popped
; we turn it into a skull, heart etc
        LD A, (IX +sBalloon.newSprite)      ; get new sprite value
        LD (IX +sBalloon.pattern), A        ; make this the pattern

        LD A, blank
        LD (IX +sBalloon.newSprite), A

        ; since one balloon has now popped, can we create another
        LD A, (balloonNext)                 ; get next free balloon
        LD B, A                             ; save in B for later
        LD D, B                             ; calculate offset
        LD E, sBalloon
        MUL D, E
        LD IY, balloonSpr
        ADD IY, DE
        LD A, (IY +sBalloon.pattern)        ; get current Pattern
        CP 255                              ; if it's 255, we're at end
        JP Z, balloonEnd
        LD A, Sballoon
        LD (IY +sBalloon.pattern), A
        LD A, B
        INC A
        LD (balloonNext), A
        JP balloonEnd

deadItem
        LD A, blank
        LD (IX +sBalloon.pattern), A
        JP balloonEnd

moveBalloonRight
; move the balloon sprite right a bit
; and wrap to screen start if we are at the RHS
        LD H, (IX +sBalloon.highX)          ; get high X
        LD L, (IX +sBalloon.lowX)           ; get low X

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
        LD (IX +sBalloon.highX), H          ; set new high X
        LD (IX +sBalloon.lowX), L           ; set new low X

; here we adj how long the balloon is going
; to continue going up or down
        LD A, (IX +sBalloon.vDelay)         ; get delay
        INC A                               ; add 1
        AND 7                               ; limit 0-7
        LD (IX +sBalloon.vDelay), A         ; save it
        AND A                               ; is it 0
        JR NZ, balloonYCng1                 ; jump if Not
        CALL random
        AND 7
        OR 3
        LD (IX +sBalloon.vDelay), A
        LD A, (IX +sBalloon.swoop)          ; get up/down index
        INC A                               ; add 1
        AND %00011111                       ; limit 0-31
        LD (IX +sBalloon.swoop), A          ; save it

balloonYCng1
        LD A, (IX +sBalloon.swoop)          ; get up/down index again !
        LD HL, balloonSwoop                 ; point to swooping data
        ADD HL, A                           ; add index
        LD A, (HL)                          ; get up/down value
        AND A                               ; was it 0
        JR Z, balloonDown                   ; move down if so
        DEC A                               ; what about now, was 1
        JR Z, balloonUp                     ; move up if so
        JP balloonEnd                       ; if originally 2, no up/down

balloonDown
        LD A, (IX +sBalloon.lowY)
        INC A
        CP maxY
        JR C, clampMaxY1
        LD A, 16
        LD (IX +sBalloon.swoop), A
        LD A, maxY
clampMaxY1
        LD (IX +sBalloon.lowY), A
        JP balloonEnd
balloonUp
        LD A, (IX +sBalloon.lowY)
        DEC A
        CP minY
        JR NC, clampMinY1
        XOR A
        LD (IX +sBalloon.swoop), A
        LD A, minY
clampMinY1
        LD (IX +sBalloon.lowY), A
        JP balloonEnd


; Skull has completly different movement
; so handle that here
skull1
        LD A, (IX +sBalloon.landValue)
        DEC A
        LD (IX +sBalloon.landValue), A
        JP NZ, balloonEnd
        LD A, skullDelay
        LD (IX +sBalloon.landValue), A
        CALL random
        AND %00000001
        JR Z, skullX
        JR skullY
skullX
        LD HL, (spriteX)                    ; get Paul's X coord
        LD E, (IX +sBalloon.lowX)           ; get Skulls X coord
        LD D, (IX +sBalloon.highX)
        SBC HL, DE                          ; subtract Skull X from Paul's X
        JR C, SkullLeft                     ; Skull was greater, so move Left
        JR SkullRight                       ; otherwise move Left
SkullLeft
        DEC DE
        LD (IX +sBalloon.lowX), E
        LD (IX +sBalloon.highX), D
        JP balloonEnd
SkullRight
        INC DE
        LD (IX +sBalloon.lowX), E
        LD (IX +sBalloon.highX), D
        JP balloonEnd
skullY
        LD HL, (spriteY)
        LD E, (IX +sBalloon.lowY)
        LD D, 0
        SBC HL, DE
        JR C, SkullUp
        JR SkullDown
SkullUp
        DEC E
        LD (IX +sBalloon.lowY), E
        JP balloonEnd
SkullDown
        INC E
        LD (IX +sBalloon.lowY), E
        JR balloonEnd

toxic1
        JP balloonEnd

itemFalling
; this is where Paul has popped a balloon and the item
; is now falling to the ground
; ensure X is such that when landed, it can be collected
; i.e. >=24 <=280 (%00011000 - %100011000)
        LD L, (IX +sBalloon.lowX)           ; get the
        LD H, (IX +sBalloon.highX)          ; x co-ord
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
        LD E, (IX +sBalloon.lowY)
        INC E
        LD (IX +sBalloon.lowY), E
        LD A, E
        CP 23                               ; make sure we are below the titles
        JR C, balloonEnd
        CP 248                              ; and not wrapping over the titles
        JR NC, balloonEnd

        CALL itemTileCollision
        LD A, (IX +sBalloon.landValue)
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
        LD (IX +sBalloon.landValue), A
        JR balloonEnd

landed
        DEC E
        LD (IX +sBalloon.lowY), E
        LD A, (IX +sBalloon.pattern)
        INC A
        LD (IX +sBalloon.pattern), A
        JR balloonEnd

balloonEnd
        CALL showSP1                        ; show the sprite

        LD BC, sBalloon                     ; balloon data structure length
        ADD IX, BC                          ; add and hence point to next balloon
        JP balloonUpt1                      ; loop
