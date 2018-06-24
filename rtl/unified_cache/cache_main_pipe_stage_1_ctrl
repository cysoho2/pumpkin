`include "parameters.h"

module cache_main_pipe_stage_1_ctrl
#(
    parameter BANK_NUM                           = 0,
    parameter NUM_INPUT_PORT                     = 2,
    parameter UNIFIED_CACHE_PACKET_WIDTH_IN_BITS = `UNIFIED_CACHE_PACKET_WIDTH_IN_BITS,

    parameter NUM_SET                            = `UNIFIED_CACHE_NUM_SETS,
    parameter NUM_WAY                            = `UNIFIED_CACHE_SET_ASSOCIATIVITY,
    parameter BLOCK_SIZE_IN_BYTES                = `UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES,
    parameter SET_PTR_WIDTH_IN_BITS              = $clog2(NUM_SET)
)
(
    input                                                   reset_in,
    input                                                   clk_in,
    
    input   [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]    access_packet,
    output                                                  access_packet_ack,
    input                                                   bank_lock_release,

    // to valid, history, dirty, tag array
    output                                                  access_en_to_main_array_out,
    output                                                  write_en_to_main_array_out,
    output  [NUM_WAY                            - 1 : 0]    way_select_to_main_array_out,
    output  [SET_PTR_WIDTH_IN_BITS              - 1 : 0]    access_set_addr_to_main_array_out,
    output                                                  write_single_entry_to_main_array_out,

    // to miss/writeback buffer tag, valid, fetched, array
    output                                                  read_en_to_side_buffer_out,
    output                                                  write_en_to_side_buffer_out,
    output  [SET_PTR_WIDTH_IN_BITS              - 1 : 0]    read_entry_addr_decoded_to_side_buffer_out,
    output  [SET_PTR_WIDTH_IN_BITS              - 1 : 0]    write_entry_addr_decoded_to_side_buffer_out,
                        
    output                                                  cam_en_to_side_buffer_out,
    output                                                  cam_entry_to_side_buffer_out,
    output                                                  write_entry_to_side_buffer_output
);

reg  bank_lock;
wire issue_grant = access_packet[`UNIFIED_CACHE_PACKET_VALID_POS] & (~bank_lock | (bank_lock & bank_lock_release));

always@(posedge clk_in or posedge reset_in)
begin
    if(reset_in)
    begin
        bank_lock           <= 1'b0;
        access_packet_ack   <= 1'b0;
    end
    
    else if(issue_grant)
    begin
        bank_lock           <= 1'b1;
        access_packet_ack   <= 1'b0;
    end

    else if(bank_lock & bank_lock_release)
    begin
        bank_lock           <= 1'b0;
        access_packet_ack   <= 1'b1;
    end

    else
    begin
        bank_lock           <= bank_lock;
        access_packet_ack   <= 1'b0;
    end
end

wire access_full_addr = access_packet[`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO];

always@*
begin
    if(issue_grant) // ready to issue request
    begin
        // to valid, history, dirty, tag array
        access_en_to_main_array_out                     <= 1'b1;
        write_en_to_main_array_out                      <= 1'b0;
        way_select_to_main_array_out                    <= {(NUM_WAY){1'b1}};
        access_set_addr_to_main_array_out               <= access_full_addr[`UNIFIED_CACHE_INDEX_POS_HI : `UNIFIED_CACHE_INDEX_POS_HI];
        write_single_entry_to_main_array_out            <= 1'b0;

        // to miss/writeback buffer tag, valid, fetched, array
        read_en_to_side_buffer_out                      <= 1'b1;
        write_en_to_side_buffer_out                     <= 1'b0; 
        read_entry_addr_decoded_to_side_buffer_out      <= 0;
        write_entry_addr_decoded_to_side_buffer_out     <= 0;
        cam_en_to_side_buffer_out                       <= 1'b1;
        cam_entry_to_side_buffer_out                    <= access_full_addr[`UNIFIED_CACHE_TAG_POS_HI : `UNIFIED_CACHE_TAG_POS_LO];
        write_entry_to_side_buffer_out                  <= 0;
    end

    else
    begin
        // to valid, history, dirty, tag array
        access_en_to_main_array_out                     <= 1'b0;
        write_en_to_main_array_out                      <= 1'b0;
        way_select_to_main_array_out                    <= {(NUM_WAY){1'b0}};
        access_set_addr_to_main_array_out               <= 0;
        write_single_entry_to_main_array_out            <= 1'b0;

        // to miss/writeback buffer tag, valid, fetched, array
        read_en_to_side_buffer_out                      <= 1'b0;
        write_en_to_side_buffer_out                     <= 1'b0; 
        read_entry_addr_decoded_to_side_buffer_out      <= 0;
        write_entry_addr_decoded_to_side_buffer_out     <= 0;
        cam_en_to_side_buffer_out                       <= 1'b0;
        cam_entry_to_side_buffer_out                    <= 0;
        write_entry_to_side_buffer_output               <= 0;
    end
end
endmodule