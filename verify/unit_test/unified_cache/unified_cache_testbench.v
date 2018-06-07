`include "sim_config.h"
`include "parameters.h"

`define MEM_SIZE 32

module unified_cache_testbench();

reg                                                             clk_in;
reg                                                             reset_in;

reg     [31:0]                                                  clk_ctr;

reg     [(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS)   - 1 : 0]         sim_main_memory        [(`MEM_SIZE)   - 1 : 0];
reg     [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way1_packet_issue      [(`MEM_SIZE)/2 - 1 : 0];
reg     [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way2_packet_issue      [(`MEM_SIZE)/2 - 1 : 0];

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way1_packet_to_cache;
wire                                                            way1_packet_ack_from_cache;
reg     [1:0]                                                   way1_packet_index;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way1_packet_from_cache;
reg                                                             way1_packet_ack_to_cache;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way2_packet_to_cache;
wire                                                            way2_packet_ack_from_cache;
reg     [1:0]                                                   way2_packet_index;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way2_packet_from_cache;
reg                                                             way2_packet_ack_to_cache;

reg     [(`MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]                   mem_packet_to_cache;
wire                                                            mem_packet_ack_from_cache;

wire     [(`MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]                  mem_packet_from_cache;
reg      [(`MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]                  cache_packet_pending;
reg                                                             mem_packet_ack_to_cache;

assign way1_packet_to_cache = way1_packet_issue[way1_packet_index];
assign way2_packet_to_cache = way2_packet_issue[way2_packet_index];

always@(posedge clk_in or posedge reset_in)
begin
    if (reset_in)
    begin
            way1_packet_index       <= 0;
            way2_packet_index       <= 0;

            mem_packet_to_cache     <= 0;

            way1_packet_ack_to_cache <= 0;
            way2_packet_ack_to_cache <= 0;
            mem_packet_ack_to_cache  <= 0;
    end

    else
    begin
        // way1 packet 
        if(way1_packet_ack_from_cache)
        begin
                way1_packet_index <= way1_packet_index + 1'b1;
        end

        else
        begin
                way1_packet_index <= way1_packet_index;
        end

        if(clk_ctr % 5 == 0 & way1_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS])
        begin
                way1_packet_ack_to_cache <= 1'b1;
        end
        
        else
        begin
                way1_packet_ack_to_cache <= 1'b0;
        end

        // way2 packet
        if(way2_packet_ack_from_cache)
        begin
                way2_packet_index <= way2_packet_index + 1'b1;
        end

        else
        begin
                way2_packet_index <= way2_packet_index;
        end

        if(clk_ctr % 6 == 0 & way2_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS])
        begin
                way2_packet_ack_to_cache <= 1'b1;
        end
        
        else
        begin
                way2_packet_ack_to_cache <= 1'b0;
        end
        
        // way1 packet 
        if(way1_packet_ack_from_cache)
        begin
                way1_packet_index <= way1_packet_index + 1'b1;
        end

        else
        begin
                way1_packet_index <= way1_packet_index;
        end

        if(clk_ctr % 5 == 0 & way1_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS])
        begin
                way1_packet_ack_to_cache <= 1'b1;
        end
        
        else
        begin
                way1_packet_ack_to_cache <= 1'b0;
        end

        // way2 packet
        if(way2_packet_ack_from_cache)
        begin
                way2_packet_index <= way2_packet_index + 1'b1;
        end

        else
        begin
                way2_packet_index <= way2_packet_index;
        end

        if(clk_ctr % 6 == 0 & way2_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS])
        begin
                way2_packet_ack_to_cache <= 1'b1;
        end
        
        else
        begin
                way2_packet_ack_to_cache <= 1'b0;
        end
    end
end

// from cache packet
always@(posedge clk_in or posedge reset_in)
begin
    if(reset_in)
    begin
        mem_packet_ack_to_cache <= 0;
        cache_packet_pending    <= 0;
    end
    
    else if(mem_packet_from_cache[`MEM_PACKET_VALID_POS] & clk_ctr % 6 == 0 & ~mem_packet_ack_to_cache)
    begin
        mem_packet_ack_to_cache <= 1;
        cache_packet_pending    <=
        {   
                /*type*/{mem_packet_from_cache[`MEM_PACKET_TYPE_POS_HI : `MEM_PACKET_TYPE_POS_LO]},
                /*write*/{1'b0},
                /*valid*/{1'b1},
                /*data*/{sim_main_memory[mem_packet_from_cache[mem_packet_from_cache[`MEM_PACKET_ADDR_POS_HI : `MEM_PACKET_ADDR_POS_LO]]]},
                /*addr*/{mem_packet_from_cache[`MEM_PACKET_ADDR_POS_HI : `MEM_PACKET_ADDR_POS_LO]}
        };
    end

    else if(mem_packet_ack_to_cache)
    begin
        mem_packet_ack_to_cache <= 0;
        cache_packet_pending    <= 0;
    end
end

// to cache packet
always@(posedge clk_in or posedge reset_in)
begin
    if(reset_in)
    begin
        mem_packet_to_cache     <= 0;
    end
    
    else if(mem_packet_ack_to_cache)
    begin
        mem_packet_to_cache     <= cache_packet_pending;
    end

    else if(mem_packet_to_cache[`MEM_PACKET_VALID_POS] & ~mem_packet_ack_from_cache)
    begin
        mem_packet_to_cache     <= mem_packet_to_cache;
    end

    else if(mem_packet_to_cache[`MEM_PACKET_VALID_POS] & mem_packet_ack_from_cache)
    begin
        mem_packet_to_cache     <= 0; 
    end
end

always@(posedge clk_in or posedge reset_in)
begin
    if (reset_in)
    begin
            clk_ctr <= 0;
    end
    
    else
    begin
            clk_ctr <= clk_ctr + 1'b1;    
    end
end

always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

initial
begin
    
    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, unified_cache_testbench);
    `endif
    
    $display("\n[info-testbench] simulation for %m begins now");
    //$readmemh(`MEM_FILE_PATH, sim_main_memory);
                            clk_in   = 1'b0;
                            reset_in = 1'b0;
#(`FULL_CYCLE_DELAY)        reset_in = 1'b1;
#(`FULL_CYCLE_DELAY)        reset_in = 1'b0;

        sim_main_memory[0] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}};
        sim_main_memory[1] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 1;
        sim_main_memory[2] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 2;
        sim_main_memory[3] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 3;
        sim_main_memory[4] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 4;
        sim_main_memory[5] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 5;
        sim_main_memory[6] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 6;
        sim_main_memory[7] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 7;

        way1_packet_issue[0] = {/*type*/ 3'b000, /*write*/1'b0, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_DATA_LEN_IN_BITS'h0001} };
        way1_packet_issue[1] = {/*type*/ 3'b000, /*write*/1'b0, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_DATA_LEN_IN_BITS'h0002} };
        way1_packet_issue[2] = {/*type*/ 3'b000, /*write*/1'b0, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_DATA_LEN_IN_BITS'h0003} };
        way1_packet_issue[3] = {/*type*/ 3'b000, /*write*/1'b0, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_DATA_LEN_IN_BITS'h0004} };

        way2_packet_issue[0] = {/*type*/ 3'b100, /*write*/1'b1, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_DATA_LEN_IN_BITS'h1001} };
        way2_packet_issue[1] = {/*type*/ 3'b100, /*write*/1'b1, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_DATA_LEN_IN_BITS'h1002} };
        way2_packet_issue[2] = {/*type*/ 3'b100, /*write*/1'b1, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_DATA_LEN_IN_BITS'h1003} };
        way2_packet_issue[3] = {/*type*/ 3'b100, /*write*/1'b1, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_DATA_LEN_IN_BITS'h1004} };

#(`FULL_CYCLE_DELAY * 300)  $display("\n[info-testbench] simulation for %m comes to the end\n");
                            $finish;

end

unified_cache
#(
    .NUM_INPUT_PORT(2),
    .UNIFIED_CACHE_PACKET_WIDTH_IN_BITS(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS),
    .MEM_PACKET_WIDTH_IN_BITS(`MEM_PACKET_WIDTH_IN_BITS)
)
unified_cache
(
    .reset_in                       (reset_in),
    .clk_in                         (clk_in),

    .input_packet_flatted_in        ({way1_packet_to_cache, way2_packet_to_cache}),
    .input_packet_ack_flatted_out   ({way1_packet_ack_from_cache, way2_packet_ack_from_cache}),
    
    .output_packet_flatted_out      ({way1_packet_from_cache, way2_packet_from_cache}),
    .output_packet_ack_flatted_in   ({way1_packet_ack_to_cache, way2_packet_ack_to_cache}),

    .from_mem_packet_in             (mem_packet_to_cache),
    .from_mem_packet_ack_out        (mem_packet_ack_from_cache),

    .to_mem_packet_out              (mem_packet_from_cache),
    .to_mem_packet_ack_in           (mem_packet_ack_to_cache)
);

endmodule
