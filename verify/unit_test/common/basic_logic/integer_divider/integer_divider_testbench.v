`include "parameters.h"

module integer_divider_testbench();

parameter OPERAND_WIDTH_IN_BITS = 64;
parameter NUM_TEST_DIGIT = OPERAND_WIDTH_IN_BITS / 4;

reg  reset_in;
reg  clk_in;

reg valid_to_div;
reg dividend_sign_to_div;
reg  [(OPERAND_WIDTH_IN_BITS - 1):0] dividend_to_div;

reg  divisor_sign_to_div;
reg  [(OPERAND_WIDTH_IN_BITS - 1):0] divisor_to_div;

wire issue_ack_from_div;

wire valid_from_div;

wire remainder_sign_from_div;
wire [(OPERAND_WIDTH_IN_BITS - 1):0]remainder_from_div;
wire quotient_sign_from_div;
wire [(OPERAND_WIDTH_IN_BITS - 1):0] quotient_from_div;

reg  issue_ack_to_div;

wire divide_by_zero_from_div;

integer operand_index;
integer check_index;

reg [31:0] test_case;
reg test_judge;

reg [5:0] operand_data_pointer;
reg [5:0] product_data_pointer;

reg [(NUM_TEST_DIGIT - 1):0] test_divisor_sign_array;
reg [(NUM_TEST_DIGIT - 1):0] test_dividend_sign_array;
reg [(OPERAND_WIDTH_IN_BITS - 1):0] test_divisor_data_buffer [(NUM_TEST_DIGIT - 1):0];
reg [(OPERAND_WIDTH_IN_BITS - 1):0] test_dividend_data_buffer [(NUM_TEST_DIGIT - 1):0];

reg [(NUM_TEST_DIGIT - 1):0] passed_exception_array;
reg [(NUM_TEST_DIGIT - 1):0] passed_remainder_sign_array;
reg [(NUM_TEST_DIGIT - 1):0] passed_quotient_sign_array;
reg [(OPERAND_WIDTH_IN_BITS - 1):0] passed_remainder_data_buffer [(NUM_TEST_DIGIT - 1):0];
reg [(OPERAND_WIDTH_IN_BITS - 1):0] passed_quotient_data_buffer [(NUM_TEST_DIGIT - 1):0];

reg [(NUM_TEST_DIGIT - 1):0] exception_from_div_array;
reg [(NUM_TEST_DIGIT - 1):0] remainder_sign_from_div_array;
reg [(NUM_TEST_DIGIT - 1):0] quotient_sign_from_div_array;
reg [(OPERAND_WIDTH_IN_BITS - 1):0] remainder_data_from_div_buffer [(NUM_TEST_DIGIT - 1):0];
reg [(OPERAND_WIDTH_IN_BITS - 1):0] quotient_data_from_div_buffer [(NUM_TEST_DIGIT - 1):0];

reg [(NUM_TEST_DIGIT - 1):0] exception_match_array;
reg [(NUM_TEST_DIGIT - 1):0] remainder_sign_match_array;
reg [(NUM_TEST_DIGIT - 1):0] quotient_sign_match_array;
reg [(NUM_TEST_DIGIT - 1):0] remainder_data_match_array;
reg [(NUM_TEST_DIGIT - 1):0] quotient_data_match_array;

wire read_end_flag;
wire write_end_flag;

wire test_dividend_sign_from_array;
wire test_divisor_sign_from_array;
wire [(OPERAND_WIDTH_IN_BITS - 1):0] test_dividend_data_from_buffer;
wire [(OPERAND_WIDTH_IN_BITS - 1):0] test_divisor_data_from_buffer;

assign read_end_flag = (product_data_pointer == NUM_TEST_DIGIT);
assign write_end_flag = (operand_data_pointer == NUM_TEST_DIGIT);

assign test_divisor_sign_from_array = (write_end_flag)? 1'b0 : test_divisor_sign_array[operand_data_pointer];
assign test_dividend_sign_from_array = (write_end_flag)? 1'b0 : test_dividend_sign_array[operand_data_pointer];
assign test_divisor_data_from_buffer = (write_end_flag)? {(OPERAND_WIDTH_IN_BITS){1'b0}} : test_divisor_data_buffer[operand_data_pointer];
assign test_dividend_data_from_buffer = (write_end_flag)? {(OPERAND_WIDTH_IN_BITS){1'b0}} : test_dividend_data_buffer[operand_data_pointer];

//write
always @(posedge clk_in)
begin
    if (reset_in)
    begin
        divisor_to_div <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        dividend_to_div <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

        valid_to_div <= 1'b0;

        operand_data_pointer <= 5'b0;
    end
    else
    begin
        if (~write_end_flag)
        begin
            divisor_sign_to_div <= test_divisor_sign_from_array;
            dividend_sign_to_div <= test_dividend_sign_from_array;
            divisor_to_div <= test_divisor_data_from_buffer;
            dividend_to_div <= test_dividend_data_from_buffer;
            valid_to_div <= 1'b1;

            if (issue_ack_from_div)
            begin
                operand_data_pointer <= operand_data_pointer + 1'b1;
            end
        end
        else
        begin
            divisor_to_div <= 0;
            dividend_to_div <= 0;
            divisor_sign_to_div <= 1'b0;
            dividend_sign_to_div <= 1'b0;
            valid_to_div <= 1'b0;
        end
    end
end

//read
always @ (posedge clk_in)
begin
    if (reset_in)
    begin
        product_data_pointer <= 0;
        issue_ack_to_div <= 0;
    end
    else
    begin
        if (~read_end_flag)
        begin
            if (issue_ack_to_div)
            begin
                issue_ack_to_div <= 1'b0;
            end
            else
            begin
                if (valid_from_div)
                begin
                    issue_ack_to_div <= 1'b1;

                    exception_from_div_array[product_data_pointer] <= divide_by_zero_from_div;
                    remainder_sign_from_div_array[product_data_pointer] <= remainder_sign_from_div;
                    quotient_sign_from_div_array[product_data_pointer] <= quotient_sign_from_div;
                    remainder_data_from_div_buffer[product_data_pointer] <= remainder_from_div;
                    quotient_data_from_div_buffer[product_data_pointer] <= quotient_from_div;
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
        for (check_index = 0; check_index < NUM_TEST_DIGIT; check_index = check_index + 1)
        begin
            exception_match_array[check_index] <= (exception_from_div_array[check_index] == passed_exception_array[check_index]);
            remainder_sign_match_array[check_index] <= (remainder_sign_from_div_array[check_index] == passed_remainder_sign_array[check_index]);
            quotient_sign_match_array[check_index] <= (quotient_sign_from_div_array[check_index] == passed_quotient_sign_array[check_index]);
            remainder_data_match_array[check_index] <= (remainder_data_from_div_buffer[check_index] == passed_remainder_data_buffer[check_index]);
            quotient_data_match_array[check_index] <= (quotient_data_from_div_buffer[check_index] == passed_quotient_data_buffer[check_index]);
        end

        if ((&exception_match_array) & (&remainder_sign_match_array) & (&quotient_sign_match_array) & (&remainder_data_match_array) & (&quotient_data_match_array))
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

    for (operand_index = 0; operand_index < NUM_TEST_DIGIT; operand_index = operand_index + 1'b1)
    begin
        test_divisor_sign_array[operand_index] <= 0;
        test_dividend_sign_array[operand_index] <= 0;
        test_divisor_data_buffer[operand_index] <= 0;
        test_dividend_data_buffer[operand_index] <= 0;

        passed_exception_array[operand_index] <= 0;
        passed_remainder_data_buffer[operand_index] <= 0;
        passed_quotient_data_buffer[operand_index] <= 0;
        passed_quotient_sign_array[operand_index] <= 0;
        passed_remainder_sign_array[operand_index] <= 0;

        exception_from_div_array[operand_index] <= 0;
        remainder_data_from_div_buffer[operand_index] <= {(NUM_TEST_DIGIT){1'b1}};
        quotient_data_from_div_buffer[operand_index] <= {(NUM_TEST_DIGIT){1'b1}};
        remainder_sign_from_div_array[operand_index] <= 0;
        quotient_sign_from_div_array[operand_index] <= 0;


        exception_match_array[operand_index] <= 0;
        remainder_sign_match_array[operand_index] <= 0;
        quotient_sign_match_array[operand_index] <= 0;
        remainder_data_match_array[operand_index] <= 0;
        quotient_data_match_array[operand_index] <= 0;
    end

    // test case 0
    test_case <= 0;
    #(`FULL_CYCLE_DELAY * 5)
    for (operand_index = 0; operand_index < NUM_TEST_DIGIT; operand_index = operand_index + 1'b1)
    begin
        test_divisor_sign_array[operand_index] <= 0;
        test_dividend_sign_array[operand_index] <= 0;
        test_divisor_data_buffer[operand_index] <= operand_index * 3 + 1;
        test_dividend_data_buffer[operand_index] <= {(OPERAND_WIDTH_IN_BITS){1'b1}} - operand_index;
 
         passed_exception_array[operand_index] <= 0;
         passed_remainder_data_buffer[operand_index] <= ({(OPERAND_WIDTH_IN_BITS){1'b1}} - operand_index) % (operand_index * 3 + 1);
         passed_quotient_data_buffer[operand_index] <= ({(OPERAND_WIDTH_IN_BITS){1'b1}} - operand_index) / (operand_index * 3 + 1);
         passed_quotient_sign_array[operand_index] <= 0;
         passed_remainder_sign_array[operand_index] <= 0;       
                
         exception_from_div_array[operand_index] <= 0;
         remainder_data_from_div_buffer[operand_index] <= {(NUM_TEST_DIGIT){1'b1}};
         quotient_data_from_div_buffer[operand_index] <= {(NUM_TEST_DIGIT){1'b1}};
         remainder_sign_from_div_array[operand_index] <= 0;
         quotient_sign_from_div_array[operand_index] <= 0;
         
         exception_match_array[operand_index] <= 0;
         remainder_sign_match_array[operand_index] <= 0;
         quotient_sign_match_array[operand_index] <= 0;
         remainder_data_match_array[operand_index] <= 0;
         quotient_data_match_array[operand_index] <= 0;               
    end  

    #(`FULL_CYCLE_DELAY * 5)
    reset_in <= 1'b0;

    #(`FULL_CYCLE_DELAY * 4500) $display("[info-testbench] test case %d %40s : \t%s", test_case, "unsigned divide", test_judge ? "passed" : "failed");


    #(`FULL_CYCLE_DELAY * 5)  $display("\n[info-testbench] simulation for %m comes to the end\n");
                              $finish;

end

always begin #`HALF_CYCLE_DELAY clk_in                      <= ~clk_in; end

integer_divider
#(
    .OPERAND_WIDTH_IN_BITS(OPERAND_WIDTH_IN_BITS)
)
integer_divider
(
    .reset_in                                               (reset_in),
    .clk_in                                                 (clk_in),

    .valid_in                                               (valid_to_div),

    .dividend_sign_in                                       (dividend_sign_to_div),
    .dividend_in                                            (dividend_to_div),

    .divisor_sign_in                                        (divisor_sign_to_div),
    .divisor_in                                             (divisor_to_div),

    .issue_ack_out                                          (issue_ack_from_div),

    .valid_out                                              (valid_from_div),
    .remainder_sign_out                                     (remainder_sign_from_div),
    .remainder_out                                          (remainder_from_div),

    .quotient_sign_out                                      (quotient_sign_from_div),
    .quotient_out                                           (quotient_from_div),

    .issue_ack_in                                           (issue_ack_to_div),

    .divide_by_zero                                         (divide_by_zero_from_div)
);

endmodule
