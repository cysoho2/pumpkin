`include "parameters.h"

module unified_cache
#(
        parameter UNIFIED_CACHE_PACKET_WIDTH_IN_BITS = 70,
        parameter MEM_PACKET_WIDTH_IN_BITS           = 70
)
(
        input                                           reset_in,
        input                                           clk_in,

        // instruction packet
        input   [(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         inst_packet_in,
        output                                                         inst_packet_ack_out,

        output  [(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         inst_packet_out,
        input                                                          inst_packet_ack_in,

        // data packet
        input   [(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         data_packet_in,
        output                                                         data_packet_ack_out,

        output  [(UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         data_packet_out,
        input                                                          data_packet_ack_in,

        // to/from mem
        input   [(MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]   from_mem_packet_in,
        output                                         from_mem_packet_ack_out,

        output  [(MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]   to_mem_packet_out,
        input                                          to_mem_packet_ack_in    
);

// receives instruction packets
wire [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0] inst_packet_to_arbiter;
wire                                                 inst_packet_valid_to_arbiter;

fifo_queue
#(
        .QUEUE_SIZE                     (`INST_REQUEST_QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        (`INST_REQUEST_QUEUE_PTR_WIDTH_IN_BITS),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
)
inst_request_queue
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (), // intened left unconnected
        .is_full_out                    (is_inst_request_queue_full),

        .request_in                     (inst_packet_in),
        .request_valid_in               (inst_packet_in[`UNIFIED_CACHE_PACKET_VALID_POS]),
        .issue_ack_out                  (inst_packet_ack_out),
        .request_out                    (inst_packet_to_arbiter),
        .request_valid_out              (inst_packet_valid_to_arbiter),
        .issue_ack_in                   (packet_ack_to_inst_request_queue),
        .fifo_entry_packed_out          (), // intened left unconnected
        .fifo_entry_valid_packed_out    ()  // intened left unconnected
);

// receive data packet
wire [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0] data_packet_to_arbiter;
wire                                                 data_packet_valid_to_arbiter;

fifo_queue
#(
        .QUEUE_SIZE                     (`DATA_REQUEST_QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        (`DATA_REQUEST_QUEUE_PTR_WIDTH_IN_BITS),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
)
data_request_queue
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (),  // intended to left unconnected
        .is_full_out                    (is_data_request_queue_full),

        .request_in                     (data_packet_in),
        .request_valid_in               (data_packet_in[`UNIFIED_CACHE_PACKET_VALID_POS]),
        .issue_ack_out                  (data_packet_ack_out),
        .request_out                    (data_packet_to_arbiter),
        .request_valid_out              (data_packet_valid_to_arbiter),
        .issue_ack_in                   (packet_ack_to_data_request_queue),
        .fifo_entry_packed_out          (), // intended toleft unconnected
        .fifo_entry_valid_packed_out    ()  // intended to left unconnected
);

// arbiter
wire [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0] access_packet_from_arbiter;
wire                                                 ack_to_arbiter;

priority_arbiter
#(.NUM_REQUESTS(2), .SINGLE_REQUEST_WIDTH_IN_BITS(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS))
input_requests_arbiter
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        // the arbiter considers priority from right(high) to left(low)
        .request_packed_in              ({data_packet_to_arbiter, inst_packet_to_arbiter }),
        .request_valid_packed_in        ({data_packet_valid_to_arbiter, inst_packet_valid_to_arbiter}),
        .request_critical_packed_in     ({is_data_request_queue_full, is_inst_request_queue_full}),
        .issue_ack_out                  ({packet_ack_to_data_request_queue, packet_ack_to_inst_request_queue}),
        
        .request_out                    (access_packet_from_arbiter),
        .request_valid_out              (),
        .issue_ack_in                   (ack_to_arbiter)
);

assign to_mem_packet_out = access_packet_from_arbiter;
assign ack_to_arbiter = to_mem_packet_ack_in;

//assign data_packet_out = from_mem_packet_in[`MEM_PACKET_TYPE_POS_LO] == `DATA_PACKET_FLAG ? from_mem_packet_in : 0;
//assign inst_packet_out = from_mem_packet_in[`MEM_PACKET_TYPE_POS_LO] == `DATA_PACKET_FLAG ? 0 : from_mem_packet_in;
//assign from_mem_packet_ack_out = from_mem_packet_in[`MEM_PACKET_TYPE_POS_LO] == `DATA_PACKET_FLAG ? data_packet_ack_in : inst_packet_ack_in;


// tag array
unified_cache_tag_array
#(
        .SINGLE_TAG_SIZE_IN_BITS        ((`UNIFIED_CACHE_TAG_POS_HI) - (`UNIFIED_CACHE_TAG_POS_LO)),
        .NUMBER_WAYS                    (`UNIFIED_CACHE_SET_ASSOCIATIVITY),
        .NUMBER_SETS                    (`UNIFIED_CACHE_NUM_SETS),
        .SET_PTR_WIDTH_IN_BITS          (`UNIFIED_CACHE_INDEX_LEN_IN_BITS)
)
tag_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .way_select_in                  (),

        .read_en_in                     (),
        .read_set_addr_in               (),
        .read_tag_pack_out              (),

        .write_en_in                    (),
        .write_set_addr_in              (),
        
        .write_tag_in                   (),
        .evict_tag_out                  ()
);

