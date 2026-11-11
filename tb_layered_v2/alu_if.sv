// alu_if.sv
// Virtual interface that connects every TB layer to the DUT.
// All signals match method4_alu ports exactly.

`timescale 1ns/1ps
import alu_pkg::*;

interface alu_if (input logic clk);

  logic        rst_n;
  logic [3:0]  A;
  logic [3:0]  B;
  opcode_t     sel;
  logic        alu_en;
  logic [3:0]  ALU_Out;
  logic        CarryOut;

  // ---------------------------------------------------------------
  // Driver clocking block  - drive on negedge, sample 1-step after
  // ---------------------------------------------------------------
  clocking driver_cb @(posedge clk);
    default input  #1step
            output #1ns;
    output rst_n, A, B, sel, alu_en;
    input  ALU_Out, CarryOut;
  endclocking

  // ---------------------------------------------------------------
  // Monitor clocking block - sample 1-step after posedge
  // ---------------------------------------------------------------
  clocking monitor_cb @(posedge clk);
    default input #1step;
    input rst_n, A, B, sel, alu_en, ALU_Out, CarryOut;
  endclocking

  modport driver_mp  (clocking driver_cb,  input clk);
  modport monitor_mp (clocking monitor_cb, input clk);

endinterface : alu_if