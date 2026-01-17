newGame
; first time in OR lives all lost and starting over
;
        CALL ULAon
        CALL killSprites

        LD HL, 0
        LD (score), HL

        XOR A
        LD (keyCnt), A

        LD A, 3
        LD (lives), A

        LD A, 15
        LD (volume), A

        LD A, splashLevel
        CALL createLevel
        CALL setupBalloonData

        displayText tInst1
        displayText tInst2
        displayText tInst3

        LD IX, balloonTemp
        LD (IX +strucBalloon.index), 52
        LD (IX +strucBalloon.pattern), Sballoon
        LD (IX +strucBalloon.lowX), 208
        LD (IX +strucBalloon.highX), 0
        LD (IX +strucBalloon.lowY), 8
        CALL showSP1
        LD (IX +strucBalloon.index), 53
        LD (IX +strucBalloon.pattern), Sballoon
        LD (IX +strucBalloon.lowX), 232
        LD (IX +strucBalloon.highX), 0
        LD (IX +strucBalloon.lowY), 24
        CALL showSP1

        CALL paulInit
        CALL showPaul1

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
        LD A, 2 - 1                         ; starting level
        LD (LEVEL), A
        ;JP commonInit
        JP levelUp

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
        LDIR                                ; do the scroll
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

restartGame
; life lost, so restart
        CALL killSprites                    ; remove all sprites from screen
        LD IX, balloonSpr                   ; point to balloon data

; here we turn all skulls back into balloons
restartGame1
        LD A, (IX +strucBalloon.pattern)    ; get balloon pattern
        CP 255                              ; are we at the end
        JR Z, commonInit                    ; branch if so

        CP Sskull                           ; is pattern a skull
        JR NZ, restartGame2                 ; branch over if not

        LD A, Sballoon                      ; change skull back to balloon
        LD (IX +strucBalloon.pattern), A    ; set pattern
        LD HL, 0                            ;
        LD (IX +strucBalloon.lowX), L       ; set X coord as lhs
        LD (IX +strucBalloon.highX), H      ;
restartGame2
        LD A, (IX +strucBalloon.index)      ; set pop delay
        LD C, A
        LD A, 255
        LD (IX +strucBalloon.popDelayL), A
        LD A, C
        ADD 2
        SLA A
        LD (IX +strucBalloon.popDelayH), A

        LD DE, strucBalloon
        ADD IX, DE
        JR restartGame1

commonInit
; these need doing on life lost or new game
        CALL ULAoff
        CALL paulInit
        LD A, (LEVEL)
        CALL createLevel                    ; create and show tilemap
        CALL showTitles                     ; show titles etc
        CALL showLevel
        RET

levelUp
        CALL killSprites
        LD A, 0
        LD (keyCnt), A

        CALL paulInit

        LD A, (LEVEL)
        INC A
        LD (LEVEL), A

        CALL createLevel
        CALL setupBalloonData
        CALL showTitles
        CALL showLevel
        RET

paulInit
        ; initialise Paul with starting data
        LD IX, manSprite                    ; point to Paul's data
        LD A, facingRight                   ; Paul will start facing right
        LD (IX +strucBalloon.pattern), A    ; set it
        LD A, nothing                       ; Paul will be jumping on the spot, no left/right movement
        LD (IX +strucBalloon.dirH), A       ; set it
        LD A, 1                             ; pogo power at 1
        LD (strengthInd), A                 ; set it
        CALL setRiseCnt                     ; set riseCnt according to pogo strength
        LD A, 15                            ; max health
        LD (health), A                      ; set it
        LD A, healthDefault                 ; health delay default
        LD (healthDelay), A                 ; set it

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

        ; display the message "Level x" and "Press Spaceto begin"
        displayText tLevel1
        displayText tLevel2
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
;        LD IY, roomData                             ; point to base room/level data
        LD IY, level0
        LD E, A                                     ; get the room number into E
        LD D, strucLevelData                        ; get the room data length
        MUL D, E                                    ; multiply
        ADD IY, DE                                  ; hence room data for A

        LD E, (IY +strucLevelData.dataAddrL)        ; get layout low address in E
        LD D, (IY +strucLevelData.dataAddrH)        ; get layout high address in D

        LD A, (IY +strucLevelData.balloonCount)     ; get balloon count for level
        LD (balloonSprCnt), A                       ; save it

        LD A, (IY +strucLevelData.maxOnScreen)      ; get max on screen for level
        LD (maxOnScreen), A                         ; save it

        LD A, (IY +strucLevelData.featureByte)      ; get special features
        LD (features), A                            ; save it

        LD IX, manSprite                            ; ready to set initial Paul data
        LD L, (IY +strucLevelData.paulXL)           ; X coord
        LD H, (IY +strucLevelData.paulXH)
        LD (IX +strucBalloon.lowX), L
        LD (IX +strucBalloon.highX), H
        LD L, (IY +strucLevelData.paulYL)           ; Y coord
        LD H, (IY +strucLevelData.paulYH)
        LD (IX +strucBalloon.lowY), L
        LD (IX +strucBalloon.highY), H

        LD A, (IY +strucLevelData.toxicCnt)
        LD (toxicCnt), A

        LD L, (IY +strucLevelData.toxic1YL)           
        LD H, (IY +strucLevelData.toxic1YH)
        LD (toxic1Y), HL
        LD L, (IY +strucLevelData.toxic1XL)           
        LD H, (IY +strucLevelData.toxic1XH)
        LD (toxic1X), HL
        LD L, (IY +strucLevelData.toxic1YL)           
        LD H, (IY +strucLevelData.toxic1YH)
        LD (toxic2Y), HL
        LD L, (IY +strucLevelData.toxic1XL)           
        LD H, (IY +strucLevelData.toxic1XH)
        LD (toxic2X), HL
        LD L, (IY +strucLevelData.toxic1YL)           
        LD H, (IY +strucLevelData.toxic1YH)
        LD (toxic3Y), HL
        LD L, (IY +strucLevelData.toxic1XL)           
        LD H, (IY +strucLevelData.toxic1XH)
        LD (toxic3X), HL


        CALL createTileMap
        RET

