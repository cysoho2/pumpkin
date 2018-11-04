`include "parameters.h"

module dual_port_blockram_testbench();

parameter SINGLE_ENTRY_SIZE_IN_BITS     = 64;
parameter NUM_SET                       = 64;
parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUM_SET);
parameter WRITE_MASK_LEN                = SINGLE_ENTRY_SIZE_IN_BITS / `BYTE_LEN_IN_BITS;

reg                                             reset_in;
reg                                             clk_in;

reg                                             port_A_access_en_in;
reg     [WRITE_MASK_LEN            - 1 : 0]     port_A_write_en_in;
reg     [SET_PTR_WIDTH_IN_BITS     - 1 : 0]     port_A_access_set_addr_in;
reg     [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     port_A_write_entry_in;
wire    [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     port_A_read_entry_out;
wire                                            port_A_read_valid_out;

reg                                             port_B_access_en_in;
reg     [WRITE_MASK_LEN            - 1 : 0]     port_B_write_en_in;
reg     [SET_PTR_WIDTH_IN_BITS     - 1 : 0]     port_B_access_set_addr_in;
reg     [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     port_B_write_entry_in;
wire    [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     port_B_read_entry_out;
wire                                            port_B_read_valid_out;

reg  [3:0]                                      test_case_num;
reg  [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]        test_input_1;
reg  [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]        test_input_2;
reg  [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]        test_result_1;
reg  [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]        test_result_2;
reg                                             test_judge;

initial
begin

    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, dual_port_blockram_testbench);
    `endif

    $display("\n[info-testbench] simulation for %m begins now");

    /**
     *  reset
     **/

    clk_in                      = 0;
    reset_in                    = 1;

    port_A_access_en_in         = 0;
    port_A_write_en_in          = {(WRITE_MASK_LEN){1'b0}};;
    port_A_access_set_addr_in   = 0;
    port_A_write_entry_in       = 0;

    port_B_access_en_in         = 0;
    port_B_write_en_in          = {(WRITE_MASK_LEN){1'b0}};;
    port_B_access_set_addr_in   = 0;
    port_B_write_entry_in       = 0;

    test_case_num               = 0;
    test_input_1                = 0;

    test_result_1               = 0;
    test_result_2               = 0;
    test_judge                  = 0;

    #(`FULL_CYCLE_DELAY) reset_in = 0;
    $display("[info-testbench] %m testbench reset completed\n");

    /**
     *  write "test_input_1" to Port-A then read from Port-A
     *  pass : the read data should be equal to the written data
     **/

    #(`FULL_CYCLE_DELAY)
    test_input_1                            = {{(SINGLE_ENTRY_SIZE_IN_BITS/2){2'b10}}};

    #(`FULL_CYCLE_DELAY)
    
    port_A_access_en_in                     = 1;
    port_A_write_en_in                      = {(WRITE_MASK_LEN){1'b1}};
    port_A_access_set_addr_in               = NUM_SET - 1;
    port_A_write_entry_in                   = test_input_1;

    #(`FULL_CYCLE_DELAY * 2)
    
    port_A_access_en_in                     = 1;
    port_A_write_en_in                      = {(WRITE_MASK_LEN){1'b0}};
    port_A_access_set_addr_in               = NUM_SET - 1;
    port_A_write_entry_in                   = 0;

    #(`FULL_CYCLE_DELAY * 2) test_result_1      = port_A_read_entry_out;

    test_judge                              = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ENTRY_SIZE_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %60s : \t%s", test_case_num, "basic write-read access - to Port A", test_judge ? "passed" : "failed");

    #(`FULL_CYCLE_DELAY) test_case_num      = test_case_num + 1;
    test_judge                              = port_A_read_valid_out === 1'b1 && port_A_read_valid_out !== 1'bx;
    $display("[info-testbench] test case %d %60s : \t%s", test_case_num, "basic write-read access - get valid", test_judge ? "passed" : "failed");
    
    port_A_access_en_in         = 0;
    port_A_write_en_in          = {(WRITE_MASK_LEN){1'b0}};;
    port_A_access_set_addr_in   = 0;
    port_A_write_entry_in       = 0;

    /**
     *  write "test_input_1" to Port-B then read from Port-B
     *  pass : the read data should be equal to the written data
     **/

    #(`FULL_CYCLE_DELAY) test_case_num      = test_case_num + 1;
    test_input_1                            = {{(SINGLE_ENTRY_SIZE_IN_BITS/2){2'b10}}};

    #(`FULL_CYCLE_DELAY)
    
    port_B_access_en_in                     = 1;
    port_B_write_en_in                      = {(WRITE_MASK_LEN){1'b1}};
    port_B_access_set_addr_in               = 1;
    port_B_write_entry_in                   = test_input_1;

    #(`FULL_CYCLE_DELAY)
    port_B_access_en_in                     = 0;
    port_B_write_en_in                      = {(WRITE_MASK_LEN){1'b0}};;
    port_B_access_set_addr_in               = 0;
    port_B_write_entry_in                   = 0;

    #(`FULL_CYCLE_DELAY)
    
    port_B_access_en_in                     = 1;
    port_B_write_en_in                      = {(WRITE_MASK_LEN){1'b0}};
    port_B_access_set_addr_in               = 1;
    port_B_write_entry_in                   = 0;

    #(`FULL_CYCLE_DELAY) test_result_1      = port_B_read_entry_out;

    test_judge                              = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ENTRY_SIZE_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %60s : \t%s", test_case_num, "basic write-read access - to Port B", test_judge ? "passed" : "failed");
    
    #(`FULL_CYCLE_DELAY) test_case_num      = test_case_num + 1;
    test_judge                              = port_B_read_valid_out === 1'b1 && port_B_read_valid_out !== 1'bx;
    $display("[info-testbench] test case %d %60s : \t%s", test_case_num, "basic write-read access - get valid", test_judge ? "passed" : "failed");
    
    port_B_access_en_in         = 0;
    port_B_write_en_in          = {(WRITE_MASK_LEN){1'b0}};;
    port_B_access_set_addr_in   = 0;
    port_B_write_entry_in       = 0;

    /**
     *  write "test_input_1" to Port_A and read from Port-B simultaneously, with different address
     *  pass : the data is read should equal the data is written
     **/

    #(`FULL_CYCLE_DELAY)
    port_A_access_en_in                     = 0;
    port_A_write_en_in                      = {(WRITE_MASK_LEN){1'b0}};
    port_A_access_set_addr_in               = 0;
    port_A_write_entry_in                   = 0;
    port_B_access_en_in                     = 0;
    port_B_write_en_in                      = {(WRITE_MASK_LEN){1'b0}};
    port_B_access_set_addr_in               = 0;
    port_B_write_entry_in                   = 0;

    #(`FULL_CYCLE_DELAY * 3) test_case_num  = test_case_num + 1;
    #(`FULL_CYCLE_DELAY)     test_input_2   = { {(SINGLE_ENTRY_SIZE_IN_BITS/2){1'b1}}, {(SINGLE_ENTRY_SIZE_IN_BITS/2){1'b1}} };

    port_A_access_en_in                     = 1;
    port_A_write_en_in                      = {(WRITE_MASK_LEN){1'b1}};
    port_A_access_set_addr_in               = test_case_num;
    port_A_write_entry_in                   = test_input_2;
    port_B_access_en_in                     = 1;
    port_B_write_en_in                      = {(WRITE_MASK_LEN){1'b0}};
    port_B_access_set_addr_in               = NUM_SET - 1;
    port_B_write_entry_in                   = 0;

    #(`FULL_CYCLE_DELAY) test_result_1      = port_B_read_entry_out;
    test_judge                              = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ENTRY_SIZE_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %60s : \t%s", test_case_num, "basic simultaneous write-read access - read data", test_judge ? "passed" : "failed");

    #(`FULL_CYCLE_DELAY)
    port_A_access_en_in                     = 1;
    port_A_write_en_in                      = {(WRITE_MASK_LEN){1'b0}};
    port_A_access_set_addr_in               = test_case_num;
    port_A_write_entry_in                   = 0;

    #(`FULL_CYCLE_DELAY) test_case_num      = test_case_num + 1;
    test_result_2                           = port_A_read_entry_out;
    test_judge                              = (test_result_2 === test_input_2) && (test_result_2 !== {(SINGLE_ENTRY_SIZE_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %60s : \t%s", test_case_num, "basic simultaneous write-read access - write data", test_judge ? "passed" : "failed");

    #(`FULL_CYCLE_DELAY) test_result_2      = test_judge;

    /**
     *  set "write_en_in" to zero then write new data
     *  pass : RAM should be reading the old data
     **/

    #(`FULL_CYCLE_DELAY * 300) $display("\n[info-testbench] simulation for %m comes to the end\n");
    $finish;
end

always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

dual_port_blockram
#(
    .SINGLE_ENTRY_SIZE_IN_BITS      (SINGLE_ENTRY_SIZE_IN_BITS),
    .NUM_SET                        (NUM_SET),
    .SET_PTR_WIDTH_IN_BITS          (SET_PTR_WIDTH_IN_BITS)
)
dual_port_blockram
(
    .clk_in                         (clk_in),
    .reset_in                       (reset_in),

    .port_A_access_en_in            (port_A_access_en_in),
    .port_A_write_en_in             (port_A_write_en_in),
    .port_A_access_set_addr_in      (port_A_access_set_addr_in),
    .port_A_write_entry_in          (port_A_write_entry_in),
    .port_A_read_entry_out          (port_A_read_entry_out),
    .port_A_read_valid_out          (port_A_read_valid_out),

    .port_B_access_en_in            (port_B_access_en_in),
    .port_B_write_en_in             (port_B_write_en_in),
    .port_B_access_set_addr_in      (port_B_access_set_addr_in),
    .port_B_write_entry_in          (port_B_write_entry_in),
    .port_B_read_entry_out          (port_B_read_entry_out),
    .port_B_read_valid_out          (port_B_read_valid_out)
);

endmodule
