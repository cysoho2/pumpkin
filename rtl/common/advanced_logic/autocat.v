module autocat
#
(
    //parameter SAMPLE_RATIO      = 32,
    parameter CACHE_ASSOCIATIVITY = 16,
    parameter COUNTER_LEN         = 32,
    parameter SET_ADDR_LEN        = 64,
    parameter RESET_REQUEST       = 32'h0010_0000;
)
(
    input                                              clk_in,
    input                                              reset_in,

    output [CACHE_ASSOCIATIVITY * COUNTER_LEN - 1 : 0] cat_counter_flatted,

    input  [SET_ADDR_LEN                      - 1 : 0] set_address,
    input                                              access_valid,
    input  [CACHE_ASSOCIATIVITY               - 1 : 0] hit_vec,

    output [CACHE_ASSOCIATIVITY               - 1 : 0] suggested_waymask
);

//wire is_sampled = set_address[$clog2(SAMPLE_RATIO) - 1 : 0] == 0;
wire reset_with_request_limit = reset_in | request_counter == RESET_REQUEST;

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
        hit_vec             <= 0;
    end

    else
    begin
        access_valid_pre    <= access_valid;
        hit_vec_pre         <= hit_vec;
        
        if(~access_valid_pre & access_valid)
            access_counter <= access_counter + 1'b1;
    end
end

wire [CACHE_ASSOCIATIVITY * COUNTER_LEN - 1 : 0] counter_flatted;

// hit counter array
generate
genvar gen;

for(gen = 0; gen < CACHE_ASSOCIATIVITY; gen = gen + 1)
begin
    reg [COUNTER_LEN - 1 : 0] hit_counter;
    assign counter_flatted[gen * COUNTER_LEN +: COUNTER_LEN] = hit_counter;

    always@(posedge clk_in, posedge reset_with_request_limit)
    begin
        if(reset_with_request_limit)
        begin
            hit_counter <= 0;
        end

        else if(~hit_vec_pre[gen] & hit_vec[gen])
        begin
            hit_counter <= hit_counter + 1'b1;
        end
    end
end

endgenerate

endmodule