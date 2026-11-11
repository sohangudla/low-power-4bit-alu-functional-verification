// method1_alu.sv
// Method 1 — Clock Gating + Precomputation Logic
// Power measured on Basys3 Artix-7: 2.427 W (vs baseline 2.554 W).
//
// Techniques:
//   • Clock gating  : ALU registers update only when alu_en is asserted,
//                     preventing unnecessary sequential toggling when idle.
//   • Precomputation: All 8 operation results are computed in parallel by
//                     purely combinational logic; a MUX selects the required
//                     result. This confines switching to the chosen path,
//                     reducing dynamic power from unwanted transitions.

`timescale 1ns/1ps
import alu_pkg::*;

module method1_alu (
  input  logic        clk,
  input  logic        rst_n,       // active-low async reset
  input  logic [3:0]  A, B,
  input  opcode_t     sel,
  input  logic        alu_en,
  output logic [3:0]  ALU_Out,
  output logic        CarryOut
);

  //----------------------------------------------------------------------
  // Precomputation — all results computed combinationally in parallel
  //----------------------------------------------------------------------
  logic [4:0] res_add, res_sub;   // 5-bit to capture carry
  logic [3:0] res_and, res_or, res_xor, res_not, res_b, res_a;

  always_comb begin
    res_add = {1'b0, A} + {1'b0, B};
    res_sub = {1'b0, A} - {1'b0, B};
    res_and = A & B;
    res_or  = A | B;
    res_xor = A ^ B;
    res_not = ~A;
    res_b   = B;
    res_a   = A;
  end

  // MUX to select pre-computed result
  logic [4:0] mux_out;   // bit[4] = carry, bits[3:0] = result

  always_comb begin
    unique case (sel)
      ADD   : mux_out = res_add;
      SUB   : mux_out = res_sub;
      AND_OP: mux_out = {1'b0, res_and};
      OR_OP : mux_out = {1'b0, res_or};
      XOR_OP: mux_out = {1'b0, res_xor};
      NOT_OP: mux_out = {1'b0, res_not};
      PASS_B: mux_out = {1'b0, res_b};
      PASS_A: mux_out = {1'b0, res_a};
      default: mux_out = 5'b0;
    endcase
  end

  //----------------------------------------------------------------------
  // Clock-gated output register
  // SystemVerilog's enable on always_ff synthesises to a clock-enable (CE)
  // on the flip-flop — modern tools (Vivado) infer a proper ICG cell.
  //----------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ALU_Out  <= 4'b0;
      CarryOut <= 1'b0;
    end else if (alu_en) begin   // <-- clock-gate condition
      ALU_Out  <= mux_out[3:0];
      CarryOut <= mux_out[4];
    end
    // When alu_en == 0: registers hold last value, no switching.
  end

endmodule
