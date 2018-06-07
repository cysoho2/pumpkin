module dual_port_blockram
#(
    parameter SINGLE_ELEMENT_SIZE_IN_BITS = 64,
    parameter NUMBER_SET                  = 64,
    parameter SET_PTR_WIDTH_IN_BITS       = 6
)
(
    input                                            clk_in,

    input                                            read_en_in,
    input      [SET_PTR_WIDTH_IN_BITS       - 1 : 0] read_set_addr_in,
    output reg [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] read_element_out,

    input                                            write_en_in,
    input      [SET_PTR_WIDTH_IN_BITS       - 1 : 0] write_set_addr_in,
    input      [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] write_element_in,
    output reg [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] evict_element_out
);

(* ram_style = "block" *) reg [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] blockram [NUMBER_SET - 1 : 0];

always @(posedge clk_in)
begin
    if(read_en_in)
    begin

        read_element_out <= blockram[read_set_addr_in];

        if(write_en_in)
        begin
            evict_element_out           <= blockram[write_set_addr_in];
            blockram[write_set_addr_in] <= write_element_in;
        end
    end
end
endmodule
