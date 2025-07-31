device ZXSPECTRUMNEXT

INCLUDE "c.inc"



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

; main game start
MP2
        CALL newGame                        ; game start, all lives lost
MP1
        CALL restartGame
loop
        CALL showPaul
        JR C, paulDead

        CALL balloonUpt

        CALL showPaul
        JR C, paulDead
        HALT


        LD HL, (spriteX)
        LD A, H
        CP 1
        JR NZ, pause0
        LD A, L
        CP 40
        JR C, pause0
        CALL levelUp
        JR loop
        ; key H will pause the program
pause0
        LD BC, $bffe
        IN A, (C)
        AND %00010000
        JR NZ, noPause
pause
        HALT
        IN A, (C)
        AND %00010000
        JR NZ, pause

noPause
        ; Key X will end the program
        LD BC, $fefe                        ; port for keys: shift, z, x, c, v
        IN A, (C)                           ; read the port
        AND %00000100                       ; mask bit 2, i.e. x
        JR NZ, loop                          ; branch if x is not pressed
        JR progEnd                          ; otherwise jump to end prog

paulDead
        LD A, (lives)                       ; get current lives
        DEC A                               ; minus 1
        LD (lives), A                       ; save it
        JR NZ, MP1                          ; if not 0, restart level
        JR MP2                              ; otherwise start over
progEnd
        CALL endProg
        NEXTREG $7, 0
        IM 1
        LD BC, tilebmp
        RET



balloonUpt
;        RET
        LD IX, balloonSpr                   ; point to balloon data

balloonUpt1
        LD A, (IX +sprPat)                  ; get pattern
        LD C, A                             ; save pattern
        CP 255                              ; check for finished marker
        RET Z                               ; exit if done

        ADD A, A                            ; each address is 2 bytes
        LD HL, balloonAction                ; get base table
        ADD HL, A                           ; add offset
        LD E, (HL)                          ; transfer
        INC HL                              ; into
        LD D, (HL)                          ; DE
        EX DE, HL                           ; swap DE into HL
        JP (HL)                             ; jump to action required

doBalloon
        LD L, (IX +sprPopDelayL)            ; get the pop delay low byte
        LD H, (IX +sprPopDelayH)            ; get the pop delay high byte
        DEC HL                              ; decrease count
        LD (IX +sprPopDelayL), L            ; save low byte
        LD (IX +sprPopDelayH), H            ; save high byte
        LD A, L                             ; is it zero now
        OR H
        JP NZ, moveBalloonRight             ; branch if timer >0

balloonPop
; timer has run out and so we increment the animation by 1 frame
;
        LD A, C                             ; get the balloon pattern
        INC A                               ; add 1
        LD (IX +sprPat), A                  ; save it

        LD A, C                             ; inspect original pattern
        CP blank
        JP Z, deadItem

        CP balloon +3                       ; is it now fully popped
        JR Z, fullyPopped                   ; branch if so

        CP skull + 3
        JP Z, deadItem

        CP balloon
        JR NZ, popDone

        ; here it should be a balloon that has popped on its own
        ; so turn it into a skull unless the item is the key
        LD A, soundPop
        CALL playsound
        LD A, (IX +sprNewSprite)
        CP key
        JR Z, popDone
        LD A, skull
        LD (IX +sprNewSprite), A

popDone
        LD HL, 15                           ; set a little delay
        LD (IX +sprPopDelayL), L            ; save low byte
        LD (IX +sprPopDelayH), H            ; save high byte
        JP balloonEnd

fullyPopped
; here balloon is fully popped
; we turn it into a skull, heart etc
        LD A, (IX +sprNewSprite)            ; get new sprite value
        LD (IX +sprPat), A                  ; make this the pattern

        LD A, blank
        LD (IX +sprNewSprite), A

        ; since one balloon has now popped, can we create another
        LD A, (balloonNext)                 ; get next free balloon
        LD B, A                             ; save in B for later
        LD D, B                             ; calculate offset
        LD E, balloonSprLen
        MUL D, E
        LD IY, balloonSpr
        ADD IY, DE
        LD A, (IY +sprPat)                  ; get current Pattern
        CP 255                              ; if it's 255, we're at end
        JP Z, balloonEnd
        LD A, balloon
        LD (IY +sprPat), A
        LD A, B
        INC A
        LD (balloonNext), A
        JP balloonEnd

deadItem
        LD A, blank
        LD (IX +sprPat), A
        JP balloonEnd

moveBalloonRight
; move the balloon sprite right a bit
; and wrap to screen start if we are at the RHS
        LD H, (IX +sprHighX)                ; get high X
        LD L, (IX +sprLowX)                 ; get low X

; a pending balloon may decide to continue right
; therefore we need this entry point here
balloonR
        INC HL                              ; +1 the x coord
        LD A, H                             ; prepare to test X bounds
        AND A                               ; are we <= 255
        JR Z, storeX                        ; branch if so, no wrap needed
        LD A, L                             ; prepare to test <320
        AND %01000000                       ; are we <= 320
        JR Z, storeX                        ; branch if so, no wrap needed
        LD H, 0                             ; LHS of screen
        LD L, 0                             ; LHS of screen
storeX
        LD (IX +sprHighX), H                ; set new high X
        LD (IX +sprLowX), L                 ; set new low X

endBalloonRight
; here we adj how long the balloon is going
; to continue going up or down
        LD A, (IX +sprDelay)                ; get delay
        INC A                               ; add 1
        AND 7                               ; limit 0-7
        LD (IX +sprDelay), A                ; save it
        AND A                               ; is it 0
        JR NZ, balloonYCng1                 ; jump if Not
        CALL random
        AND 7
        OR 3
        LD (IX +sprDelay), A
        LD A, (IX +sprSwoop)                ; get up/down index
        INC A                               ; add 1
        AND %00011111                       ; limit 0-31
        LD (IX +sprSwoop), A                ; save it

balloonYCng1
        LD A, (IX +sprSwoop)                ; get up/down index again !
        LD HL, balloonSwoop                 ; point to swooping data
        ADD HL, A                           ; add index
        LD A, (HL)                          ; get up/down value
        AND A                               ; was it 0
        JR Z, balloonDown                   ; move down if so
        DEC A                               ; what about now, was 1
        JR Z, balloonUp                     ; move up if so
        JP balloonEnd                       ; if originally 2, no up/down

balloonDown
        LD A, (IX +sprLowY)
        INC A
        CP maxY
        JR C, clampMaxY1
        LD A, 16
        LD (IX +sprSwoop), A
        LD A, maxY
clampMaxY1
        LD (IX +sprLowY), A
        JP balloonEnd
balloonUp
        LD A, (IX +sprLowY)
        DEC A
        CP minY
        JR NC, clampMinY1
        LD A, 0
        LD (IX +sprSwoop), A
        LD A, minY
clampMinY1
        LD (IX +sprLowY), A
        JP balloonEnd


; Skull has completly different movement
; so handle that here
skull1
        CALL random
        AND %00000001
        JR Z, skullX
        JR skullY
skullX
        LD HL, (spriteX)                    ; get Paul's X coord
        LD E, (IX +sprLowX)                 ; get Skulls X coord
        LD D, (IX +sprHighX)
        SBC HL, DE                          ; subtract Skull X from Paul's X
        JR C, SkullLeft                     ; Skull was greater, so move Left
        JR SkullRight                       ; otherwise move Left
SkullLeft
        DEC DE
        LD (IX +sprLowX), E
        LD (IX +sprHighX), D
        JP balloonEnd
SkullRight
        INC DE
        LD (IX +sprLowX), E
        LD (IX +sprHighX), D
        JP balloonEnd
skullY
        LD HL, (spriteY)
        LD E, (IX +sprLowY)
        LD D, 0
        SBC HL, DE
        JR C, SkullUp
        JR SkullDown
SkullUp
        DEC E
        LD (IX +sprLowY), E
        JP balloonEnd
SkullDown
        INC E
        LD (IX +sprLowY), E
        JR balloonEnd

toxic1
        JP balloonEnd

itemFalling
; this is where Paul has popped a balloon and the item
; is now falling to the ground
; ensure X is such that when landed, it can be collected
; i.e. >=24 <=280 (%00011000 - %100011000)
        LD L, (IX +sprLowX)                 ; get the
        LD H, (IX +sprHighX)                ; x co-ord
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
        LD E, (IX +sprLowY)
        INC E
        LD (IX +sprLowY), E
        LD A, E
        CP 23                               ; make sure we are below the titles
        JR C, balloonEnd
        CP 248                              ; and not wrapping over the titles
        JR NC, balloonEnd

        CALL itemTileCollision
        LD A, (IX +sprLandValue)
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
        LD (IX +sprLandValue), A
        JR balloonEnd

landed
        DEC E
        LD (IX +sprLowY), E
        LD A, (IX +sprPat)
        INC A
        LD (IX +sprPat), A
        JR balloonEnd

balloonEnd
        CALL showSP1

        LD BC, balloonSprLen
        ADD IX, BC
        JP balloonUpt1


balloonSwoop
        DB 0,0,0,1,2,0,0,0,1,0,0,0,2,1,1,0,0,2,1,1,1,2,0,1,1,1,1,0,2,1,1,2

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

maxX EQU 320
minX EQU 0
maxY EQU 240
minY EQU 24



showPaul1
        LD IX, manSprite
        CALL showSP
        CALL showManRels
;        HALT
;        HALT
;        HALT
;        HALT
        RET

riseCnt        DB 18

strengthInd    DB 1

jumping        EQU 0
falling        EQU 1
nothing        EQU 0
left           EQU 1
right          EQU 2
facingLeft     EQU 2
facingRight    EQU 0

leftRightCount DB 2
leftRightDelay DB 2

keyDelay       DB 5
keyDelayInit   EQU 5
; Pauls health indicator
; if he hits a baddie or bangs his head then the delay is reduced by 3
; when delay is zero then health reduces by 1 and delay is set to default
health         DB 15
healthDelay    DB 7
healthDefault  EQU 15

boxGreen     EQU 9
boxAmber     EQU 10
boxRed       EQU 11
boxBlank     EQU 12

showPaul
        LD A, (keyDelay)                    ; we only intercept keystrokes every so often    
        DEC A
        LD (keyDelay), A
        JR NZ, showPaul0

        LD A, keyDelayInit
        LD (keyDelay), A

keyDown
        LD BC, $fefe                        ; read keyboard up/down
        IN A, (C)
        BIT 1, A
        JR NZ, keyUp
        LD A, (strengthInd)
        CP 0
        JR Z, keyUp
        DEC A
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
        LD A, (riseCnt)                     ; determine vertical direction
        DEC A
        JP M, paulFalling
        LD (riseCnt), A
        JP Z, paulFalling                   ; branch if so

paulRising
        DEC (IX +sprLowY)                   ; otherwise move Paul up
        JR doLeftRight                      ; end of rise processing

paulFalling
        INC (IX +sprLowY)                   ; move Paul down

doLeftRight
; so here we decide if Paul is allowed to move left/right
; it is restricted so that movement resembles a sin wave
; so only when the counter is 0, movement is allowed
        LD A, (leftRightCount)              ; get L/R countdown
        DEC A                               ; decrease it
        LD (leftRightCount), A              ; save it
        JP NZ, leftrightEnd                 ; if not theres no horizontal mvmt

        LD A, (leftRightDelay)              ; set L/R countdown default
        LD (leftRightCount), A              ; save it

        LD A, (IX +sprDirH)                 ; get the horizontal movement
        CP nothing                          ; is it 0
        JR Z, leftrightEnd                  ; 0 = up/down only
        CP left                             ; is it 1
        JR Z, paulLeft                      ; 1 = left
        CP right                            ; is it 2
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
;        LD A, (IX +sprDirH)
;        CALL DispA
;        LD IY, tileMapData +997
;        LD A, (hitLind)
;        CALL DispA
;        LD IY, tileMapData +1037
;        LD A, (hitRind)
;        CALL DispA
;        LD A, (hitind1)
;        AND A
;        CALL NZ, showPaul1
;        LD A, (hitind1)
;        AND A
;        CALL NZ, keySpace


        LD A, (hitind)
        AND A
        JP Z, paulFinish

; here xy coords have been updated and we have detected a collision
; has occured
; hitind1 is the top pixel line with collision
; hitind  is the lowest pixel line with collision
tileCollision
        LD A, (hitind1)                     ; get high point of hit
        CP 31                               ; bottom of pogo stick?
        JP Z, bounce                        ; this is a bounce

        CP 26                               ; near bottom of pogo stick
        JR C, tileCollision1                ; branch if not
                                            ; but check low point to ensure
;        LD A, (hitind)                      ; that it's still a bounce
;        CP 31
;        JR NZ tileCollision1                ; branch if its not

        CALL reverseX1                      ; kinda bounce but reverse any
        JP bounce                           ; left/right movement and bounce

tileCollision1
        LD A, (riseCnt)
        AND A
        JR Z, hitFalling
        JR hitRising