;roomData defs strucLevelData * (splashLevel +1)
;
; the level or "room" data
;
level0
        DW page000                          ; address of screen data
        DB 10                               ; level balloon count
        DB 5                                ; level max on screen
        DB %00000000                        ; feature byte (bit 0 - 1= disable keyboard for level, e.g. splash screen)
        DW 144                              ; Paul's starting X
        DW 216                              ; Paul's starting Y
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X

        DW page001                           ; level 1
        DB 11
        DB 5
        DB %00000000
        DW 144, 216
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X


        DW page002                          ; level 2
        DB 12
        DB 5
        DB %00000000
        DW 144, 216
        DB 1                                ; toxic cnt
        DW 56                               ; toxic 1 X
        DW 19                               ; toxic 1 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 3 X
        DW 0                                ; Toxic 3 Y

        DW page003                          ; level 3
        DB 13
        DB 5
        DB %00000000
        DW 144, 216
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X

        DW page004                           ; level 4
        DB 14
        DB 5
        DB %00000000
        DW 144, 216
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X

        DW page005                           ; level 5
        DB 15
        DB 5
        DB %00000000
        DW 144, 216
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X

        DW page006                           ; level 6
        DB 16
        DB 5
        DB 0
        DW 144, 216
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X

        DW page007                           ; level 7
        DB 17
        DB 5
        DB 0
        DW 144, 216
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X

        DW page008                           ; level 8
        DB 18
        DB 5
        DB 0
        DW 144, 216
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X

        DW page009                           ; level 9  instructions
        DB 10
        DB 5
        DB %00000001
        DW 72, 64
        DB 0                                ; toxic cnt
        DW 0                                ; toxic 1 Y
        DW 0                                ; toxic 1 X
        DW 0                                ; toxic 2 Y
        DW 0                                ; toxic 2 X
        DW 0                                ; toxic 3 Y
        DW 0                                ; Toxic 3 X

;
; create tilemap from the compressed data
;
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

;
; display the text for the screen
; e.g. "pogo power" + meter
;      "health" + meter
;       score, hi-score, lives, key etc
;
showTitles
        CALL showPower
        displayText tPower1
        displayText tPower2
        displayText tPower3
        displayText tPower4
        displayText tPower5
        displayText tPower6
        displayText tPower7
        displayText tPower8
        displayText tPower9

        CALL showHealth
        displayText tHealth1
        displayText tHealth2
        displayText tHealth3
        displayText tHealth4
        displayText tHealth5
        displayText tHealth6

        displayText tScore1
        displayText tHiScore
        displayText tLives

        CALL showScore
        CALL showHiScore
        CALL showLives
        CALL showKey

        RET

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

        ; turn off sound from all 3 AY chips
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
        RET

killSprites
        LD A, 0                             ; start at sprite 0
        LD B, 127                           ; loop for all 127 sprites
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

setupBalloonData
        LD IX, balloonSpr                   ; point to balloon data
        LD C, 0                             ; initialise the sprite index
        LD A, (toxicCnt)                    ; get count of toxic drops in this room
        CP 0                                ; is it 0?
        JP Z, setupBalloon                  ; branch if so

        LD B, A                             ; save the toxic count into B
        LD A, (maxOnScreen)                 ; get maximum balloons allowed on screen
        ADD B                               ; adjust for toxic count
        LD (maxOnScreen), A                 ; and save back

setUpToxic
        CALL createToxic                    ; create the toxic drop
        LD DE, strucBalloon                 ; get balloon structure length
        ADD IX, DE                          ; and and hence point to next balloon
        INC C                               ; increase sprite index
        DJNZ setUpToxic                     ; loop if more toxic drops


