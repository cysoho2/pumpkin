module radix_four_rst_divider
#(
    parameter OPERAND_WIDTH_IN_BITS = 64,
    parameter NUM_RADIX = 4,
    parameter DIVISOR_INSPECTED_WIDTH_IN_BITS = 3, //from most significant bit to least significant bit
    parameter PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS = 5 //from most significant bit to least significant bit
)
(
    input reset_in,
    input clk_in,

    output reg request_ack_out,
    input dividend_sign_in,
    input [OPERAND_WIDTH_IN_BITS - 1 : 0] dividend_in,
    input divisor_sign_in,
    input [OPERAND_WIDTH_IN_BITS - 1 : 0] divisor_in,

    input request_ack_in,
    output reg quotient_sign_out,
    output reg [OPERAND_WIDTH_IN_BITS - 1 : 0] quotient_out,
    output reg remainder_sign_out,
    output reg [OPERAND_WIDTH_IN_BITS - 1 : 0] remainder_out
);

parameter NUM_PD_PLOT_CASE = 2 ** (DIVISOR_INSPECTED_WIDTH_IN_BITS - 1);
parameter P_DIVIDED_BASE_VALUE = 4'b0110;
parameter MAX_WEIGHT_OF_DIVIDOR = 2;
parameter NUM_PROPROCESS_DIVISOR_REG_FILE = MAX_WEIGHT_OF_DIVIDOR * 2;
parameter PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS = $clog2(NUM_RADIX);
parameter CSA_OPERAND_WIDTH_IN_BITS = OPERAND_WIDTH_IN_BITS + 2;

integer vector_index;

reg divisor_sign_reg;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0] divisor_reg;
reg dividend_sign_reg;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0] dividend_reg;

reg [CSA_OPERAND_WIDTH_IN_BITS - 1 : 0] carry_reg;
reg [CSA_OPERAND_WIDTH_IN_BITS - 1 : 0] sum_reg;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0] remainder_reg;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0] quotient_reg;

reg [PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS - 1 : 0] recoding_data_reg_stage_0;
reg [PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS - 1 : 0] fixed_recoding_data_reg_stage_0;
reg sign_bit_from_selector_stage_0;

reg [PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS - 1 : 0] recoding_data_reg_stage_1;
reg [PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS - 1 : 0] fixed_recoding_data_reg_stage_1;

reg [CSA_OPERAND_WIDTH_IN_BITS - 1 : 0] proprocess_divisor_reg_file [NUM_PROPROCESS_DIVISOR_REG_FILE - 1 : 0]; //weight : [-2, 2]

reg [2 ** PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS - 1 : 0] non_bit_lookup_table [2 ** DIVISOR_INSPECTED_WIDTH_IN_BITS - 1 : 0];
reg [2 ** PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS - 1 : 0] power_bit_lookup_table [2 ** DIVISOR_INSPECTED_WIDTH_IN_BITS - 1 : 0];

reg init_store_reg_stage;
reg is_initing_flag;
reg is_running_flag;
reg recoding_enable;

reg [31:0] quotient_ctr;

wire [OPERAND_WIDTH_IN_BITS - 1 : 0] shifted_divisor_to_reg_file;
wire [OPERAND_WIDTH_IN_BITS - 1 : 0] shifted_dividend_to_sum_reg;

wire divisor_one_is_found_out;
wire dividend_one_is_found_out;
wire [$clog2(OPERAND_WIDTH_IN_BITS) - 1 : 0] divisor_first_one_index;
wire [$clog2(OPERAND_WIDTH_IN_BITS) - 1 : 0] dividend_first_one_index;
wire [$clog2(OPERAND_WIDTH_IN_BITS) - 1 : 0] fixed_divisor_first_one_index;
wire [$clog2(OPERAND_WIDTH_IN_BITS) - 1 : 0] fixed_dividend_first_one_index;

wire [CSA_OPERAND_WIDTH_IN_BITS - 1 : 0] carry_reg_data_to_csa;
wire [CSA_OPERAND_WIDTH_IN_BITS - 1 : 0] sum_reg_data_to_csa;
wire [CSA_OPERAND_WIDTH_IN_BITS - 1 : 0] generation_data_to_csa;

