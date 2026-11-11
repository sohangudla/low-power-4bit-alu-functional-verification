// =============================================================================
// FILE        : alu_transaction.sv
// DESCRIPTION : Transaction class — the fundamental data object that flows
//               through the verification environment.
//               Each transaction represents ONE ALU operation:
//                 - stimulus fields  : A, B, sel, alu_en
//                 - expected fields  : exp_result, exp_carry  (set by scoreboard)
//                 - observed fields  : obs_result, obs_carry  (set by monitor)
// =============================================================================

class alu_transaction;

    // -------------------------------------------------------------------------
    // Stimulus fields (randomizable)
    // -------------------------------------------------------------------------
    rand logic [3:0] A;
    rand logic [3:0] B;
    rand logic [2:0] sel;
    rand logic       alu_en;

    // -------------------------------------------------------------------------
    // Expected output (computed by scoreboard)
    // -------------------------------------------------------------------------
    logic [3:0] exp_result;
    logic       exp_carry;

    // -------------------------------------------------------------------------
    // Observed output (captured by monitor from DUT)
    // -------------------------------------------------------------------------
    logic [3:0] obs_result;
    logic       obs_carry;

    // -------------------------------------------------------------------------
    // Constraint : alu_en is always 1 during normal test cases
    //              (a separate directed test will check alu_en = 0 behaviour)
    // -------------------------------------------------------------------------
    constraint c_alu_en { alu_en == 1'b1; }

    // -------------------------------------------------------------------------
    // Constraint : ensure all 8 opcodes get tested (soft, can be overridden)
    // -------------------------------------------------------------------------
    constraint c_sel_dist {
        sel dist { 3'b000 := 15,   // ADD
                   3'b001 := 15,   // SUB
                   3'b010 := 10,   // AND
                   3'b011 := 10,   // OR
                   3'b100 := 10,   // XOR
                   3'b101 := 10,   // NOT
                   3'b110 := 10,   // Transfer B
                   3'b111 := 10 }; // Transfer A
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new();
        A       = 4'b0;
        B       = 4'b0;
        sel     = 3'b0;
        alu_en  = 1'b1;
    endfunction

    // -------------------------------------------------------------------------
    // Deep copy — used when passing transactions between components
    // -------------------------------------------------------------------------
    function alu_transaction copy();
        alu_transaction t = new();
        t.A          = this.A;
        t.B          = this.B;
        t.sel        = this.sel;
        t.alu_en     = this.alu_en;
        t.exp_result = this.exp_result;
        t.exp_carry  = this.exp_carry;
        t.obs_result = this.obs_result;
        t.obs_carry  = this.obs_carry;
        return t;
    endfunction

    // -------------------------------------------------------------------------
    // display() — prints transaction contents to console
    // -------------------------------------------------------------------------
    function void display(string tag = "TXN");
        $display("[%0t] [%s] A=%0d B=%0d sel=%03b alu_en=%0b | exp=%0d(c=%0b) obs=%0d(c=%0b)",
                 $time, tag, A, B, sel, alu_en,
                 exp_result, exp_carry,
                 obs_result, obs_carry);
    endfunction

    // -------------------------------------------------------------------------
    // op_name() — returns human-readable opcode string
    // -------------------------------------------------------------------------
    function string op_name();
        case (sel)
            3'b000 : return "ADD";
            3'b001 : return "SUB";
            3'b010 : return "AND";
            3'b011 : return "OR ";
            3'b100 : return "XOR";
            3'b101 : return "NOT";
            3'b110 : return "PASS_B";
            3'b111 : return "PASS_A";
            default: return "???";
        endcase
    endfunction

endclass : alu_transaction
