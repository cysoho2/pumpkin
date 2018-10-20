module adder_tree
#(
    parameter NUM_ADDER                                                     = 1,
    parameter OPERAND_RGHIT_SHIFT_IN_BITS                                   = 0,
    parameter OPERAND_WIDTH_IN_BITS                                         = 64,
    parameter RESULT_WIDTH_IN_BITS                                          = 64
)
(
    input                                                                   reset_in,
    input                                                                   clk_in,
    
    input          [OPERAND_WIDTH_IN_BITS * NUM_ADDER - 1 : 0]              operand_package_1_in,
    input          [OPERAND_WIDTH_IN_BITS * NUM_ADDER - 1 : 0]              operand_package_2_in,
    
    output reg     [RESULT_WIDTH_IN_BITS * NUM_ADDER - 1 : 0]               result_package_out                            
);


parameter [31 : 0] OPERAND_PACKAGE_SIZE                                     = OPERAND_WIDTH_IN_BITS * NUM_ADDER;
parameter [31 : 0] RESULT_PACKAGE_SIZE                                      = RESULT_WIDTH_IN_BITS * NUM_ADDER;

genvar gen;
generate

    for (gen = 0; gen < NUM_ADDER; gen = gen + 1)
    begin
    
        wire [RESULT_WIDTH_IN_BITS - 1 : 0]     gen_operand_1;
        wire [RESULT_WIDTH_IN_BITS - 1 : 0]     gen_operand_2;
        
        wire [RESULT_WIDTH_IN_BITS - 1 : 0]     gen_result; 
    
        assign gen_operand_1 = 
            {{operand_package_1_in[OPERAND_PACKAGE_SIZE - gen * OPERAND_WIDTH_IN_BITS - 1 : OPERAND_PACKAGE_SIZE - (gen+ 1) * OPERAND_WIDTH_IN_BITS]}, {(OPERAND_RGHIT_SHIFT_IN_BITS){1'b0}}};
        assign gen_operand_2 =
            {{(RESULT_WIDTH_IN_BITS - OPERAND_WIDTH_IN_BITS){1'b0}}, {operand_package_2_in[OPERAND_PACKAGE_SIZE - gen * OPERAND_WIDTH_IN_BITS - 1 : OPERAND_PACKAGE_SIZE - (gen + 1) * OPERAND_WIDTH_IN_BITS]}};
        
        assign gen_result = result_package_out[RESULT_PACKAGE_SIZE - gen * RESULT_WIDTH_IN_BITS - 1 : RESULT_PACKAGE_SIZE - (gen + 1) * RESULT_WIDTH_IN_BITS];
        
        always@(posedge clk_in, posedge reset_in)
        begin
            if (reset_in)
            begin
                result_package_out <= {(RESULT_PACKAGE_SIZE){1'b0}};
            end
            else
            begin
                result_package_out[RESULT_PACKAGE_SIZE - gen * RESULT_WIDTH_IN_BITS - 1 : RESULT_PACKAGE_SIZE - (gen + 1) * RESULT_WIDTH_IN_BITS] =
                     (OPERAND_WIDTH_IN_BITS < RESULT_WIDTH_IN_BITS) ? {{(RESULT_WIDTH_IN_BITS - OPERAND_WIDTH_IN_BITS){1'b0}}, gen_operand_1 + gen_operand_2} : gen_operand_1 + gen_operand_2;   
            end
        end
       
    end

endgenerate

endmodule
