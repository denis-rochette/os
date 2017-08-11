;#########################################
;
; Get memory map from bios
; ES:DI = Address Range Descriptor destination buffer
;
; AX = 0 success / 1 not supported / 2 error
; CX = Entries count
;
;#########################################
memoryMap:
    xor cx, cx
    push cx
    mov eax, 0x0000e820 			; BIOS int 0x15 AX 0xE820 (EAX on some BIOSes) - Get system memory map
    xor ebx, ebx        			; Start at beginning of map
    mov ecx, 0x14       			; Size of Address Range Descriptor buffer
    mov edx, 'PAMS'     			; "SMAP"
    int 0x15            			; BIOS interrupt
    jc .notSupported    			; If not supported by the BIOS
    cmp eax, 'PAMS'
    jne .error          			; If BIOS doesn't return "SMAP"
    test ebx, ebx
    je .error           			; If Address Range Descriptor is one entry long
    jmp .testEntry
.loop:
    mov eax, 0x0000e820 			; BIOS int 0x15 AX 0xE820 (EAX on some BIOSes) - Get system memory map
    mov ecx, 0x14       			; Size of Address Range Descriptor buffer
    mov edx, 'PAMS'     			; "SMAP"
    int 0x15            			; BIOS interrupt
.testEntry:
    jcxz .skipEntry     			; If length return is O
    mov ecx, [es:di + 0x08] 		; Get low part of length
    test ecx, ecx
    jne .addEntry                   ; If length > 0
    mov ecx, [es:di + 0x08 + 0x04]  ; Get low part of length
    jecxz .skipEntry                ; If length = 0
.addEntry:
    pop cx
    inc cx                          ; New entry
    push cx
    add di, 0x14                    ; Destination buffer to next entry
.skipEntry:
    test ebx, ebx
    jne .loop                       ; If get system memory map is done
    pop cx
    ret
.notSupported:
    pop cx
    mov ax, 0x01 
    ret
.error:
    pop cx
    mov ax, 0x02
    ret

; ### Address Range Descriptor (Multiboot specification)
;   db  Size of the structure in bytes
;   dq  Base address of address range
;   dq  Length in bytes of address range
;   dd  Type of address range
