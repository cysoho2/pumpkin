`include "sim_config.h"
`include "parameters.h"

module fast_multiplication_testbench;

    parameter OPERAND_WIDTH_IN_BITS  = 64;
    parameter PRODUCT_WIDTH_IN_BITS = 128;

    reg                                           reset_in;
    reg                                           clk_in;
    
    wire                                      is_ready_out;
    wire                                           is_valid_out;
    reg                                           is_valid_in;

    reg                                           multiplier_sign_bit_in;
    reg       [OPERAND_WIDTH_IN_BITS - 1 : 0]     multiplier_in;
    
    reg                                           multicand_sign_bit_in;
    reg       [OPERAND_WIDTH_IN_BITS - 1 : 0]     multicand_in;
    
    wire                                      product_sign_bit_out;
    wire  [PRODUCT_WIDTH_IN_BITS - 1 : 0]     product_out; 

initial
begin
    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, fast_multiplication_testbench);
    `endif

        $display("\n[info-testbench] simulation for %m begins now");

        clk_in                                                          <= 1'b0;
        reset_in                                                        <= 1'b1;

        $display("[info-testbench] %m testbench reset completed");
        
        #(`FULL_CYCLE_DELAY * 50) 
        
        
        #(`FULL_CYCLE_DELAY * 1.5)    is_valid_in = 1'b1;
                                multiplier_in = 7;
                                multicand_in = 2;
        #(`FULL_CYCLE_DELAY)    reset_in = 1'b0;
        #(`FULL_CYCLE_DELAY)    multiplier_in = 69;
                                multicand_in = 98;

        #(`FULL_CYCLE_DELAY)    multiplier_in = 123;
                                multicand_in = 123;
                               
        #(`FULL_CYCLE_DELAY * 2)    multiplier_in = 255;
                                multicand_in = 98;
                                
        #(`FULL_CYCLE_DELAY)    multiplier_in = 999;
                                multicand_in = 989;
                                
/*        #(`FULL_CYCLE_DELAY)    multiplier_in = {(OPERAND_WIDTH_IN_BITS){1'b1}};
                                multicand_in = {(OPERAND_WIDTH_IN_BITS){1'b1}}; */
        
        #(`FULL_CYCLE_DELAY * 300) $display("[info-testbench] simulation comes to the end\n");
                                   $finish;
end


always begin #`HALF_CYCLE_DELAY clk_in                                  <= ~clk_in; end

fast_multiplication
#(
    .OPERAND_WIDTH_IN_BITS(OPERAND_WIDTH_IN_BITS),
    .PRODUCT_WIDTH_IN_BITS(PRODUCT_WIDTH_IN_BITS) 
)
fast_multiplication
(
    .reset_in(reset_in),
    .clk_in(clk_in),
    
    .is_ready_out(is_ready_out),
    .is_valid_out(is_valid_out),
    .is_valid_in(is_valid_in),

    .multiplier_sign_bit_in(multiplier_sign_bit_in),
    .multiplier_in(multiplier_in),
    
    .multicand_sign_bit_in(multicand_sign_bit_in),
    .multicand_in(multicand_in),
    
    .product_sign_bit_out(product_sign_bit_out),
    .product_out(product_out)
);

endmodule
