;-------------------------------------|         |-------------------------------------|
;                                     |         |                                     |
;         MEMORY MAP - First MB       |         |         MODERN STANDARD MBR         |
;                                     |         |                                     |
;-0x00000000-|------------------------|     ,---|---offset---|                        |
;            |                        |    /    |-0x00000000-|------------------------|
;            |                        |    |    |            |                        |
;    1 KB    |  Real Mode Interrupt   |    |    |            |                        |
;            |      Vector Table      |    |    |  218 bytes |  Free for use memory   |
;            |                        |    |    |            |                        |
;-0x00000400-|------------------------|    |    |            |                        |
;            |                        |    |    |-0x000000DA-|------------------------|
;            |                        |    |    |            |                        |
;  256 bytes |     BIOS Data Aera     |  Start  |            |                        |
;            |                        |  there  |   6 bytes  |     Disk timestamp     |
;            |                        |    |    |            |                        |
;-0x00000500-|------------------------|    |    |            |                        |
;            |                        |    |    |-0x000000E0-|------------------------|
;            |                        |    |    |            |                        |
;    30 KB   |  Free for use memory   |    |    |            |                        |
;            |                        |    |    |  216 bytes |  Free for use memory   |
;            |                        |    /    |            |                        |
;-0x00007C00-|------------------------|---'     |            |                        |
;            |                        |         |-0x000001B8-|------------------------|
;            |                        |         |            |                        |
;  512 bytes |       BootSector       |         |            |                        |
;            |                        |         |   6 bytes  |     Disk signature     |
;            |                        |         |            |                        |
;-0x00007E00-|------------------------|         |            |                        |
;            |                        |         |-0x000001BE-|------------------------|
;            |                        |         |            |                        |
;   492 KB   |  Free for use memory   |         |            |                        |
;            |                        |         |  64 bytes  |    Partition table     |
;            |                        |         |            |                        |
;-0x00080000-|- - - - - - - - - - - - |         |            |                        |
;            |                        |         |-0x000001FE-|------------------------|
;            |                        |         |            |                        |
;   130 KB   |  Free for use memory   |         |            |                        |
;            |                        |         |   2 bytes  |     Boot signature     |
;            |                        |         |            |                        |
; 0x0009FC00 |------------------------|         |            |                        |
;            |                        |         |-0x00000200-|------------------------|
;            |                        |     
;   130 KB   |   Extended BIOS Data   |     
;            |          Area          |     
;            |                        |     
;-0x000A0000-|------------------------|     
;            |                        |     
;            |                        |     
;   393 KB   |     Various memory     |     
;            |                        |     
;            |                        |     
;-0x00100000-|------------------------|     

;-------------------------------------|
;                                     |
;         MEMORY MAP - Bootloader     |
;                                     |
;-0x00007C00-|------------------------|
;            |                        |
;            |                        |
;  512 bytes |        Stage 1         |
;            |                        |
;            |                        |
;-0x00007E00-|------------------------|
;            |                        |
;            |                        |
; 1024 bytes |    Bootloader stack    |
;            |                        |
;            |                        |
;-0x00008200-|------------------------|
;            |                        |
;            |                        |
; 1024 bytes |        Stage 2         |
;            |                        |
;            |                        |
;-0x00008600-|- - - - - - - - - - - - |
;            |                        |
;            |                        |
;  512 bytes |   Stage 2 protected    |
;            |                        |
;            |                        |
;-0x00008800-|- - - - - - - - - - - - |
;            |                        |
;            |                        |
;  512 bytes |      Stage 2 long      |
;            |                        |
;            |                        |
;-0x00009000-|------------------------|
;            |                        |
;-0x00010000-|------------------------|
;            |                        |
;            |        Address         |
;            |                        |
;            |    Range Descriptor    |
;            |                        |
;-0x0001????-|++++++++++++++++++++++++|
;            |                        |
;-0x00020000-|------------------------|
;            |                        |
;            |                        |
;            |    Page directories    |
;            |                        |
;            |                        |
;-0x0002????-|++++++++++++++++++++++++|
;            |                        |
;-0x00030000-|------------------------|
;            |                        |
;            |                        |
;            |  Free for use memory   |
;            |                        |
;            |                        |
;-0x0009FC00-|------------------------|
;            |                        |
;-0x00100000-|------------------------|
;            |                        |
;            |                        |
;            |         Kernel         |
;            |                        |
;            |                        |
;-0x????????-|++++++++++++++++++++++++|

