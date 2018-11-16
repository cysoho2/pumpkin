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

    input                                                                                   issue_ack_in,

    output reg                                                                              divide_by_zero
);

//parameter [31:0] stage_0                                                                    = 2'b00; //shift
//parameter [31:0] stage_1                                                                    = 2'b01; //subtract the Divisor register from Remainder register
//parameter [31:0] stage_2                                                                    = 2'b10; //test Remainder, write

`define STATE_RESET 3'b000
`define STATE_INPUT 3'b001
`define STATE_SHIFT 3'b010
`define STATE_SUB 3'b011
`define STATE_OUTPUT 3'b100
`define STATE_EXCEPTION 3'b101

wire [OPERAND_WIDTH_IN_BITS - 1 : 0]                                                        data_from_remainder_left_reg;
wire                                                                                        is_negative_to_control;

reg [2:0]                                                                                   state_ctr;
reg [31:0]                                                                                  remainder_reg_shift_ctr;

reg                                                                                         wait_to_idle_flag;
reg                                                                                         wait_to_busy_flag;
reg                                                                                         division_is_finished_flag;
reg                                                                                         output_clear_flag;

reg                                                                                         dividend_sign_reg;
reg                                                                                         divisor_sign_reg;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0]                                                         divisor_reg;
reg [OPERAND_WIDTH_IN_BITS * 2 : 0]                                                         remainder_reg;

reg state_reset_flag;
reg state_input_flag;
reg state_shift_flag;
reg state_sub_flag;
reg state_output_flag;
reg state_exception_flag;

wire [OPERAND_WIDTH_IN_BITS : 0]                                                             subtract_result_to_remainder;

wire div_by_zero_flag;
wire output_enable;

assign data_from_remainder_left_reg                                                         = remainder_reg[OPERAND_WIDTH_IN_BITS * 2 - 1 : OPERAND_WIDTH_IN_BITS];
assign subtract_result_to_remainder                                                         = {1'b0, data_from_remainder_left_reg} - {1'b0, divisor_reg};
assign is_negative_to_control                                                               = subtract_result_to_remainder[OPERAND_WIDTH_IN_BITS];

assign div_by_zero_flag                                                                     = ~(| divisor_in);
assign output_enable                                                                        = (remainder_reg_shift_ctr == OPERAND_WIDTH_IN_BITS);

//idle to busy & busy to idle
//always@(posedge clk_in)
//begin
//    if (reset_in)
//    begin
        // valid_out                                                                        <= 1'b0;
        // // wait_to_busy_flag                                                                        <= 1'b1;
        //
        // wait_to_busy_flag                                                                   <= 1'b1;
        // division_is_finished_flag                                                           <= 1'b0;
        // output_clear_flag                                                                   <= 1'b0;
        //
        // remainder_reg_shift_ctr                                                             <= 32'b0;
        //
        // divisor_sign_reg                                                                    <= 1'b0;
        // dividend_sign_reg                                                                   <= 1'b0;
        //
        // divisor_reg                                                                         <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        // remainder_reg                                                                       <= {(OPERAND_WIDTH_IN_BITS * 2 + 1){1'b0}};
        //
        // remainder_sign_out                                                                  <= 1'b0;
        // remainder_out                                                                       <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        //
        // quotient_sign_out                                                                   <= 1'b0;
        // quotient_out                                                                        <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
//    end
//    else
//    begin

        //clear output register
        // if (output_clear_flag)
        // begin
        //     wait_to_busy_flag                                                               <= 1'b1;
        //
        //     output_clear_flag                                                               <= 1'b0;
        //
        //     valid_out                                                                       <= 1'b0;
        //
        //     remainder_sign_out                                                              <= 1'b0;
        //     quotient_sign_out                                                               <= 1'b0;
        //
        //     remainder_out                                                                   <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        //     quotient_out                                                                    <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        // end


        //idle to busy
        // if (valid_in)
        // begin
        //
        //     if (wait_to_busy_flag)
        //     begin
        //
        //         wait_to_busy_flag                                                                    <= 1'b0;
        //         issue_ack_out                                                                   <= 1'b1;
        //
        //         divisor_sign_reg                                                                <= divisor_sign_in;
        //         dividend_sign_reg                                                               <= dividend_sign_in;
        //
        //         divisor_reg                                                                     <= divisor_in;
        //         remainder_reg                                                                   <= {{1'b0}, {(OPERAND_WIDTH_IN_BITS){1'b0}}, dividend_in};
        //     end
        // end

        //busy to idle
        // else if ((remainder_reg_shift_ctr == OPERAND_WIDTH_IN_BITS))
        // begin
        //
        //     if (wait_to_idle_flag)
        //     begin
        //         if (issue_ack_in)
        //         begin
        //             output_clear_flag                                                               <= 1'b1;
        //             remainder_reg_shift_ctr                                                         <= 32'b0;
        //         end
        //     end
        //     else
        //     begin
        //         valid_out                                                                    <= 1'b1;
        //
        //         //write output reg
        //         quotient_sign_out                                                               <= divisor_sign_reg ^ dividend_sign_reg;
        //         remainder_sign_out                                                              <= divisor_sign_reg;
        //
        //         remainder_out                                                                   <= data_from_remainder_left_reg[OPERAND_WIDTH_IN_BITS - 1 : 0];
        //         quotient_out                                                                    <= remainder_reg[OPERAND_WIDTH_IN_BITS - 1 : 0];
        //
        //         //clear reg
        //         divisor_sign_reg                                                                <= 1'b0;
        //         dividend_sign_reg                                                               <= 1'b0;
        //
        //         divisor_reg                                                                     <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        //         remainder_reg                                                                   <= {(OPERAND_WIDTH_IN_BITS * 2 + 1){1'b0}};
        //     end
        //
        // end
