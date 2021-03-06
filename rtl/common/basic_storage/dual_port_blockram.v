`include "parameters.vh"

module dual_port_blockram
#(
    parameter SINGLE_ENTRY_WIDTH_IN_BITS  = 64,
    parameter NUM_SET                     = 64, /* must be a power of 2 */
    parameter SET_PTR_WIDTH_IN_BITS       = $clog2(NUM_SET),
    parameter WRITE_MASK_LEN              = SINGLE_ENTRY_WIDTH_IN_BITS / `BYTE_LEN_IN_BITS,
    parameter CONFIG_MODE                 = "ReadFirst", /* option: ReadFirst */
    parameter WITH_VALID_REG_ARRAY        = "Yes" /* option: Yes, No */
)
(
    input                                               reset_in,
    input                                               clk_in,

    input                                               write_port_access_en_in,
    input      [WRITE_MASK_LEN             - 1 : 0]     write_port_write_en_in,
    input      [SET_PTR_WIDTH_IN_BITS      - 1 : 0]     write_port_access_set_addr_in,
    input      [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]     write_port_data_in,

    input                                               read_port_access_en_in,
    input      [SET_PTR_WIDTH_IN_BITS      - 1 : 0]     read_port_access_set_addr_in,
    output reg [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]     read_port_data_out,
    output reg                                          read_port_valid_out
);

integer write_lane;
integer set_index;

// For valid array
generate

if(WITH_VALID_REG_ARRAY == "Yes")
begin
    reg  [NUM_SET - 1 : 0] valid_array;

    always@(posedge clk_in)
    begin
        if(reset_in)
        begin
            valid_array <= 0;
            read_port_valid_out <= 0;
        end

        else
        begin
            // validate
            if(write_port_access_en_in & |write_port_write_en_in)
            begin
                valid_array[write_port_access_set_addr_in] <= 1'b1;
            end

            // output
            if(read_port_access_en_in)
                read_port_valid_out <= valid_array[read_port_access_set_addr_in];
            else
                read_port_valid_out <= 0;
        end
    end
end

else
begin
    always@*
    begin
        if(reset_in)
        begin
            read_port_valid_out <= 0;
        end

        else
        begin
            read_port_valid_out <= 1;
        end
    end
end

endgenerate

(* ram_style = "block" *) reg [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0] blockram [NUM_SET - 1 : 0];

// write port operation
always @(posedge clk_in)
begin
    if(write_port_access_en_in)
    begin
        for(write_lane = 0; write_lane < WRITE_MASK_LEN; write_lane = write_lane + 1)
        begin
            if(write_port_write_en_in[write_lane])
            begin
                blockram[write_port_access_set_addr_in][write_lane * `BYTE_LEN_IN_BITS +: `BYTE_LEN_IN_BITS]
                <= write_port_data_in[write_lane * `BYTE_LEN_IN_BITS +: `BYTE_LEN_IN_BITS];
            end
        end
    end
end

generate
if(CONFIG_MODE == "ReadFirst")
begin
    // read port operation
    always @(posedge clk_in)
    begin
        if(read_port_access_en_in)
        begin
            read_port_data_out <= blockram[read_port_access_set_addr_in];
        end
    end
end

// this branch will incorrectly make vivado infer LUTRAM rather than BlockRAM
// it seems that write first mode can not be used together with byte-enable BlockRAM
else if(CONFIG_MODE == "WriteFirst")
begin
    wire need_write_forward = (read_port_access_en_in & write_port_access_en_in) & (|write_port_write_en_in) &
                              (read_port_access_set_addr_in == write_port_access_set_addr_in);

    wire [SINGLE_ENTRY_WIDTH_IN_BITS - 1: 0] write_port_full_data_mask;
    genvar byte_lane;
    for(byte_lane = 0; byte_lane < SINGLE_ENTRY_WIDTH_IN_BITS; byte_lane = byte_lane + 1)
    begin
        assign write_port_full_data_mask[byte_lane] = write_port_write_en_in[byte_lane / `BYTE_LEN_IN_BITS];
    end

    // read port operation
    always @(posedge clk_in)
    begin
        if(need_write_forward)
        begin
            read_port_data_out <= write_port_data_in & write_port_full_data_mask;
        end
        
        else if(read_port_access_en_in)
        begin
            read_port_data_out <= blockram[read_port_access_set_addr_in];
        end
    end
end

else
begin
    // read port operation
    always @(posedge clk_in)
    begin
        if(read_port_access_en_in)
        begin
            read_port_data_out <= blockram[read_port_access_set_addr_in];
        end
    end
end

endgenerate
endmodule
