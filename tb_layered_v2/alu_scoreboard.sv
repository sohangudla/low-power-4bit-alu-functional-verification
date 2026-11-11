// alu_scoreboard.sv - VERBOSE version (prints every transaction to Tcl Console)

`timescale 1ns/1ps
import alu_pkg::*;

class alu_scoreboard;

  mailbox #(alu_transaction) mon2scb;

  logic [3:0] prev_A      = 4'b0;
  logic [3:0] prev_B      = 4'b0;
  opcode_t    prev_sel    = ADD;
  logic       prev_alu_en = 1'b0;
  bit         first_txn   = 1;

  logic [3:0] ref_ALU_Out  = 4'b0;
  logic       ref_CarryOut = 1'b0;

  int unsigned total_checked = 0;
  int unsigned pass_count    = 0;
  int unsigned fail_count    = 0;
  int unsigned skip_count    = 0;

  function new(mailbox #(alu_transaction) mb);
    mon2scb = mb;
  endfunction

  task run();
    alu_transaction t;
    forever begin
      mon2scb.get(t);
      check(t);
    end
  endtask

  local task check(alu_transaction t);
    logic [4:0] expected_combo;
    logic [3:0] expected_out;
    logic       expected_carry;

    if (first_txn) begin
      first_txn   = 0;
      prev_A      = t.A;
      prev_B      = t.B;
      prev_sel    = t.sel;
      prev_alu_en = t.alu_en;
      return;
    end

    expected_combo = compute_combo(prev_A, prev_B, prev_sel);

    if (prev_alu_en) begin
      if (ref_ALU_Out  != expected_combo[3:0]) ref_ALU_Out  = expected_combo[3:0];
      if (ref_CarryOut != expected_combo[4]  ) ref_CarryOut = expected_combo[4];
    end

    expected_out   = ref_ALU_Out;
    expected_carry = ref_CarryOut;

    total_checked++;
    if (!prev_alu_en) skip_count++;

    if ((t.ALU_Out === expected_out) && (t.CarryOut === expected_carry)) begin
      pass_count++;
      $display("[SCB][PASS] #%0d | A=%0h B=%0h sel=%-6s en=%0b | Exp Out=%0h Carry=%0b | Got Out=%0h Carry=%0b",
        total_checked, prev_A, prev_B, prev_sel.name(), prev_alu_en,
        expected_out, expected_carry, t.ALU_Out, t.CarryOut);
    end else begin
      fail_count++;
      $error("[SCB][FAIL] #%0d | A=%0h B=%0h sel=%-6s en=%0b | Exp Out=%0h Carry=%0b | Got Out=%0h Carry=%0b",
        total_checked, prev_A, prev_B, prev_sel.name(), prev_alu_en,
        expected_out, expected_carry, t.ALU_Out, t.CarryOut);
    end

    prev_A      = t.A;
    prev_B      = t.B;
    prev_sel    = t.sel;
    prev_alu_en = t.alu_en;
  endtask

  local function logic [4:0] compute_combo(
    logic [3:0] A, logic [3:0] B, opcode_t sel
  );
    logic [3:0] iso_A, iso_B;
    logic       is_arith;
    is_arith = (sel == ADD) || (sel == SUB);
    iso_A    = is_arith ? A : 4'b0;
    iso_B    = is_arith ? B : 4'b0;
    case (sel)
      ADD    : return ({1'b0, iso_A} + {1'b0, iso_B});
      SUB    : return ({1'b0, iso_A} - {1'b0, iso_B});
      AND_OP : return {1'b0, A & B};
      OR_OP  : return {1'b0, A | B};
      XOR_OP : return {1'b0, A ^ B};
      NOT_OP : return {1'b0, ~A};
      PASS_B : return {1'b0, B};
      PASS_A : return {1'b0, A};
      default: return 5'b0;
    endcase
  endfunction

  function void report();
    $display("");
    $display("================================================================");
    $display("  SCOREBOARD FINAL REPORT");
    $display("================================================================");
    $display("  Total transactions checked : %0d", total_checked);
    $display("  PASS                       : %0d", pass_count);
    $display("  FAIL                       : %0d", fail_count);
    $display("  Disabled (freeze-check)    : %0d", skip_count);
    $display("----------------------------------------------------------------");
    if (fail_count == 0)
      $display("  RESULT : ** ALL TESTS PASSED **");
    else
      $display("  RESULT : !! %0d FAILURES DETECTED !!", fail_count);
    $display("================================================================");
    $display("");
  endfunction

endclass : alu_scoreboard