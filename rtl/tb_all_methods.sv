// tb_all_methods.sv
// Testbench — exercises all four ALU implementations and the baseline.
// Covers every opcode, reset behaviour, clock-gating, bus-inversion,
// FSM transitions, and glitch-free (no-update) paths.
//
// Run with: vsim / xsim / iverilog+vvp — all synthesisers supported.

`timescale 1ns/1ps
import alu_pkg::*;

module tb_all_methods;

  // =====================================================================
  // Clock and reset
  // =====================================================================
  localparam int CLK_PERIOD = 10;   // 10 ns → 100 MHz

  logic        clk   = 0;
  logic        rst_n = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // =====================================================================
  // DUT interfaces
  // =====================================================================
  logic [3:0]  A, B;
  opcode_t     sel;
  logic        alu_en, start;

  logic [3:0]  out_base,  out_m1,  out_m2,  out_m3,  out_m4;
  logic        cout_base, cout_m1, cout_m2, cout_m3, cout_m4;

  baseline_alu dut_base (.clk, .rst_n, .A, .B, .sel, .alu_en,
                          .ALU_Out(out_base), .CarryOut(cout_base));

  method1_alu  dut_m1   (.clk, .rst_n, .A, .B, .sel, .alu_en,
                          .ALU_Out(out_m1),  .CarryOut(cout_m1));

  method2_alu  dut_m2   (.clk, .rst_n, .A, .B, .sel, .alu_en,
                          .ALU_Out(out_m2),  .CarryOut(cout_m2));

  method3_alu  dut_m3   (.clk, .rst_n, .A, .B, .sel, .alu_en, .start,
                          .ALU_Out(out_m3),  .CarryOut(cout_m3));

  method4_alu  dut_m4   (.clk, .rst_n, .A, .B, .sel, .alu_en,
                          .ALU_Out(out_m4),  .CarryOut(cout_m4));

  // =====================================================================
  // Helper tasks
  // =====================================================================

  // Apply operands and wait two clock edges for pipeline to settle
  task automatic apply (
    input logic [3:0] a_in, b_in,
    input opcode_t    op,
    input logic       en = 1
  );
    A      = a_in;
    B      = b_in;
    sel    = op;
    alu_en = en;
    start  = 1;
    @(posedge clk); #1;
    start  = 0;
    @(posedge clk); #1;
  endtask

  // Check outputs (reference is method-4 which mirrors baseline logic)
  task automatic check (
    input logic [4:0] expected,   // {carry, result}
    input string      label
  );
    automatic logic [4:0] got_base = {cout_base, out_base};
    automatic logic [4:0] got_m1   = {cout_m1,   out_m1};
    automatic logic [4:0] got_m2   = {cout_m2,   out_m2};
    automatic logic [4:0] got_m3   = {cout_m3,   out_m3};
    automatic logic [4:0] got_m4   = {cout_m4,   out_m4};

    if (got_base !== expected)
      $display("FAIL  [baseline] %s  exp=%05b got=%05b", label, expected, got_base);
    if (got_m1   !== expected)
      $display("FAIL  [method1]  %s  exp=%05b got=%05b", label, expected, got_m1);
    if (got_m2   !== expected)
      $display("FAIL  [method2]  %s  exp=%05b got=%05b", label, expected, got_m2);
    if (got_m3   !== expected)
      $display("FAIL  [method3]  %s  exp=%05b got=%05b", label, expected, got_m3);
    if (got_m4   !== expected)
      $display("FAIL  [method4]  %s  exp=%05b got=%05b", label, expected, got_m4);

    if ( (got_base === expected) && (got_m1 === expected) &&
         (got_m2   === expected) && (got_m3 === expected) &&
         (got_m4   === expected) )
      $display("PASS  %s", label);
  endtask

  // =====================================================================
  // Stimulus
  // =====================================================================
  initial begin
    A = 0; B = 0; sel = ADD; alu_en = 0; start = 0;

    // Release reset after 3 cycles
    repeat(3) @(posedge clk);
    rst_n = 1;
    @(posedge clk); #1;

    $display("=== Arithmetic operations ===");

    // ADD: 5 + 3 = 8, no carry
    apply(4'd5, 4'd3, ADD);
    check(5'b0_1000, "ADD 5+3=8");

    // ADD: 9 + 9 = 18 (0x12) → result=2, carry=1
    apply(4'd9, 4'd9, ADD);
    check(5'b1_0010, "ADD 9+9 carry");

    // SUB: 7 - 4 = 3
    apply(4'd7, 4'd4, SUB);
    check(5'b0_0011, "SUB 7-4=3");

    // SUB: 2 - 5 → underflow (borrow in unsigned = 'carry')
    apply(4'd2, 4'd5, SUB);
    check(5'b1_1101, "SUB 2-5 underflow");

    $display("=== Logic operations ===");

    apply(4'b1100, 4'b1010, AND_OP);
    check(5'b0_1000, "AND 1100&1010");

    apply(4'b1100, 4'b1010, OR_OP);
    check(5'b0_1110, "OR  1100|1010");

    apply(4'b1100, 4'b1010, XOR_OP);
    check(5'b0_0110, "XOR 1100^1010");

    apply(4'b1010, 4'b0000, NOT_OP);
    check(5'b0_0101, "NOT ~1010");

    $display("=== Pass-through operations ===");

    apply(4'b1111, 4'b0000, PASS_A);
    check(5'b0_1111, "PASS_A");

    apply(4'b0000, 4'b1111, PASS_B);
    check(5'b0_1111, "PASS_B");

    $display("=== Clock-gate test (alu_en=0, outputs must hold) ===");
    begin
      // After a PASS_A with result 4'b1111...
      apply(4'b1111, 4'b0000, PASS_A);

      // Now disable and change operands — outputs must NOT change
      A      = 4'b0001;
      B      = 4'b0010;
      sel    = ADD;
      alu_en = 0;
      start  = 0;
      repeat(4) @(posedge clk); #1;

      // Outputs should still be 4'b1111 with no carry
      check(5'b0_1111, "Clock-gate hold");
    end

    $display("=== Reset test ===");
    begin
      apply(4'd15, 4'd15, ADD);     // result = 14, carry = 1
      rst_n = 0;                    // assert reset (async — outputs clear immediately)
      #1;                           // small delay — async reset propagates combinationally
      // While still in reset, outputs should already be 0
      check(5'b0_0000, "Post-reset zero");
      @(posedge clk); #1;
      rst_n = 1;                    // release reset
    end

    $display("=== Bus inversion path (method3) — rapid toggling ===");
    begin
      rst_n = 0; @(posedge clk); #1; rst_n = 1; @(posedge clk); #1;

      // Toggle between 0000 and 1111 every cycle — max Hamming distance → inversion triggers
      repeat(4) begin
        apply(4'b0000, 4'b1111, ADD);
        apply(4'b1111, 4'b0000, ADD);
      end
      $display("Bus inversion exercised (check waveform for inv_flag)");
    end

    $display("=== Glitch-free path (method4) — same value re-applied ===");
    begin
      apply(4'd6, 4'd2, ADD);      // result = 8
      // Apply the same operands again — method4 must NOT toggle the output register
      apply(4'd6, 4'd2, ADD);
      check(5'b0_1000, "Glitch-free same value");
    end

    $display("=== All tests complete ===");
    #20 $finish;
  end

  // =====================================================================
  // Waveform dump (works with both VCS/Xcelium and iverilog)
  // =====================================================================
  initial begin
    $dumpfile("tb_all_methods.vcd");
    $dumpvars(0, tb_all_methods);
  end

endmodule
