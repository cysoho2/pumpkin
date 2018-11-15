`include "parameters.h"

module replacing_policy
#(
    parameter NUM_WAY   = 4,
    parameter ALGORITHM = "1-bit NRU" /* option: 1-bit NRU */
)
(
    input  [NUM_WAY - 1 : 0] valid_flatted_in,
    input  [NUM_WAY - 1 : 0] history_flatted_in,
    output [NUM_WAY - 1 : 0] replaced_way_out
);

wire [31:0] invalid_index;
wire        invalid_is_found;
find_first_one_index
#(
    .VECTOR_LENGTH(NUM_WAY)
)
first_invalid_index
(
    .vector_in(~valid_flatted_in),
    .first_one_index_out(invalid_index),
    .one_is_found_out(invalid_is_found)
);

wire [31:0] victim_index;

assign replaced_way_out = invalid_is_found ? invalid_index : victim_index;

// insert replacing policy here

generate
if(ALGORITHM == "1-bit NRU")
begin
    

end
endgenerate


endmodule
