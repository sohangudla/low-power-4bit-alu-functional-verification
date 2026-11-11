// method2_alu.sv
// Method 2 — Operand Isolation
// Power measured on Basys3 Artix-7: 2.408 W.
//
// Technique:
//   • Operand isolation: inputs to each functional unit (adder, logic gates)
//     are gated to 0 when that unit is NOT required by the current opcode.
//     This prevents glitches and spurious switching in inactive units,
//     which is the dominant source of dynamic power in a combinational block.
//   • Clock gating retained from Method 1.

`timescale 1ns/1ps
import alu_pkg::*;

module method2_alu (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [3:0]  A, B,
  input  opcode_t     sel,
  input  logic        alu_en,
  output logic [3:0]  ALU_Out,
  output logic        CarryOut
);

  //----------------------------------------------------------------------
  // Operand isolation: gate inputs to zero for unused units
  //----------------------------------------------------------------------
  logic [3:0] arith_A, arith_B;   // isolated inputs for add/sub unit
  logic [3:0] logic_A, logic_B;   // isolated inputs for logic unit

  logic is_arith, is_logic;

  always_comb begin
    is_arith = (sel == ADD) || (sel == SUB);
    is_logic = (sel == AND_OP) || (sel == OR_OP) ||
               (sel == XOR_OP) || (sel == NOT_OP);

    // Gate inputs — tie to zero when unit is inactive
    arith_A = is_arith ? A : 4'b0;
    arith_B = is_arith ? B : 4'b0;

    logic_A = is_logic ? A : 4'b0;
    logic_B = is_logic ? B : 4'b0;
  end

  //----------------------------------------------------------------------
  // Isolated functional units
  //----------------------------------------------------------------------
  logic [4:0] arith_out;   // {carry, result}
  logic [3:0] logic_out;

  always_comb begin
    // Arithmetic unit (sub uses B complement trick)
    if (sel == SUB)
      arith_out = {1'b0, arith_A} - {1'b0, arith_B};
    else
      arith_out = {1'b0, arith_A} + {1'b0, arith_B};
  end

  always_comb begin
    unique case (sel)
      AND_OP : logic_out = logic_A & logic_B;
      OR_OP  : logic_out = logic_A | logic_B;
      XOR_OP : logic_out = logic_A ^ logic_B;
      NOT_OP : logic_out = ~logic_A;
      default: logic_out = 4'b0;
    endcase
  end

  //----------------------------------------------------------------------
  // Output MUX + clock-gated register
  //----------------------------------------------------------------------
  logic [4:0] mux_out;

  always_comb begin
    unique case (sel)
      ADD, SUB              : mux_out = arith_out;
      AND_OP, OR_OP, XOR_OP,
      NOT_OP                : mux_out = {1'b0, logic_out};
      PASS_B                : mux_out = {1'b0, B};
      PASS_A                : mux_out = {1'b0, A};
      default               : mux_out = 5'b0;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ALU_Out  <= 4'b0;
      CarryOut <= 1'b0;
    end else if (alu_en) begin
      ALU_Out  <= mux_out[3:0];
      CarryOut <= mux_out[4];
    end
  end

endmodule
