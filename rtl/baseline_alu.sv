// baseline_alu.sv
// Baseline 4-bit ALU — no power optimisations.
// Reference design; measured power on Basys3 Artix-7: 2.554 W.

`timescale 1ns/1ps
import alu_pkg::*;

module baseline_alu (
  input  logic        clk,
  input  logic        rst_n,       // active-low async reset
  input  logic [3:0]  A, B,
  input  opcode_t     sel,
  input  logic        alu_en,
  output logic [3:0]  ALU_Out,
  output logic        CarryOut
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ALU_Out  <= 4'b0;
      CarryOut <= 1'b0;
    end else if (alu_en) begin
      case (sel)
        ADD   : {CarryOut, ALU_Out} <= {1'b0, A} + {1'b0, B};
        SUB   : {CarryOut, ALU_Out} <= {1'b0, A} - {1'b0, B};
        AND_OP: begin ALU_Out <= A & B;  CarryOut <= 1'b0; end
        OR_OP : begin ALU_Out <= A | B;  CarryOut <= 1'b0; end
        XOR_OP: begin ALU_Out <= A ^ B;  CarryOut <= 1'b0; end
        NOT_OP: begin ALU_Out <= ~A;     CarryOut <= 1'b0; end
        PASS_B: begin ALU_Out <= B;      CarryOut <= 1'b0; end
        PASS_A: begin ALU_Out <= A;      CarryOut <= 1'b0; end
        default: begin ALU_Out <= 4'b0;  CarryOut <= 1'b0; end
      endcase
    end
  end

endmodule
