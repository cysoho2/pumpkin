`include "parameters.h"

module unified_cache_bank
#(
    parameter NUM_INPUT_PORT                     = 2,
    parameter UNIFIED_CACHE_PACKET_WIDTH_IN_BITS = `UNIFIED_CACHE_PACKET_WIDTH_IN_BITS,

    parameter NUM_SET                            = `UNIFIED_CACHE_NUM_SETS,
    parameter BANK_NUM                           = 0,
    parameter NUM_WAY                            = `UNIFIED_CACHE_SET_ASSOCIATIVITY,
    parameter BLOCK_SIZE_IN_BYTES                = `UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES
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

wire                                              is_miss_queue_full;
wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] miss_replay_request;
wire                                              miss_replay_request_ack;

wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] access_packet;
wire                                              access_packet_ack;

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
    .request_flatted_in             ({request_flatted_in, miss_replay_request}),
    .request_valid_flatted_in       ({request_valid_flatted_in, miss_replay_request[`UNIFIED_CACHE_PACKET_VALID_POS]}),
    .request_critical_flatted_in    ({request_critical_flatted_in, is_miss_queue_full}),
    .issue_ack_out                  ({issue_ack_out, miss_replay_request_ack}),
    
    .request_out                    (access_packet),
    .request_valid_out              (),
    .issue_ack_in                   (access_packet_ack)
);

//cache_main_pipe_stage_1_ctrl

endmodule