`include "sim_config.h"
`include "parameters.h"

`define MEM_SIZE 64

module unified_cache_testbench();

reg                                                             clk_in;
reg                                                             reset_in;

reg     [31:0]                                                  clk_ctr;
reg     [1023:0]                                                mem_image_path;

reg     [(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS)   - 1 : 0]         sim_main_memory        [(`MEM_SIZE)   - 1 : 0];
reg     [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way1_packet_issue      [(`MEM_SIZE)/2 - 1 : 0];
reg     [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way2_packet_issue      [(`MEM_SIZE)/2 - 1 : 0];
reg     [(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS) - 1 : 0]           correct_result_mem_1   [(`MEM_SIZE)/2 - 1 : 0];
reg     [(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS) - 1 : 0]           correct_result_mem_2   [(`MEM_SIZE)/2 - 1 : 0];

reg     [31:0]                                                  correct_result_ctr_1;
reg     [31:0]                                                  correct_result_ctr_2;
reg     [31:0]                                                  test_hit_1;
reg     [31:0]                                                  test_hit_2;

reg                                                             test_judge;
reg                                                             test_way1_enable;
reg                                                             test_way2_enable;

reg                                                             test_way1_ack_in_ctr;
reg                                                             test_way2_ack_in_ctr;

reg     [15:0]                                                   test_gen_char          [15:0];
reg     [1023:0]                                                test_case_char         [15:0];

integer                                                         test_gen;
integer                                                         test_case;
integer                                                         test_latency;
integer                                                         test_phase;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way1_packet_to_cache;
wire                                                            way1_packet_ack_from_cache;
reg     [$clog2(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS):0]         way1_packet_index;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way1_packet_from_cache;
reg                                                             way1_packet_ack_to_cache;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way2_packet_to_cache;
wire                                                            way2_packet_ack_from_cache;
reg     [$clog2(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) :0]        way2_packet_index;

wire    [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         way2_packet_from_cache;
reg                                                             way2_packet_ack_to_cache;

reg     [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]         mem_packet_to_cache;
wire                                                            mem_packet_ack_from_cache;

wire     [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]        mem_packet_from_cache;
reg      [(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS) - 1 : 0]        cache_packet_pending;
reg                                                             mem_packet_ack_to_cache;

assign way1_packet_to_cache = test_way1_enable? way1_packet_issue[way1_packet_index] : {(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'b0}};
assign way2_packet_to_cache = test_way2_enable? way2_packet_issue[way2_packet_index] : {(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS){1'bz}};

always@(posedge clk_in or posedge reset_in)
begin
    if (reset_in)
    begin
            way1_packet_index       <= 0;
            way2_packet_index       <= 0;

            mem_packet_to_cache     <= 0;

            way1_packet_ack_to_cache <= 1;
            way2_packet_ack_to_cache <= 1;
            mem_packet_ack_to_cache  <= 1;
            
            correct_result_ctr_1     <= 0;
            correct_result_ctr_2     <= 0;
            
            test_hit_1               <= 0;
            test_hit_2               <= 0;
                        
            test_way1_ack_in_ctr     <= 0;
            test_way2_ack_in_ctr     <= 0;
                        
            test_way1_enable         <= 0;
            test_way2_enable         <= 0;
            test_judge               <= 0;
    end

    else
    begin
        // way1 packet 
        
        if(test_way1_enable)
        begin
            if(way1_packet_ack_from_cache)
            begin
                way1_packet_index <= way1_packet_index + 1'b1;
            end

            else
            begin
                    way1_packet_index <= way1_packet_index;
            end

            if(way1_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS]) 
            begin
                    test_way1_ack_in_ctr     <= test_way1_ack_in_ctr + 1'b1;
                    way1_packet_ack_to_cache <= 1'b1;
                    
                    if (~way1_packet_ack_to_cache & ~ way1_packet_from_cache[`UNIFIED_CACHE_PACKET_IS_WRITE_POS])
                    begin
                        if (~(|(correct_result_mem_1[correct_result_ctr_1] ^ way1_packet_from_cache[`UNIFIED_CACHE_PACKET_DATA_POS_HI : `UNIFIED_CACHE_PACKET_DATA_POS_LO])))
                        begin
                            test_hit_1 = test_hit_1 + 1'b1;
                        end
                        else
                        begin
                            test_hit_1 = test_hit_1;
                        end
                        
                        correct_result_ctr_1 = correct_result_ctr_1 + 1'b1;
                    end
            end
            
            else
            begin
                    way1_packet_ack_to_cache <= 1'b0;
            end
        end

        // way2 packet
        if (test_way2_enable)
        begin
            if(way2_packet_ack_from_cache)
            begin
                    way2_packet_index <= way2_packet_index + 1'b1;
            end
    
            else
            begin
                    way2_packet_index <= way2_packet_index;
            end
    
            if(way2_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS]) 
            begin
                test_way2_ack_in_ctr     <= test_way2_ack_in_ctr + 1'b1;
                way2_packet_ack_to_cache <= 1'b1;
                                
                if (~way2_packet_ack_to_cache & ~ way2_packet_from_cache[`UNIFIED_CACHE_PACKET_IS_WRITE_POS])
                begin
                    if (~(|(correct_result_mem_2[correct_result_ctr_2] ^ way2_packet_from_cache[`UNIFIED_CACHE_PACKET_DATA_POS_HI : `UNIFIED_CACHE_PACKET_DATA_POS_LO])))
                    begin
                        test_hit_2 = test_hit_2 + 1'b1;
                    end
                    
                    else
                    begin
                        test_hit_2 = test_hit_2;
                    end
                                    
                        correct_result_ctr_2 = correct_result_ctr_2 + 1'b1;
                end
            end                                          
            
            else
            begin
                    way2_packet_ack_to_cache <= 1'b0;
            end
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
    
    else if(mem_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS] & (clk_ctr % test_latency == 0) & (~mem_packet_ack_to_cache))
    begin
        mem_packet_ack_to_cache <= 1;
        
        if ({mem_packet_from_cache[`UNIFIED_CACHE_PACKET_IS_WRITE_POS]})
        begin
            sim_main_memory[mem_packet_from_cache[`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO]] = mem_packet_from_cache[`UNIFIED_CACHE_PACKET_DATA_POS_HI : `UNIFIED_CACHE_PACKET_DATA_POS_LO];
        end
        
        cache_packet_pending    <=
        {   
            /*cacheable*/   {mem_packet_from_cache[`UNIFIED_CACHE_PACKET_CACHEABLE_POS]},
            /*write*/       {mem_packet_from_cache[`UNIFIED_CACHE_PACKET_IS_WRITE_POS]},                   
            /*valid*/       {mem_packet_from_cache[`UNIFIED_CACHE_PACKET_VALID_POS]},
            /*port*/        {mem_packet_from_cache[`UNIFIED_CACHE_PACKET_PORT_NUM_HI : `UNIFIED_CACHE_PACKET_PORT_NUM_LO]},
            /*byte mask*/   {mem_packet_from_cache[`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO]},     
            /*type*/        {mem_packet_from_cache[`UNIFIED_CACHE_PACKET_TYPE_POS_HI : `UNIFIED_CACHE_PACKET_TYPE_POS_LO]},
            /*data*/        {sim_main_memory[mem_packet_from_cache[`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO]]},
            /*addr*/        {mem_packet_from_cache[`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO]}
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

    else if(mem_packet_to_cache[`UNIFIED_CACHE_PACKET_VALID_POS] & ~mem_packet_ack_from_cache)
    begin
        mem_packet_to_cache     <= mem_packet_to_cache;
    end

    else if(mem_packet_to_cache[`UNIFIED_CACHE_PACKET_VALID_POS] & mem_packet_ack_from_cache)
    begin
        mem_packet_to_cache     <= 0; 
    end
end

always@(posedge clk_in or posedge reset_in)
begin
    if (reset_in)
    begin
        test_latency = 200;
    end
    
    else
    begin
        case(test_phase)
        0: test_latency = 20;
        1: test_latency = 2;
        2: test_latency = 200;
        endcase
    end
    
end

always@(posedge clk_in or posedge reset_in)
begin
    if (reset_in)
    begin
            clk_ctr <= 1;
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
    
                                clk_in                               = 1'b0;
                                reset_in                             = 1'b0;
                                test_case                            = 1'b0;
      
                                mem_image_path = {`MEM_IMAGE_DIR, "/unified_cache/sim_main_mem"};
                                
                                test_gen_char[0]                     = "0";
                                test_gen_char[1]                     = "1";
                                test_gen_char[2]                     = "2";
                                test_gen_char[3]                     = "3";
                                
                                test_gen_char[4]                     = "4";
                                test_gen_char[5]                     = "5";
                                test_gen_char[6]                     = "6";
                                test_gen_char[7]                     = "7";
                                
                                test_gen_char[8]                     = "8";
                                test_gen_char[9]                     = "9";
                                test_gen_char[10]                    = "10";
                                test_gen_char[11]                    = "11";
                                
                                test_gen_char[12]                    = "12";
                                test_gen_char[13]                    = "13";
                                test_gen_char[14]                    = "14";
                                test_gen_char[15]                    = "15";
    
                                test_case_char[0]                    = "single-way random read";
                                test_case_char[1]                    = "single-way random write and read";
                                test_case_char[2]                    = "single-way interleaved-bank read";
                                test_case_char[3]                    = "single-way interleaved-bank write and read";
                                
                                test_case_char[4]                    = "single-way same-bank read";
                                test_case_char[5]                    = "single-way same-bank write and read";
                                test_case_char[6]                    = "single-way same-set read";
                                test_case_char[7]                    = "single-way same-set write and read";
                                
                                test_case_char[8]                    = "dual-way random read";
                                test_case_char[9]                    = "dual-way random write and read";
                                test_case_char[10]                   = "dual-way interleaved-bank read";
                                test_case_char[11]                   = "dual-way interleaved-bank write and read";
                                
                                test_case_char[12]                   = "dual-way same-bank read";
                                test_case_char[13]                   = "dual-way same-bank write and read";
                                test_case_char[14]                   = "dual-way same-set read";
                                test_case_char[15]                   = "dual-way same-set write and read";
    

    //case 0 ~ case 7
    for (test_gen = 0; test_gen < 4; test_gen = test_gen + 1'b1)
    begin                             
                                
        #(`FULL_CYCLE_DELAY * 2)    reset_in                             = 1'b1;
        #(`FULL_CYCLE_DELAY)        reset_in                             = 1'b0;
    
        //case 0
                                    test_phase                           <= 0;
                                    test_way1_enable                     <= 1;
                                    test_way2_enable                     <= 0;
    
    
        $readmemb(mem_image_path, sim_main_memory);
        $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_request_pool"}, way1_packet_issue);
        $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_correct_result_mem"}, correct_result_mem_1);
        
        #(`FULL_CYCLE_DELAY * 8000) test_judge                           = (test_hit_1 == (`MEM_SIZE) / 2)? 1 : 0;
        $display("[info-testbench] test case %d%35s : \t%s", test_case, {"                        ", test_case_char[test_case]}, test_judge? "passed" : "failed");

        
         //case 1 (phase 1)
                                     test_phase                           <= 1;
         #(`FULL_CYCLE_DELAY)        test_case                            <= test_case + 1'b1;
         #(`FULL_CYCLE_DELAY)        reset_in                             = 1'b1;
         #(`FULL_CYCLE_DELAY)        reset_in                             = 1'b0;
         
                                     test_way1_enable                     <= 1;
                                     test_way2_enable                     <= 0;
         
    
         $readmemb(mem_image_path, sim_main_memory);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_request_pool"}, way1_packet_issue);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_correct_result_mem"}, correct_result_mem_1);     
    
         #(`FULL_CYCLE_DELAY * 8000) test_judge = (test_hit_1 == (`MEM_SIZE) / 4)? 1 : 0;
         $display("[info-testbench] test case %d%35s : \t%s", test_case, {" (latency : 2 cycles)   ", test_case_char[test_case]}, test_judge? "passed" : "failed");

         
         //case 1 (phase 2)
                                     test_phase                           <= 2;

                                         
         #(`FULL_CYCLE_DELAY)        reset_in                             = 1'b1;
         #(`FULL_CYCLE_DELAY)        reset_in                             = 1'b0;
                                     
                                     test_way1_enable                     <= 1;
                                     test_way2_enable                     <= 0;         
    
         $readmemb(mem_image_path, sim_main_memory);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_request_pool"}, way1_packet_issue);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_correct_result_mem"}, correct_result_mem_1); 
         
     
         #(`FULL_CYCLE_DELAY * 8000) test_judge = (test_hit_1 == (`MEM_SIZE) / 4)? 1 : 0;
         $display("[info-testbench] test case %d%35s : \t%s", test_case,{" (latency : 200 cycles) ", test_case_char[test_case]}, test_judge? "passed" : "failed");
         
         test_case                                                        <= test_case + 1'b1;
    end
     
    //case 8 ~ case 15
    for (test_gen = 4; test_gen < 8; test_gen = test_gen + 1'b1)
    begin  
        //case 8
                                     test_phase                          <= 0;
        
         #(`FULL_CYCLE_DELAY)        reset_in                            = 1'b1;
         #(`FULL_CYCLE_DELAY)        reset_in                            = 1'b0;
    
                                     test_way1_enable                    <= 1;
                                     test_way2_enable                    <= 1;
    
        $readmemb(mem_image_path, sim_main_memory);
        $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_request_pool"}, way1_packet_issue);
        $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_correct_result_mem"}, correct_result_mem_1);
        $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way2_request_pool"}, way2_packet_issue);
        $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way2_correct_result_mem"}, correct_result_mem_2); 
        
        #(`FULL_CYCLE_DELAY * 8000) test_judge = (test_hit_1 == (`MEM_SIZE) / 2 && test_hit_2 == (`MEM_SIZE) / 2)? 1 : 0;
        $display("[info-testbench] test case %d%35s : \t%s", test_case,  {"                        ", test_case_char[test_case]}, test_judge? "passed" : "failed");

        
        //case 9 (phase 1)
                                     test_phase                          <= 1;
                                     test_case                           <= test_case + 1'b1;
         
         #(`FULL_CYCLE_DELAY)        reset_in                            = 1'b1;
         #(`FULL_CYCLE_DELAY)        reset_in                            = 1'b0;
         
                                     test_way1_enable                    <= 1;
                                     test_way2_enable                    <= 1;
    
         $readmemb(mem_image_path, sim_main_memory);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_request_pool"}, way1_packet_issue);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_correct_result_mem"}, correct_result_mem_1);     
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way2_request_pool"}, way2_packet_issue);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way2_correct_result_mem"}, correct_result_mem_2); 
    
         #(`FULL_CYCLE_DELAY * 8000) test_judge = (test_hit_1 == (`MEM_SIZE) / 4 && test_hit_2 == (`MEM_SIZE) / 4)? 1 : 0;
         $display("[info-testbench] test case %d%35s : \t%s", test_case, {" (latency : 2 cycles)   ", test_case_char[test_case]}, test_judge? "passed" : "failed");

         
         //case 9 (phase 2)
                                     test_phase                         <= 2;
                                         
         #(`FULL_CYCLE_DELAY)        reset_in                           = 1'b1;
         #(`FULL_CYCLE_DELAY)        reset_in                           = 1'b0;
         
                                     test_way1_enable                   <= 1;
                                     test_way2_enable                   <= 1;
    
         $readmemb(mem_image_path, sim_main_memory);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_request_pool"}, way1_packet_issue);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way1_correct_result_mem"}, correct_result_mem_1);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way2_request_pool"}, way2_packet_issue);
         $readmemb({`MEM_IMAGE_DIR, "/unified_cache/case_", test_gen_char[test_case], "/way2_correct_result_mem"}, correct_result_mem_2);  
     
         #(`FULL_CYCLE_DELAY * 8000) test_judge = ((test_hit_1 == ((`MEM_SIZE)) / 4)) && (test_hit_2 == ((`MEM_SIZE) / 4))? 1 : 0;
         $display("[info-testbench] test case %d%35s : \t%s", test_case, {" (latency : 200 cycles) ", test_case_char[test_case]}, test_judge? "passed" : "failed");
         
         test_case                                                        <= test_case + 1'b1;
    end
 
 
     #(`FULL_CYCLE_DELAY * 3000)  $display("\n[info-testbench] simulation for %m comes to the end\n");
                                  $finish;

end

unified_cache
#(
    .NUM_INPUT_PORT(2),
    .NUM_BANK(4),
    .UNIFIED_CACHE_PACKET_WIDTH_IN_BITS(`UNIFIED_CACHE_PACKET_WIDTH_IN_BITS)
)
unified_cache
(
    .reset_in                       (reset_in),
    .clk_in                         (clk_in),

    .input_packet_flatted_in        ({way2_packet_to_cache, way1_packet_to_cache}),
    .input_packet_ack_flatted_out   ({way2_packet_ack_from_cache, way1_packet_ack_from_cache}),
    
    .output_packet_flatted_out      ({way2_packet_from_cache, way1_packet_from_cache}),
    .output_packet_ack_flatted_in   ({way2_packet_ack_to_cache, way1_packet_ack_to_cache}),

    .from_mem_packet_in             (mem_packet_to_cache),
    .from_mem_packet_ack_out        (mem_packet_ack_from_cache),

    .to_mem_packet_out              (mem_packet_from_cache),
    .to_mem_packet_ack_in           (mem_packet_ack_to_cache)
);

endmodule
