`include "parameters.h"

`define IDLE        4'b0000
`define JUDGE       4'b0001
`define READ_HIT    4'b0010
`define READ_MISS   4'b0011
`define WRITE_HIT   4'b0100
`define WRITE_MISS  4'b0101

module cache_bank_basic_ctrl
#(
    parameter BANK_NUM                           = 0,
    
    parameter NUM_INPUT_PORT                     = 2,
    parameter NUM_SET                            = 4,
    parameter NUM_WAY                            = 4,
    parameter BLOCK_SIZE_IN_BYTES                = 4,

    parameter UNIFIED_CACHE_PACKET_WIDTH_IN_BITS = 80,
    parameter BLOCK_SIZE_IN_BITS                 = BLOCK_SIZE_IN_BYTES * `BYTE_LEN_IN_BITS,
    parameter SET_PTR_WIDTH_IN_BITS              = $clog2(NUM_SET),
    parameter WRITE_MASK_LEN                     = BLOCK_SIZE_IN_BITS / `BYTE_LEN_IN_BITS,
    parameter UNIFIED_CACHE_TAG_LEN_IN_BITS      = `CPU_ADDR_LEN_IN_BITS - `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS - `UNIFIED_CACHE_INDEX_LEN_IN_BITS
)
(
    input                                                                   reset_in,
    input                                                                   clk_in,
    
    input       [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS         - 1 : 0]        access_packet,
    output  reg                                                             access_packet_ack,

    input       [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS          - 1 : 0]       fetched_request_in,
    input                                                                   fetched_request_valid_in,
    output  reg                                                             fetched_request_ack_out,

    output  reg [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS          - 1 : 0]       miss_request_out,
    output  reg                                                             miss_request_valid_out,
    output  reg                                                             miss_request_critical_out,
    input                                                                   miss_request_ack_in,

    output  reg [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS          - 1 : 0]       writeback_request_out,
    output  reg                                                             writeback_request_valid_out,
    output  reg                                                             writeback_request_critical_out,
    input                                                                   writeback_request_ack_in,

    output  reg [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS          - 1 : 0]       return_request_out,
    output  reg                                                             return_request_valid_out,
    output  reg                                                             return_request_critical_out,
    input                                                                   return_request_ack_in,

    input   [NUM_WAY                                         - 1 : 0]       valid_flatted_in,
    input   [NUM_WAY                                         - 1 : 0]       history_flatted_in,
    input   [NUM_WAY * UNIFIED_CACHE_TAG_LEN_IN_BITS         - 1 : 0]       tag_flatted_in,
    input   [BLOCK_SIZE_IN_BITS                              - 1 : 0]       data_in,

    // to valid, tag array
    output  reg                                                             access_en_to_main_array_out,
    output  reg                                                             write_en_to_main_array_out,
    output  reg [NUM_WAY                                     - 1 : 0]       way_select_to_main_array_out,
    output  reg [SET_PTR_WIDTH_IN_BITS                       - 1 : 0]       access_set_addr_to_main_array_out,

    // to history array
    output  reg                                                             access_en_to_history_array_out,
    output  reg                                                             write_en_to_history_array_out,
    output  reg [NUM_WAY                                     - 1 : 0]       way_select_to_history_array_out,
    output  reg [SET_PTR_WIDTH_IN_BITS                       - 1 : 0]       access_set_addr_to_history_array_out,

    // to data array
    output  reg                                                             access_en_to_data_array_out,
    output  reg                                                             write_en_to_data_array_out,
    output  reg [NUM_WAY                                     - 1 : 0]       way_select_to_data_array_out,
    output  reg [SET_PTR_WIDTH_IN_BITS                       - 1 : 0]       access_set_addr_to_data_array_out,
    
    // write signals
    output  reg [NUM_WAY                                     - 1 : 0]       write_valid_out,
    output  reg [NUM_WAY                                     - 1 : 0]       write_history_out,
    output  reg [UNIFIED_CACHE_TAG_LEN_IN_BITS               - 1 : 0]       write_tag_out,
    output  reg [BLOCK_SIZE_IN_BITS                          - 1 : 0]       write_data_out,
    output  reg [WRITE_MASK_LEN                              - 1 : 0]       write_mask_to_data_array_out
);

reg  bank_lock;
reg  bank_lock_release;
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

