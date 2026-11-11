// alu_monitor.sv
// Monitor - passively observes the DUT interface every clock cycle.
// Captures BOTH stimulus and response into a transaction object and
// forwards it to the Scoreboard via mailbox.
// The monitor is purely observational - it never drives any signal.

`timescale 1ns/1ps
import alu_pkg::*;

class alu_monitor;

  // Virtual interface handle (assigned by Environment)
  virtual alu_if vif;

  // Mailbox to Scoreboard
  mailbox #(alu_transaction) mon2scb;

  // Statistics
  int unsigned txns_observed = 0;

  // Constructor
  function new(
    virtual alu_if             vif,
    mailbox #(alu_transaction)  mb
  );
    this.vif     = vif;
    this.mon2scb = mb;
  endfunction

  // ---------------------------------------------------------------
  // Main monitor task - runs until simulation ends ($finish)
  // ---------------------------------------------------------------
  task run();
    // Wait until reset is released before sampling
    @(posedge vif.rst_n);
    @(vif.monitor_cb);  // one more cycle settle

    forever begin
      @(vif.monitor_cb);
      sample_and_forward();
    end
  endtask

  local task sample_and_forward();
    alu_transaction t = new();

    // Stimulus (what was driven this cycle)
    t.A      = vif.monitor_cb.A;
    t.B      = vif.monitor_cb.B;
    t.sel    = vif.monitor_cb.sel;
    t.alu_en = vif.monitor_cb.alu_en;

    // Response (DUT output)
    t.ALU_Out  = vif.monitor_cb.ALU_Out;
    t.CarryOut = vif.monitor_cb.CarryOut;

    mon2scb.put(t);
    txns_observed++;
  endtask

endclass : alu_monitor