from cocotb.runner import get_runner
from pathlib import Path
# import argparse

def main():
    hdl_toplevel_lang = "verilog"
    
    # parser = argparse.ArgumentParser()
    # parser.add_argument("-GUI", default="True")
    # parser.add_argument("-SIM", default="questa")
    # parser.add_argument("-W", default="True")
    # parser.add_argument("-DEBUG", default="False")
    
    # args = parser.parse_args()
    
    # sim = args.SIM
    # gui = args.GUI
    # waves = args.W
    # test_module_dict = {"True": "soc_riscv_core_debug", "False": "soc_riscv_core_test"}
    # test_module = test_module_dict[args.DEBUG]

    # print(sim, gui, waves, test_module)
    
    proj_path = Path(__file__).resolve().parent.parent.parent

    verilog_sources = []
    vhdl_sources = []

    if hdl_toplevel_lang == "verilog":
        verilog_sources = [proj_path / "rtl" / "packages" / "alu_control_pkg.sv",
                           proj_path / "rtl" / "packages" / "shift_control_pkg.sv",
                           proj_path / "rtl" / "packages" / "core_pkg.sv",
                           proj_path / "rtl" / "packages" / "comparator_control_pkg.sv",
                           proj_path / "rtl" / "packages" / "imm_types_pkg.sv",
                           proj_path / "rtl" / "packages" / "mem_control_pkg.sv",
                           proj_path / "rtl" / "soc_riscv_core.sv",
                           proj_path / "sim" / "try_it" / "sv" / "main_ram_fetch.sv",
                           proj_path / "sim" / "try_it" / "sv" / "main_ram_data.sv",
                           proj_path / "rtl" / "core_decode_stage" / "core_decode_stage.sv",
                           proj_path / "rtl" / "core_decode_stage" / "instruction_decode_unit.sv",
                           proj_path / "rtl" / "core_decode_stage" / "core_register_file.sv",
                           proj_path / "rtl" / "core_execution_stage" / "core_alu.sv",
                           proj_path / "rtl" / "core_execution_stage" / "core_comparator.sv",
                           proj_path / "rtl" / "core_execution_stage" / "core_shift.sv",
                           proj_path / "rtl" / "core_execution_stage" / "core_execution_stage.sv",
                           proj_path / "rtl" / "core_fetch_stage" / "core_fetch_stage.sv",
                           proj_path / "rtl" / "core_fetch_stage" / "instruction_fetch_unit.sv",
                           proj_path / "rtl" / "core_memory_stage" / "load_store_unit.sv",
                           proj_path / "sim" / "try_it" / "sv" / "soc_riscv_core_test.sv"]

    runner = get_runner("questa")

    runner.build(
        verilog_sources = verilog_sources,
        vhdl_sources = vhdl_sources,
        includes = [proj_path / "packages"],
        hdl_toplevel ="soc_riscv_core_test",
        always = True,
    )

    runner.test(
        hdl_toplevel = "soc_riscv_core_test",
        test_module = "soc_riscv_core_test",
        waves = True,
        gui = True,
    )


if __name__ == "__main__":
    main()