; hit whilst rising
hitRising
        LD A, soundHithead
        CALL playsound

        LD A, (hitind1)                     ; see highpoint of hit
        CP 8
        JR NC, hitRising1                   ; dont decrease health if so

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
        INC (IX +sprLowY)                   ; move Paul down

        LD A, 0                             ; Paul is now falling
        LD (riseCnt), A                     ; set it

        LD A, (hitind1)                     ; don't pause l/r movement
        CP 6                                ; if its just Paul's head
        JP Z, paulFinish

        LD A, 0
        LD (IX +sprDirH), A
        JP paulFinish


hitFalling
        ; hit whilst falling, but it is not a bounce?!
        LD A, (hitLind)
        LD B, A
        LD A, (hitRind)
        LD C, A
        LD A, (IX +sprPat)
        CP facingLeft
        JR Z, fallingLeft
        JR fallingRight

fallingLeft
        LD A, B
        AND C
        CP 1
        JR Z, FLEnd
        LD A, B
        CP 1
        JR Z, FLhitL
        JR FLhitR

FLhitL
        CALL reverseX1
        JR FLEnd
FLhitR
        CALL movePaulLeft
        JR FLEnd

fallingRight
        LD A, B
        AND C
        CP 1
        JR Z, FLEnd
        LD A, C
        CP 1
        JR Z, FRhitR
        JR FRhitL
FRhitR
        CALL reverseX1
        JR FLEnd
FRhitL
        CALL movePaulRight
        JR FLEnd

FLEnd
        DEC (IX +sprLowY)
        LD A, nothing
        LD (IX +sprDirH), A
        LD A, (hitind)
        CP 31
        JR Z, bounce
        JP paulFinish

bounce
; here we were either falling and glanced or fully hit the ground
; - make the bounce sound
; - if we were falling, then change to jumping
; - if we were jumping then continue jumping
        LD A, (strengthInd)
        SLA A
        SLA A
        AND %00011111
        OR 3
        LD (sound3Dur), A                   ; set duration related to strength
        LD A, soundBounce
        CALL playsound

        DEC (IX +sprLowY)                   ; move Paul up

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

        LD BC, $7ffe                        ; ready keypoard port
        IN A, (C)                           ; read it
        AND %00000001                       ; mask except spacebar
        XOR %00000001                       ; reverse so press = 1
        LD B, A                             ; save in B
        LD A, (dynamiteCnt)                 ; see if we have any dynamite
        AND B                               ; if press and dynamite
        CALL NZ, killSkulls                 ; kill the skulls

        CALL chkCollide                     ; check balloon collision
        CALL showHealth
        LD A, (health)                      ; get health value
        AND A                               ; see if it's zero
        RET NZ                              ; return if not
        SCF                                  ; otherwise set carry flag
        RET                                 ; and return, dead

killSkulls
        PUSH IY
        LD IY, balloonSpr
        LD A, (balloonSprCnt)
        LD C, 0                             ; skull kill count
        LD B, A                             ; "balloons" to process
ks0
        LD A, (IY +sprPat)                  ; get pattern
        CP skull                            ; was it a skull
        JR NZ, ks1                          ; branch if not, next to test
        INC A                               ; +1 to pattern -> explosion
        LD (IY +sprPat), A                  ; set it
        LD HL, 15                           ; and a little pop delay
        LD (IY +sprPopDelayH), H
        LD (IY +sprPopDelayL), L
        INC C                               ; increase killed skulls count
ks1
        LD DE, balloonSprLen
        ADD IY, DE
        DJNZ ks0
        POP IY
        LD A, C                             ; get killed skulls count
        AND A                               ; was it 0
        RET Z                               ; return if so
ks2
        LD A, soundKillskull                ; make sound fx
        CALL playsound
        LD A, 0                             ; dynamite is exhausted
        LD (dynamiteCnt), A
        CALL showDynamite
        RET

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
        LD (IX +sprPat), A
        LD A, left
        LD (IX +sprDirH), A

keyRight
        LD BC, $dffe                        ; keys Y U I O P
        IN A, (C)
        BIT 0, A
        JR NZ, keyEnd

        LD A, facingRight
        LD (IX +sprPat), A
        LD A, right
        LD (IX +sprDirH), A

keyEnd
        RET


; this shows a Pogo power meter on screen
showPower
        LD A, (strengthInd)                 ; strength 1-16
        LD E, A                             ; save it in E
        LD B, 15                            ; 15 bars to display
        LD C, 40                            ; tile next line displacement
        LD HL, tileMapData +121             ; start at top
        CALL powerColour                    ; get power colour in D
showPower2
        LD A, E                             ; get E
        CP B                                ; compare with B
        JR NC, setPC                        ; branch if B <= A
        LD A, boxBlank                      ; set box to empty colour
        JR setPC1
setPC
        LD A, D                             ; set box to power colour
setPC1
        LD (HL), A                          ; put power colour tile on screen
        LD A, C                             ; get tile displacement
        ADD HL, A                           ; ready for next line down
        DJNZ showPower2                     ; loop for all 15 bars
        RET

powerColour
        LD A, E
        LD D, boxRed
        CP 12
        JR NC, PCend
        LD D, boxAmber
        CP 7
        JR NC, PCend
        LD D, boxGreen
PCend
        RET

; this shows a Paul health meter on screen
showHealth
        LD A, (features)                    ; get the page features
        BIT 0, A                            ; bit 0 signifies show health
        RET NZ                              ; return if its not set
        LD A, (health)                      ; get current health
        LD B, 15                            ; there are 15 health boxes
        LD C, 40                            ; tile next line displacement
        LD E, A                             ; save in E for later
        LD HL, tileMapData +158             ; top of health boxes
        CALL healthColour                   ; get the tile to use in D
showHealth2
        LD A, E                             ; get the health
        CP B                                ; compare with current box
        JR NC, setHC                        ;
        LD A, boxBlank
        JR setHC1
setHC
        LD A, D                             ; get the health tile to display
setHC1
        LD (HL), A                          ; put on screen
        LD A, C                             ; get tile displacement
        ADD HL, A                           ; ready for next line down
        DJNZ showHealth2                    ; loop for all 15 bars
        RET

healthColour
        LD A, E                             ; get the health
        LD D, boxGreen                      ; default to Green box
        CP 12                               ; is health GE 12
        JR NC, HCend                        ; jump if so
        LD D, boxAmber                      ; default to Orange
        CP 9                                ; is health GE 9
        JR NC, HCend                        ; jump if so
        LD D, boxRed                        ; default to Red
HCend
        RET


movePaulRight
        LD L, (IX +sprLowX)                 ; add 1 to X coord
        LD H, (IX +sprHighX)                ; i.e. move RIGHT
        INC HL
        LD (IX +sprLowX), L
        LD (IX +sprHighX), H
        RET

movePaulLeft
        LD L, (IX +sprLowX)                 ; deduct 1 from X coord
        LD H, (IX +sprHighX)                ; i.e. move LEFT
        DEC HL
        LD (IX +sprLowX), L
        LD (IX +sprHighX), H
        RET

reverseX1
 ;       LD A, (IX +sprDirH)
        LD A, (IX +sprPat)
        CP facingLeft
 ;       CP left
        JR Z, movePaulRight
 ;       CP right
        CP facingRight
        JR Z, movePaulLeft
        RET
;rx1Left
;        CALL xPlus1
;        RET
;rx1Right
;        CALL xMinus1
;        RET

bounceTable
        DB 16, 24, 32, 36, 40, 44, 48, 52, 56, 60, 64 , 68, 72, 76, 80, 84
        DB   4,  4,  4,  4,  4,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6



newGame
; first time in OR lives all lost and starting over
;
        CALL ULAon
        CALL killSprites

        LD HL, 0
        LD (score), HL
        LD A, 0
        LD (dynamiteCnt), A
        LD (keyCnt), A
        LD A, 3
        LD (lives), A

        LD A, 15
        LD (volume), A
        LD A, splashLevel
        CALL createLevel
        CALL setupBalloon
        CALL instructions
        LD IY, tScroll                      ; point to scrolling instructions
        LD H, 1                             ; first scroll delay
        LD L, textLines                     ; count of text lines
waitSpace
        CALL doScroll
        PUSH HL
        PUSH IY
        CALL showPaul
        POP IY
        POP HL
waitSpace1
        HALT
        LD BC, $7ffe                        ; port for keys: space sym m n b
        IN A, (C)                           ; read port
        BIT 0, A                            ; is space pressed
        JR NZ, waitSpace                    ; branch if not pressed
        LD A, 12
        LD (volume), A
        LD A, 0
        LD (LEVEL), A
        JR commonInit

restartGame
; life lost, so restart
        CALL killSprites                    ; remove all sprites from screen
        LD IX, balloonSpr                   ; point to balloon data

; here we turn all skulls back into balloons
restartGame1
        LD A, (IX +sprPat)                  ; get balloon pattern
        CP 255                              ; are we at the end
        JR Z, commonInit                    ; branch if so
        CP skull                            ; is pattern a skull
        JR NZ, restartGame2                 ; branch over if not
        LD A, balloon                       ; change skull back to balloon
        LD (IX +sprPat), A                  ; - set pattern
        LD HL, 0                            ;
        LD (IX +sprLowX), L                 ; - set X coord as lhs
        LD (IX +sprHighX), H                ;
restartGame2
        LD A, (IX +sprIndex)                ; - set pop delay
        LD C, A
        LD A, 255
        LD (IX +sprPopDelayL), A
        LD A, C
        ADD 2
        SLA A
        LD (IX +sprPopDelayH), A

        LD DE, balloonSprLen
        ADD IX, DE
        JR restartGame1

levelUp
        CALL killSprites
        LD A, 0
        LD (dynamiteCnt), A
        LD (keyCnt), A
        CALL paulInit
        LD A, (LEVEL)
        INC A
        LD (LEVEL), A
        CALL createLevel
        CALL setupBalloon
        CALL showTitles
        CALL showLevel
        RET

commonInit
; these need doing on life lost or new game
        CALL ULAoff
        CALL paulInit
        LD A, (LEVEL)
        CALL createLevel                    ; create and show tilemap
        CALL showTitles                     ; show titles etc
        CALL showLevel
        RET

paulInit
        ; initialise Paul with starting data
        LD IX, manSprite
        LD A, facingRight
        LD (IX +sprPat), A
        LD A, nothing
        LD (IX +sprDirH), A
        LD A, 1
        LD (strengthInd), A
        LD A,18
        LD (riseCnt), A
        LD A, 15                            ; max health
        LD (health), A                      ; set it
        LD A, healthDefault                 ; health delay default
        LD (healthDelay), A                 ; set it
        LD A, 0
        LD (dynamiteCnt), A

        RET

showLevel
        ; this just save a portion of the screen
        ; to display a message and then it is restored
        LD HL, tileMapData +650             ; save this portion of tilemap
        LD DE, levelStore
        LD BC, 20
        LDIR 
        LD HL, tileMapData +650 +80         ; save this portion of tilemap
        LD BC, 20
        LDIR 

        ; display the message
        LD IY, tLevel1                      ; show "Level"
        CALL DispT
        LD IY, tLevel2                      ; show "Press Space"
        CALL DispT
        LD A, (LEVEL)
        INC A
        LD IY, iyLevel                      ; show the actual level number
        CALL DispA1
        CALL keySpace                       ; wait for space bar

        ; put the screen back to how it was
        LD HL, levelStore
        LD DE, tileMapData +650
        LD BC, 20
        LDIR 
        LD DE, tileMapData +650 +80
        LD BC, 20
        LDIR 
        RET

createLevel
; A passed with room number 0-9 to create
        LD IY, roomData                     ; point to base room/level data
        LD E, A                             ; get the room number into E
        LD D, levelLen                      ; get the room data length
        MUL D, E                            ; multiply
        ADD IY, DE                          ; hence room data for A
        LD E, (IY +0)                       ; get layout low address in E
        LD D, (IY +1)                       ; get layout high address in D

        LD A, (IY +2)                       ; get balloon count for level
        LD (balloonSprCnt), A               ; save it

        LD A, (IY +3)                       ; get max on screen for level
        LD (maxOnScreen), A                 ; save it

        LD A, (IY +4)                       ; get special features
        LD (features), A                    ; sav it

        LD IX, manSprite                    ; ready to set initial Paul data
        LD L, (IY +5)                       ; X coord
        LD H, (IY +6)
        LD (IX +sprLowX), L
        LD (IX +sprHighX), H
        LD L, (IY +7)                       ; Y coord
        LD H, (IY +8)
        LD (IX +sprLowY), L
        LD (IX +sprHighY), H

        CALL createTileMap
        RET

maxLevel EQU 8
levelLen EQU 9
splashLevel EQU 9

roomData
; tilemap location of room
; target balloons to pop
; feature byte
;   bit 7
;   bit 6
;   bit 5
;   bit 4
;   bit 3
;   bit 2
;   bit 1
;   bit 0 - 1 = disable keyboard for level (splash instruction screen)

