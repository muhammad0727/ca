`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ZaiNaveed

module top_fsm_system (
    input wire clk,
    input wire pbin,
    input wire [15:0] physical_sw,
    output wire [15:0] physical_leds
);

    // DEBOUNCER (Cleans up the physical reset button signal)
    wire rst_clean;
    wire [31:0] switch_data;            // hold the value read from the switches
    reg  [31:0] led_write_data = 32'd0; // counter value here
    wire slow_clk;

    debouncer rst_db (
        .clk(clk),
        .pbin(pbin),
        .pbout(rst_clean)           // generated a clean signal
    );

    leds switch_reader (
        .clk(clk), .rst(rst_clean),
        .btns(16'd0),               // Not used for this FSM
        .writeData(32'd0),          // We don't write to switches
        .writeEnable(1'b0),         // Disabled
        .readEnable(1'b1),          // Always ON so we can monitor switches
        .memAddress(30'd0),
        .switches(physical_sw),     // Plug in the physical switches
        .readData(switch_data)      // output data
    );

    switches led_writer (
        .clk(clk), .rst(rst_clean),
        .writeData(led_write_data),
        .writeEnable(1'b1),         // Always ON so LEDs update instantly
        .readEnable(1'b0), .memAddress(30'd0),
        .readData(),                // Ignored
        .leds(physical_leds)
    );

    clock_divider ticker (
        .clk_in(clk),               // Feed it the 100MHz fast clock
        .rst(rst_clean),            // Feed it the clean reset signal
        .clk_out(slow_clk)          // It spits out the 1Hz slow clock!
    );

    // ==================== FSM AND COUNTER LOGIC ====================

    localparam IDLE  = 1'b0;
    localparam COUNT = 1'b1;

    // Initial values so the design starts in a known state at power-on
    // without needing the reset button pressed first.
    reg state = IDLE;
    reg next_state;
    reg [15:0] counter = 16'd0;

    wire [15:0] sw_value = switch_data[15:0];

   
    reg slow_clk_d = 1'b0;
    always @(posedge clk)
        slow_clk_d <= slow_clk;

    wire tick = slow_clk & ~slow_clk_d;

    // ---- state register ----
    always @(posedge clk) begin
        if (rst_clean)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ---- next state logic ----
    always @(*) begin
        next_state = state;
        case (state)
            IDLE  : if (sw_value != 16'd0) next_state = COUNT;
            COUNT : if (counter  == 16'd0) next_state = IDLE;
        endcase
    end

    // ---- counter ----
    // The load happens only in IDLE. That single restriction is what makes the
    // switches "ignored" for the rest of the countdown - no extra logic needed.
    always @(posedge clk) begin
        if (rst_clean)
            counter <= 16'd0;
        else begin
            case (state)
                IDLE  : if (sw_value != 16'd0)        counter <= sw_value;
                COUNT : if (tick && counter != 16'd0) counter <= counter - 1'b1;
            endcase
        end
    end

    // ---- Moore output ----
    // The LEDs depend on the state alone, not on the inputs.
    always @(*) begin
        case (state)
            COUNT   : led_write_data = {16'd0, counter};
            default : led_write_data = 32'd0;
        endcase
    end

endmodule
