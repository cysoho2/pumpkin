`include "sim_config.h"
`include "parameters.h"

module multicycle_divider_testbench;

parameter OPERAND_WIDTH_IN_BITS                             = 64;

reg                                                         reset_in;
reg                                                         clk_in;
    
reg                                                         is_valid_in;
    
wire                                                        is_valid_out;
wire                                                        is_ready_out;
    
reg                                                         dividend_sign_in;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0]                         dividend_in;
    
reg                                                         divisor_sign_in;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0]                         divisor_in;
    
wire                                                        remainder_sign_out;
wire [OPERAND_WIDTH_IN_BITS - 1 : 0]                        remainder_out;
    
wire                                                        quotient_sign_out;
wire [OPERAND_WIDTH_IN_BITS - 1 : 0]                        quotient_out;


reg                                                         test_dividend_sign_in;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0]                         test_dividend_in;
    
reg                                                         test_divisor_sign_in;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0]                         test_divisor_in; 

initial
begin
    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, multicycle_divider_testbench);
    `endif

        $display("\n[info-testbench] simulation for %m begins now");
        //init
        reset_in                                            <= 1'b1;
        clk_in                                              <= 1'b0;
        is_valid_in                                         <= 1'b0;
        
        dividend_sign_in                                    <= 1'b0;
        divisor_sign_in                                     <= 1'b0;
        dividend_in                                         <= 0;
        divisor_in                                          <= 0;
        $display("[info-testbench] %m testbench reset completed");
        
        //case 0 : +7 / +2
        #(`FULL_CYCLE_DELAY * 2)   test_dividend_in         <= 7;
                                   test_divisor_in          <= 2;
                                   test_dividend_sign_in    <= 0;
                                   test_divisor_sign_in     <= 0;
                                   
        #(`FULL_CYCLE_DELAY * 2)   dividend_in              <= test_dividend_in;
                                   divisor_in               <= test_divisor_in;
                                   dividend_sign_in         <= test_dividend_sign_in;
                                   divisor_sign_in          <= test_divisor_sign_in;   
                                                        
        #(`FULL_CYCLE_DELAY * 2)   reset_in                 <= 1'b0;
                                   is_valid_in              <= 1'b1;
                                   
        #(`FULL_CYCLE_DELAY * 2)   is_valid_in              <= 1'b0;
                                  
        //case 1 : -7 / +2
        #(`FULL_CYCLE_DELAY * 300) dividend_sign_in         <= 1;
                                   divisor_sign_in          <= 0;   
                                                        
        #(`FULL_CYCLE_DELAY * 2)   is_valid_in              <= 1'b1;
        
        #(`FULL_CYCLE_DELAY * 2)   is_valid_in              <= 1'b0;
        
        
        //case 2 : +7 / -2
        #(`FULL_CYCLE_DELAY * 300) dividend_sign_in         <= 0;
                                   divisor_sign_in          <= 1;   
                                                        
        #(`FULL_CYCLE_DELAY * 2)   is_valid_in              <= 1'b1; 
        #(`FULL_CYCLE_DELAY * 2)   is_valid_in              <= 1'b0;
                
        //case 3 : -MAX / -MAX/2 - 1
        #(`FULL_CYCLE_DELAY * 300) dividend_sign_in         <= 1;
                                   divisor_sign_in          <= 1;
                                   dividend_in              <= {(OPERAND_WIDTH_IN_BITS){1'b1}};
                                   divisor_in               <= {{1'b0}, {(OPERAND_WIDTH_IN_BITS - 2){1'b1}}, {1'b0}};
                                                        
        #(`FULL_CYCLE_DELAY * 2)   is_valid_in              <= 1'b1;
        
        #(`FULL_CYCLE_DELAY * 2)   is_valid_in              <= 1'b0;       
        
        #(`FULL_CYCLE_DELAY * 300) $display("[info-testbench] simulation comes to the end\n");
                                   $finish;
end

always begin #`HALF_CYCLE_DELAY clk_in                      <= ~clk_in; end

multicycle_divider
#(
    .OPERAND_WIDTH_IN_BITS(OPERAND_WIDTH_IN_BITS)
)
multicycle_divider
(
    .reset_in                                               (reset_in),
    .clk_in                                                 (clk_in),
    
    .is_valid_in                                            (is_valid_in),
    
    .is_valid_out                                           (is_valid_out),
    .is_ready_out                                           (is_ready_out),
    
    .dividend_sign_in                                       (dividend_sign_in),
    .dividend_in                                            (dividend_in),
    
    .divisor_sign_in                                        (divisor_sign_in),
    .divisor_in                                             (divisor_in),
    
    .remainder_sign_out                                     (remainder_sign_out),
    .remainder_out                                          (remainder_out),
    
    .quotient_sign_out                                      (quotient_sign_out),
    .quotient_out                                           (quotient_out)
    
);

endmodule
