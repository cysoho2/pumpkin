`include "sim_config.h"
`include "parameters.h"

module find_first_one_index_testbench();

    parameter                                   VECTOR_LENGTH   = 8;
    
    parameter                                   TEST_INDEX_1    = 1;
    parameter                                   TEST_INDEX_2    = VECTOR_LENGTH / 2;    
    parameter                                   TEST_INDEX_3    = VECTOR_LENGTH - 1;   
    
    reg                                         clk_in;
    reg                                         reset_in;
    reg  [31 : 0]                               clk_ctr;                  

    reg  [VECTOR_LENGTH - 1 : 0]                vector_input;
    wire [31                : 0]                first_one_index;
    
    integer                                     test_case_num;
    reg                                         test_judge;
    reg  [VECTOR_LENGTH - 1 : 0]                test_input_1;

    find_first_one_index
    #(
        .VECTOR_LENGTH                          (VECTOR_LENGTH)
    )
    
    find_first_one_index
    (
        .vector_input                           (vector_input),
        .first_one_index                        (first_one_index)
    );

    initial
    begin
        $display("\n[info-rtl] simulation begins now\n");
        
        clk_in                                  = 1'b0;
        reset_in                                = 1'b0;
        test_case_num                           = 1'b0;
        vector_input                            = {(VECTOR_LENGTH){1'b0}};
        test_judge                              = 1'b0;
        
        #(`FULL_CYCLE_DELAY) reset_in           = 1'b1;
        #(`FULL_CYCLE_DELAY) reset_in           = 1'b0;
        
        #(`FULL_CYCLE_DELAY) test_case_num      = test_case_num + 1'b1;
        
        
        #(`FULL_CYCLE_DELAY) test_input_1       = { {(TEST_INDEX_1){1'b0}}, {(VECTOR_LENGTH - TEST_INDEX_1){1'b1}}};
        #(`FULL_CYCLE_DELAY) test_judge         = test_judge | (TEST_INDEX_1 -1 == first_one_index);
        #(`FULL_CYCLE_DELAY) vector_input       = test_input_1;
      
        #(`FULL_CYCLE_DELAY) test_input_1       = {{(TEST_INDEX_2){1'b0}}, {(VECTOR_LENGTH - TEST_INDEX_2){1'b1}}};
        #(`FULL_CYCLE_DELAY) test_judge         = test_judge | (TEST_INDEX_2 -1 == first_one_index);
        #(`FULL_CYCLE_DELAY) vector_input       = test_input_1;
        
        #(`FULL_CYCLE_DELAY) test_input_1       = {{(TEST_INDEX_3){1'b0}}, {(VECTOR_LENGTH - TEST_INDEX_3){1'b1}}};
        #(`FULL_CYCLE_DELAY) test_judge         = test_judge | (TEST_INDEX_3 -1 == first_one_index);
        #(`FULL_CYCLE_DELAY) vector_input       = test_input_1;
       
        $display("[info-testbench] test case %d %40s : \t%s", test_case_num, "basic access", test_judge ? "passed" : "failed");

    
        #3000   $display("\n[info-rtl] simulation comes to the end\n");
        $finish;
    end
    
    always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

endmodule