//     end
// end

//control


// always @ (posedge clk_in)
// begin
//     if (reset_in)
//     begin
//
//     end
//     else
//     begin
        // case (state_ctr)
            // `STATE_SHIFT: begin
            //     if (~wait_to_idle_flag)
            //     begin
            //         remainder_reg                                                               <= remainder_reg << 1;
            //         remainder_reg_shift_ctr                                                     <= remainder_reg_shift_ctr + 1'b1;
            //     end
            // end

            // `STATE_SUB: begin
            //     if (~wait_to_idle_flag)
            //     begin
            //         //write
            //         if (~ is_negative_to_control)
            //         begin
            //             remainder_reg[OPERAND_WIDTH_IN_BITS * 2 - 1 : OPERAND_WIDTH_IN_BITS]    <= subtract_result_to_remainder;
            //         end
            //         //update
            //         remainder_reg[0]                                                            <= is_negative_to_control? 1'b0 : 1'b1;
            //     end
            // end

            // `STATE_EXCEPTION: begin
            //     valid_out                                                                    <= 1'b1;
            //
            //     //write output reg
            //     quotient_sign_out                                                               <= 0;
            //     remainder_sign_out                                                              <= 0;
            //
            //     remainder_out                                                                   <= 0;
            //     quotient_out                                                                    <= 0;
            //
            //     //clear reg
            //     divisor_sign_reg                                                                <= 1'b0;
            //     dividend_sign_reg                                                               <= 1'b0;
            //
            //     divisor_reg                                                                     <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
            //     remainder_reg                                                                   <= {(OPERAND_WIDTH_IN_BITS * 2 + 1){1'b0}};
            //
            //     divide_by_zero                                                                  <= 1'b1;
            // end

        //     default: begin
        //         state_ctr <= `STATE_RESET;
        //     end
        // endcase
//     end
// end

