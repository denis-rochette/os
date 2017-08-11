;##################################################################################
;
; 32-bit protected mode entry point
;
;##################################################################################
[ORG 0x8600]    ; 0x8600 offset
[BITS 32]       ; 32-bit protected mode

jmp stage2Protected

%include "config.inc"
%include "kernelConfig.inc"

%include "stage2/gdt.inc"
%include "stage2/longMode.inc"
%include "stage2/physicalAddressExtension.inc"
%include "stage2/tableDirectory.inc"

stage2Protected:
    mov ax, GDT_DATA_SEGMENT    ; Setup GDT data segments
    mov ds, ax                  ; Make DS correct
    mov es, ax                  ; Make ES correct
    mov fs, ax                  ; Make FS correct 
    mov gs, ax                  ; Make GS correct 
    ;mov ss, ax                  ; This is wrong, and should be patched, but we don't use stack anymore

    call enablePhysicalAddressExtension
    mov edi, 0x20000                    ; Table directory at 0x0000:0x20000
    call setTableDirectory
    call enableLongMode

    jmp  GDT_CODE_SEGMENT:0x8800


times (BYTES_PER_SECTOR * STAGE2_PROTECTED_SECTORS) - ($-$$) db 0   ; Fill sector
