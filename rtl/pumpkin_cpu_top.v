`include "parameters.h"

module pumpkin_cpu_top
(
    input                                                       reset_in,
    input                                                       clk_in  

    /*inout   [(`OFF_CORE_ACCESS_WIDTH_IN_BITS) - 1 : 0]          off_core_access_payload_inout,
    inout                                                       off_core_access_ack_inout,
    inout   [(`CPU_WORD_LEN_IN_BITS)          - 1 : 0]          off_core_access_addr_inout,  
    inout                                                       off_core_access_addr_valid_inout,
    output                                                      off_core_access_is_write_out,
    output                                                      inout_ctrl_out*/
);

/*wire    [(`INSTS_FETCH_WIDTH_IN_BITS)         - 1 : 0]          insts_fetch_from_l1_icache_to_ifetcher;
wire    [(`CPU_WORD_LEN_IN_BITS)              - 1 : 0]          insts_fetch_addr_from_ifetcher_to_l1_icache;
wire    [(`L2_PACKET_WIDTH_IN_BITS)           - 1 : 0]          l2_packet_from_l2_cache_to_l1_icache;
wire    [(`L2_PACKET_WIDTH_IN_BITS)           - 1 : 0]          l2_packet_from_l1_icache_to_l2_cache;

wire    [(`INSTS_FETCH_WIDTH_IN_BITS)         - 1 : 0]          insts_fetched_from_ifetcher_to_idecoder_out;

insts_fetcher ifetcher
(
    .reset_in                           (reset_in),
    .clk_in                             (clk_in),
    
    // to L1 icache
    .insts_fetch_in                     (insts_fetch_from_l1_icache_to_ifetcher),
    .insts_fetch_valid_in               (insts_fetch_valid_from_l1_icache_to_ifetcher),
    .insts_fetch_ack_in                 (insts_fetch_ack_from_l1_icache_to_ifetcher),
    .insts_fetch_addr_out               (insts_fetch_addr_from_ifetcher_to_l1_icache),
    .insts_fetch_addr_valid_out         (insts_fetch_addr_valid_from_ifetcher_to_l1_icache),
    
    // to insts decoder
    .insts_to_idecoder_out              (insts_fetched_from_ifetcher_to_idecoder_out)
);

l1_insts_cache l1_icache
(
    .reset_in                           (reset_in),
    .clk_in                             (clk_in),
    
     // to ifetcher
    .insts_fetch_out                    (insts_fetch_from_l1_icache_to_ifetcher),
    .insts_fetch_valid_out              (insts_fetch_valid_from_l1_icache_to_ifetcher),
    .insts_fetch_ack_out                (insts_fetch_ack_from_l1_icache_to_ifetcher),
    .insts_fetch_addr_in                (insts_fetch_addr_from_ifetcher_to_l1_icache),
    .insts_fetch_addr_valid_in          (insts_fetch_addr_valid_from_ifetcher_to_l1_icache),

    // to l2 cache
    .l2_packet_in                       (l2_packet_from_l2_cache_to_l1_icache),
    .insts_fill_ack_in                  (insts_fill_ack_from_l2_cache_to_l1_icache),
    .l2_packet_out                      (l2_packet_from_l1_icache_to_l2_cache)
);

l2_unified_cache l2_cache
(
    .reset_in                           (reset_in),
    .clk_in                             (clk_in),

    // to l1 icache
    .insts_packet_out                   (l2_packet_from_l2_cache_to_l1_icache),
    .insts_fill_ack_out                 (insts_fill_ack_from_l2_cache_to_l1_icache),
    .insts_packet_in                    (l2_packet_from_l1_icache_to_l2_cache),

    // to l1 dcache
    .data_packet_out                    (),
    .data_fill_ack_out                  (),
    .data_packet_in                     ({(`L2_PACKET_WIDTH_IN_BITS){1'b0}}),

    // to mem
    .payload_inout                      (off_core_access_payload_inout),
    .payload_fill_ack_inout             (off_core_access_ack_inout),
    .payload_addr_inout                 (off_core_access_addr_inout),
    .payload_fill_addr_valid_inout      (off_core_access_addr_valid_inout),
    .payload_is_write_out               (off_core_access_is_write_out),
    .inout_ctrl_out                     (inout_ctrl_out)
);


insts_decoder idecoder
(
    //input
    .insts_from_ifetcher_in(insts_fetched_from_ifetcher_to_idecoder_out)


    //output


);
*/

endmodule