; level 0
        DW page000                          ; address of screen data
        DB 10                               ; level balloon count
        DB 5                                ; level max on screen
        DB %00000000                        ; feature byte
        DW 144                              ; Paul's starting X
        DW 216                              ; Paul's starting Y

        DW page001                           ; level 1
        DB 11
        DB 5
        DB %00000000
        DW 144, 216

        DW page002                          ; level 2
        DB 12
        DB 5
        DB %00000000
        DW 144, 216

        DW page003                          ; level 3
        DB 13
        DB 5
        DB %00000000
        DW 144, 216

        DW page004                           ; level 4
        DB 14
        DB 5
        DB %00000000
        DW 144, 216

        DW page005                           ; level 5
        DB 15
        DB 5
        DB %00000000
        DW 144, 216

        DW page006                           ; level 6
        DB 16
        DB 5
        DB 0
        DW 144, 216

        DW page007                           ; level 7
        DB 17
        DB 5
        DB 0
        DW 144, 216

        DW page008                           ; level 8
        DB 18
        DB 5
        DB 0
        DW 144, 216

        DW page009                           ; level 9  instructions
        DB 10
        DB 5
        DB %00000001
        DW 72, 64


createTileMap
; DE passed with address of room data to display
        LD HL, tileMapData      ; HL points to the tileMap address
        EX DE, HL               ; swap them over
                                ; HL = screen definition
                                ; DE = tilemap address
CTM2
        LD A, (HL)              ; get tile to display
        INC HL                  ; point to the tile count to display
        LD B, (HL)              ; put count in B
        INC HL                  ; ready for next tile
CTM1
        LD (DE), A              ; put tile on the screen
        INC DE                  ; point to next address
        DJNZ CTM1               ; loop until this tile complete
        LD A, D
        CP $65                  ; at end DE=$6500
        JR NZ, CTM2             ; loop for next tile
CTME
        RET                      ; return


showTitles
        CALL showPower
        LD IY, tPower1
        CALL DispT
        LD IY, tPower2
        CALL DispT
        LD IY, tPower3
        CALL DispT
        LD IY, tPower4
        CALL DispT
        LD IY, tPower5
        CALL DispT
        LD IY, tPower6
        CALL DispT
        LD IY, tPower7
        CALL DispT
        LD IY, tPower8
        CALL DispT
        LD IY, tPower9
        CALL DispT

        CALL showHealth
        LD IY, tHealth1
        CALL DispT
        LD IY, tHealth2
        CALL DispT
        LD IY, tHealth3
        CALL DispT
        LD IY, tHealth4
        CALL DispT
        LD IY, tHealth5
        CALL DispT
        LD IY, tHealth6
        CALL DispT


        LD IY, tScore1
        CALL DispT
        LD IY, tHiScore
        CALL DispT
        LD IY, tLives
        CALL DispT

        CALL showScore
        CALL showHiScore
        CALL showLives
        CALL showDynamite
        CALL showKey

        LD IX, balloonTemp
        LD (IX +sprIndex), 52
        LD (IX +sprPat), dynamite
        LD (IX +sprLowX), 32
        LD (IX +sprHighX), 0
        LD (IX +sprLowY), 224
        CALL showSP1
        LD (IX +sprIndex), 53
        LD (IX +sprPat), key
        LD (IX +sprLowX), 56
        LD (IX +sprHighX), 0
        LD (IX +sprLowY), 224
        CALL showSP1

        RET

showScore
        PUSH IY
        LD IY, iyScore
        LD HL, (score)
        CALL DispHL
        POP IY
        OR A
        LD DE, (hiscore)
        SBC HL, DE
        JR NC, uptHiScore
        RET
uptHiScore
        LD HL, (score)
        LD (hiscore), HL
showHiScore
        PUSH IY
        LD HL, (hiscore)
        LD IY, iyHiScore
        CALL DispHL
        POP IY
        RET

showLives
        PUSH IY
        LD IY, iyLives
        LD A, (lives)
        CALL DispA1
        POP IY
        RET

showDynamite
        LD A, (dynamiteCnt)
        LD B, tileCross
        AND A
        JR Z, showDynamite1
        INC B
showDynamite1
        LD HL, iyDynamite
        LD (HL), B
        RET
showKey
        LD A, (keyCnt)
        LD B, tileCross
        AND A
        JR Z, showKey1
        INC B
        LD A, 0
        LD HL, tileMapData +917
        LD (HL), A
        INC HL
        LD (HL), A
        INC HL
        LD (HL), A
        ADD HL, 38
        LD (HL), A
        INC HL
        LD (HL), A
        INC HL
        LD (HL), A
        ADD HL, 38
        LD (HL), A
        INC HL
        LD (HL), A
        INC HL
        LD (HL), A
        ADD HL, 38
        LD (HL), A
        INC HL
        LD (HL), A
        INC HL
        LD (HL), A
showKey1
        LD HL, iyKey
        LD (HL), B
        RET

doScroll
        DEC H                               ; -1 for scroll delay
        RET NZ                              ; return if not ready
        LD H, 30                            ; set delay for next scroll

        PUSH HL                             ; save scroll info
        LD B, 8                             ; count of lines to scroll
        LD HL, tileMapData +840             ; initial from
        LD DE, tileMapData +800             ; initial to
scroll
        PUSH HL
        PUSH DE
        PUSH BC
        LD BC, 40                           ; each line is 40 chars
        LDIR                                 ; do the scroll
        POP BC
        POP DE
        POP HL
        LD A, 40                            ; next line down
        ADD HL, A
        ADD DE, A
        DJNZ scroll                         ; repeat for all lines

        PUSH IY
        CALL DispT
        POP IY
        POP HL

        LD DE, 43                           ; instruction line is 43 chars
        ADD IY, DE                          ; point to next line
        DEC L                               ; see if we need to loop around
        RET NZ                              ; return if not
        LD IY, tScroll                      ; reset to start
        LD L, textLines                     ; and reset lines
        RET

instructions
        LD IY, tInst1
        CALL DispT

        LD IY, tInst2
        CALL DispT

        LD IY, tInst3
        CALL DispT

        LD IX, balloonTemp
        LD (IX +sprIndex), 52
        LD (IX +sprPat), 8
        LD (IX +sprLowX), 208
        LD (IX +sprHighX), 0
        LD (IX +sprLowY), 8
        CALL showSP1
        LD (IX +sprIndex), 53
        LD (IX +sprPat), 8
        LD (IX +sprLowX), 232
        LD (IX +sprHighX), 0
        LD (IX +sprLowY), 24
        CALL showSP1

        LD IX, manSprite
        LD A, 1
        LD (strengthInd), A
        LD A, 18
        LD (riseCnt), A
        LD A, nothing
        LD (IX +sprDirH), A
        CALL showPaul1

        RET

tPower1      DB   6, 0, "p", 255
tPower2      DB   7, 0, "o", 255
tPower3      DB   8, 0, "g", 255
tPower4      DB   9, 0, "o", 255
tPower5      DB 11, 0, "p", 255
tPower6      DB 12, 0, "o", 255
tPower7      DB 13, 0, "w", 255
tPower8      DB 14, 0, "e", 255
tPower9      DB 15, 0, "r", 255

tHealth1     DB   8,39, "h", 255
tHealth2     DB   9,39, "e", 255
tHealth3     DB 10,39, "a", 255
tHealth4     DB 11,39, "l", 255
tHealth5     DB 12,39, "t", 255
tHealth6     DB 13,39, "h", 255

tScore1      DB 0, 1, "score", 255
tHiScore     DB 0, 15, "hiscore", 255
tLives       DB 0, 30, "lives", 255

tInst1       DB 15,  0, " o: jump left         p: jump right     ", 255
tInst2       DB 17,  0, " a: increase bounce   z: decrease bounce", 255
tInst3       DB 31,  9, "press space to begin", 255

textLines EQU 31
tScroll
       DB 28,  0, " ", 164, 165, " pop the balloons before they burst  ", 255
       DB 28,  0, " ", 166, 167, " for the chance to collect a reward  ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, " ", 160, 161, " take too long and they'll turn into ", 255
       DB 28,  0, " ", 162, 163, " these nasties, they are deadly !    ", 255
       DB 28,  0, "                                        ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, " collect any rewards once they land ... ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, " ", 180, 181, " grab the points booster, rack 'em up", 255
       DB 28,  0, " ", 182, 183, " every point counts                  ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, " ", 172, 173, " apples are good for you             ", 255
       DB 28,  0, " ", 174, 175, " snag this for a juicy health boost  ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, " ", 168, 169, " you can't live forever but this     ", 255
       DB 28,  0, " ", 170, 171, " will award an extra life            ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, " ", 184, 185, " use this to blast those nasties     ", 255
       DB 28,  0, " ", 186, 187, " press 'space' in game to activate   ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, " ", 176, 177, " find the key to unlock your         ", 255
       DB 28,  0, " ", 178, 179, " escape route and level up           ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, " oh yeah, don't bang your head too much ", 255
       DB 28,  0, " it'll sap your health                  ", 255
       DB 28,  0, "                                        ", 255
       DB 28,  0, "                                        ", 255
       DB 28,  0, "                                        ", 255
       DB 28,  0, "                                        ", 255
       DB 28,  0, "                                        ", 255

tLevel1      DB 16, 16, "level", 255
tLevel2      DB 18, 10, "press space to begin", 255

iyScore      EQU tileMapData + 7
iyHiScore    EQU tileMapData +23
iyLives      EQU tileMapData + 36
iyLevel      EQU tileMapData +662
iyDynamite   EQU tileMapData +1205
iyKey        EQU tileMapData +1208
tileCross    EQU 13
tileTick     EQU 14


score        DW 0
hiscore      DW 0
lives        DB 3
dynamiteCnt  DB 0
keyCnt       DB 0
features     DB 0
LEVEL        DB 0

levelStore   DEFS 60, 0

random1
        PUSH HL
        PUSH DE
        PUSH BC
        LD HL, LFSRSeed +4
        LD E, (HL)
        INC HL
        LD D, (HL)
        INC HL
        LD C, (HL)
        INC HL
        LD A, (HL)
        LD B, A
        RL E
        RL D
        RL C
        RL A
        RL E
        RL D
        RL C
        RL A
        RL E
        RL D
        RL C
        RL A
        LD H, A
        RL E
        RL D
        RL C
        RL A
        XOR B
        RL E
        RL D
        XOR H
        XOR C
        XOR D
        LD HL, LFSRSeed +6
        LD DE, LFSRSeed +7
        LD BC, 7
        LDDR 
        LD (DE), A
        POP BC
        POP DE
        POP HL
        RET

random
        LD A, (rseed)
        LD D, A
        RRCA 
        RRCA 
        RRCA 
        XOR $1f
        ADD A, D
        SBC A, 255
        LD (rseed),A
        RET

randomY
        CALL random1
        AND %00001111
        LD HL, rndY
        ADD HL, A
        LD A, (HL)
        RET
randomX
        CALL random1
        AND %00001111
        SLA A
        LD HL, rndX
        ADD HL, A
        LD A, (HL)
        LD D, A
        INC HL
        LD A, (HL)
        LD H, A
        LD L, D
        RET

keySpace
        LD BC, $7ffe                        ; port for keys: space, sym, mnb
        IN A, (C)                           ; read port
        BIT 0, A                            ; test for space key
        RET Z                               ; return if pressed
        JR keySpace                         ; otherwise loop

LFSRSeed DB $12, $34, $56, $78, $9a, $bc, $de, $f0
rseed    DB 1
rndY     DB 24,32,48,64,80,96,104,120,136,152,168,176,192,208,224,240
rndX     DW 0,16,40,64,80,104,128,144,168,192,208,232,256,272,296,320



endProg
        CALL killSprites

        LD A, $6b               ; ready to read tilemap control $6b
        CALL ReadNextReg        ; do the read
        AND %01111111           ; just run off bit 7 to disable tilemap
        NEXTREG $6b, A          ; do the write

        LD A, $15               ; ready to read sprites and layers system $15
        CALL ReadNextReg        ; do the read
        AND %11111110           ; just turn off bit 0 to disable sprites
        NEXTREG $15, A          ; do the write

        LD A, 255
        LD BC, AYSelect
        OUT (C), A
        LD D,7
        LD BC, AYSelect
        OUT (C), D
        LD BC, AYrw
        LD A, 255
        OUT (C), A

        LD A, 254
        LD BC, AYSelect
        OUT (C), A
        LD D, 7
        LD BC, AYSelect
        OUT (C), D
        LD A, 255
        LD BC, AYrw
        OUT (C), A

        LD A, 253
        LD BC, AYSelect
        OUT (C), A
        LD D, 7
        LD BC, AYSelect
        OUT (C), A
        LD A, 255
        LD BC, AYrw
        OUT (C), A


        CALL ULAon
        RET                      ; return to basic

killSprites
        LD A, 0
        LD B, 127
KS1
        NEXTREG $34, A
        NEXTREG $35, 0
        NEXTREG $36, 0
        NEXTREG $37, 0
        NEXTREG $38, 0
        NEXTREG $39, 0

        INC A
        DJNZ KS1
        RET

ULAoff
        LD A, $68
        CALL ReadNextReg
        OR %10000000
        NEXTREG $68, A
        RET
ULAon
        LD A, $68
        CALL ReadNextReg
        AND %01111111
        NEXTREG $68, A
        RET

ReadNextReg
        PUSH BC
        LD BC, $243b
        OUT (C), A
        INC B
        IN A, (C)
        POP BC
        RET




