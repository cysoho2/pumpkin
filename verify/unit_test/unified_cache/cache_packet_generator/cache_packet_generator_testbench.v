`include "parameters.h"

module cache_packet_generator_testbench();

reg clk_in;
reg reset_in;

`define MEM_SIZE  64
`define MEM_DELAY 100
reg [`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS - 1 : 0] sim_memory [`MEM_SIZE - 1 : 0];
reg [31:0] clk_counter;

`define STATE_IDLE          0
`define STATE_DELAY         1
`define STATE_WRITE         2
`define STATE_READ_RETURN   3
reg [2:0] mem_ctrl_state;

wire [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]  test_packet_way0;
wire [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]  test_packet_way1;
wire                                                test_packet_ack_way0;
wire                                                test_packet_ack_way1;
wire  [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] return_packet_way0;
wire  [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] return_packet_way1;
wire                                                return_packet_ack_way0;
wire                                                return_packet_ack_way1;

wire done;
wire error;

reg  [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]  mem_to_cache_packet;
wire                                                from_cache_ack;
wire [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]  cache_to_mem_packet;
reg                                                 to_cache_ack;

wire access_full_addr = cache_to_mem_packet[`UNIFIED_CACHE_PACKET_VALID_POS] ? 
                        cache_to_mem_packet[`UNIFIED_CACHE_PACKET_ADDR_POS_HI :
                                            `UNIFIED_CACHE_PACKET_ADDR_POS_LO]
                        : 0;

wire [`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS   - 1 : 0]  write_mask_extend;
wire [`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN - 1 : 0]  write_mask = 
        cache_to_mem_packet[`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO];

generate
genvar mask_index;
for(mask_index = 0; mask_index < `UNIFIED_CACHE_BLOCK_SIZE_IN_BITS; mask_index = mask_index + 1)
begin
    assign write_mask_extend[mask_index] = write_mask[mask_index / `BYTE_LEN_IN_BITS];
end
endgenerate

cache_packet_generator
#(
    .NUM_WAY(2),
    .TIMING_OUT_CYCLE(`MEM_DELAY * 1000)
)
cache_packet_generator
(
    .clk_in                         (clk_in),
    .reset_in                       (reset_in),
    
    .test_packet_flatted_out        ({test_packet_way1, test_packet_way0}),
    .test_packet_ack_flatted_in     ({test_packet_ack_way1, test_packet_ack_way0}),
    .return_packet_flatted_in       ({return_packet_way1, return_packet_way0}),
    .return_packet_ack_flatted_out  ({return_packet_ack_way1, return_packet_ack_way0}),
    
    .done                           (done),
    .error                          (error)
);

// to cache packet
wire [`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]   to_cache_packet_concatenated;
packet_concat to_cache_packet_concat
(
    .addr_in        (cache_to_mem_packet[`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO]),
    .data_in        (cache_to_mem_packet[`UNIFIED_CACHE_PACKET_IS_WRITE_POS] ?
                     cache_to_mem_packet[`UNIFIED_CACHE_PACKET_DATA_POS_HI : `UNIFIED_CACHE_PACKET_DATA_POS_LO]:
                     sim_memory[access_full_addr >> `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS]),
    .type_in        (cache_to_mem_packet[`UNIFIED_CACHE_PACKET_TYPE_POS_HI : `UNIFIED_CACHE_PACKET_TYPE_POS_LO]),
    .write_mask_in  (cache_to_mem_packet[`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO]),
    .port_num_in    (cache_to_mem_packet[`UNIFIED_CACHE_PACKET_PORT_NUM_HI : `UNIFIED_CACHE_PACKET_PORT_NUM_LO]),
    .valid_in       (cache_to_mem_packet[`UNIFIED_CACHE_PACKET_VALID_POS]),
    .is_write_in    (cache_to_mem_packet[`UNIFIED_CACHE_PACKET_IS_WRITE_POS]),
    .cacheable_in   (cache_to_mem_packet[`UNIFIED_CACHE_PACKET_CACHEABLE_POS]),
    .packet_out     (to_cache_packet_concatenated)
);

