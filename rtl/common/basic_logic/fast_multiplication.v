module fast_multiplication
#(
    parameter OPERAND_WIDTH_IN_BITS  = 64,
    parameter PRODUCT_WIDTH_IN_BITS = 128 
)
(
    input                                           reset_in,
    input                                           clk_in,
    
    output reg                                      is_ready_out,
    output reg                                      is_valid_out,
    input                                           is_valid_in,

    input                                           multiplier_sign_bit_in,
    input       [OPERAND_WIDTH_IN_BITS - 1 : 0]     multiplier_in,
    
    input                                           multicand_sign_bit_in,
    input       [OPERAND_WIDTH_IN_BITS - 1 : 0]     multicand_in,
    
    output reg                                      product_sign_bit_out,
    output reg  [PRODUCT_WIDTH_IN_BITS - 1 : 0]     product_out
);


parameter [31:0] NUM_STAGE = 6;

parameter [31:0] STAGE_0_NUM_ADDER = 32;
parameter [31:0] STAGE_1_NUM_ADDER = 16;
parameter [31:0] STAGE_2_NUM_ADDER = 8;
parameter [31:0] STAGE_3_NUM_ADDER = 4;
parameter [31:0] STAGE_4_NUM_ADDER = 2;
parameter [31:0] STAGE_5_NUM_ADDER = 1;

parameter [31:0] STAGE_0_SHIFT_IN_BITS = 1;
parameter [31:0] STAGE_1_SHIFT_IN_BITS = 2;
parameter [31:0] STAGE_2_SHIFT_IN_BITS = 4;
parameter [31:0] STAGE_3_SHIFT_IN_BITS = 8;
parameter [31:0] STAGE_4_SHIFT_IN_BITS = 16;
parameter [31:0] STAGE_5_SHIFT_IN_BITS = 32;

parameter [31:0] STAGE_0_OPERAND_WIDTH_IN_BITS = OPERAND_WIDTH_IN_BITS + 1;
parameter [31:0] STAGE_1_OPERAND_WIDTH_IN_BITS = STAGE_0_OPERAND_WIDTH_IN_BITS + STAGE_0_SHIFT_IN_BITS;
parameter [31:0] STAGE_2_OPERAND_WIDTH_IN_BITS = STAGE_1_OPERAND_WIDTH_IN_BITS + STAGE_1_SHIFT_IN_BITS;
parameter [31:0] STAGE_3_OPERAND_WIDTH_IN_BITS = STAGE_2_OPERAND_WIDTH_IN_BITS + STAGE_2_SHIFT_IN_BITS;
parameter [31:0] STAGE_4_OPERAND_WIDTH_IN_BITS = STAGE_3_OPERAND_WIDTH_IN_BITS + STAGE_3_SHIFT_IN_BITS;
parameter [31:0] STAGE_5_OPERAND_WIDTH_IN_BITS = STAGE_4_OPERAND_WIDTH_IN_BITS + STAGE_4_SHIFT_IN_BITS;

parameter [31:0] STAGE_0_RESULT_WIDTH_IN_BITS = STAGE_1_OPERAND_WIDTH_IN_BITS;
parameter [31:0] STAGE_1_RESULT_WIDTH_IN_BITS = STAGE_2_OPERAND_WIDTH_IN_BITS;
parameter [31:0] STAGE_2_RESULT_WIDTH_IN_BITS = STAGE_3_OPERAND_WIDTH_IN_BITS;
parameter [31:0] STAGE_3_RESULT_WIDTH_IN_BITS = STAGE_4_OPERAND_WIDTH_IN_BITS;
parameter [31:0] STAGE_4_RESULT_WIDTH_IN_BITS = STAGE_5_OPERAND_WIDTH_IN_BITS;
parameter [31:0] STAGE_5_RESULT_WIDTH_IN_BITS = STAGE_5_OPERAND_WIDTH_IN_BITS + STAGE_5_SHIFT_IN_BITS;

parameter [31:0] STAGE_0_OPERAND_PACKAGE_WIDTH_IN_BITS = STAGE_0_OPERAND_WIDTH_IN_BITS * STAGE_0_NUM_ADDER;
parameter [31:0] STAGE_1_OPERAND_PACKAGE_WIDTH_IN_BITS = STAGE_1_OPERAND_WIDTH_IN_BITS * STAGE_1_NUM_ADDER;
parameter [31:0] STAGE_2_OPERAND_PACKAGE_WIDTH_IN_BITS = STAGE_2_OPERAND_WIDTH_IN_BITS * STAGE_2_NUM_ADDER;
parameter [31:0] STAGE_3_OPERAND_PACKAGE_WIDTH_IN_BITS = STAGE_3_OPERAND_WIDTH_IN_BITS * STAGE_3_NUM_ADDER;
parameter [31:0] STAGE_4_OPERAND_PACKAGE_WIDTH_IN_BITS = STAGE_4_OPERAND_WIDTH_IN_BITS * STAGE_4_NUM_ADDER;
parameter [31:0] STAGE_5_OPERAND_PACKAGE_WIDTH_IN_BITS = STAGE_5_OPERAND_WIDTH_IN_BITS * STAGE_5_NUM_ADDER;

