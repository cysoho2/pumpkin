`include "prefetcher_parameters.h"

module spp_prefetcher
#(
        parameter ADDR_WIDTH = 64
)
(
        input clk_in,
        input reset_in,

        input [ADDR_WIDTH - 1 : 0]      access_address_in,
        input                           access_valid_in,
        output                          access_address_ack_out,

        output [ADDR_WIDTH - 1 : 0]     prefetch_address_out,
        output                          prefetch_valid_out,
        input                           prefetch_ack_in,
        
        output                          prefetch_confidence_out,            // currently unused wire
        output                          prefetch_critical_out,              // currently unused wire

        input                           l3_read_queue_ack_in,
        input                           l3_read_queue_full_in,             // currently unused wire

        input                           access_write_in,                   // currently unused wire
        input                           access_core_id_in,                 // currently unused wire
        input                           access_inst_flag_in,               // currently unused wire
        input                           access_type_in,                    // currently unused wire

        input [ADDR_WIDTH - 1 : 0]      evict_address_in,                  // currently unused wire
        input                           evict_valid_in,                    // currently unused wire

        input [ADDR_WIDTH - 1 : 0]      refill_address_in,                 // currently unused wire
        input                           refill_valid_in                    // currently unused wire
);

wire [ADDR_WIDTH - 1 : 0]      address_to_main_ctrl;

fifo_queue
#(
        .QUEUE_SIZE                     (`INPUT_REQUEST_QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        ($clog2(`INPUT_REQUEST_QUEUE_SIZE)),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (ADDR_WIDTH)
)
input_request_queue
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (), // intened left unconnected
        .is_full_out                    (is_input_request_queue_full),

        .request_in                     (access_address_in),
        .request_valid_in               (access_valid_in),
        .issue_ack_out                  (access_address_ack_out),
        
        .request_out                    (address_to_main_ctrl),
        .request_valid_out              (address_valid_to_main_ctrl),
        .issue_ack_in                   (main_ctrl_ack_to_input_request_queue)
);

wire [ADDR_WIDTH                                                        - 1 : 0] prefetch_to_output_queue;

wire [$clog2(`SIG_TABLE_SET)                                            - 1 : 0] access_set_addr_to_sig_tag;
wire [`SIG_TABLE_ASSOCIATIVITY                                          - 1 : 0] way_select_to_sig_tag;
wire [`SIG_TABLE_ASSOCIATIVITY                                          - 1 : 0] read_set_page_valid;
wire [`SIG_TABLE_PAGE_NUM_TAG_BITS * `SIG_TABLE_ASSOCIATIVITY           - 1 : 0] read_set_page_tag;
wire [`SIG_TABLE_PAGE_NUM_TAG_BITS                                      - 1 : 0] write_page_tag;

wire [$clog2(`SIG_TABLE_SET)                                            - 1 : 0] access_set_addr_to_sig_data;
wire [`SIG_TABLE_ASSOCIATIVITY                                          - 1 : 0] way_select_to_sig_data;

wire [`SIG_LENTH * `SIG_TABLE_ASSOCIATIVITY                             - 1 : 0] read_set_sig;
wire [`SIG_LENTH                                                        - 1 : 0] write_sig;

wire [6 * `SIG_TABLE_ASSOCIATIVITY                                      - 1 : 0] read_set_sig_blockID;
wire [5:0] write_sig_blockID;

wire [$clog2(`PT_TABLE_SIG_SET)                                         - 1 : 0] access_set_addr_to_pt_sig_tag;
wire [`PT_TABLE_SIG_ASSOCIATIVITY                                       - 1 : 0] way_select_to_pt_sig_tag;

wire [`PT_TABLE_SIG_ASSOCIATIVITY                                       - 1 : 0] pt_valid_set;

wire [`PT_TABLE_SIG_TAG_BITS * `PT_TABLE_SIG_ASSOCIATIVITY              - 1 : 0] read_set_pt_sig_tag;
wire [`PT_TABLE_SIG_TAG_BITS                                            - 1 : 0] write_pt_sig_tag;

wire [$clog2(`PT_TABLE_SIG_SET)                                         - 1 : 0] access_set_addr_to_pt_sig_data;
wire [`PT_TABLE_SIG_ASSOCIATIVITY                                       - 1 : 0] way_select_to_pt_sig_data;

wire [`PT_TABLE_SIG_COUNTER_BITS * `PT_TABLE_SIG_COUNTER_BITS           - 1 : 0] read_set_pt_sig_counter;
wire [`PT_TABLE_SIG_COUNTER_BITS                                        - 1 : 0] write_pt_sig_counter;

