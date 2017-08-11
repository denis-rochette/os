#---TOOLS---
MKDIR   :=  mkdir -p
RM      :=  rm -rf

#---NAMES---
ARCH        :=  x86-64
ISO         :=  os-$(ARCH).iso
BOOTLOADER  :=  bootloader
KERNEL      :=	os-$(ARCH)

#---COMPILERS/LINKERS---
AS  :=  nasm
RC  :=  rustc
LD  :=  ld

#---FLAGS---
RFLAGS  :=  --emit=obj
ASFLAGS :=  -f elf32
LDFLAGS :=	-T linker.ld -m elf_i386
LDLIBS  :=

#---DIRECTORIES---
BOOT_DIR    :=  ./boot/$(ARCH)/
LIBS_DIR    :=  ./lib/
SRCS_DIR    :=  ./src/
OBJS_DIR    :=  ./obj/

#---SOURCES---
BOOT_SRCS   :=	$(BOOT_DIR)/stage1/stage1.s         \
                $(BOOT_DIR)/stage2/stage2.s         \
                $(BOOT_DIR)/stage2/stage2Protected.s\
                $(BOOT_DIR)/stage2/stage2Long.s     # The order is very important!
LIBS_SRCS   :=  #$(LIBS_DIR)
SRCS	    :=	$(wildcard $(SRCS_DIR)/$(ARCH)/*.s)

#---OBJECTS---
BOOT_OBJS   :=  $(BOOT_SRCS:$(BOOT_DIR)%.s=$(OBJS_DIR)%.o)
LIBS_OBJS   :=  $(LIBS_SRCS:$(LIBS_DIR)%.rs=$(OBJS_DIR)%.o)
OBJS        :=  $(patsubst $(SRCS_DIR)%.s,  $(OBJS_DIR)%.o, $(filter %.s,  $(SRCS)))\
                $(patsubst $(SRCS_DIR)%.rs, $(OBJS_DIR)%.o, $(filter %.rs, $(SRCS)))

#---BOOTLOADER CONFIG (Architecture dependent)---
CONFIG              :=  $(BOOT_DIR)/config.inc
KERNEL_CONFIG       :=  $(BOOT_DIR)/kernelConfig.inc
BYTES_PER_SECTOR    :=  $(shell printf "%d" `sed -n 's/%define[[:space:]]\+BYTES_PER_SECTOR[[:space:]]\+\(0x[0-9A-Fa-f]\+\)/\1/p' $(CONFIG)`)
ISO_SECTORS         =   $(shell expr '(' `du -b $(BOOTLOADER) | cut -f1` + `du -b $(KERNEL) | cut -f1` ')' / $(BYTES_PER_SECTOR) + 1)
BOOTLOADER_SECTORS  =   $(shell expr 1 + `printf "%d" $(shell sed -n 's/%define[[:space:]]\+STAGE2_SECTORS[[:space:]]\+\(0x[0-9A-Fa-f]\+\)/\1/p' $(CONFIG))`)
KERNEL_SECTORS      =   $(shell expr `du -b $(KERNEL) | cut -f1` / $(BYTES_PER_SECTOR) + 1)

#---RULES---
all: $(ISO)
	@tput bold; tput setaf 2; echo "Build done!"; tput sgr0 setaf 9

$(ISO): $(OBJS_DIR) $(KERNEL) $(BOOTLOADER)
	@dd if=/dev/zero of=$@ bs=$(BYTES_PER_SECTOR) count=$(ISO_SECTORS) status=none
	@cat $(BOOTLOADER) $(KERNEL) | dd of=$@ conv=notrunc status=none
	@tput el && tput bold && tput setaf 7 && echo -n "Iso build:              " && tput bold && tput setaf 2 && echo "✓" && tput sgr0 setaf 9

$(OBJS_DIR):
	@$(MKDIR) $(OBJS_DIR)
	@$(MKDIR) $(OBJS_DIR)/stage1
	@$(MKDIR) $(OBJS_DIR)/stage2
	@$(MKDIR) $(OBJS_DIR)/$(ARCH)

$(BOOTLOADER): setKernelSectors $(BOOT_OBJS)
	@dd if=/dev/zero of=$@ bs=$(BYTES_PER_SECTOR) count=$(BOOTLOADER_SECTORS) status=none
	@cat $(BOOT_OBJS) | dd of=$@ conv=notrunc status=none
	@tput el && tput bold && tput setaf 7 && echo -n "Bootloader compilation: " && tput bold && tput setaf 2 && echo "✓" && tput sgr0 setaf 9

$(KERNEL): $(LIBS_OBJS) $(OBJS)
	@$(LD) $(LDFLAGS) $(LDLIBS) -o $@ $^
	@tput el && tput bold && tput setaf 7 && echo -n "Kernel compilation:     " && tput bold && tput setaf 2 && echo "✓" && tput sgr0 setaf 9

setKernelSectors: $(KERNEL)
	@sed -i "s/%define\([[:space:]]\+\)KERNEL_SECTORS\([[:space:]]\+\)0x[0-9A-Fa-f]\+/%define\1KERNEL_SECTORS\20x$(KERNEL_SECTORS)/g" $(KERNEL_CONFIG)

$(OBJS_DIR)%.o: $(BOOT_DIR)%.s
	@tput el && tput bold && tput setaf 7 && echo -n "Compilation:            " && tput bold && tput setaf 3 && echo "..." && tput sgr0 setaf 9
	@tput cuu 1
	@$(AS) -I $(BOOT_DIR) -f bin -o $@ $^ || (tput el && tput bold && tput setaf 7 && echo -n "Compilation:            " && tput bold && tput setaf 1 && echo "✗" && tput sgr0 setaf 9; false)

$(OBJS_DIR)%.o: $(LIBS_DIR)%.rs
	@tput el && tput bold && tput setaf 7 && echo -n "Compilation:            " && tput bold && tput setaf 3 && echo "..." && tput sgr0 setaf 9
	@tput cuu 1
	@$(RC) $(RCFLAGS) -o $@ $^ || (tput el && tput bold && tput setaf 7 && echo -n "Compilation:            " && tput bold && tput setaf 1 && echo "✗" && tput sgr0 setaf 9; false)

$(OBJS_DIR)%.o: $(SRCS_DIR)%.rs
	@tput el && tput bold && tput setaf 7 && echo -n "Compilation:            " && tput bold && tput setaf 3 && echo "..." && tput sgr0 setaf 9
	@tput cuu 1
	@$(RC) $(RCFLAGS) -o $@ $^ || (tput el && tput bold && tput setaf 7 && echo -n "Compilation:            " && tput bold && tput setaf 1 && echo "✗" && tput sgr0 setaf 9; false)

$(OBJS_DIR)%.o: $(SRCS_DIR)%.s
	@tput el && tput bold && tput setaf 7 && echo -n "Compilation:            " && tput bold && tput setaf 3 && echo "..." && tput sgr0 setaf 9
	@tput cuu 1
	@$(AS) -I $(SRCS_DIR) $(ASFLAGS) -o $@ $^ || (tput el && tput bold && tput setaf 7 && echo -n "Compilation:            " && tput bold && tput setaf 1 && echo "✗" && tput sgr0 setaf 9; false)

clean:
	@tput bold && tput setaf 7 && echo -n "Objects clean:          " && tput sgr0 setaf9
	@$(RM) $(OBJS_DIR) $(BOOTLOADER) $(KERNEL)
	@tput bold && tput setaf 2 && echo "✓" && tput sgr0 setaf9

distclean: clobber
realclean: clobber
clobber: clean
	@tput bold && tput setaf 7 && echo -n "Directory clean:        " && tput sgr0 setaf9
	@$(RM) $(ISO)
	@tput bold && tput setaf 2 && echo "✓" && tput sgr0 setaf9

.PHONY: all clean distclean realclean clobber setKernelSectors
