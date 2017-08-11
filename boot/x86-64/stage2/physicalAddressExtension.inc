;#########################################
;
; Enable long mode
;
;#########################################
enablePhysicalAddressExtension:
    mov eax, cr4
    or  eax, 0b100000   ; Set the PAE bit
    mov cr4, eax
    ret
