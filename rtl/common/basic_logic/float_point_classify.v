`include parameters.h

module float_point_classify
#(
	parameter       FLOAT_POINT_EXPONENT_WIDTH_IN_BITS                  = `DOUBLE_FLOAT_POINT_EXPONENT_WIDTH_IN_BITS,
    parameter       FLOAT_POINT_FRACTION_WIDTH_IN_BITS                  = `DOUBLE_FLOAT_POINT_FRACTION_WIDTH_IN_BITS
)
(
    input                                                               float_point_precision_in,

    input                                                               float_point_sign_bit_in,
    input           [(FLOAT_POINT_EXPONENT_WIDTH_IN_BITS - 1):0]        float_point_exponent_in,
    input           [(FLOAT_POINT_FRACTION_WIDTH_IN_BITS - 1):0]        float_point_fraction_in,

	output reg      [(`FLOAT_POINT_NUMBER_FORMAT_WIDTH - 1):0]          float_point_classify_out
);

parameter   EXPONENT_RETRIEVAL_WIDTH_IN_BITS                            = (float_point_precision_in == `SINGLE_PRECISION_FLOAT_POINT_NUMBER)? `SINGLE_FLOAT_POINT_EXPONENT_WIDTH_IN_BITS : `DOUBLE_FLOAT_POINT_EXPONENT_WIDTH_IN_BITS;
parameter   FRACTION_RETRIEVAL_WIDTH_IN_BITS                            = (float_point_precision_in == `SINGLE_PRECISION_FLOAT_POINT_NUMBER)? `SINGLE_FLOAT_POINT_FRACTION_WIDTH_IN_BITS : `DOUBLE_FLOAT_POINT_FRACTION_WIDTH_IN_BITS;

wire        is_positive;
wire        is_negetive;

wire        is_exponent_all_deassert;
wire        is_exponent_all_assert;
wire        is_fraction_all_deassert;
wire        is_exponent_all_assert;

wire        is_fraction_most_significant_assert;

assign      is_positive                                                 = ~float_point_sign_bit_in;
assign      is_negetive                                                 = float_point_sign_bit_in;

assign      is_exponent_all_deassert                                    = ~|(float_point_exponent_in[(EXPONENT_RETRIEVAL_WIDTH_IN_BITS - 1):0]);
assign      is_exponent_all_assert                                      = &(float_point_exponent_in[(EXPONENT_RETRIEVAL_WIDTH_IN_BITS - 1):0]);
assign      is_fraction_all_deassert                                    = ~|(float_point_fraction_in[(FRACTION_RETRIEVAL_WIDTH_IN_BITS - 1):0]);
assign      is_fraction_all_assert                                      = &(float_point_fraction_in[(FRACTION_RETRIEVAL_WIDTH_IN_BITS - 1):0]);

assign      is_fraction_most_significant_assert                         = float_point_fraction_in[(FRACTION_RETRIEVAL_WIDTH_IN_BITS - 1)];

always @ ( * )
begin
        if (is_negetive & is_exponent_all_assert & is_fraction_all_deassert)
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_NEGATIVE_INFINITY;
        end

        else if (is_negetive & ~(is_exponent_all_assert) & ~(is_exponent_all_deassert))
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_NEGATIVE_NORMAL_NUMBER;
        end

        else if (is_negetive & is_exponent_all_deassert & ~is_fraction_all_deassert)
        begin
            float_point_classify_out                                    <= 'FLOAT_POINT_FORMAT_NEGATIVE_SUBNORMAL_NUMBER;
        end

        else if (is_negetive & is_exponent_all_deassert & is_fraction_all_deassert)
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_NEGATIVE_ZERO;
        end

        else if (is_positive & is_exponent_all_deassert & is_fraction_all_deassert)
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_POSITIVE_ZERO;
        end

        else if (is_positive & is_exponent_all_deassert & ~is_fraction_all_deassert)
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_POSITIVE_SUBNORMAL_NUMBER;
        end

        else if (is_positive & ~is_exponent_all_assert & ~is_exponent_all_deassert)
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_POSITIVE_NORMAL_NUMBER;
        end

        else if (is_positive & is_exponent_all_assert & is_exponent_all_deassert)
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_POSITIVE_INFINITY;
        end

        else if (is_exponent_all_assert & ~is_fraction_most_significant_assert ~is_fraction_all_deassert)
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_SIGNALING_NAN;
        end

        else if (is_exponent_all_assert & is_fraction_most_significant_assert)
        begin
            float_point_classify_out                                    <= `FLOAT_POINT_FORMAT_QUIET_NAN;
        end
end

endmodule //float_point_classify
