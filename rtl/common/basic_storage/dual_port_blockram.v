`include "parameters.h"

module dual_port_blockram
#(
    parameter SINGLE_ENTRY_WIDTH_IN_BITS  = 64,
    parameter NUM_SET                     = 64,
    parameter SET_PTR_WIDTH_IN_BITS       = $clog2(NUM_SET),
    parameter WRITE_MASK_LEN              = SINGLE_ENTRY_WIDTH_IN_BITS / `BYTE_LEN_IN_BITS,
    parameter CONFIG_MODE                 = "ReadFirst", /* option: ReadFirst*/
    parameter WITH_VALID_REG_ARRAY        = "Yes"
)
(
    input                                               reset_in,
    input                                               clk_in,

    input                                               port_A_access_en_in,
    input      [WRITE_MASK_LEN             - 1 : 0]     port_A_write_en_in,
    input      [SET_PTR_WIDTH_IN_BITS      - 1 : 0]     port_A_access_set_addr_in,
    input      [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]     port_A_write_entry_in,
    output reg [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]     port_A_read_entry_out,
    output reg                                          port_A_read_valid_out,

    input                                               port_B_access_en_in,
    input      [WRITE_MASK_LEN             - 1 : 0]     port_B_write_en_in,
    input      [SET_PTR_WIDTH_IN_BITS      - 1 : 0]     port_B_access_set_addr_in,
    input      [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]     port_B_write_entry_in,
    output reg [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]     port_B_read_entry_out,
    output reg                                          port_B_read_valid_out
);

integer write_lane;
integer set_index;

generate

if(WITH_VALID_REG_ARRAY == "Yes")
begin
    reg [NUM_SET - 1 : 0] valid_array;

    always@(posedge clk_in)
    begin
        if(reset_in)
        begin
            for(set_index = 0; set_index < NUM_SET; set_index = set_index + 1)
            begin
                valid_array[set_index] <= 0;
            end

            port_A_read_valid_out <= 0;
            port_B_read_valid_out <= 0;
        end

        else
        begin
            // port-A validate
            if(port_A_access_en_in & |port_A_write_en_in)
            begin
                valid_array[port_A_access_set_addr_in] <= 1'b1;

                if(port_B_access_en_in & |port_B_write_en_in &
                   (port_A_access_set_addr_in != port_B_access_set_addr_in))
                begin
                    valid_array[port_B_access_set_addr_in] <= 1'b1;
                end
            end

            // port-B validate
            else if(port_B_access_en_in & |port_B_write_en_in)
            begin
                valid_array[port_B_access_set_addr_in] <= 1'b1;
            end

            // port-A output
            if(port_A_access_en_in)
                port_A_read_valid_out <= valid_array[port_A_access_set_addr_in];
            else
                port_A_read_valid_out <= 0;
            
            // port-B output
            if(port_B_access_en_in)
                port_B_read_valid_out <= valid_array[port_B_access_set_addr_in];
            else
                port_B_read_valid_out <= 0;
        end
    end
end

else
begin
    always@*
    begin
        if(reset_in)
        begin
            port_A_read_valid_out <= 0;
            port_B_read_valid_out <= 0;
        end

        else
        begin
            port_A_read_valid_out <= 1;
            port_B_read_valid_out <= 1;
        end
    end
end

endgenerate

(* ram_style = "block" *) reg [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0] blockram [NUM_SET - 1 : 0];

generate
if(CONFIG_MODE == "ReadFirst")
begin
    // port A operation
    always @(posedge clk_in)
    begin
        if(port_A_access_en_in)
        begin
            for(write_lane = 0; write_lane < WRITE_MASK_LEN; write_lane = write_lane + 1)
            begin
                if(port_A_write_en_in[write_lane])
                begin
                    blockram[port_A_access_set_addr_in][write_lane * `BYTE_LEN_IN_BITS +: `BYTE_LEN_IN_BITS]
                    <= port_A_write_entry_in[write_lane * `BYTE_LEN_IN_BITS +: `BYTE_LEN_IN_BITS];
                end
            end

            port_A_read_entry_out <= blockram[port_A_access_set_addr_in];
        end
    end

    // port B operation
    always @(posedge clk_in)
    begin
        if(port_B_access_en_in)
        begin
            for(write_lane = 0; write_lane < WRITE_MASK_LEN; write_lane = write_lane + 1)
            begin
                if(port_B_write_en_in[write_lane])
                begin
                    blockram[port_B_access_set_addr_in][write_lane * `BYTE_LEN_IN_BITS +: `BYTE_LEN_IN_BITS]
                    <= port_B_write_entry_in[write_lane * `BYTE_LEN_IN_BITS +: `BYTE_LEN_IN_BITS];
                end
            end

            port_B_read_entry_out <= blockram[port_B_access_set_addr_in];
        end
    end
end
endgenerate
endmodule
