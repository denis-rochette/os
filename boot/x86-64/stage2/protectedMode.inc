;#########################################
;
; Enable protected mode
;
;#########################################
enableProtectedMode:
    mov eax, cr0
    or  eax, 0b1    ; Set protected mode bit
    mov cr0, eax
    ret

;#########################################
;
; Disable protected mode
;
;#########################################
disableProtectedMode:
    mov eax, cr0
    and eax, 0b11111110 ; Unset protected mode bit
    mov cr0, eax
    ret
