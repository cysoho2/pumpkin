module mux_decoded_8
#(
    parameter NUMBER_WAY = 8,
    parameter SINGLE_ENTRY_SIZE_IN_BITS = 32
)
(
    input      [SINGLE_ENTRY_SIZE_IN_BITS * NUMBER_WAY - 1 : 0]  way_flatted_in,
    input      [NUMBER_WAY                             - 1 : 0]  sel_in,
    output reg [SINGLE_ENTRY_SIZE_IN_BITS              - 1 : 0]  way_flatted_out
);

wire [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0] data_to_mux [NUMBER_WAY - 1 : 0];

generate
    genvar gen;

    for(gen = 0; gen < NUMBER_WAY; gen = gen + 1)
    begin
        assign data_to_mux[gen] = way_flatted_in[(gen+1) * SINGLE_ENTRY_SIZE_IN_BITS - 1 : gen * SINGLE_ENTRY_SIZE_IN_BITS];
    end

endgenerate

wire [3:0] sel_index;

find_first_one_index
#(
    .VECTOR_LENGTH(NUMBER_WAY),
    .MAX_OUTPUT_WIDTH(4)
)
find_first_one_index
(
    .vector_in(sel_in),
    .first_one_index_out(sel_index),
    .one_is_found_out()
);

assign way_flatted_out = data_to_mux[sel_index];

endmodule
