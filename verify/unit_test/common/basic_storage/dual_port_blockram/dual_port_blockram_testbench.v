`include "parameters.h"

module dual_port_blockram_testbench();

parameter SINGLE_ENTRY_WIDTH_IN_BITS    = 64;
parameter NUM_SET                       = 64;
parameter SET_PTR_WIDTH_IN_BITS         = $clog2(NUM_SET);
parameter WRITE_MASK_LEN                = SINGLE_ENTRY_WIDTH_IN_BITS / `BYTE_LEN_IN_BITS;
parameter CONFIG_MODE                   = "WriteFirst"; /* option: ReadFirst, WriteFirst*/

reg                                             reset_in;
reg                                             clk_in;

reg                                             write_port_access_en_in;
reg     [WRITE_MASK_LEN             - 1 : 0]    write_port_write_en_in;
reg     [SET_PTR_WIDTH_IN_BITS      - 1 : 0]    write_port_access_set_addr_in;
reg     [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]    write_port_data_in;

reg                                             read_port_access_en_in;
reg     [SET_PTR_WIDTH_IN_BITS      - 1 : 0]    read_port_access_set_addr_in;
wire    [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]    read_port_data_out;
wire                                            read_port_valid_out;

reg     [3:0]                                   test_case_num;
reg     [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]    test_input;
reg     [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]    test_result;
reg                                             test_judge;

dual_port_blockram
#(
    .SINGLE_ENTRY_WIDTH_IN_BITS         (SINGLE_ENTRY_WIDTH_IN_BITS),
    .NUM_SET                            (NUM_SET),
    .SET_PTR_WIDTH_IN_BITS              (SET_PTR_WIDTH_IN_BITS),
    .CONFIG_MODE                        (CONFIG_MODE)
)
dual_port_blockram
(
    .clk_in                             (clk_in),
    .reset_in                           (reset_in),

    .write_port_access_en_in            (write_port_access_en_in),
    .write_port_write_en_in             (write_port_write_en_in),
    .write_port_access_set_addr_in      (write_port_access_set_addr_in),
    .write_port_data_in                 (write_port_data_in),

    .read_port_access_en_in             (read_port_access_en_in),
    .read_port_access_set_addr_in       (read_port_access_set_addr_in),
    .read_port_data_out                 (read_port_data_out),
    .read_port_valid_out                (read_port_valid_out)
);

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

    clk_in                          = 0;
    reset_in                        = 1;

    write_port_access_en_in         = 0;
    write_port_write_en_in          = {(WRITE_MASK_LEN){1'b0}};;
    write_port_access_set_addr_in   = 0;
    write_port_data_in              = 0;

    read_port_access_en_in          = 0;
    read_port_access_set_addr_in    = 0;

    test_case_num                   = 0;
    test_input                      = 0;
    test_result                     = 0;
    test_judge                      = 0;

    #(`FULL_CYCLE_DELAY) reset_in   = 0;
    $display("[info-testbench] %m testbench reset completed");

    /**
     *  write "test_input" to write_port then read from read_port
     *  pass : the read data should be equal to the written data
     **/

    #(`FULL_CYCLE_DELAY * 200)
    test_input                          = {{(SINGLE_ENTRY_WIDTH_IN_BITS/`BYTE_LEN_IN_BITS){8'hff}}};

    #(`FULL_CYCLE_DELAY)
    write_port_access_en_in             = 1;
    write_port_write_en_in              = {(WRITE_MASK_LEN/2){2'b01}};
    write_port_access_set_addr_in       = NUM_SET - 1;
    write_port_data_in                  = test_input;

    #(`FULL_CYCLE_DELAY)
    write_port_access_en_in             = 0;
    write_port_write_en_in              = {(WRITE_MASK_LEN){1'b0}};
    write_port_access_set_addr_in       = 0;
    write_port_data_in                  = 0;
    read_port_access_en_in              = 1;
    read_port_access_set_addr_in        = NUM_SET - 1;

    #(`FULL_CYCLE_DELAY) test_result    = read_port_data_out;

    test_judge                          = (test_result === {{(SINGLE_ENTRY_WIDTH_IN_BITS/`BYTE_LEN_IN_BITS/2){16'h00_ff}}} ||
                                           test_result === {{(SINGLE_ENTRY_WIDTH_IN_BITS/`BYTE_LEN_IN_BITS/2){16'hxx_ff}}}) &&
                                          (test_result !== {(SINGLE_ENTRY_WIDTH_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %80s : \t%s", test_case_num, "basic write-read access", test_judge ? "passed" : "failed");

    #(`FULL_CYCLE_DELAY) test_case_num  = test_case_num + 1;
    test_judge                          = read_port_valid_out === 1'b1 && read_port_valid_out !== 1'bx;
    $display("[info-testbench] test case %d %80s : \t%s", test_case_num, "basic valid access", test_judge ? "passed" : "failed");

    read_port_access_en_in              = 0;
    read_port_access_set_addr_in        = 0;

    #(`FULL_CYCLE_DELAY)
    test_case_num                       = test_case_num + 1;
    read_port_access_en_in              = 1;
    read_port_access_set_addr_in        = 1;
    #(`FULL_CYCLE_DELAY) 
    test_judge                          = read_port_valid_out === 1'b0 && read_port_valid_out !== 1'bx;
    $display("[info-testbench] test case %d %80s : \t%s", test_case_num, "basic invalid access", test_judge ? "passed" : "failed");

    /**
     *  write "test_input" to write_port, read from read_port, with the different address
     *  pass : the data is read should equal the data is written
     **/

    #(`FULL_CYCLE_DELAY) test_case_num  = test_case_num + 1;
    
    test_input                          = {{(SINGLE_ENTRY_WIDTH_IN_BITS/`BYTE_LEN_IN_BITS){8'hf0}}};

    write_port_access_en_in             = 1;
    write_port_write_en_in              = {(WRITE_MASK_LEN){1'b1}};
    write_port_access_set_addr_in       = 1;
    write_port_data_in                  = test_input;

    read_port_access_en_in              = 1;
    read_port_access_set_addr_in        = NUM_SET - 1;

    #(`FULL_CYCLE_DELAY)
    read_port_access_en_in              = 0;
    read_port_access_set_addr_in        = 0;

    test_result                         = read_port_data_out;
    test_judge                          = (test_result === {{(SINGLE_ENTRY_WIDTH_IN_BITS/`BYTE_LEN_IN_BITS/2){16'h00_ff}}} ||
                                           test_result === {{(SINGLE_ENTRY_WIDTH_IN_BITS/`BYTE_LEN_IN_BITS/2){16'hxx_ff}}}) &&
                                          (test_result !== {(SINGLE_ENTRY_WIDTH_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %80s : \t%s", test_case_num, "concurrent access - phase 1", test_judge ? "passed" : "failed");

    #(`FULL_CYCLE_DELAY) test_case_num      = test_case_num + 1;
    read_port_access_en_in              = 1;
    read_port_access_set_addr_in        = 1;

    #(`FULL_CYCLE_DELAY)
    test_result                         = read_port_data_out;
    test_judge                          = (test_result === test_input & read_port_valid_out === 1'b1) &&
                                          (test_result !== {(SINGLE_ENTRY_WIDTH_IN_BITS){1'bx}});

    $display("[info-testbench] test case %d %80s : \t%s", test_case_num, "concurrent access - phase 2", test_judge ? "passed" : "failed");

    #(`FULL_CYCLE_DELAY * 300) $display("[info-testbench] simulation for %m comes to the end\n");
    $finish;
end

always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

endmodule
