        struct levelData
dataAddrL       byte
dataAddrH       byte
balloonCount    byte
maxOnScreen     byte
featureByte     byte
paulXL          byte
paulXH          byte
paulYL          byte
paulYH          byte
        ENDS
        
    struct sBalloon
index       byte                            ; index for sprite system 0-99
lowX        byte                            ; x coord lsb
highX       byte                            ; x coord msb
lowY        byte                            ; y coord lsb
highY       byte                            ; y coord msb
vDelay      byte                            ; used by balloon sprite to delay up/down movement
swoop       byte                            ; used by balloon sprite, index into array to decide up/down
popDelayL   byte                            ; balloon sprite pop delay lsb
popDelayH   byte                            ; balloon sprite pop delay msb
newSprite   byte                            ; new sprite pattern IF popped by Paul
landValue   byte                            ; direction Vertical (Paul)     land seek value (balloon)
dirH        byte                            ; direction Horizontal (Paul)
pattern     byte                            ; sprite pattern
    ENDS

balloonMaxCount equ 21
balloonSpr defs sBalloon * balloonMaxCount
balloonTemp defs sBalloon

balloonSprCnt  DB 0                         ; balloon count set for level
maxOnScreen    DB 0                         ; max balloons allowed on screen at a time, set for level
balloonNext    DB 0                         ; next free balloon

maxX EQU 320
minX EQU 0
maxY EQU 240
minY EQU 24

balloonSwoop
        DB 0,0,0,1,2,0,0,0,1,0,0,0,2,1,1,0,0,2,1,1,1,2,0,1,1,1,1,0,2,1,1,2


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

manSpriteLen equ $ - manSprite

    assert manSpriteLen = sBalloon, manSprite and sBalloon lengths differ in globals.inc

bounceTable
        DB 16, 24, 32, 36, 40, 44, 48, 52, 56, 60, 64 , 68, 72, 76, 80, 84
        DB   4,  4,  4,  4,  4,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6
        
skullDelay equ 2

;-------------------------------------------------------
; pattern nymbers for the sprites
;-------------------------------------------------------
toxic          EQU 33
Sskull          EQU 4
Sballoon        EQU 8
blank          EQU 32
Sheart          EQU 12
Sapple          EQU 16
Skey            EQU 20
Spoints         EQU 24
dynamite       EQU 28

;-------------------------------------------------------
; tilr nymbers for the tiles
;-------------------------------------------------------
tileCross    EQU 13
tileTick     EQU 14



maxLevel EQU 8
levelLen EQU 9
splashLevel EQU 9

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

       DB 28,  0, " ", 176, 177, " find the key to unlock your         ", 255
       DB 28,  0, " ", 178, 179, " escape route and level up           ", 255
       DB 28,  0, "                                        ", 255

       DB 28,  0, "                                        ", 255
       DB 28,  0, "                                        ", 255
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
;iyDynamite   EQU tileMapData +1205
iyKey        EQU tileMapData +1208


score        DW 0
hiscore      DW 0
lives        DB 3
;dynamiteCnt  DB 0
keyCnt       DB 0
features     DB 0
LEVEL        DB 0

levelStore   DEFS 60, 0

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

AYSelect       EQU $FFFD
AYrw           EQU $bffd
AYPortC        EQU $FD      ; Port low byte, stays in C
AYPortSelectB  EQU $FF      ; B value for AYSelect port ($FFFD)
AYPortWriteB   EQU $BF      ; B value for AYrw port ($BFFD)
channel1ToneL  equ 0
channel1ToneH  equ 1
channel2ToneL  equ 2
channel2ToneH  equ 3
channel3ToneL  equ 4
channel3ToneH  equ 5
channel1Volume equ 8
channel2Volume equ 9
channel3Volume equ 10
mixerFlag      equ 7

mixerFlags  
    db %11111111, %11111110, %11110111, %11110110
    db %11111111, %11111101, %11101111, %11101101
    db %11111111, %11111011, %11011111, %11011011
    