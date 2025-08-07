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

; 1 bit per pixel bitmaps (like old school ZX Spectrum)
; space needed is (char width +1 space) * (char height +1 space) * 8
; Paul is    2+1 wide  x 4+1 tall
; Balloon is 2+1 wide by 2+1 tall
; Skull is   2+1 wide by 2+1 tall
; Set-up by calling "buildbmp" below

paulbmpR    DEFS 120, 0                     ; Paul facing right
paulbmpL    DEFS 120, 0                     ; Paul facing left
balloonbmp  DEFS 72, 0                      ; Balloon
skullbmp    DEFS 72, 0                      ; Skull
toxicbmp    DEFS 72, 0

heartbmp    DEFS 72, 0
applebmp    DEFS 72, 0
keybmp      DEFS 72, 0
pointsbmp   DEFS 72, 0
dynamitebmp DEFS 72, 0


; bitmap of first 32 tiles, 32 x 8 = 256
; the remaining files are used for the text output
tilebmp  DEFS 256, 0


buildbmp
        LD D, 0                             ; set the sprite number to convert
        LD C, 32                            ; set pixel lines in sprite
        LD IX, paulbmpR                     ; point to destination bmp
        CALL buildbmp0                      ; convert

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
        LD E, 0                             ; sprites are 256b
        LD HL, SpritePatterns               ; set base for pattern
        ADD HL, DE                          ; add in offset

        LD D, C                             ; loop for all pixel lines
spriteLoop
        LD C, 2                             ; byte loop for 2 x 8 pixel defs
build0
        LD B, 8                             ; loop for 8 defs to make our bm byte
        LD E, 0                             ; initialse our bitmap byte
build1
        LD A, (HL)                          ; get a pixel def
        AND A                               ; is it 0
        JR Z, bit0                          ; jump if its 0
        JR bit1                             ; jump if its 1
build2
        INC HL                              ; point to next pixel def
        DJNZ build1                         ; loop if more
        LD (IX +0), E                       ; set bitmap byte
        INC IX                              ; ready for next bitmap byte
        DEC C                               ; dec byte loop
        JR NZ, build0                       ; loop if more bytes

        INC IX                              ; skip over the bitmap right pad
        DEC D                               ; dec pixel line count
        JR NZ, spriteLoop                   ; loop if more pixel lines
        RET

bit0
        SLA E
        JR build2
bit1
        SLA E
        SET 0, E
        JR build2

bitmapTiles
        LD HL, TilePatterns                 ; point to tile patterns data
        LD IX, tilebmp                      ; point to our bipmap store
        LD D, 32                            ; convert tiles 0-31
tileloop
        LD C, 8                             ; 8 lines to a tile
lineloop
        LD B, 4                             ; 4 bytes to a line
        LD E, 0                             ; initialise bitmap byte
fourByteLoop
        LD A, (HL)                          ; get pattern data (2 pixels)
        AND %11110000                       ; test first nibble
        JR Z, nib10                         ; branch if 0
        JR nib11                            ; branch if not 0
nib1Done
        LD A, (HL)                          ; get pattern data (2 pixels)
        AND %00001111                       ; test second nibble
        JR Z, nib20                         ; branch if 0
        JR nib21                            ; branch if not 0
nib2Done
        INC HL                              ; point to next byte of pattern data
        DJNZ fourByteLoop                   ; loop if more for this line

        LD (IX +0), E                       ; bitmap byte created, so save it
        INC IX                              ; and ready for next
        DEC C                               ; decrease line loop
        JR NZ, lineloop                     ; loop if more

        DEC D                               ; decrease tile loop
        JR NZ, tileloop                     ; loop if more
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
