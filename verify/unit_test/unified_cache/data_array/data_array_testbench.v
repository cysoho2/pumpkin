`timescale 10ns/1ns
`include "parameters.h"

module data_array_testbench();

parameter CACHE_BLOCK_SIZE_IN_BITS      = 64;
parameter NUMBER_SETS                   = 64;
parameter NUMBER_WAYS                   = 16;
parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUMBER_SETS);

integer                                         test_case_num;
reg     [CACHE_BLOCK_SIZE_IN_BITS - 1 : 0]      test_input_1;
reg     [CACHE_BLOCK_SIZE_IN_BITS - 1 : 0]      test_result_1;
reg     [CACHE_BLOCK_SIZE_IN_BITS - 1 : 0]      test_result_2;
reg                                             test_judge;

reg     clk_in;
reg     reset_in;
reg     access_en_in;
reg     write_en_in;

reg     [SET_PTR_WIDTH_IN_BITS       - 1 : 0] access_set_addr_in;
reg     [NUMBER_WAYS                 - 1 : 0] way_select_in;

reg     [CACHE_BLOCK_SIZE_IN_BITS - 1 : 0] write_data_in;
wire    [CACHE_BLOCK_SIZE_IN_BITS - 1 : 0] read_data_out;

initial
begin  
        $display("\n[info-testbench] simulation for %m begins now\n");
        clk_in                  = 0;
        reset_in                = 0;

        test_case_num           = 0;
        test_input_1            = 0;

        access_en_in            = 0;
        write_en_in             = 0;
        access_set_addr_in      = 0;
        way_select_in           = {(NUMBER_WAYS){1'b0}};
        write_data_in           = 0;

        test_result_1           = 0;
        test_result_2           = 0;
        test_judge              = 0;

        #5 reset_in             = 1;
        #5 reset_in             = 0;
        #10 $display("[info-testbench] %m testbench reset completed\n");
     
        test_case_num           = test_case_num + 1;
        test_input_1            = { {(CACHE_BLOCK_SIZE_IN_BITS/2){1'b1}}, {(CACHE_BLOCK_SIZE_IN_BITS/2){1'b0}} };

        access_en_in            = 1;
        write_en_in             = 1;
        access_set_addr_in      = NUMBER_SETS - 1;
        way_select_in           = {(NUMBER_WAYS){1'b1}};
        write_data_in           = test_input_1;

        #1 write_en_in          = 0;
        
        test_result_1           = read_data_out;
        test_result_2           = 0;
        test_judge              = (test_result_1 === test_input_1) && (test_result_1 !== {(CACHE_BLOCK_SIZE_IN_BITS){1'bx}});

        $display("[info-testbench] No.%3d test (basic write-read access) %s\n", test_case_num, test_judge ? "pass" : "fail");

        #3000 $display("[info-testbench] simulation for %m comes to the end\n");
        $finish;
end

always begin #1 clk_in <= ~clk_in; end

data_array
#(
        .CACHE_BLOCK_SIZE_IN_BITS       (CACHE_BLOCK_SIZE_IN_BITS),
        .NUMBER_SETS                    (NUMBER_SETS),
        .NUMBER_WAYS                    (NUMBER_WAYS),
        .SET_PTR_WIDTH_IN_BITS          (SET_PTR_WIDTH_IN_BITS)
)
data_array
(
        .clk_in(clk_in),
        .reset_in(reset_in),

        .access_en_in(access_en_in),
        .write_en_in(write_en_in),
        .access_set_addr_in(access_set_addr_in),
        .way_select_in(way_select_in),

        .write_data_in(write_data_in),
        .read_data_out(read_data_out)
);

endmodule