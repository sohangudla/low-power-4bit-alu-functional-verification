// alu_pkg.sv  —  shared types and opcodes
package alu_pkg;

  typedef enum logic [2:0] {
    ADD   = 3'b000,
    SUB   = 3'b001,
    AND_OP= 3'b010,
    OR_OP = 3'b011,
    XOR_OP= 3'b100,
    NOT_OP= 3'b101,
    PASS_B= 3'b110,
    PASS_A= 3'b111
  } opcode_t;

endpackage
