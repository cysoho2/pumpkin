`include "parameters.h"

module l1_insts_cache
(
    input                                                       clk_in,
    input                                                       reset_in,

    // L1 Instruction Cache supplies instructions to ifetcher
    output  [(`INSTS_FETCH_WIDTH_IN_BITS)   - 1 : 0]            insts_fetch_out,
    output                                                      insts_fetch_valid_out,
    output                                                      insts_fetch_ack_out,
    input   [(`CPU_WORD_LEN_IN_BITS)        - 1 : 0]            insts_fetch_addr_in,
    input                                                       insts_fetch_addr_valid_in,

    // L1 Instruction Cache is filled from L2 unified cache
    input   [(`L2_PACKET_WIDTH_IN_BITS)   - 1 : 0]              l2_packet_in,
    input                                                       L2_packet_ack_in,
    output  [(`L2_PACKET_WIDTH_IN_BITS)        - 1 : 0]         l2_packet_out
);

assign insts_fetch_out              = l2_packet_in[`L2_PACKET_DATA_POS_HI : `L2_PACKET_DATA_POS_LO];
assign insts_fetch_valid_out        = l2_packet_in[`L2_PACKET_VALID_POS];
assign insts_fetch_ack_out          = l2_packet_ack_in;
assign l2_packet_out                = {insts_fetch_addr_in, {(`L2_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, insts_fetch_addr_valid_in, 1'b0, 1'b1};

endmodule