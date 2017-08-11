;#########################################
;
; Enable long mode
;
;#########################################
enableLongMode:
    mov ecx, 0xc0000080                         ; Read the EFER MSR
    rdmsr
    or  eax, 0b100000000                        ; Set the long mode bit
    wrmsr
    mov eax, cr0
    or  eax, 0b10000000000000000000000000000000 ; Set the paging
    mov cr0, eax
    ret
