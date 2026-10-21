`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Lab 6 - 32-bit ALU for a single-cycle RISC-V (RV32I) processor
//
// ALUControl encoding (Patterson & Hennessy codes for AND/OR/ADD/SUB, the
// remaining RV32I operations placed on unused codes):
//
//      ALUControl | Operation | ALUResult
//      -----------+-----------+------------------------------
//         0000    |   AND     | A & B
//         0001    |   OR      | A | B
//         0010    |   ADD     | A + B
//         0011    |   XOR     | A ^ B
//         0100    |   SLL     | A << B[4:0]
//         0101    |   SRL     | A >> B[4:0]   (logical, zero-fill)
//         0110    |   SUB     | A - B         (also used by BEQ)
//         others  |   -       | 0
//
// BEQ has no code of its own: the processor subtracts (0110) and takes the
// branch when Zero = 1, because A - B == 0 exactly when A == B.
//////////////////////////////////////////////////////////////////////////////////


module ALU(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUControl,
    output reg  [31:0] ALUResult,
    output wire        Zero
);

    localparam ALU_AND = 4'b0000;
    localparam ALU_OR  = 4'b0001;
    localparam ALU_ADD = 4'b0010;
    localparam ALU_XOR = 4'b0011;
    localparam ALU_SLL = 4'b0100;
    localparam ALU_SRL = 4'b0101;
    localparam ALU_SUB = 4'b0110;

    // ---- arithmetic unit: one adder does both ADD and SUB ----
    // A - B = A + ~B + 1 (two's complement). For SUB the input mux passes ~B
    // and the "+1" comes in as the carry-in, so no separate subtractor is needed.
    wire        sub   = (ALUControl == ALU_SUB);
    wire [31:0] b_mux = sub ? ~B : B;
    wire [31:0] sum   = A + b_mux + {31'd0, sub};

    // ---- logic unit (works on the original B, not on b_mux) ----
    wire [31:0] and_out = A & B;
    wire [31:0] or_out  = A | B;
    wire [31:0] xor_out = A ^ B;

    // ---- shifter ----
    // RV32I shifts use only the low 5 bits of the second operand (0..31).
    wire [4:0]  shamt   = B[4:0];
    wire [31:0] sll_out = A << shamt;
    wire [31:0] srl_out = A >> shamt;   // >> is logical: zeros enter from the left

    // ---- result multiplexer ----
    // default branch keeps this purely combinational (no latch is inferred).
    always @(*) begin
        case (ALUControl)
            ALU_AND : ALUResult = and_out;
            ALU_OR  : ALUResult = or_out;
            ALU_ADD : ALUResult = sum;
            ALU_XOR : ALUResult = xor_out;
            ALU_SLL : ALUResult = sll_out;
            ALU_SRL : ALUResult = srl_out;
            ALU_SUB : ALUResult = sum;
            default : ALUResult = 32'd0;
        endcase
    end

    // ---- zero detector: a 32-input NOR of the result ----
    assign Zero = (ALUResult == 32'd0);

endmodule
