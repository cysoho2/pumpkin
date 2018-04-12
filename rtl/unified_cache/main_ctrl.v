#include "parameters.h"

module main_ctrl
#(
        parameter SINGLE_TAG_SIZE_IN_BITS  = 2,
        parameter CACHE_BLOCK_SIZE_IN_BITS = 2,
        parameter NUMBER_WAYS              = 2,
        parameter NUMBER_SETS              = 2,
        parameter SET_PTR_WIDTH_IN_BITS    = 1,
)
(
        input                                                                   reset_in,
        input                                                                   clk_in,
        
        input           [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)       - 1 : 0]   request_in,
        
        // to tag array
        output     reg  [NUMBER_WAYS                                 - 1 : 0]   tag_way_select_out,

        output     reg                                                          tag_read_en_out,
        output     reg  [SET_PTR_WIDTH_IN_BITS                       - 1 : 0]   tag_read_set_addr_out,
        input           [SINGLE_TAG_SIZE_IN_BITS * NUMBER_WAYS       - 1 : 0]   tag_read_pack_in,

        output     reg                                                          tag_write_en_out,
        output     reg  [SET_PTR_WIDTH_IN_BITS                       - 1 : 0]   tag_write_set_addr_out,        
        output     reg  [SINGLE_TAG_SIZE_IN_BITS                     - 1 : 0]   tag_write_out,
        input           [SINGLE_TAG_SIZE_IN_BITS                     - 1 : 0]   tag_evict_in,

        // to data array
        output     reg  [NUMBER_WAYS                                 - 1 : 0]   data_way_select_out,

        output     reg                                                          data_read_en_out,
        output     reg  [SET_PTR_WIDTH_IN_BITS                       - 1 : 0]   data_read_set_addr_out,
        input           [CACHE_BLOCK_SIZE_IN_BITS                    - 1 : 0]   data_read_data_in,
        
        output     reg                                                          data_write_en_out,
        output     reg  [SET_PTR_WIDTH_IN_BITS                       - 1 : 0]   data_write_set_addr_out,    
        output     reg  [CACHE_BLOCK_SIZE_IN_BITS                    - 1 : 0]   data_write_out
)

wire [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0] stage1 = request_in;
reg  [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0] stage2;

// main stage 1, access tag array, write back buffer
always @(posedge clk_in or posedge reset_in)
begin
        if(reset_in)
        begin
                stage2                  <= 0;
                
                read_en_out             <= 0;
                read_set_addr_out       <= 0;
        end

        else
        begin
                if(stage1[`UNIFIED_CACHE_PACKET_VALID_POS]
                   & `UNIFIED_CACHE_PACKET_TYPE_NORMAL == stage1[`UNIFIED_CACHE_PACKET_TYPE_POS_HI : `UNIFIED_CACHE_PACKET_TYPE_POS_LO])
                begin
                        read_en_out             <= 1'b1;
                        read_set_addr_out       <= stage1[(`UNIFIED_CACHE_INDEX_POS_HI) : (`UNIFIED_CACHE_INDEX_POS_LO)]
                end

                else
                begin
                        read_en_out             <= 1'b0;
                        read_set_addr_out       <= 0;
                end
        end

end

// main stage 2, get the tag array read result, determin hit/miss
// generate 