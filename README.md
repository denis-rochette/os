# OS based on a microkernel

This OS is not intended to be a *real* OS or highly competitive... It's just a personal project made to learn how OS work.

Portability is not a priority for now, so it use its own x86-64 bootloader.

## Build dependencies
 * GNU/Linux ;)
 * coreutils
 * GNU make
 * gcc
 * ld
 * nasm
 * sed

# Build

```shell
make
```

# Running with QEMU

```shell
qemu-system-x86-64 [--no-reboot] -drive format=raw,file=os-x86-64.iso
```

# Bootloader

Very small 2-stages **x86-64** bootloader *(with probably a lot of mistakes)*, it do, in order:
 * load a *memory map* using BIOS
 * set a minimal data/code *GDT*
 * enable *A20*
 * load the kernel
 * enable *32-bit protected mode*
 * enable *physical address extension*
 * set a minimal identity *table directory*
 * enable *64-bit long mode*
 * jump to the *kernel*

More details can be found in the header of the *boot/x86/stage1/stage1.s*.
The bootloader probably need a relativly new BIOS for some interrupt extensions.

## Bootloader - TODO
 * Check if the BIOS has extenions, and print error otherwise (some functions skip this part)
 * Check is the CPU is compatible, and print error otherwise
 * Improved the A20 mechanism
 * *Multiboot specifications compliant?*
 * *Change the boot/x86/stage2/tableDirectory.inc it's basically the osdev.org's one*


### Feel free to add some *issues*, *comments*, *patches*, *ideas*, ... :)