always @ (posedge clk_in)
begin
    if (reset_in)
    begin
        valid_out                                                                        <= 1'b0;
        // wait_to_busy_flag                                                                        <= 1'b1;

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
        if (issue_ack_out)
        begin
            issue_ack_out <= 1'b0;
        end

        if (state_reset_flag)
        begin

        end

        if (state_input_flag)
        begin
            if (valid_in)
            begin
                if (wait_to_busy_flag)
                begin
                    wait_to_busy_flag                                                               <= 1'b0;
                    issue_ack_out                                                                   <= 1'b1;

                    divisor_sign_reg                                                                <= divisor_sign_in;
                    dividend_sign_reg                                                               <= dividend_sign_in;

                    divisor_reg                                                                     <= divisor_in;
                    remainder_reg                                                                   <= {{1'b0}, {(OPERAND_WIDTH_IN_BITS){1'b0}}, dividend_in};
                end
            end
        end

        if (state_shift_flag)
        begin
            remainder_reg                                                                           <= remainder_reg << 1;
            remainder_reg_shift_ctr                                                                 <= remainder_reg_shift_ctr + 1'b1;
        end

        if (state_sub_flag)
        begin
            if (~ is_negative_to_control)
            begin
                remainder_reg[OPERAND_WIDTH_IN_BITS * 2 - 1 : OPERAND_WIDTH_IN_BITS]    <= subtract_result_to_remainder;
            end
            //update
            remainder_reg[0]                                                            <= is_negative_to_control? 1'b0 : 1'b1;
        end

        if (state_output_flag)
        begin
            valid_out                                                                    <= 1'b1;

            //write output reg
            quotient_sign_out                                                               <= divisor_sign_reg ^ dividend_sign_reg;
            remainder_sign_out                                                              <= divisor_sign_reg;

            remainder_out                                                                   <= data_from_remainder_left_reg[OPERAND_WIDTH_IN_BITS - 1 : 0];
            quotient_out                                                                    <= remainder_reg[OPERAND_WIDTH_IN_BITS - 1 : 0];

            divide_by_zero                                                                  <= 1'b0;

            //clear reg
            divisor_sign_reg                                                                <= 1'b0;
            dividend_sign_reg                                                               <= 1'b0;

            divisor_reg                                                                     <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
            remainder_reg                                                                   <= {(OPERAND_WIDTH_IN_BITS * 2 + 1){1'b0}};

            if (issue_ack_in)
            begin
                wait_to_busy_flag                                                               <= 1'b1;

                output_clear_flag                                                               <= 1'b0;

                valid_out                                                                       <= 1'b0;

                remainder_sign_out                                                              <= 1'b0;
                quotient_sign_out                                                               <= 1'b0;

                remainder_out                                                                   <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
                quotient_out                                                                    <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

                remainder_reg_shift_ctr                                                         <= 32'b0;
            end
        end

        if (state_exception_flag)
        begin
            valid_out                                                                       <= 1'b1;

            //write output reg
            quotient_sign_out                                                               <= 1'b0;
            remainder_sign_out                                                              <= 1'b0;

            remainder_out                                                                   <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
            quotient_out                                                                    <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

            divide_by_zero                                                                  <= 1'b1;

            //clear reg
            divisor_sign_reg                                                                <= 1'b0;
            dividend_sign_reg                                                               <= 1'b0;

            divisor_reg                                                                     <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
            remainder_reg                                                                   <= {(OPERAND_WIDTH_IN_BITS * 2 + 1){1'b0}};

            if (issue_ack_in)
            begin
                wait_to_busy_flag                                                               <= 1'b1;

                output_clear_flag                                                               <= 1'b0;

                valid_out                                                                       <= 1'b0;

                remainder_sign_out                                                              <= 1'b0;
                quotient_sign_out                                                               <= 1'b0;

                remainder_out                                                                   <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
                quotient_out                                                                    <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

                remainder_reg_shift_ctr                                                         <= 32'b0;
            end
        end
    end
end

always @ (*)
begin
    case (state_ctr)
        `STATE_RESET: begin
            state_reset_flag <= 1'b1;
            state_input_flag <= 1'b0;
            state_shift_flag <= 1'b0;
            state_sub_flag <= 1'b0;
            state_output_flag <= 1'b0;
            state_exception_flag <= 1'b0;
        end

        `STATE_INPUT: begin
            state_reset_flag <= 1'b0;
            state_input_flag <= 1'b1;
            state_shift_flag <= 1'b0;
            state_sub_flag <= 1'b0;
            state_output_flag <= 1'b0;
            state_exception_flag <= 1'b0;
        end

        `STATE_SHIFT: begin
            state_reset_flag <= 1'b0;
            state_input_flag <= 1'b0;
            state_shift_flag <= 1'b1;
            state_sub_flag <= 1'b0;
            state_output_flag <= 1'b0;
            state_exception_flag <= 1'b0;
        end

        `STATE_SUB: begin
            state_reset_flag <= 1'b0;
            state_input_flag <= 1'b0;
            state_shift_flag <= 1'b0;
            state_sub_flag <= 1'b1;
            state_output_flag <= 1'b0;
            state_exception_flag <= 1'b0;
        end

        `STATE_OUTPUT: begin
            state_reset_flag <= 1'b0;
            state_input_flag <= 1'b0;
            state_shift_flag <= 1'b0;
            state_sub_flag <= 1'b0;
            state_output_flag <= 1'b1;
            state_exception_flag <= 1'b0;
        end

        `STATE_EXCEPTION: begin
            state_reset_flag <= 1'b0;
            state_input_flag <= 1'b0;
            state_shift_flag <= 1'b0;
            state_sub_flag <= 1'b0;
            state_output_flag <= 1'b0;
            state_exception_flag <= 1'b1;
        end

        default: begin
            state_reset_flag <= 1'b0;
            state_input_flag <= 1'b0;
            state_shift_flag <= 1'b0;
            state_sub_flag <= 1'b0;
            state_output_flag <= 1'b0;
            state_exception_flag <= 1'b0;
        end
    endcase
end

always @(posedge clk_in)
begin
    if (reset_in)
    begin
        state_ctr <= `STATE_RESET;
    end
    else
    begin
        case (state_ctr)
            `STATE_RESET: begin
                state_ctr <= `STATE_INPUT;
            end

            `STATE_INPUT: begin

                if (valid_in)
                begin
                    if (div_by_zero_flag)
                    begin
                        state_ctr <= `STATE_EXCEPTION;
                    end
                    else
                    begin
                        state_ctr <= `STATE_SHIFT;
                    end
                end
                else
                begin
                    state_ctr <= `STATE_INPUT;
                end
            end

            `STATE_SHIFT: begin
                state_ctr <= `STATE_SUB;
            end

            `STATE_SUB: begin
                if (output_enable)
                begin
                    state_ctr <= `STATE_OUTPUT;
                end
                else
                begin
                    state_ctr <= `STATE_SHIFT;
                end
            end

            `STATE_OUTPUT: begin
                if (issue_ack_in)
                begin
                    state_ctr <= `STATE_INPUT;
                end
                else
                begin
                    state_ctr <= `STATE_OUTPUT;
                end
            end

            `STATE_EXCEPTION: begin
                if (issue_ack_in)
                begin
                    state_ctr <= `STATE_INPUT;
                end
                else
                begin
                    state_ctr <= `STATE_EXCEPTION;
                end
            end

            default: begin
                state_ctr <= `STATE_RESET;
            end
        endcase
    end
end

endmodule
