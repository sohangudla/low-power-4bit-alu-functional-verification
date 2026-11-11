# =============================================================================
# FILE   : run_sim.do
# USE IN : ModelSim or QuestaSim (Tools -> TCL Console -> do run_sim.do)
# =============================================================================

# Create and map work library
vlib work
vmap work work

# Compile DUT files first (order matters)
vlog -sv -work work ../alu_pkg.sv
vlog -sv -work work ../method4_alu.sv

# Compile testbench files
vlog -sv -work work alu_if.sv
vlog -sv -work work alu_dut_wrapper.sv
vlog -sv -work work tb_top.sv

# Run simulation
vsim -t 1ps -sv_seed random work.tb_top

# Log all signals
log -r /*

# Run until $finish
run -all

# Print final messages
echo "Simulation complete."
