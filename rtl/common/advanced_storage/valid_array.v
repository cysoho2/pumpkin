module valid_array
#(
        parameter SINGLE_ELEMENT_SIZE_IN_BITS 	= 1,
        parameter NUMBER_SETS              	= 64,
        parameter NUMBER_WAYS              	= 16,
        parameter SET_PTR_WIDTH_IN_BITS    	= $clog2(NUMBER_SETS)
)
(
        input                                                           reset_in,
        input                                                           clk_in,

        input                                                           access_en_in,
        input      [SET_PTR_WIDTH_IN_BITS    - 1 : 0]                   access_set_addr_in,

        input                                                           write_en_in,
        input      [NUMBER_WAYS              - 1 : 0]                   write_way_select_in,

        output     [SINGLE_ELEMENT_SIZE_IN_BITS * NUMBER_WAYS - 1 : 0]  read_set_valid_out
);

generate
        genvar gen;

        for(gen = 0; gen < NUMBER_WAYS; gen = gen + 1)
        begin

                single_port_lutram
                #(
                        .SINGLE_ELEMENT_SIZE_IN_BITS(SINGLE_ELEMENT_SIZE_IN_BITS),
                        .NUMBER_SETS(NUMBER_SETS),
                        .SET_PTR_WIDTH_IN_BITS(SET_PTR_WIDTH_IN_BITS)
                )
                data_way
                (
                        .reset_in               (reset_in),
                        .clk_in                 (clk_in),

                        .access_en_in           (access_en_in & write_way_select_in[gen]),
                        .write_en_in            (write_en_in  & write_way_select_in[gen]),

                        .access_set_addr_in     (access_set_addr_in),

                        .write_element_in       (write_en_in  & write_way_select_in[gen]),
                        .read_element_out       (read_set_valid_out[(gen+1) * SINGLE_ELEMENT_SIZE_IN_BITS - 1 : gen * SINGLE_ELEMENT_SIZE_IN_BITS])
                );

        end

endgenerate

endmodule
