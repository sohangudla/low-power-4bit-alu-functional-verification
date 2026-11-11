// alu_generator.sv
// Compatible with Vivado 2018.2 xsim

`timescale 1ns/1ps
import alu_pkg::*;

class alu_generator;

  mailbox #(alu_transaction) gen2drv;
  int unsigned num_rand_txns = 200;

  // Track total sent
  local int unsigned total_sent = 0;

  function new(mailbox #(alu_transaction) mb);
    gen2drv = mb;
  endfunction

  // Returns total transactions queued
  function int unsigned get_total_count();
    return total_sent;
  endfunction

  task run();
    send_directed_tests();
    send_random_tests();
    $display("[GEN]  Done - %0d total transactions queued.", total_sent);
  endtask

  // ---------------------------------------------------------------
  // Directed corner-case tests
  // ---------------------------------------------------------------
  local task send_directed_tests();

    // Disabled cycles
    send(4'h0, 4'h0, ADD,    1'b0);
    send(4'h5, 4'h3, ADD,    1'b1);

    // ADD
    send(4'h0, 4'h0, ADD,    1'b1);
    send(4'h7, 4'h8, ADD,    1'b1);
    send(4'h8, 4'h8, ADD,    1'b1);   // carry
    send(4'hF, 4'hF, ADD,    1'b1);   // carry + wrap
    send(4'hF, 4'h1, ADD,    1'b1);   // wrap to 0

    // SUB
    send(4'hF, 4'hF, SUB,    1'b1);   // = 0
    send(4'h0, 4'h1, SUB,    1'b1);   // borrow/wrap
    send(4'h5, 4'h3, SUB,    1'b1);   // = 2
    send(4'h0, 4'hF, SUB,    1'b1);   // borrow

    // Logical
    send(4'hF, 4'h0, AND_OP, 1'b1);
    send(4'hA, 4'h5, AND_OP, 1'b1);
    send(4'hA, 4'h5, OR_OP,  1'b1);
    send(4'h0, 4'h0, OR_OP,  1'b1);
    send(4'hF, 4'hF, XOR_OP, 1'b1);
    send(4'hA, 4'h5, XOR_OP, 1'b1);
    send(4'h0, 4'h0, NOT_OP, 1'b1);
    send(4'hF, 4'h0, NOT_OP, 1'b1);

    // Pass-through
    send(4'h7, 4'h3, PASS_A, 1'b1);
    send(4'h7, 4'h3, PASS_B, 1'b1);

    // Glitch-free: repeat same inputs
    send(4'h5, 4'h3, ADD,    1'b1);
    send(4'h5, 4'h3, ADD,    1'b1);

    // Freeze: disable between valid ops
    send(4'h9, 4'h6, XOR_OP, 1'b1);
    send(4'h1, 4'h2, ADD,    1'b0);
    send(4'h1, 4'h2, ADD,    1'b0);
    send(4'h9, 4'h6, XOR_OP, 1'b1);
  endtask

  // ---------------------------------------------------------------
  // Random tests
  // ---------------------------------------------------------------
  local task send_random_tests();
    alu_transaction t;
    repeat (num_rand_txns) begin
      t = new();
      if (!t.randomize())
        $error("[GEN]  Randomization failed!");
      gen2drv.put(t);
      total_sent++;
    end
  endtask

  local task send(
    logic [3:0] a, b,
    opcode_t    op,
    logic       en
  );
    alu_transaction t = new();
    t.A      = a;
    t.B      = b;
    t.sel    = op;
    t.alu_en = en;
    gen2drv.put(t);
    total_sent++;
  endtask

endclass : alu_generator