wire [CSA_OPERAND_WIDTH_IN_BITS - 1 : 0] carry_data_from_csa;
wire [CSA_OPERAND_WIDTH_IN_BITS - 1 : 0] sum_data_from_csa;

//select

wire [DIVISOR_INSPECTED_WIDTH_IN_BITS - 1 : 0] inspected_bits_from_divisor_reg;
wire [PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS - 1 : 0] inspected_bits_from_carry_reg;
wire [PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS - 1 : 0] inspected_bits_from_sum_reg;

wire [PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS - 1 : 0] shifted_partial_remainder_to_generation;

wire non_from_selector_to_generation;
wire sign_from_selector_to_generation;
wire power_from_selector_to_generation;

wire [PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS - 1 : 0] recoding_data_to_quotient;
wire least_significant_bit_from_quotient;

wire [PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS - 1 : 0] p;
wire [DIVISOR_INSPECTED_WIDTH_IN_BITS - 1 : 0] d;

//find first one index
assign fixed_dividend_first_one_index = (OPERAND_WIDTH_IN_BITS - dividend_first_one_index - 1 - (2'b11 - dividend_first_one_index % 4));
assign fixed_divisor_first_one_index = (OPERAND_WIDTH_IN_BITS - divisor_first_one_index - 1);
assign shifted_divisor_to_reg_file = divisor_one_is_found_out? divisor_reg << fixed_divisor_first_one_index : {(OPERAND_WIDTH_IN_BITS){1'b0}};
assign shifted_dividend_to_sum_reg = dividend_one_is_found_out? dividend_reg << fixed_dividend_first_one_index : {(OPERAND_WIDTH_IN_BITS){1'b0}};

//transmit
assign carry_reg_data_to_csa = carry_reg;
assign sum_reg_data_to_csa = sum_reg;

assign inspected_bits_from_carry_reg = carry_reg[CSA_OPERAND_WIDTH_IN_BITS - 1 : CSA_OPERAND_WIDTH_IN_BITS - PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS];
assign inspected_bits_from_sum_reg = sum_reg[CSA_OPERAND_WIDTH_IN_BITS - 1 : CSA_OPERAND_WIDTH_IN_BITS - PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS];

assign inspected_bits_from_divisor_reg = divisor_reg[OPERAND_WIDTH_IN_BITS - 2 : OPERAND_WIDTH_IN_BITS - DIVISOR_INSPECTED_WIDTH_IN_BITS - 1];
assign shifted_partial_remainder_to_generation = inspected_bits_from_carry_reg + inspected_bits_from_sum_reg;

//Multiple generation
assign generation_data_to_csa = non_from_selector_to_generation? {(CSA_OPERAND_WIDTH_IN_BITS){1'b0}} : proprocess_divisor_reg_file[{~sign_from_selector_to_generation, power_from_selector_to_generation}];

//Select q
assign p = shifted_partial_remainder_to_generation;
assign d = inspected_bits_from_divisor_reg;

assign non_from_selector_to_generation = is_running_flag? non_bit_lookup_table[d][31 - p] : 0;
assign power_from_selector_to_generation = is_running_flag? power_bit_lookup_table[d][31 - p] : 0;
assign sign_from_selector_to_generation = is_running_flag ? p[4] : 0;

//Booth's Recoding
assign least_significant_bit_from_quotient = quotient_reg[0];
assign recoding_data_to_quotient[PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS - 1] = (~sign_from_selector_to_generation & power_from_selector_to_generation) | (non_from_selector_to_generation & sign_from_selector_to_generation);
assign recoding_data_to_quotient[0] = (~non_from_selector_to_generation & ~sign_from_selector_to_generation) | (~power_from_selector_to_generation & sign_from_selector_to_generation);

//CSA tree
generate
genvar gen;

    for (gen = 0; gen < CSA_OPERAND_WIDTH_IN_BITS; gen = gen + 1)
    begin
        wire  input_0;
        wire  input_1;
        wire  input_2;

        assign input_0 = generation_data_to_csa[gen];
        assign input_1 = carry_reg_data_to_csa[gen];
        assign input_2 = sum_reg_data_to_csa[gen];

        assign carry_data_from_csa[gen] = (~input_0 & input_1 & input_2) | (input_0 & ~input_1 & input_2) | (input_0 & input_1 & ~input_2) | (input_0 & input_1 & input_2);
        assign sum_data_from_csa[gen] = (~input_0 & ~input_1 & input_2) | (~input_0 & input_1 & ~input_2) | (input_0 & ~input_1 & ~input_2) | (input_0 & input_1 & input_2);


    end

endgenerate


always @ ( posedge clk_in, posedge reset_in )
begin
    if (reset_in)
    begin

        divisor_sign_reg <= 1'b0;
        dividend_sign_reg <= 1'b0;
        divisor_reg <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        dividend_reg <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

        carry_reg <= {(CSA_OPERAND_WIDTH_IN_BITS){1'b0}};
        sum_reg <= {(CSA_OPERAND_WIDTH_IN_BITS){1'b0}};
        remainder_reg <= {(OPERAND_WIDTH_IN_BITS){1'b0}};
        quotient_reg <= {(OPERAND_WIDTH_IN_BITS){1'b0}};

        for (vector_index = 0; vector_index < NUM_PROPROCESS_DIVISOR_REG_FILE; vector_index = vector_index + 1)
        begin
            proprocess_divisor_reg_file[vector_index] <= 0;
        end

        non_bit_lookup_table[0] <= {32'b1110_0000_0000_0000_0000_0000_0000_0001};
        non_bit_lookup_table[1] <= {32'b1110_0000_0000_0000_0000_0000_0000_0001};
        non_bit_lookup_table[2] <= {32'b1111_0000_0000_0000_0000_0000_0000_0011};
        non_bit_lookup_table[3] <= {32'b1111_0000_0000_0000_0000_0000_0000_0011};

        non_bit_lookup_table[4] <= {32'b1111_0000_0000_0000_0000_0000_0000_0011};
        non_bit_lookup_table[5] <= {32'b1111_0000_0000_0000_0000_0000_0000_0011};
        non_bit_lookup_table[6] <= {32'b1111_0000_0000_0000_0000_0000_0000_0011};
        non_bit_lookup_table[7] <= {32'b1111_0000_0000_0000_0000_0000_0000_0011};

        power_bit_lookup_table[0] <= {32'b0000_0001_1111_1111_1111_1111_1110_0000};
        power_bit_lookup_table[1] <= {32'b0000_0000_1111_1111_1111_1111_1100_0000};
        power_bit_lookup_table[2] <= {32'b0000_0000_0111_1111_1111_1111_1000_0000};
        power_bit_lookup_table[3] <= {32'b0000_0000_0011_1111_1111_1111_0000_0000};

        power_bit_lookup_table[4] <= {32'b0000_0000_0001_1111_1111_1110_0000_0000};
        power_bit_lookup_table[5] <= {32'b0000_0000_0001_1111_1111_1110_0000_0000};
        power_bit_lookup_table[6] <= {32'b0000_0000_0000_1111_1111_1100_0000_0000};
        power_bit_lookup_table[7] <= {32'b0000_0000_0000_1111_1111_1100_0000_0000};

        fixed_recoding_data_reg_stage_0 <= {(PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS){1'b0}};
        recoding_data_reg_stage_0 <= {(PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS){1'b0}};
        sign_bit_from_selector_stage_0 <= 0;

        fixed_recoding_data_reg_stage_1 <= {(PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS){1'b0}};
        recoding_data_reg_stage_1 <= {(PRODUCT_QUOTIENT_PER_CYCLE_IN_BITS){1'b0}};

        quotient_ctr <= 1'b0;

        init_store_reg_stage <= 1'b1;
        is_initing_flag <= 1'b0;
        is_running_flag <= 1'b0;
        recoding_enable <= 1'b0;
    end
    else
    begin
        if (init_store_reg_stage)
        begin
            divisor_sign_reg <= divisor_sign_in;
            dividend_sign_reg <= dividend_sign_in;

            divisor_reg <= divisor_in;
            dividend_reg <= dividend_in;

            //goto
            init_store_reg_stage <= 1'b0;
            is_initing_flag <= 1;
        end

        if (is_initing_flag)
        begin

            //store
            sum_reg <= {{{1'b0}}, {shifted_dividend_to_sum_reg}, {1'b0}};
            quotient_ctr <= quotient_ctr + fixed_dividend_first_one_index + 2;

            divisor_reg <= {{(CSA_OPERAND_WIDTH_IN_BITS - OPERAND_WIDTH_IN_BITS){1'b0}}, {shifted_divisor_to_reg_file}};
            proprocess_divisor_reg_file[2'b00] <= {{1'b0}, {{1'b0}, {shifted_divisor_to_reg_file[OPERAND_WIDTH_IN_BITS - 1 : 0]}}};
            proprocess_divisor_reg_file[2'b01] <= {{1'b0}, {shifted_divisor_to_reg_file[OPERAND_WIDTH_IN_BITS - 1 : 0]}, {1'b0}};
            proprocess_divisor_reg_file[2'b10] <= {{1'b1}, {~{{1'b0}, {shifted_divisor_to_reg_file[OPERAND_WIDTH_IN_BITS - 1 : 0]}} + 1'b1}};
            proprocess_divisor_reg_file[2'b11] <= {{1'b1}, {~shifted_divisor_to_reg_file[OPERAND_WIDTH_IN_BITS - 1 : 0] + 1'b1}, {1'b0}};

            //goto
            is_initing_flag <= 1'b0;
            is_running_flag <= 1'b1;
            recoding_enable <= 1'b1;
        end

        if (is_running_flag)
        begin
            //partial remainder
            carry_reg <= {carry_data_from_csa << 3};
            sum_reg <= sum_data_from_csa << 2;

            if (quotient_ctr == OPERAND_WIDTH_IN_BITS - 2)
            begin
                is_running_flag <= 1'b0;
            end
        end

        if (recoding_enable)
        begin
            //quetient
            quotient_ctr <= quotient_ctr + 2;
            if (quotient_ctr == OPERAND_WIDTH_IN_BITS + 2)
            begin
                recoding_enable <= 1'b0;
                quotient_reg = {{quotient_reg[OPERAND_WIDTH_IN_BITS - 3 : 0]}, fixed_recoding_data_reg_stage_1};
            end
            else
            begin
                recoding_data_reg_stage_0 <= recoding_data_to_quotient;
                fixed_recoding_data_reg_stage_0 <= (~power_from_selector_to_generation & ~non_from_selector_to_generation)? {recoding_data_to_quotient[0], recoding_data_to_quotient[1]} : recoding_data_to_quotient;
                sign_bit_from_selector_stage_0 <= sign_from_selector_to_generation;

                recoding_data_reg_stage_1 <= recoding_data_reg_stage_0;
                fixed_recoding_data_reg_stage_1 <= fixed_recoding_data_reg_stage_0;

                quotient_reg = (sign_bit_from_selector_stage_0)? {{quotient_reg[OPERAND_WIDTH_IN_BITS - 3 : 0]}, {recoding_data_reg_stage_1}} : {{quotient_reg[OPERAND_WIDTH_IN_BITS - 3 : 0]}, {fixed_recoding_data_reg_stage_1}};

            end

        end

    end
end

find_last_one_index
#(
    .VECTOR_LENGTH(OPERAND_WIDTH_IN_BITS),
    .MAX_OUTPUT_WIDTH($clog2(OPERAND_WIDTH_IN_BITS))
)
find_last_one_index_divisor
(
    .vector_in(divisor_reg[OPERAND_WIDTH_IN_BITS - 1 : 0]),
    .last_one_index_out(divisor_first_one_index),
    .one_is_found_out(divisor_one_is_found_out)
);

find_last_one_index
#(
    .VECTOR_LENGTH(OPERAND_WIDTH_IN_BITS),
    .MAX_OUTPUT_WIDTH($clog2(OPERAND_WIDTH_IN_BITS))
)
find_last_one_index_dividend
(
    .vector_in(dividend_reg[OPERAND_WIDTH_IN_BITS - 1  : 0]),
    .last_one_index_out(dividend_first_one_index),
    .one_is_found_out(dividend_one_is_found_out)
);

endmodule
