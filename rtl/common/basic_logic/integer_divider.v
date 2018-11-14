module integer_divider
#(
    parameter OPERAND_WIDTH_IN_BITS                                                         = 64
)
(
    input                                                                                   reset_in,
    input                                                                                   clk_in,

    input                                                                                   valid_in,
    input                                                                                   dividend_sign_in,
    input [OPERAND_WIDTH_IN_BITS - 1 : 0]                                                   dividend_in,

    input                                                                                   divisor_sign_in,
    input [OPERAND_WIDTH_IN_BITS - 1 : 0]                                                   divisor_in,

    output reg                                                                              issue_ack_out,

    output reg                                                                              valid_out,
    output reg                                                                              remainder_sign_out,
    output reg [OPERAND_WIDTH_IN_BITS - 1 : 0]                                              remainder_out,

    output reg                                                                              quotient_sign_out,
    output reg [OPERAND_WIDTH_IN_BITS - 1 : 0]                                              quotient_out,

    output reg                                                                              divide_by_zero
);

parameter [31:0] stage_0                                                                    = 2'b00; //shift
parameter [31:0] stage_1                                                                    = 2'b01; //subtract the Divisor register from Remainder register
parameter [31:0] stage_2                                                                    = 2'b10; //test Remainder, write

parameter STATE_RESET = 2'b00;
parameter STATE_SHIFT = 2'b01;
parameter STATE_SUB = 2'b10;

wire [OPERAND_WIDTH_IN_BITS - 1 : 0]                                                        data_from_remainder_left_reg;
wire                                                                                        is_negative_to_control;

reg [1:0]                                                                                   state_ctr;
reg [31:0]                                                                                  remainder_reg_shift_ctr;

reg                                                                                         wait_to_busy_flag;
reg                                                                                         division_is_finished_flag;
reg                                                                                         output_clear_flag;

reg                                                                                         dividend_sign_reg;
reg                                                                                         divisor_sign_reg;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0]                                                         divisor_reg;
reg [OPERAND_WIDTH_IN_BITS * 2 : 0]                                                         remainder_reg;

wire [OPERAND_WIDTH_IN_BITS : 0]                                                             subtract_result_to_remainder;

assign data_from_remainder_left_reg                                                         = remainder_reg[OPERAND_WIDTH_IN_BITS * 2 - 1 : OPERAND_WIDTH_IN_BITS];
assign subtract_result_to_remainder                                                         = {1'b0, data_from_remainder_left_reg} - {1'b0, divisor_reg};
assign is_negative_to_control                                                               = subtract_result_to_remainder[OPERAND_WIDTH_IN_BITS];

