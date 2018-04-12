module dual_port_blockram_test
();

parameter SINGLE_ELEMENT_SIZE_IN_BITS = 64,
parameter NUMBER_SETS                 = 64,
parameter SET_PTR_WIDTH_IN_BITS       = 6

reg                                        reset_in,
reg                                        clk_in,
    
reg                                        read_en_in,
reg  [SET_PTR_WIDTH_IN_BITS       - 1 : 0] read_set_addr_in,
wire [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] read_element_out,

reg                                        write_en_in,
reg  [SET_PTR_WIDTH_IN_BITS       - 1 : 0] write_set_addr_in,
reg  [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] write_element_in,
reg  [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] evict_element_out