setupIM2:
; sub routine to set-up IM2 to point to BB
; example
;       ld b, $c8
;       call setupIM2
;
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





showSP
        LD A, (IX +sprIndex)    ; get the sprite index
        NEXTREG $34, A          ; set sprite to activate

        LD A, (IX +sprLowX)     ; get sprite X lsb
        NEXTREG $35, A          ; set attr byte 0 of port $0057

        LD A, (IX +sprLowY)     ; get sprite Y lsb
        NEXTREG $36, A          ; set attr byte 1 of port $0057

        LD A, (IX +sprHighX)    ; get sprite X msb
        AND 1                   ; only need bit 0 of X msb
        NEXTREG $37, A          ; bits 7-4 palette offset
                                ;        3 1=enable X mirroring
                                ;        2 1=enable Y mirroring
                                ;        1 1=rotate 90 clockwise
                                ;        0 msb of X
                                ; this is attr byte 2 of port $0057
        LD A, (IX +sprPat)      ; get pattern index to use
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
        LD A, (IX +sprIndex)    ; get the sprite index
        NEXTREG $34, A          ; set sprite to activate
        LD A, (IX +sprLowX)     ; get sprite X lsb
        NEXTREG $35, A          ; set attr byte 0 of port $0057
        LD A, (IX +sprLowY)     ; get sprite Y lsb
        NEXTREG $36, A          ; set attr byte 1 of port $0057
        LD A, (IX +sprHighX)    ; get sprite X msb
        AND 1                   ; only need bit 0 of X msb
        NEXTREG $37, A          ; bits 7-4 palette offset

        LD A, (IX +sprPat)      ; get pattern index to use

        OR %10000000            ;
        NEXTREG $38, A          ; bits 7 1=make sprite visible
        RET

showManRels
        LD A, (IX +sprIndex)    ; set first RELATIVE sprite
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


sprIndex       EQU 0
sprLowX        EQU 1
sprHighX       EQU 2
sprLowY        EQU 3
sprHighY       EQU 4
sprDelay       EQU 5
sprSwoop       EQU 6
sprPopDelayL   EQU 7
sprPopDelayH   EQU 8
sprNewSprite   EQU 9
sprDirV        EQU 10
sprLandValue   EQU 10
sprDirH        EQU 11
sprPat         EQU 12

manSprite      DB 50
spriteX        DW 88
spriteY        DW 200
spriteTX       DW 48
spriteTY       DW 192
spriteO        DB 0
spriteDirV     DB 0
spriteDirH     DB 0
manPat         DB 0

toxic          EQU 33
skull          EQU 4
balloon        EQU 8
blank          EQU 32
heart          EQU 12
apple          EQU 16
key            EQU 20
points         EQU 24
dynamite       EQU 28

balloonSprLen  EQU 13                       ; balloon record length
balloonMaxCnt  EQU 21                       ; max balloons and room allocated
balloonSprCnt  DB 0                         ; balloon count remaining for level
maxOnScreen    DB 0                         ; max allowed on screen at a time
balloonNext    DB 0                         ; next free balloon

balloonTemp    DEFS balloonSprLen
balloonSpr     DEFS balloonSprLen * balloonMaxCnt
; 00 - 00 = this is the index for the sprite system 0 - 99
; 01 - 02 = X coord
; 03 - 04 = Y coord
; 05 - 05 = delay - used by balloon sprite to delay up/down movement
; 06 - 06 = swoop - used by balloon sprite, index into array to decide up/down
; 07 - 08 = pop delay - used by balloon sprite
; 09 - 09 = new sprite pattern IF popped by Paul
; 10 - 10 = direction Vertical (Paul)     land seek value (balloon)
; 11 - 11 = direction Horizontal (Paul)
; 12 - 12 = sprite pattern

setupBalloon
             LD IX, balloonSpr              ; point to balloon data
             LD A, (balloonSprCnt)
             LD B, A
             LD C, 0
setupBalloon1
             CALL createBalloon
             LD DE, balloonSprLen
             ADD IX, DE
             INC C
             DJNZ setupBalloon1

             LD A, 255
             LD (IX +sprPat), A
             LD A, (maxOnScreen)
             INC A
             LD (balloonNext), A
             RET

createBalloon
             LD A, C                        ; get sprite index
             LD (IX +sprIndex), A           ; set in balloon data

             CALL randomY                   ; get a random Y coord in A
             LD (IX +sprLowY), A            ; set in balloon data
             LD A, 0                        ; set the high Y coord byte to 0
             LD (IX +sprHighY), A           ; set in balloon data

             CALL random                    ; get a random number in A
             AND %00011111                  ; limit to 0-31
             LD (IX +sprSwoop), A           ; set in balloon data

             ; this determines how long it will take
             ; before the balloon auto pops
             ; and turns into a skull
             LD A, 255                      ; initialise low byte pop delay
             LD (IX +sprPopDelayL), A       ; set it
             LD A, C                        ; initialise high byte pop delay
             ADD 2                          ; use balloon index + 1
             SLA A
             LD (IX +sprPopDelayH), A       ; set it

             LD A, 0                        ;
             LD (IX +sprLandValue), A

             LD A, (maxOnScreen)
             CP B
             JR NC, offScreen

onScreen
             LD A, balloon                  ; on screen, so pattern is balloon
             LD (IX +sprPat), A

             CALL randomX                   ; get a random X coord in HL
             LD (IX +sprLowX), L            ; set in balloon data
             LD (IX +sprHighX), H           ; set in balloon data
             JR setupEnd

offScreen
             LD A, blank                    ; off screen, so pattern is blank
             LD (IX +sprPat), A
             LD HL, 0                       ; set X as 0
             LD (IX +sprLowX), L            ; set in balloon data
             LD (IX +sprHighX), H           ; set in balloon data
             JR setupEnd

setupEnd
; get a random number 0-15
; item will be assigned as follows
; 07 blank      38%  0 -  5
; 24 points     24%  6 -  9
; 16 apple      24% 10 - 13
; 12 heart       7%      14
; 28 dynamite    7%      15
        LD A, B                             ; get the count of balloons
        DEC A                               ; are we on the last one
        JR Z, assignKey                     ; branch if so
assignItem1
        CALL random1
        AND %00001111
        LD HL, items
        ADD HL, A
        LD A, (HL)
        LD (IX +sprNewSprite), A       ; may spawn into

        RET
assignKey
        LD A, (keyCnt)
        AND A
        JR NZ, assignItem1
        LD A, key
        LD (IX +sprNewSprite), A       ; may spawn into

        RET

items
        DB blank
        DB blank
        DB blank
        DB blank
        DB blank
        DB blank
        DB points
        DB points
        DB points
        DB points
        DB apple
        DB apple
        DB apple
        DB apple
        DB heart
        DB dynamite



playsound:
; Input : A = sound fx to play
;
; routine will choose next available channel and copy sound fx to that channel
; IM2 will then process that data
        PUSH HL
        PUSH DE
        PUSH BC

        DEC A
        SLA A
        SLA A
        SLA A
        SLA A

        LD HL, sound1
        ADD HL, A

        LD A, (nextCH)                  ; whats the nextCH to use
        CP 0                            ; is it 0?
        JR Z, playCh1                   ; jump if so
        CP 1                            ; is it 1?
        JR Z, playCh2                   ; jump if so
        LD A, 255                       ; its 2, set next so its 0
        LD DE, Ch3                      ; set AY channel to 3
        JR play                         ; and branch to do the sound setup
playCh1:
        LD DE, Ch1                      ; set the AY channel to 1
        JR play                         ; and branch to do the sound setup
playCh2:
        LD DE, Ch2                      ; set the AY channel to 2
play:
        INC A                           ; roll on nextCH
        LD (nextCH), A                  ; and save it
        LD BC, 10                       ; we copy 10 bytes of sound setup
        LDIR                             ; do the copy

        POP BC
        POP DE
        POP HL
        RET

sound1:
; initial tone period
; tone period delta
; initial volme (*256)
; volume delta
; tone, noise, envelope flags
; length in frames (50hz)

; hit head sound
        DW 500
        DW 10
        DW 15 * 256
        DW 20
        DB %00000001
        DB 5
        DB 0,0,0,0,0,0

; this is the pop sound
sound2:
        DW 100
        DW 10
        DW 15*256
        DW -20
        DB %0000001
        DB 10
        DB 0,0,0,0,0,0

; bounce sound
sound3:
        DW 252
        DW -10
        DW 15*256
        DW -100
        DB 1
sound3Dur
        DB 15
        DB 0,0,0,0,0,0

sound4:
        DW 100
        DW -10
        DW 15*256
        DW -100
        DB 3
        DB 5
        DB 0,0,0,0,0,0

; item hit sound
sound5:
        DW 100
        DW -10
        DW 15*256
        DW 20
        DB %0000001
        DB 10
        DB 0,0,0,0,0,0

; kill skull sound
sound6:
        DW 500
        DW 10
        DW 15*256
        DW 20
        DB %11111111
        DB 100
        DB 0,0,0,0,0,0

nextCH:      DB 0

Ch1:
Ch1Pitch:    DW 0
Ch1PitchD:   DW 0
Ch1Volume    DW 00
Ch1VolumeD:  DW 00
Ch1Flags:    DB 0
Ch1Length:   DB 0

Ch2:
Ch2Pitch:    DW 00
Ch2PitchD:   DW 00
Ch2Volume    DW 00
Ch2VolumeD:  DW 00
Ch2Flags:    DB 0
Ch2Length:   DB 0

Ch3:
Ch3Pitch:    DW 00
Ch3PitchD:   DW 00
Ch3Volume    DW 00
Ch3VolumeD:  DW 00
Ch3Flags:    DB 0
Ch3Length:   DB 0

soundHithead   EQU 1
soundPop       EQU 2
soundBounce    EQU 3
soundHitskull  EQU 4
soundCollect   EQU 5
soundKillskull EQU 6



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

inkBit EQU 7
paperBit EQU 0

; this needs to be 4096 - (number of chars * 32)
mychars EQU TilePatterns + 2752

convertChars:
             LD IX, mychars
             LD DE, charSet
convertChars1:
             LD A, (DE)
             CP 255
             RET Z
             CALL convertChar
             INC DE
             JR convertChars1
             RET

convertChar:
             PUSH DE
             SUB 32
             LD D, A
             LD E, 8
             MUL D, E
             LD IY, 15616
             ADD IY, DE
             LD C, 8
cc0:
             LD B, 4
             LD A, (IY)
cc1:
             LD H, 0
             SLA A
             CALL setBit
             SLA A
             CALL setBit
             LD (IX), H
             INC IX
             DJNZ cc1
             INC IY
             DEC C
             JR NZ, cc0
             POP DE
             RET

setBit
             LD L, A
             JR C, bitSet
             JR bitNotSet
sb1          LD A, L
             RET
bitSet
             SLA H
             SLA H
             SLA H
             SLA H
             LD A, H
             OR inkBit
             LD H, A
             JR sb1
bitNotSet
             SLA H
             SLA H
             SLA H
             SLA H
             LD A, H
             OR paperBit
             LD H, A
             JR sb1
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

; 1 bit per pixel bitmaps (like old school ZX Spectrum)
; space needed is (char width +1 space) * (char height +1 space) * 8
; Paul is    2+1 wide  x 4+1 tall
; Balloon is 2+1 wide by 2+1 tall
; Skull is   2+1 wide by 2+1 tall
; Set-up by calling "buildbmp" below

paulbmpR    DEFS 120, 0                      ; Paul facing right
paulbmpL    DEFS 120, 0                      ; Paul facing left
balloonbmp  DEFS 72, 0                       ; Balloon
skullbmp    DEFS 72, 0                       ; Skull
toxicbmp    DEFS 72, 0

heartbmp    DEFS 72, 0
applebmp    DEFS 72, 0
keybmp      DEFS 72, 0
pointsbmp   DEFS 72, 0
dynamitebmp DEFS 72, 0


; bitmap of first 32 tiles, 32 x 8 = 256
; the remaining files are used for the text output
tilebmp  DEFS 256, 0


hitind  DB 0
hitind1 DB 0
hitRind DB 0
hitLind DB 0

paulTileCollision
        LD A, 0                             ; no hit
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
        LD A, (IX +sprLowY)             ; get the Y pixel coord
        AND %00000111                   ; mask to get portion into next char
        LD D, A                         ; we then multiply by 3 because
        LD E, 3                         ; of starting at the RHS of the
        MUL D, E                        ; 5x3 tile bitmap

        LD HL, tileBmpMap +2            ; point to RHS of the map
        ADD HL, DE                      ; move down DE pixels

        LD A, (IX +sprLowX)             ; now get the X pixel coord
        AND %00000111                   ; similarly mask of 0-7
        LD B, A                         ; how many pixels into next char across

        LD A, (IX +sprPat)              ; get Sprite patten
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
        LD A, 0
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
        LD A, (IX +sprLowY)             ; get the Y pixel coord
        AND %00000111                   ; mask to get portion into next char
        LD D, A                         ; we then multiply by 3 because
        LD E, 3                         ; of starting at the RHS of the
        MUL D, E                        ; 5x3 tile bitmap

        LD HL, tileBmpMap +47           ; point to RHS of the map
        ADD HL, DE                      ; move down DE pixels

        LD A, (IX +sprLowX)             ; now get the X pixel coord
        AND %00000111                   ; similarly mask of 0-7
        LD B, A                         ; how many pixels into next char across

        LD A, (IX +sprPat)
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

