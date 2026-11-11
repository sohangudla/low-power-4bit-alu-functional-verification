// =============================================================================
// FILE        : alu_driver.sv
// DESCRIPTION : Driver — reads transactions from the gen2drv mailbox and
//               drives them onto the DUT's interface using the driver clocking
//               block. All drives are synchronised to the rising clock edge.
//
//               Protocol:
//                 - Wait for posedge clk (via clocking block)
//                 - Apply A, B, sel, alu_en
//                 - Hold for one cycle so DUT can register the inputs
//                 - Deassert alu_en between transactions (optional idle gap)
// =============================================================================

class alu_driver;

    // -------------------------------------------------------------------------
    // Virtual interface handle (connected to actual interface in environment)
    // -------------------------------------------------------------------------
    virtual alu_if.DRIVER vif;

    // -------------------------------------------------------------------------
    // Mailbox — receives transactions from Generator
    // -------------------------------------------------------------------------
    mailbox #(alu_transaction) gen2drv;

    // -------------------------------------------------------------------------
    // Transaction counter (for logging)
    // -------------------------------------------------------------------------
    int txn_count;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(virtual alu_if.DRIVER vif,
                 mailbox #(alu_transaction) mbx);
        this.vif     = vif;
        this.gen2drv = mbx;
        txn_count    = 0;
    endfunction

    // -------------------------------------------------------------------------
    // reset_dut() — drives rst_n low for 3 cycles to initialise the DUT
    // -------------------------------------------------------------------------
    task reset_dut();
        $display("[%0t] [DRV] Asserting reset (rst_n = 0)...", $time);
        vif.driver_cb.rst_n   <= 1'b0;
        vif.driver_cb.alu_en  <= 1'b0;
        vif.driver_cb.A       <= 4'b0;
        vif.driver_cb.B       <= 4'b0;
        vif.driver_cb.sel     <= 3'b0;
        repeat(3) @(vif.driver_cb);
        vif.driver_cb.rst_n   <= 1'b1;
        @(vif.driver_cb);
        $display("[%0t] [DRV] Reset deasserted (rst_n = 1)", $time);
    endtask

    // -------------------------------------------------------------------------
    // drive_txn() — applies one transaction to the interface
    // -------------------------------------------------------------------------
    task drive_txn(alu_transaction t);
        @(vif.driver_cb);                      // wait for clock edge
        vif.driver_cb.A      <= t.A;
        vif.driver_cb.B      <= t.B;
        vif.driver_cb.sel    <= t.sel;
        vif.driver_cb.alu_en <= t.alu_en;
        @(vif.driver_cb);                      // hold for one cycle
        txn_count++;
    endtask

    // -------------------------------------------------------------------------
    // run() — main driver task: drain mailbox until empty
    // -------------------------------------------------------------------------
    task run();
        alu_transaction t;

        reset_dut();

        $display("[%0t] [DRV] Starting to drive transactions...", $time);

        forever begin
            gen2drv.get(t);                    // blocking get from mailbox
            drive_txn(t);

            if (txn_count % 20 == 0)
                $display("[%0t] [DRV] %0d transactions driven so far", $time, txn_count);
        end
    endtask : run

endclass : alu_driver
