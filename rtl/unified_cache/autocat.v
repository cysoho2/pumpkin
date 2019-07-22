module autocat
#(
    parameter CACHE_ASSOCIATIVITY = 16, // currently only support 16-way fix configuration
    parameter COUNTER_WIDTH       = 32,
    parameter RESET_BIN_POWER     = 20,  // 2^20 is about 1M requests
    parameter ALLOWED_GAP         = 500
)
(
    input                                                       clk_in,
    input                                                       reset_in,

    input                                                       access_valid_in,
    input      [CACHE_ASSOCIATIVITY                 - 1 : 0]    hit_vec_in,

    output reg [CACHE_ASSOCIATIVITY                 - 1 : 0]    suggested_waymask_out
);

// overall request counter
reg                               access_valid_pre;
reg [CACHE_ASSOCIATIVITY - 1 : 0] hit_vec_pre;
reg [63                      : 0] access_counter;

wire request_limit            = access_counter == 2 ** RESET_BIN_POWER;
wire reset_with_request_limit = reset_in | request_limit;

always@(posedge clk_in)
begin
    if(reset_with_request_limit)
    begin
        access_counter      <= 0;
        access_valid_pre    <= 0;
        hit_vec_pre         <= 0;
    end

    else
    begin
        access_valid_pre    <= access_valid_in;
        hit_vec_pre         <= hit_vec_in;
        
        if(~access_valid_pre & access_valid_in)
            access_counter <= access_counter + 1'b1;
    end
end

wire [CACHE_ASSOCIATIVITY * COUNTER_WIDTH - 1 : 0] counter_flatted;
wire [CACHE_ASSOCIATIVITY * COUNTER_WIDTH - 1 : 0] post_sort_counter_flatted;

// hit counter array
generate
genvar gen;

for(gen = 0; gen < CACHE_ASSOCIATIVITY; gen = gen + 1)
begin
    reg [COUNTER_WIDTH - 1 : 0] hit_counter;
    assign counter_flatted[gen * COUNTER_WIDTH +: COUNTER_WIDTH] = hit_counter;

    always@(posedge clk_in)
    begin
        if(reset_with_request_limit)
        begin
            hit_counter <= 0;
        end

        else if(|(~hit_vec_pre[gen:0] & hit_vec_in[gen:0]))
        begin
            hit_counter <= hit_counter + 1'b1;
        end
    end
end

endgenerate

// sort all the hit counters
bitonic_sorter
#(
    .SINGLE_WAY_WIDTH_IN_BITS(COUNTER_WIDTH),
    .NUM_WAY(CACHE_ASSOCIATIVITY)
)
sorter
(
    .clk_in(clk_in),
    .reset_in(reset_in),
    .pre_sort_flatted_in(counter_flatted),
    .post_sort_flatted_out(post_sort_counter_flatted)
);

wire [CACHE_ASSOCIATIVITY * COUNTER_WIDTH - 1 : 0] post_calc_counter_flatted;
generate
    for(gen = 0; gen < CACHE_ASSOCIATIVITY; gen = gen + 1)
    begin
        assign post_calc_counter_flatted[gen * COUNTER_WIDTH +: COUNTER_WIDTH] =
               post_sort_counter_flatted[gen * COUNTER_WIDTH +: COUNTER_WIDTH] >> (RESET_BIN_POWER - 4);
    end
endgenerate

integer loop_index;
reg [CACHE_ASSOCIATIVITY - 1 : 0] first_best_partition;

always@*
begin : Find
    first_best_partition  <= 0;

    for(loop_index = 0; loop_index < CACHE_ASSOCIATIVITY; loop_index = loop_index + 1)
    begin
        if(post_calc_counter_flatted[loop_index * COUNTER_WIDTH +: COUNTER_WIDTH] + ALLOWED_GAP >=
           post_calc_counter_flatted[(CACHE_ASSOCIATIVITY - 1) * COUNTER_WIDTH +: COUNTER_WIDTH])
        begin
            first_best_partition <= loop_index;
            disable Find; //TO exit the loop
        end
    end
end

always@(posedge clk_in)
begin
    if(reset_in)
    begin
        suggested_waymask_out       <= 16'b1111_1111_1111_1111;
    end

    else if(request_limit)
    begin
        for(loop_index = 0; loop_index < CACHE_ASSOCIATIVITY; loop_index = loop_index + 1)
        begin
            if(first_best_partition >= loop_index)
                suggested_waymask_out[loop_index] <= 1'b1;
            else suggested_waymask_out[loop_index] <= 1'b0;
        end
    end
end

endmodule