`include "parameters.h"

module unified_cache
#(
    parameter NUM_INPUT_PORT                     = 2,
    parameter UNIFIED_CACHE_PACKET_WIDTH_IN_BITS = 70,
    parameter MEM_PACKET_WIDTH_IN_BITS           = 70
)
(
    input                                                                               reset_in,
    input                                                                               clk_in,

    // input packet
    input   [NUM_INPUT_PORT * (UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]             input_packet_flatted_in,
    output  [NUM_INPUT_PORT - 1 : 0]                                                    input_packet_ack_flatted_out,

    // return packet
    output  [NUM_INPUT_PORT * (UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]             output_packet_flatted_out,
    input   [NUM_INPUT_PORT - 1 : 0]                                                    output_packet_ack_flatted_in,

    // from mem
    input   [(MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]                                        from_mem_packet_in,
    output                                                                              from_mem_packet_ack_out,

    // to mem
    output  [(MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]                                        to_mem_packet_out,
    input                                                                               to_mem_packet_ack_in
);

wire  [(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]                    input_packet_packed [NUM_INPUT_PORT - 1 : 0];
wire  [NUM_INPUT_PORT - 1 : 0]                                          is_input_queue_full_flatted;
wire  [NUM_INPUT_PORT - 1 : 0]                                          input_queue_ack_flatted_out;

wire  [(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]                    input_packet_to_input_arbiter_packed [NUM_INPUT_PORT - 1 : 0];
wire  [NUM_INPUT_PORT * (UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]   input_packet_to_input_arbiter_flatted;
wire  [NUM_INPUT_PORT - 1 : 0]                                          input_packet_valid_to_input_arbiter_flatted;
wire  [NUM_INPUT_PORT - 1 : 0]                                          input_packet_critical_to_input_arbiter_flatted;
wire  [NUM_INPUT_PORT - 1 : 0]                                          input_arbiter_to_input_queue_ack_flatted;

// generate auto-connection between mulitple ports and input_arbiter
generate
genvar gen;

for(gen = 0; gen < NUM_INPUT_PORT; gen = gen + 1)
begin
    
    fifo_queue
    #(
        .QUEUE_SIZE                     (`INPUT_QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        ($clog2(`INPUT_QUEUE_SIZE)),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
    )
    input_queue
    (
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (), // intened left unconnected
        .is_full_out                    (is_input_queue_full_flatted[gen]),

        .request_in                     (input_packet_packed[gen]),
        .request_valid_in               (input_packet_packed[gen][`UNIFIED_CACHE_PACKET_VALID_POS]),
        .issue_ack_out                  (input_queue_ack_flatted_out[gen]),
        
        .request_out                    (input_packet_to_input_arbiter_packed[gen]),
        .request_valid_out              (input_packet_valid_to_input_arbiter_flatted[gen]),
        .issue_ack_in                   (input_arbiter_to_input_queue_ack_flatted[gen])
    );

    assign input_packet_to_input_arbiter_flatted[(gen + 1) * (UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 :
                                                  gen * (UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)]
            = input_packet_to_input_arbiter_packed[gen];
    
    assign input_packet_critical_to_input_arbiter_flatted[gen] = is_input_queue_full_flatted[gen];
end

endgenerate

wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] access_packet_from_input_arbiter;

priority_arbiter
#(
    .NUM_REQUESTS(NUM_INPUT_PORT),
    .SINGLE_REQUEST_WIDTH_IN_BITS(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
)
input_arbiter
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        // the arbiter considers priority from right(high) to left(low)
        .request_packed_in              (input_packet_to_input_arbiter_flatted),
        .request_valid_packed_in        (input_packet_valid_to_input_arbiter_flatted),
        .request_critical_packed_in     (input_packet_critical_to_input_arbiter_flatted),
        .issue_ack_out                  (input_arbiter_to_input_queue_ack_flatted),
        
        .request_out                    (access_packet_from_input_arbiter),
        .request_valid_out              (access_packet_valid_from_input_arbiter),
        .issue_ack_in                   (ack_to_input_arbiter)
);

assign to_mem_packet_out = access_packet_from_input_arbiter;
assign to_mem_packet_ack_in = ack_to_input_arbiter;

endmodule