buildbmp
        LD D, 0                         ; set the sprite number to convert
        LD C, 32                        ; set pixel lines in sprite
        LD IX, paulbmpR                 ; point to destination bmp
        CALL buildbmp0                  ; convert

        LD D, 2
        LD C, 32
        LD IX, paulbmpL
        CALL buildbmp0

        LD D, balloon
        LD C, 16
        LD IX, balloonbmp
        CALL buildbmp0

        LD D, skull
        LD C, 16
        LD IX, skullbmp
        CALL buildbmp0

        LD D, heart
        LD C, 16
        LD IX, heartbmp
        CALL buildbmp0

        LD D, apple
        LD C, 16
        LD IX, applebmp
        CALL buildbmp0

        LD D, key
        LD C, 16
        LD IX, keybmp
        CALL buildbmp0

        LD D, points
        LD C, 16
        LD IX, pointsbmp
        CALL buildbmp0

        LD D, dynamite
        LD C, 16
        LD IX, dynamitebmp
        CALL buildbmp0

        CALL bitmapTiles
        RET

buildbmp0
        LD E, 0                         ; sprites are 256b
        LD HL, SpritePatterns           ; set base for pattern
        ADD HL, DE                      ; add in offset

        LD D, C                         ; loop for all pixel lines
spriteLoop
        LD C, 2                         ; byte loop for 2 x 8 pixel defs
build0
        LD B, 8                         ; loop for 8 defs to make our bm byte
        LD E, 0                         ; initialse our bitmap byte
build1
        LD A, (HL)                      ; get a pixel def
        AND A                           ; is it 0
        JR Z, bit0                      ; jump if its 0
        JR bit1                         ; jump if its 1
build2
        INC HL                          ; point to next pixel def
        DJNZ build1                     ; loop if more
        LD (IX +0), E                   ; set bitmap byte
        INC IX                          ; ready for next bitmap byte
        DEC C                           ; dec byte loop
        JR NZ, build0                   ; loop if more bytes

        INC IX                          ; skip over the bitmap right pad
        DEC D                           ; dec pixel line count
        JR NZ, spriteLoop               ; loop if more pixel lines
        RET

bit0
        SLA E
        JR build2
bit1
        SLA E
        SET 0, E
        JR build2

build3x5
; build a 3x5 bitmap of tilemap data where sprite currently is
; IX = sprite in question

        LD E, (IX +sprLowX)                 ; get X char coord
        LD D, (IX +sprHighX)                ; i.e. X pixel / 8
        LD B, 3
        BSRA DE,B
        LD B, E                             ; B = X pixel / 8

        LD A, (IX +sprLowY)                 ; get Y char coord
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
        SLA A                               ; multiply by 8
        SLA A                               ; to point to udg we want
        SLA A
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


bitmapTiles
        LD HL, TilePatterns         ; point to tile patterns data
        LD IX, tilebmp              ; point to our bipmap store
        LD D, 32                    ; convert tiles 0-31
tileloop
        LD C, 8                     ; 8 lines to a tile
lineloop
        LD B, 4                     ; 4 bytes to a line
        LD E, 0                     ; initialise bitmap byte
fourByteLoop
        LD A, (HL)                  ; get pattern data (2 pixels)
        AND %11110000               ; test first nibble
        JR Z, nib10                 ; branch if 0
        JR nib11                    ; branch if not 0
nib1Done
        LD A, (HL)                  ; get pattern data (2 pixels)
        AND %00001111               ; test second nibble
        JR Z, nib20                 ; branch if 0
        JR nib21                    ; branch if not 0
nib2Done
        INC HL                      ; point to next byte of pattern data
        DJNZ fourByteLoop           ; loop if more for this line

        LD (IX +0), E               ; bitmap byte created, so save it
        INC IX                      ; and ready for next
        DEC C                       ; decrease line loop
        JR NZ, lineloop             ; loop if more

        DEC D                       ; decrease tile loop
        JR NZ, tileloop             ; loop if more
        RET

nib10
        SLA E
        JR nib1Done
nib11
        SLA E
        SET 0, E
        JR nib1Done
nib20
        SLA E
        JR nib2Done
nib21
        SLA E
        SET 0, E
        JR nib2Done








chkCollide
; get Paul's 1bit bitmap depending on his direction
        LD IX, manSprite
        LD A, (IX +sprPat)
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
        LD A, 0
        LD (collisionInd), A

        LD A, (IX +sprPat)
        CP 255
        RET Z

        PUSH IX
        CALL chkSprite1
        POP IX

        LD A, (collisionInd)
        AND A
        RET NZ
        LD DE, balloonSprLen
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
        LD (IY +sprNewSprite), A
itemHitCommon
        LD (IY +sprPat), A
        LD A, 0
        LD (IY +sprPopDelayH), A
        LD A, 15
        LD (IY +sprPopDelayL), A
        AND A
        RET

noAction
        RET

CS1
        LD (spriteBitmap), BC               ; save off location of 1bit bitmap
        LD (collisionInx), IX               ; and the balloon in question
doYDiff
        LD A, (spriteY)                     ; get Paul's Y coord
        LD B, (IX +sprLowY)                 ; get Balloon Y coord
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
        LD E, (IX +sprLowX)
        LD D, (IX +sprHighX)
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



