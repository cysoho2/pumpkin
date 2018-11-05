`include "parameters.h"

module single_port_lutram
#(
    parameter SINGLE_ENTRY_WIDTH_IN_BITS    = 64,
    parameter NUM_SET                       = 64,
    parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUM_SET),
    parameter WRITE_MASK_LEN                = SINGLE_ENTRY_WIDTH_IN_BITS / `BYTE_LEN_IN_BITS,
    parameter WITH_VALID_REG_ARRAY          = "Yes"
)
(
    input                                           clk_in,
    input                                           reset_in,

    input                                           access_en_in,
    input      [WRITE_MASK_LEN             - 1 : 0] write_en_in,
    input      [SET_PTR_WIDTH_IN_BITS      - 1 : 0] access_set_addr_in,

    input      [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0] write_entry_in,
    output     [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0] read_entry_out,
    output reg                                      read_valid_out
);

generate

if(WITH_VALID_REG_ARRAY == "Yes")
begin
    reg [NUM_SET - 1 : 0] valid_array;
    integer set_index;

    always@(posedge clk_in, posedge reset_in)
    begin
        if(reset_in)
        begin
            for(set_index = 0; set_index < NUM_SET; set_index = set_index + 1)
            begin
                valid_array[set_index] <= 0;
            end

            read_valid_out <= 0;
        end

        else
        begin
            // validate
            if(|write_en_in)
            begin
                valid_array[access_set_addr_in] <= 1'b1;
            end

            // output
            if(access_en_in)
                read_valid_out <= valid_array[access_set_addr_in];
            else
                read_valid_out <= 0;
        end
    end
end

else
begin
    always@*
    begin
        if(reset_in)
        begin
            read_valid_out <= 0;
        end

        else
        begin
            read_valid_out <= 1;
        end
    end
end

endgenerate

integer index;
integer write_lane;
(* ram_style = "distributed" *) reg [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0] lut_ram [NUM_SET - 1 : 0];

always @(posedge clk_in)
begin

    for(write_lane = 0; write_lane < WRITE_MASK_LEN; write_lane = write_lane + 1)
    begin
        if(write_en_in[write_lane] & access_en_in)
        begin
            lut_ram[access_set_addr_in][write_lane * `BYTE_LEN_IN_BITS +: `BYTE_LEN_IN_BITS]
                <= write_entry_in[write_lane * `BYTE_LEN_IN_BITS +: `BYTE_LEN_IN_BITS];
        end
    end
end

assign read_entry_out = lut_ram[access_set_addr_in];

endmodule
