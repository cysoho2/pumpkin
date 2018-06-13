module single_port_lutram
#(
    parameter SINGLE_ENTRY_SIZE_IN_BITS     = 64,
    parameter NUM_SET                       = 64,
    parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUM_SET)
)
(
    input                                               clk_in,
    input                                               reset_in,

    input                                               access_en_in,
    input                                               write_en_in,
    input      [SET_PTR_WIDTH_IN_BITS     - 1 : 0]      access_set_addr_in,

    input      [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]      write_entry_in,
    output reg [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]      read_entry_out
);

integer index;
reg [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0] lutram [NUM_SET - 1 : 0];

always @(posedge clk_in or posedge reset_in)
begin
    if(reset_in)
    begin
        for(index = 0; index < NUM_SET; index = index + 1)
        begin
            lutram[index] <= 0;
        end
    end
 
    else if(access_en_in)
    begin
        if(write_en_in)
        begin
            lutram[access_set_addr_in] <= write_entry_in;
        end

        else
        begin
            read_entry_out <= lutram[access_set_addr_in];
        end
    end
end
endmodule