wire [`CPU_ADDR_LEN_IN_BITS            - 1 : 0] access_full_addr = access_packet[`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO];
wire [`UNIFIED_CACHE_INDEX_LEN_IN_BITS - 1 : 0] access_set_addr  = access_full_addr[`UNIFIED_CACHE_INDEX_POS_HI : `UNIFIED_CACHE_INDEX_POS_LO];
wire                                            is_write         = access_packet[`UNIFIED_CACHE_PACKET_IS_WRITE_POS];
wire [WRITE_MASK_LEN                   - 1 : 0] write_mask       = access_packet[`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO];

wire [NUM_WAY - 1 : 0]                          hit_flatted;
reg  [3           : 0]                          stage;

generate
genvar way_index;
    for(way_index = 0; way_index < NUM_WAY; way_index = way_index + 1)
    begin
        assign hit_flatted[way_index] = 
                    (tag_flatted_in[way_index * UNIFIED_CACHE_TAG_LEN_IN_BITS +: UNIFIED_CACHE_TAG_LEN_IN_BITS]
                        == access_full_addr[`UNIFIED_CACHE_TAG_POS_HI : `UNIFIED_CACHE_TAG_POS_LO])
                    & valid_flatted_in[way_index];
    end
endgenerate

always@(posedge clk_in or posedge reset_in)
begin
    if(reset_in)
    begin
        stage                                           <= `IDLE;
        bank_lock_release                               <= 0;
        // to valid, tag array
        access_en_to_main_array_out                     <= 0;
        write_en_to_main_array_out                      <= 0;
        way_select_to_main_array_out                    <= {(NUM_WAY){1'b0}};
        access_set_addr_to_main_array_out               <= 0;
        // to history array
        access_en_to_history_array_out                  <= 0;
        write_en_to_history_array_out                   <= 0;
        way_select_to_history_array_out                 <= {(NUM_WAY){1'b0}};
        access_set_addr_to_history_array_out            <= 0;
        // to data array
        access_en_to_data_array_out                     <= 0;
        write_en_to_data_array_out                      <= 0;
        way_select_to_data_array_out                    <= {(NUM_WAY){1'b0}};
        access_set_addr_to_data_array_out               <= 0;

        write_valid_out                                 <= {(NUM_WAY){1'b0}};
        write_history_out                               <= {(NUM_WAY){1'b0}};
        write_tag_out                                   <= {(UNIFIED_CACHE_TAG_LEN_IN_BITS){1'b0}};
        write_data_out                                  <= {(BLOCK_SIZE_IN_BITS){1'b0}};
        write_mask_to_data_array_out                    <= {(WRITE_MASK_LEN){1'b0}};

        access_packet_ack                               <= 1'b0;
        fetched_request_ack_out                         <= 1'b0;
        
        miss_request_out                                <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
        miss_request_valid_out                          <= 1'b0;
        miss_request_critical_out                       <= 1'b0;
        writeback_request_out                           <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
        writeback_request_valid_out                     <= 1'b0;
        writeback_request_critical_out                  <= 1'b0;
        return_request_out                              <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
        return_request_valid_out                        <= 1'b0;
        return_request_critical_out                     <= 1'b0;
    end

    else
    begin
        if(issue_grant && stage == `IDLE) // ready to issue request
        begin
            stage                                           <= `JUDGE;
            bank_lock_release                               <= 1'b0;
            // to valid, tag array
            access_en_to_main_array_out                     <= 1'b1;
            write_en_to_main_array_out                      <= 1'b0;
            way_select_to_main_array_out                    <= {(NUM_WAY){1'b1}};
            access_set_addr_to_main_array_out               <= access_set_addr;
            // to history array
            access_en_to_history_array_out                  <= 1'b1;
            write_en_to_history_array_out                   <= 1'b0;
            way_select_to_history_array_out                 <= {(NUM_WAY){1'b1}};
            access_set_addr_to_history_array_out            <= access_set_addr;
            // to data array
            access_en_to_data_array_out                     <= 0;
            write_en_to_data_array_out                      <= 0;
            way_select_to_data_array_out                    <= {(NUM_WAY){1'b0}};
            access_set_addr_to_data_array_out               <= 0;
            
            write_valid_out                                 <= {(NUM_WAY){1'b0}};
            write_history_out                               <= {(NUM_WAY){1'b0}};
            write_tag_out                                   <= {(UNIFIED_CACHE_TAG_LEN_IN_BITS){1'b0}};
            write_data_out                                  <= {(BLOCK_SIZE_IN_BITS){1'b0}};
            write_mask_to_data_array_out                    <= {(WRITE_MASK_LEN){1'b0}};

            access_packet_ack                               <= 1'b0;
            fetched_request_ack_out                         <= 1'b0;

            miss_request_out                                <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
            miss_request_valid_out                          <= 1'b0;
            miss_request_critical_out                       <= 1'b0;
            writeback_request_out                           <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
            writeback_request_valid_out                     <= 1'b0;
            writeback_request_critical_out                  <= 1'b0;
            return_request_out                              <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
            return_request_valid_out                        <= 1'b0;
            return_request_critical_out                     <= 1'b0;
        end

        else if(stage == `JUDGE)
        begin
            if( (|hit_flatted) && ~is_write )
            begin
                stage                                           <= `READ_HIT;
                bank_lock_release                               <= 1'b0;

                // to valid, tag array
                access_en_to_main_array_out                     <= 1'b1;
                write_en_to_main_array_out                      <= 1'b0;
                way_select_to_main_array_out                    <= {(NUM_WAY){1'b1}};
                access_set_addr_to_main_array_out               <= access_set_addr;
                // to history array
                access_en_to_history_array_out                  <= 1'b1;
                write_en_to_history_array_out                   <= 1'b0;
                way_select_to_history_array_out                 <= {(NUM_WAY){1'b1}};
                access_set_addr_to_history_array_out            <= access_set_addr;
                // to data array
                access_en_to_data_array_out                     <= 1'b1;
                write_en_to_data_array_out                      <= 1'b0;
                way_select_to_data_array_out                    <= hit_flatted;
                access_set_addr_to_data_array_out               <= access_set_addr;
                
                write_valid_out                                 <= {(NUM_WAY){1'b0}};
                write_history_out                               <= hit_flatted | history_flatted_in;
                write_tag_out                                   <= {(UNIFIED_CACHE_TAG_LEN_IN_BITS){1'b0}};
                write_data_out                                  <= {(BLOCK_SIZE_IN_BITS){1'b0}};
                write_mask_to_data_array_out                    <= {(WRITE_MASK_LEN){1'b0}};

                access_packet_ack                               <= 1'b0;
                fetched_request_ack_out                         <= 1'b0;

                miss_request_out                                <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
                miss_request_valid_out                          <= 1'b0;
                miss_request_critical_out                       <= 1'b0;
                writeback_request_out                           <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
                writeback_request_valid_out                     <= 1'b0;
                writeback_request_critical_out                  <= 1'b0;
                return_request_out                              <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
                return_request_valid_out                        <= 1'b0;
                return_request_critical_out                     <= 1'b0;
            end
            
            else if( ~(|hit_flatted) && ~is_write )
            begin
                stage                                           <= `READ_MISS;
                bank_lock_release                               <= 1'b0;

                // to valid, tag array
                access_en_to_main_array_out                     <= 1'b0;
                write_en_to_main_array_out                      <= 1'b0;
                way_select_to_main_array_out                    <= {(NUM_WAY){1'b0}};
                access_set_addr_to_main_array_out               <= 0;
                // to history array
                access_en_to_history_array_out                  <= 1'b0;
                write_en_to_history_array_out                   <= 1'b0;
                way_select_to_history_array_out                 <= {(NUM_WAY){1'b0}};
                access_set_addr_to_history_array_out            <= 0;
                // to data array
                access_en_to_data_array_out                     <= 1'b0;
                write_en_to_data_array_out                      <= 1'b0;
                way_select_to_data_array_out                    <= {(NUM_WAY){1'b0}};
                access_set_addr_to_data_array_out               <= 0;
                
                write_valid_out                                 <= {(NUM_WAY){1'b0}};
                write_history_out                               <= {(NUM_WAY){1'b0}};
                write_tag_out                                   <= {(UNIFIED_CACHE_TAG_LEN_IN_BITS){1'b0}};
                write_data_out                                  <= {(BLOCK_SIZE_IN_BITS){1'b0}};
                write_mask_to_data_array_out                    <= {(WRITE_MASK_LEN){1'b0}};

                access_packet_ack                               <= 1'b0;
                fetched_request_ack_out                         <= 1'b0;

                miss_request_out                                <= access_packet;
                miss_request_valid_out                          <= 1'b1;
                miss_request_critical_out                       <= 1'b1;
                writeback_request_out                           <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
                writeback_request_valid_out                     <= 1'b0;
                writeback_request_critical_out                  <= 1'b0;
                return_request_out                              <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
                return_request_valid_out                        <= 1'b1;
                return_request_critical_out                     <= 1'b1;
            end
            
            else if( (|hit_flatted) && is_write )
            begin
                stage <= `WRITE_HIT;
            end
            
            else if( ~(|hit_flatted) && is_write )
            begin
                stage <= `WRITE_MISS;
            end
        end

        else if(stage == `READ_HIT)
        begin
            if(return_request_ack_in & return_request_valid_out)
            begin
                stage                                       <= `IDLE;
                bank_lock_release                           <= 1'b1;
            end

            else
            begin
                stage                                       <= `READ_HIT;
                bank_lock_release                           <= 1'b0;
            end
            
            // to valid, tag array
            access_en_to_main_array_out                     <= 1'b1;
            write_en_to_main_array_out                      <= 1'b0;
            way_select_to_main_array_out                    <= {(NUM_WAY){1'b1}};
            access_set_addr_to_main_array_out               <= access_set_addr;
            // to history array
            access_en_to_history_array_out                  <= 1'b1;
            write_en_to_history_array_out                   <= 1'b0;
            way_select_to_history_array_out                 <= {(NUM_WAY){1'b1}};
            access_set_addr_to_history_array_out            <= access_set_addr;
            // to data array
            access_en_to_data_array_out                     <= 1'b1;
            write_en_to_data_array_out                      <= 1'b0;
            way_select_to_data_array_out                    <= hit_flatted;
            access_set_addr_to_data_array_out               <= access_set_addr;
            
            write_valid_out                                 <= {(NUM_WAY){1'b0}};
            write_history_out                               <= {(NUM_WAY){1'b0}};
            write_tag_out                                   <= {(UNIFIED_CACHE_TAG_LEN_IN_BITS){1'b0}};
            write_data_out                                  <= {(BLOCK_SIZE_IN_BITS){1'b0}};
            write_mask_to_data_array_out                    <= {(WRITE_MASK_LEN){1'b0}};

            access_packet_ack                               <= 1'b0;
            fetched_request_ack_out                         <= 1'b0;

            miss_request_out                                <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
            miss_request_valid_out                          <= 1'b0;
            miss_request_critical_out                       <= 1'b0;
            writeback_request_out                           <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
            writeback_request_valid_out                     <= 1'b0;
            writeback_request_critical_out                  <= 1'b0;
            return_request_out                              <=
            {   
                /*cacheable*/   {access_packet[`UNIFIED_CACHE_PACKET_CACHEABLE_POS]},
                /*write*/       {access_packet[`UNIFIED_CACHE_PACKET_IS_WRITE_POS]},                   
                /*valid*/       {access_packet[`UNIFIED_CACHE_PACKET_VALID_POS]},
                /*port*/        {access_packet[`UNIFIED_CACHE_PACKET_PORT_NUM_HI : `UNIFIED_CACHE_PACKET_PORT_NUM_LO]},
                /*byte mask*/   {access_packet[`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO]},     
                /*type*/        {access_packet[`UNIFIED_CACHE_PACKET_TYPE_POS_HI : `UNIFIED_CACHE_PACKET_TYPE_POS_LO]},
                /*data*/        {data_in},
                /*addr*/        {access_packet[`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO]}
            };
            return_request_valid_out                        <= 1'b1;
            return_request_critical_out                     <= 1'b1;
        end

        else if(stage == `READ_MISS)
        begin
            if(fetched_request_valid_in)
            begin
                return_request_out                          <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
                return_request_valid_out                    <= 1'b1;
                return_request_critical_out                 <= 1'b1;
            end

            // to valid, tag array
            access_en_to_main_array_out                     <= 1'b0;
            write_en_to_main_array_out                      <= 1'b0;
            way_select_to_main_array_out                    <= {(NUM_WAY){1'b0}};
            access_set_addr_to_main_array_out               <= 0;
            // to history array
            access_en_to_history_array_out                  <= 1'b0;
            write_en_to_history_array_out                   <= 1'b0;
            way_select_to_history_array_out                 <= {(NUM_WAY){1'b0}};
            access_set_addr_to_history_array_out            <= 0;
            // to data array
            access_en_to_data_array_out                     <= 1'b1;
            write_en_to_data_array_out                      <= 1'b0;
            way_select_to_data_array_out                    <= {(NUM_WAY){1'b0}};
            access_set_addr_to_data_array_out               <= 0;
            
            write_valid_out                                 <= {(NUM_WAY){1'b0}};
            write_history_out                               <= {(NUM_WAY){1'b0}};
            write_tag_out                                   <= {(UNIFIED_CACHE_TAG_LEN_IN_BITS){1'b0}};
            write_data_out                                  <= {(BLOCK_SIZE_IN_BITS){1'b0}};
            write_mask_to_data_array_out                    <= {(WRITE_MASK_LEN){1'b0}};

            access_packet_ack                               <= 1'b0;
            fetched_request_ack_out                         <= 1'b0;

            if(miss_request_ack_in & miss_request_valid_out)
            begin
                miss_request_out                            <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
                miss_request_valid_out                      <= 1'b0;
                miss_request_critical_out                   <= 1'b0;
            end

            else if(miss_request_valid_out)
            begin
                miss_request_out                            <= access_packet;
                miss_request_valid_out                      <= 1'b1;
                miss_request_critical_out                   <= 1'b1;
            end

            writeback_request_out                           <= {(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
            writeback_request_valid_out                     <= 1'b0;
            writeback_request_critical_out                  <= 1'b0;
        end
    end
end
endmodule