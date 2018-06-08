module tri_port_regfile
#(
    parameter SINGLE_ENTRY_SIZE_IN_BITS = 8,
    parameter NUMBER_ENTRY              = 4
)
(
    input                                                   reset_in,
    input                                                   clk_in,

    input                                                   read_en_in,
    input                                                   write_en_in,
    input                                                   cam_en_in,

    input      [NUMBER_ENTRY   - 1 : 0]                     read_entry_addr_decoded_in,
    input      [NUMBER_ENTRY   - 1 : 0]                     write_entry_addr_decoded_in,
    input      [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]          cam_entry_in,

    input      [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]          write_entry_in,
    output reg [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]          read_entry_out,
    output reg [NUMBER_ENTRY              - 1 : 0]          cam_result_decoded_out,

    output reg [NUMBER_ENTRY              - 1 : 0]          entry_valid_flatted_out
);

generate
genvar gen;

    reg [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0] entry;
    reg                                     entry_valid;

    always @(posedge clk_in, posedge reset_in)
    begin
        if(reset_in)
        begin
            entry       <= {(SINGLE_ENTRY_SIZE_IN_BITS){1'b0}};
            entry_valid <= 0;
        end

        else
        begin

            // write entry
            if(write_en_in && write_entry_addr_decoded_in[gen])
            begin
                entry       <= write_entry_in;
                if(~entry_valid)
                    entry_valid <= 1'b1;
                else entry_valid <= entry_valid;
            end

            // read entry
            if(read_en_in && read_entry_addr_decoded_in[gen])
            begin
                read_entry_out <= entry;
            end

            else
            begin
                read_entry_out <= 0;
            end

            // cam
            if(cam_en_in)
            begin
                cam_result_decoded_out[gen] = (entry_valid & (entry == cam_entry_in)) ? 1'b1 : 1'b0;
            end

            else
            begin
                cam_result_decoded_out[gen] = 1'b0;
            end
        end
    end

endgenerate

endmodule
