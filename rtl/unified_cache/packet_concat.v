`include "parameters.h"

module packet_concat
#
(
    parameter ADDR_LEN = `CPU_ADDR_LEN_IN_BITS,
    parameter DATA_LEN = `UNIFIED_CACHE_BLOCK_SIZE_IN_BITS,
    parameter TYPE_LEN = `UNIFIED_CACHE_PACKET_TYPE_WIDTH,
    parameter MASK_LEN = `UNIFIED_CACHE_PACKET_BYTE_MASK_LEN,
    parameter PORT_LEN = `UNIFIED_CACHE_PACKET_PORT_ID_WIDTH
)
(
    input [ADDR_LEN - 1 : 0] addr_in,
    input [DATA_LEN - 1 : 0] data_in,
    input [TYPE_LEN - 1 : 0] type_in,
    input [MASK_LEN - 1 : 0] write_mask_in,
    input [PORT_LEN - 1 : 0] port_num_in,
    input                    valid_in,
    input                    is_write_in,
    input                    cacheable_in,
    output                   packet_out
);

assign packet_out[`UNIFIED_CACHE_PACKET_ADDR_POS_HI         : `UNIFIED_CACHE_PACKET_ADDR_POS_LO]        = addr_in;
assign packet_out[`UNIFIED_CACHE_PACKET_DATA_POS_HI         : `UNIFIED_CACHE_PACKET_DATA_POS_LO]        = data_in;
assign packet_out[`UNIFIED_CACHE_PACKET_TYPE_POS_HI         : `UNIFIED_CACHE_PACKET_TYPE_POS_LO]        = type_in;
assign packet_out[`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI    : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO]   = write_mask_in;
assign packet_out[`UNIFIED_CACHE_PACKET_PORT_NUM_HI         : `UNIFIED_CACHE_PACKET_PORT_NUM_LO]        = port_num_in;
assign packet_out[`UNIFIED_CACHE_PACKET_VALID_POS]                                                      = valid_in;
assign packet_out[`UNIFIED_CACHE_PACKET_IS_WRITE_POS]                                                   = is_write_in;
assign packet_out[`UNIFIED_CACHE_PACKET_CACHEABLE_POS]                                                  = cacheable_in;

endmodule

/*

wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]   packet_concatenated;
packet_concat return_packet_concat
(
    .addr_in        (),
    .data_in        (),
    .type_in        (),
    .write_mask_in  (),
    .port_num_in    (),
    .valid_in       (),
    .is_write_in    (),
    .cacheable_in   (),
    .packet_out     (packet_concatenated)
);

*/