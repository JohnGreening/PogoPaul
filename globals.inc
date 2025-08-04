    struct sBalloon
index       byte                ; index for sprite system 0-99
lowX        byte                ; x coord lsb
highX       byte                ; x coord msb
lowY        byte                ; y coord lsb
highY       byte                ; y coord msb
vDelay      byte                ; used by balloon sprite to delay up/down movement
swoop       byte                ; used by balloon sprite, index into array to decide up/down
popDelayL   byte                ; balloon sprite pop delay lsb
popDelayH   byte                ; balloon sprite pop delay msb
newSprite   byte                ; new sprite pattern IF popped by Paul
landValue   byte                ; direction Vertical (Paul)     land seek value (balloon)
dirH        byte                ; direction Horizontal (Paul)
pattern     byte                ; sprite pattern
    ENDS

balloonMaxCount equ 21
balloonSpr defs balloon * balloonMaxCount
balloonTemp defs balloon

balloonSprCnt  DB 0             ; balloon count set for level
maxOnScreen    DB 0             ; max balloons allowed on screen at a time, set for level
balloonNext    DB 0             ; next free balloon

;--------------------------------------------------------------
; Paul structure and data, frigged to fit the balloon structure
;--------------------------------------------------------------
manSprite      DB 50
spriteX        DW 88
spriteY        DW 200
spriteTX       DW 48
spriteTY       DW 192
spriteO        DB 0
spriteDirV     DB 0
spriteDirH     DB 0
manPat         DB 0

;-------------------------------------------------------
; pattern nymbers for the sprites
;-------------------------------------------------------
toxic          EQU 33
skull          EQU 4
balloon        EQU 8
blank          EQU 32
heart          EQU 12
apple          EQU 16
key            EQU 20
points         EQU 24
dynamite       EQU 28