setupBalloon
        LD A, (balloonSprCnt)
        LD B, A
        ; LD C, 0
setupBalloon1
        CALL createBalloon
        LD DE, strucBalloon
        ADD IX, DE
        INC C
        DJNZ setupBalloon1

        LD A, 255
        LD (IX +strucBalloon.pattern), A
        LD A, (maxOnScreen)
        INC A
        LD (balloonNext), A
        RET

createBalloon
        LD A, C                        ; get sprite index
        LD (IX +strucBalloon.index), A     ; set in balloon data

        CALL randomY                   ; get a random Y coord in A
        LD (IX +strucBalloon.lowY), A      ; set in balloon data
        LD A, 0                        ; set the high Y coord byte to 0
        LD (IX +strucBalloon.highY), A     ; set in balloon data

        CALL random                    ; get a random number in A
        AND %00011111                  ; limit to 0-31
        LD (IX +strucBalloon.swoop), A     ; set in balloon data

             ; this determines how long it will take
             ; before the balloon auto pops
             ; and turns into a skull
        LD A, 255                      ; initialise low byte pop delay
        LD (IX +strucBalloon.popDelayL), A ; set it
        LD A, C                        ; initialise high byte pop delay
        ADD 2                          ; use balloon index + 1
        SLA A
        LD (IX +strucBalloon.popDelayH), A ; set it

        LD A, 0
        LD (IX +strucBalloon.landValue), A

        LD A, (maxOnScreen)
;             CP B
;             JR NC, offScreen
         CP C
         JR C, .offScreen

.onScreen
        LD A, Sballoon                 ; on screen, so pattern is balloon
        LD (IX +strucBalloon.pattern), A

        CALL randomX                   ; get a random X coord in HL
        LD (IX +strucBalloon.lowX), L      ; set in balloon data
        LD (IX +strucBalloon.highX), H     ; set in balloon data
        JR setupEnd

.offScreen
        LD A, Sblank                    ; off screen, so pattern is blank
        LD (IX +strucBalloon.pattern), A
        LD HL, 0                       ; set X as 0
        LD (IX +strucBalloon.lowX), L      ; set in balloon data
        LD (IX +strucBalloon.highX), H     ; set in balloon data
        JR setupEnd

setupEnd
; get a random number 0-15
; item will be assigned as follows
; 07 blank      38%  0 -  5 & 15
; 24 points     24%  6 -  9
; 16 apple      24% 10 - 13
; 12 heart       7%      14
        LD A, B                             ; get the count of balloons
        DEC A                               ; are we on the last one
        JR Z, assignKey                     ; branch if so
assignItem1
        CALL random1                        ; get a random number
        AND %00001111                       ; mask off so its 0-15
        LD HL, items                        ; point to items list
        ADD HL, A                           ; index with random number
        LD A, (HL)                          ; get item
        LD (IX +strucBalloon.newSprite), A  ; set what this balloon may spawn into

        RET
assignKey
        LD A, (keyCnt)                      ; get the count of "held" keys
        AND A                               ; test for 0, not held
        JR NZ, assignItem1                  ; if we are already holding the key, select another item
        LD A, Skey                          ; set item to be the key
        LD (IX +strucBalloon.newSprite), A  ; set what this balloon may spawn into

        RET

createToxic
        LD A, C                             ; get sprite index
        LD (IX +strucBalloon.index), A      ; set in balloon data

        LD HL, toxic1Y                      ; point to the starting coords 4 bytes per toxic drop
        ADD A, A                            ; multiply index by 2
        ADD A, A                            ; multiply index by 4
        ADD HL, A                           ; add to base
        LD A, (HL)
        LD (IX +strucBalloon.lowY), A
        INC HL
        LD A, (HL)
        LD (IX +strucBalloon.highY), A
        INC HL
        LD A, (HL)
        LD (IX +strucBalloon.lowX), A
        INC HL
        LD A, (HL)
        LD (IX +strucBalloon.highX), A

        LD A, 0
        LD (IX +strucBalloon.popDelayH), A
        CALL random
        LD (IX +strucBalloon.popDelayL), A
        
        LD A, Stoxic
        LD (IX +strucBalloon.pattern), A


        RET


             


items
        DB Sblank                           ;  0
        DB Sblank                           ;  1
        DB Sblank                           ;  2
        DB Sblank                           ;  3
        DB Sblank                           ;  4
        DB Sblank                           ;  5
        DB Spoints                          ;  6
        DB Spoints                          ;  7
        DB Spoints                          ;  8
        DB Spoints                          ;  9
        DB Sapple                           ; 10
        DB Sapple                           ; 11
        DB Sapple                           ; 12
        DB Sapple                           ; 13
        DB Sheart                           ; 14
        DB Sblank                           ; 15

