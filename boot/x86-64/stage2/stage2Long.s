;##################################################################################
;
; 64-bit long mode entry point
;
;##################################################################################
[ORG 0x8800]    ; 0x8800 offset
[BITS 64]       ; 64-bit protected mode

jmp stage2Long

%include "config.inc"
%include "kernelConfig.inc"

stage2Long:
    call 0x00100000
    cli
    hlt

times (BYTES_PER_SECTOR * STAGE2_LONG_SECTORS) - ($-$$) db 0   ; Fill sector
