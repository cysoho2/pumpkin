`include "prefetcher_parameters.h"
//`include "find_first_one_index.v"

`define IDLE_TO_SIG_TABLE_ACCESS                                                0
`define SIG_TABLE_ACCESS_TO_UPDATE                                              1
`define SIG_TABLE_UPDATE_TO_PT_TABLE_ACCESS                                     2
`define PT_TABLE_ACCESS_TO_UPDATE                                               3
`define PREFETCH_ISSUE                                                          4

module spp_main_ctrl
#(
        parameter ADDR_WIDTH                    = 64,
        parameter SIG_TABLE_SET_INDEX_BITS      = `SIG_TABLE_SET_INDEX_BITS,
        parameter PT_TABLE_SIG_INDEX_BITS       = `PT_TABLE_SIG_INDEX_BITS,
        parameter PT_TABLE_SIG_TAG_BITS         = `PT_TABLE_SIG_TAG_BITS,
        parameter PT_TABLE_DELTA_INDEX_BITS     = `PT_TABLE_DELTA_INDEX_BITS
)
(
        input reset_in,
        input clk_in,

        // input request queue
        output reg                                                                                              ack_to_input_request_queue_out,
        input           [ADDR_WIDTH                                                              - 1 : 0]       access_address_in, 
        input                                                                                                   access_address_valid_in,

        // prefetch output queue
        output reg      [ADDR_WIDTH                                                              - 1 : 0]       prefetch_to_output_queue_out,
        output reg                                                                                              prefetch_to_output_queue_valid_out,
        input                                                                                                   output_queue_ack_in,

        // signature table
        // sig_tag_common
        output reg                                                                                              access_en_to_sig_tag_out,
        output reg      [SIG_TABLE_SET_INDEX_BITS                                                - 1 : 0]       access_set_addr_to_sig_tag_out,
        output reg                                                                                              write_en_to_sig_tag_out,
        output reg      [`SIG_TABLE_ASSOCIATIVITY                                                - 1 : 0]       way_select_to_sig_tag_out,
                
        // sig valid array
        input           [`SIG_TABLE_ASSOCIATIVITY                                                - 1 : 0]       read_set_page_valid_in,

        // sig page tag array
        input           [`SIG_TABLE_PAGE_NUM_TAG_BITS * `SIG_TABLE_ASSOCIATIVITY                 - 1 : 0]       read_set_page_tag_in,
        output reg      [`SIG_TABLE_PAGE_NUM_TAG_BITS                                            - 1 : 0]       write_page_tag_out,

        // sig_data_common
        output reg                                                                                              access_en_to_sig_data_out,
        output reg      [SIG_TABLE_SET_INDEX_BITS                                                - 1 : 0]       access_set_addr_to_sig_data_out,
        output reg                                                                                              write_en_to_sig_data_out,
        output reg      [`SIG_TABLE_ASSOCIATIVITY                                                - 1 : 0]       way_select_to_sig_data_out,

        // sig array
        input           [`SIG_LENTH * `SIG_TABLE_ASSOCIATIVITY                                   - 1 : 0]       read_set_sig_in,
        output reg      [`SIG_LENTH                                                              - 1 : 0]       write_sig_out,

        // sig blockID array
        input           [6 * `SIG_TABLE_ASSOCIATIVITY                                            - 1 : 0]       read_set_sig_blockID_in,    
        output reg      [5:0]                                                                                   write_sig_blockID_out,

        // pattern table
        // pt_sig_tag_common
        output reg                                                                                              access_en_to_pt_sig_tag_out,
        output reg      [PT_TABLE_SIG_INDEX_BITS                                                 - 1 : 0]       access_set_addr_to_pt_sig_tag_out,
        output reg      [`PT_TABLE_SIG_ASSOCIATIVITY                                             - 1 : 0]       way_select_to_pt_sig_tag_out,
        output reg                                                                                              write_en_to_pt_sig_tag_out,

        // pt_sig_valid
        input           [`PT_TABLE_SIG_ASSOCIATIVITY                                             - 1 : 0]       read_set_pt_valid_in,

        // pt_sig_tag
        input           [PT_TABLE_SIG_TAG_BITS * `PT_TABLE_SIG_ASSOCIATIVITY                     - 1 : 0]       read_set_pt_sig_tag_in,
        output reg      [PT_TABLE_SIG_TAG_BITS                                                   - 1 : 0]       write_pt_sig_tag_out,

        // pt_sig_counter
        output reg                                                                                              access_en_to_pt_sig_data_out,
        output reg      [PT_TABLE_SIG_INDEX_BITS                                                 - 1 : 0]       access_set_addr_to_pt_sig_data_out,
        output reg      [`PT_TABLE_SIG_ASSOCIATIVITY                                             - 1 : 0]       way_select_to_pt_sig_data_out,
        output reg                                                                                              write_en_to_pt_sig_data_out,
                
        input           [`PT_TABLE_SIG_COUNTER_BITS * `PT_TABLE_SIG_COUNTER_BITS                 - 1 : 0]       read_set_pt_sig_counter_in,
        output reg      [`PT_TABLE_SIG_COUNTER_BITS                                              - 1 : 0]       write_pt_sig_counter_out,

                
        // pt_delta_tag_common
        output reg                                                                                              access_en_to_pt_delta_tag_out,
        output reg      [PT_TABLE_DELTA_INDEX_BITS                                               - 1 : 0]       access_set_addr_to_pt_delta_tag_out,
        output reg      [`PT_TABLE_DELTA_ASSOCIATIVITY                                           - 1 : 0]       way_select_to_pt_delta_tag_out,
        output reg                                                                                              write_en_to_pt_delta_tag_out,

        // pt_delta_valid
        input           [`PT_TABLE_DELTA_ASSOCIATIVITY                                           - 1 : 0]       read_set_pt_delta_valid_in,
                        
        // pt_delta
        input           [`PT_TABLE_DELTA_ASSOCIATIVITY * `DELTA_BITS                             - 1 : 0]       read_set_pt_delta_in,
        output reg      [`DELTA_BITS                                                             - 1 : 0]       write_pt_delta_out,

        // pt_delta_counter
        output reg                                                                                              access_en_to_pt_delta_data_out,
        output reg      [PT_TABLE_DELTA_INDEX_BITS                                               - 1 : 0]       access_set_addr_to_pt_delta_data_out,
        output reg      [`PT_TABLE_DELTA_ASSOCIATIVITY                                           - 1 : 0]       way_select_to_pt_delta_data_out,
        output reg                                                                                              write_en_to_pt_delta_data_out,
                
        input           [`PT_TABLE_DELTA_COUNTER_BITS * `PT_TABLE_DELTA_ASSOCIATIVITY            - 1 : 0]       read_set_pt_delta_counter_in,
        output reg      [`PT_TABLE_DELTA_COUNTER_BITS                                            - 1 : 0]       write_pt_delta_counter_out
); 

reg [2:0] stage;

always@(posedge clk_in, posedge reset_in)
begin
        if(reset_in)
        begin
                stage <= `IDLE_TO_SIG_TABLE_ACCESS;
                ack_to_input_request_queue_out <= 1'b0;
        end

        else
        begin
                case(stage)

                        `IDLE_TO_SIG_TABLE_ACCESS :
                        begin
                                if(access_address_valid_in) 
                                begin
                                        stage <= `SIG_TABLE_ACCESS_TO_UPDATE;
                                end
                                ack_to_input_request_queue_out <= 1'b0;
                        end

                        `SIG_TABLE_ACCESS_TO_UPDATE:
                        begin
                                if(1) 
                                begin
                                        stage <= `SIG_TABLE_UPDATE_TO_PT_TABLE_ACCESS;
                                end
                                ack_to_input_request_queue_out <= 1'b0;
                        end

                        `SIG_TABLE_UPDATE_TO_PT_TABLE_ACCESS:
                        begin
                                if(1) 
                                begin
                                        stage <= `PT_TABLE_ACCESS_TO_UPDATE;
                                end
                                ack_to_input_request_queue_out <= 1'b0;
                        end

                        `PT_TABLE_ACCESS_TO_UPDATE:
                        begin
                                if(1) 
                                begin
                                        stage <= `PREFETCH_ISSUE;
                                end
                                ack_to_input_request_queue_out <= 1'b0;
                        end

                        `PREFETCH_ISSUE:
                        begin
                                if(output_queue_ack_in & prefetch_to_output_queue_valid_out)
                                begin
                                        stage <= `IDLE_TO_SIG_TABLE_ACCESS;
                                        ack_to_input_request_queue_out <= 1'b1;
                                end

                                else if(!prefetch_to_output_queue_valid_out)
                                begin
                                        ack_to_input_request_queue_out <= 1'b0;
                                end

                                else
                                begin
                                        stage <= stage;
                                        ack_to_input_request_queue_out <= ack_to_input_request_queue_out;      
                                end
                        end
                endcase
        end
end

// sig table aux signals
wire [`SIG_TABLE_ASSOCIATIVITY - 1 : 0]                 page_matched_vector;
wire [`SIG_TABLE_ASSOCIATIVITY - 1 : 0]                 page_matched_index;
wire [5:0]                                              current_blockID = access_address_in[11:6];
wire [5:0]                                              last_blockID    = read_set_sig_blockID_in[page_matched_index];
wire [6:0]                                              blockID_delta   = current_blockID - last_blockID;

reg  [`SIG_TABLE_ASSOCIATIVITY - 1 : 0]                 sig_table_replace_vector;

reg                                                     sig_table_accessed;
reg                                                     sig_table_hit;

reg  [`SIG_LENTH - 1 : 0]                               signature_to_pt_access;
reg  [6:0]                                              blockID_delta_to_pt_access;
reg  [5:0]                                              current_blockID_to_pt_access;

generate
        genvar gen;

        for(gen = 0; gen < `SIG_TABLE_ASSOCIATIVITY; gen = gen + 1)
        begin
                assign page_matched_vector[gen] = read_set_page_valid_in[gen] & 
                                         ( read_set_page_tag_in[(gen+1) * `SIG_TABLE_PAGE_NUM_TAG_BITS - 1 : gen * `SIG_TABLE_PAGE_NUM_TAG_BITS] == 
                                         ( (access_address_in >> (12 + SIG_TABLE_SET_INDEX_BITS)) & (`SIG_TABLE_PAGE_NUM_TAG_BITS - 1)));
        end
