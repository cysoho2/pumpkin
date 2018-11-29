module replacer
#(
    parameter NUM_WAY      = 8,
    parameter NUM_SET      = 64,
    parameter STORAGE_TYPE = "LUTRAM", /* option: LUTRAM, BlockRAM */
    parameter ALGORITHM    = "1-bit NRU" /* option: 1-bit NRU */
)
(
    input                    clk_in,
    input                    reset_in,

    input  [NUM_WAY - 1 : 0] valid_flatted_in,
    input  [NUM_WAY - 1 : 0] used_way_decoded_in,
    output [NUM_WAY - 1 : 0] replaced_way_out,
    
    input                    replacer_read_en_in,
    input                    replacer_read_set_addr_in,

    input                    replacer_write_en_in,
    input                    replacer_write_set_addr_in
);

wire [31:0] invalid_index;
wire        invalid_is_found;
find_first_one_index
#(
    .VECTOR_LENGTH(NUM_WAY)
)
first_invalid_index
(
    .vector_in(~valid_flatted_in),
    .first_one_index_out(invalid_index),
    .one_is_found_out(invalid_is_found)
);

wire [31:0] victim_index;

assign replaced_way_out = invalid_is_found ? invalid_index : 
                          (victim_is_find ? victim_index : 0);

// insert replacing policy here
generate
if(ALGORITHM == "1-bit NRU")
begin
    wire [NUM_WAY - 1 : 0] read_history;
    wire [NUM_WAY - 1 : 0] write_history;

    find_first_one_index
    #(
        .VECTOR_LENGTH(NUM_WAY)
    )
    first_invalid_index
    (
        .vector_in(~read_history),
        .first_one_index_out(victim_index),
        .one_is_found_out(victim_is_find)
    );

    always@(posedge clk_in)
    begin
        if(reset_in)
        begin
            bank_lock               <= 1'b0;
            access_packet_ack_out   <= 1'b0;
        end

        else if(bank_lock & bank_lock_release)
        begin
            bank_lock               <= 1'b0;
            access_packet_ack_out   <= 1'b1;
        end
    end

    integer way_index;
    wire [NUM_WAY - 1 : 0] replacer_write_expand;
    for(way_index = 0; way_index < NUM_WAY; way_index = way_index + 1)
    begin
        assign replacer_write_expand[way_index] = replacer_write_en_in;
    end
    
    if(STORAGE_TYPE == "LUTRAM")
    begin
        assign read_history = ram_output;
        assign ram_input    = write_history;
        
        dual_port_lutram
        #(
            .SINGLE_ENTRY_WIDTH_IN_BITS     (SINGLE_ENTRY_WIDTH_IN_BITS),
            .NUM_SET                        (QUEUE_SIZE),
            .CONFIG_MODE                    ("WriteFirst"),
            .WITH_VALID_REG_ARRAY           ("No")
        )
        history_array
        (
            .clk_in                         (clk_in),
            .reset_in                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    (reset_in),

            .write_port_access_en_in        (1'b1),
            .write_port_write_en_in         (replacer_write_expand),
            .write_port_access_set_addr_in  (replacer_write_set_addr_in),
            .write_port_data_in             (ram_input),

            .read_port_access_en_in         (replacer_read_en_in),
            .read_port_access_set_addr_in   (replacer_read_set_addr_in),
            .read_port_data_out             (ram_output),
            .read_port_valid_out            ()
        );
    end

    else if(STORAGE_TYPE == "BlockRAM")
    begin
        assign read_history = ram_output;
        assign ram_input    = write_history;
        
        dual_port_blockram
        #(
            .SINGLE_ENTRY_WIDTH_IN_BITS     (SINGLE_ENTRY_WIDTH_IN_BITS),
            .NUM_SET                        (QUEUE_SIZE),
            .CONFIG_MODE                    ("WriteFirst"),
            .WITH_VALID_REG_ARRAY           ("No")
        )
        history_array
        (
            .clk_in                         (clk_in),
            .reset_in                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    (reset_in),

            .write_port_access_en_in        (1'b1),
            .write_port_write_en_in         (replacer_write_expand),
            .write_port_access_set_addr_in  (replacer_write_set_addr_in),
            .write_port_data_in             (ram_input),

            .read_port_access_en_in         (replacer_read_en_in),
            .read_port_access_set_addr_in   (replacer_read_set_addr_in),
            .read_port_data_out             (ram_output),
            .read_port_valid_out            ()
        );
    end
end
endgenerate


endmodule
