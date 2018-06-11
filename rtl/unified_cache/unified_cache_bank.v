`include "parameters.h"

module unified_cache_bank
#(
    parameter UNIFIED_CACHE_PACKET_WIDTH_IN_BITS = 70,
    parameter BANK_NUM                           = 0
)
(
    input  [NUM_INPUT_PORT * (UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0] request_flatted_in,
    input  [NUM_INPUT_PORT                                        - 1 : 0] request_valid_flatted_in,
    input  [NUM_INPUT_PORT                                        - 1 : 0] request_critical_flatted_in,
    output [NUM_INPUT_PORT                                        - 1 : 0] issue_ack_out,

    input  [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS                    - 1 : 0] fetched_request_in,
    input                                                                  fetched_request_valid_in,
    output                                                                 fetch_ack_out,

    output [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS                    - 1 : 0] miss_request_out,
    output                                                                 miss_request_valid_out,
    output                                                                 miss_request_critical_out,
    input                                                                  miss_request_ack_in,

    output [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS                    - 1 : 0] writeback_request_out,
    output                                                                 writeback_request_valid_out,
    output                                                                 writeback_request_critical_out,
    input                                                                  writeback_request_ack_in,

    output [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS                    - 1 : 0] return_request_out,
    output                                                                 return_request_valid_out,
    output                                                                 return_request_critical_out,
    input                                                                  return_request_ack_in
);

endmodule