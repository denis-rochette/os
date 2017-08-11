;#########################################
;
; Load GDT
;
;#########################################
loadGdt:
    lgdt [gdtDescriptor]    ; Load GTD register
    ret

; ### Global Descriptor Table ###
gdtStart:
    dd 0x00         ; First empty entry (base address)
    dd 0x00         ; First empty entry (segment limit)
gdtData:
    db 0xff         ; Lowest byte of limit
    db 0xff         ; Highest byte of limit
    db 0x00         ; Lowest byte of base address
    db 0x00         ; Second byte of base address
    db 0x00         ; Third byte of base address
    db 0b10010010   ; Type
    db 0b11001111   ; Size
    db 0x00         ; Highest byte of base address
gdtCode:
    db 0xff         ; Lowest byte of limit
    db 0xff         ; Highest byte of limit
    db 0x00         ; Lowest byte of base address
    db 0x00         ; Second byte of base address
    db 0x00         ; Third byte of base address
    db 0b10011010   ; Type
    db 0b11001111   ; Size
    db 0x00         ; Highest byte of base address
gdtEnd:

gdtDescriptor:
    dw gdtEnd - gdtStart - 1    ; Size of the gtd minus 1
    dd gdtStart

GDT_CODE_SEGMENT equ gdtCode - gdtStart
GDT_DATA_SEGMENT equ gdtData - gdtStart

