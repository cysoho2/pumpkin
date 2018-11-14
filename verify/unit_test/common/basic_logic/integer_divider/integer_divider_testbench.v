`include "parameters.h"

module integer_divider_testbench();

parameter OPERAND_WIDTH_IN_BITS = 64;
parameter NUM_TEST_DIGIT = OPERAND_WIDTH_IN_BITS;

reg  reset_in;
reg  clk_in;

wire multiply_exception_from_mul;

reg  multiplicand_valid_to_mul;
reg  multiplicand_sign_to_mul;
reg  [(OPERAND_WIDTH_IN_BITS - 1):0] multiplicand_to_mul;

reg  multiplier_valid_to_mul;
reg  multiplier_sign_to_mul;
reg  [(OPERAND_WIDTH_IN_BITS - 1):0] multiplier_to_mul;

wire issue_ack_from_mul;

wire product_valid_from_mul;
wire product_sign_from_mul;
wire [(PRODUCT_WIDTH_IN_BITS - 1):0] product_from_mul;

reg  issue_ack_to_mul;

integer operand_index;

reg [31:0] test_case;
reg test_judge;

reg [5:0] operand_data_pointer;
reg [5:0] product_data_pointer;

reg [(OPERAND_WIDTH_IN_BITS - 1):0] test_multiplier_data_buffer [(NUM_TEST_DIGIT - 1):0];
reg [(OPERAND_WIDTH_IN_BITS - 1):0] test_multiplicand_data_buffer [(NUM_TEST_DIGIT - 1):0];
reg [(OPERAND_WIDTH_IN_BITS - 1):0] test_product_data_buffer [(NUM_TEST_DIGIT - 1):0];
reg [(OPERAND_WIDTH_IN_BITS - 1):0] data_from_mul_buffer [(NUM_TEST_DIGIT - 1):0];
reg [(NUM_TEST_DIGIT - 1):0] match_array;

wire read_end_flag;
wire write_and_flag;

wire [(OPERAND_WIDTH_IN_BITS - 1):0] test_multiplicand_data_from_buffer;
wire [(OPERAND_WIDTH_IN_BITS - 1):0] test_multiplier_data_from_buffer;

assign read_end_flag = (product_data_pointer == NUM_TEST_DIGIT);
assign write_and_flag = (operand_data_pointer == NUM_TEST_DIGIT);

assign test_multiplier_data_from_buffer = test_multiplier_data_buffer[operand_data_pointer];
assign test_multiplicand_data_from_buffer = test_multiplicand_data_buffer[operand_data_pointer];

//write
always @(posedge clk_in)
begin
    if (reset_in)
    begin
        multiplicand_to_mul <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        multiplier_to_mul <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

        multiplier_valid_to_mul <= 1'b0;
        multiplicand_valid_to_mul <= 1'b0;

        operand_data_pointer <= 5'b0;
    end
    else
    begin
        if (~write_and_flag)
        begin
            multiplier_to_mul <= test_multiplier_data_from_buffer;
            multiplicand_to_mul <= test_multiplicand_data_from_buffer;
            multiplier_valid_to_mul <= 1'b1;
            multiplicand_valid_to_mul <= 1'b1;

            if (issue_ack_from_mul)
            begin
                operand_data_pointer <= operand_data_pointer + 1'b1;
            end
        end
        else
        begin
            multiplier_to_mul <= 0;
            multiplicand_to_mul <= 0;
            multiplier_valid_to_mul <= 1'b0;
            multiplicand_valid_to_mul <= 1'b0;
        end
    end
end

//read
always @ (posedge clk_in)
begin
    if (reset_in)
    begin
        product_data_pointer <= 0;
        issue_ack_to_mul <= 0;
    end
    else
    begin
        if (~read_end_flag)
        begin
            if (issue_ack_to_mul)
            begin
                issue_ack_to_mul <= 1'b0;
            end
            else
            begin
                if (product_valid_from_mul)
                begin
                    issue_ack_to_mul <= 1'b1;
                    data_from_mul_buffer[product_data_pointer] <= product_from_mul;
                    product_data_pointer <= product_data_pointer + 1'b1;
                end
            end
        end
    end
end

//check
always @ (posedge clk_in)
begin
    if (reset_in)
    begin
        test_judge <= 0;
    end
    else
    begin
        for (operand_index = 0; operand_index < NUM_TEST_DIGIT; operand_index = operand_index + 1)
        begin
            match_array[operand_index] <= data_from_mul_buffer[operand_index] == test_product_data_buffer[operand_index];
        end

        if (&match_array)
        begin
            test_judge <= 1'b1;
        end
        else
        begin
            test_judge <= 1'b0;
        end
    end
end

initial
begin

    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, integer_divider_testbench);
    `endif

    $display("\n[info-testbench] simulation for %m begins now");
    //initial
    clk_in <= 1'b0;
    reset_in <= 1'b1;

    test_case <= 0;
    for (operand_index = 0; operand_index < NUM_TEST_DIGIT; operand_index = operand_index + 1'b1)
    begin
        test_multiplier_data_buffer[operand_index] <= {{(NUM_TEST_DIGIT / 2){1'b1}}, {(NUM_TEST_DIGIT / 2){1'b0}}} + (1 << operand_index);
        test_multiplicand_data_buffer[operand_index] <= {(NUM_TEST_DIGIT){1'b1}} - (1 << operand_index);
        test_product_data_buffer[operand_index] <= ({{(NUM_TEST_DIGIT / 2){1'b1}}, {(NUM_TEST_DIGIT / 2){1'b0}}} + (1 << operand_index)) * ({(NUM_TEST_DIGIT){1'b1}} - (1 << operand_index));

        data_from_mul_buffer[operand_index] <= {(NUM_TEST_DIGIT){1'b0}};

        match_array[operand_index] <= 0;
   end


    #(`FULL_CYCLE_DELAY * 5)
    reset_in <= 1'b0;


    #(`FULL_CYCLE_DELAY * 4500) $display("[info-testbench] test case %d %40s : \t%s", test_case, "multiplier", test_judge ? "passed" : "failed");


    #(`FULL_CYCLE_DELAY * 5)  $display("\n[info-testbench] simulation for %m comes to the end\n");
                              $finish;

end

always begin #`HALF_CYCLE_DELAY clk_in                      <= ~clk_in; end

multicycle_divider
#(
    .OPERAND_WIDTH_IN_BITS(OPERAND_WIDTH_IN_BITS)
)
multicycle_divider
(
    .reset_in                                               (reset_in),
    .clk_in                                                 (clk_in),

    .valid_in                                               (valid_to_div),

    .dividend_sign_in                                       (dividend_sign_to_div),
    .dividend_in                                            (dividend_to_div),

    .divisor_sign_in                                        (divisor_sign_to_div),
    .divisor_in                                             (divisor_to_div),

    .valid_out                                              (valid_from_div),
    .remainder_sign_out                                     (remainder_sign_from_div),
    .remainder_out                                          (remainder_from_div),

    .quotient_sign_out                                      (quotient_sign_from_div),
    .quotient_out                                           (quotient_from_div)

    .divide_by_zero                                         (divide_by_zero_from_div)
);

endmodule
