ENTRY(kmain)

OUTPUT_FORMAT(binary)

SECTIONS {
    . = 1M;
    .text :
    {
        *(.text)
    }
}
