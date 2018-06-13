`include "parameters.h"

module unified_cache_bank
#(
    parameter BANK_NUM                           = 0,
    parameter NUM_INPUT_PORT                     = 2,
    parameter UNIFIED_CACHE_PACKET_WIDTH_IN_BITS = `UNIFIED_CACHE_PACKET_WIDTH_IN_BITS,

    parameter NUM_SET                            = `UNIFIED_CACHE_NUM_SETS,
    parameter NUM_WAY                            = `UNIFIED_CACHE_SET_ASSOCIATIVITY,
    parameter BLOCK_SIZE                         = `UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES
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

/*
priority_arbiter
#(
    .NUM_REQUEST(NUM_INPUT_PORT + 1), // input requests + miss replay
    .SINGLE_REQUEST_WIDTH_IN_BITS(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
)
to_mem_arbiter
(
    .reset_in                       (reset_in),
    .clk_in                         (clk_in),

    // the arbiter considers priority from right(high) to left(low)
    .request_flatted_in             ({miss_request_flatted, writeback_request_flatted}),
    .request_valid_flatted_in       ({miss_request_valid_flatted, writeback_request_valid_flatted}),
    .request_critical_flatted_in    ({miss_request_critical_flatted, writeback_request_critical_flatted}),
    .issue_ack_out                  ({miss_request_ack_flatted, writeback_request_ack_flatted}),
    
    .request_out                    (to_mem_packet_out),
    .request_valid_out              (),
    .issue_ack_in                   (to_mem_packet_ack_in)
);*/

endmodule