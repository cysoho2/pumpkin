module number_round
#(
    parameter INPUT_WIDTH_IN_BITS = 32,
    parameter OUTPUT_WIDTH_IN_BITS = 16, //output width should be smaller than input width
    parameter ROUND_TYPE = "CHOP"
)
(
    input [(INPUT_WIDTH_IN_BITS - 1):0] original_data_in,

    output reg is_rounded,
    output reg [(OUTPUT_WIDTH_IN_BITS - 1):0] rounded_data_out
);

generate

    if (ROUND_TYPE == "CHOP")
    begin
        always@(*)
        begin
            rounded_data_out <= original_data_in[(INPUT_WIDTH_IN_BITS - 1):(INPUT_WIDTH_IN_BITS - OUTPUT_WIDTH_IN_BITS)];
        end
    end

endgenerate


endmodule
