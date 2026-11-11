// =============================================================================
// FILE        : alu_monitor.sv
// DESCRIPTION : Monitor — passively observes the DUT's interface on every
//               rising clock edge and builds a transaction from what it sees.
//               Sends the captured transaction to the Scoreboard via mon2scb.
//
//               The monitor NEVER drives signals. It only reads.
//               It samples inputs AND outputs so the scoreboard can do full
//               comparison (expected vs observed).
// =============================================================================

class alu_monitor;

    // -------------------------------------------------------------------------
    // Virtual interface handle (monitor modport — read-only)
    // -------------------------------------------------------------------------
    virtual alu_if.MONITOR vif;

    // -------------------------------------------------------------------------
    // Mailbox — sends captured transactions to Scoreboard
    // -------------------------------------------------------------------------
    mailbox #(alu_transaction) mon2scb;

    // -------------------------------------------------------------------------
    // Sample counter
    // -------------------------------------------------------------------------
    int sample_count;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(virtual alu_if.MONITOR vif,
                 mailbox #(alu_transaction) mbx);
        this.vif      = vif;
        this.mon2scb  = mbx;
        sample_count  = 0;
    endfunction

    // -------------------------------------------------------------------------
    // run() — samples the interface on every clock edge after reset deasserts
    // -------------------------------------------------------------------------
    task run();

        alu_transaction t;

        // Wait until reset is released
        @(posedge vif.clk iff (vif.monitor_cb.rst_n === 1'b1));
        @(vif.monitor_cb); // one more cycle for DUT to settle

        $display("[%0t] [MON] Monitor active, sampling started", $time);

        forever begin
            @(vif.monitor_cb);               // sample on every rising edge

            // Only capture when ALU is enabled
            if (vif.monitor_cb.alu_en === 1'b1) begin
                t = new();

                // Capture inputs
                t.A      = vif.monitor_cb.A;
                t.B      = vif.monitor_cb.B;
                t.sel    = vif.monitor_cb.sel;
                t.alu_en = vif.monitor_cb.alu_en;

                // Capture DUT outputs
                t.obs_result = vif.monitor_cb.result;
                t.obs_carry  = vif.monitor_cb.carry_out;

                sample_count++;
                mon2scb.put(t);             // send to scoreboard
            end
        end
    endtask : run

endclass : alu_monitor
