CROSS_PREFIX ?= riscv32-unknown-elf-
CC = $(CROSS_PREFIX)gcc
LD = $(CROSS_PREFIX)ld
OBJDUMP = $(CROSS_PREFIX)objdump
OBJCOPY = $(CROSS_PREFIX)objcopy


ASM_FILES = $(wildcard asm/*.s)
DIS_FILES = $(patsubst %.s,%.dis,$(ASM_FILES))
HEX_FILES = $(patsubst %.s,%.hex,$(ASM_FILES))

all: $(HEX_FILES) $(DIS_FILES)

clean:
	rm -f $(BIN_FILES)
	rm -f $(HEX_FILES)

asm/%.hex: asm/%.elf
	$(OBJCOPY) -O binary $< $@.tmp
	xxd -p -c 16 $@.tmp | ./rev_pad.py > $@

asm/%.obj: asm/%.s
	$(CC) -march=rv32i -c $< -o $@

asm/%.elf: asm/%.obj
	$(LD) -T ldscript.lds -e _start -o $@ $^

asm/%.dis: asm/%.elf
	$(OBJDUMP) -d $< > $@
