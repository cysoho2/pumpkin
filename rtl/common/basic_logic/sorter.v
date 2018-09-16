module acsending_sorter
#(
    parameter SINGLE_REQUEST_WIDTH_IN_BITS = 32,
    parameter NUM_REQUEST                  = 16
)
(
    input                                                       clk_in,
    input                                                       reset_in,
    input [SINGLE_REQUEST_WIDTH_IN_BITS * NUM_REQUEST - 1 : 0]  pre_sort_flatted,
    input [SINGLE_REQUEST_WIDTH_IN_BITS * NUM_REQUEST - 1 : 0]  post_sort_flatted
);