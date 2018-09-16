module chain_adder
#
(
    parameter SINGLE_WAY_WIDTH_IN_BITS  = 32,
    parameter NUM_WAY                   = 16
)
(
    input  [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0]  way_flatted_in,
    output [SINGLE_WAY_WIDTH_IN_BITS * NUM_WAY - 1 : 0]  result_out
);



endmodule