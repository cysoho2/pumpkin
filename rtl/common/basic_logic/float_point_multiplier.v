`include "parameters.h"

module float_point_multiplier
#(
    parameter OPERAND_EXPONENT_WIDTH_IN_BITS = `DOUBLE_FLOAT_POINT_EXPONENT_WIDTH_IN_BITS,
    parameter OPERAND_FRACTION_WIDTH_IN_BITS = `DOUBLE_FLOAT_POINT_FRACTION_WIDTH_IN_BITS
)
(
    input                                                               reset_in,
    input                                                               clk_in,

    input                                                               operantion_mode_in,
    input                                                               float_point_precision_in,
    input       [(`FLOAT_POINT_ROUNDING_MODE_FIELD_LEN_IN_BITS - 1):0]  float_point_rounding_mode_in,

    input                                                               operand_0_valid_in,
    input                                                               operand_0_sign_in,
    input       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]                operand_0_exponent_in,
    input       [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]                operand_0_fraction_in,

    input                                                               operand_1_valid_in,
    input                                                               operand_1_sign_in,
    input       [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]                operand_1_exponent_in,
    input       [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]                operand_1_fraction_in,

    output reg                                                          issue_ack_out,

    output reg                                                          product_valid_out,
    output reg                                                          product_sign_out,
    output reg  [(OPERAND_EXPONENT_WIDTH_IN_BITS - 1):0]                product_exponent_out,
    output reg  [(OPERAND_FRACTION_WIDTH_IN_BITS - 1):0]                product_fraction_out,

    input                                                               issue_ack_in,

    output reg  [(`FLOAT_POINT_ACCRUED_EXCEPTION_FIELD_LEN_IN_BITS):0]  float_point_accrued_exception_out
);

parameter MUL_OPERAND_WIDTH_IN_BITS = (OPERAND_FRACTION_WIDTH_IN_BITS + 1'b1) * 2;

integer_multiplier
#(
    .OPERAND_WIDTH_IN_BITS(MUL_OPERAND_WIDTH_IN_BITS)
)
(
    .reset_in(reset_in),
    .clk_in(clk_in),

    .multiply_exception_out(),

    .multiplicand_valid_in(),
    ,multiplicand_sign_in(),
    .multiplicand_in(),

    .multiplier_valid_in(),
    .multiplier_sign_in(),
    .multiplier_in(),

    .issue_ack_out(),

    .product_valid_out(),
    .product_sign_out(),
    .product_out(),

    .issue_ack_in()
);

endmodule
