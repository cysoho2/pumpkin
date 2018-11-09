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
    output reg  [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    product_fraction_out,

    input                                                   issue_ack_in,
);

parameter ROUND_TYPE = "CHOP",


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

//control sign
reg       operand_buffer_write_enable;
reg       baseline_exponent_write_enable;
reg       fraction_pre_shift_len_write_enable;

reg       rounded_product_buffer_write_enable;

reg       sign_out_write_enable;
reg       exponent_out_write_enable;
reg       fraction_out_write_enable;
reg       clear_output_enable;


wire      valid_input_flag;

wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    difference_of_exponents;

wire                                                  operand_0_exponent_is_larger;
wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    data_to_baseline_exponent_buffer;

wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    data_to_fraction_pre_shift_len_buffer;


assign    valid_input_flag = operand_0_valid_in & operand_1_valid_in;

assign    difference_of_exponents = operand_0_exponent_in - operand_1_exponent_in;

assign    operand_0_exponent_is_larger = ~ difference_of_exponents[(OPERAND_EXPONENT_WIDTH_IN_BITS - 1'b1)];
assign    data_to_baseline_exponent_buffer = (operand_0_exponent_is_larger)? operand_0_exponent_in : operand_1_exponent_in;

assign    data_to_fraction_pre_shift_len_buffer = (operand_0_exponent_is_larger)? difference_of_exponents : ~(difference_of_exponents - 1'b1);

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
            fraction_pre_shift_len_buffer  <= data_to_baseline_exponent_buffer;
        end
    end
end




//control logic
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
                ctrl_state <= STATE_PRE_SHIFT
            end

            default: begin
                ctrl_state <= STATE_RESET;
            end

        endcase
    end
end

//state machine
always @ ( * )
begin
    case (ctrl_state)
        STATE_RESET: begin
            issue_ack_out                           <= 1'b0;

            operand_buffer_write_enable             <= 1'b0;
            baseline_exponent_write_enable          <= 1'b0;
            fraction_pre_shift_len_write_enable     <= 1'b0;

            rounded_product_buffer_write_enable     <= 1'b0;

            sign_out_write_enable                   <= 1'b0;
            exponent_out_write_enable               <= 1'b0;
            fraction_out_write_enable               <= 1'b0;
            clear_output_enable                     <= 1'b0;
        end

        STATE_PRE_SHIFT: begin
            issue_ack_out                           <= 1'b1;

            operand_buffer_write_enable             <= 1'b1;
            baseline_exponent_write_enable          <= 1'b1;
            fraction_pre_shift_len_write_enable     <= 1'b1;

            rounded_product_buffer_write_enable     <= 1'b0;

            sign_out_write_enable                   <= 1'b0;
            exponent_out_write_enable               <= 1'b0;
            fraction_out_write_enable               <= 1'b0;
            clear_output_enable                     <= 1'b0;
        end

        STATE_COMPUTE: begin
            issue_ack_out                           <= 1'b0;

            operand_buffer_write_enable             <= 1'b0;
            baseline_exponent_write_enable          <= 1'b0;
            fraction_pre_shift_len_write_enable     <= 1'b0;

            rounded_product_buffer_write_enable     <= 1'b1;

            sign_out_write_enable                   <= 1'b0;
            exponent_out_write_enable               <= 1'b0;
            fraction_out_write_enable               <= 1'b0;
            clear_output_enable                     <= 1'b0;
        end

        STATE_POST_SHIFT: begin
            issue_ack_out                           <= 1'b0;

            operand_buffer_write_enable             <= 1'b0;
            baseline_exponent_write_enable          <= 1'b0;
            fraction_pre_shift_len_write_enable     <= 1'b0;

            rounded_product_buffer_write_enable     <= 1'b0;

            sign_out_write_enable                   <= 1'b1;
            exponent_out_write_enable               <= 1'b1;
            fraction_out_write_enable               <= 1'b1;
            clear_output_enable                     <= 1'b1;
        end

        default: begin
            issue_ack_out                           <= 1'b0;

            operand_buffer_write_enable             <= 1'b0;
            baseline_exponent_write_enable          <= 1'b0;
            fraction_pre_shift_len_write_enable     <= 1'b0;

            rounded_product_buffer_write_enable     <= 1'b0;

            sign_out_write_enable                   <= 1'b0;
            exponent_out_write_enable               <= 1'b0;
            fraction_out_write_enable               <= 1'b0;
            clear_output_enable                     <= 1'b0;
        end
    endcase
end

number_round
#(
    .INPUT_WIDTH_IN_BITS(),
    .OUTPUT_WIDTH_IN_BITS(), //output width should be smaller than input width
    .ROUND_TYPE()
)
number_round
(
    .original_data_in(),
    .rounded_data_out();
);

endmodule
