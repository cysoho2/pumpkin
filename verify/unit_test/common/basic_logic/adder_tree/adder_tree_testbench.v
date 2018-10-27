`include "sim_config.h"
`include "parameters.h"

module adder_tree_testbench();

reg                     clk_in;
reg                     reset_in;
reg [2 * 80 - 1 : 0]    operand_package_1_in;
reg [2 * 80 - 1 : 0]    operand_package_2_in;
wire [2 * 96 - 1 : 0]  result_package_out;



always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

initial
begin
    
    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, adder_tree_testbench);
    `endif
    
                                    $display("\n[info-testbench] simulation for %m begins now");
                                    
                                    clk_in                  = 1'b1;
                                    reset_in                = 1'b1;
     #(`FULL_CYCLE_DELAY * 50)                               
     #(`FULL_CYCLE_DELAY * 1.5)       operand_package_1_in    = {{(80){1'b0}}, {(80){1'b1}}};
                                    operand_package_2_in    = {{(80){1'b1}}, {(80){1'b0}}};
     
     #(`FULL_CYCLE_DELAY * 1)       reset_in                = 1'b0;
     #(`FULL_CYCLE_DELAY * 2)          operand_package_1_in    <= 0;
                                    operand_package_2_in    <= 0;
    

     #(`FULL_CYCLE_DELAY * 30)    $display("\n[info-testbench] simulation for %m comes to the end\n");
                                    $finish;

end

adder_tree
#(
    .NUM_ADDER(2),
    .OPERAND_RGHIT_SHIFT_IN_BITS(16),
    .OPERAND_WIDTH_IN_BITS(80),
    .RESULT_WIDTH_IN_BITS(96)
)
adder_tree
(
    .reset_in                       (reset_in),
    .clk_in                         (clk_in),
    
    .operand_package_1_in           (operand_package_1_in),
    .operand_package_2_in           (operand_package_2_in),
    
    .result_package_out             (result_package_out)                            
);

endmodule
