`include "parameters.h"

module replacing_policy
#(
    parameter NUM_WAY = 4,
    parameter POLICY  = "1-bit NRU" /* option: 1-bit NRU */
)
(
    input       [NUM_WAY - 1 : 0] valid_flatted_in,
    input       [NUM_WAY - 1 : 0] history_flatted_in,
    output reg  [NUM_WAY - 1 : 0] replaced_way_out
);

// insert your replacing policy here


endmodule