melodyData:
T2_0: DB 189,0,15,94,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_1: DB 84,0,15,168,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_2: DB 212,0,15,106,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_3: DB 126,0,15,252,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_4: DB 224,0,15,112,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_5: DB 141,0,15,27,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_6: DB 189,0,15,121,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_7: DB 168,0,15,80,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_8: DB 212,0,15,168,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_9: DB 252,0,15,248,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_10: DB 224,0,15,193,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_11: DB 27,1,15,54,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_12: DB 121,1,15,243,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_13: DB 80,1,15,161,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_14: DB 168,1,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_15: DB 248,1,15,240,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_16: DB 193,1,15,130,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_17: DB 248,1,15,240,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_18: DB 22,2,15,44,4,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_19: DB 54,2,15,107,4,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_20: DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_21: DB 141,0,15,27,1,15,224,0,15,189,0,15,107,4,15,214,8,15
T2_22: DB 121,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_23: DB 100,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_24: DB 80,1,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_25: DB 212,0,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_26: DB 212,0,15,168,1,15,54,2,15,161,2,15,0,0,0,0,0,0
T2_27: DB 80,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_28: DB 212,0,15,107,4,15,54,2,15,0,0,0,0,0,0,0,0,0
T2_29: DB 80,1,15,220,1,15,54,2,15,168,1,15,0,0,0,0,0,0
T2_30: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_31: DB 212,0,15,246,4,15,123,2,15,0,0,0,0,0,0,0,0,0
T2_32: DB 212,0,15,168,1,15,248,1,15,0,0,0,0,0,0,0,0,0
T2_33: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_34: DB 212,0,15,65,5,15,161,2,15,0,0,0,0,0,0,0,0,0
T2_35: DB 106,0,15,65,5,15,161,2,15,168,0,15,212,0,15,0,0,0
T2_36: DB 159,0,15,189,0,15,94,0,15,54,2,15,168,1,15,0,0,0
T2_37: DB 178,0,15,89,0,15,150,0,15,0,0,0,0,0,0,0,0,0
T2_38: DB 84,0,15,141,0,15,168,0,15,107,4,15,0,0,0,0,0,0
T2_39: DB 106,0,15,168,0,15,212,0,15,107,4,15,0,0,0,0,0,0
T2_40: DB 94,0,15,189,0,15,159,0,15,168,1,15,161,2,15,54,2,15
T2_41: DB 168,0,15,141,0,15,84,0,15,0,0,0,0,0,0,0,0,0
T2_42: DB 168,0,15,141,0,15,84,0,15,107,4,15,0,0,0,0,0,0
T2_43: DB 112,0,15,189,0,15,224,0,15,107,4,15,0,0,0,0,0,0
T2_44: DB 94,0,15,159,0,15,189,0,15,193,1,15,54,2,15,123,2,15
T2_45: DB 94,0,15,159,0,15,189,0,15,0,0,0,0,0,0,0,0,0
T2_46: DB 106,0,15,168,0,15,212,0,15,79,3,15,0,0,0,0,0,0
T2_47: DB 106,0,15,168,0,15,212,0,15,168,1,15,54,2,15,161,2,15
T2_48: DB 106,0,15,168,0,15,212,0,15,0,0,0,0,0,0,0,0,0
T2_49: DB 106,0,15,168,0,15,212,0,15,161,2,15,54,2,15,168,1,15
T2_50: DB 121,1,15,193,1,15,54,2,15,0,0,0,0,0,0,0,0,0
T2_51: DB 100,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_52: DB 80,1,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_53: DB 212,0,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_54: DB 212,0,15,54,2,15,168,1,15,161,2,15,0,0,0,0,0,0
T2_55: DB 80,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_56: DB 212,0,15,107,4,15,54,2,15,0,0,0,0,0,0,0,0,0
T2_57: DB 80,1,15,54,2,15,220,1,15,168,1,15,0,0,0,0,0,0
T2_58: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_59: DB 212,0,15,246,4,15,123,2,15,0,0,0,0,0,0,0,0,0
T2_60: DB 212,0,15,168,1,15,248,1,15,0,0,0,0,0,0,0,0,0
T2_61: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_62: DB 212,0,15,161,2,15,65,5,15,0,0,0,0,0,0,0,0,0
T2_63: DB 0,0,0,161,2,15,65,5,15,0,0,0,0,0,0,0,0,0
T2_64: DB 212,0,15,126,0,15,252,0,15,200,2,15,145,5,15,0,0,0
T2_65: DB 212,0,15,27,1,15,141,0,15,0,0,0,0,0,0,0,0,0
T2_66: DB 212,0,15,150,0,15,44,1,15,243,2,15,230,5,15,0,0,0
T2_67: DB 252,0,15,126,0,15,0,0,0,243,2,15,230,5,15,0,0,0
T2_68: DB 106,0,15,212,0,15,168,1,15,243,2,15,87,2,15,248,1,15
T2_69: DB 84,0,15,168,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_70: DB 84,0,15,168,0,15,243,2,15,0,0,0,0,0,0,0,0,0
T2_71: DB 189,0,15,94,0,15,243,2,15,0,0,0,0,0,0,0,0,0
T2_72: DB 212,0,15,106,0,15,168,1,15,248,1,15,87,2,15,0,0,0
T2_73: DB 126,0,15,252,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_74: DB 94,0,15,159,0,15,189,0,15,54,2,15,193,1,15,0,0,0
T2_75: DB 94,0,15,159,0,15,189,0,15,107,4,15,54,2,15,0,0,0
T2_76: DB 94,0,15,159,0,15,189,0,15,0,0,0,0,0,0,0,0,0
T2_77: DB 94,0,15,159,0,15,189,0,15,240,3,15,248,1,15,0,0,0
T2_78: DB 121,1,15,130,3,15,193,1,15,0,0,0,0,0,0,0,0,0
T2_79: DB 100,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_80: DB 80,1,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_81: DB 212,0,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_82: DB 212,0,15,168,1,15,54,2,15,161,2,15,0,0,0,0,0,0
T2_83: DB 80,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_84: DB 212,0,15,107,4,15,54,2,15,0,0,0,0,0,0,0,0,0
T2_85: DB 80,1,15,220,1,15,54,2,15,168,1,15,0,0,0,0,0,0
T2_86: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_87: DB 212,0,15,246,4,15,123,2,15,0,0,0,0,0,0,0,0,0
T2_88: DB 212,0,15,168,1,15,248,1,15,0,0,0,0,0,0,0,0,0
T2_89: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_90: DB 212,0,15,65,5,15,161,2,15,0,0,0,0,0,0,0,0,0
T2_91: DB 106,0,15,65,5,15,161,2,15,168,0,15,212,0,15,0,0,0
T2_92: DB 159,0,15,189,0,15,94,0,15,54,2,15,168,1,15,0,0,0
T2_93: DB 178,0,15,89,0,15,150,0,15,0,0,0,0,0,0,0,0,0
T2_94: DB 84,0,15,141,0,15,168,0,15,107,4,15,0,0,0,0,0,0
T2_95: DB 106,0,15,168,0,15,212,0,15,107,4,15,0,0,0,0,0,0
T2_96: DB 94,0,15,189,0,15,159,0,15,168,1,15,161,2,15,54,2,15
T2_97: DB 168,0,15,141,0,15,84,0,15,0,0,0,0,0,0,0,0,0
T2_98: DB 168,0,15,141,0,15,84,0,15,107,4,15,0,0,0,0,0,0
T2_99: DB 189,0,15,112,0,15,224,0,15,107,4,15,0,0,0,0,0,0
T2_100: DB 159,0,15,189,0,15,94,0,15,193,1,15,54,2,15,123,2,15
T2_101: DB 159,0,15,189,0,15,94,0,15,0,0,0,0,0,0,0,0,0
T2_102: DB 106,0,15,168,0,15,212,0,15,79,3,15,0,0,0,0,0,0
T2_103: DB 106,0,15,168,0,15,212,0,15,168,1,15,54,2,15,161,2,15
T2_104: DB 106,0,15,168,0,15,212,0,15,0,0,0,0,0,0,0,0,0
T2_105: DB 106,0,15,168,0,15,212,0,15,80,1,15,54,2,15,168,1,15
T2_106: DB 212,0,15,106,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_107: DB 189,0,15,94,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_108: DB 168,0,15,84,0,15,168,1,15,79,3,15,0,0,0,0,0,0
T2_109: DB 212,0,15,106,0,15,168,1,15,79,3,15,0,0,0,0,0,0
T2_110: DB 189,0,15,94,0,15,80,1,15,168,1,15,54,2,15,0,0,0
T2_111: DB 84,0,15,168,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_112: DB 84,0,15,168,0,15,220,1,15,183,3,15,0,0,0,0,0,0
T2_113: DB 212,0,15,106,0,15,220,1,15,183,3,15,0,0,0,0,0,0
T2_114: DB 189,0,15,94,0,15,54,2,15,168,1,15,80,1,15,0,0,0
T2_115: DB 106,0,15,212,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_116: DB 84,0,15,168,0,15,248,1,15,240,3,15,0,0,0,0,0,0
T2_117: DB 106,0,15,212,0,15,248,1,15,240,3,15,0,0,0,0,0,0
T2_118: DB 94,0,15,189,0,15,61,1,15,168,1,15,248,1,15,0,0,0
T2_119: DB 168,0,15,84,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_120: DB 168,0,15,84,0,15,22,2,15,44,4,15,0,0,0,0,0,0
T2_121: DB 106,0,15,212,0,15,22,2,15,44,4,15,0,0,0,0,0,0
T2_122: DB 94,0,15,189,0,15,22,2,15,168,1,15,61,1,15,0,0,0
T2_123: DB 212,0,15,106,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_124: DB 84,0,15,141,0,15,168,0,15,54,2,15,107,4,15,0,0,0
T2_125: DB 106,0,15,168,0,15,212,0,15,54,2,15,107,4,15,0,0,0
T2_126: DB 94,0,15,189,0,15,159,0,15,80,1,15,168,1,15,54,2,15
T2_127: DB 168,0,15,141,0,15,84,0,15,0,0,0,0,0,0,0,0,0
T2_128: DB 168,0,15,141,0,15,84,0,15,107,4,15,0,0,0,0,0,0
T2_129: DB 189,0,15,112,0,15,224,0,15,107,4,15,0,0,0,0,0,0
T2_130: DB 159,0,15,189,0,15,94,0,15,54,2,15,193,1,15,0,0,0
T2_131: DB 159,0,15,189,0,15,94,0,15,0,0,0,0,0,0,0,0,0
T2_132: DB 106,0,15,168,0,15,212,0,15,168,1,15,79,3,15,54,2,15
T2_133: DB 106,0,15,168,0,15,212,0,15,54,2,15,107,4,15,0,0,0
T2_134: DB 106,0,15,168,0,15,212,0,15,0,0,0,0,0,0,0,0,0
T2_135: DB 106,0,15,168,0,15,212,0,15,240,3,15,248,1,15,0,0,0
T2_136: DB 121,1,15,193,1,15,130,3,15,0,0,0,0,0,0,0,0,0
T2_137: DB 100,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_138: DB 80,1,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_139: DB 212,0,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_140: DB 212,0,15,168,1,15,54,2,15,161,2,15,0,0,0,0,0,0
T2_141: DB 80,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_142: DB 212,0,15,107,4,15,54,2,15,0,0,0,0,0,0,0,0,0
T2_143: DB 80,1,15,220,1,15,54,2,15,168,1,15,0,0,0,0,0,0
T2_144: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_145: DB 212,0,15,246,4,15,123,2,15,0,0,0,0,0,0,0,0,0
T2_146: DB 212,0,15,168,1,15,248,1,15,0,0,0,0,0,0,0,0,0
T2_147: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_148: DB 212,0,15,65,5,15,161,2,15,0,0,0,0,0,0,0,0,0
T2_149: DB 106,0,15,65,5,15,161,2,15,168,0,15,212,0,15,0,0,0
T2_150: DB 159,0,15,189,0,15,94,0,15,54,2,15,168,1,15,0,0,0
T2_151: DB 178,0,15,89,0,15,150,0,15,0,0,0,0,0,0,0,0,0
T2_152: DB 84,0,15,141,0,15,168,0,15,107,4,15,0,0,0,0,0,0
T2_153: DB 106,0,15,168,0,15,212,0,15,107,4,15,0,0,0,0,0,0
T2_154: DB 94,0,15,189,0,15,159,0,15,168,1,15,161,2,15,54,2,15
T2_155: DB 168,0,15,141,0,15,84,0,15,0,0,0,0,0,0,0,0,0
T2_156: DB 168,0,15,141,0,15,84,0,15,107,4,15,0,0,0,0,0,0
T2_157: DB 112,0,15,189,0,15,224,0,15,107,4,15,0,0,0,0,0,0
T2_158: DB 94,0,15,159,0,15,189,0,15,193,1,15,54,2,15,123,2,15
T2_159: DB 94,0,15,159,0,15,189,0,15,0,0,0,0,0,0,0,0,0
T2_160: DB 106,0,15,168,0,15,212,0,15,79,3,15,0,0,0,0,0,0
T2_161: DB 106,0,15,168,0,15,212,0,15,168,1,15,54,2,15,161,2,15
T2_162: DB 106,0,15,168,0,15,212,0,15,0,0,0,0,0,0,0,0,0
T2_163: DB 106,0,15,168,0,15,212,0,15,161,2,15,54,2,15,168,1,15
T2_164: DB 121,1,15,193,1,15,54,2,15,0,0,0,0,0,0,0,0,0
T2_165: DB 100,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_166: DB 80,1,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_167: DB 212,0,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_168: DB 212,0,15,54,2,15,168,1,15,161,2,15,0,0,0,0,0,0
T2_169: DB 80,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_170: DB 212,0,15,107,4,15,54,2,15,0,0,0,0,0,0,0,0,0
T2_171: DB 80,1,15,54,2,15,220,1,15,168,1,15,0,0,0,0,0,0
T2_172: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_173: DB 212,0,15,246,4,15,123,2,15,0,0,0,0,0,0,0,0,0
T2_174: DB 212,0,15,168,1,15,248,1,15,0,0,0,0,0,0,0,0,0
T2_175: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_176: DB 212,0,15,161,2,15,65,5,15,0,0,0,0,0,0,0,0,0
T2_177: DB 0,0,0,161,2,15,65,5,15,0,0,0,0,0,0,0,0,0
T2_178: DB 212,0,15,126,0,15,252,0,15,200,2,15,145,5,15,0,0,0
T2_179: DB 212,0,15,27,1,15,141,0,15,0,0,0,0,0,0,0,0,0
T2_180: DB 212,0,15,150,0,15,44,1,15,243,2,15,230,5,15,0,0,0
T2_181: DB 252,0,15,126,0,15,0,0,0,243,2,15,230,5,15,0,0,0
T2_182: DB 106,0,15,212,0,15,168,1,15,243,2,15,87,2,15,248,1,15
T2_183: DB 84,0,15,168,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_184: DB 84,0,15,168,0,15,243,2,15,0,0,0,0,0,0,0,0,0
T2_185: DB 189,0,15,94,0,15,243,2,15,0,0,0,0,0,0,0,0,0
T2_186: DB 212,0,15,106,0,15,168,1,15,248,1,15,87,2,15,0,0,0
T2_187: DB 126,0,15,252,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_188: DB 94,0,15,159,0,15,189,0,15,54,2,15,193,1,15,0,0,0
T2_189: DB 94,0,15,159,0,15,189,0,15,107,4,15,54,2,15,0,0,0
T2_190: DB 94,0,15,159,0,15,189,0,15,0,0,0,0,0,0,0,0,0
T2_191: DB 94,0,15,159,0,15,189,0,15,240,3,15,248,1,15,0,0,0
T2_192: DB 121,1,15,130,3,15,193,1,15,0,0,0,0,0,0,0,0,0
T2_193: DB 100,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_194: DB 80,1,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_195: DB 212,0,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_196: DB 212,0,15,168,1,15,54,2,15,161,2,15,0,0,0,0,0,0
T2_197: DB 80,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_198: DB 212,0,15,107,4,15,54,2,15,0,0,0,0,0,0,0,0,0
T2_199: DB 80,1,15,220,1,15,54,2,15,168,1,15,0,0,0,0,0,0
T2_200: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_201: DB 212,0,15,246,4,15,123,2,15,0,0,0,0,0,0,0,0,0
T2_202: DB 212,0,15,168,1,15,248,1,15,0,0,0,0,0,0,0,0,0
T2_203: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_204: DB 212,0,15,65,5,15,161,2,15,0,0,0,0,0,0,0,0,0
T2_205: DB 106,0,15,65,5,15,161,2,15,168,0,15,212,0,15,0,0,0
T2_206: DB 159,0,15,189,0,15,94,0,15,54,2,15,168,1,15,0,0,0
T2_207: DB 178,0,15,89,0,15,150,0,15,0,0,0,0,0,0,0,0,0
T2_208: DB 84,0,15,141,0,15,168,0,15,107,4,15,0,0,0,0,0,0
T2_209: DB 106,0,15,168,0,15,212,0,15,107,4,15,0,0,0,0,0,0
T2_210: DB 94,0,15,189,0,15,159,0,15,168,1,15,161,2,15,54,2,15
T2_211: DB 168,0,15,141,0,15,84,0,15,0,0,0,0,0,0,0,0,0
T2_212: DB 168,0,15,141,0,15,84,0,15,107,4,15,0,0,0,0,0,0
T2_213: DB 189,0,15,112,0,15,224,0,15,107,4,15,0,0,0,0,0,0
T2_214: DB 159,0,15,189,0,15,94,0,15,193,1,15,54,2,15,123,2,15
T2_215: DB 159,0,15,189,0,15,94,0,15,0,0,0,0,0,0,0,0,0
T2_216: DB 106,0,15,168,0,15,212,0,15,79,3,15,0,0,0,0,0,0
T2_217: DB 106,0,15,168,0,15,212,0,15,168,1,15,54,2,15,161,2,15
T2_218: DB 106,0,15,168,0,15,212,0,15,0,0,0,0,0,0,0,0,0
T2_219: DB 106,0,15,168,0,15,212,0,15,80,1,15,54,2,15,168,1,15
T2_220: DB 212,0,15,106,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_221: DB 189,0,15,94,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_222: DB 168,0,15,84,0,15,168,1,15,79,3,15,0,0,0,0,0,0
T2_223: DB 212,0,15,106,0,15,168,1,15,79,3,15,0,0,0,0,0,0
T2_224: DB 189,0,15,94,0,15,80,1,15,168,1,15,54,2,15,0,0,0
T2_225: DB 84,0,15,168,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_226: DB 84,0,15,168,0,15,220,1,15,183,3,15,0,0,0,0,0,0
T2_227: DB 212,0,15,106,0,15,220,1,15,183,3,15,0,0,0,0,0,0
T2_228: DB 189,0,15,94,0,15,54,2,15,168,1,15,80,1,15,0,0,0
T2_229: DB 106,0,15,212,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_230: DB 84,0,15,168,0,15,248,1,15,240,3,15,0,0,0,0,0,0
T2_231: DB 106,0,15,212,0,15,248,1,15,240,3,15,0,0,0,0,0,0
T2_232: DB 94,0,15,189,0,15,61,1,15,168,1,15,248,1,15,0,0,0
T2_233: DB 168,0,15,84,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_234: DB 168,0,15,84,0,15,22,2,15,44,4,15,0,0,0,0,0,0
T2_235: DB 106,0,15,212,0,15,22,2,15,44,4,15,0,0,0,0,0,0
T2_236: DB 94,0,15,189,0,15,22,2,15,168,1,15,61,1,15,0,0,0
T2_237: DB 212,0,15,106,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_238: DB 84,0,15,141,0,15,168,0,15,54,2,15,107,4,15,0,0,0
T2_239: DB 106,0,15,168,0,15,212,0,15,54,2,15,107,4,15,0,0,0
T2_240: DB 94,0,15,189,0,15,159,0,15,80,1,15,168,1,15,54,2,15
T2_241: DB 168,0,15,141,0,15,84,0,15,0,0,0,0,0,0,0,0,0
T2_242: DB 168,0,15,141,0,15,84,0,15,107,4,15,0,0,0,0,0,0
T2_243: DB 189,0,15,112,0,15,224,0,15,107,4,15,0,0,0,0,0,0
T2_244: DB 159,0,15,189,0,15,94,0,15,54,2,15,193,1,15,0,0,0
T2_245: DB 159,0,15,189,0,15,94,0,15,0,0,0,0,0,0,0,0,0
T2_246: DB 106,0,15,168,0,15,212,0,15,168,1,15,79,3,15,54,2,15
T2_247: DB 106,0,15,168,0,15,212,0,15,54,2,15,107,4,15,0,0,0
T2_248: DB 106,0,15,168,0,15,212,0,15,79,3,15,159,6,15,0,0,0
T2_249: DB 212,0,15,168,0,15,80,1,15,79,3,15,159,6,15,0,0,0
T2_250: DB 159,0,15,61,1,15,189,0,15,0,0,0,0,0,0,0,0,0
T2_251: DB 44,1,15,150,0,15,178,0,15,0,0,0,0,0,0,0,0,0
T2_252: DB 27,1,15,168,0,15,141,0,15,159,6,15,79,3,15,0,0,0
T2_253: DB 168,0,15,126,0,15,252,0,15,80,1,15,168,1,15,54,2,15
T2_254: DB 141,0,15,27,1,15,168,0,15,0,0,0,0,0,0,0,0,0
T2_255: DB 141,0,15,27,1,15,168,0,15,107,4,15,0,0,0,0,0,0
T2_256: DB 212,0,15,168,0,15,80,1,15,107,4,15,0,0,0,0,0,0
T2_257: DB 189,0,15,61,1,15,159,0,15,54,2,15,168,1,15,80,1,15
T2_258: DB 44,1,15,150,0,15,178,0,15,0,0,0,0,0,0,0,0,0
T2_259: DB 27,1,15,168,0,15,141,0,15,79,3,15,0,0,0,0,0,0
T2_260: DB 168,0,15,126,0,15,252,0,15,80,1,15,168,1,15,54,2,15
T2_261: DB 168,0,15,27,1,15,141,0,15,0,0,0,0,0,0,0,0,0
T2_262: DB 168,0,15,27,1,15,141,0,15,107,4,15,0,0,0,0,0,0
T2_263: DB 168,0,15,0,0,0,0,0,0,107,4,15,0,0,0,0,0,0
T2_264: DB 212,0,15,54,2,15,168,1,15,80,1,15,0,0,0,0,0,0
T2_265: DB 27,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_266: DB 252,0,15,246,4,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_267: DB 224,0,15,246,4,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_268: DB 212,0,15,61,1,15,168,1,15,248,1,15,0,0,0,0,0,0
T2_269: DB 189,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_270: DB 168,0,15,123,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_271: DB 189,0,15,123,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_272: DB 212,0,15,168,1,15,22,2,15,61,1,15,0,0,0,0,0,0
T2_273: DB 189,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_274: DB 27,1,15,161,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_275: DB 168,0,15,161,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_276: DB 159,0,15,80,1,15,54,2,15,168,1,15,0,0,0,0,0,0
T2_277: DB 141,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_278: DB 126,0,15,107,4,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_279: DB 141,0,15,107,4,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_280: DB 168,0,15,80,1,15,168,1,15,54,2,15,0,0,0,0,0,0
T2_281: DB 159,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_282: DB 27,1,15,168,0,15,141,0,15,79,3,15,0,0,0,0,0,0
T2_283: DB 168,0,15,126,0,15,252,0,15,80,1,15,168,1,15,54,2,15
T2_284: DB 141,0,15,27,1,15,168,0,15,0,0,0,0,0,0,0,0,0
T2_285: DB 141,0,15,27,1,15,168,0,15,107,4,15,0,0,0,0,0,0
T2_286: DB 212,0,15,168,0,15,80,1,15,107,4,15,0,0,0,0,0,0
T2_287: DB 189,0,15,61,1,15,159,0,15,54,2,15,168,1,15,80,1,15
T2_288: DB 44,1,15,150,0,15,178,0,15,0,0,0,0,0,0,0,0,0
T2_289: DB 168,0,15,141,0,15,27,1,15,79,3,15,0,0,0,0,0,0
T2_290: DB 168,0,15,126,0,15,252,0,15,80,1,15,168,1,15,54,2,15
T2_291: DB 141,0,15,27,1,15,168,0,15,0,0,0,0,0,0,0,0,0
T2_292: DB 141,0,15,27,1,15,168,0,15,161,2,15,0,0,0,0,0,0
T2_293: DB 141,0,15,0,0,0,0,0,0,161,2,15,0,0,0,0,0,0
T2_294: DB 126,0,15,200,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_295: DB 119,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_296: DB 112,0,15,189,0,15,141,0,15,243,2,15,0,0,0,0,0,0
T2_297: DB 112,0,15,189,0,15,141,0,15,243,2,15,0,0,0,0,0,0
T2_298: DB 112,0,15,189,0,15,141,0,15,121,1,15,193,1,15,54,2,15
T2_299: DB 112,0,15,212,0,15,150,0,15,0,0,0,0,0,0,0,0,0
T2_300: DB 112,0,15,212,0,15,150,0,15,243,2,15,0,0,0,0,0,0
T2_301: DB 126,0,15,0,0,0,0,0,0,243,2,15,0,0,0,0,0,0
T2_302: DB 150,0,15,212,0,15,121,1,15,168,1,15,248,1,15,0,0,0
T2_303: DB 189,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_304: DB 141,0,15,224,0,15,54,2,15,193,1,15,121,1,15,0,0,0
T2_305: DB 141,0,15,224,0,15,246,4,15,123,2,15,0,0,0,0,0,0
T2_306: DB 141,0,15,224,0,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_307: DB 141,0,15,224,0,15,161,2,15,65,5,15,0,0,0,0,0,0
T2_308: DB 80,1,15,212,0,15,161,2,15,65,5,15,168,0,15,0,0,0
T2_309: DB 61,1,15,159,0,15,189,0,15,230,5,15,243,2,15,0,0,0
T2_310: DB 150,0,15,178,0,15,44,1,15,0,0,0,0,0,0,0,0,0
T2_311: DB 168,0,15,141,0,15,27,1,15,159,6,15,79,3,15,0,0,0
T2_312: DB 168,0,15,126,0,15,252,0,15,54,2,15,80,1,15,168,1,15
T2_313: DB 141,0,15,27,1,15,168,0,15,0,0,0,0,0,0,0,0,0
T2_314: DB 141,0,15,27,1,15,168,0,15,107,4,15,0,0,0,0,0,0
T2_315: DB 212,0,15,168,0,15,80,1,15,107,4,15,0,0,0,0,0,0
T2_316: DB 159,0,15,61,1,15,189,0,15,80,1,15,168,1,15,54,2,15
T2_317: DB 44,1,15,178,0,15,150,0,15,0,0,0,0,0,0,0,0,0
T2_318: DB 27,1,15,168,0,15,141,0,15,79,3,15,0,0,0,0,0,0
T2_319: DB 168,0,15,126,0,15,252,0,15,54,2,15,80,1,15,168,1,15
T2_320: DB 141,0,15,27,1,15,168,0,15,0,0,0,0,0,0,0,0,0
T2_321: DB 141,0,15,27,1,15,168,0,15,107,4,15,0,0,0,0,0,0
T2_322: DB 168,0,15,0,0,0,0,0,0,107,4,15,0,0,0,0,0,0
T2_323: DB 212,0,15,168,1,15,161,2,15,0,0,0,0,0,0,0,0,0
T2_324: DB 27,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_325: DB 252,0,15,246,4,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_326: DB 224,0,15,246,4,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_327: DB 212,0,15,168,1,15,248,1,15,61,1,15,0,0,0,0,0,0
T2_328: DB 189,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_329: DB 168,0,15,123,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_330: DB 189,0,15,123,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_331: DB 212,0,15,61,1,15,22,2,15,168,1,15,0,0,0,0,0,0
T2_332: DB 189,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_333: DB 212,0,15,161,2,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_334: DB 212,0,15,168,1,15,54,2,15,80,1,15,0,0,0,0,0,0
T2_335: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_336: DB 212,0,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_337: DB 27,1,15,79,3,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_338: DB 44,1,15,80,1,15,168,1,15,220,1,15,0,0,0,0,0,0
T2_339: DB 27,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_340: DB 212,0,15,123,2,15,61,1,15,168,1,15,248,1,15,0,0,0
T2_341: DB 252,0,15,61,1,15,123,2,15,248,1,15,168,1,15,0,0,0
T2_342: DB 212,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_343: DB 212,0,15,87,2,15,100,1,15,168,1,15,248,1,15,0,0,0
T2_344: DB 252,0,15,87,2,15,100,1,15,168,1,15,248,1,15,0,0,0
T2_345: DB 212,0,15,100,1,15,87,2,15,248,1,15,168,1,15,0,0,0
T2_346: DB 252,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_347: DB 27,1,15,80,1,15,168,1,15,54,2,15,0,0,0,0,0,0
T2_348: DB 212,0,15,80,1,15,168,1,15,54,2,15,0,0,0,0,0,0
T2_349: DB 168,0,15,80,1,15,168,1,15,54,2,15,0,0,0,0,0,0
T2_350: DB 141,0,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_351: DB 141,0,15,80,1,15,168,1,15,54,2,15,0,0,0,0,0,0
T2_352: DB 168,0,15,80,1,15,168,1,15,54,2,15,0,0,0,0,0,0
T2_353: DB 212,0,15,80,1,15,168,1,15,54,2,15,0,0,0,0,0,0
T2_354: DB 27,1,15,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
T2_355: DB 44,1,15,252,0,15,243,2,15,168,1,15,0,0,0,0,0,0
T2_356: DB 212,0,15,44,1,15,248,1,15,243,2,15,0,0,0,0,0,0
T2_357: DB 212,0,15,44,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_358: DB 61,1,15,168,0,15,193,1,15,54,2,15,0,0,0,0,0,0
T2_359: DB 189,0,15,61,1,15,193,1,15,54,2,15,0,0,0,0,0,0
T2_360: DB 189,0,15,61,1,15,193,1,15,54,2,15,0,0,0,0,0,0
T2_361: DB 212,0,15,80,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_362: DB 212,0,15,80,1,15,79,3,15,168,1,15,0,0,0,0,0,0
T2_363: DB 212,0,15,80,1,15,54,2,15,107,4,15,0,0,0,0,0,0
T2_364: DB 212,0,15,80,1,15,0,0,0,0,0,0,0,0,0,0,0,0
T2_365: DB 212,0,15,80,1,15,65,5,15,161,2,15,0,0,0,0,0,0