wire [$clog2(`PT_TABLE_DELTA_SET)                                       - 1 : 0] access_set_addr_to_pt_delta_tag;
wire [`PT_TABLE_DELTA_ASSOCIATIVITY                                     - 1 : 0] way_select_to_pt_delta_tag;

wire [`PT_TABLE_DELTA_ASSOCIATIVITY                                     - 1 : 0] read_set_pt_delta_valid;
wire [`PT_TABLE_DELTA_ASSOCIATIVITY * `DELTA_BITS                       - 1 : 0] read_set_pt_delta;
wire [`DELTA_BITS                                                       - 1 : 0] write_pt_delta;

wire [$clog2(`PT_TABLE_DELTA_SET)                                       - 1 : 0] access_set_addr_to_pt_delta_data;
wire [`PT_TABLE_DELTA_ASSOCIATIVITY                                     - 1 : 0] way_select_to_pt_delta_data;
wire [`PT_TABLE_DELTA_COUNTER_BITS * `PT_TABLE_DELTA_ASSOCIATIVITY      - 1 : 0] read_set_pt_delta_counter;
wire [`PT_TABLE_DELTA_COUNTER_BITS                                      - 1 : 0] write_pt_delta_counter;

spp_main_ctrl
#(
        .ADDR_WIDTH                    (ADDR_WIDTH),
        .SIG_TABLE_SET_INDEX_BITS      (`SIG_TABLE_SET_INDEX_BITS),
        .PT_TABLE_SIG_INDEX_BITS       (`PT_TABLE_SIG_INDEX_BITS),
        .PT_TABLE_SIG_TAG_BITS         (`PT_TABLE_SIG_TAG_BITS),
        .PT_TABLE_DELTA_INDEX_BITS     (`PT_TABLE_DELTA_INDEX_BITS)
)
spp_main_ctrl
(
        .reset_in                                       (reset_in),
        .clk_in                                         (clk_in),

        // input request queue
        .ack_to_input_request_queue_out                 (main_ctrl_ack_to_input_request_queue),
        .access_address_in                              (address_to_main_ctrl), 
        .access_address_valid_in                        (address_valid_to_main_ctrl),

        // prefetch output queue
        .prefetch_to_output_queue_out                   (prefetch_to_output_queue),
        .prefetch_to_output_queue_valid_out             (prefetch_to_output_queue_valid),
        .output_queue_ack_in                            (output_queue_ack),

        // signature table
                // sig_tag_common
                .access_en_to_sig_tag_out                       (access_en_to_sig_tag),
                .access_set_addr_to_sig_tag_out                 (access_set_addr_to_sig_tag),
                .write_en_to_sig_tag_out                        (write_en_to_sig_tag),
                .way_select_to_sig_tag_out                      (way_select_to_sig_tag),
                
                        // sig valid array
                        .read_set_page_valid_in                         (read_set_page_valid),

                        // sig page tag array
                        .read_set_page_tag_in                           (read_set_page_tag),
                        .write_page_tag_out                             (write_page_tag),

                // sig_data_common
                .access_en_to_sig_data_out                      (access_en_to_sig_data),
                .access_set_addr_to_sig_data_out                (access_set_addr_to_sig_data),
                .write_en_to_sig_data_out                       (write_en_to_sig_data),
                .way_select_to_sig_data_out                     (way_select_to_sig_data),

                        // sig array
                        .read_set_sig_in                                (read_set_sig),
                        .write_sig_out                                  (write_sig),

                        // sig blockID array
                        .read_set_sig_blockID_in                            (read_set_sig_blockID),    
                        .write_sig_blockID_out                          (write_sig_blockID),

        // pattern table
                // pt_sig_tag_common
                .access_en_to_pt_sig_tag_out                    (access_en_to_pt_sig_tag),
                .access_set_addr_to_pt_sig_tag_out              (access_set_addr_to_pt_sig_tag),
                .write_en_to_pt_sig_tag_out                     (write_en_to_pt_sig_tag),
                .way_select_to_pt_sig_tag_out                   (way_select_to_pt_sig_tag),

                        // pt_sig_valid
                        .read_set_pt_valid_in                           (pt_valid_set),

                        // pt_sig_tag
                        .read_set_pt_sig_tag_in                         (read_set_pt_sig_tag),
                        .write_pt_sig_tag_out                           (write_pt_sig_tag),

                // pt_sig_counter
                .access_en_to_pt_sig_data_out                   (access_en_to_pt_sig_data),
                .access_set_addr_to_pt_sig_data_out             (access_set_addr_to_pt_sig_data),
                .write_en_to_pt_sig_data_out                    (write_en_to_pt_sig_data),
                .way_select_to_pt_sig_data_out                  (way_select_to_pt_sig_data),
                
                        .read_set_pt_sig_counter_in                     (read_set_pt_sig_counter),
                        .write_pt_sig_counter_out                       (write_pt_sig_counter),

                
                // pt_delta_tag_common
                .access_en_to_pt_delta_tag_out                  (access_en_to_pt_delta_tag),
                .access_set_addr_to_pt_delta_tag_out            (access_set_addr_to_pt_delta_tag),
                .write_en_to_pt_delta_tag_out                   (write_en_to_pt_delta_tag),
                .way_select_to_pt_delta_tag_out                 (way_select_to_pt_delta_tag),

                        // pt_delta_valid
                        .read_set_pt_delta_valid_in                     (read_set_pt_delta_valid),
                        
                        // pt_delta
                        .read_set_pt_delta_in                           (read_set_pt_delta),
                        .write_pt_delta_out                             (write_pt_delta),

                // pt_delta_counter
                .access_en_to_pt_delta_data_out                  (access_en_to_pt_delta_data),
                .access_set_addr_to_pt_delta_data_out            (access_set_addr_to_pt_delta_data),
                .write_en_to_pt_delta_data_out                   (write_en_to_pt_delta_data),
                .way_select_to_pt_delta_data_out                 (way_select_to_pt_delta_data),
                
                        .read_set_pt_delta_counter_in                   (read_set_pt_delta_counter),
                        .write_pt_delta_counter_out                     (write_pt_delta_counter)
);


// signature table
valid_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (1),
        .NUMBER_SETS                    (`SIG_TABLE_SET),
        .NUMBER_WAYS                    (`SIG_TABLE_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`SIG_TABLE_SET))
)
sig_valid_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_sig_tag),
        .access_set_addr_in             (access_set_addr_to_sig_tag),
        
        .write_en_in                    (write_en_to_sig_tag),
        .write_way_select_in            (way_select_to_sig_tag),

        .read_set_valid_out             (read_set_page_valid)
);

