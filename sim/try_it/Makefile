SRC ?= prog  # Name of .c or .s file (without extension)
RV_TOOLCHAIN ?= riscv64-unknown-elf  # Toolchain prefix (e.g. riscv32-unknown-elf, riscv64-unknown-linux-gnu)

RV_TOOLCHAIN := $(strip $(RV_TOOLCHAIN))
CC := $(RV_TOOLCHAIN)-gcc
OBJDUMP := $(RV_TOOLCHAIN)-objdump
OBJCOPY := $(RV_TOOLCHAIN)-objcopy

.PHONY: all c asm help clean

all: c

%.o: %.s
	$(CC) -c -march=rv32i -mabi=ilp32 $< -o $@

c: $(SRC).c
	$(CC) -S -march=rv32i -mabi=ilp32 $< -o $(SRC).s
	$(MAKE) asm

asm: $(SRC).o
	$(MAKE) _objdump_verilog

_objdump_verilog: $(SRC).o
	$(OBJDUMP) -d $<
	$(OBJCOPY) -O verilog --verilog-data-width 4 $< program.v

help:
	@echo "Targets:"
	@echo "------------------"
	@echo "c                -- Compile C source to verilog RV32I instructions"
	@echo "asm              -- Assemble ASM source to verilog RV32I instructions"
	@echo "help             -- Show this help message"
	@echo "clean            -- Clean object files and program.v"
	@echo "clean_src        -- Clean C and ASM files"
	@echo "clean_all        -- Clean all"
	@echo
	@echo "Flags:"
	@echo "------------------"
	@echo "SRC             -- Source file name (default: prog)"
	@echo "RV_TOOLCHAIN    -- RISC-V toolchain prefix (default: riscv64-unknown-elf)"

clean:
	rm -f *.o
	rm -f program.v

clean_src:
	rm -f *.c
	rm -f *.s

clean_all: 
	$(MAKE) clean clean_src