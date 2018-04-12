`timescale 10ns/1ns
`include "parameters.h"

`define MEM_SIZE 32

module unified_cache_testbench();

reg     [(`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES) - 1 : 0]    sim_main_memory        [(`MEM_SIZE) - 1 : 0];
reg     [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]                         inst_packet_issue      [(`MEM_SIZE)/2 - 1 : 0];
reg     [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]                         data_packet_issue      [(`MEM_SIZE)/2 - 1 : 0];

reg             clk_in;
reg             reset_in;

reg     [31:0]  clk_ctr;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         inst_packet_to_cache;
wire                                                            inst_packet_ack_from_cache;
reg     [1:0]                                                   inst_packet_index;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         inst_packet_from_cache;
reg                                                             inst_packet_ack_to_cache;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         data_packet_to_cache;
wire                                                            data_packet_ack_from_cache;
reg     [1:0]                                                   data_packet_index;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         data_packet_from_cache;
reg                                                             data_packet_ack_to_cache;

reg     [(`MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]                   mem_packet_to_cache;
wire                                                            mem_packet_ack_from_cache;

wire     [(`MEM_PACKET_WIDTH_IN_BITS) - 1 : 0]                  mem_packet_from_cache;
reg                                                             mem_packet_ack_to_cache;

assign inst_packet_to_cache = inst_packet_issue[inst_packet_index];
assign data_packet_to_cache = data_packet_issue[data_packet_index];

always@(posedge clk_in or posedge reset_in)
begin
        if (reset_in)
        begin
                inst_packet_index       <= 0;
                data_packet_index       <= 0;

                mem_packet_to_cache     <= 0;

                inst_packet_ack_to_cache <= 0;
                data_packet_ack_to_cache <= 0;
                mem_packet_ack_to_cache  <= 0;
        end

        else
        begin
                // inst packet 
                if(inst_packet_ack_from_cache)
                begin
                        inst_packet_index <= inst_packet_index + 1'b1;
                end

                else
                begin
                        inst_packet_index <= inst_packet_index;
                end

                if(clk_ctr % 5 == 0 & inst_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS])
                begin
                        inst_packet_ack_to_cache <= 1'b1;
                end
                
                else
                begin
                        inst_packet_ack_to_cache <= 1'b0;
                end

                // data packet
                if(data_packet_ack_from_cache)
                begin
                        data_packet_index <= data_packet_index + 1'b1;
                end

                else
                begin
                        data_packet_index <= data_packet_index;
                end

                if(clk_ctr % 6 == 0 & data_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS])
                begin
                        data_packet_ack_to_cache <= 1'b1;
                end
                
                else
                begin
                        data_packet_ack_to_cache <= 1'b0;
                end

                // mem packet
                if(mem_packet_from_cache[`MEM_PACKET_VALID_POS])
                begin
                        if(~mem_packet_to_cache[`MEM_PACKET_VALID_POS])
                        begin
                                mem_packet_to_cache 
                                <= {   
                                        /*type*/{mem_packet_from_cache[`MEM_PACKET_TYPE_POS_HI : `MEM_PACKET_TYPE_POS_LO]},
                                	/*write*/{1'b0},
                                	/*valid*/{1'b1},
                                        /*data*/{sim_main_memory[mem_packet_from_cache[mem_packet_from_cache[`MEM_PACKET_ADDR_POS_HI : `MEM_PACKET_ADDR_POS_LO]]]},
                                        /*addr*/{mem_packet_from_cache[`MEM_PACKET_ADDR_POS_HI : `MEM_PACKET_ADDR_POS_LO]}
                                };
                                
                                mem_packet_ack_to_cache <= 1;
                        end

                        else
                        begin
                                mem_packet_ack_to_cache <= 0;
                        end

                end

                if(mem_packet_to_cache[`MEM_PACKET_VALID_POS] & mem_packet_ack_from_cache)
                begin
                        mem_packet_to_cache <= 0;
                end
        end
end

always begin #1 clk_in <= ~clk_in; end

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

initial
begin
        $display("simulation start!");
        //$readmemh(`MEM_FILE_PATH, sim_main_memory);
        clk_in   = 1'b0;
        reset_in = 1'b0;
#1      reset_in = 1'b1;
#1      reset_in = 1'b0;

        sim_main_memory[0] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}};
        sim_main_memory[1] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 1;
        sim_main_memory[2] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 2;
        sim_main_memory[3] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 3;
        sim_main_memory[4] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 4;
        sim_main_memory[5] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 5;
        sim_main_memory[6] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 6;
        sim_main_memory[7] = {((`BYTE_LEN_IN_BITS) * (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)){1'h0}} + 7;

        inst_packet_issue[0] = {/*type*/ 3'b000, `INST_PACKET_FLAG, /*write*/1'b0, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_WORD_LEN_IN_BITS'h00} };
        inst_packet_issue[1] = {/*type*/ 3'b000, `INST_PACKET_FLAG, /*write*/1'b0, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_WORD_LEN_IN_BITS'h10} };
        inst_packet_issue[2] = {/*type*/ 3'b000, `INST_PACKET_FLAG, /*write*/1'b0, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_WORD_LEN_IN_BITS'h20} };
        inst_packet_issue[3] = {/*type*/ 3'b000, `INST_PACKET_FLAG, /*write*/1'b0, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_WORD_LEN_IN_BITS'h30} };

        data_packet_issue[0] = {/*type*/ 3'b000, `DATA_PACKET_FLAG, /*write*/1'b1, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_WORD_LEN_IN_BITS'h40} };
        data_packet_issue[1] = {/*type*/ 3'b000, `DATA_PACKET_FLAG, /*write*/1'b1, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_WORD_LEN_IN_BITS'h50} };
        data_packet_issue[2] = {/*type*/ 3'b000, `DATA_PACKET_FLAG, /*write*/1'b1, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_WORD_LEN_IN_BITS'h60} };
        data_packet_issue[3] = {/*type*/ 3'b000, `DATA_PACKET_FLAG, /*write*/1'b1, /*valid*/1'b1, /*data*/{(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}}, /*addr*/{`CPU_WORD_LEN_IN_BITS'h70} };

#30000  
        $finish;

end

unified_cache unified_cache
(
        .reset_in                       (reset_in),
        .clk_in                         (clk_in),

        .inst_packet_in                 (inst_packet_to_cache),
        .inst_packet_ack_out            (inst_packet_ack_from_cache),
        
        .inst_packet_out                (inst_packet_from_cache),
        .inst_packet_ack_in             (inst_packet_ack_to_cache),

        .data_packet_in                 (data_packet_to_cache),
        .data_packet_ack_out            (data_packet_ack_from_cache),

        .data_packet_out                (data_packet_from_cache),
        .data_packet_ack_in             (data_packet_ack_to_cache),

        .from_mem_packet_in             (mem_packet_to_cache),
        .from_mem_packet_ack_out        (mem_packet_ack_from_cache),

        .to_mem_packet_out              (mem_packet_from_cache),
        .to_mem_packet_ack_in           (mem_packet_ack_to_cache)
);

endmodule
