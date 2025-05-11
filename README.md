# Single-Cycle RV32I CPU Core

A minimal implementation of a single-cycle RISC-V CPU core supporting the RV32I instruction set, written in Verilog HDL.
This does not work and requires verification.

---

## Simulation

### Requirements:
- **QuestaSim/ModelSim**
- **Cocotb**

### How to Run:
```bash
cd sim/try_it
pip install cocotb  # Install dependencies
python3 run_test.py  # Start simulation
```
You can see the dump of registers and memory in `sim/try_it/core_state`
You can also initialize the memory and registers before starting the simulation with `sim/try_it/gpr.v` and `sim/try_it/memory.v`

## Building programs
To build programs you need https://github.com/riscv-collab/riscv-gnu-toolchain
Then see more
```bash
cd sim/try_it
make help
```
