`include parameters.h

module float_point_classify_testbench();






float_point_classify
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



endmodule
