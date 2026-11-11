// alu_transaction.sv
// Transaction (sequence item) — the atomic data object that flows
// between Generator → Driver → Monitor → Scoreboard.
// Each instance represents ONE ALU operation cycle.

`timescale 1ns/1ps
import alu_pkg::*;

class alu_transaction;

  // ---- stimulus fields (randomisable) ----
  rand logic [3:0]  A;
  rand logic [3:0]  B;
  rand opcode_t     sel;
  rand logic        alu_en;

  // ---- response fields (filled in by Monitor) ----
  logic [3:0]  ALU_Out;
  logic        CarryOut;

  // ---- constraints ----
  // Bias alu_en HIGH most of the time (80 %) to get useful coverage
  constraint en_bias_c  { alu_en dist { 1'b1 := 80, 1'b0 := 20 }; }

  // Cover all opcodes equally
  constraint opcode_dist_c { sel dist {
    ADD    := 1,
    SUB    := 1,
    AND_OP := 1,
    OR_OP  := 1,
    XOR_OP := 1,
    NOT_OP := 1,
    PASS_B := 1,
    PASS_A := 1
  }; }

  // ---- utility methods ----

  // Deep copy — used by Monitor to clone a stimulus txn
  function alu_transaction clone();
    alu_transaction t = new();
    t.A      = this.A;
    t.B      = this.B;
    t.sel    = this.sel;
    t.alu_en = this.alu_en;
    t.ALU_Out  = this.ALU_Out;
    t.CarryOut = this.CarryOut;
    return t;
  endfunction

  // Human-readable print
  function void print(string tag = "TXN");
    $display("[%0t] %s | A=%0h B=%0h sel=%-6s en=%0b | Out=%0h Carry=%0b",
             $time, tag,
             A, B, sel.name(), alu_en,
             ALU_Out, CarryOut);
  endfunction

endclass : alu_transaction
