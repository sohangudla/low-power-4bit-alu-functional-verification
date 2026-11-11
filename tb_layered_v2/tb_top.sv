// tb_top.sv
// Top-level testbench with `include statements.
// Only 4 files needed in Vivado Sources:
//   1. alu_pkg.sv
//   2. alu_if.sv
//   3. method4_alu.sv
//   4. tb_top.sv  (includes all 6 class files internally)

`timescale 1ns/1ps
import alu_pkg::*;

`include "alu_transaction.sv"
`include "alu_generator.sv"
`include "alu_driver.sv"
`include "alu_monitor.sv"
`include "alu_scoreboard.sv"
`include "alu_environment.sv"

module tb_top;

  // ---------------------------------------------------------------
  // Clock - 10 ns period (100 MHz)
  // ---------------------------------------------------------------
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------
  alu_if dut_if (.clk(clk));

  // ---------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------
  method4_alu DUT (
    .clk     (dut_if.clk),
    .rst_n   (dut_if.rst_n),
    .A       (dut_if.A),
    .B       (dut_if.B),
    .sel     (dut_if.sel),
    .alu_en  (dut_if.alu_en),
    .ALU_Out (dut_if.ALU_Out),
    .CarryOut(dut_if.CarryOut)
  );

  // ---------------------------------------------------------------
  // Environment
  // ---------------------------------------------------------------
  alu_environment env;

  initial begin
    env = new(dut_if);
    env.set_rand_count(200);
    env.run();
    $finish;
  end

  // ---------------------------------------------------------------
  // Timeout watchdog
  // ---------------------------------------------------------------
  initial begin
    #500_000;
    $error("[TOP]  TIMEOUT - simulation exceeded 500 us.");
    $finish;
  end

endmodule : tb_top