// alu_environment.sv
// Compatible with Vivado 2018.2 xsim
// Generator runs first, returns count, driver uses that count.

`timescale 1ns/1ps
import alu_pkg::*;

class alu_environment;

  alu_generator  gen;
  alu_driver     drv;
  alu_monitor    mon;
  alu_scoreboard scb;

  mailbox #(alu_transaction) gen2drv;
  mailbox #(alu_transaction) mon2scb;

  virtual alu_if vif;

  int unsigned total_txns;

  function new(virtual alu_if vif);
    this.vif = vif;
    gen2drv  = new();
    mon2scb  = new();
    gen      = new(gen2drv);
    drv      = new(vif, gen2drv);
    mon      = new(vif, mon2scb);
    scb      = new(mon2scb);
  endfunction

  function void set_rand_count(int unsigned n);
    gen.num_rand_txns = n;
  endfunction

  task run();
    $display("[ENV]  Simulation start.");

    // Phase 1 - generator fills mailbox completely (purely functional,
    // no clock edges needed). Returns the exact number of txns queued.
    gen.run();
    total_txns = gen.get_total_count();
    $display("[ENV]  Mailbox filled - %0d transactions queued.", total_txns);

    // Phase 2 - drive, monitor and check in parallel
    fork
      drv.run(total_txns);   // drives exactly total_txns then exits
      mon.run();             // runs forever, killed after drv finishes
      scb.run();             // runs forever, killed after drv finishes
    join_any

    // Allow a few extra cycles for pipeline flush and last monitor sample
    repeat (5) @(posedge vif.clk);

    disable fork;

    $display("[ENV]  Driver done. Mon observed %0d txns.", mon.txns_observed);
    scb.report();
    $display("[ENV]  Simulation end.");
  endtask

endclass : alu_environment