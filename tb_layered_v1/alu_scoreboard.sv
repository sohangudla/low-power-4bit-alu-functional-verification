// =============================================================================
// FILE        : alu_scoreboard.sv
// DESCRIPTION : Scoreboard — the self-checking heart of the testbench.
//
//               For every transaction received from the Monitor:
//                 1. Computes the EXPECTED result using a golden reference model
//                 2. Compares expected vs DUT-observed output
//                 3. Prints PASS / FAIL with full context
//                 4. Tracks pass/fail counts and prints a final summary
//
//               The reference model exactly mirrors the DUT's operation table:
//                 000 → A + B   (with carry)
//                 001 → A - B   (with borrow as carry)
//                 010 → A & B
//                 011 → A | B
//                 100 → A ^ B
//                 101 → ~A
//                 110 → B       (PASS_B)
//                 111 → A       (PASS_A)
// =============================================================================

class alu_scoreboard;

    // -------------------------------------------------------------------------
    // Mailbox — receives captured transactions from Monitor
    // -------------------------------------------------------------------------
    mailbox #(alu_transaction) mon2scb;

    // -------------------------------------------------------------------------
    // Counters
    // -------------------------------------------------------------------------
    int pass_count;
    int fail_count;
    int total_count;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(mailbox #(alu_transaction) mbx);
        mon2scb     = mbx;
        pass_count  = 0;
        fail_count  = 0;
        total_count = 0;
    endfunction

    // -------------------------------------------------------------------------
    // compute_expected() — golden reference model
    // Returns {carry_out[0], result[3:0]} packed as 5 bits
    // -------------------------------------------------------------------------
    function automatic logic [4:0] compute_expected(
        input logic [3:0] A,
        input logic [3:0] B,
        input logic [2:0] sel
    );
        logic [4:0] res;
        case (sel)
            3'b000 : res = {1'b0, A} + {1'b0, B};          // ADD
            3'b001 : res = {1'b0, A} - {1'b0, B};          // SUB
            3'b010 : res = {1'b0, A & B};                   // AND
            3'b011 : res = {1'b0, A | B};                   // OR
            3'b100 : res = {1'b0, A ^ B};                   // XOR
            3'b101 : res = {1'b0, ~A};                      // NOT
            3'b110 : res = {1'b0, B};                       // PASS_B
            3'b111 : res = {1'b0, A};                       // PASS_A
            default: res = 5'b0;
        endcase
        return res;
    endfunction

    // -------------------------------------------------------------------------
    // check() — compares one transaction and logs result
    // -------------------------------------------------------------------------
    function void check(alu_transaction t);
        logic [4:0] expected;
        string      op;
        string      status;

        total_count++;
        op = t.op_name();

        // Compute expected from golden model
        expected        = compute_expected(t.A, t.B, t.sel);
        t.exp_result    = expected[3:0];
        t.exp_carry     = expected[4];

        // Compare
        if ((t.obs_result === t.exp_result) && (t.obs_carry === t.exp_carry)) begin
            pass_count++;
            status = "PASS";
            $display("[%0t] [SCB] %s | %-6s | A=%02h B=%02h → exp=%02h(c=%0b) obs=%02h(c=%0b)",
                     $time, status, op,
                     t.A, t.B,
                     t.exp_result, t.exp_carry,
                     t.obs_result, t.obs_carry);
        end else begin
            fail_count++;
            status = "FAIL";
            $display("[%0t] [SCB] %s | %-6s | A=%02h B=%02h → exp=%02h(c=%0b) obs=%02h(c=%0b)  *** MISMATCH ***",
                     $time, status, op,
                     t.A, t.B,
                     t.exp_result, t.exp_carry,
                     t.obs_result, t.obs_carry);
        end
    endfunction

    // -------------------------------------------------------------------------
    // run() — main scoreboard task: drain mailbox and check each transaction
    // -------------------------------------------------------------------------
    task run();
        alu_transaction t;
        $display("[%0t] [SCB] Scoreboard active", $time);

        forever begin
            mon2scb.get(t);      // blocking get
            check(t);
        end
    endtask : run

    // -------------------------------------------------------------------------
    // report() — final summary printed at end of simulation
    // -------------------------------------------------------------------------
    function void report();
        $display("\n");
        $display("╔══════════════════════════════════════════════╗");
        $display("║          SCOREBOARD FINAL REPORT             ║");
        $display("╠══════════════════════════════════════════════╣");
        $display("║  Total transactions checked : %-5d          ║", total_count);
        $display("║  PASS                       : %-5d          ║", pass_count);
        $display("║  FAIL                       : %-5d          ║", fail_count);
        $display("╠══════════════════════════════════════════════╣");
        if (fail_count == 0)
            $display("║        *** ALL TESTS PASSED ***              ║");
        else
            $display("║        *** %0d TEST(S) FAILED ***             ║", fail_count);
        $display("╚══════════════════════════════════════════════╝\n");
    endfunction

endclass : alu_scoreboard
