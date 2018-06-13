module single_port_blockram
#(
    parameter SINGLE_ENTRY_SIZE_IN_BITS     = 64,
    parameter NUM_SET                       = 64,
    parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUM_SET)
)
(
    input                                               clk_in,

    input                                               access_en_in,
    input                                               write_en_in,
    input      [SET_PTR_WIDTH_IN_BITS     - 1 : 0]      access_set_addr_in,

    input      [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]      write_entry_in,
    output reg [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]      read_entry_out
);

(* ram_style = "block" *) reg [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0] blockram [NUM_SET - 1 : 0];

always @(posedge clk_in)
begin
    if(access_en_in)
    begin
        if(write_en_in)
        begin
            blockram[access_set_addr_in] <= write_entry_in;
        end

        else
        begin
            read_entry_out <= blockram[access_set_addr_in];
        end
    end
end
endmodule
