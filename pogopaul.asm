device ZXSPECTRUMNEXT

INCLUDE "myMacros.inc"
INCLUDE "c.inc"
INCLUDE "globals.inc"
INCLUDE "initialisation.inc"
INCLUDE "melody.inc"
INCLUDE "utilities.inc"
INCLUDE "textDisplay.inc"
INCLUDE "levelSetup.inc"
INCLUDE "ingameRoutines.inc"
INCLUDE "soundEffects.inc"
INCLUDE "updateBalloons.inc"
INCLUDE "updatePaul.inc"
INCLUDE "tileCollision.inc"
INCLUDE "spriteCollision.inc"
INCLUDE "spriteDisplay.inc"

; ----------------------------
; Game Initialization
; ----------------------------
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


; ----------------------------
; main game start
; ----------------------------
GameStart:
        CALL newGame                        ; game start from scratch

RestartLevel:
        CALL restartGame

; ----------------------------
; Main Game Loop
; ----------------------------
MainLoop:
        CALL showPaul
        JR C, HandleDeath

        CALL balloonUpt

        CALL showPaul
        JR C, HandleDeath

        HALT

        ; Check if Paul reached the exit
        LD HL, (spriteX)
        LD A, H
        CP 1
        JR NZ, CheckPause
        LD A, L
        CP 40
        JR C, CheckPause

        CALL levelUp
        JR MainLoop

; ----------------------------
; Pause Handling (H key)
; ----------------------------
CheckPause:
        LD BC, $bffe                ; key group with H
        IN A, (C)
        AND %00010000               ; bit 4 = H
        JR NZ, CheckExit

PauseLoop:
        HALT
        IN A, (C)
        AND %00010000
        JR NZ, PauseLoop            ; wait until H pressed again

; ----------------------------
; Exit Handling (X key)
; ----------------------------
CheckExit:
        LD BC, $fefe                ; key group: shift, Z, X, C, V
        IN A, (C)
        AND %00000100               ; bit 2 = X
        JR NZ, MainLoop             ; X not pressed → continue game
        JR EndProgram               ; X pressed → end program

; ----------------------------
; Paul Died: Lose a life
; ----------------------------
HandleDeath:
        LD A, (lives)
        DEC A
        LD (lives), A
        JR NZ, RestartLevel         ; still have lives → retry level
        JR GameStart                ; no lives → new game

; ----------------------------
; Program End
; ----------------------------
EndProgram:
        CALL endProg
        NEXTREG $7, 0                   ; set speed to 3.5mhz
        IM 1
        RET

setupIM2:
; sub routine to set-up IM2 to point to BB
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

ORG $f0f0
im2Routine
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL

INCLUDE "im2Routine.inc"

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