associative_data_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (`SIG_TABLE_PAGE_NUM_TAG_BITS),
        .NUMBER_SETS                    (`SIG_TABLE_SET),
        .NUMBER_WAYS                    (`SIG_TABLE_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`SIG_TABLE_SET))
)
sig_page_tag_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_sig_tag),
        .access_set_addr_in             (access_set_addr_to_sig_tag),
        
        .write_en_in                    (write_en_to_sig_tag),
        .way_select_in                  (way_select_to_sig_tag),
        
        .read_single_element_out        (),
        .read_set_element_out           (read_set_page_tag),
        .write_single_element_in        (write_page_tag)

);

associative_data_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (`SIG_LENTH),
        .NUMBER_SETS                    (`SIG_TABLE_SET),
        .NUMBER_WAYS                    (`SIG_TABLE_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`SIG_TABLE_SET))
)
sig_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_sig_data),
        .access_set_addr_in             (access_set_addr_to_sig_data),
        
        .write_en_in                    (write_en_to_sig_data),
        .way_select_in                  (way_select_to_sig_data),
        
        .read_single_element_out        (),
        .read_set_element_out           (read_set_sig),
        .write_single_element_in        (write_sig)

);

associative_data_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (6),
        .NUMBER_SETS                    (`SIG_TABLE_SET),
        .NUMBER_WAYS                    (`SIG_TABLE_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`SIG_TABLE_SET))
)
sig_blockID_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_sig_data),
        .access_set_addr_in             (access_set_addr_to_sig_data),
        
        .write_en_in                    (write_en_to_sig_data),
        .way_select_in                  (way_select_to_sig_data),
        
        .read_single_element_out        (),
        .read_set_element_out           (read_set_sig_blockID),
        .write_single_element_in        (write_sig_blockID)
);

// pattern table - signature

valid_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (1),
        .NUMBER_SETS                    (`PT_TABLE_SIG_SET),
        .NUMBER_WAYS                    (`PT_TABLE_SIG_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`PT_TABLE_SIG_SET))
)
pattern_sig_valid_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_pt_sig_tag),
        .access_set_addr_in             (access_set_addr_to_pt_sig_tag),

        .write_way_select_in            (way_select_to_pt_sig_tag),
        .write_en_in                    (write_en_to_pt_sig_tag),

        .read_set_valid_out             (pt_valid_set)
);

