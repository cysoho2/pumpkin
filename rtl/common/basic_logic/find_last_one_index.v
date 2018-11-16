module find_last_one_index
#(
    parameter VECTOR_LENGTH    = 8,
    parameter MAX_OUTPUT_WIDTH = 16
)
(
    input       [VECTOR_LENGTH    - 1 : 0]      vector_in,
    output reg  [MAX_OUTPUT_WIDTH - 1 : 0]      last_one_index_out,
    output reg                                  one_is_found_out
);

integer loop_index;

always@*
begin : Find_Last_One
    last_one_index_out  <= {(MAX_OUTPUT_WIDTH){1'b0}};
    one_is_found_out     <= 1'b0;

    for(loop_index = VECTOR_LENGTH - 1; loop_index >= 0; loop_index = loop_index - 1)
    begin
        if(vector_in[loop_index])
        begin
            last_one_index_out  <= loop_index;
            one_is_found_out     <= 1'b1;
            disable Find_Last_One; //TO exit the loop
        end
    end
end

endmodule
