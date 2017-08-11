global kmain

bits 64
section .text
kmain:
    mov dword [0xb8000], 0x2f4b2f4f
    hlt
