; ----------------------------------------
; DisplayText: Displays a text label
; Usage: DisplayText labelName
; ----------------------------------------
displayText MACRO label
        LD IY, label
        CALL DispT
        ENDM
