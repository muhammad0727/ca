`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Lab 6 - self-checking testbench for ALU.v
//
// Every vector is held for 10 ns so it is easy to read in the waveform.
// Whole run is ~720 ns, so it finishes inside Vivado's default 1000 ns run.
// Tip: in the waveform window set the radix of "op_name" to ASCII to see the
// name of the operation being tested.
//////////////////////////////////////////////////////////////////////////////////


module ALU_tb;

    // same codes as ALU.v
    localparam ALU_AND = 4'b0000;
    localparam ALU_OR  = 4'b0001;
    localparam ALU_ADD = 4'b0010;
    localparam ALU_XOR = 4'b0011;
    localparam ALU_SLL = 4'b0100;
    localparam ALU_SRL = 4'b0101;
    localparam ALU_SUB = 4'b0110;

    reg  [31:0] A          = 32'd0;
    reg  [31:0] B          = 32'd0;
    reg  [3:0]  ALUControl = 4'd0;
    wire [31:0] ALUResult;
    wire        Zero;

    reg  [31:0] op_name    = "----";   // 4 ASCII characters, for the waveform only

    integer pass_count = 0;
    integer fail_count = 0;
    integer seed       = 2026;
    integer i;

    reg  [3:0]  rand_ctrl;
    reg  [31:0] rand_a;
    reg  [31:0] rand_b;
    reg  [31:0] rand_expected;

    ALU dut (
        .A          (A),
        .B          (B),
        .ALUControl (ALUControl),
        .ALUResult  (ALUResult),
        .Zero       (Zero)
    );

    // ---- apply one vector, wait, compare against the expected values ----
    task check;
        input [31:0] name;
        input [3:0]  ctrl;
        input [31:0] a;
        input [31:0] b;
        input [31:0] exp_result;
        input        exp_zero;
        begin
            op_name    = name;
            ALUControl = ctrl;
            A          = a;
            B          = b;
            #10;
            if (ALUResult === exp_result && Zero === exp_zero) begin
                pass_count = pass_count + 1;
                $display("PASS  %s ctrl=%b  A=%h  B=%h  ->  ALUResult=%h  Zero=%b",
                         name, ctrl, a, b, ALUResult, Zero);
            end
            else begin
                fail_count = fail_count + 1;
                $display("FAIL  %s ctrl=%b  A=%h  B=%h  ->  ALUResult=%h  Zero=%b   (expected %h  Zero=%b)",
                         name, ctrl, a, b, ALUResult, Zero, exp_result, exp_zero);
            end
        end
    endtask

    // ---- reference model for the random tests ----
    // Written with the plain Verilog operators (SUB as a - b), so it does not
    // share the A + ~B + 1 structure used inside the ALU.
    function [31:0] model;
        input [3:0]  ctrl;
        input [31:0] a;
        input [31:0] b;
        begin
            case (ctrl)
                ALU_AND : model = a & b;
                ALU_OR  : model = a | b;
                ALU_ADD : model = a + b;
                ALU_XOR : model = a ^ b;
                ALU_SLL : model = a << b[4:0];
                ALU_SRL : model = a >> b[4:0];
                ALU_SUB : model = a - b;
                default : model = 32'd0;
            endcase
        end
    endfunction

    function [31:0] op_label;
        input [3:0] ctrl;
        begin
            case (ctrl)
                ALU_AND : op_label = "AND ";
                ALU_OR  : op_label = "OR  ";
                ALU_ADD : op_label = "ADD ";
                ALU_XOR : op_label = "XOR ";
                ALU_SLL : op_label = "SLL ";
                ALU_SRL : op_label = "SRL ";
                ALU_SUB : op_label = "SUB ";
                default : op_label = "----";
            endcase
        end
    endfunction

    initial begin
        $dumpfile("ALU_tb.vcd");     // for GTKWave / EDA Playground; Vivado shows its own waveform
        $dumpvars(0, ALU_tb);

        #10;

        // ---- 1) the lab's fixed operands A = 0x10101010, B = 0x01010101 ----
        check("ADD ", ALU_ADD, 32'h10101010, 32'h01010101, 32'h11111111, 1'b0);
        check("SUB ", ALU_SUB, 32'h10101010, 32'h01010101, 32'h0F0F0F0F, 1'b0);
        check("SLL ", ALU_SLL, 32'h10101010, 32'h01010101, 32'h20202020, 1'b0); // shamt = B[4:0] = 1
        check("SRL ", ALU_SRL, 32'h10101010, 32'h01010101, 32'h08080808, 1'b0);
        check("AND ", ALU_AND, 32'h10101010, 32'h01010101, 32'h00000000, 1'b1); // no common 1 bits
        check("OR  ", ALU_OR , 32'h10101010, 32'h01010101, 32'h11111111, 1'b0);
        check("XOR ", ALU_XOR, 32'h10101010, 32'h01010101, 32'h11111111, 1'b0);
        check("BEQ ", ALU_SUB, 32'h10101010, 32'h01010101, 32'h0F0F0F0F, 1'b0); // A != B -> not taken
        check("BEQ ", ALU_SUB, 32'h10101010, 32'h10101010, 32'h00000000, 1'b1); // A == B -> taken

        // ---- 2) ADD: carries, carry out and overflow wrap-around ----
        check("ADD ", ALU_ADD, 32'h00000000, 32'h00000000, 32'h00000000, 1'b1);
        check("ADD ", ALU_ADD, 32'hFFFFFFFF, 32'h00000001, 32'h00000000, 1'b1); // carry out is dropped
        check("ADD ", ALU_ADD, 32'h7FFFFFFF, 32'h00000001, 32'h80000000, 1'b0); // signed overflow wraps
        check("ADD ", ALU_ADD, 32'h12345678, 32'h9ABCDEF0, 32'hACF13568, 1'b0);

        // ---- 3) SUB ----
        check("SUB ", ALU_SUB, 32'h00000005, 32'h00000003, 32'h00000002, 1'b0);
        check("SUB ", ALU_SUB, 32'h00000003, 32'h00000005, 32'hFFFFFFFE, 1'b0); // -2
        check("SUB ", ALU_SUB, 32'h00000000, 32'h00000001, 32'hFFFFFFFF, 1'b0); // borrow through every bit
        check("SUB ", ALU_SUB, 32'h80000000, 32'h00000001, 32'h7FFFFFFF, 1'b0);
        check("SUB ", ALU_SUB, 32'h12345678, 32'h12345678, 32'h00000000, 1'b1);

        // ---- 4) logic ----
        check("AND ", ALU_AND, 32'hFFFFFFFF, 32'h12345678, 32'h12345678, 1'b0);
        check("AND ", ALU_AND, 32'hDEADBEEF, 32'hFFFF0000, 32'hDEAD0000, 1'b0);
        check("AND ", ALU_AND, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h00000000, 1'b1);
        check("OR  ", ALU_OR , 32'h12340000, 32'h00005678, 32'h12345678, 1'b0);
        check("OR  ", ALU_OR , 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, 1'b0);
        check("OR  ", ALU_OR , 32'h00000000, 32'h00000000, 32'h00000000, 1'b1);
        check("XOR ", ALU_XOR, 32'hAAAAAAAA, 32'h55555555, 32'hFFFFFFFF, 1'b0);
        check("XOR ", ALU_XOR, 32'hDEADBEEF, 32'hFFFFFFFF, 32'h21524110, 1'b0); // XOR with all 1s = NOT
        check("XOR ", ALU_XOR, 32'hCAFEF00D, 32'hCAFEF00D, 32'h00000000, 1'b1); // x ^ x = 0

        // ---- 5) shifts: only B[4:0] is used as the shift amount ----
        check("SLL ", ALU_SLL, 32'h00000001, 32'h00000000, 32'h00000001, 1'b0); // shift by 0
        check("SLL ", ALU_SLL, 32'h00000001, 32'h0000001F, 32'h80000000, 1'b0); // shift by 31
        check("SLL ", ALU_SLL, 32'h00000001, 32'h00000021, 32'h00000002, 1'b0); // B = 33 -> shamt = 1
        check("SLL ", ALU_SLL, 32'hFFFFFFFF, 32'h00000004, 32'hFFFFFFF0, 1'b0); // zeros enter from the right
        check("SLL ", ALU_SLL, 32'h80000000, 32'h00000001, 32'h00000000, 1'b1); // bit 31 falls off
        check("SRL ", ALU_SRL, 32'h80000000, 32'h0000001F, 32'h00000001, 1'b0); // shift by 31
        check("SRL ", ALU_SRL, 32'hFFFFFFFF, 32'h00000004, 32'h0FFFFFFF, 1'b0); // zero fill, not sign fill
        check("SRL ", ALU_SRL, 32'h80000000, 32'hFFFFFFE4, 32'h08000000, 1'b0); // B[4:0] = 4, upper bits ignored
        check("SRL ", ALU_SRL, 32'h12345678, 32'h00000000, 32'h12345678, 1'b0); // shift by 0
        check("SRL ", ALU_SRL, 32'h00000001, 32'h00000001, 32'h00000000, 1'b1); // bit 0 falls off

        // ---- 6) BEQ = SUB, branch taken when Zero = 1 ----
        check("BEQ ", ALU_SUB, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000, 1'b1); // equal     -> taken
        check("BEQ ", ALU_SUB, 32'h00000000, 32'h80000000, 32'h80000000, 1'b0); // not equal -> not taken
        check("BEQ ", ALU_SUB, 32'h00000001, 32'h00000002, 32'hFFFFFFFF, 1'b0); // not equal -> not taken

        // ---- 7) unused codes give 0, so Zero = 1 ----
        check("----", 4'b0111, 32'h10101010, 32'h01010101, 32'h00000000, 1'b1);
        check("----", 4'b1000, 32'h10101010, 32'h01010101, 32'h00000000, 1'b1);
        check("----", 4'b1111, 32'h10101010, 32'h01010101, 32'h00000000, 1'b1);

        // ---- 8) random operands, 4 per operation, checked against the model ----
        for (i = 0; i < 28; i = i + 1) begin
            case (i % 7)
                0       : rand_ctrl = ALU_ADD;
                1       : rand_ctrl = ALU_SUB;
                2       : rand_ctrl = ALU_SLL;
                3       : rand_ctrl = ALU_SRL;
                4       : rand_ctrl = ALU_AND;
                5       : rand_ctrl = ALU_OR;
                default : rand_ctrl = ALU_XOR;
            endcase
            rand_a        = $random(seed);
            rand_b        = $random(seed);
            rand_expected = model(rand_ctrl, rand_a, rand_b);
            check(op_label(rand_ctrl), rand_ctrl, rand_a, rand_b,
                  rand_expected, (rand_expected == 32'd0));
        end

        $display("--------------------------------------------------------------------------");
        $display("ALU_tb finished: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
