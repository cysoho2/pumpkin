`include "parameters.h"

module integer_multiplier_testbench();

parameter OPERAND_WIDTH_IN_BITS = 64;
parameter PRODUCT_WIDTH_IN_BITS = 64;
parameter NUM_TEST_DIGIT = OPERAND_WIDTH_IN_BITS;

reg  reset_in;
reg  clk_in;

wire multiply_exception_out;

reg  multiplicand_valid_from_mul;
reg  multiplicand_sign_from_mul;
reg  [(OPERAND_WIDTH_IN_BITS - 1):0] multiplicand_from_mul;

reg  multiplier_valid_from_mul;
reg  multiplier_sign_from_mul;
reg  [(OPERAND_WIDTH_IN_BITS - 1):0] multiplier_from_mul;

wire issue_ack_to_mul;

wire product_valid_to_mul;
wire product_sign_to_mul;
wire [(PRODUCT_WIDTH_IN_BITS - 1):0] product_to_mul;

reg  issue_ack_from_mul;

integer operand_index;

reg [31:0] test_case;
reg [5:0] multiplicand_data_pointer;
reg [5:0] multiplier_data_pointer;
reg [(NUM_TEST_DIGIT - 1):0] test_operand_buffer [(OPERAND_WIDTH_IN_BITS - 1):0];

wire [(OPERAND_WIDTH_IN_BITS - 1):0] test_multiplicand_data_from_buffer;
wire [(OPERAND_WIDTH_IN_BITS - 1):0] test_multiplier_data_from_buffer;

assign test_multiplier_data_from_buffer = test_operand_buffer[multiplier_data_pointer];
assign test_multiplicand_data_from_buffer = test_operand_buffer[multiplicand_data_pointer];

//write
always @(posedge clk_in)
begin
    if (reset_in)
    begin
        multiplier_in <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        multiplicand_in <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

        multiplier_data_pointer <= 5'b0;
        multiplicand_data_pointer <= NUM_TEST_DIGIT - 5'b0;
    end
    else
    begin
        multiplier_in <= test_multiplier_data_from_buffer;
        multiplicand_in <= test_multiplicand_data_from_buffer;

        if (issue_ack_from_mul)
        begin
            multiplier_data_pointer <= multiplier_data_pointer + 1'b1;
            test_multiplicand_data_from_buffer <= test_multiplicand_data_from_buffer - 1'b1;
        end
    end
end

//read

//check


always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

integer_multiplier
#(
    .OPERAND_WIDTH_IN_BITS(OPERAND_WIDTH_IN_BITS);
    .PRODUCT_WIDTH_IN_BITS(PRODUCT_WIDTH_IN_BITS);
)
integer_multiplier
(
    .reset_in(reset_in),
    .clk_in(clk_in),

    .multiply_exception_out(multiply_exception_to_mul),

    .multiplicand_valid_in(multiplicand_valid_from_mul),
    .multiplicand_sign_in(multiplicand_sign_from_mul),
    .multiplicand_in(multiplicand_from_mul),

    .multiplier_valid_in(multiplier_valid_from_mul),
    .multiplier_sign_in(multiplier_sign_from_mul),
    .multiplier_in(multiplier_from_mul),

    .issue_ack_out(issue_ack_to_mul),

    .product_valid_out(product_valid_to_mul),
    .product_sign_out(product_sign_to_mul),
    .product_out(product_to_mul),

    .issue_ack_in(issue_ack_from_mul)
);

initial
begin

    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, integer_multiplier_testbench);
    `endif

    //initial
    clk_in <= 1'b0;
    reset_in <= 1'b1;

    for (operand_index = 0; operand_index < NUM_TEST_DIGIT; operand_index = operand_index + 1'b0)
    begin
        test_operand_buffer[operand_index] <= {{(NUM_TEST_DIGIT - operand_index){1'b1}}, {(operand_index){1'b0}}};
    end

    //begin
    #(`FULL_CYCLE_DELAY * 5) test_case <= 0;
    reset_in <= 1'b0;

    //end

    $display("\n[info-testbench] simulation for %m begins now");


    #(`FULL_CYCLE_DELAY * 5)  $display("\n[info-testbench] simulation for %m comes to the end\n");
                              $finish;

end

endmodule
