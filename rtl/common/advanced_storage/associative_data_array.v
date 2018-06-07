module associative_data_array
#(
        parameter SINGLE_ELEMENT_SIZE_IN_BITS   = 64,
        parameter NUMBER_SETS                   = 64,
        parameter NUMBER_WAYS                   = 16,
        parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUMBER_SETS)
)
(
        input                                                          reset_in,
        input                                                          clk_in,

        input                                                          access_en_in,
        input                                                          write_en_in,

        input  [SET_PTR_WIDTH_IN_BITS       - 1 : 0]                   access_set_addr_in,
        input  [NUMBER_WAYS                 - 1 : 0]                   way_select_in,

        output [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0]                   read_single_element_out,
        output [SINGLE_ELEMENT_SIZE_IN_BITS * NUMBER_WAYS - 1 : 0]     read_set_element_out,
        input  [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0]                   write_single_element_in
);

wire [SINGLE_ELEMENT_SIZE_IN_BITS * NUMBER_WAYS - 1 : 0] data_to_mux;
assign read_set_element_out = data_to_mux;

generate
        genvar gen;

        for(gen = 0; gen < NUMBER_WAYS; gen = gen + 1)
        begin

                single_port_blockram
                #(.SINGLE_ELEMENT_SIZE_IN_BITS(SINGLE_ELEMENT_SIZE_IN_BITS), .NUMBER_SETS(NUMBER_SETS), .SET_PTR_WIDTH_IN_BITS(SET_PTR_WIDTH_IN_BITS))
                data_way
                (
                        .clk_in                 (clk_in),

                        .access_en_in           (access_en_in & way_select_in[gen]),
                        .write_en_in            (write_en_in  & way_select_in[gen]),

                        .access_set_addr_in     (access_set_addr_in),

                        .write_element_in       (write_single_element_in),
                        .read_element_out       (data_to_mux[(gen+1) * SINGLE_ELEMENT_SIZE_IN_BITS - 1 : gen * SINGLE_ELEMENT_SIZE_IN_BITS])
                );

        end

endgenerate

reg [NUMBER_WAYS - 1 : 0] way_select_stage;
always @(posedge clk_in or posedge reset_in)
begin
        if(reset_in)
        begin
                way_select_stage        <= {(NUMBER_WAYS){1'b0}};
        end

        else
        begin
                way_select_stage        <= way_select_in;
        end
end

mux_decoded_8
#(.NUMBER_WAYS(NUMBER_WAYS), .SINGLE_ELEMENT_SIZE_IN_BITS(SINGLE_ELEMENT_SIZE_IN_BITS))
mux_8
(
        .way_packed_in (data_to_mux),
        .sel_in        (way_select_stage),
        .way_packed_out(read_single_element_out)
);

endmodule
