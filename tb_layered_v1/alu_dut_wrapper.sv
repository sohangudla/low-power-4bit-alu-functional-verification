// =============================================================================
// FILE        : alu_dut_wrapper.sv
// DESCRIPTION : Optional thin wrapper around your DUT.
//               Use this ONLY if your DUT port names do not match what
//               tb_top.sv expects (result, carry_out).
//
//               If your DUT already has ports named exactly:
//                 A, B, sel, alu_en, clk, rst_n, result, carry_out
//               then you do NOT need this file — instantiate your DUT directly
//               in tb_top.sv.
//
//               This wrapper maps the method4_alu port names:
//                 ALU_Out  → result
//                 CarryOut → carry_out
// =============================================================================

`timescale 1ns/1ps
import alu_pkg::*;

module alu_dut_wrapper (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  A,
    input  logic [3:0]  B,
    input  logic [2:0]  sel,
    input  logic        alu_en,
    output logic [3:0]  result,       // mapped from ALU_Out
    output logic        carry_out     // mapped from CarryOut
);

    // Instantiate the real DUT
    method4_alu u_dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .A        (A),
        .B        (B),
        .sel      (opcode_t'(sel)),   // cast to enum type if needed
        .alu_en   (alu_en),
        .ALU_Out  (result),
        .CarryOut (carry_out)
    );

endmodule : alu_dut_wrapper