//idle to busy & busy to idle
always@(posedge clk_in)
begin
    if (reset_in)
    begin
        is_valid_out                                                                        <= 1'b0;
        // is_ready_out                                                                        <= 1'b1;

        wait_to_busy_flag                                                                   <= 1'b1;
        division_is_finished_flag                                                           <= 1'b0;
        output_clear_flag                                                                   <= 1'b0;

        remainder_reg_shift_ctr                                                             <= 32'b0;

        divisor_sign_reg                                                                    <= 1'b0;
        dividend_sign_reg                                                                   <= 1'b0;

        divisor_reg                                                                         <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        remainder_reg                                                                       <= {(OPERAND_WIDTH_IN_BITS * 2 + 1){1'b0}};

        remainder_sign_out                                                                  <= 1'b0;
        remainder_out                                                                       <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

        quotient_sign_out                                                                   <= 1'b0;
        quotient_out                                                                        <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
    end
    else
    begin

        //clear output register
        if (output_clear_flag)
        begin
            is_ready_out                                                                    <= 1'b1;

            output_clear_flag                                                               <= 1'b0;

            is_valid_out                                                                    <= 1'b0;

            remainder_sign_out                                                              <= 1'b0;
            quotient_sign_out                                                               <= 1'b0;

            remainder_out                                                                   <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
            quotient_out                                                                    <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        end

        //idle to busy
        if (is_valid_in)
        begin
            if (wait_to_busy_flag)
            begin
                is_ready_out                                                                    <= 1'b0;

                divisor_sign_reg                                                                <= divisor_sign_in;
                dividend_sign_reg                                                               <= dividend_sign_in;

                divisor_reg                                                                     <= divisor_in;
                remainder_reg                                                                   <= {{1'b0}, {(OPERAND_WIDTH_IN_BITS){1'b0}}, dividend_in};
            end
        end

        //busy to idle
        else if ((remainder_reg_shift_ctr == OPERAND_WIDTH_IN_BITS))
        begin
            is_valid_out                                                                    <= 1'b1;

            output_clear_flag                                                               <= 1'b1;
            remainder_reg_shift_ctr                                                         <= 32'b0;

            //write output reg
            quotient_sign_out                                                               <= divisor_sign_reg ^ dividend_sign_reg;
            remainder_sign_out                                                              <= divisor_sign_reg;

            remainder_out                                                                   <= data_from_remainder_left_reg[OPERAND_WIDTH_IN_BITS - 1 : 0];
            quotient_out                                                                    <= remainder_reg[OPERAND_WIDTH_IN_BITS - 1 : 0];

            //clear reg
            divisor_sign_reg                                                                <= 1'b0;
            dividend_sign_reg                                                               <= 1'b0;

            divisor_reg                                                                     <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
            remainder_reg                                                                   <= {(OPERAND_WIDTH_IN_BITS * 2 + 1){1'b0}};

        end
    end
end

//control
/*
always@(posedge clk_in)
begin
    if (reset_in)
    begin

    end
    else
    begin
        if (~ is_ready_out)
        begin
            case (state_ctr)
            stage_0:begin
                //shift
                remainder_reg                                                               <= remainder_reg << 1;
            end
            stage_1:begin
                subtract_result_to_remainder                                                <= {1'b1, data_from_remainder_left_reg} - {1'b0, divisor_reg};
            end
            stage_2:begin
                //write
                if (~ is_negative_to_control)
                begin
                    remainder_reg[OPERAND_WIDTH_IN_BITS * 2 - 1 : OPERAND_WIDTH_IN_BITS]    <= subtract_result_to_remainder;
                end
                //update
                remainder_reg[0]                                                            <= is_negative_to_control? 1'b0 : 1'b1;
                remainder_reg_shift_ctr                                                     <= remainder_reg_shift_ctr + 1'b1;
            end
            endcase
        end
    end
end
*/

always @ ( * )
begin
    case (state_ctr)
        STATE_SHIFT: begin
            remainder_reg                                                               <= remainder_reg << 1;
            remainder_reg_shift_ctr                                                     <= remainder_reg_shift_ctr + 1'b1;
        end

        STATE_SUB: begin
            //write
            if (~ is_negative_to_control)
            begin
                remainder_reg[OPERAND_WIDTH_IN_BITS * 2 - 1 : OPERAND_WIDTH_IN_BITS]    <= subtract_result_to_remainder;
            end
            //update
            remainder_reg[0]                                                            <= is_negative_to_control? 1'b0 : 1'b1;
        end

        default: ;
    endcase
end

//stage counter
/*
always@(posedge clk_in)
begin
    if (reset_in | is_ready_out)
    begin
        state_ctr                                                                           <= 1'b0;
    end
    else
    begin
        if (state_ctr == 2'b10)
        begin
            state_ctr                                                                       <= 2'b00;
        end
        else
        begin
            state_ctr                                                                       <= state_ctr + 1'b1;
        end
    end
end
*/

always @(posedge clk_in)
begin
    if (reset_in)
    begin
        state_ctr <= STATE_RESET;
    end
    else
    begin
        case (state_ctr)
            STATE_RESET: begin
                state_ctr <= STATE_SHIFT;
            end

            STATE_SHIFT: begin
                state_ctr <= STATE_SUB;
            end

            STATE_SUB: begin
                state_ctr <= STATE_SHIFT;
            end
        endcase
    end
end

endmodule
