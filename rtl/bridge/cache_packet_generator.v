`include "parameters.h"

module cache_packet_generator
#
(
    NUM_WAY = 2
)
(
    input                                                               reset_in,
    input                                                               clk_in,

    output reg  [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS * NUM_WAY - 1 : 0] test_packet_flatted_out,
    input       [NUM_WAY                                       - 1 : 0] test_packet_ack_flatted_in,

    input       [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS * NUM_WAY - 1 : 0] return_packet_flatted_in,
    output reg  [NUM_WAY                                       - 1 : 0] return_packet_ack_flatted_in,

    output reg                                                          done,
    output reg                                                          error
);

endmodule