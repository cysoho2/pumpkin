`include "parameters.h"
`include "sim_config.h"

module single_port_blockram_testbench();

parameter SINGLE_ENTRY_SIZE_IN_BITS     = 64;
parameter NUM_SET                       = 64;
parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUM_SET);

integer                                         test_case_num;
reg     [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     test_input_1;
reg     [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     test_result_1;
reg     [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     test_result_2;
reg                                             test_judge;

reg     clk_in;
reg     access_en_in;
reg     write_en_in;

reg     [SET_PTR_WIDTH_IN_BITS     - 1 : 0]     access_set_addr_in;

reg     [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     write_entry_in;
wire    [SINGLE_ENTRY_SIZE_IN_BITS - 1 : 0]     read_entry_out;

initial
begin
    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, single_port_blockram_testbench);
    `endif

    $display("\n[info-testbench] simulation for %m begins now");
    clk_in                                      = 0;

    test_case_num                               = 0;
    test_input_1                                = 0;

    access_en_in                                = 0;
    write_en_in                                 = 0;
    access_set_addr_in                          = 0;
    write_entry_in                              = 0;

    test_result_1                               = 0;
    test_result_2                               = 0;
    test_judge                                  = 0;

    $display("[info-testbench] %m testbench reset completed\n");

    test_input_1                                = { {(SINGLE_ENTRY_SIZE_IN_BITS/2){1'b1}}, {(SINGLE_ENTRY_SIZE_IN_BITS/2){1'b0}} };

    access_en_in                                = 1;
    write_en_in                                 = 1;
    #(`FULL_CYCLE_DELAY) write_entry_in         = test_input_1;
    #(`FULL_CYCLE_DELAY) access_set_addr_in     = NUM_SET - 1;

    #(`FULL_CYCLE_DELAY) write_en_in            = 0;

    #(`FULL_CYCLE_DELAY * 2) test_result_1      = read_entry_out;
    test_result_2                               = 0;
    test_judge                                  = (test_result_1 === test_input_1) && (test_result_1 !== {(SINGLE_ENTRY_SIZE_IN_BITS){1'bx}});


    $display("[info-testbench] test case %d %40s : \t%s", test_case_num, "basic write-read access", test_judge ? "passed" : "failed");


    #(`HALF_CYCLE_DELAY) test_case_num          = test_case_num + 1;
    test_input_1                                = { {(SINGLE_ENTRY_SIZE_IN_BITS/2){1'b0}}, {(SINGLE_ENTRY_SIZE_IN_BITS/2){1'b1}} };

    access_en_in                                = 1;
    write_en_in                                 = 0;
    access_set_addr_in                          = NUM_SET - 1;
    write_entry_in                              = test_input_1;

    #(`FULL_CYCLE_DELAY) write_en_in            = 0;

    #(`FULL_CYCLE_DELAY) test_result_2          = read_entry_out;
    test_judge                                  = (test_result_2 === test_result_1) && (test_result_2 !== {(SINGLE_ENTRY_SIZE_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %40s : \t%s", test_case_num, "write enable verify", test_judge ? "passed" : "failed");

    #(`FULL_CYCLE_DELAY * 1500) $display("\n[info-testbench] simulation for %m comes to the end\n");
    $finish;
end

always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

single_port_blockram
#(
    .SINGLE_ENTRY_SIZE_IN_BITS      (SINGLE_ENTRY_SIZE_IN_BITS),
    .NUM_SET                        (NUM_SET),
    .SET_PTR_WIDTH_IN_BITS          (SET_PTR_WIDTH_IN_BITS)
)
single_port_blockram
(
    .clk_in                         (clk_in),

    .access_en_in                   (access_en_in),
    .write_en_in                    (write_en_in),
    .access_set_addr_in             (access_set_addr_in),

    .write_entry_in                 (write_entry_in),
    .read_entry_out                 (read_entry_out)
);

endmodule