parameter [31:0] STAGE_0_RESULT_PACKAGE_WIDTH_IN_BITS = STAGE_0_RESULT_WIDTH_IN_BITS * STAGE_0_NUM_ADDER;
parameter [31:0] STAGE_1_RESULT_PACKAGE_WIDTH_IN_BITS = STAGE_1_RESULT_WIDTH_IN_BITS * STAGE_1_NUM_ADDER;
parameter [31:0] STAGE_2_RESULT_PACKAGE_WIDTH_IN_BITS = STAGE_2_RESULT_WIDTH_IN_BITS * STAGE_2_NUM_ADDER;
parameter [31:0] STAGE_3_RESULT_PACKAGE_WIDTH_IN_BITS = STAGE_3_RESULT_WIDTH_IN_BITS * STAGE_3_NUM_ADDER;
parameter [31:0] STAGE_4_RESULT_PACKAGE_WIDTH_IN_BITS = STAGE_4_RESULT_WIDTH_IN_BITS * STAGE_4_NUM_ADDER;
parameter [31:0] STAGE_5_RESULT_PACKAGE_WIDTH_IN_BITS = STAGE_5_RESULT_WIDTH_IN_BITS * STAGE_5_NUM_ADDER;


wire [STAGE_0_RESULT_PACKAGE_WIDTH_IN_BITS - 1 : 0] result_package_from_stage_0;
wire [STAGE_1_RESULT_PACKAGE_WIDTH_IN_BITS - 1 : 0] result_package_from_stage_1;
wire [STAGE_2_RESULT_PACKAGE_WIDTH_IN_BITS - 1 : 0] result_package_from_stage_2;
wire [STAGE_3_RESULT_PACKAGE_WIDTH_IN_BITS - 1 : 0] result_package_from_stage_3;
wire [STAGE_4_RESULT_PACKAGE_WIDTH_IN_BITS - 1 : 0] result_package_from_stage_4;
wire [STAGE_5_RESULT_PACKAGE_WIDTH_IN_BITS - 1 : 0] result_package_from_stage_5;

