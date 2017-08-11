;#########################################
;
; Set a minimal identity table directory
; on the fist 2M
; ES:EDI = Table directory address
;
;#########################################
setTableDirectory:
    mov  cr3, edi       ; set CR3 to the table directory address

    push edi
    mov  ecx, 0x1000    ; set the initial 4K * 4 (due to rep) = 16K memory
    xor  eax, eax       ; with zero
    cld
    rep stosd
    pop edi

    mov eax, edi
    add eax, 0x1000                 ; Set PDPT at edi + 0x1000
    or  eax, 0b11                   ; Page are valid and R/W
    mov dword [edi], eax            ; Set PML4T at edi
    mov eax, edi
    add eax, 0x2000                 ; set PDT at edi + 0x2000
    or  eax, 0b11                   ; Page are valid and R/W
    mov dword [edi+0x1000], eax     ; set PDPT at edi + 0x1000
    mov eax, edi
    add eax, 0x3000                 ; set PT at edi + 0x3000
    or  eax, 0b11                   ; Page are valid and R/W
    mov dword [edi+0x2000], eax     ; set PDT at edi + 0x2000

    add edi, 0x3000
    mov ebx, 0b11
    mov ecx, 0x200
.loop:
    mov  dword [edi], ebx
    add  ebx, 0x1000
    add  edi, 0x08
    loop .loop
ret
