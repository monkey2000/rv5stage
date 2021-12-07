CROSS_PREFIX ?= riscv32-unknown-elf-
CC = $(CROSS_PREFIX)gcc
LD = $(CROSS_PREFIX)ld
OBJDUMP = $(CROSS_PREFIX)objdump
OBJCOPY = $(CROSS_PREFIX)objcopy

CFLAGS = -march=rv32i -ffreestanding -nostdlib -nostartfiles

ASM_FILES = $(wildcard asm/*.s)
ASM_DIS_FILES = $(patsubst %.s,%.dis,$(ASM_FILES))
ASM_HEX_FILES = $(patsubst %.s,%.hex,$(ASM_FILES))

C_FILES = $(wildcard c/*.c)
C_DIS_FILES = $(patsubst %.c,%.dis,$(C_FILES))
C_HEX_FILES = $(patsubst %.c,%.hex,$(C_FILES))

all: bl/bootloader.obj $(ASM_DIS_FILES) $(ASM_HEX_FILES) $(C_DIS_FILES) $(C_HEX_FILES)

clean:
	rm -f $(ASM_DIS_FILES)
	rm -f $(ASM_HEX_FILES)
	rm -f $(C_DIS_FILES)
	rm -f $(C_HEX_FILES)

bl/bootloader.obj: bl/bootloader.s
	$(CC) $(CFLAGS) -c $< -o $@

asm/%.obj: asm/%.s
	$(CC) $(CFLAGS) -c $< -o $@

asm/%.elf: asm/%.obj
	$(LD) -T ldscript.lds -e _start -o $@ $^

asm/%.hex: asm/%.elf
	$(OBJCOPY) -O binary $< $@.tmp
	xxd -p -c 16 $@.tmp | ./rev_pad.py > $@
	rm $@.tmp

asm/%.dis: asm/%.elf
	$(OBJDUMP) -d $< > $@

c/%.obj: c/%.c
	$(CC) $(CFLAGS) -c $< -o $@

c/%.elf: c/%.obj bl/bootloader.obj
	$(LD) -T ldscript.lds -e _start -o $@ $^

c/%.hex: c/%.elf
	$(OBJCOPY) -O binary $< $@.tmp
	xxd -p -c 16 $@.tmp | ./rev_pad.py > $@
	rm $@.tmp

c/%.dis: c/%.elf
	$(OBJDUMP) -d $< > $@