wire [STAGE_0_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_1_to_stage_0;
wire [STAGE_0_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_2_to_stage_0;

wire [STAGE_1_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_1_to_stage_1;
wire [STAGE_1_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_2_to_stage_1;

wire [STAGE_2_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_1_to_stage_2;
wire [STAGE_2_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_2_to_stage_2;

wire [STAGE_3_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_1_to_stage_3;
wire [STAGE_3_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_2_to_stage_3;

wire [STAGE_4_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_1_to_stage_4;
wire [STAGE_4_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_2_to_stage_4;

wire [STAGE_5_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_1_to_stage_5;
wire [STAGE_5_OPERAND_PACKAGE_WIDTH_IN_BITS - 1 : 0] operand_package_2_to_stage_5;

reg [NUM_STAGE - 1 : 0] valid_bit_buffer;

always@(posedge clk_in, posedge reset_in)
begin
    if (reset_in)
    begin
        is_ready_out                            <= 1'b1;
        product_sign_bit_out                    <= 1'b0;
        product_out                             <= {(PRODUCT_WIDTH_IN_BITS){1'b0}};
    end
    else
    begin
        is_ready_out                            <= 1'b1;
        is_valid_out                            <= valid_bit_buffer[NUM_STAGE - 1];
        
        product_sign_bit_out                    <= ~ (multiplier_sign_bit_in ^ multicand_sign_bit_in);
        product_out                             <= result_package_from_stage_5;
        
    end
end


generate
genvar gen;

//valid buffer
for (gen = 0; gen < NUM_STAGE; gen = gen + 1)
begin
    if (gen == 0)
    begin
        always@(posedge clk_in, posedge reset_in)
        begin
            if (reset_in)
            begin
                valid_bit_buffer[0] = 1'b0; 
            end
            else
            begin
                valid_bit_buffer[0] <= is_valid_in;
            end
        end 
    end
    else
    begin
        always@(posedge clk_in, posedge reset_in)
        begin
            if (reset_in)
            begin
                valid_bit_buffer[gen] = 1'b0; 
            end
            else
            begin
                valid_bit_buffer[gen] <= valid_bit_buffer[gen - 1]; 
            end
        end
    end    
end

//operand to stage 0
for (gen = 0; gen < STAGE_0_NUM_ADDER; gen = gen + 1)
begin
    assign operand_package_2_to_stage_0[(gen + 1) * STAGE_0_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_0_OPERAND_WIDTH_IN_BITS] = multiplier_in[gen * 2] ? multicand_in : {(STAGE_0_OPERAND_WIDTH_IN_BITS){1'b0}};
    assign operand_package_1_to_stage_0[(gen + 1) * STAGE_0_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_0_OPERAND_WIDTH_IN_BITS] = multiplier_in[gen * 2 + 1] ? multicand_in : {(STAGE_0_OPERAND_WIDTH_IN_BITS){1'b0}};
end

//operand to stage 1
for(gen = 0; gen < STAGE_1_NUM_ADDER; gen = gen + 1)
begin
    assign operand_package_2_to_stage_1[(gen + 1) * STAGE_1_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_1_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_0[(gen * 2 + 1) * STAGE_0_RESULT_WIDTH_IN_BITS - 1 : (gen * 2) * STAGE_0_RESULT_WIDTH_IN_BITS];
    assign operand_package_1_to_stage_1[(gen + 1) * STAGE_1_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_1_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_0[(gen * 2 + 2) * STAGE_0_RESULT_WIDTH_IN_BITS - 1 : (gen * 2 + 1) * STAGE_0_RESULT_WIDTH_IN_BITS];
end

//operand to stage 2
for(gen = 0; gen < STAGE_2_NUM_ADDER; gen = gen + 1)
begin
    assign operand_package_2_to_stage_2[(gen + 1) * STAGE_2_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_2_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_1[(gen * 2 + 1) * STAGE_1_RESULT_WIDTH_IN_BITS - 1 : (gen * 2) * STAGE_1_RESULT_WIDTH_IN_BITS];
    assign operand_package_1_to_stage_2[(gen + 1) * STAGE_2_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_2_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_1[(gen * 2 + 2) * STAGE_1_RESULT_WIDTH_IN_BITS - 1 : (gen * 2 + 1) * STAGE_1_RESULT_WIDTH_IN_BITS];
end

//operand to stage 3
for(gen = 0; gen < STAGE_3_NUM_ADDER; gen = gen + 1)
begin
    assign operand_package_2_to_stage_3[(gen + 1) * STAGE_3_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_3_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_2[(gen * 2 + 1) * STAGE_2_RESULT_WIDTH_IN_BITS - 1 : (gen * 2) * STAGE_2_RESULT_WIDTH_IN_BITS];
    assign operand_package_1_to_stage_3[(gen + 1) * STAGE_3_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_3_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_2[(gen * 2 + 2) * STAGE_2_RESULT_WIDTH_IN_BITS - 1 : (gen * 2 + 1) * STAGE_2_RESULT_WIDTH_IN_BITS];
end

//operand to stage 4
for(gen = 0; gen < STAGE_4_NUM_ADDER; gen = gen + 1)
begin
    assign operand_package_2_to_stage_4[(gen + 1) * STAGE_4_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_4_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_3[(gen * 2 + 1) * STAGE_3_RESULT_WIDTH_IN_BITS - 1 : (gen * 2) * STAGE_3_RESULT_WIDTH_IN_BITS];
    assign operand_package_1_to_stage_4[(gen + 1) * STAGE_4_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_4_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_3[(gen * 2 + 2) * STAGE_3_RESULT_WIDTH_IN_BITS - 1 : (gen * 2 + 1) * STAGE_3_RESULT_WIDTH_IN_BITS];
end

//operand to stage 5
for(gen = 0; gen < STAGE_5_NUM_ADDER; gen = gen + 1)
begin
    assign operand_package_2_to_stage_5[(gen + 1) * STAGE_5_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_5_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_4[(gen * 2 + 1) * STAGE_4_RESULT_WIDTH_IN_BITS - 1 : (gen * 2) * STAGE_4_RESULT_WIDTH_IN_BITS];
    assign operand_package_1_to_stage_5[(gen + 1) * STAGE_5_OPERAND_WIDTH_IN_BITS - 1 : gen * STAGE_5_OPERAND_WIDTH_IN_BITS] = result_package_from_stage_4[(gen * 2 + 2) * STAGE_4_RESULT_WIDTH_IN_BITS - 1 : (gen * 2 + 1) * STAGE_4_RESULT_WIDTH_IN_BITS];
end

endgenerate

adder_tree
#(
    .NUM_ADDER(STAGE_0_NUM_ADDER),
    .OPERAND_RGHIT_SHIFT_IN_BITS(STAGE_0_SHIFT_IN_BITS),
    .OPERAND_WIDTH_IN_BITS(STAGE_0_OPERAND_WIDTH_IN_BITS),
    .RESULT_WIDTH_IN_BITS(STAGE_0_RESULT_WIDTH_IN_BITS)
)
adder_tree_stage_0
(
    .reset_in(reset_in),
    .clk_in(clk_in),
    
    .operand_package_1_in(operand_package_1_to_stage_0),
    .operand_package_2_in(operand_package_2_to_stage_0),
    
    .result_package_out(result_package_from_stage_0)
);

adder_tree
#(
    .NUM_ADDER(STAGE_1_NUM_ADDER),
    .OPERAND_RGHIT_SHIFT_IN_BITS(STAGE_1_SHIFT_IN_BITS),
    .OPERAND_WIDTH_IN_BITS(STAGE_1_OPERAND_WIDTH_IN_BITS),
    .RESULT_WIDTH_IN_BITS(STAGE_1_RESULT_WIDTH_IN_BITS)
)
adder_tree_stage_1
(
    .reset_in(reset_in),
    .clk_in(clk_in),
    
    .operand_package_1_in(operand_package_1_to_stage_1),
    .operand_package_2_in(operand_package_2_to_stage_1),
    
    .result_package_out(result_package_from_stage_1)
);

adder_tree
#(
    .NUM_ADDER(STAGE_2_NUM_ADDER),
    .OPERAND_RGHIT_SHIFT_IN_BITS(STAGE_2_SHIFT_IN_BITS),
    .OPERAND_WIDTH_IN_BITS(STAGE_2_OPERAND_WIDTH_IN_BITS),
    .RESULT_WIDTH_IN_BITS(STAGE_2_RESULT_WIDTH_IN_BITS)
)
adder_tree_stage_2
(
    .reset_in(reset_in),
    .clk_in(clk_in),
    
    .operand_package_1_in(operand_package_1_to_stage_2),
    .operand_package_2_in(operand_package_2_to_stage_2),
    
    .result_package_out(result_package_from_stage_2)
);

adder_tree
#(
    .NUM_ADDER(STAGE_3_NUM_ADDER),
    .OPERAND_RGHIT_SHIFT_IN_BITS(STAGE_3_SHIFT_IN_BITS),
    .OPERAND_WIDTH_IN_BITS(STAGE_3_OPERAND_WIDTH_IN_BITS),
    .RESULT_WIDTH_IN_BITS(STAGE_3_RESULT_WIDTH_IN_BITS)
)
adder_tree_stage_3
(
    .reset_in(reset_in),
    .clk_in(clk_in),
    
    .operand_package_1_in(operand_package_1_to_stage_3),
    .operand_package_2_in(operand_package_2_to_stage_3),
    
    .result_package_out(result_package_from_stage_3)
);

adder_tree
#(
    .NUM_ADDER(STAGE_4_NUM_ADDER),
    .OPERAND_RGHIT_SHIFT_IN_BITS(STAGE_4_SHIFT_IN_BITS),
    .OPERAND_WIDTH_IN_BITS(STAGE_4_OPERAND_WIDTH_IN_BITS),
    .RESULT_WIDTH_IN_BITS(STAGE_4_RESULT_WIDTH_IN_BITS)
)
adder_tree_stage_4
(
    .reset_in(reset_in),
    .clk_in(clk_in),
    
    .operand_package_1_in(operand_package_1_to_stage_4),
    .operand_package_2_in(operand_package_2_to_stage_4),
    
    .result_package_out(result_package_from_stage_4)
);

adder_tree
#(
    .NUM_ADDER(STAGE_5_NUM_ADDER),
    .OPERAND_RGHIT_SHIFT_IN_BITS(STAGE_5_SHIFT_IN_BITS),
    .OPERAND_WIDTH_IN_BITS(STAGE_5_OPERAND_WIDTH_IN_BITS),
    .RESULT_WIDTH_IN_BITS(STAGE_5_RESULT_WIDTH_IN_BITS)
)
adder_tree_stage_5
(
    .reset_in(reset_in),
    .clk_in(clk_in),
    
    .operand_package_1_in(operand_package_1_to_stage_5),
    .operand_package_2_in(operand_package_2_to_stage_5),
    
    .result_package_out(result_package_from_stage_5)
);

//generate


//genvar gen, stage;

////parallel tree
//for (stage = 0; stage < NUM_STAGE; stage = stage + 1)
//begin
//    for (gen = 0; gen < 2 ** (NUM_STAGE - stage - 1); gen = gen + 1)
//    begin
        
//    end
//end

//endgenerate

endmodule
