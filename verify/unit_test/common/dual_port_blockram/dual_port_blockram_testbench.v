`timescale 10ns/1ns
`include "parameters.h"

module dual_port_blockram_testbench();

parameter SINGLE_ELEMENT_SIZE_IN_BITS = 64;
parameter NUMBER_SETS                 = 64;
parameter SET_PTR_WIDTH_IN_BITS       = 6;

reg                                        reset_in;
reg                                        clk_in;
    
reg                                        read_en_in;
reg  [SET_PTR_WIDTH_IN_BITS       - 1 : 0] read_set_addr_in;
wire [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] read_element_out;

reg                                        write_en_in;
reg  [SET_PTR_WIDTH_IN_BITS       - 1 : 0] write_set_addr_in;
reg  [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] write_element_in;
wire [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] evict_element_out;

reg  [2:0]                                 test_case_num;
reg  [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] test_input_1;
reg  [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] test_input_2;
reg  [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] test_result_1;
reg  [SINGLE_ELEMENT_SIZE_IN_BITS - 1 : 0] test_result_2;
reg                                        test_judge;

initial
begin
    $display("\n[info-testbench] simulation for %m begins now");
    
    /**
     *  reset
     **/
    
    clk_in                  = 0;

    test_case_num           = 0;
    test_input_1            = 0;

    write_en_in             = 0;
    write_set_addr_in       = 0;
    write_element_in        = 0;

    read_en_in              = 0;
    read_set_addr_in        = 0;

    test_result_1           = 0;
    test_result_2           = 0;
    test_judge              = 0;

    $display("[info-testbench] %m testbench reset completed\n");

    /**
     *  write "test_input_1" to "write_set_addr_in" then read from "write_set_addr_in" 
     *  pass : the data is read should equal the data is written 
     **/

    #1 test_case_num        = test_case_num + 1;
    test_input_1            = { {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}}, {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b0}} };

    read_en_in              = 1;
    write_en_in             = 1;

    #2 write_set_addr_in    = NUMBER_SETS - test_case_num;
    read_set_addr_in        = NUMBER_SETS - test_case_num;
    
    write_element_in        = test_input_1;
    #20 test_result_1       = read_element_out;
    
    write_en_in             = 0;
    read_en_in              = 0;
    
    test_judge              = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ELEMENT_SIZE_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %40s : \t%s", test_case_num, "basic asynchronous write-read access",test_judge ? "pass" : "fail");

    /**
     *  write "test_input_1" to "write_set_addr_in" and read from "write_set_addr_in" simultaneously
     *  pass : the data is read should equal the data is written  
     **/
 
    #10 test_case_num       = test_case_num + 1;
    test_input_1            = { {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}}, {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}} };
    
    read_en_in              = 1;
    write_en_in             = 1;

    #2 write_set_addr_in    = NUMBER_SETS - test_case_num;
    read_set_addr_in        = NUMBER_SETS - test_case_num;
    
    write_element_in        = test_input_1;
    #20 test_result_1       = read_element_out;
    
    write_en_in             = 0;
    read_en_in              = 0;
         
    test_judge              = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ELEMENT_SIZE_IN_BITS){1'bx}});
         
    $display("[info-testbench] test case %d %40s : \t%s", test_case_num, "basic simultaneous write-read access", test_judge ? "pass" : "fail");

    /**
     *  write "test_input_2" to "write_set_addr_in"
     *  pass : evicted data should equal the value in "test_input_1"
     **/
    
    #10 test_case_num       = test_case_num + 1;
    test_input_1            = { {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b0}}, {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}} };
    test_input_2            = { {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}}, {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b0}} };
    
    read_en_in              = 1;
    write_en_in             = 1;
    
    #2 write_set_addr_in    = NUMBER_SETS - test_case_num;
    read_set_addr_in        = NUMBER_SETS - test_case_num;
    
    write_element_in        = test_input_1;
    
    #10 write_en_in          = 0;
    #2 write_en_in          = 1;
    
    write_element_in        = test_input_2;
    #10 test_result_1        = evict_element_out;

    
    #2 read_en_in           = 0;
    write_en_in             = 0;

    test_judge              = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ELEMENT_SIZE_IN_BITS){1'bx}});
    
    $display("[info-testbench] test case %d %40s : \t%s", test_case_num, "evict access", test_judge ? "pass" : "fail");
 
    /**
     *  set "write_en_in" to zero then write new data
     *  pass : RAM should be read the old data 
     **/
 
    #2 test_case_num        = test_case_num + 1;
    
    test_input_1            = { {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b0}}, {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}} };
    test_input_2            = { {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b1}}, {(SINGLE_ELEMENT_SIZE_IN_BITS/2){1'b0}} };
    
    read_en_in              = 1;
    write_en_in             = 1;
    
    #2 write_set_addr_in    = NUMBER_SETS - test_case_num;
    read_set_addr_in        = NUMBER_SETS - test_case_num;
    
    write_element_in        = test_input_1;

    #10 write_en_in          = 0;
    write_element_in        = test_input_2;
    #2 write_en_in          = 0;

    #2 test_result_1        = read_element_out;
    
    #2 read_en_in           = 0;
    write_en_in             = 0;
    
    test_judge              = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ELEMENT_SIZE_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %40s : \t%s", test_case_num, "write enable verify", test_judge ? "pass" : "fail");

    #3000 $display("\n[info-testbench] simulation for %m comes to the end\n");
    $finish;
end

always begin #1 clk_in <= ~clk_in; end

dual_port_blockram
#(
        .SINGLE_ELEMENT_SIZE_IN_BITS    (SINGLE_ELEMENT_SIZE_IN_BITS),
        .NUMBER_SETS                    (NUMBER_SETS),
        .SET_PTR_WIDTH_IN_BITS          (SET_PTR_WIDTH_IN_BITS)
)

dual_port_blockram
(
        .clk_in                         (clk_in),
    
        .read_en_in                     (read_en_in),
        .read_set_addr_in               (read_set_addr_in),
        .read_element_out               (read_element_out),

        .write_en_in                    (write_en_in),
        .write_set_addr_in              (write_set_addr_in),
        .write_element_in               (write_element_in),
        .evict_element_out              (evict_element_out)
);

endmodule
