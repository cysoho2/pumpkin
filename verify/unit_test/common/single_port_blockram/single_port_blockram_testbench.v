`timescale 10ns/1ns
`include "parameters.h"

module single_port_blockram_testbench();

parameter SINGLE_ELEMENT_SIZE_IN_BITS   = 64;
parameter NUMBER_SETS                   = 64;
parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUMBER_SETS);

integer                                         test_case_num;
reg     [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0]   test_input_1;
reg     [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0]   test_result_1;
reg     [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0]   test_result_2;
reg                                             test_judge;

reg     clk_in;
reg     access_en_in;
reg     write_en_in;

reg     [SET_PTR_WIDTH_IN_BITS       - 1 : 0]   access_set_addr_in;

reg     [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0]   write_element_in;
wire    [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0]   read_element_out;

initial
begin  
        $display("\n[info-testbench] simulation for %m begins now");
        clk_in                  = 0;

        test_case_num           = 0;
        test_input_1            = 0;

        access_en_in            = 0;
        write_en_in             = 0;
        access_set_addr_in      = 0;
        write_element_in        = 0;

        test_result_1           = 0;
        test_result_2           = 0;
        test_judge              = 0;

        $display("[info-testbench] %m testbench reset completed\n");
     
        #1 test_case_num        = test_case_num + 1;
        test_input_1            = { {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}}, {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b0}} };

        access_en_in            = 1;
        write_en_in             = 1;
        access_set_addr_in      = NUMBER_SETS - 1;
        write_element_in        = test_input_1;

        #2 write_en_in          = 0;
        
        #2 test_result_1        = read_element_out;
        test_result_2           = 0;
        test_judge              = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ELEMENT_SIZE_IN_BITS){1'bx}});

        $display("[info-testbench] No.%2d test (basic write-read access) %s", test_case_num, test_judge ? "pass" : "fail");

        #1 test_case_num        = test_case_num + 1;
        test_input_1            = { {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b0}}, {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}} };

        access_en_in            = 1;
        write_en_in             = 0;
        access_set_addr_in      = NUMBER_SETS - 1;
        write_element_in        = test_input_1;

        #2 write_en_in          = 0;
        
        #2 test_result_2        = read_element_out;
        test_judge              = (test_result_2 === test_result_1) && (test_result_2 !== {(SINGLE_ELEMENT_SIZE_IN_BITS){1'bx}});

        $display("[info-testbench] No.%2d test (write enable verify) %s", test_case_num, test_judge ? "pass" : "fail");

        #3000 $display("\n[info-testbench] simulation for %m comes to the end\n");
        $finish;
end

always begin #1 clk_in <= ~clk_in; end

single_port_blockram
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (SINGLE_ELEMENT_SIZE_IN_BITS),
        .NUMBER_SETS                    (NUMBER_SETS),
        .SET_PTR_WIDTH_IN_BITS          (SET_PTR_WIDTH_IN_BITS)
)
single_port_blockram
(
        .clk_in                         (clk_in),

        .access_en_in                   (access_en_in),
        .write_en_in                    (write_en_in),
        .access_set_addr_in             (access_set_addr_in),

        .write_element_in               (write_element_in),
        .read_element_out               (read_element_out)
);

endmodule