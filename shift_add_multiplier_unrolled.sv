`default_nettype none

// Registers
//   - first operand  : WIDTH * WIDTH
//   - second operand : (WIDTH-1) * WIDTH/2
//   - result         : WIDTH * WIDTH + WIDTH * (WIDTH+1) / 2
//   - result valid   : WIDTH
//
//   for 8 in -> 16 out: 200 registers

// Full Adders
//   - (WIDTH-1)^2 + (WIDTH-1) * WIDTH/2
//
//   for 8 in -> 16 out: 92 full adders

module shift_add_multiplier_unrolled_stage #(
    parameter OPERAND_WIDTH = 8,
    parameter STAGE = 0
) (
    input logic i_clk,
    input logic i_reset,
    input logic i_operands_valid,
    input logic [OPERAND_WIDTH-1:0] i_operand_a,
    input logic [OPERAND_WIDTH-STAGE-1:0] i_operand_b,
    input logic [OPERAND_WIDTH+STAGE-1:0] i_result,
    output logic o_result_valid,
    output logic [OPERAND_WIDTH-1:0] o_operand_a,
    output logic [OPERAND_WIDTH-STAGE-2:0] o_operand_b,
    output logic [OPERAND_WIDTH+STAGE:0] o_result
);

    logic result_valid;
    logic [OPERAND_WIDTH-1:0] operand_a;
    logic [OPERAND_WIDTH-STAGE-2:0] operand_b;
    logic [OPERAND_WIDTH+STAGE:0] result;

    logic [OPERAND_WIDTH+STAGE:0] shifted_operand_a;

    assign shifted_operand_a = { i_operand_a, { STAGE{ 1'b0 } } };

    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            operand_a <= 0;
            operand_b <= 0;
            result_valid <= 1'b0;
            result <= 0;
        end else begin
            operand_a <= i_operand_a;
            operand_b <= i_operand_b[OPERAND_WIDTH-1:1];
            result_valid <= i_operands_valid;
            result <= (i_operand_b[0]) ? i_result + shifted_operand_a : i_result;
        end
    end

    assign o_operand_a = operand_a;
    assign o_operand_b = operand_b;
    assign o_result_valid = result_valid;
    assign o_result = result;

endmodule


module shift_add_multiplier_unrolled #(
    parameter OPERAND_WIDTH = 8
) (
    input logic i_clk,
    input logic i_reset,
    input logic i_operands_valid,
    input logic [OPERAND_WIDTH-1:0] i_operand_a,
    input logic [OPERAND_WIDTH-1:0] i_operand_b,
    output logic o_result_valid,
    output logic [OPERAND_WIDTH*2-1:0] o_result
);

    logic [OPERAND_WIDTH:0] result_valid_signals;
    logic [OPERAND_WIDTH-1:0] operand_a_signals[OPERAND_WIDTH-1:0];
    logic [OPERAND_WIDTH-1:0] operand_b_signals[OPERAND_WIDTH-1:0];
    logic [OPERAND_WIDTH*2-1:0] result_signals[OPERAND_WIDTH:0];

    assign result_valid_signals[0] = i_operands_valid;
    assign operand_a_signals[0] = i_operand_a;
    assign operand_b_signals[0] = i_operand_b;
    assign result_signals[0] = '0;

    genvar k;

    generate
    for (k = 0; k < OPERAND_WIDTH-1; k++) begin : g_stages
        localparam OPERAND_B_WIDTH = OPERAND_WIDTH-k;
        localparam RESULT_WIDTH = OPERAND_WIDTH+k;

        shift_add_multiplier_unrolled_stage #(
            .OPERAND_WIDTH(OPERAND_WIDTH),
            .STAGE(k)
        ) stage (
            .i_clk(i_clk),
            .i_reset(i_reset),
            .i_operands_valid(result_valid_signals[k]),
            .i_operand_a(operand_a_signals[k]),
            .i_operand_b(operand_b_signals[k][OPERAND_B_WIDTH-1:0]),
            .i_result(result_signals[k][RESULT_WIDTH-1:0]),
            .o_result_valid(result_valid_signals[k+1]),
            .o_operand_a(operand_a_signals[k+1]),
            .o_operand_b(operand_b_signals[k+1][OPERAND_B_WIDTH-2:0]),
            .o_result(result_signals[k+1][RESULT_WIDTH+1-1:0])
        );
    end
    endgenerate

    shift_add_multiplier_unrolled_stage #(
        .OPERAND_WIDTH(OPERAND_WIDTH),
        .STAGE(OPERAND_WIDTH-1)
    ) last_stage (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_operands_valid(result_valid_signals[OPERAND_WIDTH-1]),
        .i_operand_a(operand_a_signals[OPERAND_WIDTH-1]),
        .i_operand_b(operand_b_signals[OPERAND_WIDTH-1][0:0]),
        .i_result(result_signals[OPERAND_WIDTH-1][OPERAND_WIDTH*2-2:0]),
        .o_result_valid(result_valid_signals[OPERAND_WIDTH]),
        .o_operand_a(),
        .o_operand_b(),
        .o_result(result_signals[OPERAND_WIDTH][OPERAND_WIDTH*2-1:0])
    );

    assign o_result_valid = result_valid_signals[OPERAND_WIDTH];
    assign o_result = result_signals[OPERAND_WIDTH];

endmodule