associative_data_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (`PT_TABLE_SIG_TAG_BITS),
        .NUMBER_SETS                    (`PT_TABLE_SIG_SET),
        .NUMBER_WAYS                    (`PT_TABLE_SIG_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`PT_TABLE_SIG_SET))
)
pattern_sig_tag_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_pt_sig_tag),
        .access_set_addr_in             (access_set_addr_to_pt_sig_tag),
        
        .way_select_in                  (way_select_to_pt_sig_tag),
        .write_en_in                    (write_en_to_pt_sig_tag),
        
        .read_single_element_out        (),
        .read_set_element_out           (read_set_pt_sig_tag),
        .write_single_element_in        (write_pt_sig_tag)
);

associative_data_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (`PT_TABLE_SIG_COUNTER_BITS),
        .NUMBER_SETS                    (`PT_TABLE_SIG_SET),
        .NUMBER_WAYS                    (`PT_TABLE_SIG_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`PT_TABLE_SIG_SET))
)
pattern_sig_counter_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_pt_sig_data),
        .access_set_addr_in             (access_set_addr_to_pt_sig_data),
        
        .way_select_in                  (way_select_to_pt_sig_data),
        .write_en_in                    (write_en_to_pt_sig_data),
        
        .read_single_element_out        (),
        .read_set_element_out           (read_set_pt_sig_counter),
        .write_single_element_in        (write_pt_sig_counter)
);

// pattern table - delta

valid_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (1),
        .NUMBER_SETS                    (`PT_TABLE_DELTA_SET),
        .NUMBER_WAYS                    (`PT_TABLE_DELTA_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`PT_TABLE_DELTA_SET))
)
pattern_delta_valid_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_pt_delta_tag),
        .access_set_addr_in             (access_set_addr_to_pt_delta_tag),

        .write_way_select_in            (way_select_to_pt_delta_tag),
        .write_en_in                    (write_en_to_pt_delta_tag),

        .read_set_valid_out             (read_set_pt_delta_valid)
);

associative_data_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (`DELTA_BITS),
        .NUMBER_SETS                    (`PT_TABLE_DELTA_SET),
        .NUMBER_WAYS                    (`PT_TABLE_DELTA_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`PT_TABLE_DELTA_SET))
)
pattern_delta_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_pt_delta_tag),
        .access_set_addr_in             (access_set_addr_to_pt_delta_tag),
        
        .way_select_in                  (way_select_to_pt_delta_tag),
        .write_en_in                    (write_en_to_pt_delta_tag),

        .read_single_element_out        (),
        .read_set_element_out           (read_set_pt_delta),
        .write_single_element_in        (write_pt_delta)
);

associative_data_array
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (`PT_TABLE_DELTA_COUNTER_BITS),
        .NUMBER_SETS                    (`PT_TABLE_DELTA_SET),
        .NUMBER_WAYS                    (`PT_TABLE_DELTA_ASSOCIATIVITY),
        .SET_PTR_WIDTH_IN_BITS          ($clog2(`PT_TABLE_DELTA_SET))
)
pattern_delta_counter_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_to_pt_delta_data),
        .access_set_addr_in             (access_set_addr_to_pt_delta_data),
        
        .way_select_in                  (way_select_to_pt_delta_data),
        .write_en_in                    (write_en_to_pt_delta_data),

        .read_single_element_out        (),
        .read_set_element_out           (read_set_pt_delta_counter),
        .write_single_element_in        (write_pt_delta_counter)
);


// output prefetch queue

fifo_queue
#(
        .QUEUE_SIZE                     (`PREFETCH_OUTPUT_QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        ($clog2(`PREFETCH_OUTPUT_QUEUE_SIZE)),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (ADDR_WIDTH)
)
prefetch_queue
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (), // intened left unconnected
        .is_full_out                    (),

        .request_in                     (prefetch_to_output_queue),
        .request_valid_in               (prefetch_to_output_queue_valid),
        .issue_ack_out                  (output_queue_ack),
        
        .request_out                    (prefetch_address_out),
        .request_valid_out              (prefetch_valid_out),
        .issue_ack_in                   (prefetch_ack_in)
);

endmodule