// with 8 elements, this module will be synthesized into 4-layer of logic
module conditional_compare_select
#
(
    parameter NUM_ELEMENTS                 = 8, // currently support 16-elements at most
	parameter ELEMENT_PTR_SIZE_IN_BITS     = 3,
	parameter SINGLE_ELEMENT_WIDTH_IN_BITS = 3
)
(
	input                                [NUM_ELEMENTS - 1 : 0] 	condition_in,
	input [SINGLE_ELEMENT_WIDTH_IN_BITS * NUM_ELEMENTS - 1 : 0]		 elements_in,
	output               [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0]		 selected_out
);

generate
    genvar i;
    wire [SINGLE_ELEMENT_WIDTH_IN_BITS * NUM_ELEMENTS - 1 : 0]      values_layer1;
    wire     [ELEMENT_PTR_SIZE_IN_BITS * NUM_ELEMENTS - 1 : 0]        ptrs_layer1;

    if(NUM_ELEMENTS != 0)
    begin : layer1
        for(i = 0; i < NUM_ELEMENTS; i = i + 1)
        begin
            assign values_layer1[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS] =
            	    condition_in[i] ? elements_in[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS] : {SINGLE_ELEMENT_WIDTH_IN_BITS{1'b0}};

            assign   ptrs_layer1[(i+1) * ELEMENT_PTR_SIZE_IN_BITS - 1 : i * ELEMENT_PTR_SIZE_IN_BITS] = i;
        end
    end
endgenerate

generate
    wire [SINGLE_ELEMENT_WIDTH_IN_BITS * NUM_ELEMENTS / 2 - 1 : 0] values_layer2;
    wire     [ELEMENT_PTR_SIZE_IN_BITS * NUM_ELEMENTS / 2 - 1 : 0]   ptrs_layer2;

    if(NUM_ELEMENTS / 2 > 0)
    begin : layer2
        for(i = 0; i < NUM_ELEMENTS / 2; i = i + 1)
        begin
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value1 = values_layer1[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value2 = values_layer1[(i+1 + (NUM_ELEMENTS / 2)) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : (i + (NUM_ELEMENTS / 2)) * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]       ptr1 =   ptrs_layer1[(i+1) * ELEMENT_PTR_SIZE_IN_BITS - 1 : i * ELEMENT_PTR_SIZE_IN_BITS];
            wire [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]       ptr2 =   ptrs_layer1[(i+1 + (NUM_ELEMENTS / 2)) * ELEMENT_PTR_SIZE_IN_BITS - 1 : (i + (NUM_ELEMENTS / 2)) * ELEMENT_PTR_SIZE_IN_BITS];

            assign values_layer2[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS] = value1 > value2 ? value1 : value2;
            assign   ptrs_layer2[(i+1) * ELEMENT_PTR_SIZE_IN_BITS     - 1 : i * ELEMENT_PTR_SIZE_IN_BITS]     = value1 > value2 ? ptr1 : ptr2;
        end
    end

    else if(NUM_ELEMENTS == 1)
    begin
    	assign selected_out = ptrs_layer1[ELEMENT_PTR_SIZE_IN_BITS - 1 : 0];
    end
endgenerate

generate
    wire [SINGLE_ELEMENT_WIDTH_IN_BITS * NUM_ELEMENTS / 4 - 1 : 0] values_layer3;
    wire     [ELEMENT_PTR_SIZE_IN_BITS * NUM_ELEMENTS / 4 - 1 : 0]   ptrs_layer3;

    if(NUM_ELEMENTS / 4 > 0)
    begin : layer3
        for(i = 0; i < NUM_ELEMENTS / 4; i = i + 1)
        begin
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value1 = values_layer2[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value2 = values_layer2[(i+1 + (NUM_ELEMENTS / 4)) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : (i + (NUM_ELEMENTS / 4)) * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire     [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]   ptr1 =   ptrs_layer2[(i+1) * ELEMENT_PTR_SIZE_IN_BITS - 1 : i * ELEMENT_PTR_SIZE_IN_BITS];
            wire     [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]   ptr2 =   ptrs_layer2[(i+1 + (NUM_ELEMENTS / 4)) * ELEMENT_PTR_SIZE_IN_BITS - 1 : (i + (NUM_ELEMENTS / 4)) * ELEMENT_PTR_SIZE_IN_BITS];

            assign values_layer3[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS] = value1 > value2 ? value1 : value2;
            assign   ptrs_layer3[(i+1) * ELEMENT_PTR_SIZE_IN_BITS     - 1 : i * ELEMENT_PTR_SIZE_IN_BITS]     = value1 > value2 ? ptr1 : ptr2;
        end
    end

    else if(NUM_ELEMENTS == 2)
    begin
    	assign selected_out = ptrs_layer2[ELEMENT_PTR_SIZE_IN_BITS - 1 : 0];
    end
endgenerate

generate
    wire [SINGLE_ELEMENT_WIDTH_IN_BITS * NUM_ELEMENTS / 8 - 1 : 0] values_layer4;
    wire     [ELEMENT_PTR_SIZE_IN_BITS * NUM_ELEMENTS / 8 - 1 : 0]   ptrs_layer4;

    if(NUM_ELEMENTS / 8 > 0)
    begin : layer4
        for(i = 0; i < NUM_ELEMENTS / 8; i = i + 1)
        begin
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value1 = values_layer3[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value2 = values_layer3[(i+1 + (NUM_ELEMENTS / 8)) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : (i + (NUM_ELEMENTS / 8)) * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire     [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]   ptr1 =   ptrs_layer3[(i+1) * ELEMENT_PTR_SIZE_IN_BITS - 1 : i * ELEMENT_PTR_SIZE_IN_BITS];
            wire     [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]   ptr2 =   ptrs_layer3[(i+1 + (NUM_ELEMENTS / 8)) * ELEMENT_PTR_SIZE_IN_BITS - 1 : (i + (NUM_ELEMENTS / 8)) * ELEMENT_PTR_SIZE_IN_BITS];

            assign values_layer4[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS] = value1 > value2 ? value1 : value2;
            assign   ptrs_layer4[(i+1) * ELEMENT_PTR_SIZE_IN_BITS     - 1 : i * ELEMENT_PTR_SIZE_IN_BITS]     = value1 > value2 ?   ptr1 : ptr2;
        end
    end

    else if(NUM_ELEMENTS == 4)
    begin
    	assign selected_out = ptrs_layer3[ELEMENT_PTR_SIZE_IN_BITS - 1 : 0];
    end
endgenerate

generate
    wire [SINGLE_ELEMENT_WIDTH_IN_BITS * NUM_ELEMENTS / 16 - 1 : 0] values_layer5;
    wire     [ELEMENT_PTR_SIZE_IN_BITS * NUM_ELEMENTS / 16 - 1 : 0]   ptrs_layer5;

    if(NUM_ELEMENTS / 16 > 0)
    begin : layer5
        for(i = 0; i < NUM_ELEMENTS / 16; i = i + 1)
        begin
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value1 = values_layer4[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value2 = values_layer4[(i+1 + (NUM_ELEMENTS / 16)) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : (i + (NUM_ELEMENTS / 16)) * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire     [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]   ptr1 =   ptrs_layer4[(i+1) * ELEMENT_PTR_SIZE_IN_BITS - 1 : i * ELEMENT_PTR_SIZE_IN_BITS];
            wire     [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]   ptr2 =   ptrs_layer4[(i+1 + (NUM_ELEMENTS / 16)) * ELEMENT_PTR_SIZE_IN_BITS - 1 : (i + (NUM_ELEMENTS / 16)) * ELEMENT_PTR_SIZE_IN_BITS];

            assign values_layer5[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS] = value1 > value2 ? value1 : value2;
            assign   ptrs_layer5[(i+1) * ELEMENT_PTR_SIZE_IN_BITS     - 1 : i * ELEMENT_PTR_SIZE_IN_BITS]     = value1 > value2 ?   ptr1 : ptr2;
        end
    end

    else if(NUM_ELEMENTS == 8)
    begin
    	assign selected_out = ptrs_layer4[ELEMENT_PTR_SIZE_IN_BITS - 1 : 0];
    end
endgenerate

generate
    wire [SINGLE_ELEMENT_WIDTH_IN_BITS * NUM_ELEMENTS / 32 - 1 : 0] values_layer6;
    wire     [ELEMENT_PTR_SIZE_IN_BITS * NUM_ELEMENTS / 32 - 1 : 0]   ptrs_layer6;

    if(NUM_ELEMENTS / 32 > 0)
    begin : layer6
        for(i = 0; i < NUM_ELEMENTS / 32; i = i + 1)
        begin
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value1 = values_layer5[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire [SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : 0] value2 = values_layer5[(i+1 + (NUM_ELEMENTS / 32)) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : (i + (NUM_ELEMENTS / 32)) * SINGLE_ELEMENT_WIDTH_IN_BITS];
        	wire     [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]   ptr1 =   ptrs_layer5[(i+1) * ELEMENT_PTR_SIZE_IN_BITS - 1 : i * ELEMENT_PTR_SIZE_IN_BITS];
            wire     [ELEMENT_PTR_SIZE_IN_BITS - 1 : 0]   ptr2 =   ptrs_layer5[(i+1 + (NUM_ELEMENTS / 32)) * ELEMENT_PTR_SIZE_IN_BITS - 1 : (i + (NUM_ELEMENTS / 32)) * ELEMENT_PTR_SIZE_IN_BITS];

            assign values_layer6[(i+1) * SINGLE_ELEMENT_WIDTH_IN_BITS - 1 : i * SINGLE_ELEMENT_WIDTH_IN_BITS] = value1 > value2 ? value1 : value2;
            assign   ptrs_layer6[(i+1) * ELEMENT_PTR_SIZE_IN_BITS     - 1 : i * ELEMENT_PTR_SIZE_IN_BITS]     = value1 > value2 ?   ptr1 : ptr2;
        end
    end

    else if(NUM_ELEMENTS == 16)
    begin
    	assign selected_out = ptrs_layer5[ELEMENT_PTR_SIZE_IN_BITS - 1 : 0];
    end
endgenerate

endmodule