// valid array
unified_cache_tag_array
#(
        .SINGLE_TAG_SIZE_IN_BITS        (1),
        .NUMBER_WAYS                    (`UNIFIED_CACHE_SET_ASSOCIATIVITY),
        .NUMBER_SETS                    (`UNIFIED_CACHE_NUM_SETS),
        .SET_PTR_WIDTH_IN_BITS          (`UNIFIED_CACHE_INDEX_LEN_IN_BITS)
)
valid_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .way_select_in                  (),

        .read_en_in                     (),
        .read_set_addr_in               (),
        .read_tag_pack_out              (),

        .write_en_in                    (),
        .write_set_addr_in              (),
        
        .write_tag_in                   (),
        .evict_tag_out                  ()
);

// history array
unified_cache_tag_array
#(
        .SINGLE_TAG_SIZE_IN_BITS        (1),
        .NUMBER_WAYS                    (`UNIFIED_CACHE_SET_ASSOCIATIVITY),
        .NUMBER_SETS                    (`UNIFIED_CACHE_NUM_SETS),
        .SET_PTR_WIDTH_IN_BITS          (`UNIFIED_CACHE_INDEX_LEN_IN_BITS)
)
history_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .way_select_in                  (),

        .read_en_in                     (),
        .read_set_addr_in               (),
        .read_tag_pack_out              (),

        .write_en_in                    (),
        .write_set_addr_in              (),
        
        .write_tag_in                   (),
        .evict_tag_out                  ()
);

unified_cache_data_array
#(
        .CACHE_BLOCK_SIZE_IN_BITS       (),
        .NUMBER_WAYS                    (`UNIFIED_CACHE_SET_ASSOCIATIVITY),
        .NUMBER_SETS                    (`UNIFIED_CACHE_NUM_SETS),
        .SET_PTR_WIDTH_IN_BITS          (`UNIFIED_CACHE_INDEX_LEN_IN_BITS)
)
data_array
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .way_select_in                  (),
        .access_en_in                   (),
        .write_en_in                    (),
        .access_set_addr_in             (),
    
        .read_data_out                  (),
        .write_data_in                  ()
);

writeback_buffer
#(
        .QUEUE_SIZE                     (`WRITEBACK_BUFFER_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        (`WRITEBACK_BUFFER_PTR_WIDTH_IN_BITS),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (`MEM_PACKET_WIDTH_IN_BITS),
        .ADDR_LEN_IN_BITS               (`CPU_DATA_LEN_IN_BITS),
        .STORAGE_TYPE                   ("LUTRAM")
)
writeback_buffer
(  
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (), // intened left unconnected
        .is_full_out                    (),

        .request_in                     (),
        .request_valid_in               (),
        .issue_ack_out                  (),
                
        .request_out                    (),
        .request_valid_out              (),
        .issue_ack_in                   (),
        
        .cam_address_in                 (),
        .cam_result_out                 ()
);

fifo_queue
#(
        .QUEUE_SIZE                     (`INST_REQUEST_QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        (`INST_REQUEST_QUEUE_PTR_WIDTH_IN_BITS),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
)
inst_return_queue
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (), // intened left unconnected
        .is_full_out                    (),

        .request_in                     (),
        .request_valid_in               (),
        .issue_ack_out                  (),
        .request_out                    (),
        .request_valid_out              (),
        .issue_ack_in                   (),
        .fifo_entry_packed_out          (), // intened left unconnected
        .fifo_entry_valid_packed_out    ()  // intened left unconnected
);

fifo_queue
#(
        .QUEUE_SIZE                     (`DATA_REQUEST_QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        (`DATA_REQUEST_QUEUE_PTR_WIDTH_IN_BITS),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
)
data_return_queue
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (),  // intened left unconnected
        .is_full_out                    (),

        .request_in                     (),
        .request_valid_in               (),
        .issue_ack_out                  (),
        .request_out                    (),
        .request_valid_out              (),
        .issue_ack_in                   (),
        .fifo_entry_packed_out          (), // intened left unconnected
        .fifo_entry_valid_packed_out    ()  // intened left unconnected
);

priority_arbiter
#(.NUM_REQUESTS(2), .SINGLE_REQUEST_WIDTH_IN_BITS(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS))
mem_requests_arbiter
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        // the arbiter considers priority from right(high) to left(low)
        .request_packed_in              (),
        .request_valid_packed_in        (),
        .request_critical_packed_in     (),
        .issue_ack_out                  (),
        
        .request_out                    (),
        .request_valid_out              (),
        .issue_ack_in                   ()
);

fifo_queue
#(
        .QUEUE_SIZE                     (`INST_REQUEST_QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS        (`INST_REQUEST_QUEUE_PTR_WIDTH_IN_BITS),
        .SINGLE_ENTRY_WIDTH_IN_BITS     (`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
)
mem_request_queue
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .is_empty_out                   (), // intened left unconnected
        .is_full_out                    (),

        .request_in                     (),
        .request_valid_in               (),
        .issue_ack_out                  (),
        .request_out                    (),
        .request_valid_out              (),
        .issue_ack_in                   (),
        .fifo_entry_packed_out          (), // intened left unconnected
        .fifo_entry_valid_packed_out    ()  // intened left unconnected
);

main_ctrl
#(
        // parameter list
)
(
        // port list
);

endmodule

