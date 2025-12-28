; --------------------------------
; Draw Pogo Power Meter (15 bars)
; --------------------------------
showPower:
        LD A, (strengthInd)                 ; A = current strength (1–16)
        LD E, A                             ; Save for use in loop
        LD B, 15                            ; Number of bars to draw
        LD C, 40                            ; Tile row stride
        LD HL, tileMapData + 121            ; Start position (top of power bar)

        ; Inlined getPowerColour:
        LD D, boxRed
        CP 12
        JR NC, .drawBarLoop
        LD D, boxAmber
        CP 7
        JR NC, .drawBarLoop
        LD D, boxGreen

.drawBarLoop:
        LD A, E                             ; Get strength
        CP B                                ; Is strength ≥ current bar number?
        JR NC, .useColourTile               ; If so, draw color
        LD A, boxBlank                      ; Otherwise, draw blank
        JR .storeTile

.useColourTile:
        LD A, D                             ; Use power colour

.storeTile:
        LD (HL), A                          ; Write tile
        LD A, C
        ADD HL, A                           ; Move to next row
        DJNZ .drawBarLoop                   ; Loop
        RET


; --------------------------------
; Draw Paul's Health Meter (15 bars)
; --------------------------------
showHealth:
        LD A, (features)                    ; Get page features
        BIT 0, A                            ; Is health display disabled?
        RET NZ                              ; If so, skip display

        LD A, (health)                      ; Get current health value
        LD E, A                             ; Store for later
        LD B, 15                            ; Number of bars
        LD C, 40                            ; Tile row stride
        LD HL, tileMapData + 158            ; Start of health bar

        ; Inlined healthColour logic
        LD D, boxGreen                      ; Default to green
        CP 12
        JR NC, .drawHealthBar
        LD D, boxAmber
        CP 9
        JR NC, .drawHealthBar
        LD D, boxRed

.drawHealthBar:
        LD A, E                             ; E = health
        CP B
        JR NC, .useHealthTile               ; If health ≥ bar number
        LD A, boxBlank
        JR .storeTile

.useHealthTile:
        LD A, D                             ; Use health colour tile

.storeTile:
        LD (HL), A                          ; Draw tile
        LD A, C
        ADD HL, A                           ; Move to next row
        DJNZ .drawHealthBar                 ; Loop for all 15 bars
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

showKey
        ld A, Tkey                          ; tile start for key 1/4                           
        LD HL, tileMapData +1121            ; tilemap position
        ld (hl), a                          ; place tile 1/4
        inc a
        inc hl
        ld (hl), a                          ; place tile 2/4
        inc a
        ld hl, tileMapData +1161
        ld (hl), a                          ; place tile 3/4
        inc a
        inc hl
        ld (hl), a                          ; place tile 4/4
        

        LD A, (keyCnt)                      ; get current key count                          
        LD B, TtileCross                    ; set tile number to be the cross, not tick
        AND A                               ; test key count
        JR Z, showKey1                      ; branch if key not caught yet
        INC B                               ; set tile number to be the tick
        LD A, 0                             ; set A = blank tile (exit for Paul to escape)
        LD HL, tileMapData +917             ; exit is 3 blank tiles for 4 lines
        LD (HL), A                          ; exit line #1
        INC HL
        LD (HL), A
        INC HL
        LD (HL), A
        ADD HL, 38
        LD (HL), A                          ; exit line #2
        INC HL
        LD (HL), A
        INC HL
        LD (HL), A
        ADD HL, 38
        LD (HL), A                          ; exit line #3
        INC HL
        LD (HL), A
        INC HL
        LD (HL), A
        ADD HL, 38
        LD (HL), A                          ; exit line #4
        INC HL
        LD (HL), A
        INC HL
        LD (HL), A
showKey1
        LD HL, tileMapData +1202            ; position for the tick or cross
        LD (HL), B                          ; set the tile as appropriate
        RET

