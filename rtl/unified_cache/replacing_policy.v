`include "parameters.h"

module replacing_policy
#
(
    parameter NUM_WAY = 4
)
(
    input   [NUM_WAY - 1 : 0] valid_flatted_in,
    input   [NUM_WAY - 1 : 0] history_flatted_in,
    output  [NUM_WAY - 1 : 0] replaced_way_out
);

wire [NUM_WAY - 1 : 0] first_valid_way;
wire                   valid_way_exist;

wire [NUM_WAY - 1 : 0] first_unused_way;

find_first_one_index
#(
    .VECTOR_LENGTH(NUM_WAY)
)
find_first_valid
(
    .vector_in              (NUM_WAY),
    .first_one_index_out    (first_valid_way),
    .one_is_found_out       (valid_way_exist)
);

find_first_one_index
#(
    .VECTOR_LENGTH(NUM_WAY)
)
find_first_unused
(
    .vector_in              (NUM_WAY),
    .first_one_index_out    (first_unused_way),
    .one_is_found_out       ()
);

wire [NUM_WAY - 1 : 0] target_index = valid_way_exist ? first_valid_way : first_unused_way;

generate
genvar loop_index;

    for(loop_index = 0; loop_index < NUM_WAY; loop_index = loop_index + 1)
    begin
        assign replaced_way_out[loop_index] = loop_index == target_index ? 1'b1 : 1'b0; 
    end

endgenerate

endmodule