%include "config.inc"

[ORG 0x7c00]    ; 0x7c00 offset
[BITS 16]       ; 16-bit real mode

;##################################################################################
;
; Stage 1 entry point
;
;##################################################################################
[SECTION .textOne start=0x7c00]
jmp 0x0000:stage1   ; Enforce the CS:IP to be 0x0000:0x7c00 (due to logical segmentation address)

%include "lib.inc"

stage1:
    cli             ; Disable interrupts
    xor ax, ax      ; Setup the data segment registers at the stage 1 memory
    mov ds, ax      ; Make DS correct
    mov ax, 0x07c0
    mov es, ax      ; Make ES correct
    mov ax, 0x07e0  ; Setup the stack segment registers at the bootloader stack memory
    mov ss, ax      ; Make SS correct
    mov bp, 0x03ff  ; Setup 1024 bytes stack
    mov sp, 0x03ff

    mov BYTE [bootDrive], dl    ; Save drive's index we boot from
    call clearScreen
    call loadStage2

    mov dl, BYTE [bootDrive]    ; Save drive's index we boot from, for stage 2
    jmp 0x0000:0x8200           ; Jump stage 2

;#########################################
;
; Load stage 2 in memory
;
;#########################################
loadStage2:
    mov ax, 0x01            ; Second sector
    mov cx, STAGE2_SECTORS
    mov bx, 0x0600          ; 512 stage 1 + 1024 stack
    call readSectors
    ret

;#########################################
;
; Convert LBA to CHS
; AX = LBA address to convert
;
; CL = Sectors number
; DH = Heads number
; CH = Cylinders number
;
;#########################################
LBAToCHS:
    mov dl, SECTORS_PER_TRACK
    div dl
    inc ah
    mov cl, ah                  ; Sector number  = (LBA % sectorPerTrack) + 1
    xor ah, ah
    mov dl, HEADS_PER_CYLINDER
    div dl
    mov dh, ah                  ; Head number = (LBA / sectorPerTrack) % headPerCylinder
    mov ch, al                  ; Cylinder number = (LBA / sectorPerTrack) / HEADS_PER_CYLINDER
    ret

[SECTION .diskTimestamp start=0x7cda]
dw  0x00
db  0x00
db  0x00
db  0x00
db  0x00

[SECTION .textTwo follows=.diskTimestamp]
;#########################################
;
; Read sectors of drive
; AX = Starting LBA sector
; CX = Number of sectors to read
; ES:BX = Destination buffer
;
;#########################################
readSectors:
    mov dx, 0x05                ; Five retries for read's errors
.loop:
    push ax
    push cx
    push bx
    push dx
    call LBAToCHS               ; CL(Sectors number), DH(Heads number), CH(Cylinders number)
    mov ah, 0x02                ; BIOS int 0x13 AH 0x02 - Reads sectors of drive
    mov al, 0x01                ; Read one sectors
    mov dl, BYTE [bootDrive]    ; Drive index
    int 0x13                    ; BIOS interrupt
    jc .error                   ; If a read error occured
    test al, 0x01
    je .error                   ; If no sector has been read
    pop dx
    pop bx
    pop cx
    pop ax
    add bx, BYTES_PER_SECTOR    ; Increase destination buffer
    inc ax                      ; Next sector
    dec cx                      ; One sector less
    test cx, cx
    jne readSectors             ; If sectors need to be read
    ret
.error:
    xor ax, ax                  ; BIOS int 0x13 AH 0x00 - Reset drive
    int 0x13                    ; BIOS interrupt
    pop dx
    pop bx
    pop cx
    pop ax
    dec dx                      ; One chance less
    jnz .loop                   ; Retry if there is still chances
    mov si, readDriveError
    call printString
    jmp exitOnError

; ### Read Only Data ###
readDriveError db "Drive reading failed!", 13, 10, 0

; ### Data ###
bootDrive: db 0

; ### MBR Signature ###
[SECTION .MBRSignature start=0x7db8]
            dd  0x00    ; Disk signature
            dw  0x00    ; Non-copy protected
times 16    db  0x00    ; Partition entry 1
times 16    db  0x00    ; Partition entry 2
times 16    db  0x00    ; Partition entry 3
times 16    db  0x00    ; Partition entry 4
            dw  0xaa55  ; Boot signature
