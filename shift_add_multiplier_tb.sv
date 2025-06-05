`timescale 1ns/1ps

module shift_add_multiplier_tb();

localparam CLK_PERIOD = 2;
localparam OPERAND_WIDTH = 8;

logic clk;
logic reset;
logic operands_valid;
logic [OPERAND_WIDTH-1:0] operand_a;
logic [OPERAND_WIDTH-1:0] operand_b;
logic result_valid[1:0];
logic [OPERAND_WIDTH*2-1:0] result[1:0];

logic failure = 1'b0;

shift_add_multiplier #(
    .OPERAND_WIDTH(OPERAND_WIDTH)
) uut0 (
    .i_clk(clk),
    .i_reset(reset),
    .i_operands_valid(operands_valid),
    .i_operand_a(operand_a),
    .i_operand_b(operand_b),
    .o_result_valid(result_valid[0]),
    .o_result(result[0])
);

shift_add_multiplier_unrolled #(
    .OPERAND_WIDTH(OPERAND_WIDTH)
) uut1 (
    .i_clk(clk),
    .i_reset(reset),
    .i_operands_valid(operands_valid),
    .i_operand_a(operand_a),
    .i_operand_b(operand_b),
    .o_result_valid(result_valid[1]),
    .o_result(result[1])
);

task operation;
    input [OPERAND_WIDTH-1:0] op_a;
    input [OPERAND_WIDTH-1:0] op_b;
    input op_valid;
begin
    operand_a = op_a;
    operand_b = op_b;
    operands_valid = op_valid;
    #CLK_PERIOD;
end
endtask

task check_result;
    input int test_number;
    input res_valid0;
    input res_valid1;
    input expected_res_valid;
    input [OPERAND_WIDTH*2-1:0]res0;
    input [OPERAND_WIDTH*2-1:0]res1;
    input [OPERAND_WIDTH*2-1:0]expected_res;
begin
    if (res_valid0 != expected_res_valid) begin
        $display("FAILURE: test %d, expected result_valid[0] to be %b, got %b", test_number, expected_res_valid, res_valid0);
        $finish;
    end
    if (res_valid1 != expected_res_valid) begin
        $display("FAILURE: test %d, expected result_valid[1] to be %b, got %b", test_number, expected_res_valid, res_valid1);
        $finish;
    end
    if (expected_res_valid && res0 != expected_res) begin
        $display("FAILURE: test %d, expected result[0] to be %d, got %d", test_number, expected_res, res0);
        $finish;
    end
    if (expected_res_valid && res1 != expected_res) begin
        $display("FAILURE: test %d, expected result[1] to be %d, got %d", test_number, expected_res, res1);
        $finish;
    end
end
endtask

initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
    // reset
    reset = 1'b1;
    operand_a = 0;
    operand_b = 0;
    operands_valid = 1'b0;
    
    #(CLK_PERIOD*8);
    if (result_valid[0] != 1'b0 || result_valid[1] != 1'b0) begin
        $display("FAILURE: reset of result_valid");
        $finish;
    end
    if (result[0] != 0 || result[1] != 0) begin
        $display("FAILURE: reset of result");
        $finish;
    end

    reset = 1'b0;
    operands_valid = 1'b1;
    operation(18,  230, 1'b1);
    operation(76,  154, 1'b1);
    operation(204, 199, 1'b0); // bubble
    operation(13,  58,  1'b1);
    operation(121, 34,  1'b1);
    operation(98,  243, 1'b1);
    operation(6,   174, 1'b1);
    operation(251, 90,  1'b1);
    check_result(1, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 18*230);
    operation(87,  113, 1'b1);
    check_result(2, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 76*154);
    operation(200, 11,  1'b0); // bubble
    check_result(3, result_valid[0], result_valid[1], 1'b0, result[0], result[1], 204*199);
    operation(35,  187, 1'b1);
    check_result(4, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 13*58);
    operation(243, 64,  1'b1);
    check_result(5, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 121*34);
    operation(160, 215, 1'b1);
    check_result(6, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 98*243);
    operation(7,   144, 1'b1);
    check_result(7, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 6*174);
    operation(59,  182, 1'b1);
    check_result(8, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 251*90);
    operation(129, 39,  1'b1);
    check_result(9, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 87*113);
    operation(100, 221, 1'b1);
    check_result(10, result_valid[0], result_valid[1], 1'b0, result[0], result[1], 200*11);
    operation(26,  70,  1'b1);
    check_result(11, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 35*187);
    operation(195, 85,  1'b1);
    check_result(12, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 243*64);
    operation(255, 255,  1'b1);
    check_result(13, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 160*215);
    #CLK_PERIOD;
    check_result(14, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 7*144);
    #CLK_PERIOD;
    check_result(15, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 59*182);
    #CLK_PERIOD;
    check_result(16, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 129*39);
    #CLK_PERIOD;
    check_result(17, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 100*221);
    #CLK_PERIOD;
    check_result(18, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 26*70);
    #CLK_PERIOD;
    check_result(19, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 195*85);
    #CLK_PERIOD;
    check_result(20, result_valid[0], result_valid[1], 1'b1, result[0], result[1], 255*255);

    $display("TESTS PASSED");
    $finish;
end

endmodule
