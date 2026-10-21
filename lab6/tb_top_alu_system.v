`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Lab 6 - self-checking testbench for top_alu_system.v
//
// The run is ~5 us, longer than Vivado's default 1000 ns:
// press "Run All" after the simulation opens.
//
// Two copies of the top are simulated with the same switches and reset:
//   dut        : the board configuration, A = 0x10101010, B = 0x01010101
//   dut_halves : A = 0xABCD1234, B = 0x00000004. With the board operands the
//                upper and lower 16 bits of every result are equal and
//                ADD/OR/XOR all give 0x11111111, so this copy is what proves
//                the half-select and the operation select are really right.
//////////////////////////////////////////////////////////////////////////////////


module tb_top_alu_system;

    localparam integer STEP = 20;   // STEP_CYCLES used in simulation (2 s on the board)

    localparam ALU_AND = 4'b0000;
    localparam ALU_OR  = 4'b0001;
    localparam ALU_ADD = 4'b0010;
    localparam ALU_XOR = 4'b0011;
    localparam ALU_SLL = 4'b0100;
    localparam ALU_SRL = 4'b0101;
    localparam ALU_SUB = 4'b0110;

    localparam V_LOW    = 2'b00;
    localparam V_HIGH   = 2'b01;
    localparam V_STATUS = 2'b10;

    reg         clk         = 1'b0;
    reg         pbin        = 1'b0;
    reg  [15:0] physical_sw = 16'd0;
    wire [15:0] physical_leds;
    wire [15:0] leds_halves;

    integer pass_count = 0;
    integer fail_count = 0;

    top_alu_system #(
        .STEP_CYCLES(STEP)
    ) dut (
        .clk(clk),
        .pbin(pbin),
        .physical_sw(physical_sw),
        .physical_leds(physical_leds)
    );

    top_alu_system #(
        .OPERAND_A(32'hABCD1234),
        .OPERAND_B(32'h00000004),
        .STEP_CYCLES(STEP)
    ) dut_halves (
        .clk(clk),
        .pbin(pbin),
        .physical_sw(physical_sw),
        .physical_leds(leds_halves)
    );

    always #5 clk = ~clk;  // 100 MHz

    // sw = {mode, view[1:0], B=A, 8'd0, ALUControl}
    function [15:0] sw_word;
        input       auto_mode;
        input [1:0] view;
        input       b_eq_a;
        input [3:0] ctrl;
        begin
            sw_word = {auto_mode, view, b_eq_a, 8'd0, ctrl};
        end
    endfunction

    // ---- set the switches, give the FSM time to loop, check both boards ----
    task expect_leds;
        input [31:0] name;
        input [15:0] sw;
        input [15:0] exp_main;
        input [15:0] exp_halves;
        begin
            physical_sw = sw;
            repeat (10) @(posedge clk);
            #1;
            if (physical_leds === exp_main && leds_halves === exp_halves) begin
                pass_count = pass_count + 1;
                $display("PASS  %s sw=%b  leds=%h  leds_halves=%h",
                         name, sw, physical_leds, leds_halves);
            end
            else begin
                fail_count = fail_count + 1;
                $display("FAIL  %s sw=%b  leds=%h  leds_halves=%h   (expected %h / %h)",
                         name, sw, physical_leds, leds_halves, exp_main, exp_halves);
            end
        end
    endtask

    // ---- auto mode: wait (with a time limit) for the next status word ----
    // The limit is shorter than one full 8-step round, so a skipped or
    // out-of-order step makes this FAIL instead of matching on the next round.
    task expect_step;
        input [31:0] name;
        input [15:0] exp_main;
        integer n;
        begin
            n = 0;
            while (physical_leds !== exp_main && n < 2*STEP + 10) begin
                @(posedge clk);
                n = n + 1;
            end
            #1;
            if (physical_leds === exp_main) begin
                pass_count = pass_count + 1;
                $display("PASS  %s auto step  leds=%h  (after %0d clocks)", name, physical_leds, n);
            end
            else begin
                fail_count = fail_count + 1;
                $display("FAIL  %s auto step  leds=%h   (expected %h)", name, physical_leds, exp_main);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_top_alu_system.vcd");
        $dumpvars(0, tb_top_alu_system);

        // ---- 0) reset ----
        pbin = 1'b1;
        repeat (4) @(posedge clk);
        #1;
        if (physical_leds === 16'd0 && leds_halves === 16'd0) begin
            pass_count = pass_count + 1;
            $display("PASS  RST  leds are dark while reset is held");
        end
        else begin
            fail_count = fail_count + 1;
            $display("FAIL  RST  leds=%h leds_halves=%h while reset is held", physical_leds, leds_halves);
        end
        pbin = 1'b0;

        // ---- 1) manual mode, low half of ALUResult ----
        //                           mode  view   B=A   op            board    halves
        expect_leds("ADD ", sw_word(1'b0, V_LOW, 1'b0, ALU_ADD), 16'h1111, 16'h1238);
        expect_leds("SUB ", sw_word(1'b0, V_LOW, 1'b0, ALU_SUB), 16'h0F0F, 16'h1230);
        expect_leds("SLL ", sw_word(1'b0, V_LOW, 1'b0, ALU_SLL), 16'h2020, 16'h2340);
        expect_leds("SRL ", sw_word(1'b0, V_LOW, 1'b0, ALU_SRL), 16'h0808, 16'hD123);
        expect_leds("AND ", sw_word(1'b0, V_LOW, 1'b0, ALU_AND), 16'h0000, 16'h0004);
        expect_leds("OR  ", sw_word(1'b0, V_LOW, 1'b0, ALU_OR ), 16'h1111, 16'h1234);
        expect_leds("XOR ", sw_word(1'b0, V_LOW, 1'b0, ALU_XOR), 16'h1111, 16'h1230);
        expect_leds("----", sw_word(1'b0, V_LOW, 1'b0, 4'b0111), 16'h0000, 16'h0000);

        // ---- 2) manual mode, high half of ALUResult ----
        expect_leds("ADD ", sw_word(1'b0, V_HIGH, 1'b0, ALU_ADD), 16'h1111, 16'hABCD);
        expect_leds("SUB ", sw_word(1'b0, V_HIGH, 1'b0, ALU_SUB), 16'h0F0F, 16'hABCD);
        expect_leds("SLL ", sw_word(1'b0, V_HIGH, 1'b0, ALU_SLL), 16'h2020, 16'hBCD1);
        expect_leds("SRL ", sw_word(1'b0, V_HIGH, 1'b0, ALU_SRL), 16'h0808, 16'h0ABC);
        expect_leds("AND ", sw_word(1'b0, V_HIGH, 1'b0, ALU_AND), 16'h0000, 16'h0000);
        expect_leds("OR  ", sw_word(1'b0, V_HIGH, 1'b0, ALU_OR ), 16'h1111, 16'hABCD);
        expect_leds("XOR ", sw_word(1'b0, V_HIGH, 1'b0, ALU_XOR), 16'h1111, 16'hABCD);

        // ---- 3) manual mode, status view {Zero, 0, step, ALUControl} ----
        expect_leds("ADD ", sw_word(1'b0, V_STATUS, 1'b0, ALU_ADD), 16'h0002, 16'h0002);
        expect_leds("AND ", sw_word(1'b0, V_STATUS, 1'b0, ALU_AND), 16'h8000, 16'h0000); // board: Zero = 1
        expect_leds("BEQ ", sw_word(1'b0, V_STATUS, 1'b0, ALU_SUB), 16'h0006, 16'h0006); // A != B: not taken
        expect_leds("----", sw_word(1'b0, V_STATUS, 1'b0, 4'b0111), 16'h8007, 16'h8007); // unused code: 0

        // ---- 4) B = A ----
        expect_leds("BEQ ", sw_word(1'b0, V_STATUS, 1'b1, ALU_SUB), 16'h8006, 16'h8006); // A == B: taken
        expect_leds("BEQ ", sw_word(1'b0, 2'b11,    1'b1, ALU_SUB), 16'h8006, 16'h8006); // view 11 = status
        expect_leds("SUB ", sw_word(1'b0, V_LOW,    1'b1, ALU_SUB), 16'h0000, 16'h0000);
        expect_leds("ADD ", sw_word(1'b0, V_LOW,    1'b1, ALU_ADD), 16'h2020, 16'h2468); // A + A
        expect_leds("ADD ", sw_word(1'b0, V_HIGH,   1'b1, ALU_ADD), 16'h2020, 16'h579A);
        expect_leds("XOR ", sw_word(1'b0, V_LOW,    1'b1, ALU_XOR), 16'h0000, 16'h0000); // A ^ A

        // ---- 5) auto mode, status view ----
        // sw[3:0] = 1111 on purpose: it must be ignored in auto mode.
        // expected = {Zero, 8'd0, step, ALUControl}
        physical_sw = sw_word(1'b1, V_STATUS, 1'b0, 4'b1111);
        expect_step("ADD ", 16'h0002);
        expect_step("SUB ", 16'h0016);
        expect_step("SLL ", 16'h0024);
        expect_step("SRL ", 16'h0035);
        expect_step("AND ", 16'h8040);   // Zero = 1
        expect_step("OR  ", 16'h0051);
        expect_step("XOR ", 16'h0063);
        expect_step("BEQ ", 16'h0076);   // A != B: not taken
        expect_step("ADD ", 16'h0002);   // wraps back to the first step

        // ---- 6) reset in the middle of auto mode ----
        expect_step("SUB ", 16'h0016);
        pbin = 1'b1;
        repeat (3) @(posedge clk);
        #1;
        if (physical_leds === 16'd0) begin
            pass_count = pass_count + 1;
            $display("PASS  RST  leds cleared by reset during auto mode");
        end
        else begin
            fail_count = fail_count + 1;
            $display("FAIL  RST  leds=%h, reset during auto mode did not clear them", physical_leds);
        end
        pbin = 1'b0;
        expect_step("ADD ", 16'h0002);   // starts again from the first step

        // ---- 7) back to manual mode: the step field goes back to 0 ----
        expect_step("SUB ", 16'h0016);   // let auto mode move past the first step
        expect_leds("ADD ", sw_word(1'b0, V_STATUS, 1'b0, ALU_ADD), 16'h0002, 16'h0002);
        expect_leds("SRL ", sw_word(1'b0, V_LOW,    1'b0, ALU_SRL), 16'h0808, 16'hD123);

        // ---- 8) auto mode again: starts from ADD, not from where it stopped ----
        physical_sw = sw_word(1'b1, V_STATUS, 1'b0, 4'b0000);
        expect_step("ADD ", 16'h0002);
        expect_step("SUB ", 16'h0016);

        $display("--------------------------------------------------------------------------");
        $display("tb_top_alu_system finished: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

endmodule
