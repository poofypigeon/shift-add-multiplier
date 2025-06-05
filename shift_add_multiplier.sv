`default_nettype none

// Registers
//   - counters       : WIDTH * clog2(WIDTH)
//   - first operand  : WIDTH * (WIDTH-1)
//   - second operand : (WIDTH*2-1) * (WIDTH-1)
//   - result         : (WIDTH*2-2) * (WIDTH-1) + WIDTH*2
//   - result valid   : 1
//
//   for 8 in -> 16 out: 300 registers

// Full Adders
//   - (WIDTH-1)^2 + (WIDTH-1) * WIDTH/2
//
//   for 8 in -> 16 out: 112 full adders

module shift_add_multiplier_unit #(
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

    logic [$clog2(OPERAND_WIDTH):0] counter;
    logic [OPERAND_WIDTH*2-1:0] operand_a;
    logic [OPERAND_WIDTH-2:0] operand_b;
    logic [OPERAND_WIDTH*2-1:0] result;
    logic [OPERAND_WIDTH*2-2:0] accumulator;

    assign result = accumulator + ((operand_b[0]) ? operand_a : 0);

    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            counter <= 0;
            operand_a <= 0;
            operand_b <= 0;
            accumulator <= 0;
        end else if ((counter == 0 || counter == OPERAND_WIDTH-1) && i_operands_valid) begin
            accumulator <= (i_operand_b[0]) ? i_operand_a : 0;
            operand_a <= { { (OPERAND_WIDTH-1){ 1'b0 } }, i_operand_a, 1'b0 };
            operand_b <= { 1'b0, i_operand_b[OPERAND_WIDTH-1:1] };
            counter <= 1;
        end else if (counter != 0) begin
            accumulator <= result;
            operand_a <= { operand_a[OPERAND_WIDTH*2-2:0], 1'b0};
            operand_b <= { 1'b0, operand_b[OPERAND_WIDTH-2:1] };
            counter <= (counter == OPERAND_WIDTH-1) ? 0 : counter + 1;
        end
    end

    assign o_result_valid = (counter == OPERAND_WIDTH-1);
    assign o_result = result;

endmodule


module shift_add_multiplier #(
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

    logic [$clog2(OPERAND_WIDTH):0] counter;

    logic [OPERAND_WIDTH-2:0] in_valid_vector;
    logic [OPERAND_WIDTH-2:0] out_valid_vector;

    logic [OPERAND_WIDTH*2-1:0] result_vector[OPERAND_WIDTH-2:0];

    logic result_valid = 1'b0;
    logic [OPERAND_WIDTH*2-1:0] result = 0;

    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            counter <= 0;
            result_valid <= 1'b0;
            result <= 0;
        end else begin
            counter <= (counter == OPERAND_WIDTH-2) ? 0 : counter + 1;
            result_valid <= |out_valid_vector;
            result <= result_vector[counter];
        end
    end

    always_comb begin
        for (int i = 0; i < OPERAND_WIDTH-1; i++) begin
            in_valid_vector[i] = i_operands_valid && counter == i;
        end
    end

    genvar k;

    generate
    for (k = 0; k < OPERAND_WIDTH - 1; k++) begin : g_units
        shift_add_multiplier_unit #(
            .OPERAND_WIDTH(OPERAND_WIDTH)
        ) unit (
            .i_clk(i_clk),
            .i_reset(i_reset),
            .i_operands_valid(in_valid_vector[k]),
            .i_operand_a(i_operand_a),
            .i_operand_b(i_operand_b),
            .o_result_valid(out_valid_vector[k]),
            .o_result(result_vector[k])
        );
    end
    endgenerate

    assign o_result_valid = result_valid;
    assign o_result = result;

endmodule
