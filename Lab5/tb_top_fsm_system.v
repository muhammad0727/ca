`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ZaiNaveed


module tb_top_fsm_system;

    localparam integer CLKS_PER_TICK = 6;      // (MAX_COUNT + 1) * 2

    reg clk  = 1'b0;
    reg pbin = 1'b0;
    reg  [15:0] physical_sw = 16'd0;
    wire [15:0] physical_leds;

    top_fsm_system dut (
        .clk (clk),
        .pbin (pbin),
        .physical_sw (physical_sw),
        .physical_leds (physical_leds)
    );

    always #5 clk = ~clk;  // 100 MHz

    initial begin
        $monitor("t=%6t ns | sw=%3d leds=%3d", $time, physical_sw, physical_leds);
        // 0 - power-on reset (also clears the X on clk_out)
        pbin = 1'b1;
        repeat (4) @(posedge clk);
        pbin = 1'b0;
        repeat (4) @(posedge clk);

        // 1 - zero on the switches keeps the FSM waiting
        repeat (10) @(posedge clk);
        #1;
        if (physical_leds !== 16'd0) $display("FAIL: leds must stay dark while waiting");

        // 2 - non-zero latches the value and displays it
        physical_sw = 16'd5;
        repeat (6) @(posedge clk);
        #1;
        if (physical_leds !== 16'd5) $display("FAIL: leds should show the latched value 5");

        // 3 - clearing the switches mid-count must not stop the countdown
        physical_sw = 16'd0;
        repeat (4) @(posedge clk);
        #1;
        if (physical_leds === 16'd0) $display("FAIL: countdown stopped when switches cleared");

        // 4 - it reaches zero and returns to waiting
        repeat (5 * CLKS_PER_TICK + 12) @(posedge clk);
        #1;
        if (physical_leds !== 16'd0) $display("FAIL: leds should be dark once the count ends");

        // 5 - reset during a countdown clears everything
        physical_sw = 16'd9;
        repeat (2 * CLKS_PER_TICK) @(posedge clk);
        pbin = 1'b1;
        repeat (4) @(posedge clk);
        #1;
        if (physical_leds !== 16'd0) $display("FAIL: reset should clear the leds");
        pbin        = 1'b0;
        physical_sw = 16'd0;

        repeat (20) @(posedge clk);
        $display("Testbench finished");
        $finish;
    end

endmodule
