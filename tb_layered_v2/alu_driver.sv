// alu_driver.sv
// Compatible with Vivado 2018.2 xsim
// Uses simple blocking get() - generator signals done via done flag

`timescale 1ns/1ps
import alu_pkg::*;

class alu_driver;

  virtual alu_if      vif;
  mailbox #(alu_transaction) gen2drv;
  int unsigned txns_driven = 0;

  function new(virtual alu_if vif, mailbox #(alu_transaction) mb);
    this.vif     = vif;
    this.gen2drv = mb;
  endfunction

  task run(int unsigned total_txns);
    reset_dut();
    drive_all(total_txns);
    $display("[DRV]  Done - %0d transactions driven.", txns_driven);
  endtask

  local task reset_dut();
    vif.driver_cb.rst_n  <= 1'b0;
    vif.driver_cb.alu_en <= 1'b0;
    vif.driver_cb.A      <= 4'b0;
    vif.driver_cb.B      <= 4'b0;
    vif.driver_cb.sel    <= ADD;
    repeat (3) @(vif.driver_cb);
    vif.driver_cb.rst_n  <= 1'b1;
    @(vif.driver_cb);
    $display("[DRV]  Reset released at %0t.", $time);
  endtask

  local task drive_all(int unsigned total_txns);
    alu_transaction t;
    repeat (total_txns) begin
      gen2drv.get(t);   // blocking - waits until item is available
      drive_txn(t);
    end
    // One extra cycle to flush pipeline register
    @(vif.driver_cb);
  endtask

  local task drive_txn(alu_transaction t);
    @(vif.driver_cb);
    vif.driver_cb.A      <= t.A;
    vif.driver_cb.B      <= t.B;
    vif.driver_cb.sel    <= t.sel;
    vif.driver_cb.alu_en <= t.alu_en;
    txns_driven++;
  endtask

endclass : alu_driver