frameTable:
DW 10, T2_0
DW 11, T2_1
DW 11, T2_2
DW 21, T2_3
DW 11, T2_4
DW 21, T2_5
DW 11, T2_6
DW 11, T2_7
DW 11, T2_8
DW 21, T2_9
DW 11, T2_10
DW 21, T2_11
DW 11, T2_12
DW 11, T2_13
DW 10, T2_14
DW 22, T2_15
DW 10, T2_16
DW 11, T2_17
DW 11, T2_18
DW 21, T2_19
DW 22, T2_20
DW 21, T2_21
DW 11, T2_22
DW 11, T2_23
DW 10, T2_24
DW 11, T2_25
DW 11, T2_26
DW 10, T2_27
DW 22, T2_28
DW 11, T2_29
DW 10, T2_30
DW 22, T2_31
DW 10, T2_32
DW 11, T2_33
DW 11, T2_34
DW 11, T2_35
DW 10, T2_36
DW 11, T2_37
DW 11, T2_38
DW 10, T2_39
DW 11, T2_40
DW 11, T2_41
DW 11, T2_42
DW 10, T2_43
DW 11, T2_44
DW 11, T2_45
DW 21, T2_46
DW 11, T2_47
DW 11, T2_48
DW 21, T2_49
DW 11, T2_50
DW 10, T2_51
DW 11, T2_52
DW 11, T2_53
DW 11, T2_54
DW 10, T2_55
DW 22, T2_56
DW 10, T2_57
DW 11, T2_58
DW 22, T2_59
DW 10, T2_60
DW 11, T2_61
DW 11, T2_62
DW 10, T2_63
DW 11, T2_64
DW 11, T2_65
DW 11, T2_66
DW 10, T2_67
DW 11, T2_68
DW 11, T2_69
DW 10, T2_70
DW 11, T2_71
DW 11, T2_72
DW 11, T2_73
DW 21, T2_74
DW 11, T2_75
DW 10, T2_76
DW 22, T2_77
DW 11, T2_78
DW 10, T2_79
DW 11, T2_80
DW 11, T2_81
DW 10, T2_82
DW 11, T2_83
DW 22, T2_84
DW 10, T2_85
DW 11, T2_86
DW 21, T2_87
DW 11, T2_88
DW 11, T2_89
DW 11, T2_90
DW 10, T2_91
DW 11, T2_92
DW 11, T2_93
DW 10, T2_94
DW 11, T2_95
DW 11, T2_96
DW 11, T2_97
DW 10, T2_98
DW 11, T2_99
DW 11, T2_100
DW 10, T2_101
DW 22, T2_102
DW 11, T2_103
DW 10, T2_104
DW 22, T2_105
DW 10, T2_106
DW 11, T2_107
DW 11, T2_108
DW 11, T2_109
DW 10, T2_110
DW 11, T2_111
DW 11, T2_112
DW 10, T2_113
DW 11, T2_114
DW 11, T2_115
DW 11, T2_116
DW 10, T2_117
DW 11, T2_118
DW 11, T2_119
DW 10, T2_120
DW 11, T2_121
DW 11, T2_122
DW 11, T2_123
DW 10, T2_124
DW 11, T2_125
DW 11, T2_126
DW 10, T2_127
DW 11, T2_128
DW 11, T2_129
DW 11, T2_130
DW 10, T2_131
DW 22, T2_132
DW 10, T2_133
DW 11, T2_134
DW 22, T2_135
DW 10, T2_136
DW 11, T2_137
DW 11, T2_138
DW 10, T2_139
DW 11, T2_140
DW 11, T2_141
DW 21, T2_142
DW 11, T2_143
DW 11, T2_144
DW 21, T2_145
DW 11, T2_146
DW 11, T2_147
DW 10, T2_148
DW 11, T2_149
DW 11, T2_150
DW 10, T2_151
DW 11, T2_152
DW 11, T2_153
DW 11, T2_154
DW 10, T2_155
DW 11, T2_156
DW 11, T2_157
DW 10, T2_158
DW 11, T2_159
DW 22, T2_160
DW 10, T2_161
DW 11, T2_162
DW 21, T2_163
DW 11, T2_164
DW 11, T2_165
DW 11, T2_166
DW 10, T2_167
DW 11, T2_168
DW 11, T2_169
DW 21, T2_170
DW 11, T2_171
DW 11, T2_172
DW 21, T2_173
DW 11, T2_174
DW 10, T2_175
DW 11, T2_176
DW 11, T2_177
DW 11, T2_178
DW 10, T2_179
DW 11, T2_180
DW 11, T2_181
DW 10, T2_182
DW 11, T2_183
DW 11, T2_184
DW 11, T2_185
DW 10, T2_186
DW 11, T2_187
DW 21, T2_188
DW 11, T2_189
DW 11, T2_190
DW 21, T2_191
DW 11, T2_192
DW 11, T2_193
DW 10, T2_194
DW 11, T2_195
DW 11, T2_196
DW 11, T2_197
DW 21, T2_198
DW 11, T2_199
DW 10, T2_200
DW 22, T2_201
DW 11, T2_202
DW 10, T2_203
DW 11, T2_204
DW 11, T2_205
DW 10, T2_206
DW 11, T2_207
DW 11, T2_208
DW 11, T2_209
DW 10, T2_210
DW 11, T2_211
DW 11, T2_212
DW 10, T2_213
DW 11, T2_214
DW 11, T2_215
DW 21, T2_216
DW 11, T2_217
DW 11, T2_218
DW 21, T2_219
DW 11, T2_220
DW 11, T2_221
DW 10, T2_222
DW 11, T2_223
DW 11, T2_224
DW 10, T2_225
DW 11, T2_226
DW 11, T2_227
DW 11, T2_228
DW 10, T2_229
DW 11, T2_230
DW 11, T2_231
DW 10, T2_232
DW 11, T2_233
DW 11, T2_234
DW 11, T2_235
DW 10, T2_236
DW 11, T2_237
DW 11, T2_238
DW 10, T2_239
DW 11, T2_240
DW 11, T2_241
DW 11, T2_242
DW 10, T2_243
DW 11, T2_244
DW 11, T2_245
DW 21, T2_246
DW 22, T2_247
DW 10, T2_248
DW 11, T2_249
DW 11, T2_250
DW 10, T2_251
DW 22, T2_252
DW 11, T2_253
DW 10, T2_254
DW 11, T2_255
DW 11, T2_256
DW 10, T2_257
DW 11, T2_258
DW 22, T2_259
DW 10, T2_260
DW 11, T2_261
DW 11, T2_262
DW 10, T2_263
DW 11, T2_264
DW 11, T2_265
DW 11, T2_266
DW 10, T2_267
DW 11, T2_268
DW 11, T2_269
DW 10, T2_270
DW 11, T2_271
DW 11, T2_272
DW 11, T2_273
DW 10, T2_274
DW 11, T2_275
DW 11, T2_276
DW 10, T2_277
DW 11, T2_278
DW 11, T2_279
DW 11, T2_280
DW 10, T2_281
DW 22, T2_282
DW 10, T2_283
DW 11, T2_284
DW 11, T2_285
DW 11, T2_286
DW 10, T2_287
DW 11, T2_288
DW 21, T2_289
DW 11, T2_290
DW 11, T2_291
DW 11, T2_292
DW 10, T2_293
DW 11, T2_294
DW 11, T2_295
DW 10, T2_296
DW 11, T2_297
DW 11, T2_298
DW 11, T2_299
DW 10, T2_300
DW 11, T2_301
DW 11, T2_302
DW 10, T2_303
DW 22, T2_304
DW 11, T2_305
DW 10, T2_306
DW 11, T2_307
DW 11, T2_308
DW 10, T2_309
DW 11, T2_310
DW 22, T2_311
DW 10, T2_312
DW 11, T2_313
DW 11, T2_314
DW 10, T2_315
DW 11, T2_316
DW 11, T2_317
DW 21, T2_318
DW 11, T2_319
DW 11, T2_320
DW 10, T2_321
DW 11, T2_322
DW 11, T2_323
DW 11, T2_324
DW 10, T2_325
DW 11, T2_326
DW 11, T2_327
DW 10, T2_328
DW 11, T2_329
DW 11, T2_330
DW 11, T2_331
DW 10, T2_332
DW 22, T2_333
DW 10, T2_334
DW 11, T2_335
DW 11, T2_336
DW 11, T2_337
DW 10, T2_338
DW 11, T2_339
DW 21, T2_340
DW 11, T2_341
DW 11, T2_342
DW 11, T2_343
DW 10, T2_344
DW 11, T2_345
DW 11, T2_346
DW 10, T2_347
DW 11, T2_348
DW 11, T2_349
DW 11, T2_350
DW 10, T2_351
DW 11, T2_352
DW 11, T2_353
DW 10, T2_354
DW 22, T2_355
DW 11, T2_356
DW 10, T2_357
DW 11, T2_358
DW 11, T2_359
DW 10, T2_360
DW 11, T2_361
DW 22, T2_362
DW 10, T2_363
DW 11, T2_364
DW 11, T2_365
DW $FFFF, T2_0



