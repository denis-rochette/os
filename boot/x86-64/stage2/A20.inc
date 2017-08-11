;#########################################
;
; Wait from 8043 input
;
;#########################################
Wait8043KeyboardControllerInput:
    in   al, 0x64                           ; Read status register from 8043 Keyboard Controller
    test al, 0x02                           ; Test bit 2 (Input buffer status)
    jnz  Wait8043KeyboardControllerInput    ; Loop if not empty
    ret

;#########################################
;
; Wait from 8043 output
;
;#########################################
Wait8043KeyboardControllerOutput:
    in   al, 0x64                           ; Read status register from 8043 Keyboard Controller
    test al, 0x01                           ; Test bit 1 (Output buffer status)
    jz  Wait8043KeyboardControllerOutput    ; Loop if not empty
    ret

;#########################################
;
; Enable addressing line 20
;
;#########################################
enableA20:
    mov  al, 0xD0                           ; Read output port from 8043 Keyboard Controller
    out  0x64, al                           ; Send command to 8043 Keyboard Controller
    call Wait8043KeyboardControllerOutput
    in   al, 0x60                           ; Read input buffer from 8043 Keyboard Controller
    push ax
    call Wait8043KeyboardControllerInput
    mov  al, 0xD1                           ; Write output port from 8043 Keyboard Controller
    out  0x64, al                           ; Send command to 8043 Keyboard Controller
    call Wait8043KeyboardControllerInput
    pop  ax
    or   al, 0x02                           ; Set bit 2 to enable A20
    out  0x60, al                           ; Write input buffer from 8043 Keyboard Controller
    ret
