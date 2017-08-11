;#########################################
;
; Clear screen
;
;#########################################
clearScreen:
    push es
    mov ax, 0xb800              ; Start video memory (0xB8000:0x0000)    
    mov es, ax
    mov ax, WORD [VIDEO_MEMORY_COLUMN]
    mul WORD [VIDEO_MEMORY_ROW]
    shl ax, 0x01
    mov dx, ax                  ; End video memory (column * row * 2)
    xor di, di
    mov ax, 0x0f00              ; White null character
.loop:
    mov WORD [es:di], 0x0f00    ; Two bytes per characters: color and ascii code
    add di, 0x02
    cmp di, dx
    jne .loop                   ; If end video memory offset
    pop es
    mov ah, 0x02                ; BIOS int 0x10 AH 0x02 - Set cursor position
    xor bh, bh                  ; Page number
    xor dx, dx                  ; Row and column numbers
    int 0x10                    ; BIOS interrupt
    ret

;#########################################
;
; Wait for a key press
;
;#########################################
waitKeyPress:
    mov ah, 0x00    ; BIOS int 0x16 AH 0x0 - Get keystroke
    int 0x16        ; BIOS interrupt
    ret

;#########################################
;
; Print string
; SI = String address
;
;#########################################
printString:
    mov ah, 0x0e    ; BIOS int 0x10 AH 0x0E - Teletype output 
    xor bx, bx      ; Page number and foreground color (graphics mode only)
.loop:
    lodsb           ; Load next byte from SI to AL
    test al, al
    je  .end        ; If end of the string
    int 0x10        ; BIOS interrupt
    jmp .loop
.end:
    ret

;#########################################
;
; Print error message, wait for a key
; press, then reboot
;
;#########################################
exitOnError:
    mov  si, exitError
    call printString
    call waitKeyPress
    db 0EAh                 ; Machine language to jump to FFFF:0000 (reboot)
    dw 0000h
    dw 0FFFFh

; ### Read Only Data ###
exitError         db "An error occurred, press any key to reboot...", 0
