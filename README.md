SystemVerilog, Vivado, Artix-7 FPGA
•	Designed a 4-bit ALU in SystemVerilog supporting 8 operations; synthesized on Basys-3 FPGA, establishing a baseline dynamic power of 2.554 W.
•	Built layered verification environment (generator, driver, monitor, scoreboard); ran 200 randomized test vectors to validate all operations.
•	Optimized the design using a glitch-free conditional output register, achieving 48.8% dynamic power reduction — 2.554 W → 1.307 W — verified via Vivado simulation.

## Source code

| Path | Contents |
|---|---|
| `rtl/alu_pkg.sv` | Shared opcode/type package |
| `rtl/baseline_alu.sv` | Baseline 4-bit ALU (8 operations) |
| `rtl/method1_alu.sv` … `method4_alu.sv` | Low-power variants (incl. glitch-free conditional output register) |
| `rtl/tb_all_methods.sv` | Testbench comparing all methods |
| `tb_layered_v1/` | Layered SystemVerilog testbench: transaction, generator, driver, monitor, scoreboard, environment, interface, DUT wrapper, `run_sim.do` |
| `tb_layered_v2/` | Refined layered testbench |
| `constraints/x.xdc` | Basys-3 constraints |
| `fv_final_report.docx` | Project report |
