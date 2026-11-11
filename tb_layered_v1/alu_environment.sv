// =============================================================================
// FILE        : alu_environment.sv
// DESCRIPTION : Environment — the top-level container that:
//                 1. Creates all verification components
//                 2. Creates the shared mailboxes
//                 3. Connects components to each other and to the interface
//                 4. Launches all components in parallel via fork-join
//                 5. Waits for the generator to finish, then drains the pipe
//                    and calls the scoreboard final report
//
//               Data flow:
//                 Generator → [gen2drv mbx] → Driver → DUT
//                                              DUT   → Monitor → [mon2scb mbx] → Scoreboard
// =============================================================================

`include "alu_transaction.sv"
`include "alu_generator.sv"
`include "alu_driver.sv"
`include "alu_monitor.sv"
`include "alu_scoreboard.sv"

class alu_environment;

    // -------------------------------------------------------------------------
    // Component handles
    // -------------------------------------------------------------------------
    alu_generator   gen;
    alu_driver      drv;
    alu_monitor     mon;
    alu_scoreboard  scb;

    // -------------------------------------------------------------------------
    // Mailboxes for inter-component communication
    // -------------------------------------------------------------------------
    mailbox #(alu_transaction) gen2drv;   // Generator  → Driver
    mailbox #(alu_transaction) mon2scb;   // Monitor    → Scoreboard

    // -------------------------------------------------------------------------
    // Virtual interface handle (passed from top-level testbench)
    // -------------------------------------------------------------------------
    virtual alu_if vif;

    // -------------------------------------------------------------------------
    // Number of transactions to generate
    // -------------------------------------------------------------------------
    int num_transactions;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(virtual alu_if vif, int num = 60);
        this.vif             = vif;
        this.num_transactions = num;

        // Create mailboxes (unbounded)
        gen2drv = new();
        mon2scb = new();

        // Create components and wire them up
        gen = new(gen2drv, num_transactions);
        drv = new(vif.DRIVER, gen2drv);
        mon = new(vif.MONITOR, mon2scb);
        scb = new(mon2scb);
    endfunction

    // -------------------------------------------------------------------------
    // run() — launches all components and manages simulation flow
    // -------------------------------------------------------------------------
    task run();
        $display("\n[%0t] [ENV] ====== SIMULATION START ======\n", $time);

        // Launch all components concurrently
        fork
            gen.run();   // generates all transactions then returns
            drv.run();   // runs forever (driven by mailbox)
            mon.run();   // runs forever (samples every clock)
            scb.run();   // runs forever (checks every sample)
        join_none

        // Wait for generator to finish producing all transactions
        wait (gen2drv.num() == 0 && drv.txn_count >= num_transactions);

        // Allow pipeline to drain (extra cycles for DUT output to propagate)
        #200;

        // Stop the forever loops
        disable fork;

        // Print final summary
        scb.report();

        $display("[%0t] [ENV] ====== SIMULATION END ======\n", $time);
    endtask : run

endclass : alu_environment
