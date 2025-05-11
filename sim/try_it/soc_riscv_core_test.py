import cocotb
from pathlib import Path
from cocotb.triggers import Timer, RisingEdge

program_path = Path(__file__).resolve().parent / "program.v"
memory_path = Path(__file__).resolve().parent / "memory.v"
gpr_init_path = Path(__file__).resolve().parent / "gpr.v"

file_program = open(program_path)
file_memory = open(memory_path)
file_gpr_init = open(gpr_init_path)

memory_list_path = Path(__file__).resolve().parent / "core_state" / "memory_list.mem"
gpr_list_path = Path(__file__).resolve().parent / "core_state" / "gpr_list.mem"

clk_period = 10
program = []
memory = []
gpr_init = []

pc_start_addr = 0
# write program to list
for four_instructions in file_program:
    if '@' in four_instructions:
        pc_start_addr = int(four_instructions[1:], 16)
    else:
        hex_four_instructions = four_instructions.split()
        for hex_instruction in hex_four_instructions:
            decimal_instruction = int(hex_instruction, 16)
            program.append(decimal_instruction)

# write data to list
for four_data in file_program:
    hex_four_data = four_data.split()
    for hex_data in hex_four_data:
        decimal_data = int(hex_data, 16)
        memory.append(decimal_data)

# write regs to list
for reg in file_gpr_init:
    hex_reg = reg.strip()
    decimal_reg = int(hex_reg, 16)
    gpr_init.append(decimal_reg)

#clock generate
async def clk_generate(dut, clk_period):
    for _ in range(10000):
        dut.clk.value = 0
        await Timer(clk_period / 2, units = 'ns')
        dut.clk.value = 1
        await Timer(clk_period / 2, units='ns')

#reset
async def rst_generate(dut, clk_period):
    dut.rst.value = 0
    await Timer(clk_period + clk_period/2, units='ns')
    dut.rst.value = 1

async def memory_fetch_initialization(dut):
    j = pc_start_addr
    for i in range(0, len(program)):
        dut.ram_fetch.mem[j >> 2] = program[i]
        j += 4
        
#write memory file to main memory
async def memory_data_initialization(dut):
    for i in range(0, len(memory)):
        dut.ram_data.mem[i] = memory[i]

# wrtie gpt_init to gpr
async def gpr_initialization(dut):
    for i in range(0, len(gpr_init)):
        dut.core.ID.GPR.register_memory[i] = gpr_init[i]


# create memory list
async def create_memory_list(dut):
    with open(memory_list_path, 'w') as file:
        for i in range(32):
            file.write(str(dut.ram_data.mem[i]) + '\n')

# create gpr list
async def create_gpr_list(dut):
    with open(gpr_list_path, 'w') as file:
        file.write("00000000000000000000000000000000" + '\n')
        for i in range(1, 32):
            file.write(str(dut.core.ID.GPR.register_memory[i]) + '\n')

async def instuction_wait(dut):
    await RisingEdge(dut.clk)
    while(dut.core.IF.RDATA.value == 0):
        await RisingEdge(dut.clk)
    print(f"Current Instruction: {hex(dut.core.IF.RDATA.value)}\n GPR:")
    for i in range(1, 32):
        print(hex(dut.core.ID.GPR.register_memory[i].value))

# @cocotb.test()
# async def debug_mode(dut):
#     await full_initialization(dut)
#     await RisingEdge(dut.clk)
#     i = input()
#     while i != 'stop':
#         i = input()
#         await instuction_wait(dut)
#         await Timer(clk_period, units='ns')

# full memory initialization
async def full_initialization(dut):
    cocotb.start_soon(clk_generate(dut, clk_period))
    cocotb.start_soon(rst_generate(dut, clk_period))
    cocotb.start_soon(memory_fetch_initialization(dut))
    cocotb.start_soon(memory_data_initialization(dut))
    cocotb.start_soon(gpr_initialization(dut))

@cocotb.test()
async def system_test(dut):
    await full_initialization(dut)
    await Timer(5000 * clk_period, units='ns')
    await create_memory_list(dut)
    await create_gpr_list(dut)
