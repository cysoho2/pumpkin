`include parameters.h

module float_point_adder
#(
    parameter OPERAND_EXPONENT_WIDTH_IN_BITS = `DOUBLE_POINT_NUMBER_EXPONENT_WIDTH_IN_BITS,
    parameter OPERAND_FRACTION_WIDTH_IN_BITS = `DOUBLE_POINT_NUMBER_FRACTION_WIDTH_IN_BITS
)
(
    input                                                   reset_in,
    input                                                   clk_in,

    input                                                   operantion_mode_in,
    input                                                   float_point_precision_in,

    input                                                   operand_0_valid_in,
    input                                                   operand_0_sign_in,
    input       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    operand_0_exponent_in,
    input       [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]    operand_0_fraction_in,

    input                                                   operand_1_valid_in,
    input                                                   operand_1_sign_in,
    input       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    operand_1_exponent_in,
    input       [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]    operand_1_fraction_in,

    output reg                                              issue_ack_out,

    output reg                                              product_valid_out,
    output reg                                              product_sign_out,
    output reg  [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    product_exponent_out,
    output reg  [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]    product_fraction_out,

    input                                                   issue_ack_in
);

parameter ROUND_TYPE = "CHOP",

parameter EXTENDED_FRACTION_WIDTH_IN_BITS = OPERAND_FRACTION_WIDTH_IN_BITS * 2 + 2;
parameter NUMBER_ROUND_INPUT_WIDTH_IN_BITS = EXTENDED_FRACTION_WIDTH_IN_BITS;
parameter NUMBER_ROUND_OUTPUT_WIDTH_IN_BITS = OPERAND_FRACTION_WIDTH_IN_BITS + 1;

parameter ADD_OPERANTION = 0;
parameter SUB_OPERANTION = 1;

parameter STATE_WAIT_RESET  = 0;
parameter STATE_PRE_SHIFT   = 1;
parameter STATE_COMPUTE     = 2;
parameter STATE_POST_SHIFT  = 3;

reg                                                   operantion_mode_buffer,

reg                                                   operand_0_sign_buffer;
reg       [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]    operand_0_fraction_buffer;

reg                                                   operand_1_sign_buffer;
reg       [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]    operand_1_fraction_buffer;

reg       [1:0] ctrl_state;

reg       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    baseline_exponent_buffer;
reg       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    fraction_pre_shift_len_buffer;

reg       [(EXTENDED_FRACTION_WIDTH_IN_BITS):0]       rounded_product_buffer;
reg                                                   product_sign_buffer;

//control sign
reg       operand_buffer_write_enable;
reg       baseline_exponent_write_enable;
reg       fraction_pre_shift_len_write_enable;

reg       rounded_product_buffer_write_enable;
reg       product_sign_buffer_write_enable;

reg       product_output_write_enable;
reg       clear_output_enable;

wire      [(`FLOAT_POINT_NUMBER_FORMAT_WIDTH - 1):0]  opearand_0_float_point_classify_out;
wire      [(`FLOAT_POINT_NUMBER_FORMAT_WIDTH - 1):0]  opearand_1_float_point_classify_out;

wire      valid_input_flag;

wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    difference_of_exponents;
wire                                                  operand_0_exponent_is_larger;
wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    data_to_baseline_exponent_buffer;
wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    data_to_fraction_pre_shift_len_buffer;

wire      [(EXTENDED_FRACTION_WIDTH_IN_BITS - 1):0]   extended_operand_0_fraction;
wire      [(EXTENDED_FRACTION_WIDTH_IN_BITS - 1):0]   extended_operand_1_fraction;
wire      [(EXTENDED_FRACTION_WIDTH_IN_BITS - 1):0]   extended_product_fraction;
wire      overflow_bit_in_extended_product_fraction;

wire      [(OPERAND_FRACTION_WIDTH_IN_BITS):0]        data_to_rounded_product_buffer;
wire                                                  data_to_product_sign_buffer;

wire                                                  data_to_product_sign_out;
wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    data_to_product_exponent_out;
wire      [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]    data_to_product_fraction_out;


assign    valid_input_flag = operand_0_valid_in & operand_1_valid_in;

assign    difference_of_exponents = operand_0_exponent_in - operand_1_exponent_in;
assign    operand_0_exponent_is_larger = ~ difference_of_exponents[(OPERAND_EXPONENT_WIDTH_IN_BITS - 1'b1)];
assign    data_to_baseline_exponent_buffer = (operand_0_exponent_is_larger)? operand_0_exponent_in : operand_1_exponent_in;
assign    data_to_fraction_pre_shift_len_buffer = (operand_0_exponent_is_larger)? difference_of_exponents : ~(difference_of_exponents - 1'b1);

assign    extended_operand_0_fraction = (operand_0_exponent_is_larger)? operand_0_fraction_buffer : (operand_0_fraction_buffer >> data_to_fraction_pre_shift_len_buffer);
assign    extended_operand_1_fraction = (~operand_0_exponent_is_larger)? operand_1_fraction_buffer : (operand_1_fraction_buffer >> data_to_fraction_pre_shift_len_buffer);
assign    extended_product_fraction = (operantion_mode_buffer == ADD_OPERANTION) ? (extended_operand_0_fraction + extended_operand_1_fraction) : (extended_operand_0_fraction - extended_operand_1_fraction);
assign    overflow_bit_in_extended_product_fraction = extended_product_fraction[(EXTENDED_FRACTION_WIDTH_IN_BITS - 1)];

assign    data_to_product_sign_buffer = (operand_0_exponent_is_larger)? operand_0_sign_buffer;

assign    data_to_product_sign_out = ;
assign    data_to_product_exponent_out;
assign    data_to_product_fraction_out;

//input
always @(posedge clk_in)
begin
    if (reset_in)
    begin
        operantion_mode_buffer  <= 1'b0;

        operand_0_sign_buffer <= 1'b0;
        operand_0_fraction_buffer <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};

        operand_1_sign_buffer <= 1'b0;
        operand_1_fraction_buffer <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};

        baseline_exponent_buffer <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};
        fraction_pre_shift_len_buffer <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};

        rounded_product_buffer <= {(EXTENDED_FRACTION_WIDTH_IN_BITS){1'b0}};

        product_sign_out <= 1'b0;
        product_exponent_out <= {(OPERAND_EXPONENT_WIDTH_IN_BITS){1'b0}};
        product_fraction_out <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};
    end
    else
    begin
        if (operand_buffer_write_enable)
        begin
            operantion_mode_buffer <= operantion_mode_in;

            operand_0_sign_buffer <= operand_0_sign_in;
            operand_0_fraction_buffer <= operand_0_fraction_in;

            operand_1_sign_buffer <= operand_1_sign_in;
            operand_1_fraction_buffer <= operand_1_fraction_in;
        end

        if (baseline_exponent_write_enable)
        begin
            baseline_exponent_buffer <= data_to_baseline_exponent_buffer;
        end

        if (fraction_pre_shift_len_write_enable)
        begin
            fraction_pre_shift_len_buffer  <= data_to_fraction_pre_shift_len_buffer;
        end

        if (rounded_product_buffer_write_enable)
        begin
            rounded_product_buffer <= data_to_rounded_product_buffer;
        end

        if (product_sign_buffer_write_enable)
        begin
            product_sign_buffer <= data_to_product_sign_buffer;
        end

        if (product_output_write_enable)
        begin
            product_sign_out <= data_to_product_sign_out;
            product_exponent_out <= data_to_product_exponent_out;
            product_fraction_out <= data_to_product_fraction_out;
        end
    end
end

//Exception


//State Machine
always @(posedge clk_in)
begin
    if (reset_in)
    begin
        ctrl_state <= STATE_RESET;
    end
    else
    begin
        case (ctrl_state)
            STATE_RESET: begin
                ctrl_state <= STATE_PRE_SHIFT;
            end

            STATE_PRE_SHIFT: begin
                if (valid_input_flag)
                begin
                    ctrl_state <= STATE_COMPUTE;
                end
                else
                begin
                    ctrl_state <= ctrl_state;
                end
            end

            STATE_COMPUTE: begin
                ctrl_state <= STATE_POST_SHIFT;
            end

            STATE_POST_SHIFT: begin
                if (issue_ack_in)
                begin
                    ctrl_state <= STATE_PRE_SHIFT;
                end
            end

            default: begin
                ctrl_state <= STATE_RESET;
            end

        endcase
    end
end

//Control Sign
always @ ( * )
begin
    case (ctrl_state)
        STATE_RESET: begin
            issue_ack_out                           <= 1'b0;

            operand_buffer_write_enable             <= 1'b0;
            baseline_exponent_write_enable          <= 1'b0;
            fraction_pre_shift_len_write_enable     <= 1'b0;

            rounded_product_buffer_write_enable     <= 1'b0;
            product_sign_buffer_write_enable        <= 1'b0;

            product_output_write_enable             <= 1'b0;
            clear_output_enable                     <= 1'b1;
        end

        STATE_PRE_SHIFT: begin
            issue_ack_out                           <= 1'b1;

            operand_buffer_write_enable             <= 1'b1;
            baseline_exponent_write_enable          <= 1'b1;
            fraction_pre_shift_len_write_enable     <= 1'b1;

            rounded_product_buffer_write_enable     <= 1'b0;
            product_sign_buffer_write_enable        <= 1'b0;

            product_output_write_enable             <= 1'b0;
            clear_output_enable                     <= 1'b1;
        end

        STATE_COMPUTE: begin
            issue_ack_out                           <= 1'b0;

            operand_buffer_write_enable             <= 1'b0;
            baseline_exponent_write_enable          <= 1'b0;
            fraction_pre_shift_len_write_enable     <= 1'b0;

            rounded_product_buffer_write_enable     <= 1'b1;
            product_sign_buffer_write_enable        <= 1'b1;

            product_output_write_enable             <= 1'b0;
            clear_output_enable                     <= 1'b1;
        end

        STATE_POST_SHIFT: begin
            issue_ack_out                           <= 1'b0;

            operand_buffer_write_enable             <= 1'b0;
            baseline_exponent_write_enable          <= 1'b0;
            fraction_pre_shift_len_write_enable     <= 1'b0;

            rounded_product_buffer_write_enable     <= 1'b0;
            product_sign_buffer_write_enable        <= 1'b0;

            product_output_write_enable             <= 1'b1;
            clear_output_enable                     <= 1'b0;
        end

        default: begin
            issue_ack_out                           <= 1'b0;

            operand_buffer_write_enable             <= 1'b0;
            baseline_exponent_write_enable          <= 1'b0;
            fraction_pre_shift_len_write_enable     <= 1'b0;

            rounded_product_buffer_write_enable     <= 1'b0;
            product_sign_buffer_write_enable        <= 1'b0;

            product_output_write_enable             <= 1'b0;
            clear_output_enable                     <= 1'b1;
        end
    endcase
end

float_point_classify
#(
	.FLOAT_POINT_EXPONENT_WIDTH_IN_BITS(`DOUBLE_FLOAT_POINT_EXPONENT_WIDTH_IN_BITS),
    .FLOAT_POINT_FRACTION_WIDTH_IN_BITS(`DOUBLE_FLOAT_POINT_FRACTION_WIDTH_IN_BITS)
)
float_point_classify_operand_0
(
    .float_point_precision_in(float_point_precision_in),

    .float_point_sign_bit_in(operand_0_sign_in),
    .float_point_exponent_in(operand_0_exponent_in),
    .float_point_fraction_in(operand_0_fraction_in),

	.float_point_classify_out(opearand_0_float_point_classify_out)
);

float_point_classify
#(
	.FLOAT_POINT_EXPONENT_WIDTH_IN_BITS(`DOUBLE_FLOAT_POINT_EXPONENT_WIDTH_IN_BITS),
    .FLOAT_POINT_FRACTION_WIDTH_IN_BITS(`DOUBLE_FLOAT_POINT_FRACTION_WIDTH_IN_BITS)
)
float_point_classify_operand_1
(
    .float_point_precision_in(float_point_precision_in),

    .float_point_sign_bit_in(operand_1_sign_in),
    .float_point_exponent_in(operand_1_exponent_in),
    .float_point_fraction_in(operand_1_fraction_in),

	.float_point_classify_out(opearand_1_float_point_classify_out)
);

number_round
#(
    .INPUT_WIDTH_IN_BITS(NUMBER_ROUND_INPUT_WIDTH_IN_BITS),
    .OUTPUT_WIDTH_IN_BITS(NUMBER_ROUND_OUTPUT_WIDTH_IN_BITS), //output width should be smaller than input width
    .ROUND_TYPE(ROUND_TYPE)
)
number_round
(
    .original_data_in(extended_product_fraction),
    .rounded_data_out(data_to_rounded_product_buffer);
);

endmodule
