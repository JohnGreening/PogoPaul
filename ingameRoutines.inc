; --------------------------------
; Draw Pogo Power Meter (15 bars)
; --------------------------------
showPower:
        PUSH DE
        LD A, (strengthInd)         ; A = current strength (1–16)
        LD E, A                     ; Save for use in loop
        LD B, 15                    ; Number of bars to draw
        LD C, 40                    ; Tile row stride
        LD HL, tileMapData + 121    ; Start position (top of power bar)

        ; Inlined getPowerColour:
        LD D, boxRed
        CP 12
        JR NC, .drawBarLoop
        LD D, boxAmber
        CP 7
        JR NC, .drawBarLoop
        LD D, boxGreen

.drawBarLoop:
        LD A, E                     ; Get strength
        CP B                        ; Is strength ≥ current bar number?
        JR NC, .useColourTile       ; If so, draw color
        LD A, boxBlank              ; Otherwise, draw blank
        JR .storeTile

.useColourTile:
        LD A, D                     ; Use power colour

.storeTile:
        LD (HL), A                  ; Write tile
        LD A, C
        ADD HL, A                   ; Move to next row
        DJNZ .drawBarLoop           ; Loop
        POP DE
        RET


; --------------------------------
; Draw Paul's Health Meter (15 bars)
; --------------------------------
showHealth:
        LD A, (features)              ; Get page features
        BIT 0, A                      ; Is health display disabled?
        RET NZ                        ; If so, skip display

        PUSH DE
        LD A, (health)               ; Get current health value
        LD E, A                      ; Store for later
        LD B, 15                     ; Number of bars
        LD C, 40                     ; Tile row stride
        LD HL, tileMapData + 158     ; Start of health bar

        ; Inlined healthColour logic
        LD D, boxGreen               ; Default to green
        CP 12
        JR NC, .drawHealthBar
        LD D, boxAmber
        CP 9
        JR NC, .drawHealthBar
        LD D, boxRed

.drawHealthBar:
        LD A, E                      ; E = health
        CP B
        JR NC, .useHealthTile        ; If health ≥ bar number
        LD A, boxBlank
        JR .storeTile

.useHealthTile:
        LD A, D                      ; Use health colour tile

.storeTile:
        LD (HL), A                   ; Draw tile
        LD A, C
        ADD HL, A                    ; Move to next row
        DJNZ .drawHealthBar          ; Loop for all 15 bars
        POP DE
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

