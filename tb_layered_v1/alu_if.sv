// =============================================================================
// FILE        : alu_if.sv
// DESCRIPTION : SystemVerilog Interface for 4-bit ALU
//               Provides a clean connection between the DUT and testbench.
//               Contains two clocking blocks:
//                 - driver_cb  : testbench drives inputs (setup before posedge)
//                 - monitor_cb : testbench samples outputs (after posedge)
// =============================================================================

interface alu_if (input logic clk);

    // -------------------------------------------------------------------------
    // Signal declarations (match DUT ports exactly)
    // -------------------------------------------------------------------------
    logic [3:0] A;          // Operand A
    logic [3:0] B;          // Operand B
    logic [2:0] sel;        // Operation select (opcode)
    logic       alu_en;     // ALU enable
    logic       rst_n;      // Active-low asynchronous reset

    logic [3:0] result;     // ALU output result
    logic       carry_out;  // Carry / borrow output

    // -------------------------------------------------------------------------
    // Driver clocking block
    // Inputs are driven 1ns before rising edge (setup time)
    // -------------------------------------------------------------------------
    clocking driver_cb @(posedge clk);
        default input  #1 output #1;
        output A;
        output B;
        output sel;
        output alu_en;
        output rst_n;
    endclocking

    // -------------------------------------------------------------------------
    // Monitor clocking block
    // Outputs are sampled 1ns after rising edge (hold time)
    // -------------------------------------------------------------------------
    clocking monitor_cb @(posedge clk);
        default input  #1 output #1;
        input  A;
        input  B;
        input  sel;
        input  alu_en;
        input  rst_n;
        input  result;
        input  carry_out;
    endclocking

    // -------------------------------------------------------------------------
    // Modport definitions
    // -------------------------------------------------------------------------
    modport DRIVER  (clocking driver_cb,  input clk);
    modport MONITOR (clocking monitor_cb, input clk);

endinterface : alu_if
