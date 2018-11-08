;`include parameters.h



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

													    input       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    ;`include parameters.h

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

parameter ADD_OPERANTION = 0;
parameter SUB_OPERANTION = 1;

parameter STATE_WAIT_INPUT  = 0;
parameter STATE_PRE_SHIFT   = 1;
parameter STATE_COMPUTE     = 2;
parameter STATE_POST_SHIFT  = 3;

reg                                                   operand_0_sign_buffer;
reg       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    operand_0_exponent_buffer;
reg       [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]    operand_0_fraction_buffer;

reg                                                   operand_1_sign_buffer;
reg       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    operand_1_exponent_buffer;
reg       [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]    operand_1_fraction_buffer;

reg       [1:0] ctrl_state;

reg       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    baseline_exponent_buffer;
reg       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    fraction_pre_shift_len;

//control sign
wire      input_enable;

wire      operand_buffer_write_enable;
wire      baseline_exponent_write_enable;
wire      fraction_pre_shift_len_write_enable;

wire      rounded_product_buffer_write_enable;

wire      sign_out_write_enable;
wire      exponent_out_write_enable;
wire      fraction_out_write_enable;
wire      clear_output_enable;



wire                                                  operand_0_exponent_is_larger;
wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    difference_of_exponents;
wire      [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]    data_to_baseline_exponent_buffer;

assign    difference_of_exponents = operand_0_exponent_in - operand_1_exponent_in;
assign    operand_0_exponent_is_larger = ~ difference_of_exponents[(OPERAND_EXPONENT_WIDTH_IN_BITS - 1)];
assign    data_to_baseline_exponent_buffer = (operand_0_exponent_is_larger)? operand_0_exponent_in : operand_1_exponent_in;

//input
always @(posedge clk_in)
begin
    if (reset_in)
    begin
        operand_0_sign_buffer <= 1'b0;
        operand_0_exponent_buffer <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};
        operand_0_fraction_buffer <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};

        operand_1_sign_buffer <= 1'b0;
        operand_1_exponent_buffer <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};
        operand_1_fraction_buffer <= {(OPERAND_FRACTION_WIDTH_IN_BITS){1'b0}};
    end
    else
    begin
        if (issue_ack_out)
        begin
            issue_ack_out <= 1'b0;
        end
        else
        begin
            if (input_enable)
            begin
                if (operand_0_valid_in & operand_1_valid_in)
                begin
                    issue_ack_out <= 1'b1;

                    operand_0_sign_buffer <= operand_0_sign_in;
                    operand_0_exponent_buffer <= operand_0_exponent_in;
                    operand_0_fraction_buffer <= operand_0_fraction_in;

                    operand_1_sign_buffer <= operand_1_sign_in;
                    operand_1_exponent_buffer <= operand_1_exponent_in;
                    operand_1_fraction_buffer <= operand_1_fraction_in;
                end
            end
            else
            begin
                issue_ack_out <= issue_ack_out;

                operand_0_sign_buffer <= operand_0_sign_buffer;
                operand_0_exponent_buffer <= operand_0_exponent_buffer;
                operand_0_fraction_buffer <= operand_0_fraction_buffer;

                operand_1_sign_buffer <= operand_1_sign_buffer;
                operand_1_exponent_buffer <= operand_1_exponent_buffer;
                operand_1_fraction_buffer <= operand_1_fraction_buffer;
            end
        end
    end
end




//control logic
always @(posedge clk_in)
begin
    if (reset_in)
    begin
        ctrl_state <= 0;
    end
    else
    begin
        case (ctrl_state)
            STATE_WAIT_INPUT: begin
                if (issue_ack_out)
                begin
                    ctrl_state <= ctrl_state + 1'b1;
                end
            end

            STATE_PRE_SHIFT: begin

            end

            STATE_COMPUTE: begin

            end

            STATE_POST_SHIFT: begin
                if (issue_ack_in)
                begin
                    ctrl_state <= 0;
                end
            end

            default: begin
                ctrl_state <= 0;
            end

        endcase
    end
end


number_round
#(
    parameter INPUT_WIDTH_IN_BITS = 32,
    parameter OUTPUT_WIDTH_IN_BITS = 16, //output width should be smaller than input width
    parameter ROUND_TYPE = "CHOP"
)
number_round
(
    input [(INPUT_WIDTH_IN_BITS - 1):0] original_data_in;

    output reg is_rounded;
    output reg [(OUTPUT_WIDTH_IN_BITS - 1):0] rounded_data_out;
);

endmodule

				)
	)`
