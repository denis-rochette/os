;#########################################
;
; Read sectors of drive
; AX = Starting LBA sector
; CX = Number of sectors to read
; DL = Drive's index
; EBX = Destination buffer (Unreal mode)
;
; AX = 0 success / 1 not supported / 2 error
;
;#########################################
readSectors:
    push ax
    push cx
    push dx
    push ebx
    mov  ah,  0x41          ; BIOS int 0x13 AH 0x41 - INT 13 extensions installation check
    mov  bx,  0x55aa        ; Magic number (I guess)
    int 0x13                ; BIOS interrupt
    jc .notSupported        ; If not supported by the BIOS
    cmp  bx,  0xaa55
    jne .notSupported       ; If not installed
    pop ebx
    pop dx
    pop cx
    pop ax
.loop:
    mov  WORD [dap + 2], 0x01       ; Number sectors to read
    mov  WORD [dap + 4], 0x00       ; Buffer offset, little endian
    mov  WORD [dap + 6], 0x3000     ; Buffer segment, some free for use memory
    mov  WORD [dap + 8], ax         ; Starting LBA sector
    mov  ah,  0x42                  ; BIOS int 0x13 AH 0x42 - Extented read
    mov  si,  dap                   ; Dap offset
    int 0x13                        ; BIOS interrupt
    jc .error                       ; If error
    cmp  WORD [dap + 2], 0x01       
    jne .error                      ; If error
    push cx
    push ax
    mov  ax,  ds
    mov  es,  ax
    mov  esi,  0x30000              ; Copying read memory
    mov  edi, ebx                   ; To ebx
    mov  cx, (BYTES_PER_SECTOR / 4) ; cx / 4 du to movsD
    cld
    a32 rep movsd                   ; Move using esi/edi
    pop ax
    pop cx
    add  ebx, BYTES_PER_SECTOR
    add  ax,  0x01                  ; Next sector
    sub  cx,  0x01
    test cx,  cx
    jne .loop                       ; If sector count is not zero
    mov  ax,  0x00
    ret
.notSupported:
    pop bx
    pop dx
    pop cx
    pop ax
    mov  ax,  0x01 
    ret
.error:
    mov  ax,  0x02
    ret

; ### Disk Address Packet
dap:
    db 0x10 ; Size of dap
    db 0x00 ; Unused
    dw 0x00 ; Number sector to read
    dw 0x00 ; Buffer offset
    dw 0x00 ; Buffer segment 
    dq 0x00 ; Starting LBA sector