unified_cache
#(
    .UNIFIED_CACHE_PACKET_WIDTH_IN_BITS (`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS),
    .NUM_INPUT_PORT                     (2),
    .NUM_BANK                           (`UNIFIED_CACHE_NUM_BANK),
    .NUM_SET                            (`UNIFIED_CACHE_NUM_SETS),
    .NUM_WAY                            (`UNIFIED_CACHE_SET_ASSOCIATIVITY),
    .BLOCK_SIZE_IN_BYTES                (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)
)
unified_cache
(
    .reset_in                       (reset_in),
    .clk_in                         (clk_in),
    .input_packet_flatted_in        ({test_packet_way1, test_packet_way0}),
    .input_packet_ack_flatted_out   ({test_packet_ack_way1, test_packet_ack_way0}),

    .return_packet_flatted_out      ({return_packet_way1, return_packet_way0}),
    .return_packet_ack_flatted_in   ({return_packet_ack_way1, return_packet_ack_way0}),

    .from_mem_packet_in             (mem_to_cache_packet),
    .from_mem_packet_ack_out        (from_cache_ack),

    .to_mem_packet_out              (cache_to_mem_packet),
    .to_mem_packet_ack_in           (to_cache_ack)
);

always@(posedge clk_in or posedge reset_in)
begin
    if(reset_in)
    begin
        mem_ctrl_state                  <= `STATE_IDLE;
        clk_counter                     <= 0;
        mem_to_cache_packet             <= 0;
        to_cache_ack                    <= 0;
    end

    else
    begin
        case(mem_ctrl_state)

            `STATE_IDLE:
            begin
                if(cache_to_mem_packet[`UNIFIED_CACHE_PACKET_VALID_POS])
                begin
                    mem_ctrl_state      <= `STATE_DELAY;
                end

                clk_counter             <= 0;
                mem_to_cache_packet     <= 0;
                to_cache_ack            <= 0;
            end

            `STATE_DELAY:
            begin
                if(cache_to_mem_packet[`UNIFIED_CACHE_PACKET_VALID_POS])
                begin
                    if(clk_counter <= `MEM_DELAY)
                    begin
                        mem_ctrl_state  <= mem_ctrl_state;
                        clk_counter     <= clk_counter + 1'b1;
                    end

                    else
                    begin
                        mem_ctrl_state  <= cache_to_mem_packet[`UNIFIED_CACHE_PACKET_IS_WRITE_POS] ?
                                          `STATE_WRITE : `STATE_READ_RETURN;
                        clk_counter     <= 0;
                    end

                    mem_to_cache_packet <= 0;
                    to_cache_ack        <= 0;
                end
            end

            `STATE_WRITE:
            begin
                sim_memory[access_full_addr >> `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS]
                <= write_mask_extend & cache_to_mem_packet[`UNIFIED_CACHE_PACKET_DATA_POS_HI :
                                                           `UNIFIED_CACHE_PACKET_DATA_POS_LO];
                mem_ctrl_state          <= `STATE_IDLE;
                clk_counter             <= 0;
                mem_to_cache_packet     <= 0;
                to_cache_ack            <= 1;
            end

            `STATE_READ_RETURN:
            begin
                if(from_cache_ack)
                    mem_ctrl_state      <= `STATE_IDLE;
                else
                    mem_ctrl_state      <= mem_ctrl_state;
                
                clk_counter             <= 0;
                mem_to_cache_packet     <= to_cache_packet_concatenated;
                to_cache_ack            <= 0;
            end
        endcase
    end
end

reg         test_case;
reg [511:0] test_case_content;
reg         test_judge;

initial
begin
    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, cache_packet_generator_testbench);
    `endif

    #(`FULL_CYCLE_DELAY * 10)    reset_in = 1'b0;
    #(`FULL_CYCLE_DELAY * 10)    reset_in = 1'b1;
    #(`FULL_CYCLE_DELAY * 10)    reset_in = 1'b0;

    $display("\n[info-testbench] simulation for %m begins now");

    test_case = 0;
    test_case_content = "cache packet generator";
    
    #(`FULL_CYCLE_DELAY * 100) test_judge = done & ~error === 1;
    $display("[info-testbench] test case %d %s : %s",
            test_case, test_case_content, test_judge? "passed" : "failed");
    
    #(`FULL_CYCLE_DELAY) $display("\n[info-rtl] simulation comes to the end\n");
    $finish;
end

always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

endmodule