endgenerate

find_first_one_index
#(
        .VECTOR_LENGTH(`SIG_TABLE_ASSOCIATIVITY)
)
find_matched_page
(
        .vector_input(page_matched_vector),
        .first_one_index(page_matched_index)
);

// sig_table
always@(posedge clk_in, posedge reset_in)
begin
        if(reset_in)
        begin
                access_en_to_sig_tag_out        <= 1'b0;
                access_set_addr_to_sig_tag_out  <= {(SIG_TABLE_SET_INDEX_BITS){1'b0}};
                write_en_to_sig_tag_out         <= 1'b0;
                way_select_to_sig_tag_out       <= {(`SIG_TABLE_ASSOCIATIVITY){1'b0}};
                write_page_tag_out              <= {(`SIG_TABLE_PAGE_NUM_TAG_BITS){1'b0}};

                access_en_to_sig_data_out       <= 1'b0;
                access_set_addr_to_sig_data_out <= {(SIG_TABLE_SET_INDEX_BITS){1'b0}};
                write_en_to_sig_data_out        <= 1'b0;
                way_select_to_sig_data_out      <= {(`SIG_TABLE_ASSOCIATIVITY){1'b0}};

                write_sig_out                   <= {(`SIG_LENTH){1'b0}};
                write_sig_blockID_out           <= 6'b0;

                sig_table_accessed              <= 1'b0;
                sig_table_hit                   <= 1'b0;

                sig_table_replace_vector        <= {{1'b1}, {(`SIG_TABLE_ASSOCIATIVITY-1){1'b0}}};
        end

        else
        begin
                case(stage)
                
                `IDLE_TO_SIG_TABLE_ACCESS:
                begin
                                if(stage == `IDLE_TO_SIG_TABLE_ACCESS & access_address_valid_in)
                                begin
                                access_en_to_sig_tag_out        <= 1'b1;
                                access_set_addr_to_sig_tag_out  <= (access_address_in >> 12);
                                write_en_to_sig_tag_out         <= 1'b0;
                                way_select_to_sig_tag_out       <= {(`SIG_TABLE_ASSOCIATIVITY){1'b1}};
                                write_page_tag_out              <= {(`SIG_TABLE_PAGE_NUM_TAG_BITS){1'b0}};

                                access_en_to_sig_data_out       <= 1'b1;
                                access_set_addr_to_sig_data_out <= (access_address_in >> 12);
                                write_en_to_sig_data_out        <= 1'b0;
                                way_select_to_sig_data_out      <= {(`SIG_TABLE_ASSOCIATIVITY){1'b1}};

                                write_sig_out                   <= {(`SIG_LENTH){1'b0}};
                                write_sig_blockID_out           <= 6'b0;

                                sig_table_hit                   <= 1'b0;
                                sig_table_accessed              <= 1'b1;

                                // TODO : access history
                                sig_table_replace_vector        <= {{1'b1}, {(`SIG_TABLE_ASSOCIATIVITY-1){1'b0}}};
                        end
                 end

                `SIG_TABLE_ACCESS_TO_UPDATE:
                begin
                        if(sig_table_accessed)
                        begin
                                // page matched
                                if(|page_matched_vector)
                                begin
                                        access_en_to_sig_tag_out        <= 1'b0;
                                        access_set_addr_to_sig_tag_out  <= {(SIG_TABLE_SET_INDEX_BITS){1'b0}};
                                        write_en_to_sig_tag_out         <= 1'b0;
                                        way_select_to_sig_tag_out       <= {(`SIG_TABLE_ASSOCIATIVITY){1'b0}};
                                        write_page_tag_out              <= {(`SIG_TABLE_PAGE_NUM_TAG_BITS){1'b0}};

                                        access_en_to_sig_data_out       <= 1'b1;
                                        access_set_addr_to_sig_data_out <= (access_address_in >> 12);
                                        write_en_to_sig_data_out        <= 1'b1;
                                        way_select_to_sig_data_out      <= page_matched_vector;

                                        write_sig_out                   <= ((read_set_sig_in[page_matched_index] << `SIG_SHIFT) ^ blockID_delta) & {(`SIG_LENTH){1'b1}};
                                        write_sig_blockID_out           <= 6'b0;

                                        sig_table_hit                   <= 1'b1;
                                        sig_table_accessed              <= 1'b0;

                                        // TODO: promote logic
                                        sig_table_replace_vector        <= sig_table_replace_vector;
                                end

                                // page miss
                                else
                                begin
                                        access_en_to_sig_tag_out        <= 1'b1;
                                        access_set_addr_to_sig_tag_out  <= (access_address_in >> 12);
                                        write_en_to_sig_tag_out         <= 1'b1;
                                        way_select_to_sig_tag_out       <= sig_table_replace_vector;
                                        write_page_tag_out              <= (access_address_in >> (12 + SIG_TABLE_SET_INDEX_BITS)) & (`SIG_TABLE_PAGE_NUM_TAG_BITS - 1);

                                        access_en_to_sig_data_out       <= 1'b1;
                                        access_set_addr_to_sig_data_out <= (access_address_in >> 12);
                                        write_en_to_sig_data_out        <= 1'b1;
                                        way_select_to_sig_data_out      <= page_matched_vector;

                                        write_sig_out                   <= current_blockID;
                                        write_sig_blockID_out           <= current_blockID;

                                        sig_table_hit                   <= 1'b0;
                                        sig_table_accessed              <= 1'b0;

                                        // TODO: replace logic/insert logic
                                        sig_table_replace_vector        <= (sig_table_replace_vector >> 1) | (sig_table_replace_vector<<(`SIG_TABLE_ASSOCIATIVITY-1)); // right rorate
                                end
                        end
                end

                default:
                begin
                        access_en_to_sig_tag_out        <= 1'b0;
                        access_set_addr_to_sig_tag_out  <= {(SIG_TABLE_SET_INDEX_BITS){1'b0}};
                        write_en_to_sig_tag_out         <= 1'b0;
                        way_select_to_sig_tag_out       <= {(`SIG_TABLE_ASSOCIATIVITY){1'b0}};
                        write_page_tag_out              <= {(`SIG_TABLE_PAGE_NUM_TAG_BITS){1'b0}};

                        access_en_to_sig_data_out       <= 1'b0;
                        access_set_addr_to_sig_data_out <= {(SIG_TABLE_SET_INDEX_BITS){1'b0}};
                        write_en_to_sig_data_out        <= 1'b0;
                        way_select_to_sig_data_out      <= {(`SIG_TABLE_ASSOCIATIVITY){1'b0}};

                        write_sig_out                   <= {(`SIG_LENTH){1'b0}};
                        write_sig_blockID_out           <= 6'b0;
                        
                        sig_table_hit                   <= 1'b0;
                        sig_table_accessed              <= 1'b0;

                        sig_table_replace_vector        <= {{1'b1}, {(`SIG_TABLE_ASSOCIATIVITY-1){1'b0}}};
                end
                endcase
        end
end

// sig_table_lookup result
always@(posedge clk_in, posedge reset_in)
begin
        if(reset_in)
        begin
                signature_to_pt_access          <= {(`SIG_LENTH){1'b0}};
                blockID_delta_to_pt_access      <= 7'b0;
                current_blockID_to_pt_access    <= 6'b0;
        end

        else
        begin
                case(stage)

                `IDLE_TO_SIG_TABLE_ACCESS:
                begin
                        signature_to_pt_access          <= {(`SIG_LENTH){1'b0}};
                        blockID_delta_to_pt_access      <= 7'b0;
                        current_blockID_to_pt_access    <= 6'b0;
                end

                `SIG_TABLE_ACCESS_TO_UPDATE:
                begin
                        if(|page_matched_vector)
                        begin
                                signature_to_pt_access          <= read_set_sig_in[page_matched_index];
                                blockID_delta_to_pt_access      <= blockID_delta;
                                current_blockID_to_pt_access    <= current_blockID;
                        end
                end

                default:
                begin
                        signature_to_pt_access          <= signature_to_pt_access;
                        blockID_delta_to_pt_access      <= blockID_delta_to_pt_access;
                        current_blockID_to_pt_access    <= current_blockID_to_pt_access;
                end

                endcase
        end
end

// pattern table
wire [`PT_TABLE_SIG_ASSOCIATIVITY - 1 : 0] pt_sig_matched_vector;
wire [`PT_TABLE_SIG_ASSOCIATIVITY - 1 : 0] pt_sig_matched_index;

generate
        for(gen = 0; gen < `PT_TABLE_SIG_ASSOCIATIVITY; gen = gen + 1)
        begin
                assign pt_sig_matched_vector[gen] = read_set_pt_valid_in[gen] & 
                                         ( read_set_pt_sig_tag_in[((gen+1) * PT_TABLE_SIG_TAG_BITS) - 1 : gen * (PT_TABLE_SIG_TAG_BITS)] == (signature_to_pt_access >> PT_TABLE_SIG_INDEX_BITS) );
        end
endgenerate

find_first_one_index
#(
        .VECTOR_LENGTH(`PT_TABLE_SIG_ASSOCIATIVITY)
)
find_matched_sig
(
        .vector_input(pt_sig_matched_vector),
        .first_one_index(pt_sig_matched_index)
);


wire [`PT_TABLE_DELTA_ASSOCIATIVITY - 1 : 0] pt_delta_matched_vector;
wire [`PT_TABLE_DELTA_ASSOCIATIVITY - 1 : 0] pt_delta_matched_index;

generate
        for(gen = 0; gen < `PT_TABLE_DELTA_ASSOCIATIVITY; gen = gen + 1)
        begin
                assign pt_delta_matched_vector[gen] = read_set_pt_delta_valid_in[gen] & 
                                         ( read_set_pt_delta_in[(gen+1) * `PT_TABLE_DELTA_COUNTER_BITS - 1 : gen * `PT_TABLE_DELTA_COUNTER_BITS] == blockID_delta_to_pt_access );
        end
endgenerate

find_first_one_index
#(
        .VECTOR_LENGTH(`PT_TABLE_DELTA_ASSOCIATIVITY)
)
find_matched_delta
(
        .vector_input(pt_delta_matched_vector),
        .first_one_index(pt_delta_matched_index)
);

reg pattern_table_accessed;
wire pattern_table_sig_hit      = |pt_sig_matched_vector;
wire pattern_table_delta_hit    = pattern_table_sig_hit & (|pt_delta_matched_vector);

reg [`PT_TABLE_SIG_ASSOCIATIVITY   - 1 : 0] pt_table_sig_replace_vector;
reg [`PT_TABLE_DELTA_ASSOCIATIVITY - 1 : 0] pt_table_delta_replace_vector;

always@(posedge clk_in, posedge reset_in)
begin
        if(reset_in)
        begin
                access_en_to_pt_sig_tag_out                     <= 1'b0;
                access_set_addr_to_pt_sig_tag_out               <= {(PT_TABLE_SIG_INDEX_BITS){1'b0}};
                way_select_to_pt_sig_tag_out                    <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b0}};
                write_en_to_pt_sig_tag_out                      <= 1'b0;
                write_pt_sig_tag_out                            <= {(PT_TABLE_SIG_TAG_BITS){1'b0}};
                
                access_en_to_pt_sig_data_out                    <= 1'b0;
                access_set_addr_to_pt_sig_data_out              <= {(PT_TABLE_SIG_INDEX_BITS){1'b0}};
                way_select_to_pt_sig_data_out                   <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b0}};
                write_en_to_pt_sig_data_out                     <= 1'b0;
                write_pt_sig_counter_out                        <= {(`PT_TABLE_SIG_COUNTER_BITS){1'b0}};

                access_en_to_pt_delta_tag_out                   <= 1'b0;
                access_set_addr_to_pt_delta_tag_out             <= {(PT_TABLE_DELTA_INDEX_BITS){1'b0}};
                way_select_to_pt_delta_tag_out                  <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                write_en_to_pt_delta_tag_out                    <= 1'b0;
                write_pt_delta_out                              <= {(`DELTA_BITS){1'b0}};

                access_en_to_pt_delta_data_out                  <= 1'b0;
                access_set_addr_to_pt_delta_data_out            <= {(PT_TABLE_DELTA_INDEX_BITS){1'b0}};
                way_select_to_pt_delta_data_out                 <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                write_en_to_pt_delta_data_out                   <= 1'b0;
                write_pt_delta_counter_out                      <= {(`PT_TABLE_DELTA_COUNTER_BITS){1'b0}};

                pattern_table_accessed                          <= 1'b0;
                pt_table_sig_replace_vector                     <= {{1'b1}, {(`PT_TABLE_SIG_ASSOCIATIVITY-1){1'b0}}};
                pt_table_delta_replace_vector                   <= {{1'b1}, {(`PT_TABLE_DELTA_ASSOCIATIVITY-1){1'b0}}};

                prefetch_to_output_queue_out                    <= {(ADDR_WIDTH){1'b0}};
                prefetch_to_output_queue_valid_out              <= 1'b0;
        end

        else
        begin
                case(stage)

                `SIG_TABLE_UPDATE_TO_PT_TABLE_ACCESS:
                begin
                        if(sig_table_hit & blockID_delta_to_pt_access != 0)
                        begin
                                access_en_to_pt_sig_tag_out                     <= 1'b1;
                                access_set_addr_to_pt_sig_tag_out               <= signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0];
                                way_select_to_pt_sig_tag_out                    <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b1}};
                                write_en_to_pt_sig_tag_out                      <= 1'b0;
                                write_pt_sig_tag_out                            <= {(PT_TABLE_SIG_TAG_BITS){1'b0}};

                                access_en_to_pt_sig_data_out                    <= 1'b1;
                                access_set_addr_to_pt_sig_data_out              <= signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0];
                                way_select_to_pt_sig_data_out                   <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b0}};
                                write_en_to_pt_sig_data_out                     <= 1'b0;
                                write_pt_sig_counter_out                        <= {(`PT_TABLE_SIG_COUNTER_BITS){1'b0}};

                                access_en_to_pt_delta_tag_out                   <= 1'b1;
                                access_set_addr_to_pt_delta_tag_out             <= (signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0] * (`PT_TABLE_SIG_ASSOCIATIVITY));
                                way_select_to_pt_delta_tag_out                  <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                                write_en_to_pt_delta_tag_out                    <= 1'b0;
                                write_pt_delta_out                              <= {(`DELTA_BITS){1'b0}};

                                access_en_to_pt_delta_data_out                  <= 1'b1;
                                access_set_addr_to_pt_delta_data_out            <= (signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0] * (`PT_TABLE_SIG_ASSOCIATIVITY));
                                way_select_to_pt_delta_data_out                 <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                                write_en_to_pt_delta_data_out                   <= 1'b0;
                                write_pt_delta_counter_out                      <= {(`PT_TABLE_DELTA_COUNTER_BITS){1'b0}};

                                pattern_table_accessed                          <= 1'b1;
                                
                                pt_table_sig_replace_vector                     <= pt_table_sig_replace_vector;
                                pt_table_delta_replace_vector                   <= pt_table_delta_replace_vector;

                                prefetch_to_output_queue_out                    <= {(ADDR_WIDTH){1'b0}};
                                prefetch_to_output_queue_valid_out              <= 1'b0;
                        end
                end

                `PT_TABLE_ACCESS_TO_UPDATE:
                begin
                        // pt_sig hit
                        if(pattern_table_accessed & pattern_table_sig_hit)
                        begin
                                access_en_to_pt_sig_tag_out                     <= 1'b0;
                                access_set_addr_to_pt_sig_tag_out               <= {(PT_TABLE_SIG_INDEX_BITS){1'b0}};
                                way_select_to_pt_sig_tag_out                    <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b0}};
                                write_en_to_pt_sig_tag_out                      <= 1'b0;
                                write_pt_sig_tag_out                            <= {(PT_TABLE_SIG_TAG_BITS){1'b0}};

                                access_en_to_pt_sig_data_out                    <= 1'b1;
                                access_set_addr_to_pt_sig_data_out              <= signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0];
                                way_select_to_pt_sig_data_out                   <= pt_sig_matched_vector;
                                write_en_to_pt_sig_data_out                     <= 1'b1;
                                write_pt_sig_counter_out                        <= read_set_pt_sig_counter_in[pt_sig_matched_index] + 1'b1 == {(`PT_TABLE_SIG_COUNTER_BITS){1'b0}} ?
                                                                                                                                                read_set_pt_sig_counter_in[pt_sig_matched_index] :
                                                                                                                                                read_set_pt_sig_counter_in[pt_sig_matched_index] + 1'b1;
                                pt_table_sig_replace_vector                     <= pt_table_sig_replace_vector;
                                pattern_table_accessed                          <= 1'b0;

                                if(pattern_table_delta_hit)
                                begin
                                        access_en_to_pt_delta_tag_out                   <= 1'b0;
                                        access_set_addr_to_pt_delta_tag_out             <= {(PT_TABLE_DELTA_INDEX_BITS){1'b0}};
                                        way_select_to_pt_delta_tag_out                  <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                                        write_en_to_pt_delta_tag_out                    <= 1'b0;
                                        write_pt_delta_out                              <= {(`DELTA_BITS){1'b0}};

                                        access_en_to_pt_delta_data_out                  <= 1'b1;
                                        access_set_addr_to_pt_delta_data_out            <= (signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0] * (`PT_TABLE_SIG_ASSOCIATIVITY));
                                        way_select_to_pt_delta_data_out                 <= pt_delta_matched_vector;
                                        write_en_to_pt_delta_data_out                   <= 1'b1;
                                        write_pt_delta_counter_out                      <= read_set_pt_delta_counter_in[pt_delta_matched_index] + 1'b1 == {(`PT_TABLE_SIG_COUNTER_BITS){1'b0}} ?
                                                                                                                                                        read_set_pt_delta_counter_in[pt_delta_matched_index] :
                                                                                                                                                        read_set_pt_delta_counter_in[pt_delta_matched_index] + 1'b1;
                                        pt_table_delta_replace_vector                   <= pt_table_delta_replace_vector;

                                        // issue checking
                                        if(read_set_pt_delta_counter_in[pt_delta_matched_index] * 2 > read_set_pt_sig_counter_in[pt_sig_matched_index])
                                        begin
                                                prefetch_to_output_queue_out                    <= access_address_in[ADDR_WIDTH - 1 : 12] | 
                                                                                                   (current_blockID_to_pt_access + read_set_pt_delta_in[pt_delta_matched_index]);
                                                prefetch_to_output_queue_valid_out              <= 1'b1;
                                        end
                                end
                                
                                else
                                begin
                                        access_en_to_pt_delta_tag_out                   <= 1'b1;
                                        access_set_addr_to_pt_delta_tag_out             <= (signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0] * (`PT_TABLE_SIG_ASSOCIATIVITY));
                                        way_select_to_pt_delta_tag_out                  <= pt_table_delta_replace_vector;
                                        write_en_to_pt_delta_tag_out                    <= 1'b1;
                                        write_pt_delta_out                              <= blockID_delta_to_pt_access;

                                        access_en_to_pt_delta_data_out                  <= 1'b1;
                                        access_set_addr_to_pt_delta_data_out            <= (signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0] * (`PT_TABLE_SIG_ASSOCIATIVITY));
                                        way_select_to_pt_delta_data_out                 <= pt_table_delta_replace_vector;
                                        write_en_to_pt_delta_data_out                   <= 1'b1;
                                        write_pt_delta_counter_out                      <= 1;
                                        
                                        pt_table_delta_replace_vector                   <= (pt_table_delta_replace_vector >> 1) | (pt_table_delta_replace_vector<<(`SIG_TABLE_ASSOCIATIVITY-1));

                                        prefetch_to_output_queue_out                    <= {(ADDR_WIDTH){1'b0}};
                                        prefetch_to_output_queue_valid_out              <= 1'b0;
                                end

                        end

                        else if(~pattern_table_sig_hit)
                        begin
                                access_en_to_pt_sig_tag_out                     <= 1'b1;
                                access_set_addr_to_pt_sig_tag_out               <= signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0];
                                way_select_to_pt_sig_tag_out                    <= pt_table_sig_replace_vector;
                                write_en_to_pt_sig_tag_out                      <= 1'b1;
                                write_pt_sig_tag_out                            <= signature_to_pt_access >> (PT_TABLE_SIG_INDEX_BITS);

                                access_en_to_pt_sig_data_out                    <= 1'b1;
                                access_set_addr_to_pt_sig_data_out              <= signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0];
                                way_select_to_pt_sig_data_out                   <= pt_table_sig_replace_vector;
                                write_en_to_pt_sig_data_out                     <= 1'b1;
                                write_pt_sig_counter_out                        <= signature_to_pt_access >> (PT_TABLE_SIG_INDEX_BITS);

                                pt_table_sig_replace_vector                     <= (pt_table_sig_replace_vector >> 1) | (pt_table_sig_replace_vector<<(`SIG_TABLE_ASSOCIATIVITY-1));
                                pattern_table_accessed                          <= 1'b0;

                                access_en_to_pt_delta_tag_out                   <= 1'b1;
                                access_set_addr_to_pt_delta_tag_out             <= (signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0] * (`PT_TABLE_SIG_ASSOCIATIVITY));
                                way_select_to_pt_delta_tag_out                  <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b1}};
                                write_en_to_pt_delta_tag_out                    <= 1'b1;
                                write_pt_delta_out                              <= 0;

                                access_en_to_pt_delta_data_out                  <= 1'b1;
                                access_set_addr_to_pt_delta_data_out            <= (signature_to_pt_access[PT_TABLE_SIG_INDEX_BITS - 1 : 0] * (`PT_TABLE_SIG_ASSOCIATIVITY));
                                way_select_to_pt_delta_data_out                 <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b1}};
                                write_en_to_pt_delta_data_out                   <= 1'b1;
                                write_pt_delta_counter_out                      <= 0;
                                        
                                pt_table_delta_replace_vector                   <= pt_table_delta_replace_vector;

                                prefetch_to_output_queue_out                    <= {(ADDR_WIDTH){1'b0}};
                                prefetch_to_output_queue_valid_out              <= 1'b0;
                        end
                end

                `PREFETCH_ISSUE:
                begin
                        access_en_to_pt_sig_tag_out                     <= 1'b0;
                        access_set_addr_to_pt_sig_tag_out               <= {(PT_TABLE_SIG_INDEX_BITS){1'b0}};
                        way_select_to_pt_sig_tag_out                    <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b0}};
                        write_en_to_pt_sig_tag_out                      <= 1'b0;
                        write_pt_sig_tag_out                            <= {(PT_TABLE_SIG_TAG_BITS){1'b0}};
                        
                        access_en_to_pt_sig_data_out                    <= 1'b0;
                        access_set_addr_to_pt_sig_data_out              <= {(PT_TABLE_SIG_INDEX_BITS){1'b0}};
                        way_select_to_pt_sig_data_out                   <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b0}};
                        write_en_to_pt_sig_data_out                     <= 1'b0;
                        write_pt_sig_counter_out                        <= {(`PT_TABLE_SIG_COUNTER_BITS){1'b0}};

                        access_en_to_pt_delta_tag_out                   <= 1'b0;
                        access_set_addr_to_pt_delta_tag_out             <= {(PT_TABLE_DELTA_INDEX_BITS){1'b0}};
                        way_select_to_pt_delta_tag_out                  <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                        write_en_to_pt_delta_tag_out                    <= 1'b0;
                        write_pt_delta_out                              <= {(`DELTA_BITS){1'b0}};

                        access_en_to_pt_delta_data_out                  <= 1'b0;
                        access_set_addr_to_pt_delta_data_out            <= {(PT_TABLE_DELTA_INDEX_BITS){1'b0}};
                        way_select_to_pt_delta_data_out                 <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                        write_en_to_pt_delta_data_out                   <= 1'b0;
                        write_pt_delta_counter_out                      <= {(`PT_TABLE_DELTA_COUNTER_BITS){1'b0}};

                        pattern_table_accessed                          <= 1'b0;
                        pt_table_sig_replace_vector                     <= pt_table_sig_replace_vector;
                        pt_table_delta_replace_vector                   <= pt_table_delta_replace_vector;

                        if(~output_queue_ack_in)
                        begin
                                prefetch_to_output_queue_out             <= prefetch_to_output_queue_out;
                                prefetch_to_output_queue_valid_out       <= prefetch_to_output_queue_valid_out;
                        end

                        else
                        begin
                                prefetch_to_output_queue_out             <= 0;
                                prefetch_to_output_queue_valid_out       <= 1'b0;
                        end
                end

                default:
                begin
                        access_en_to_pt_sig_tag_out                     <= 1'b0;
                        access_set_addr_to_pt_sig_tag_out               <= {(PT_TABLE_SIG_INDEX_BITS){1'b0}};
                        way_select_to_pt_sig_tag_out                    <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b0}};
                        write_en_to_pt_sig_tag_out                      <= 1'b0;
                        write_pt_sig_tag_out                            <= {(PT_TABLE_SIG_TAG_BITS){1'b0}};
                        
                        access_en_to_pt_sig_data_out                    <= 1'b0;
                        access_set_addr_to_pt_sig_data_out              <= {(PT_TABLE_SIG_INDEX_BITS){1'b0}};
                        way_select_to_pt_sig_data_out                   <= {(`PT_TABLE_SIG_ASSOCIATIVITY){1'b0}};
                        write_en_to_pt_sig_data_out                     <= 1'b0;
                        write_pt_sig_counter_out                        <= {(`PT_TABLE_SIG_COUNTER_BITS){1'b0}};

                        access_en_to_pt_delta_tag_out                   <= 1'b0;
                        access_set_addr_to_pt_delta_tag_out             <= {(PT_TABLE_DELTA_INDEX_BITS){1'b0}};
                        way_select_to_pt_delta_tag_out                  <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                        write_en_to_pt_delta_tag_out                    <= 1'b0;
                        write_pt_delta_out                              <= {(`DELTA_BITS){1'b0}};

                        access_en_to_pt_delta_data_out                  <= 1'b0;
                        access_set_addr_to_pt_delta_data_out            <= {(PT_TABLE_DELTA_INDEX_BITS){1'b0}};
                        way_select_to_pt_delta_data_out                 <= {(`PT_TABLE_DELTA_ASSOCIATIVITY){1'b0}};
                        write_en_to_pt_delta_data_out                   <= 1'b0;
                        write_pt_delta_counter_out                      <= {(`PT_TABLE_DELTA_COUNTER_BITS){1'b0}};

                        pattern_table_accessed                          <= 1'b0;
                        pt_table_sig_replace_vector                     <= pt_table_sig_replace_vector;
                        pt_table_delta_replace_vector                   <= pt_table_delta_replace_vector;
                end
                endcase
        end
end

endmodule