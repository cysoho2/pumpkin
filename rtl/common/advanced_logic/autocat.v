module autocat
#
(
    parameter CACHE_ASSOCIATIVITY = 16, // currently only support 16-way fix configuration
    parameter COUNTER_WIDTH       = 32,
    parameter RESET_BIN_POWER     = 20  // 2^20 is about 1M requests
)
(
    input                                                   clk_in,
    input                                                   reset_in,

    output [CACHE_ASSOCIATIVITY * COUNTER_WIDTH - 1 : 0]    cat_counter_flatted_out,

    input                                                   access_valid_in,
    input  [CACHE_ASSOCIATIVITY                 - 1 : 0]    hit_vec_in,

    output [CACHE_ASSOCIATIVITY                 - 1 : 0]    suggested_waymask_out
);

//wire is_sampled = set_address[$clog2(SAMPLE_RATIO) - 1 : 0] == 0;
wire reset_with_request_limit = reset_in | request_counter == 2 ** RESET_BIN_POWER;

// overall request counter
reg                               access_valid_pre;
reg [CACHE_ASSOCIATIVITY - 1 : 0] hit_vec_pre;
reg [63                      : 0] access_counter;

always@(posedge clk_in, posedge reset_with_request_limit)
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

    always@(posedge clk_in, posedge reset_with_request_limit)
    begin
        if(reset_with_request_limit)
        begin
            hit_counter <= 0;
        end

        else if(~hit_vec_pre[gen] & hit_vec_in[gen])
        begin
            hit_counter <= hit_counter + 1'b1;
        end
    end
end

endgenerate

// sort all the hit counters
bitonic_sorter_16
#(
    .SINGLE_WAY_WIDTH_IN_BITS(COUNTER_WIDTH),
    .NUM_WAY(NUM_WAY)
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

endmodule