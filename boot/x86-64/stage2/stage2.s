[ORG 0x8200]    ; 0x8200 offset
[BITS 16]       ; 16-bit real mode

;##################################################################################
;
; Stage 2 entry point
;
;##################################################################################
jmp 0x0000:stage2   ; Enforce the CS:IP to be 0x0000:0x8200

%include "config.inc"
%include "kernelConfig.inc"

%include "lib.inc"
%include "stage2/A20.inc"
%include "stage2/memoryMap.inc"
%include "stage2/readSectors.inc"
%include "stage2/gdt.inc"
%include "stage2/protectedMode.inc"

stage2:
    mov ax, 0x0820  ; Setup the special data segment registers at the stage 2 memory
    mov es, ax      ; Make ES correct

    mov  BYTE [bootDrive], dl   ; Save drive's index we boot from

    call loadMemoryMap

    call loadGdt                        ; We want to load the kernel at offset 0x00100000
    call enableA20                      ; However in 16-bit real mode, the addresses are only 20-bit long
    push ds                             ; We need the Unread mode: load a GDT, enable A20,
    call enableProtectedMode            ; Setup protected mode to use 32-bit data segments
    mov ax, 0x08                        ; Setup the first descriptor of the GDT
    mov ds, ax                          ; Make ES correct
    call disableProtectedMode           ; Setup back real mode to use the BIOS read interrupts
    pop ds
    call loadKernel                     ; Finally read the kernel in an unreal mode

    call enableProtectedMode            ; Protected mode
    jmp  dword GDT_CODE_SEGMENT:0x8600  ; Far jump, dword is use by NASM to do mixed-size jumps

;#########################################
;
; Load Memory map
;
;#########################################
loadMemoryMap:
    mov di, 0x7e02              ; Address Range Descriptor destination buffer at 0x0820:0x7e02 = 0x10002
    call memoryMap
    cmp ax, 0x01
    je .notSupported            ; If BIOS interrupt not supported
    cmp ax, 0x02
    je .error                   ; If an error occured
    mov WORD [0x7e00], cx       ; Otherwise, set entries count
    ret
.notSupported:
    mov si, biosInterruptNotSupported
    call printString
    jmp  exitOnError
.error:
    mov si, readMemoryMapFail
    call printString
    jmp  exitOnError

;#########################################
;
; Load kernel in memory
;
;#########################################
loadKernel:
    mov ebx, 0x00100000             ; Destination buffer 0x00100000 (32-bit registers due to unreal mode)
    mov ax, (STAGE2_SECTORS + 1)    ; Starting LBA sector
    mov cx, KERNEL_SECTORS          ; Number of sectors to read
    mov dl, BYTE [bootDrive]        ; Drive's index
    call readSectors
    cmp ax, 0x01
    je .notSupported                ; If BIOS interrupt not supported
    cmp ax, 0x02
    je .error                       ; If an error occured
    ret
.notSupported:
    mov si, biosInterruptNotSupported
    call printString
    jmp  exitOnError
.error:
    mov si, loadKernelFail
    call printString
    jmp  exitOnError


; ### Read Only Data ###
biosInterruptNotSupported db "BIOS interrupt not supported!", 10, 13, 0
loadKernelFail            db "Kernel loading failed!", 10, 13, 0
readMemoryMapFail         db "Memory map reading failed!", 10, 13, 0

; ### Data ###
bootDrive: db 0

times (BYTES_PER_SECTOR * STAGE2_REAL_SECTORS) - ($-$$) db 0    ; Fill sector