ORG $f0f0
im2Routine
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL


; this is the IM2 routine
; gets called every 1/50 second, i.e. 20ms
; push/pop are in main program


; select AY1

        LD A, %11111111
        LD BC, AYSelect
        OUT (C), A

; get the Ch1 tone value
; apply delta
        LD HL, (Ch1Pitch)
        LD BC, (Ch1PitchD)
        ADD HL, BC
        LD (Ch1Pitch), HL

; write Ch1 tone to Ay chip
        LD BC, AYSelect
        LD A, 0
        OUT (C), A
        LD BC, AYrw
        OUT (C), L

        LD BC, AYSelect
        LD A, 1
        OUT (C), A
        LD BC, AYrw
        OUT (C), H

; get the Ch1 volume value
; apply delta
        LD HL, (Ch1Volume)
        LD BC, (Ch1VolumeD)
        ADD HL, BC
        LD (Ch1Volume), HL

        LD A, H
        AND 15

; write Ch1 volume to AY chip
        LD BC, AYSelect
        LD H, 8
        OUT (C), H
        LD BC, AYrw
        OUT (C), A

; get the Ch2 tone value
; apply delta
        LD HL, (Ch2Pitch)
        LD BC, (Ch2PitchD)
        ADD HL, BC
        LD (Ch2Pitch), HL

; write Ch2 tone to Ay chip
        LD BC, AYSelect
        LD A, 2
        OUT (C), A
        LD BC, AYrw
        OUT (C), L

        LD BC, AYSelect
        LD A, 3
        OUT (C), A
        LD BC, AYrw
        OUT (C), H

; get the Ch2 volume value
; apply delta
        LD HL, (Ch2Volume)
        LD BC, (Ch2VolumeD)
        ADD HL, BC
        LD (Ch2Volume), HL

        LD A, H
        AND 15

; write Ch2 volume to AY chip
        LD BC, AYSelect
        LD H, 9
        OUT (C), H
        LD BC, AYrw
        OUT (C), A

; get the Ch3 tone value
; apply delta
        LD HL, (Ch3Pitch)
        LD BC, (Ch3PitchD)
        ADD HL, BC
        LD (Ch3Pitch), HL

; write Ch3 tone to Ay chip
        LD BC, AYSelect
        LD A, 4
        OUT (C), A
        LD BC, AYrw
        OUT (C), L

        LD BC, AYSelect
        LD A, 5
        OUT (C), A
        LD BC, AYrw
        OUT (C), H

; get the Ch3 volume value
; apply delta
        LD HL, (Ch3Volume)
        LD BC, (Ch3VolumeD)
        ADD HL, BC
        LD (Ch3Volume), HL

        LD A, H
        AND 15

; write Ch3 volume to AY chip
        LD BC, AYSelect
        LD H, 10
        OUT (C), H
        LD BC, AYrw
        OUT (C), A

; get the Ch1 flags
        LD DE, (Ch1Flags)               ; get Ch1 tone, noise flags
        LD A, 0                         ; initialise AY chip flag
        BIT 0, E                        ; is bit 0 (tone) set for Ch1
        JR NZ, ch1toneskip              ; jump if not
        SET 0, A                        ; set OFF for Ch1 tone
ch1toneskip
        BIT 1, E                        ; is bit 1 (noise) set for Ch1
        JR NZ, ch1noiseskip             ; jump if not
        SET 3, A                        ; set OFF for Ch1 noise
ch1noiseskip
        LD DE, (Ch2Flags)               ; get Ch2 tone, noise flags
        BIT 0, E                        ; is bit 0 (tone) set for Ch2
        JR NZ, ch2toneskip              ; jump if not
        SET 1, A                        ; set OFF for Ch2 tone
ch2toneskip
        BIT 1, E                        ; is bit 1 (noise) set for Ch2
        JR NZ, ch2noiseskip             ; jump if not
        SET 4, A                        ; set OFF for Ch2 noise
ch2noiseskip
        LD DE, (Ch3Flags)
        BIT 0, E
        JR NZ, ch3toneskip
        SET 2, A
ch3toneskip
        BIT 1, E
        JR NZ, ch3noiseskip
        SET 5, A
ch3noiseskip
        LD BC, AYSelect
        LD D, 7
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
        AND A                               ; is it zero?
        JP NZ, melodyEnd                    ; branch to end if not

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
        ; setup for AY2
        LD A, 254
        LD BC, AYSelect
        OUT (C), A

        ; AY2 tone A
        LD A, 0
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        LD A, 1
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY2 volume A
        LD A, 8
        LD BC, AYSelect
        OUT (C), A

        LD A, (DE)                          ; get volume it derives mixer
        AND %00000001                       ; volume 0/15, mask off for channel
        LD H, A                             ; save in H

        LD A, (volume)                      ; get our preset volume
        INC DE                              ; mixer will override if not reqd
        LD BC, AYrw
        OUT (C), A

        ; AY2 tone B
        LD A, 2
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        LD A, 3
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY2 volume B
        LD A, 9
        LD BC, AYSelect
        OUT (C), A

        LD A, (DE)
        AND %00000010
        OR H
        LD H, A

        LD A, (volume)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY2 tone C
        LD A, 4
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        LD A, 5
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY2 volume C
        LD A, 10
        LD BC, AYSelect
        OUT (C), A

        LD A, (DE)
        AND %00000100
        OR H
        LD H, A

        LD A, (volume)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; mixer AY2
        LD A, 7
        LD BC, AYSelect
        OUT (C), A

        LD A, H                             ; get mixer value - 00000111
        XOR %11111111                       ; reverse and set
        LD BC, AYrw
        OUT (C), A

        ; setup for AY3
        LD A, 253
        LD BC, AYSelect
        OUT (C), A

        ; AY3 tone A
        LD A, 0
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        LD A, 1
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY3 volume A
        LD A, 8
        LD BC, AYSelect
        OUT (C), A

        LD A, (DE)
        AND %00000001
        LD H, A

        LD A, (volume)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY3 tone B
        LD A, 2
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        LD A, 3
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY3 volume B
        LD A, 9
        LD BC, AYSelect
        OUT (C), A

        LD A, (DE)
        AND %00000010
        OR H
        LD H, A

        LD A, (volume)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY3 tone C
        LD A, 4
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        LD A, 5
        LD BC, AYSelect
        OUT (C), A
        LD A, (DE)
        INC DE
        LD BC, AYrw
        OUT (C), A

        ; AY3 volume C
        LD A, 10
        LD BC, AYSelect
        OUT (C), A

        LD A, (DE)
        AND %00000100
        OR H
        LD H, A

        LD A, (volume)
        LD BC, AYrw
        OUT (C), A

        ; mixer AY3
        LD A, 7
        LD BC, AYSelect
        OUT (C), A

        LD A, H
        XOR %11111111

        LD BC, AYrw
        OUT (C), A

melodyEnd


AYSelect EQU $FFFD
AYrw     EQU $bffd





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

