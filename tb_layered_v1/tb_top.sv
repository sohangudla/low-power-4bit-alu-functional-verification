// =============================================================================
// FILE        : tb_top.sv
// DESCRIPTION : Top-level testbench module.
//               This is the ONLY module (not a class). It:
//                 1. Declares the clock and drives it
//                 2. Instantiates the alu_if interface
//                 3. Instantiates the DUT (method4_alu) and connects it
//                 4. Creates the Environment object
//                 5. Runs the test and calls $finish
//
//               IMPORTANT: Replace "method4_alu" with your actual DUT module
//               name if it is different. The port list must match your DUT.
// =============================================================================

`timescale 1ns/1ps

`include "alu_environment.sv"

module tb_top;

    // =========================================================================
    // Clock generation — 10ns period (100 MHz)
    // =========================================================================
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // =========================================================================
    // Interface instantiation
    // =========================================================================
    alu_if dut_if (.clk(clk));

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    // *** REPLACE the module name and port names below to match YOUR DUT ***
    // The DUT used here matches the method4_alu from the earlier project.
    // Your DUT must expose: clk, rst_n, A, B, sel, alu_en, result, carry_out
    // =========================================================================
    method4_alu DUT (
        .clk      (dut_if.clk),
        .rst_n    (dut_if.rst_n),
        .A        (dut_if.A),
        .B        (dut_if.B),
        .sel      (dut_if.sel),
        .alu_en   (dut_if.alu_en),
        .ALU_Out  (dut_if.result),      // map your DUT output name here
        .CarryOut (dut_if.carry_out)    // map your DUT carry name here
    );

    // =========================================================================
    // Environment
    // =========================================================================
    alu_environment env;

    // =========================================================================
    // Main test flow
    // =========================================================================
    initial begin
        // Waveform dump (works in both Vivado and ModelSim)
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        $display("\n");
        $display("=====================================================");
        $display("   4-BIT ALU LAYERED TESTBENCH — SIMULATION START  ");
        $display("=====================================================\n");

        // Create environment (60 total transactions: 32 directed + 28 random)
        env = new(dut_if, 60);

        // Run the environment
        env.run();

        $display("=====================================================");
        $display("   SIMULATION COMPLETE                              ");
        $display("=====================================================\n");

        $finish;
    end

    // =========================================================================
    // Timeout watchdog — kills simulation if it hangs
    // =========================================================================
    initial begin
        #500_000;   // 500 us timeout
        $display("[%0t] [TOP] *** WATCHDOG TIMEOUT — SIMULATION KILLED ***", $time);
        $finish;
    end

endmodule : tb_top
