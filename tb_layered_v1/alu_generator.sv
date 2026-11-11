// =============================================================================
// FILE        : alu_generator.sv
// DESCRIPTION : Generator — creates stimulus transactions and sends them to
//               the Driver via a mailbox.
//
//               Two phases:
//                 1. DIRECTED tests  — hand-crafted edge cases covering:
//                      • All 8 opcodes with zero inputs
//                      • Overflow / carry cases for ADD
//                      • Underflow / borrow cases for SUB
//                      • All-ones and all-zeros operands
//                      • alu_en = 0 (output should hold / be zero)
//                 2. RANDOM tests    — fully randomized transactions
//                      • Constrained by c_sel_dist (all opcodes covered)
// =============================================================================

class alu_generator;

    // -------------------------------------------------------------------------
    // Mailbox handle — shared with Driver
    // -------------------------------------------------------------------------
    mailbox #(alu_transaction) gen2drv;

    // -------------------------------------------------------------------------
    // Total transactions to generate (directed + random)
    // -------------------------------------------------------------------------
    int num_transactions;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(mailbox #(alu_transaction) mbx, int num = 60);
        gen2drv         = mbx;
        num_transactions = num;
    endfunction

    // -------------------------------------------------------------------------
    // send_directed() — builds and sends one hand-crafted transaction
    // -------------------------------------------------------------------------
    local task send_directed(
        input logic [3:0] a,
        input logic [3:0] b,
        input logic [2:0] s,
        input logic       en = 1'b1
    );
        alu_transaction t = new();
        t.A      = a;
        t.B      = b;
        t.sel    = s;
        t.alu_en = en;
        gen2drv.put(t);
    endtask

    // -------------------------------------------------------------------------
    // run() — main generator task called from Environment
    // -------------------------------------------------------------------------
    task run();

        $display("\n[%0t] [GEN] ========== DIRECTED TESTS START ==========", $time);

        // ----- ADD (000) -----
        send_directed(4'd0,  4'd0,  3'b000);   // 0 + 0  = 0
        send_directed(4'd5,  4'd3,  3'b000);   // 5 + 3  = 8
        send_directed(4'd9,  4'd9,  3'b000);   // 9 + 9  = 18 → carry
        send_directed(4'hF,  4'h1,  3'b000);   // 15 + 1 = 16 → carry, result=0
        send_directed(4'hF,  4'hF,  3'b000);   // 15+15  = 30 → carry

        // ----- SUB (001) -----
        send_directed(4'd7,  4'd3,  3'b001);   // 7 - 3  = 4
        send_directed(4'd0,  4'd0,  3'b001);   // 0 - 0  = 0
        send_directed(4'd2,  4'd5,  3'b001);   // 2 - 5  underflow
        send_directed(4'hF,  4'h1,  3'b001);   // 15 - 1 = 14
        send_directed(4'd0,  4'hF,  3'b001);   // 0 - 15 underflow

        // ----- AND (010) -----
        send_directed(4'hF,  4'hF,  3'b010);   // FF & FF = FF
        send_directed(4'hF,  4'h0,  3'b010);   // FF & 00 = 00
        send_directed(4'hA,  4'h5,  3'b010);   // 1010 & 0101 = 0000
        send_directed(4'hC,  4'h6,  3'b010);   // 1100 & 0110 = 0100

        // ----- OR (011) -----
        send_directed(4'hF,  4'h0,  3'b011);   // FF | 00 = FF
        send_directed(4'hA,  4'h5,  3'b011);   // 1010 | 0101 = 1111
        send_directed(4'h0,  4'h0,  3'b011);   // 00 | 00 = 00

        // ----- XOR (100) -----
        send_directed(4'hF,  4'hF,  3'b100);   // FF ^ FF = 00
        send_directed(4'hA,  4'h5,  3'b100);   // 1010 ^ 0101 = 1111
        send_directed(4'h0,  4'hF,  3'b100);   // 00 ^ FF = FF

        // ----- NOT (101) -----
        send_directed(4'hF,  4'h0,  3'b101);   // ~1111 = 0000
        send_directed(4'h0,  4'h0,  3'b101);   // ~0000 = 1111
        send_directed(4'hA,  4'h0,  3'b101);   // ~1010 = 0101
        send_directed(4'h5,  4'h0,  3'b101);   // ~0101 = 1010

        // ----- PASS_B (110) -----
        send_directed(4'h0,  4'hF,  3'b110);   // result = B = 15
        send_directed(4'hA,  4'h5,  3'b110);   // result = B = 5
        send_directed(4'hF,  4'h0,  3'b110);   // result = B = 0

        // ----- PASS_A (111) -----
        send_directed(4'hF,  4'h0,  3'b111);   // result = A = 15
        send_directed(4'h5,  4'hA,  3'b111);   // result = A = 5
        send_directed(4'h0,  4'hF,  3'b111);   // result = A = 0

        // ----- alu_en = 0 (output should be 0 or hold) -----
        send_directed(4'd7,  4'd3,  3'b000, 1'b0);  // disabled
        send_directed(4'hF,  4'hF,  3'b100, 1'b0);  // disabled

        $display("[%0t] [GEN] Directed tests: %0d transactions sent", $time, gen2drv.num());
        $display("[%0t] [GEN] ========== RANDOM TESTS START  ==========", $time);

        // ----- Random tests -----
        begin
            int rand_count = num_transactions - 32;  // remaining after directed
            alu_transaction t;
            for (int i = 0; i < rand_count; i++) begin
                t = new();
                if (!t.randomize()) begin
                    $error("[GEN] Randomization FAILED at iteration %0d", i);
                end
                gen2drv.put(t);
            end
            $display("[%0t] [GEN] Random tests: %0d transactions sent", $time, rand_count);
        end

        $display("[%0t] [GEN] ========== GENERATION COMPLETE  ==========\n", $time);

    endtask : run

endclass : alu_generator
